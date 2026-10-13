"""Run two real Godot clients against an ENet dedicated server and HTTP service."""
import json, os
from pathlib import Path
import socket, subprocess, sys, tempfile, threading, time
from urllib.request import Request, urlopen
from urllib.error import HTTPError
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'server'))
from service import Store, make_server

def main():
    count=int(os.environ.get("GD_TEST_CLIENTS", "2"))
    names=["Network_"+str(i) for i in range(count)]
    processes=[]
    with tempfile.TemporaryDirectory() as temporary:
        tmp=Path(temporary)
        store=Store(tmp/'test.sqlite3','integration-only-server-key')
        for name in names:
            store.register(name,'integration-test-password')
        http=make_server(store,'127.0.0.1',0)
        thread=threading.Thread(target=http.serve_forever,daemon=True); thread.start()
        with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as s:
            s.bind(('127.0.0.1',0)); udp_port=s.getsockname()[1]
        env=dict(os.environ,GD_SERVER_KEY='integration-only-server-key',GD_API_URL=f'http://127.0.0.1:{http.server_port}',GD_TEST_PORT=str(udp_port),GD_TEST_CLIENTS=str(count),XDG_DATA_HOME=str(tmp/'data'),XDG_CACHE_HOME=str(tmp/'cache'),XDG_CONFIG_HOME=str(tmp/'config'))
        try:
            def api(path, data=None, token=None):
                headers={'Content-Type':'application/json'}
                if token: headers['Authorization']='Bearer '+token
                request=Request(env['GD_API_URL']+path,data=json.dumps(data).encode() if data is not None else None,headers=headers)
                with urlopen(request,timeout=10) as reply:return json.load(reply)
            a=api('/login',{'username':names[0],'password':'integration-test-password'})
            b=api('/login',{'username':names[1],'password':'integration-test-password'})
            created=api('/register',{'username':'Profile_Check','password':'integration-test-password'})
            assert created['profile']['commander_name']=='Profile_Check'
            listing=api('/market/list',{'item':'engine_sprint','price':40},a['token'])['listing_id']
            offered=api('/offers/create',{'listing':listing,'amount':20},b['token'])['offer_id']
            api('/offers/accept',{'offer':offered},a['token'])
            assert api('/me',token=a['token'])['salvage']==220
            assert api('/me',token=b['token'])['salvage']==180
            assert 'engine_sprint' in api('/profiles?name='+names[0])['discovery_records']
            api('/equip',{'index':0,'slot':'engine','item':'engine_sprint'},b['token'])
            print('HTTP_API_PASS: registration, login, public records, inventory, listing escrow, offers, settlement and fitting')
            # The game-only reward endpoints must reject normal unauthenticated clients.
            try:
                urlopen(Request(env['GD_API_URL']+'/server/finish',data=b'{}',headers={'Content-Type':'application/json'}))
                raise AssertionError('Reward endpoint did not enforce combat-server authentication')
            except HTTPError as e: assert e.code==403
            server_log=open(tmp/'server.log','w')
            server=subprocess.Popen(['godot','--headless','--path',str(root),'--','--server','--port',str(udp_port),'--match-seconds','8' if count==6 else '5'],env=env,stdout=server_log,stderr=subprocess.STDOUT); processes.append(server)
            deadline=time.monotonic()+10
            while 'GALACTIC_COMBAT_READY' not in (tmp/'server.log').read_text():
                if server.poll() is not None or time.monotonic()>deadline: raise AssertionError('Dedicated server did not start')
                time.sleep(.05)
            clients=[]
            for name in names:
                logfile=open(tmp/(name+'.log'),'w')
                client=subprocess.Popen(['godot','--headless','--path',str(root),'--script','res://tests/network_client_test.gd'],env=dict(env,GD_TEST_USER=name),stdout=logfile,stderr=subprocess.STDOUT)
                processes.append(client); clients.append((name,client,logfile))
            for name,client,logfile in clients:
                code=client.wait(timeout=40); logfile.close()
                log=(tmp/(name+'.log')).read_text()
                print(name+' output:\n'+log)
                assert code==0 and 'NETWORK_CLIENT_PASS' in log and 'SCRIPT ERROR' not in log, name+' failed'
            for name in names:
                profile=store.public(name)
                assert profile['battles']==1, 'Rewards were not recorded exactly once'
            server_log.flush()
            log=(tmp/'server.log').read_text()
            print('Dedicated server output:\n'+log)
            assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log and 'above the MTU' not in log, 'Dedicated server emitted errors or fragmentation warnings'
            print(f'NETWORK_INTEGRATION_PASS: {count} authenticated clients, ready lobby, 3v3 arena, movement, ship ownership, results, rewards, protected reward endpoint')
        finally:
            for proc in processes:
                if proc.poll() is None: proc.terminate()
            for proc in processes:
                try:proc.wait(timeout=5)
                except subprocess.TimeoutExpired:proc.kill()
            debug=Path('/tmp/gd-network-logs');debug.mkdir(exist_ok=True)
            for log in tmp.glob('*.log'):
                (debug/log.name).write_text(log.read_text())
            http.shutdown();http.server_close()
if __name__=='__main__':main()
