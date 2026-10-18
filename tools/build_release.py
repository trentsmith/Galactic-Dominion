"""Export standalone Windows/Linux games and self-hosted server ZIPs."""
import argparse, hashlib, json, os, shutil, subprocess, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def pack(folder, destination):
    with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for path in sorted(folder.rglob('*')):
            if path.is_file(): archive.write(path,path.relative_to(folder))
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--godot',default=shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--templates',type=Path,help='Directory containing matching Godot release templates')
    parser.add_argument('--python-embed',type=Path,help='Official Windows embeddable Python ZIP for one-click hosting')
    parser.add_argument('--platform',choices=['all','windows','linux'],default='all')
    parser.add_argument('--api-url',default='http://127.0.0.1:8080')
    parser.add_argument('--combat-host',default='127.0.0.1')
    parser.add_argument('--combat-port',type=int,default=7777)
    args=parser.parse_args()
    if not args.godot: parser.error('Install Godot 4.6.3 or provide --godot')
    if not args.api_url.startswith(('http://','https://')) or not args.combat_host or not 1<=args.combat_port<=65535:parser.error('Invalid server connection settings')
    out=ROOT/'releases';out.mkdir(exist_ok=True)
    env=dict(os.environ)
    if args.templates:
        version=subprocess.check_output([args.godot,'--version'],text=True).strip().split('.official')[0]
        target=Path(env.get('XDG_DATA_HOME',Path.home()/'.local/share'))/'godot/export_templates'/version
        target.mkdir(parents=True,exist_ok=True)
        for path in args.templates.iterdir():
            if path.is_file():shutil.copy2(path,target/path.name)
    subprocess.run([args.godot,'--headless','--editor','--import','--path',str(ROOT),'--quit'],check=True,env=env)
    subprocess.run([args.godot,'--headless','--path',str(ROOT),'--script','res://tools/export_models.gd'],check=True,env=env)
    platforms=['windows','linux'] if args.platform=='all' else [args.platform]
    outputs=[]
    for platform in platforms:
        folder=ROOT/'build'/platform
        if folder.exists():shutil.rmtree(folder)
        folder.mkdir(parents=True)
        name='GalacticDominion.exe' if platform=='windows' else 'GalacticDominion.x86_64'
        preset='Windows Desktop' if platform=='windows' else 'Linux Desktop'
        subprocess.run([args.godot,'--headless','--path',str(ROOT),'--export-release',preset,str(folder/name)],check=True,env=env)
        if platform=='linux':(folder/name).chmod(0o755)
        cfg='[server]\napi_url='+json.dumps(args.api_url)+'\ncombat_host='+json.dumps(args.combat_host)+'\ncombat_port='+str(args.combat_port)+'\n'
        (folder/'server.cfg').write_text(cfg)
        (folder/'PLAY.txt').write_text('Galactic Dominion v0.20 alpha\n\nRun '+name+'. Godot and Python are not required for players.\nChoose My Planet / Creature Sanctuary to raise your creatures, Planet Expeditions to explore with a little bot, Free Roam for solo spaceflight or Online to join your host.\nOnline progress is separate from local progress.\nSee https://github.com/trentsmith/Galactic-Dominion for controls and hosting.\n')
        if (ROOT/'GODOT_LICENSE.txt').exists():shutil.copy2(ROOT/'GODOT_LICENSE.txt',folder/'GODOT_LICENSE.txt')
        title='Windows' if platform=='windows' else 'Linux'
        package=out/f'Galactic-Dominion-{title}.zip';pack(folder,package);outputs.append(package)
        server=ROOT/'build'/('server-'+platform)
        if server.exists():shutil.rmtree(server)
        server.mkdir(parents=True)
        for path in folder.iterdir():shutil.copy2(path,server/path.name)
        (server/'server').mkdir()
        for name in ['service.py','catalog.json','launch.py','README.md','Caddyfile.example']:shutil.copy2(ROOT/'server'/name,server/'server'/name)
        shutil.copy2(ROOT/'Start-Server-Windows.bat',server/'Start-Server-Windows.bat')
        shutil.copy2(ROOT/'server/Allow-LAN-Windows.ps1',server/'Allow-LAN-Windows.ps1')
        if platform=='windows' and args.python_embed:
            with zipfile.ZipFile(args.python_embed) as runtime:runtime.extractall(server/'python')
        (server/'Start-Server-Linux.sh').write_text('#!/bin/sh\nset -eu\ncd "$(dirname "$0")"\nexec python3 server/launch.py --host 0.0.0.0 "$@"\n')
        (server/'Start-Server-Linux.sh').chmod(0o755)
        package=out/f'Galactic-Dominion-Server-{title}.zip';pack(server,package);outputs.append(package)
    models=out/'Galactic-Dominion-3D-Models.zip'
    with zipfile.ZipFile(models,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for path in sorted((ROOT/'art/models').iterdir()):
            if path.suffix in ['.glb','.tscn','.md']:archive.write(path,path.name)
    outputs.append(models)
    checksums=''.join(hashlib.sha256(path.read_bytes()).hexdigest()+'  '+path.name+'\n' for path in outputs)
    (out/'SHA256SUMS.txt').write_text(checksums)
    print('Release files:\n'+'\n'.join(str(p) for p in outputs))
if __name__=='__main__':main()
