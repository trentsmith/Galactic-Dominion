"""Galactic Dominion account/profile/market service. Python 3.10+, no dependencies."""
from __future__ import annotations
import argparse
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import secrets
import sqlite3
import time
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

CATALOG = json.loads((Path(__file__).parent / 'catalog.json').read_text())
ITEMS = {item['id']: item for item in CATALOG}
DEFAULT_CLASSES = ['interceptor', 'skirmisher', 'guardian']
CLASS_NAMES = dict(zip(DEFAULT_CLASSES + ['bomber', 'support'], ['Interceptor', 'Skirmisher', 'Guardian', 'Bomber', 'Support']))
SLOTS = ['engine', 'shield', 'weapon', 'utility', 'crew', 'variant']

def rarity_for_ticket(ticket):
    return "mythic" if ticket == 0 else "legendary" if ticket < 5 else "rare" if ticket < 824 else "uncommon" if ticket < 4756 else "common"

class ServiceError(Exception):
    def __init__(self, message, status=400):
        self.message, self.status = message, status

def default_profile():
    inventory = {x['id']: {'count': 1, 'discovered_at': 0, 'source': 'Fleet issue'} for x in CATALOG if x['starter']}
    # Every new online account receives a small, tradable welcome cache.
    for item in ['engine_sprint', 'shield_bulwark', 'crew_lyra']:
        inventory[item] = {'count': 1, 'discovered_at': int(time.time()), 'source': 'Welcome cache'}
    return {'version': 1, 'inventory': inventory, 'ship_classes': DEFAULT_CLASSES[:], 'loadouts': [dict(engine='engine_standard', shield='shield_standard', weapon='weapon_standard', utility='utility_standard', crew=crew, variant='variant_standard') for crew in ['crew_astra', 'crew_milo', 'crew_sera']], 'salvage': 200, 'battles': 0, 'wins': 0, 'total_kills': 0, 'total_damage': 0, 'exploration_records': {}}

