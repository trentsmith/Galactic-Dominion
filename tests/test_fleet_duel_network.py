"""Real two-commander ENet duels: 50v50, unequal fleets and disconnects.

The source fixture freezes AI to test attribution/ownership deterministically.
GD_TEST_DUEL_PACKAGED=1 instead runs a normal live 50v50 in an exported host.
"""
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'server'))
from service import Store, make_server


def run(left=50, right=50, forfeit=False, packaged=False):
    processes = []
    handles = []
    with tempfile.TemporaryDirectory() as temporary:
        tmp = Path(temporary)
        store = Store(tmp / 'fleet.sqlite3', 'duel-test-only-key')
        http = make_server(store, '127.0.0.1', 0)
        threading.Thread(target=http.serve_forever, daemon=True).start()
        address = f'http://127.0.0.1:{http.server_port}'

        def api(path, data=None, token=None):
            headers = {'Content-Type': 'application/json'}
            if token: headers['Authorization'] = 'Bearer ' + token
            request = Request(address + path, data=json.dumps(data).encode() if data is not None else None, headers=headers)
            with urlopen(request, timeout=12) as reply: return json.load(reply)

        accounts = []
        for name, count in [('Admiral_A', left), ('Admiral_B', right)]:
            account = api('/register', {'username': name, 'password': 'fleet-duel-password'})
            uid = account['profile']['user_id']; token = account['token']
            with store.transaction() as db:
                p = store._profile(store._user(db, uid)); p['salvage'] = 20000
                for item in ['variant_nexus_eldritch', 'weapon_focus']: store._grant(p, item, 'Integration fixture')
                store._save(db, uid, p)
            board = api('/fleet/recruits', token=token)
            assert board['battle_capacity'] == 50 and board['capacity'] == 200
            offers = board['offers']
            for i in range(count - 3):
                receipt = f'{name}-order-{i:016}'
                # Exercise the actual HTTP endpoints, including a safe retry.
                hired = api('/fleet/recruit', {'offer': offers[i % 5]['id'], 'request_id': receipt}, token)
                if i == 0:
                    retry = api('/fleet/recruit', {'offer': offers[i % 5]['id'], 'request_id': receipt}, token)
                    assert retry['ship_id'] == hired['ship_id'] and retry['already_recruited']
                api('/fleet/assign', {'ship_id': hired['ship_id'], 'deployed': True}, token)
            p = api('/me', token=token)
            sid = p['battle_fleet'][-1]
            for slot, item in [('engine', 'engine_sprint'), ('weapon', 'weapon_focus'), ('variant', 'variant_nexus_eldritch')]:
                api('/fleet/fit', {'ship_id': sid, 'slot': slot, 'item': item}, token)
            accounts.append((uid, token, api('/me', token=token)))

        finish_calls = 0
        original_finish = store.finish_match
        def temporary_failure(*args, **kwargs):
            nonlocal finish_calls
            finish_calls += 1
            if finish_calls == 1: raise RuntimeError('Simulated account-service interruption')
            return original_finish(*args, **kwargs)
        store.finish_match = temporary_failure

        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.bind(('127.0.0.1', 0)); port = sock.getsockname()[1]
        env = dict(os.environ, GD_SERVER_KEY='duel-test-only-key', GD_API_URL=address, GD_TEST_PORT=str(port),
                   GD_TEST_DUEL_LEFT=str(left), GD_TEST_DUEL_RIGHT=str(right), GD_TEST_DUEL_FORFEIT='1' if forfeit else '0',
                   GD_TEST_DUEL_PACKAGED='1' if packaged else '0', XDG_DATA_HOME=str(tmp/'data'), XDG_CONFIG_HOME=str(tmp/'config'), XDG_CACHE_HOME=str(tmp/'cache'))
        try:
            log = open(tmp/'server.log', 'w'); handles.append(log)
            if packaged:
                cmd = [os.environ['GD_TEST_COMBAT_BINARY'], '--headless', '--', '--server', '--port', str(port), '--match-seconds', '8']
            else:
                cmd = ['godot', '--headless', '--path', str(ROOT), '--script', 'res://tests/fleet_duel_server.gd', '--', '--server', '--port', str(port), '--match-seconds', '20']
            server = subprocess.Popen(cmd, env=env, stdout=log, stderr=subprocess.STDOUT); processes.append(server)
            wait_log(tmp/'server.log', 'GALACTIC_COMBAT_READY', server)
            clients = []
            for name in ['Admiral_A', 'Admiral_B']:
                log = open(tmp/(name+'.log'), 'w'); handles.append(log)
                client = subprocess.Popen(['godot', '--headless', '--path', str(ROOT), '--script', 'res://tests/fleet_duel_client.gd'],
                                          env=dict(env, GD_TEST_USER=name), stdout=log, stderr=subprocess.STDOUT)
                processes.append(client); clients.append((name, client))
                wait_log(tmp/(name+'.log'), 'DUEL_LOBBY_READY', client)
            for name, client in clients:
                code = client.wait(timeout=55)
                output = (tmp/(name+'.log')).read_text()
                print(name + ':\n' + output)
                assert code == 0 and 'DUEL_CLIENT_PASS' in output and 'SCRIPT ERROR' not in output and 'ERROR:' not in output, name + ' failed'
            assert finish_calls >= 2, 'Host did not retry the interrupted settlement'
            for uid, token, before in accounts:
                after = api('/me', token=token)
                assert after['battles'] == 1
                assert after['fleet_roster'] == before['fleet_roster'], 'Losing/destroyed fleet ownership or fittings changed'
                assert after['battle_fleet'] == before['battle_fleet']
                # Prove that match locks were released after settlement.
                api('/fleet/fit', {'ship_id': after['battle_fleet'][-1], 'slot': 'crew', 'item': ''}, token)
            if not packaged:
                assert store.me(accounts[0][0])['wins'] == 1
                if not forfeit: assert store.me(accounts[0][0])['total_kills'] == right, 'AI wingmate kills were not credited'
                wait_log(tmp/'server.log', 'DUEL_SERVER_PASS', server)
            server_output = (tmp/'server.log').read_text(); print('Host:\n' + server_output)
            assert not any(s in server_output for s in ['SCRIPT ERROR', 'ERROR:', 'above the MTU'])
            print(f'FLEET_DUEL_NETWORK_PASS: {left}v{right}, {"forfeit" if forfeit else "battle"}, fitted owned fleets, batched replication, switching and retried settlement')
        finally:
            for proc in processes:
                if proc.poll() is None: proc.terminate()
            for proc in processes:
                try: proc.wait(timeout=5)
                except subprocess.TimeoutExpired: proc.kill(); proc.wait(timeout=5)
            for handle in handles: handle.close()
            debug = Path('/tmp/gd-fleet-duel-logs') / f'{left}-{right}-{int(forfeit)}-{int(packaged)}'
            debug.mkdir(parents=True, exist_ok=True)
            for path in tmp.glob('*.log'): (debug/path.name).write_text(path.read_text())
            http.shutdown(); http.server_close()


def wait_log(path, marker, proc):
    deadline = time.monotonic() + 25
    while marker not in path.read_text():
        if proc.poll() is not None or time.monotonic() > deadline:
            raise AssertionError(f'Missing {marker}:\n{path.read_text()}')
        time.sleep(.05)


if __name__ == '__main__':
    packaged = os.environ.get('GD_TEST_DUEL_PACKAGED') == '1'
    run(packaged=packaged)
    if not packaged: run(left=7, right=50, forfeit=True)
