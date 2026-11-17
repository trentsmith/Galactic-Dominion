"""Real HTTP account service and two ENet clients; fixture positions ships near a job."""
import os, socket, subprocess, sys, tempfile, threading, time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'server'))
from service import Store,make_server,ServiceError

def main():
    processes=[];handles=[]
    disconnect_case=os.environ.get("GD_TEST_REWARD_DISCONNECT")=="1"
    attempts=[0]
    with tempfile.TemporaryDirectory() as temporary:
        tmp=Path(temporary);store=Store(tmp/'accounts.sqlite3','coop-test-key')
        ids=[store.register(name,'frontier-network-password')['profile']['user_id'] for name in ['Coop_A','Coop_B']]
        if disconnect_case:
            original=store.frontier_reward
            def lose_first_reply(*args):
                attempts[0]+=1
                if attempts[0]==1:
                    time.sleep(2)  # The second client leaves before this transaction starts.
                    original(*args)
                    raise ServiceError('Simulated lost reply after committed reward',503)
                return original(*args)
            store.frontier_reward=lose_first_reply
        http=make_server(store,'127.0.0.1',0);threading.Thread(target=http.serve_forever,daemon=True).start()
        with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
        env=dict(os.environ,GD_SERVER_KEY='coop-test-key',GD_API_URL=f'http://127.0.0.1:{http.server_port}',GD_TEST_PORT=str(port),XDG_DATA_HOME=str(tmp/'data'),XDG_CACHE_HOME=str(tmp/'cache'),XDG_CONFIG_HOME=str(tmp/'config'))
        def launch(name,script,args=()):
            log=open(tmp/(name+'.log'),'w');handles.append(log)
            process=subprocess.Popen(['godot','--headless','--path',str(root),'--script',script,*args],env=dict(env,GD_TEST_USER=name),stdout=log,stderr=subprocess.STDOUT)
            processes.append(process);return process
        def wait_log(name,marker):
            deadline=time.monotonic()+25
            while marker not in (tmp/(name+'.log')).read_text():
                if time.monotonic()>deadline:raise AssertionError((tmp/(name+'.log')).read_text())
                time.sleep(.05)
        try:
            launch('server','res://tests/reward_disconnect_server.gd' if disconnect_case else 'res://tests/frontier_network_server.gd',['--','--server','--port',str(port)])
            wait_log('server','GALACTIC_COMBAT_READY')
            first=launch('Coop_A','res://tests/frontier_network_client.gd');wait_log('server','COOP_WORLD_READY')
            second=launch('Coop_B','res://tests/reward_disconnect_client.gd' if disconnect_case else 'res://tests/frontier_network_client.gd')
            for name,process in [('Coop_A',first),('Coop_B',second)]:
                code=process.wait(timeout=45);log=(tmp/(name+'.log')).read_text();print(log)
                marker='COOP_EARLY_LEAVE_PASS' if disconnect_case and name=='Coop_B' else 'COOP_CLIENT_PASS'
                assert code==0 and marker in log and 'SCRIPT ERROR' not in log and 'ERROR:' not in log
            wait_log('server','COOP_SERVER_PASS')
            for uid in ids:assert store.me(uid)['frontier']['completed']==1 and store.me(uid)['salvage']==260
            deadline=time.monotonic()+5
            while True:
                with store.connect() as db:unlocked=all(row['locked_until']==0 for row in db.execute('SELECT locked_until FROM users'))
                if unlocked or time.monotonic()>deadline:break
                time.sleep(.05)
            assert unlocked,'Departures did not release the account inventory locks'
            if disconnect_case:assert attempts[0]>=2,'The simulated lost reply was not retried'
            with store.connect() as db:assert db.execute('SELECT count(*) FROM frontier_receipts').fetchone()[0]==1
            try:
                urlopen(Request(env['GD_API_URL']+'/server/roam/contract',data=b'{}',headers={'Content-Type':'application/json'}))
                raise AssertionError('Contract endpoint lacked server authentication')
            except HTTPError as error:assert error.code==403
            log=(tmp/'server.log').read_text();assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log,log
            if disconnect_case:print('COOP_RETRY_NETWORK_PASS: real participant disconnect, delayed transaction, committed reward with lost reply, automatic retry, one receipt and unlocked inventories')
            print('FRONTIER_NETWORK_PASS: two allied clients, late join, host-only jobs, replicated repair and team pings, fleet switching, individual persistent rewards and protected endpoint')
        finally:
            for process in processes:
                if process.poll() is None:process.terminate()
            for process in processes:
                try:process.wait(timeout=5)
                except subprocess.TimeoutExpired:process.kill()
            for log in handles:log.close()
            out=Path('/tmp/gd43-coop-retry-logs' if disconnect_case else '/tmp/gd43-coop-logs');out.mkdir(exist_ok=True)
            for log in tmp.glob('*.log'):(out/log.name).write_text(log.read_text())
            http.shutdown();http.server_close()
if __name__=='__main__':main()