class Store:
    def __init__(self, path, server_key):
        self.path, self.server_key = str(path), server_key
        Path(self.path).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.executescript('''
            PRAGMA journal_mode=WAL;
            CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY, username TEXT UNIQUE NOT NULL COLLATE NOCASE, salt TEXT NOT NULL, password_hash TEXT NOT NULL, profile TEXT NOT NULL, locked_until REAL NOT NULL DEFAULT 0);
            CREATE TABLE IF NOT EXISTS sessions(token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), expires REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS tickets(ticket_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), expires REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS listings(id TEXT PRIMARY KEY, seller TEXT NOT NULL REFERENCES users(id), item TEXT NOT NULL, price INTEGER NOT NULL, status TEXT NOT NULL, buyer TEXT, created REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS offers(id TEXT PRIMARY KEY, listing TEXT NOT NULL REFERENCES listings(id), buyer TEXT NOT NULL REFERENCES users(id), amount INTEGER NOT NULL, status TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS matches(id TEXT PRIMARY KEY, roster TEXT NOT NULL, status TEXT NOT NULL, created REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS roam_sessions(match_id TEXT PRIMARY KEY REFERENCES matches(id));
            CREATE TABLE IF NOT EXISTS roam_receipts(event_id TEXT PRIMARY KEY, match_id TEXT NOT NULL REFERENCES matches(id), user_id TEXT NOT NULL, ship TEXT NOT NULL, created REAL NOT NULL);
            ''')
            columns = {r['name'] for r in db.execute('PRAGMA table_info(users)')}
            if 'active_match' not in columns: db.execute("ALTER TABLE users ADD COLUMN active_match TEXT NOT NULL DEFAULT ''")
    def connect(self):
        db = sqlite3.connect(self.path, timeout=15)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys=ON')
        return db
    @contextmanager
    def transaction(self):
        db = self.connect()
        try:
            db.execute('BEGIN IMMEDIATE')
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()
    def _user(self, db, uid):
        row = db.execute('SELECT * FROM users WHERE id=?', (uid,)).fetchone()
        if row is None: raise ServiceError('Unknown account', 404)
        return row
    def _profile(self, row):
        p = json.loads(row['profile'])
        p.setdefault('discovery_records', {k:dict(v) for k,v in p['inventory'].items()})
        p.update(user_id=row['id'], commander_name=row['username'])
        return p
    def _save(self, db, uid, profile):
        db.execute('UPDATE users SET profile=? WHERE id=?', (json.dumps(profile), uid))
    def _unlocked(self, row):
        if row['locked_until'] > time.time(): raise ServiceError('Inventory is locked during an online match', 409)
    def register(self, username, password):
        if not isinstance(username, str) or not re.fullmatch(r'[A-Za-z0-9_]{3,24}', username): raise ServiceError('Name must be 3–24 letters, numbers or underscores')
        if not isinstance(password, str) or not 10 <= len(password) <= 128: raise ServiceError('Password must contain 10–128 characters')
        salt = secrets.token_hex(16)
        digest = hashlib.pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 310000).hex()
        uid = secrets.token_hex(16)
        try:
            with self.transaction() as db:
                db.execute('INSERT INTO users(id,username,salt,password_hash,profile) VALUES(?,?,?,?,?)', (uid, username, salt, digest, json.dumps(default_profile())))
        except sqlite3.IntegrityError: raise ServiceError('Commander name already exists', 409)
        return self.login(username, password)
    def login(self, username, password):
        if not isinstance(username, str) or not isinstance(password, str) or len(password) > 128: raise ServiceError('Invalid credentials', 401)
        with self.transaction() as db:
            row = db.execute('SELECT * FROM users WHERE username=?', (username,)).fetchone()
            salt = row['salt'] if row else '00' * 16
            digest = hashlib.pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 310000).hex()
            if row is None or not hmac.compare_digest(digest, row['password_hash']): raise ServiceError('Invalid credentials', 401)
            token = secrets.token_urlsafe(32)
            db.execute('DELETE FROM sessions WHERE expires<?', (time.time(),))
            db.execute('INSERT INTO sessions VALUES(?,?,?)', (hashlib.sha256(token.encode()).hexdigest(), row['id'], time.time() + 86400))
            return {'token': token, 'profile': self._profile(row)}
    def authenticate(self, token):
        digest = hashlib.sha256(token.encode()).hexdigest()
        with self.connect() as db:
            row = db.execute('SELECT user_id FROM sessions WHERE token_hash=? AND expires>?', (digest, time.time())).fetchone()
            if row is None: raise ServiceError('Sign in again', 401)
            return row['user_id']
    def me(self, uid):
        with self.connect() as db: return self._profile(self._user(db, uid))
    def public(self, username):
        with self.connect() as db:
            row = db.execute('SELECT * FROM users WHERE username=?', (username,)).fetchone()
            if not row: raise ServiceError('Commander not found', 404)
            p = self._profile(row)
            return {k: p[k] for k in ['commander_name', 'inventory', 'ship_classes', 'loadouts', 'battles', 'wins', 'total_kills', 'total_damage', 'discovery_records']}
    def ticket(self, uid):
        token = secrets.token_urlsafe(32)
        with self.transaction() as db:
            row = self._user(db, uid)
            self._unlocked(row)
            db.execute('DELETE FROM tickets WHERE user_id=? OR expires<?', (uid, time.time()))
            db.execute('INSERT INTO tickets VALUES(?,?,?)', (hashlib.sha256(token.encode()).hexdigest(), uid, time.time() + 60))
        return {'ticket': token}
    def resolve_ticket(self, token):
        with self.transaction() as db:
            digest = hashlib.sha256(str(token).encode()).hexdigest()
            row = db.execute('SELECT user_id FROM tickets WHERE ticket_hash=? AND expires>?', (digest, time.time())).fetchone()
            if not row: raise ServiceError('Invalid or expired game ticket', 401)
            db.execute('DELETE FROM tickets WHERE ticket_hash=?', (digest,))
            user = self._user(db, row['user_id'])
            self._unlocked(user)
            return self._profile(user)
    def equip(self, uid, index, slot, item, hull=None):
        if type(index) is not int or not 0 <= index < 3: raise ServiceError('Invalid fleet slot')
        with self.transaction() as db:
            row = self._user(db, uid); self._unlocked(row); p = self._profile(row)
            if hull is not None:
                if hull not in CLASS_NAMES or (hull not in DEFAULT_CLASSES and 'ship_' + hull not in p['inventory']): raise ServiceError('Hull not discovered')
                p['ship_classes'][index] = hull
                variant = ITEMS[p['loadouts'][index]['variant']]
                if variant['ship_class'] and variant['ship_class'] != CLASS_NAMES[hull]: p['loadouts'][index]['variant'] = 'variant_standard'
            else:
                definition = ITEMS.get(item)
                if slot == 'crew' and item == '': pass
                elif slot not in SLOTS or not definition or definition['slot'] != slot or item not in p['inventory']: raise ServiceError('Invalid or unowned fitting')
                elif definition['ship_class'] and definition['ship_class'] != CLASS_NAMES[p['ship_classes'][index]]: raise ServiceError('Wrong hull for this variant')
                if slot == 'crew' and item and any(i != index and fit['crew'] == item for i, fit in enumerate(p['loadouts'])): raise ServiceError('Crew is assigned to another ship')
                p['loadouts'][index][slot] = item
            self._save(db, uid, p)
            return p
    def research(self, uid, item):
        with self.transaction() as db:
            row = self._user(db, uid); self._unlocked(row); p = self._profile(row); definition = ITEMS.get(item)
            if not definition or definition['research_cost'] <= 0 or item in p['inventory']: raise ServiceError('Item cannot be researched')
            if p['salvage'] < definition['research_cost']: raise ServiceError('Not enough salvage')
            p['salvage'] -= definition['research_cost']; self._grant(p, item, 'Online research'); self._save(db, uid, p)
            return p
    def _grant(self, p, item, source):
        p.setdefault('discovery_records', {})
        p['discovery_records'].setdefault(item, {'discovered_at': int(time.time()), 'source': source})
        if item in p['inventory']: p['inventory'][item]['count'] += 1
        else: p['inventory'][item] = {'count': 1, 'discovered_at': int(time.time()), 'source': source}
    def _remove(self, p, item):
        entry = p['inventory'].get(item)
        if not entry: raise ServiceError('Item not owned')
        if entry['count'] == 1:
            if any(item in fit.values() for fit in p['loadouts']) or any(hull not in DEFAULT_CLASSES and 'ship_' + hull == item for hull in p['ship_classes']): raise ServiceError('Unequip this item before listing')
            del p['inventory'][item]
        else: entry['count'] -= 1
    def listings(self, uid):
        with self.connect() as db:
            rows = db.execute("SELECT l.*, u.username AS seller_name FROM listings l JOIN users u ON u.id=l.seller WHERE status='open' ORDER BY created DESC LIMIT 200").fetchall()
            return [dict(row) | {'mine': row['seller'] == uid} for row in rows]
    def list_item(self, uid, item, price):
        if type(price) is not int or not 1 <= price <= 1000000: raise ServiceError('Price must be 1–1000000 salvage')
        definition = ITEMS.get(item)
        if not definition or definition['starter']: raise ServiceError('Fleet-issued items cannot be traded')
        with self.transaction() as db:
            row = self._user(db, uid); self._unlocked(row); p = self._profile(row)
            if db.execute("SELECT count(*) FROM listings WHERE seller=? AND status='open'", (uid,)).fetchone()[0] >= 20: raise ServiceError('Listing limit reached')
            self._remove(p, item); self._save(db, uid, p)
            lid = secrets.token_hex(12)
            db.execute('INSERT INTO listings VALUES(?,?,?,?,?,?,?)', (lid, uid, item, price, 'open', None, time.time()))
            return {'listing_id': lid}
    def _listing(self, db, lid):
        row = db.execute("SELECT * FROM listings WHERE id=? AND status='open'", (lid,)).fetchone()
        if not row: raise ServiceError('Listing is no longer available', 409)
        return row
    def _refund_offers(self, db, lid, except_id=''):
        for offer in db.execute("SELECT * FROM offers WHERE listing=? AND status='open'", (lid,)).fetchall():
            if offer['id'] == except_id: continue
            p = self._profile(self._user(db, offer['buyer'])); p['salvage'] += offer['amount']; self._save(db, offer['buyer'], p)
            db.execute("UPDATE offers SET status='refunded' WHERE id=?", (offer['id'],))
    def buy(self, uid, lid):
        with self.transaction() as db:
            listing = self._listing(db, lid)
            if uid == listing['seller']: raise ServiceError('Cannot buy your own listing')
            buyer = self._user(db, uid); seller = self._user(db, listing['seller'])
            self._unlocked(buyer); self._unlocked(seller)
            self._refund_offers(db, lid)
            bp = self._profile(self._user(db, uid)); sp = self._profile(self._user(db, seller['id']))
            if bp['salvage'] < listing['price']: raise ServiceError('Not enough salvage')
            bp['salvage'] -= listing['price']; sp['salvage'] += listing['price']; self._grant(bp, listing['item'], 'Marketplace trade')
            self._save(db, uid, bp); self._save(db, seller['id'], sp)
            db.execute("UPDATE listings SET status='sold', buyer=? WHERE id=?", (uid, lid))
            return {'purchased': listing['item']}
    def cancel(self, uid, lid):
        with self.transaction() as db:
            listing = self._listing(db, lid)
            if listing['seller'] != uid: raise ServiceError('Not your listing', 403)
            row = self._user(db, uid); self._unlocked(row)
            self._refund_offers(db, lid)
            p = self._profile(self._user(db, uid)); self._grant(p, listing['item'], 'Cancelled listing'); self._save(db, uid, p)
            db.execute("UPDATE listings SET status='cancelled' WHERE id=?", (lid,))
            return {'cancelled': lid}
    def offer(self, uid, lid, amount):
        if type(amount) is not int or not 1 <= amount <= 1000000: raise ServiceError('Invalid offer amount')
        with self.transaction() as db:
            listing = self._listing(db, lid)
            if listing['seller'] == uid: raise ServiceError('Cannot offer on your own listing')
            row = self._user(db, uid); self._unlocked(row); p = self._profile(row)
            if db.execute("SELECT count(*) FROM offers WHERE buyer=? AND status='open'", (uid,)).fetchone()[0] >= 20: raise ServiceError('Offer limit reached')
            if p['salvage'] < amount: raise ServiceError('Not enough salvage')
            p['salvage'] -= amount; self._save(db, uid, p)
            oid = secrets.token_hex(12); db.execute('INSERT INTO offers VALUES(?,?,?,?,?)', (oid, lid, uid, amount, 'open'))
            return {'offer_id': oid}
    def offers(self, uid):
        with self.connect() as db:
            return [dict(row) for row in db.execute("SELECT o.*, l.seller, l.item, u.username AS buyer_name FROM offers o JOIN listings l ON l.id=o.listing JOIN users u ON u.id=o.buyer WHERE o.status='open' AND (o.buyer=? OR l.seller=?)", (uid, uid)).fetchall()]
    def resolve_offer(self, uid, oid, accept):
        with self.transaction() as db:
            offer = db.execute("SELECT * FROM offers WHERE id=? AND status='open'", (oid,)).fetchone()
            if not offer: raise ServiceError('Offer no longer available', 409)
            listing = self._listing(db, offer['listing'])
            if accept:
                if uid != listing['seller']: raise ServiceError('Only the seller can accept', 403)
                seller = self._user(db, uid); buyer = self._user(db, offer['buyer']); self._unlocked(seller); self._unlocked(buyer)
                self._refund_offers(db, listing['id'], oid)
                sp = self._profile(self._user(db, uid)); bp = self._profile(self._user(db, offer['buyer']))
                sp['salvage'] += offer['amount']; self._grant(bp, listing['item'], 'Accepted marketplace offer')
                self._save(db, uid, sp); self._save(db, offer['buyer'], bp)
                db.execute("UPDATE listings SET status='sold',buyer=? WHERE id=?", (offer['buyer'], listing['id']))
                db.execute("UPDATE offers SET status='accepted' WHERE id=?", (oid,))
            else:
                if uid not in [listing['seller'], offer['buyer']]: raise ServiceError('Not your offer', 403)
                bp = self._profile(self._user(db, offer['buyer'])); bp['salvage'] += offer['amount']; self._save(db, offer['buyer'], bp)
                db.execute("UPDATE offers SET status='refunded' WHERE id=?", (oid,))
            return {'resolved': oid}
    def start_match(self, mid, roster, mode="royale"):
        if mode not in ["royale", "free_roam"]: raise ServiceError("Unknown game mode")
        if not isinstance(mid, str) or not 1 <= len(mid) <= 100 or not isinstance(roster, list) or not 1 <= len(roster) <= 6: raise ServiceError('Invalid roster')
        users = [entry.get('user_id') for entry in roster]
        if len(set(users)) != len(users) or any(type(e.get('team')) is not int or e['team'] not in [0,1] for e in roster): raise ServiceError('Invalid teams')
        with self.transaction() as db:
            for uid in users: self._unlocked(self._user(db, uid))
            try: db.execute('INSERT INTO matches VALUES(?,?,?,?)', (mid, json.dumps(roster), 'live', time.time()))
            except sqlite3.IntegrityError: raise ServiceError('Match already exists', 409)
            if mode == 'free_roam': db.execute('INSERT INTO roam_sessions VALUES(?)', (mid,))
            for uid in users: db.execute('UPDATE users SET locked_until=?,active_match=? WHERE id=?', (time.time() + (120 if mode == 'free_roam' else 600), mid, uid))
            profiles = [self._profile(self._user(db, uid)) for uid in users]
        return {'started': mid, 'profiles': profiles}
    def finish_match(self, mid, winner, metrics):
        if winner not in [-1,0,1] or not isinstance(metrics, dict): raise ServiceError('Invalid results')
        prizes = {}
        with self.transaction() as db:
            match = db.execute('SELECT * FROM matches WHERE id=?', (mid,)).fetchone()
            if not match: raise ServiceError('Unknown match', 404)
            if db.execute('SELECT 1 FROM roam_sessions WHERE match_id=?', (mid,)).fetchone(): raise ServiceError('Use free-roam settlement for this session')
            if match['status'] != 'live': return {'already_settled': True}
            for entry in json.loads(match['roster']):
                uid = entry['user_id']; p = self._profile(self._user(db, uid)); won = winner == entry['team']
                p['battles'] += 1; p['wins'] += int(won); p['salvage'] += 60 if won else 30
                record = metrics.get(uid, {})
                p['total_kills'] += max(0, min(1000, int(record.get('kills', 0))))
                p['total_damage'] += max(0, min(1000000, float(record.get('damage', 0))))
                if won:
                    prizes[uid] = "ship_" + secrets.choice(list(CLASS_NAMES))
                    self._grant(p, prizes[uid], "Victory ship — permanent ownership")
                for _ in range(2 if won else 1):
                    tier = rarity_for_ticket(secrets.randbelow(16384))
                    item = secrets.choice([x for x in CATALOG if x['rarity'] == tier])['id']
                    duplicate = item in p['inventory']; self._grant(p, item, 'Authoritative online battle')
                    if duplicate: p['salvage'] += 15
                self._save(db, uid, p); db.execute("UPDATE users SET locked_until=0,active_match='' WHERE id=? AND active_match=?", (uid, mid))
            db.execute("UPDATE matches SET status='settled' WHERE id=?", (mid,))
        return {'settled': mid, 'victory_ships': prizes}

    def _roam_match(self, db, mid):
        row = db.execute('SELECT m.* FROM matches m JOIN roam_sessions r ON r.match_id=m.id WHERE m.id=?', (mid,)).fetchone()
        if not row or row['status'] != 'live': raise ServiceError('Free-roam session is not active', 409)
        return row
    def roam_join(self, mid, uid, team):
        if type(team) is not int or team not in [0,1]: raise ServiceError('Invalid team')
        with self.transaction() as db:
            row = self._roam_match(db, mid)
            roster = json.loads(row['roster'])
            if len(roster) >= 6 or any(e['user_id'] == uid for e in roster): raise ServiceError('Session is full or account already joined', 409)
            user = self._user(db,uid); self._unlocked(user)
            roster.append({'user_id':uid,'team':team})
            db.execute('UPDATE matches SET roster=? WHERE id=?', (json.dumps(roster),mid))
            db.execute('UPDATE users SET locked_until=?,active_match=? WHERE id=?', (time.time()+120,mid,uid))
            p = self._profile(self._user(db,uid))
        return {'profile':p}
    def roam_lease(self, mid):
        with self.transaction() as db:
            row = self._roam_match(db, mid)
            for member in json.loads(row['roster']):
                db.execute('UPDATE users SET locked_until=? WHERE id=? AND active_match=?', (time.time()+120, member['user_id'], mid))
        return {'renewed': mid}
    def roam_reward(self, mid, event_id, uid, damage):
        if not isinstance(event_id, str) or not 1 <= len(event_id) <= 150: raise ServiceError('Invalid encounter receipt')
        if type(damage) not in [int,float] or not 0 <= damage <= 1000000: raise ServiceError('Invalid damage')
        with self.transaction() as db:
            session = self._roam_match(db, mid)
            if uid not in [e['user_id'] for e in json.loads(session['roster'])]: raise ServiceError('Pilot is not in this session', 403)
            user = self._user(db, uid)
            if user['active_match'] != mid: raise ServiceError('Pilot has left this session', 409)
            receipt = db.execute('SELECT * FROM roam_receipts WHERE event_id=?', (event_id,)).fetchone()
            if receipt:
                if receipt['match_id'] != mid or receipt['user_id'] != uid: raise ServiceError('Receipt belongs to another encounter', 409)
                return {'already_settled': True, 'ship': receipt['ship']}
            p = self._profile(user)
            prize = 'ship_' + secrets.choice(list(CLASS_NAMES))
            self._grant(p, prize, 'Free-roam encounter victory — permanent ownership')
            p['battles'] += 1; p['wins'] += 1; p['total_kills'] += 1
            p['total_damage'] += damage; p['salvage'] += 60
            for _ in range(2):
                tier = rarity_for_ticket(secrets.randbelow(16384))
                item = secrets.choice([x for x in CATALOG if x['rarity'] == tier])['id']
                duplicate = item in p['inventory']; self._grant(p, item, 'Free-roam encounter discovery')
                if duplicate: p['salvage'] += 15
            self._save(db, uid, p)
            db.execute('INSERT INTO roam_receipts VALUES(?,?,?,?,?)', (event_id,mid,uid,prize,time.time()))
        return {'ship': prize, 'settled': event_id}
    def roam_leave(self, mid, uid):
        with self.transaction() as db:
            row = self._roam_match(db, mid)
            roster = [e for e in json.loads(row['roster']) if e['user_id'] != uid]
            db.execute('UPDATE matches SET roster=? WHERE id=?', (json.dumps(roster),mid))
            db.execute("UPDATE users SET locked_until=0,active_match='' WHERE id=? AND active_match=?", (uid,mid))
        return {'left': uid}
    def roam_end(self, mid):
        with self.transaction() as db:
            row = db.execute('SELECT m.* FROM matches m JOIN roam_sessions r ON r.match_id=m.id WHERE m.id=?', (mid,)).fetchone()
            if not row: raise ServiceError('Unknown free-roam session', 404)
            if row['status'] != 'live': return {'already_closed': True}
            for entry in json.loads(row['roster']):
                db.execute("UPDATE users SET locked_until=0,active_match='' WHERE id=? AND active_match=?", (entry['user_id'],mid))
            db.execute("UPDATE matches SET status='closed' WHERE id=?", (mid,))
        return {'closed': mid}

