"""Verify the actual launcher imports a fresh copy and starts/stops both services."""
import json, os
from pathlib import Path
import shutil, signal, socket, subprocess, sys, tempfile, time
from urllib.request import urlopen
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as temporary:
    tmp=Path(temporary);game=tmp/'game'
    shutil.copytree(root,game,ignore=shutil.ignore_patterns('.git','.godot','__pycache__','server-data','build','releases'))
    def port(kind):
        with socket.socket(socket.AF_INET,kind) as s:
            s.bind(('127.0.0.1',0));return s.getsockname()[1]
    tcp=port(socket.SOCK_STREAM);udp=port(socket.SOCK_DGRAM)
    env=dict(os.environ,XDG_DATA_HOME=str(tmp/'data'),XDG_CACHE_HOME=str(tmp/'cache'),XDG_CONFIG_HOME=str(tmp/'config'))
    with open(tmp/'launcher.log','w') as logfile:
        process=subprocess.Popen([sys.executable,str(game/'server/launch.py'),'--godot',shutil.which('godot'),'--host','127.0.0.1','--api-port',str(tcp),'--combat-port',str(udp),'--data',str(tmp/'server-data')],env=env,stdout=logfile,stderr=subprocess.STDOUT)
        try:
            deadline=time.monotonic()+20
            while 'GALACTIC_COMBAT_READY' not in (tmp/'launcher.log').read_text():
                if process.poll() is not None or time.monotonic()>deadline: raise AssertionError('Launcher did not start both services')
                time.sleep(.1)
            with urlopen(f'http://127.0.0.1:{tcp}/health',timeout=5) as response: assert json.load(response)['ok']
            assert (tmp/'server-data/combat-server.key').exists()
            process.send_signal(signal.SIGINT)
            assert process.wait(timeout=10)==0
            log=(tmp/'launcher.log').read_text()
            assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log,log
            print('LAUNCHER_PASS: fresh project import, generated private key, HTTP readiness, ENet readiness, clean shutdown')
        finally:
            if process.poll() is None: process.terminate();process.wait(timeout=10)
