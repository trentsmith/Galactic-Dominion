import concurrent.futures
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'server'))
from service import Store, ServiceError, ITEMS, rarity_for_ticket

class AccountMarketTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.store=Store(Path(self.tmp.name)/'test.sqlite3','test-only-key')
        self.a=self.store.register('Pilot_A','test-password-a')['profile']['user_id']
        self.b=self.store.register('Pilot_B','test-password-b')['profile']['user_id']
    def tearDown(self): self.tmp.cleanup()
    def test_password_and_session(self):
        with self.assertRaises(ServiceError): self.store.login('Pilot_A','wrong-password')
        reply=self.store.login('Pilot_A','test-password-a')
        self.assertEqual(self.store.authenticate(reply['token']),self.a)
        with self.store.connect() as db:
            self.assertNotEqual(db.execute('SELECT password_hash FROM users WHERE id=?',(self.a,)).fetchone()[0],'test-password-a')
        with self.assertRaises(ServiceError): self.store.authenticate('invalid-token')
    def test_unique_names_and_validation(self):
        with self.assertRaises(ServiceError): self.store.register('pilot_a','test-password-c')
        with self.assertRaises(ServiceError): self.store.register('bad name','test-password-c')
        with self.assertRaises(ServiceError): self.store.register('Pilot_C','short')
    def test_ticket_consumed_once(self):
        ticket=self.store.ticket(self.a)['ticket']
        self.assertEqual(self.store.resolve_ticket(ticket)['user_id'],self.a)
        with self.assertRaises(ServiceError): self.store.resolve_ticket(ticket)
    def test_listing_escrow_and_buy(self):
        lid=self.store.list_item(self.a,'engine_sprint',75)['listing_id']
        self.assertNotIn('engine_sprint',self.store.me(self.a)['inventory'])
        self.store.buy(self.b,lid)
        self.assertEqual(self.store.me(self.a)['salvage'],275)
        self.assertEqual(self.store.me(self.b)['salvage'],125)
        self.assertEqual(self.store.me(self.b)['inventory']['engine_sprint']['count'],2)
        with self.assertRaises(ServiceError): self.store.buy(self.b,lid)
        self.assertIn('engine_sprint',self.store.public('Pilot_A')['discovery_records'])
    def test_cancel_refunds_item(self):
        lid=self.store.list_item(self.a,'engine_sprint',75)['listing_id']
        self.store.cancel(self.a,lid)
        self.assertIn('engine_sprint',self.store.me(self.a)['inventory'])
    def test_no_self_trade_or_unauthorized_cancel(self):
        lid=self.store.list_item(self.a,'engine_sprint',75)['listing_id']
        with self.assertRaises(ServiceError): self.store.buy(self.a,lid)
        with self.assertRaises(ServiceError): self.store.cancel(self.b,lid)
    def test_equipped_and_issued_items_cannot_be_listed(self):
        self.store.equip(self.a,0,'engine','engine_sprint')
        with self.assertRaises(ServiceError): self.store.list_item(self.a,'engine_sprint',10)
        with self.assertRaises(ServiceError): self.store.list_item(self.a,'engine_standard',10)
    def test_offers_escrow_accept_and_refund(self):
        lid=self.store.list_item(self.a,'engine_sprint',100)['listing_id']
        offer=self.store.offer(self.b,lid,60)['offer_id']
        self.assertEqual(self.store.me(self.b)['salvage'],140)
        self.store.resolve_offer(self.a,offer,True)
        self.assertEqual(self.store.me(self.a)['salvage'],260)
        self.assertEqual(self.store.me(self.b)['salvage'],140)
        with self.assertRaises(ServiceError): self.store.resolve_offer(self.a,offer,True)
    def test_offers_refunded_on_cancel_or_buy(self):
        lid=self.store.list_item(self.a,'engine_sprint',100)['listing_id']
        self.store.offer(self.b,lid,60)
        self.store.cancel(self.a,lid)
        self.assertEqual(self.store.me(self.b)['salvage'],200)
        lid=self.store.list_item(self.a,'engine_sprint',100)['listing_id']
        self.store.offer(self.b,lid,60)
        self.store.buy(self.b,lid)
        self.assertEqual(self.store.me(self.b)['salvage'],100)
    def test_insufficient_funds_rolls_back(self):
        lid=self.store.list_item(self.a,'engine_sprint',1000)['listing_id']
        with self.assertRaises(ServiceError): self.store.buy(self.b,lid)
        self.assertEqual(self.store.me(self.a)['salvage'],200)
        self.assertEqual(self.store.me(self.b)['salvage'],200)
        self.assertEqual(len(self.store.listings(self.a)),1)
    def test_simultaneous_purchase_only_succeeds_once(self):
        c=self.store.register('Pilot_C','test-password-c')['profile']['user_id']
        lid=self.store.list_item(self.a,'engine_sprint',90)['listing_id']
        def purchase(uid):
            try: self.store.buy(uid,lid); return True
            except ServiceError: return False
        with concurrent.futures.ThreadPoolExecutor(2) as pool: results=list(pool.map(purchase,[self.b,c]))
        self.assertEqual(sum(results),1)
        self.assertEqual(self.store.me(self.a)['salvage'],290)
        self.assertEqual(sum(self.store.me(uid)['salvage'] for uid in [self.b,c]),310)
    def test_research_and_fitting_rules(self):
        with self.assertRaises(ServiceError): self.store.equip(self.a,0,'engine','weapon_swarm')
        with self.assertRaises(ServiceError): self.store.equip(self.a,0,'crew','crew_milo')
        self.store.research(self.a,'weapon_lance')
        self.assertEqual(self.store.me(self.a)['salvage'],10)
        self.store.equip(self.a,0,'weapon','weapon_lance')
        with self.assertRaises(ServiceError): self.store.research(self.a,'variant_void')
    def test_all_liveries_and_companions_fit_every_class(self):
        from service import CLASS_NAMES
        variants=[item for item,definition in ITEMS.items() if definition['kind']=='variant']
        crews=[item for item,definition in ITEMS.items() if definition['kind']=='crew']
        with self.store.transaction() as db:
            p=self.store._profile(self.store._user(db,self.a))
            for item in variants+crews+['ship_bomber','ship_support']:
                self.store._grant(p,item,'Test fixture')
            p['loadouts'][1]['crew']='';p['loadouts'][2]['crew']=''
            self.store._save(db,self.a,p)
        for hull in CLASS_NAMES:
            self.store.equip(self.a,0,None,None,hull=hull)
            for item in variants:
                p=self.store.equip(self.a,0,'variant',item)
                self.assertEqual(p['loadouts'][0]['variant'],item)
                self.assertEqual(p['ship_classes'][0],hull)
            for item in crews:
                p=self.store.equip(self.a,0,'crew',item)
                self.assertEqual(p['loadouts'][0]['crew'],item)
        self.store.equip(self.a,0,'variant','variant_orbitot')
        p=self.store.equip(self.a,0,None,None,hull='guardian')
        self.assertEqual(p['loadouts'][0]['variant'],'variant_orbitot')
        self.assertEqual(self.store.me(self.a)['loadouts'][0]['variant'],'variant_orbitot')
        with self.assertRaises(ServiceError):self.store.equip(self.b,0,'variant','variant_glimbloom')

    def test_authoritative_rewards_and_match_lock(self):
        self.store.start_match('match-a',[{'user_id':self.a,'team':0},{'user_id':self.b,'team':1}])
        with self.assertRaises(ServiceError): self.store.list_item(self.a,'engine_sprint',10)
        with self.assertRaises(ServiceError): self.store.equip(self.a,0,'engine','engine_sprint')
        self.store.finish_match('match-a',0,{self.a:{'kills':2,'damage':300}})
        a=self.store.me(self.a); b=self.store.me(self.b)
        self.assertEqual((a['battles'],a['wins'],a['total_kills']),(1,1,2))
        self.assertEqual((b['battles'],b['wins']),(1,0))
        self.assertTrue(self.store.finish_match('match-a',0,{})['already_settled'])
        self.assertEqual(self.store.me(self.a)['battles'],1)
        self.store.equip(self.a,0,'engine','engine_sprint')
    def test_victory_ship_is_permanent_and_tradable(self):
        with patch('service.secrets.choice', side_effect=lambda pool: pool[0]), patch('service.secrets.randbelow', return_value=5000):
            for mid in ['prize-one', 'prize-two']:
                self.store.start_match(mid,[{'user_id':self.a,'team':0},{'user_id':self.b,'team':1}])
                self.store.finish_match(mid,0,{})
        self.assertEqual(self.store.me(self.a)['inventory']['ship_interceptor']['count'],2)
        self.assertFalse(any(k.startswith('ship_') for k in self.store.me(self.b)['inventory']))
        before=self.store.me(self.a)
        self.store.finish_match('prize-two',0,{})
        self.assertEqual(self.store.me(self.a),before)
        reopened=Store(self.store.path,'test-only-key')
        self.assertEqual(reopened.me(self.a)['inventory']['ship_interceptor']['count'],2)
        for _ in range(2):
            lid=self.store.list_item(self.a,'ship_interceptor',10)['listing_id']
            self.store.buy(self.b,lid)
        self.assertNotIn('ship_interceptor',self.store.me(self.a)['inventory'])
        self.assertEqual(self.store.me(self.b)['inventory']['ship_interceptor']['count'],2)
        self.store.equip(self.b,0,None,None,hull='interceptor')
    def test_exact_rarity_distribution_matches_client(self):
        counts={tier:0 for tier in ['mythic','legendary','rare','uncommon','common']}
        for ticket in range(16384): counts[rarity_for_ticket(ticket)]+=1
        self.assertEqual(counts,dict(mythic=1,legendary=4,rare=819,uncommon=3932,common=11628))
        source=(Path(__file__).resolve().parents[1]/'scripts/progression/collection_catalog.gd').read_text()
        for boundary in ['ticket == 0','ticket < 5','ticket < 824','ticket < 4756']:
            self.assertIn(boundary,source)
        self.assertTrue(all(x['research_cost']==0 for x in ITEMS.values() if x['rarity'] in ['legendary','mythic']))
    def test_free_roam_receipts_persist_and_cannot_pay_twice(self):
        self.store.start_match('roam',[{'user_id':self.a,'team':0}],mode='free_roam')
        self.store.roam_lease('roam')
        reward=self.store.roam_reward('roam','kill-one',self.a,90)
        self.assertIn(reward['ship'],self.store.me(self.a)['inventory'])
        before=self.store.me(self.a)
        reopened=Store(self.store.path,'test-only-key')
        self.assertTrue(reopened.roam_reward('roam','kill-one',self.a,90)['already_settled'])
        self.assertEqual(before,reopened.me(self.a))
        self.assertEqual((before['wins'],before['battles'],before['total_kills'],before['total_damage']),(1,1,1,90))
        with self.assertRaises(ServiceError): self.store.list_item(self.a,'engine_sprint',10)
        self.store.roam_end('roam')
        self.store.list_item(self.a,'engine_sprint',10)
        with self.assertRaises(ServiceError): self.store.roam_reward('roam','kill-two',self.a,10)
        self.assertTrue(self.store.roam_end('roam')['already_closed'])
    def test_free_roam_drop_in_leave_and_leases(self):
        self.store.start_match('roam',[{'user_id':self.a,'team':0}],mode='free_roam')
        joined=self.store.roam_join('roam',self.b,1)
        self.assertEqual(joined['profile']['user_id'],self.b)
        with self.assertRaises(ServiceError): self.store.roam_join('roam',self.b,1)
        with self.store.connect() as db:
            db.execute('UPDATE users SET locked_until=0 WHERE id=?',(self.b,))
        self.store.roam_lease('roam')
        with self.assertRaises(ServiceError): self.store.equip(self.b,0,'engine','engine_sprint')
        self.store.roam_leave('roam',self.b)
        self.store.equip(self.b,0,'engine','engine_sprint')
        with self.assertRaises(ServiceError): self.store.roam_reward('roam','kill-one',self.b,10)
        self.store.roam_join('roam',self.b,1)
        self.store.roam_end('roam')
        self.assertEqual(self.store.me(self.b)['battles'],0)
    def test_free_roam_rejects_invalid_rewards_and_royale_mixups(self):
        self.store.start_match('roam',[{'user_id':self.a,'team':0}],mode='free_roam')
        with self.assertRaises(ServiceError): self.store.finish_match('roam',0,{})
        with self.assertRaises(ServiceError): self.store.roam_reward('roam','one',self.b,10)
        with self.assertRaises(ServiceError): self.store.roam_reward('roam','one',self.a,float('nan'))
        with self.assertRaises(ServiceError): self.store.roam_reward('roam','',self.a,10)
        self.store.roam_end('roam')
        self.store.start_match('royale',[{'user_id':self.a,'team':0}])
        with self.assertRaises(ServiceError): self.store.roam_reward('royale','one',self.a,10)
        with self.assertRaises(ServiceError): self.store.start_match('other',[{'user_id':self.b,'team':1}],mode='unknown')
    def test_expired_roam_cannot_unlock_or_reward_a_new_session(self):
        self.store.start_match('old-roam',[{'user_id':self.a,'team':0}],mode='free_roam')
        with self.store.connect() as db: db.execute('UPDATE users SET locked_until=0 WHERE id=?',(self.a,))
        self.store.start_match('new-match',[{'user_id':self.a,'team':0}])
        self.store.roam_lease('old-roam')
        with self.assertRaises(ServiceError): self.store.roam_reward('old-roam','one',self.a,10)
        self.store.roam_end('old-roam')
        with self.assertRaises(ServiceError): self.store.equip(self.a,0,'engine','engine_sprint')
    def test_existing_database_migrates_without_losing_inventory(self):
        import sqlite3
        path=Path(self.tmp.name)/'legacy.sqlite3'
        with sqlite3.connect(path) as db:
            db.execute('CREATE TABLE users(id TEXT PRIMARY KEY,username TEXT UNIQUE,salt TEXT,password_hash TEXT,profile TEXT,locked_until REAL DEFAULT 0)')
            db.execute('INSERT INTO users VALUES(?,?,?,?,?,?)',('legacy','Legacy','salt','hash',json.dumps(self.store.me(self.a)),0))
        migrated=Store(path,'test-only-key')
        self.assertEqual(migrated.me('legacy')['inventory'],self.store.me(self.a)['inventory'])
        with migrated.connect() as db: self.assertIn('active_match',[r['name'] for r in db.execute('PRAGMA table_info(users)')])
    def test_public_profile_excludes_secrets(self):
        p=self.store.public('Pilot_A')
        self.assertNotIn('password_hash',p); self.assertNotIn('token',p); self.assertNotIn('user_id',p)
        self.assertIn('loadouts',p); self.assertIn('discovery_records',p)

if __name__=='__main__': unittest.main(verbosity=2)