class Handler(BaseHTTPRequestHandler):
    server_version = 'GalacticDominion/0.5'
    def log_message(self, *_): pass
    def do_GET(self): self.handle_api('GET')
    def do_POST(self): self.handle_api('POST')
    def handle_api(self, method):
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if length < 0 or length > 65536: raise ServiceError('Request too large', 413)
            data = json.loads(self.rfile.read(length)) if length else {}
            if not isinstance(data, dict): raise ServiceError('Expected a JSON object')
            url = urlparse(self.path); path = url.path; store = self.server.store
            if method == 'GET' and path == '/health': result = {'ok': True, 'version': '0.5.0'}
            elif method == 'GET' and path == '/profiles': result = store.public(parse_qs(url.query).get('name', [''])[0])
            elif method == 'GET' and path == '/catalog': result = CATALOG
            elif method == 'POST' and path in ['/register','/login']:
                ip = self.client_address[0]; now = time.time()
                with self.server.rate_lock:
                    hits = [t for t in self.server.rate.get(ip, []) if now - t < 60]
                    if len(hits) >= 20: raise ServiceError('Too many sign-in attempts; wait a minute', 429)
                    self.server.rate[ip] = hits + [now]
                result = (store.register if path == '/register' else store.login)(data.get('username'), data.get('password'))
            elif path.startswith('/server/'):
                key = self.headers.get('X-Galactic-Server-Key', '')
                if not key or not hmac.compare_digest(key, store.server_key): raise ServiceError('Combat server authentication required', 403)
                if method != 'POST': raise ServiceError('Use POST', 405)
                if path == '/server/ticket': result = store.resolve_ticket(data.get('ticket', ''))
                elif path == '/server/start': result = store.start_match(data.get('match_id'), data.get('roster'), data.get('mode', 'royale'))
                elif path == '/server/roam/join': result = store.roam_join(data.get('match_id'), data.get('user_id'), data.get('team'))
                elif path == '/server/roam/lease': result = store.roam_lease(data.get('match_id'))
                elif path == '/server/roam/reward': result = store.roam_reward(data.get('match_id'), data.get('event_id'), data.get('user_id'), data.get('damage',0))
                elif path == '/server/roam/leave': result = store.roam_leave(data.get('match_id'), data.get('user_id'))
                elif path == '/server/roam/end': result = store.roam_end(data.get('match_id'))
                elif path == '/server/finish': result = store.finish_match(data.get('match_id'), data.get('winner'), data.get('metrics', {}))
                else: raise ServiceError('Not found', 404)
            else:
                auth = self.headers.get('Authorization', '')
                uid = store.authenticate(auth[7:] if auth.startswith('Bearer ') else '')
                if method == 'GET' and path == '/me': result = store.me(uid)
                elif method == 'POST' and path == '/ticket': result = store.ticket(uid)
                elif method == 'POST' and path == '/equip': result = store.equip(uid, data.get('index'), data.get('slot'), data.get('item'), data.get('hull'))
                elif method == 'POST' and path == '/research': result = store.research(uid, data.get('item'))
                elif method == 'GET' and path == '/market': result = store.listings(uid)
                elif method == 'POST' and path == '/market/list': result = store.list_item(uid, data.get('item'), data.get('price'))
                elif method == 'POST' and path == '/market/buy': result = store.buy(uid, data.get('listing'))
                elif method == 'POST' and path == '/market/cancel': result = store.cancel(uid, data.get('listing'))
                elif method == 'GET' and path == '/offers': result = store.offers(uid)
                elif method == 'POST' and path == '/offers/create': result = store.offer(uid, data.get('listing'), data.get('amount'))
                elif method == 'POST' and path == '/offers/accept': result = store.resolve_offer(uid, data.get('offer'), True)
                elif method == 'POST' and path == '/offers/cancel': result = store.resolve_offer(uid, data.get('offer'), False)
                else: raise ServiceError('Not found', 404)
            self.respond(200, result)
        except ServiceError as exc: self.respond(exc.status, {'error': exc.message})
        except (ValueError, TypeError, KeyError): self.respond(400, {'error': 'Invalid request data'})
        except Exception: self.respond(500, {'error': 'Server operation failed'})
    def respond(self, status, data):
        raw = json.dumps(data, allow_nan=False).encode()
        self.send_response(status); self.send_header('Content-Type', 'application/json'); self.send_header('Content-Length', str(len(raw))); self.send_header('Cache-Control', 'no-store'); self.end_headers(); self.wfile.write(raw)

def make_server(store, host, port):
    import threading
    httpd = ThreadingHTTPServer((host, port), Handler)
    httpd.store = store; httpd.rate = {}; httpd.rate_lock = threading.Lock()
    return httpd

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--host', default='127.0.0.1'); parser.add_argument('--port', type=int, default=8080); parser.add_argument('--data', default='server-data')
    args = parser.parse_args(); data = Path(args.data); data.mkdir(parents=True, exist_ok=True)
    key_path = data / 'combat-server.key'
    if not key_path.exists(): key_path.write_text(secrets.token_urlsafe(48)); key_path.chmod(0o600)
    key = os.environ.get('GD_SERVER_KEY') or key_path.read_text().strip()
    store = Store(data / 'galaxy.sqlite3', key)
    print(f'Galactic Dominion account service listening on {args.host}:{args.port}', flush=True)
    make_server(store, args.host, args.port).serve_forever()
if __name__ == '__main__': main()
