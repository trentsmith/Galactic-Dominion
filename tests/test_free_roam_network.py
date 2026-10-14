"""Real HTTP/ENet free-roam test, including a pilot joining an active world.
The server fixture parks AI and injects damage to exercise reproducible scenarios.
"""
import os, json, socket, subprocess, sys, tempfile, threading, time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'server'))
from service import Store,make_server

def main():
    processes=[]
    with tempfile.TemporaryDirectory() as temporary:
        tmp=Path(temporary);store=Store(tmp/'test.sqlite3','roam-test-key')
        a=store.register('Roam_A','integration-test-password')['profile']['user_id']
        b=store.register('Roam_B','integration-test-password')['profile']['user_id']
        with store.transaction() as db:
            p=store._profile(store._user(db,b));store._grant(p,'ship_bomber','Test fixture');store._save(db,b,p)
        with store.transaction() as db:
            p=store._profile(store._user(db,a));store._grant(p,"crew_nyx","Test fixture");store._save(db,a,p)
        store.equip(a,0,"crew","crew_nyx")
        store.equip(b,0,None,None,hull='bomber')
        http=make_server(store,'127.0.0.1',0)
        threading.Thread(target=http.serve_forever,daemon=True).start()
        with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sock:
            sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
        env=dict(os.environ,GD_SERVER_KEY='roam-test-key',GD_API_URL=f'http://127.0.0.1:{http.server_port}',GD_TEST_PORT=str(port),XDG_DATA_HOME=str(tmp/'data'),XDG_CACHE_HOME=str(tmp/'cache'),XDG_CONFIG_HOME=str(tmp/'config'))
        handles=[]
        def launch(name,script,args=()):
            handle=open(tmp/(name+'.log'),'w');handles.append(handle)
            process=subprocess.Popen(['godot','--headless','--path',str(root),'--script',script,*args],env=dict(env,GD_TEST_USER=name),stdout=handle,stderr=subprocess.STDOUT)
            processes.append(process);return process
        def wait_log(name,text,seconds=15):
            deadline=time.monotonic()+seconds
            while text not in (tmp/(name+'.log')).read_text():
                if time.monotonic()>deadline:raise AssertionError(f'{name}: missing {text}\n'+(tmp/(name+'.log')).read_text())
                time.sleep(.05)
        try:
            server=launch('server','res://tests/free_roam_server_test.gd',['--','--server','--port',str(port),'--match-seconds','2'])
            wait_log('server','GALACTIC_COMBAT_READY')
            first=launch('Roam_A','res://tests/free_roam_client_test.gd')
            wait_log('server','ROAM_WORLD_READY')
            # Join after the first player already started flying.
            second=launch('Roam_B','res://tests/free_roam_client_test.gd')
            for name,client in [('Roam_A',first),('Roam_B',second)]:
                code=client.wait(timeout=50)
                log=(tmp/(name+'.log')).read_text();print(name+' output:\n'+log)
                assert code==0 and 'ROAM_CLIENT_PASS' in log and 'SCRIPT ERROR' not in log
            wait_log('server','ROAM_SERVER_PASS')
            wait_log('server','ROAM_COMPANION_REAL_SHOT_PASS')
            deadline=time.monotonic()+5
            while time.monotonic()<deadline:
                with store.connect() as db:
                    rows=db.execute('SELECT locked_until FROM users').fetchall()
                if all(row['locked_until']==0 for row in rows):break
                time.sleep(.05)
            assert all(row['locked_until']==0 for row in rows),'Leaving did not unlock online inventory'
            pa=store.me(a);assert pa['wins']==2 and pa['battles']==2
            assert sum(v['count'] for k,v in pa['inventory'].items() if k.startswith('ship_'))>=2
            assert store.me(b)['wins']==0
            prize=next(k for k in pa['inventory'] if k.startswith('ship_'))
            listing=store.list_item(a,prize,10)['listing_id'];store.buy(b,listing)
            assert prize in store.me(b)['inventory'],'Victory ship could not transfer to another pilot'
            for endpoint in ['reward','join','lease','leave','end']:
                try:
                    urlopen(Request(env['GD_API_URL']+'/server/roam/'+endpoint,data=b'{}',headers={'Content-Type':'application/json'}))
                    raise AssertionError('Unprotected free-roam endpoint')
                except HTTPError as error:assert error.code==403
            log=(tmp/'server.log').read_text();print('Server output:\n'+log)
            assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log,log
            print('FREE_ROAM_NETWORK_PASS: two real clients, live join, replicated NPCs, travel, repair, PvE/PvP damage, respawn, persistence, trading and protected endpoints')
        finally:
            for process in processes:
                if process.poll() is None:process.terminate()
            for process in processes:
                try:process.wait(timeout=5)
                except subprocess.TimeoutExpired:process.kill()
            for handle in handles:handle.close()
            debug=Path('/tmp/gd5-roam-network-logs');debug.mkdir(exist_ok=True)
            for log in tmp.glob('*.log'):(debug/log.name).write_text(log.read_text())
            http.shutdown();http.server_close()
if __name__=='__main__':main()
