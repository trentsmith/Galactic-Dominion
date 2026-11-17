import concurrent.futures
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'server'))
from service import Store, ServiceError

class FrontierServiceTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.store=Store(Path(self.tmp.name)/'accounts.sqlite3','test-frontier-key')
        self.a=self.store.register('Front_A','frontier-test-password')['profile']['user_id']
        self.b=self.store.register('Front_B','frontier-test-password')['profile']['user_id']
        self.store.start_match('coop',[{'user_id':self.a,'team':0},{'user_id':self.b,'team':0}],'co_op')
    def tearDown(self):self.tmp.cleanup()
    def test_atomic_individual_rewards_and_duplicate_retry(self):
        reward=lambda:self.store.frontier_reward('coop','shared-1','repair',[self.a,self.b])
        with concurrent.futures.ThreadPoolExecutor(4) as pool: results=list(pool.map(lambda _:reward(),range(4)))
        self.assertEqual(sum('settled' in item for item in results),1)
        for uid in [self.a,self.b]:
            p=self.store.me(uid);self.assertEqual(p['salvage'],260);self.assertEqual(p['frontier'],{'completed':1,'reputation':8})
        self.assertNotIn('ship_interceptor',self.store.me(self.a)['inventory'])
    def test_reused_receipt_cannot_change_participants_or_kind(self):
        self.store.frontier_reward('coop','shared-1','rescue',[self.a])
        with self.assertRaises(ServiceError):self.store.frontier_reward('coop','shared-1','repair',[self.a])
        with self.assertRaises(ServiceError):self.store.frontier_reward('coop','shared-1','rescue',[self.a,self.b])
        self.assertEqual(self.store.me(self.b)['salvage'],200)
    def test_outsider_and_invalid_payloads_are_rejected(self):
        outsider=self.store.register('Other_Pilot','frontier-test-password')['profile']['user_id']
        for args in [('shared-1','repair',[self.a,outsider]),('shared-2','mythic',[self.a]),('bad','repair',[self.a]),('shared-3','repair',[]),('shared-4','repair',[self.a,self.a])]:
            with self.assertRaises(ServiceError):self.store.frontier_reward('coop',*args)
        self.assertEqual(self.store.me(self.a)['salvage'],200)
    def test_left_or_closed_session_does_not_grant_new_rewards(self):
        self.store.roam_leave('coop',self.b)
        with self.assertRaises(ServiceError):self.store.frontier_reward('coop','shared-1','escort',[self.a,self.b])
        self.assertEqual(self.store.me(self.a)['salvage'],200)
        self.store.roam_end('coop')
        with self.assertRaises(ServiceError):self.store.frontier_reward('coop','shared-2','repair',[self.a])
    def test_completed_receipt_can_be_retried_after_departure_and_closure(self):
        self.store.frontier_reward('coop','shared-1','repair',[self.a,self.b])
        self.store.roam_leave('coop',self.b);self.store.roam_end('coop')
        self.assertTrue(self.store.frontier_reward('coop','shared-1','repair',[self.b,self.a])['already_settled'])
        self.assertEqual(self.store.me(self.a)['salvage'],260)
        self.assertEqual(self.store.me(self.b)['salvage'],260)
        with self.assertRaises(ServiceError):self.store.frontier_reward('coop','shared-1','escort',[self.a,self.b])
    def test_delayed_leave_retry_cannot_unlock_a_new_match(self):
        self.store.roam_leave('coop',self.a);self.store.roam_end('coop')
        self.store.start_match('next',[{'user_id':self.a,'team':0}])
        self.store.roam_leave('coop',self.a)
        with self.store.connect() as db:self.assertEqual(self.store._user(db,self.a)['active_match'],'next')
        with self.assertRaises(ServiceError):self.store.equip(self.a,0,'engine','engine_sprint')
    def test_invalid_job_kind_is_a_validation_error(self):
        for kind in [{},[],None,123]:
            with self.assertRaises(ServiceError):self.store.frontier_reward('coop','shared-1',kind,[self.a])

if __name__=='__main__':unittest.main()
