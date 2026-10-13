"""Start the account service and Godot dedicated combat server together."""
import argparse, os
from pathlib import Path
import secrets, shutil, signal, subprocess, sys, time

def main():
    parser=argparse.ArgumentParser(description='Galactic Dominion self-hosted server')
    parser.add_argument('--godot',help='Path to the Godot 4 executable')
    parser.add_argument('--host',default='127.0.0.1',help='API bind address; use 0.0.0.0 for LAN/VPS access')
    parser.add_argument('--api-port',type=int,default=8080)
    parser.add_argument('--combat-port',type=int,default=7777)
    parser.add_argument('--data',default=None)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    executable=args.godot or shutil.which('godot') or shutil.which('godot4')
    if not executable and sys.platform=='win32':
        try:
            import tkinter as tk
            from tkinter.filedialog import askopenfilename
            window=tk.Tk();window.withdraw()
            executable=askopenfilename(title='Select your Godot 4 executable',filetypes=[('Godot executable','*.exe')])
            window.destroy()
        except Exception: pass
    if not executable or not Path(executable).is_file(): parser.error('Supply --godot with the path to your Godot 4 executable')
    data=Path(args.data).resolve() if args.data else root/'server-data'
    data.mkdir(parents=True,exist_ok=True)
    (data/'.gdignore').touch()
    key_path=data/'combat-server.key'
    if not key_path.exists():
        key_path.write_text(secrets.token_urlsafe(48));key_path.chmod(0o600)
    env=dict(os.environ,GD_SERVER_KEY=key_path.read_text().strip(),GD_API_URL=f'http://127.0.0.1:{args.api_port}')
    processes=[]
    try:
        api=subprocess.Popen([sys.executable,str(root/'server/service.py'),'--host',args.host,'--port',str(args.api_port),'--data',str(data)],env=env)
        processes.append(api)
        # Import once so class names are available even from a fresh ZIP extraction.
        imported=subprocess.run([executable,'--headless','--editor','--import','--path',str(root),'--quit'],env=env)
        if imported.returncode!=0: raise RuntimeError('Godot project import failed')
        combat=subprocess.Popen([executable,'--headless','--path',str(root),'--','--server','--port',str(args.combat_port)],env=env)
        processes.append(combat)
        print(f'Clients on this PC: API http://127.0.0.1:{args.api_port}, combat 127.0.0.1:{args.combat_port}',flush=True)
        print('Keep this window open. Press Ctrl+C to stop both services.',flush=True)
        while all(p.poll() is None for p in processes): time.sleep(.25)
        if any(p.returncode not in [None,0] for p in processes): raise RuntimeError('A server process exited; check the messages above')
    except KeyboardInterrupt: pass
    finally:
        for proc in processes:
            if proc.poll() is None: proc.terminate()
        for proc in processes:
            try:proc.wait(timeout=5)
            except subprocess.TimeoutExpired:proc.kill()
if __name__=='__main__':main()
