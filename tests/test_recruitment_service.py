"""Permanent fleet ownership, transactional recruitment and duel settlement."""
import concurrent.futures
from copy import deepcopy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'server'))
from service import Store, ServiceError, FLEET_CAP, default_profile


class RecruitmentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = Store(Path(self.tmp.name) / 'fleet.sqlite3', 'test-only-key')
        self.a = self.store.register('Commander_A', 'test-password-a')['profile']['user_id']
        self.b = self.store.register('Commander_B', 'test-password-b')['profile']['user_id']

    def tearDown(self):
        self.tmp.cleanup()

    def test_old_profile_migrates_without_losing_any_fittings_or_progress(self):
        old = default_profile()
        old['ship_classes'] = ['bomber', 'support', 'guardian']
        old['loadouts'][0]['engine'] = 'engine_sprint'
        old.update(salvage=973, wins=7, battles=12)
        with self.store.connect() as db:
            db.execute('UPDATE users SET profile=? WHERE id=?', (json.dumps(old), self.a))
        profile = self.store.me(self.a)
        self.assertEqual(profile['version'], 2)
        for key in ['inventory', 'ship_classes', 'loadouts', 'salvage', 'wins', 'battles']:
            self.assertEqual(profile[key], old[key])
        self.assertEqual(len(set(profile['active_ships'])), 3)
        self.assertEqual(profile, self.store.me(self.a))  # stable IDs before first write
        self.store.equip(self.a, 0, 'shield', 'shield_bulwark')
        reopened = Store(self.store.path, 'test-only-key').me(self.a)
        self.assertEqual(reopened['fleet_roster'][0]['loadout']['engine'], 'engine_sprint')

    def test_recruitment_cost_and_idempotency_survive_service_restart(self):
        before = self.store.me(self.a)
        first = self.store.recruit(self.a, 'siegebreaker', 'request-00000001')
        profile = first['profile']
        self.assertEqual((profile['salvage'], len(profile['fleet_roster'])), (20, 4))
        self.assertEqual(profile['active_ships'], before['active_ships'])
        ship = profile['fleet_roster'][-1]
        self.assertEqual((ship['id'], ship['hull'], ship['loadout']['crew']), (first['ship_id'], 'bomber', ''))
        reopened = Store(self.store.path, 'test-only-key')
        replay = reopened.recruit(self.a, 'siegebreaker', 'request-00000001')
        self.assertTrue(replay['already_recruited'])
        self.assertEqual(replay['profile'], profile)
        with self.assertRaises(ServiceError): reopened.recruit(self.a, 'tender', 'request-00000001')

    def test_simultaneous_retry_charges_once(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            replies = list(pool.map(lambda _: self.store.recruit(self.a, 'dart', 'request-00000002'), range(4)))
        self.assertEqual(len({r['ship_id'] for r in replies}), 1)
        self.assertEqual(self.store.me(self.a)['salvage'], 100)
        self.assertEqual(len(self.store.me(self.a)['fleet_roster']), 4)

    def test_simultaneous_distinct_orders_cannot_overspend(self):
        def hire(i):
            try: return self.store.recruit(self.a, 'siegebreaker', f'concurrent-{i:016}')
            except ServiceError: return None
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            replies = list(pool.map(hire, range(4)))
        self.assertEqual(sum(r is not None for r in replies), 1)
        self.assertEqual(self.store.me(self.a)['salvage'], 20)

    def test_invalid_or_unaffordable_recruitment_is_atomic(self):
        before = self.store.me(self.a)
        for offer, rid in [('missing', 'request-00000003'), ('dart', 'short'), (None, 'request-00000004')]:
            with self.assertRaises(ServiceError): self.store.recruit(self.a, offer, rid)
        self.assertEqual(self.store.me(self.a), before)
        self.store.recruit(self.a, 'siegebreaker', 'request-00000005')
        before = self.store.me(self.a)
        with self.assertRaises(ServiceError): self.store.recruit(self.a, 'tender', 'request-00000006')
        self.assertEqual(self.store.me(self.a), before)

    def test_reserve_capacity_is_enforced_without_debit(self):
        with self.store.transaction() as db:
            p = self.store._profile(self.store._user(db, self.a))
            template = p['fleet_roster'][0]
            for i in range(3, FLEET_CAP):
                ship = deepcopy(template); ship['id'] = f'fixture-{i}'
                p['fleet_roster'].append(ship)
            self.store._save(db, self.a, p)
        before = self.store.me(self.a)
        with self.assertRaisesRegex(ServiceError, 'full'): self.store.recruit(self.a, 'dart', 'request-00000007')
        self.assertEqual(self.store.me(self.a), before)

    def test_deploy_checks_ownership_uniqueness_and_preserves_fittings(self):
        ship_id = self.store.recruit(self.a, 'siegebreaker', 'request-00000008')['ship_id']
        starter = self.store.me(self.a)['active_ships'][0]
        self.store.equip(self.a, 0, 'engine', 'engine_sprint')
        profile = self.store.deploy(self.a, 0, ship_id)
        self.assertEqual(profile['ship_classes'], ['bomber', 'skirmisher', 'guardian'])
        self.assertEqual(profile['loadouts'][0]['engine'], 'engine_standard')
        self.assertEqual(self.store.deploy(self.a, 0, ship_id), profile)
        with self.assertRaises(ServiceError): self.store.deploy(self.a, 1, ship_id)
        with self.assertRaises(ServiceError): self.store.deploy(self.b, 0, ship_id)
        with self.assertRaises(ServiceError): self.store.deploy(self.a, True, starter)
        profile = self.store.deploy(self.a, 0, starter)
        self.assertEqual(profile['loadouts'][0]['engine'], 'engine_sprint')
        # A reserve fitting cannot be sold from under an owned vessel.
        self.store.deploy(self.a, 0, ship_id)
        with self.assertRaisesRegex(ServiceError, 'reserve'): self.store.list_item(self.a, 'engine_sprint', 10)

    def test_duplicate_active_crew_is_refused_clearly(self):
        ship_id = self.store.recruit(self.a, 'dart', 'request-00000009')['ship_id']
        starter = self.store.me(self.a)['active_ships'][0]
        self.store.deploy(self.a, 0, ship_id)
        self.store.equip(self.a, 0, 'crew', 'crew_astra')
        with self.assertRaisesRegex(ServiceError, 'crew'): self.store.deploy(self.a, 1, starter)
        self.store.equip(self.a, 0, 'crew', '')
        profile = self.store.deploy(self.a, 1, starter)
        self.assertEqual(profile['loadouts'][1]['crew'], 'crew_astra')

    def test_commission_consumes_one_blueprint_and_retries_do_not_duplicate(self):
        with self.store.transaction() as db:
            p = self.store._profile(self.store._user(db, self.a))
            self.store._grant(p, 'ship_support', 'Test battle prize')
            self.store._save(db, self.a, p)
        result = self.store.recruit(self.a, 'ship_support', 'request-00000010', commission=True)
        self.assertNotIn('ship_support', result['profile']['inventory'])
        self.assertEqual(result['profile']['fleet_roster'][-1]['hull'], 'support')
        self.assertEqual(result['profile']['salvage'], 200)
        replay = self.store.recruit(self.a, 'ship_support', 'request-00000010', commission=True)
        self.assertEqual(replay['ship_id'], result['ship_id'])
        with self.assertRaises(ServiceError): self.store.recruit(self.a, 'ship_support', 'request-00000011', commission=True)
        with self.assertRaises(ServiceError): self.store.recruit(self.a, 'engine_sprint', 'request-00000012', commission=True)

    def test_duel_requires_two_opponents_locks_accounts_and_keeps_losing_fleet(self):
        ship_id = self.store.recruit(self.a, 'dart', 'request-00000013')['ship_id']
        p = self.store.deploy(self.a, 0, ship_id)
        for roster in [[{'user_id': self.a, 'team': 0}], [{'user_id': self.a, 'team': 0}, {'user_id': self.b, 'team': 0}]]:
            with self.assertRaises(ServiceError): self.store.start_match('bad-duel', roster, mode='fleet_duel')
        roster = [{'user_id': self.a, 'team': 0}, {'user_id': self.b, 'team': 1}]
        started = self.store.start_match('duel', roster, mode='fleet_duel')
        self.assertEqual(started['profiles'][0]['active_ships'][0], ship_id)
        for action in [lambda: self.store.recruit(self.a, 'dart', 'request-00000014'),
                       lambda: self.store.deploy(self.a, 1, p['fleet_roster'][0]['id']),
                       lambda: self.store.equip(self.a, 0, 'engine', 'engine_sprint')]:
            with self.assertRaisesRegex(ServiceError, 'locked'): action()
        # A lost HTTP response can safely be retried during the match.
        self.assertTrue(self.store.recruit(self.a, 'dart', 'request-00000013')['already_recruited'])
        self.store.finish_match('duel', 1, {self.a: dict(kills=2, damage=230)})
        after = self.store.me(self.a)
        self.assertEqual(after['fleet_roster'], p['fleet_roster'])
        self.assertEqual((after['battles'], after['wins'], after['total_kills']), (1, 0, 2))
        self.assertTrue(self.store.finish_match('duel', 0, {})['already_settled'])
        self.store.deploy(self.a, 0, p['fleet_roster'][0]['id'])

    def test_public_fleet_uses_deployed_records(self):
        ship_id = self.store.recruit(self.a, 'tender', 'request-00000015')['ship_id']
        self.store.deploy(self.a, 2, ship_id)
        public = self.store.public('Commander_A')
        self.assertEqual(public['fleet_size'], 4)
        self.assertEqual(public['active_fleet'][2], dict(name='Abyss Tender', hull='support'))
        self.assertNotIn('fleet_roster', public)

    def test_fifty_ship_lineup_and_cap_are_persistent_and_unique(self):
        with self.store.transaction() as db:
            p = self.store._profile(self.store._user(db, self.a))
            p['salvage'] = 10000
            self.store._save(db, self.a, p)
        ids = []
        for i in range(48):
            ship = self.store.recruit(self.a, 'dart', f'fleet-order-{i:016}')['ship_id']
            ids.append(ship)
            if i < 47: self.store.assign_vessel(self.a, ship, True)
        p = self.store.me(self.a)
        self.assertEqual(len(p['battle_fleet']), 50)
        self.assertEqual(len(set(p['battle_fleet'])), 50)
        with self.assertRaisesRegex(ServiceError, 'full'): self.store.assign_vessel(self.a, ids[-1], True)
        self.store.assign_vessel(self.a, ids[0], True)  # idempotent
        with self.assertRaises(ServiceError): self.store.assign_vessel(self.a, p['active_ships'][0], False)
        self.store.assign_vessel(self.a, ids[0], False)
        self.store.assign_vessel(self.a, ids[-1], True)
        self.assertEqual(len(Store(self.store.path, 'test-only-key').me(self.a)['battle_fleet']), 50)
        self.assertEqual(len(self.store.public('Commander_A')['active_fleet']), 50)

    def test_any_wingmate_can_be_fitted_without_changing_other_vessels(self):
        ship_id = self.store.recruit(self.a, 'siegebreaker', 'request-00000016')['ship_id']
        before = self.store.me(self.a)
        self.store.fit_vessel(self.a, ship_id, 'engine', 'engine_sprint')
        p = self.store.assign_vessel(self.a, ship_id, True)
        self.assertEqual(p['loadouts'], before['loadouts'])
        self.assertEqual(p['fleet_roster'][-1]['loadout']['engine'], 'engine_sprint')
        for uid, sid, slot, item in [(self.b, ship_id, 'shield', 'shield_standard'),
                                     (self.a, ship_id, 'weapon', 'engine_sprint'),
                                     (self.a, ship_id, 'weapon', 'weapon_singularity'),
                                     (self.a, ship_id, 'crew', 'crew_astra')]:
            with self.assertRaises(ServiceError): self.store.fit_vessel(uid, sid, slot, item)
        self.store.fit_vessel(self.a, before['active_ships'][0], 'engine', 'engine_sprint')
        self.assertEqual(self.store.me(self.a)['loadouts'][0]['engine'], 'engine_sprint')
        roster = [{'user_id': self.a, 'team': 0}, {'user_id': self.b, 'team': 1}]
        self.store.start_match('locked-lineup', roster, mode='fleet_duel')
        with self.assertRaises(ServiceError): self.store.assign_vessel(self.a, ship_id, False)
        with self.assertRaises(ServiceError): self.store.fit_vessel(self.a, ship_id, 'crew', '')


if __name__ == '__main__': unittest.main()
