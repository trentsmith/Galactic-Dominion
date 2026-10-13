import concurrent.futures
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'server'))
from service import Store, ServiceError, ITEMS

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
    def test_public_profile_excludes_secrets(self):
        p=self.store.public('Pilot_A')
        self.assertNotIn('password_hash',p); self.assertNotIn('token',p); self.assertNotIn('user_id',p)
        self.assertIn('loadouts',p); self.assertIn('discovery_records',p)

if __name__=='__main__': unittest.main(verbosity=2)
