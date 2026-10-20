"""Two real authenticated Godot clients and authoritative army server."""
import os, socket, subprocess, sys, tempfile, threading, time
from pathlib import Path
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'server'))
from service import Store, make_server

def main():
    processes, handles = [], []
    with tempfile.TemporaryDirectory() as directory:
        tmp = Path(directory)
        store = Store(tmp / 'test.sqlite3', 'army-test-key')
        for name in ('Army_A', 'Army_B'):
            store.register(name, 'integration-test-password')
        http = make_server(store, '127.0.0.1', 0)
        threading.Thread(target=http.serve_forever, daemon=True).start()
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.bind(('127.0.0.1', 0)); port = sock.getsockname()[1]
        env = dict(os.environ, GD_SERVER_KEY='army-test-key', GD_API_URL=f'http://127.0.0.1:{http.server_port}', GD_TEST_PORT=str(port), XDG_DATA_HOME=str(tmp/'data'), XDG_CACHE_HOME=str(tmp/'cache'), XDG_CONFIG_HOME=str(tmp/'config'))
        def launch(name, script, args=()):
            handle = open(tmp / (name + '.log'), 'w'); handles.append(handle)
            proc = subprocess.Popen(['godot', '--headless', '--path', str(root), '--script', script, *args], env=dict(env, GD_TEST_USER=name), stdout=handle, stderr=subprocess.STDOUT)
            processes.append(proc); return proc
        try:
            launch('server', 'res://tests/army_network_server.gd', ['--', '--server', '--port', str(port)])
            deadline = time.monotonic() + 15
            while 'GALACTIC_COMBAT_READY' not in (tmp / 'server.log').read_text():
                if time.monotonic() > deadline: raise AssertionError('Server startup failed')
                time.sleep(.05)
            clients = [(name, launch(name, 'res://tests/army_network_client.gd')) for name in ('Army_A', 'Army_B')]
            for name, client in clients:
                assert client.wait(timeout=180) == 0, (tmp / (name + '.log')).read_text()
                log = (tmp / (name + '.log')).read_text()
                assert 'ARMY_CLIENT_PASS' in log and 'SCRIPT ERROR' not in log, log
            server_log = (tmp / 'server.log').read_text()
            assert 'ARMY_HOST_COMBAT_PASS' in server_log and 'ARMY_HOST_CONQUEST_PASS' in server_log, server_log
            for file in tmp.glob('*.log'):
                log = file.read_text()
                assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log and 'above the MTU' not in log, log
            print('ARMY_NETWORK_PASS: two authenticated clients; space creature deployment rejected and ship outpost capture replicated')
        finally:
            for proc in processes:
                if proc.poll() is None: proc.terminate()
            for proc in processes:
                try: proc.wait(timeout=5)
                except subprocess.TimeoutExpired: proc.kill(); proc.wait(timeout=5)
            for handle in handles: handle.close()
            debug = Path('/tmp/gd13-army-network-logs'); debug.mkdir(exist_ok=True)
            for file in tmp.glob('*.log'): (debug / file.name).write_text(file.read_text())
            for file in tmp.glob("*.log"):
                print("\n" + file.name + "\n" + file.read_text()[-12000:])
            http.shutdown(); http.server_close()
if __name__ == '__main__': main()
