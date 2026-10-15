# Galactic Dominion self-hosted server

Requires **Python 3.10+** and the standard **Godot 4.x** executable (tested with 4.6.3). No Python packages, Docker, paid assets or hosted accounts are required. One server instance runs one lobby and either a Fleet Royale arena or a continuous free-roam world, with up to six human pilots. AI fills empty pilot slots; free roam also contains twelve raider ships.

## One-click Windows host package

Download **Galactic-Dominion-Server-Windows.zip** from [the v0.9 release](https://github.com/trentsmith/Galactic-Dominion/releases/tag/v0.9.0), extract it, and double-click **Start-Server-Windows.bat**. Godot and Python do not need separate installation: the package includes the exported game engine and a portable official Python runtime. Do not run files from inside the ZIP preview. Keep the window open; Ctrl+C stops both servers.

The server window prints the PC's LAN addresses. Friends on your same network run the player download, open Online, put that IP in Combat Server Address and click **Use This Address For A Local-Network Host**. The shortcut sets the account URL to `http://HOST:8080`. Clients on the hosting PC can use `127.0.0.1`. Connection preferences remember the address and username.

The default ports are **TCP 8080** for accounts and **UDP 7777** for combat. If needed, run the included `Allow-LAN-Windows.ps1` from an Administrator PowerShell window; its rules apply only to Private networks and the local subnet. An executable-only host can also run `python server/launch.py --game PATH_TO_GAME --host 0.0.0.0`.

This package hosts your own six-player session; it does not register with a global matchmaking service. The server must keep running while people play. For Internet access, the LAN shortcut is insufficient: configure an HTTPS hostname/reverse proxy for the account service and forward the combat UDP port, or use a private VPN. There is no Internet relay or public domain provisioned by this package.

## Windows: host from the source project

1. Install Python from https://www.python.org/downloads/windows/ if needed. Include the Python launcher when installing.
2. Extract the full game ZIP.
3. Double-click **Start-Server-Windows.bat** in the game folder.
4. If prompted, select the Godot 4 executable you downloaded. The `_console.exe` variant is convenient for server logs; the standard executable also supports `--headless`.
5. Leave the terminal open. It imports the Godot project, starts the account service and starts the combat server. Use Ctrl+C to stop both.
6. Run the game in Godot with F5 and choose **Online / Lobby / Marketplace**.
7. Leave the account URL at `http://127.0.0.1:8080`, combat address at `127.0.0.1`, and UDP port at `7777`.
8. Create an account using a name containing 3–24 letters, numbers or underscores, and a password of at least 10 characters.
9. Click **Join Open Arena**. Choose a team if desired, then click **Ready**. The first pilot in the lobby clicks **Launch Match** when everyone is ready. Missing human slots are filled by AI. For continuous space travel and combat, the leader instead clicks **Launch Free Roam**. Additional pilots can join a running free-roam session.

You can open multiple game windows and sign in as different users to test multiplayer on one PC. F1–F3 request control of ships on your own team; a ship occupied by another human cannot be taken. Fitting slots on the Online Fleet tab correspond to the three slots shown in the lobby. Preparing all three slots lets you use your chosen fittings whichever position you receive.

## Online free roam and alien companions

Launch Free Roam from the ready lobby. Fly directly between four regions, or press **M** to warp outside combat. Approach a station within 180 metres and press **G** for repair/refill; hostiles within 650 metres or recent damage block service and warp. Ships redeploy after destruction and there is no shrinking zone or timer. Up to six pilots share two teams; twelve additional AI raiders roam the world. Joining an active session replaces an available pilot slot with the joining account's fitted hull. A human-occupied ship cannot be switched into by another player.

Equip an owned alien in **Online Fleet → Crew** before joining. Its companion orbits and automatically attacks nearby hostiles; the server alone creates projectiles and applies damage. Legendary/Mythic variants use normal species attack stats. Confirmed hostile kills pay a permanent random hull, two collectible rolls and salvage immediately, with idempotent SQLite receipts. Leave the world and refresh Online Fleet to trade your reward copies. Account inventory is locked while flying, renewed with short leases, and released when you leave; an interrupted server's lock expires automatically. Local scan discoveries are separate from online inventory.

Sessions close when their last human leaves. Accounts and collections persist, but world positions and patrol waves are not restored after restarting the server. The same v0.9 game build is required on the server and every client.

## Explicit launch command

```powershell
py -3 server\launch.py --godot "C:\path\to\Godot_v4.6.3-stable_win64_console.exe" --host 0.0.0.0
```

Linux/VPS:

```sh
python3 server/launch.py --godot /usr/local/bin/godot --host 127.0.0.1
```

Options: `--api-port 8080`, `--combat-port 7777`, `--data /path/to/server-data`. The launcher generates and retains a private combat-service key automatically. Do not share the `server-data` folder in the repository or ZIP; it contains account data and that key. The folder is ignored by Git and Godot.

## LAN play

Run with `--host 0.0.0.0` (the Windows batch file does this). Allow TCP 8080 and UDP 7777 through your PC's firewall for the intended network. Other PCs enter `http://YOUR-LAN-IP:8080` and `YOUR-LAN-IP` in the online screen. Every PC must use the same game build.

## VPS / Internet play

Put the game folder on your VPS, install Python and Godot, and run the launcher. The combat server listens on UDP 7777. Allow that port in the VPS firewall and any upstream firewall. For hosting behind a home router, UDP 7777 needs forwarding to the server PC.

The included account service uses HTTP. For Internet accounts, place it behind an HTTPS reverse proxy and keep port 8080 private. Set the game's account URL to `https://your-domain.example` and the combat address to your VPS hostname or IP. ENet traffic uses the direct UDP address, not the HTTPS proxy.

A minimal Caddy configuration is provided in `Caddyfile.example`; replace its example domain with your own and run Caddy separately. Public DNS, certificates, routing and an external VPS were not deployed or tested in the development environment. The game/server package was tested over local TCP and UDP.

Keep both services running, for example under your OS's service manager. Run a separate server process/port/data folder for a separate independent lobby. There is no global region directory or ranked matchmaking service; **Join Open Arena** is the basic quick-join flow for the server address you enter.

## Accounts, inventory and trading

Online inventory is authoritative and **separate from local exploration/single-player inventory**. Clients cannot upload local saves or award themselves online loot. New online accounts receive the standard fleet, 200 online salvage and a small welcome cache of tradable equipment.

- Configure discovered hulls, components, crew and variants in **Online Fleet**.
- Complete online matches for server-settled salvage and discovery rolls. Inventory is locked during a match so equipped items cannot be sold while their match is running.
- Select an inventory item on Online Fleet, then go to Marketplace to list it. Fleet-issued items cannot be listed. Unequip the last copy of an item before listing it.
- Listed items leave inventory into escrow. Buying atomically transfers the item and salvage. Cancellation returns the item.
- Offers reserve the buyer's salvage. Acceptance settles the trade; rejection, cancellation or a sale to someone else refunds other offers.
- Public Profiles shows online fleets, lifetime combat totals and discovery records. Trading away an item does not erase its discovery record. Anyone can read a public profile at `/profiles?name=COMMANDER_NAME` on the account service; the game's profile browser formats this data.

Passwords are salted PBKDF2 hashes, session tokens are stored as hashes and expire after 24 hours, and game tickets are single-use with a 60-second lifetime. The combat service alone can settle matches. SQLite transactions reject duplicate purchases and duplicate reward settlement.

Data lives in `server-data/galaxy.sqlite3`; the generated key is in `server-data/combat-server.key`. Stop the server before copying the whole data folder for a backup. An interrupted match may not pay rewards; inventory locks expire after ten minutes if its server does not settle it. Accounts have no email verification or password-reset UI yet.

## Tests actually run

From the project root:

```sh
python -m unittest discover -s tests -p test_service.py -v
python tests/test_network_integration.py
```

For the full six-client run, set `GD_TEST_CLIENTS=6` before running the integration test (PowerShell: `$env:GD_TEST_CLIENTS="6"`). These tests create isolated temporary accounts and databases and need local TCP/UDP sockets plus `godot` on PATH. They do not contact GitHub or a public service.

The six-client test verifies authentication, readiness, a full 3v3 arena, server-owned movement, rejection of occupied-ship takeover, results and persistent rewards. The two-client test verifies AI filling empty slots and switching into an available ship. HTTP checks exercise registration, public profiles, trading offers, escrow and online fittings. Fourteen service tests cover transactions, simultaneous purchases, authentication, single-use tickets and idempotent rewards.

This is a self-hosted multiplayer prototype with interpolated server snapshots. Internet latency, rendering performance on six real PCs, large populations, moderation and a production economy have not been validated. There is no client prediction or lag compensation yet.
