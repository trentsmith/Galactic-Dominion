Galactic Dominion v0.10 adds **PLANET EXPEDITIONS / LITTLE BOTS** to the main menu.

Explore three local single-player destinations:
- **Varkhoss Prime — Bloodforged Frontier:** crimson vegetation, volcanic ridges, imperial fortresses and dangerous wildlife.
- **Pelagia — Alien Reef World:** swim among bioluminescent coral, jellyfish, reefgrazers and Riftfin hunters.
- **Ny’Zaroth — The Dreaming Abyss:** living structures, floating stones, strange creatures and timed low-gravity fractures.

Select an owned bot/alien or use a loaner Pixlet. WASD moves, mouse looks, Shift sprints, Space jumps (Space/Ctrl swim), LMB fires a defensive pulse, G scans a nearby species, E extracts at the landing ship, and Esc pauses.

Each planet has thirty creatures, three fauna species and three flora species. Predators can destroy the bot; unextracted surveys are lost. Owned collectibles and banked progress remain. Return to the ship to save new surveys and earn one-time salvage/completion rewards. Existing saves are preserved.

The surface worlds are bounded prototype areas. Shared multiplayer planets, seamless orbit-to-surface flight and the full Crimson/Eldritch faction abilities are not implemented. The supplied lore is preserved in docs/NEXUS_ARCHIVES.md.

The model download now includes **twenty GLB/Godot model pairs**, including nine wildlife species. Static exports do not contain game behavior scripts.

**Players:** download Galactic-Dominion-Windows.zip, extract it, and run GalacticDominion.exe. Godot and Python are not needed. Choose Free Roam for solo play, or Online to join your host.

**Host on your Windows PC:** download Galactic-Dominion-Server-Windows.zip, extract it, and double-click Start-Server-Windows.bat. The host download includes the game engine and a portable Python runtime. Keep the server window open. It displays your LAN address for friends on the same network.

**Join:** enter the host's LAN address in the combat address field, click Use This Address For A Local-Network Host, create/sign into your account, and Join Open Arena. Ready up; the first pilot launches Free Roam or Fleet Royale. Free-roam sessions accept later joins.

The server and all clients must use this v0.10 build. Local and online collections stay separate. This alpha supports six human pilot slots per server plus AI; it is not a public worldwide service. Internet hosting needs router/VPS configuration and HTTPS for the account API; see the included hosting instructions.

Linux player and server downloads and SHA256 checksums are also included. Windows exports are produced by Godot; Windows GUI execution has not been tested in the Linux development environment.
