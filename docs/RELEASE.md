Galactic Dominion v0.12 adds **creature armies and world conquest** to offline and online Free Roam, plus **Kindred and Radiant sanctuary forms**.

**Play armies:** select Free Roam (or launch Free Roam in the online lobby). Press **M**, scroll down the star chart, pick a species and **Deploy 5 Creatures**. Follow escorts your command ship. Fly toward a world outpost shown in the HUD, within 1600m, then choose **Assault Nearest World**. Recall removes your surviving troops. Squads fight automatically against hostile creatures and ships. Ships automatically defend against nearby hostile troops.

- Three orbital world outposts: Varkhoss Prime, Pelagia and Ny’Zaroth. Each starts with six AI defenders.
- **50 active creatures total across the whole server**, including defenders; **10 per human pilot**. Deployment has a 20-second cooldown and creates up to five troops if capacity allows. Dead and recalled troops free capacity. Disconnecting removes that pilot’s army.
- Scouts move faster; strikers deal more damage; wardens have more health. All nine fauna models are selectable as expedition troops.
- Keep troops within 330m of a world for **30 uncontested seconds** to conquer it. Enemy troops contest progress; abandoned progress decays. Opposing players can recapture worlds.
- The host runs army AI, damage, death, orders and capture. Clients send orders and display host snapshots. These are free expedition troops, separate from owned sanctuary residents and marketplace inventory. Losing them does not delete pets. Army kills do not award ship encounter prizes.

This is session-based orbital conquest in Free Roam. Territorial ownership and troop rosters reset when the session closes. Online planet-surface armies, permanent territorial empires, creature trading and deploying individual sanctuary pets are future work. Fleet Royale remains a separate 3v3 ship mode.

**Grow your pets:** choose My Planet / Creature Sanctuary. Feed, pet and play with housed residents. Their sidebar shows friendship, love, growth and happy care time. Click **Awaken Friendship Form** when ready:

- Kindred: friendship 35, love 25, growth 20, happy care 90 seconds.
- Radiant: friendship 80, love 70, growth 65, happy care 360 seconds.
- Both require housing, food 40+ and joy 65+. Happy care accumulates while food is 60+ and joy is 65+ with the garden open.
- Forms are permanent, keep nicknames/history, add original 3D geometry and improve production by 15% / 35%. No awakening cost. Love grows through care; neglect does not reverse an earned form.

Local saves migrate from schemas 1–3 to schema 4. Older profiles retain friendship and receive partial love credit, but earn their new forms through care. Keep a backup before replacing the game. Local and online collections stay separate. The model ZIP now contains 38 GLB models plus 38 editable Godot scenes.

**Players:** download Galactic-Dominion-Windows.zip, extract it, and run GalacticDominion.exe. Godot and Python are not needed.

**Windows host:** download Galactic-Dominion-Server-Windows.zip, extract it, and double-click Start-Server-Windows.bat. It includes the engine and portable Python runtime. Keep the window open. Use its displayed LAN address in Online, click Use This Address For A Local-Network Host, sign in and join. Ready up; the first pilot launches Free Roam. Later pilots can join the running world.

The host and all clients must use v0.12. Six human pilot slots plus AI are supported. Your PC runs the server only while its window stays open. Internet hosting needs router/VPS configuration and HTTPS for the account API; see the included hosting guide. Windows GUI execution has not been tested on this Linux development machine. Linux game/server packages and SHA256 checksums are included.
