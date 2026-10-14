# Galactic Dominion — Phase 5: Free Roam & Little Space Crew

A Godot 4.x 3D space game prototype with cute original cartoon ships, orbiting alien companions, offline/online free roam, Fleet Royale, exploration, a persistent fleet hangar, collectible crew, interchangeable components, rare appearances, server-hosted 3v3 combat, public online profiles and a player marketplace. Uses only primitive meshes and GDScript. Validated with Godot 4.6.3. No plugins or paid assets are required. Offline modes require no network access.

## Open and play

1. Install Godot 4.x (the standard version; .NET is not required).
2. Extract the project folder if downloaded as a ZIP.
3. In Godot's Project Manager click **Import**, select `project.godot`, and open it.
4. Press **F5** (Run Project).
5. Click **FREE ROAM / OPEN SPACE** to explore, or **PLAY / DEPLOY FLEET** for Fleet Royale. The mouse is captured for steering; **Esc** pauses and releases it.

From a terminal: `godot --path /path/to/galactic-dominion`.


## Free-roaming space

**Free Roam / Open Space** loads four connected regions into one world. Fly directly between Vesper Reach, Kharon Belt, Auralith Drift and Ember Frontier, or open **M** for station warp. There is no shrinking zone, boundary damage, eight-minute timeout or session-ending team elimination. Nearby ship markers and **Tab** targeting are limited to 1,400 metres to keep the view readable.

- Your three configured fleet ships travel together; F1–F3 switching and the five fleet orders work as before.
- Twelve AI raiders patrol the four regions, while four friendly civilian escorts roam near stations. Raider factions can fight each other as well as your fleet.
- Approach a station within **180 metres** and press **G** to restore nearby fleet hull, shields and boost. Warp and station service require no nearby hostiles within 650 metres and no recent damage. Warp preserves damage; it does not repair ships.
- Twelve signals grant the existing local exploration discoveries. Approach within 35 metres and **hold G for two seconds**. Signals share saved IDs with Exploration, so rescanning cannot grant duplicate rewards.
- Defeat a three-ship patrol with your fleet to receive a **permanent hull, two discovery rolls and 60 salvage**. The world stays active; new patrols arrive after 45 seconds.
- Destroyed fleet ships redeploy at the nearest station after 12 seconds. Eight seconds of launch protection helps prevent immediate repeat deaths; firing ends protection. Offline **Esc** pause now stops simulation, including the free-roam world.

Online free roam supports **up to six human pilots plus twelve AI raiders** in the same world. In Online / Lobby / Marketplace, join the server, ready up, and have the leader click **Launch Free Roam**. Additional pilots can join an active free-roam session without interrupting its players. Two three-ship teams remain in this prototype; empty pilot slots use AI and F1–F3 switching cannot take another human's vessel. Warp and service move/repair only your controlled online ship. The server handles movement, damage, travel, service and respawning. Each server-confirmed player kill of a hostile ship grants a permanent hull and discovery rewards, saved immediately; leaving unlocks your inventory for trading. Online scanning is not added in this build; local exploration and online inventories remain separate.

One server process runs either Fleet Royale or a continuous free-roam session. With no human pilots left, the free-roam session closes and its lobby becomes available again. World positions and encounter waves are session state, while your collected ships, fittings and records persist.

## Cute cartoon ships and alien companions

Ships now use rounded hulls, bubble cockpits, chunky wing pods, pastel colors and cartoon outline/shading passes. Planets have rings, asteroids use softer colors, and HUD/menu panels have rounded edges. All geometry and portraits are original procedural assets; no external art packages are used.

**Equip an alien in a ship's Crew slot** in Fleet Hangar or Online Fleet. Its 3D companion orbits the ship, bobs and blinks, chooses a nearby enemy within 320 metres, and fires real projectiles. A selected enemy takes priority. Shots obey cooldowns, avoid allies, apply shields/hull damage and credit the host ship. Alien attacks are automatic on player and AI ships; online clients only animate companions and render server-owned projectiles. Companions stop attacking when their ship is destroyed and return when it redeploys. Astronauts retain their crew bonuses without spawning an alien companion.

| Species | Companion attack |
| --- | --- |
| Vesperi | 6 damage plasma orb every 1.4 seconds |
| Kharon | 10 damage charged orb every 2.1 seconds |
| Auralith | 4 damage rapid orb every 1.0 second |
| Drakari | 8 damage tracking orb every 1.7 seconds |

These attacks supplement the crew's existing stat bonus. Legendary/Mythic appearances do not increase companion damage or firing speed. To discover your first alien locally, scan the first Vesper signal to find Nyx, then equip Nyx in the hangar. Alien crew can also be researched or discovered through battle rewards.

The images below were captured from the actual Godot renderer. The flight capture parks AI to keep the screenshot reproducible; gameplay runs the patrols normally.

![Original rounded ship and alien models](docs/images/space-crew.png)

![Free-roam flight HUD with an equipped alien companion](docs/images/free-roam.png)

## Faster combat and permanent victory ships

Hull and shields are roughly halved; lasers and missiles hit harder, and shield regeneration is reduced. The eight-minute match ceiling remains. The previous build finished a six-AI match in **56.48 seconds**, versus **235 seconds** before the damage/health changes. This build, which adds alien opponents, completed its test battle in **20.42 simulated seconds**. These are individual simulations, not promised player match lengths; balance still needs interactive playtesting.

| Ship | Hull / Shield | Laser / Missile damage | Distinct role and R ability |
| --- | --- | --- | --- |
| Interceptor | 50 / 40 | 20 / 85 | Fast flanker; speed surge |
| Skirmisher | 75 / 60 | 29 / 85 | Balanced duelist; laser overcharge |
| Guardian | 110 / 120 | 35 / 85 | Slow shield tank; nearby ally protection |
| Bomber | 90 / 65 | 23 / 145 | Missile specialist; rapid missile barrage |
| Support | 95 / 90 | 21 / 70 | Fleet sustain; nearby hull repair |

Every victory grants one uniformly selected hull from these five classes, in addition to discovery rolls. The hull remains in inventory after restarting; duplicates remain additional copies. Offline rewards belong to the local save. Online rewards belong to the server account and can be sold through Marketplace. Fleet-issue starter hulls remain usable even after trading reward copies; unequip a Bomber or Support before selling its last owned copy. Wins grant standard hulls; very rare liveries are separate, tradable appearance collectibles fitted to compatible hulls. Each roll chooses uniformly within its tier, so a particular Mythic appearance is rarer than the overall Mythic rate. No paid rolls or rarity bonuses are present. Existing appearance IDs and saves remain compatible; the former Exotic tier is now called Legendary.

## Galaxy & Network expansion

**Galactic Exploration** takes your configured fleet into four sectors: Vesper Reach, Kharon Belt, Auralith Drift and Ember Frontier. Each sector has a different asteroid layout and planet tint, three scan signals and a hostile patrol. The HUD marks signals and enemies. Approach a signal within 35 metres and **hold G for two seconds** to scan it. Press **M** to open the sector chart and warp, or return to the hangar. The chart does not pause combat; Esc does pause local exploration.

Sector entry, scans and defeated patrols produce one-time discovery records and salvage. Scans reveal specific crew, equipment or hulls, so exploration gives a predictable route to new content. Revisited records do not pay again. Warp redeploys your fleet in the chosen sector. The **Galactic Records** hangar tab lists discoveries and their UTC timestamps.

The new **Bomber** class has heavy missiles and a temporary barrage ability that reduces missile reload time. The **Support** class repairs nearby allied hulls for five seconds. Unlock either in exploration or research its schematic, then select its hull in Fleet Hangar. Rare hull appearances remain cosmetic. Combat now has original synthesized placeholder laser, missile, shield, destruction and menu sounds, with master volume in Settings.

**Online / Lobby / Marketplace** connects to the included self-hosted server. It supports account registration/login, quick-joining the server's open lobby, choosing teams, readiness and 3v3 real-time combat. Up to six human pilots can join; AI fills empty positions and takes over disconnected pilots' ships. The server owns movement, health, shots, target locking, switching and match results. Clients send bounded control input and interpolate server snapshots.

Online Fleet configures server-owned hulls and fittings. Public Profiles shows online fleet, collection/discovery records and lifetime combat totals. Marketplace supports item listings, purchases, offers, acceptance, rejection and cancellation, with escrow and atomic settlement. Local save data cannot be uploaded as tradable online items: **local and online progression are separate**.

For Windows startup, LAN/VPS setup, accounts and trading, see **[server/README.md](server/README.md)**. The full game folder includes **Start-Server-Windows.bat**. You need Python 3.10+ in addition to Godot to host; regular single-player play only requires Godot. No public server was deployed for this build.

## Hangar & Discovery

From the main menu open **FLEET HANGAR / COLLECTION**. Use the fleet buttons or F1–F3 to inspect your three ships, then select fittings from the dropdowns. The rotating 3D preview shows fitted hardware and ship variants. Your base Interceptor, Skirmisher and Guardian remain available permanently.

Each ship has six slots: engine, shield, weapon, utility, crew and variant. The hangar displays the resulting hull, shields, regeneration, speed, turning, boost capacity, laser/missile output and ability recharge. Loadouts affect your next deployed battle. Component schematics can be fitted to multiple ships; a named crew member can serve aboard only one ship. To transfer a crew member, first set their current ship's crew to **Unassigned**.

There are **36 catalog entries**:

- 14 component schematics: four standard and ten alternative fittings, with bonuses and trade-offs.
- 11 crew collectibles: six human astronaut appearances and five alien appearances from four species (Vesperi, Kharon, Auralith and Drakari).
- 6 ship liveries: the standard fleet livery and five class-specific rare variants.
- 5 collectible hulls: all five classes can be won and traded. The three starter classes also remain available as fleet issue.

A new commander starts with four standard component schematics, three astronauts and the standard fleet livery: **8 discovered entries**. Open **Collection & Commander** to filter items, inspect portraits and bonuses, edit your commander name, review lifetime combat totals, or research undiscovered standard equipment and crew with salvage.

Complete a battle to gain free discovery rolls and salvage. Victory gives **one permanent random ship hull, 2 collectible rolls and 60 salvage**; defeat or draw gives **1 roll and 30 salvage**. A duplicate adds **15 salvage** and increases that entry's recovery count. Abandoning a match grants no reward. Research provides a predictable route to non-cosmetic equipment and standard crew; appearance variants can only be discovered in battle salvage.

Per-roll rarity chances: **Mythic 1/16,384 (0.0061%), Legendary 1/4,096 (0.0244%), Rare 819/16,384 (~5%), Uncommon 3,932/16,384 (~24%), Common 11,628/16,384 (~71%)**. These tiers are disjoint. The selected tier picks uniformly among its entries. Legendary and Mythic items are appearance variants; variant crew have the same combat bonus as their standard counterpart. Rare ship variants add distinctive hull colors, fins, trim, rings or energy ribbons without a power bonus.

## Local saving and updates

Loadouts, inventory, discovery timestamps, commander name, salvage and battle statistics save automatically to `user://commander_profile.json`. On Windows this is normally:

```text
%APPDATA%\Godot\app_userdata\Galactic Dominion\commander_profile.json
```

Paste `%APPDATA%\Godot\app_userdata\Galactic Dominion` into File Explorer's address bar to find the folder. Settings remain in `settings.cfg`. Local saves do not synchronize with the separate online account inventory.

Updates use the same Godot application name, so extracting a new build to another folder retains your local profile. The version-2 local save migrates version-1 profiles from the previous build without discarding their inventory. The save uses a versioned format, a temporary file for replacement, and a `.bak` copy of the previous save. Unreadable primary saves are preserved as `.corrupt-*` files before recovery; newer unsupported save versions are preserved with saving disabled. The menu and hangar display save failures rather than silently claiming success. This is a local prototype; saves are editable and not suitable as authoritative multiplayer inventory.

## Test the new features

1. Open Fleet Hangar and inspect each ship and all six slots.
2. Open Collection & Commander; inspect the alien portraits and rare ship variants, including undiscovered entries.
3. Finish a battle and check the reward list. Click **Review Discoveries / Hangar**.
4. Spend salvage researching a component. Fit it, check the changed statistics and preview geometry, then deploy.
5. Assign an unlocked alien to a ship. Unassign an existing crew member to transfer them between ships.
6. Rename the commander. Quit and restart Godot; check that name, inventory, salvage and loadouts remain.
7. If a rare ship appearance drops, fit it to its compatible class and inspect its appearance in the hangar and battle.

## Controls

| Input | Action |
| --- | --- |
| W / S | Forward / reverse thrust |
| A / D | Strafe left / right |
| Space / Ctrl | Ascend / descend |
| Mouse | Steer (relative input with a decaying steering offset) |
| Q / E | Roll |
| Shift | Boost; consumes a regenerating reserve |
| Left mouse button | Hold to fire primary lasers |
| Tab | Cycle enemy targets |
| Right mouse button | Fire tracking missile after lock |
| R | Ship class ability |
| F1 / F2 / F3 | Control Interceptor / Skirmisher / Guardian |
| 1 / 2 / 3 / 4 / 5 | Fleet: Follow / Attack selected target / Defend / Regroup / Retreat |
| G | Hold to scan a nearby exploration signal |
| M | Exploration sector chart |
| Esc | Pause/settings; online combat continues while the menu is open |

Keep a selected enemy within the forward cone and within 600 metres for 1.2 seconds to lock missiles. Shields regenerate after four seconds without damage. Destruction of the controlled ship switches to a surviving friendly ship.

## Suggested manual test

- Deploy and use thrust, reverse, strafing, vertical movement, rolling and mouse steering. Release thrust to check drift and gradual deceleration.
- Hold Shift while moving; watch boost reserve drain and recover.
- Tab to select an enemy. Align with it; verify the HUD changes to MISSILE LOCK. Fire lasers and missiles and watch enemy shield and hull bars.
- Switch with F1–F3. The previous vessel should continue flying under AI control. Activate each ability with R: speed surge, weapon overcharge, and the Guardian's 90-metre protective aura.
- Issue each fleet command with 1–5. Attack uses the target selected when the command is issued. Defend intercepts nearby threats; regroup holds formation; retreat prioritizes shield recovery.
- Fly outside the cyan safe-zone rings and verify the warning and increasing damage. Return to the centre to reset exposure.
- Esc pauses combat. Change sensitivity, invert Y, and fullscreen in Settings; resume. Settings persist locally.
- Eliminate the opposing fleet or lose your own to see results, damage totals, kills and projectile accuracy. Test Deploy Again and Main Menu.

## Rules

Six ships spawn in opposing fleets. Friendly AI follows the active pilot and engages nearby enemies; enemies seek the nearest opponent. Depleted shields trigger AI retreat until shields recover. Static asteroids have collisions and AI ray-based avoidance; small debris is decorative.

The spherical zone starts at 600 metres, begins shrinking after 30 seconds, and reaches 95 metres by 7:30. Outside damage starts at 8 per second and increases by 2 per second for each second of continuous exposure. The match lasts at most eight minutes. Fleet elimination decides the winner; at timeout the sum of surviving normalized hull and shield fractions breaks the tie. Equal scores produce a draw.

## Architecture

`scenes/main.tscn` is the entry scene. The battlefield and component scene trees are constructed in GDScript so the prototype needs no imported art dependencies.

- `scripts/ships`: ship composition, Resource statistics, momentum movement and pilot/camera input.
- `scripts/combat`: health/shield signals, extensible weapon specs, cooldowns, swept-ray projectiles, homing and target locking.
- `scripts/ai`: behavior states, nearby perception, patrol steering, obstacle avoidance and alien companion targeting/attacks.
- `scripts/fleet`: control ownership, switching and command propagation.
- `scripts/match`: spawning, ability aura aggregation, timer, team elimination and results.
- `scripts/world`: deterministic arena, safe zone, connected free-roam regions/stations and transient combat effects.
- `scripts/visuals` and `resources/shaders`: shared cartoon materials, outline shader and original 3D alien meshes.
- `scripts/ui`: HUD, projected health/target markers, results, fleet hangar, 3D preview and primitive crew portraits.
- `scripts/progression`: collectible definitions, catalog, fitting validation, stat composition, reward settlement and local profile persistence.
- `scripts/exploration`: Resource-defined sectors, scans, patrol encounters, chart navigation and discovery records.
- `scripts/online`: HTTP account client, ENet lobby, authoritative simulation, bounded inputs and snapshot presentation.
- `server`: Python/SQLite account, profile, escrow/offer/market and combat reward service, plus a cross-platform launcher.
- `resources/collectibles`: 36 reusable `.tres` collectible definitions.
- `resources/ships`: reusable Interceptor, Skirmisher, Guardian, Bomber and Support `.tres` definitions.

Add a ship class by creating another `ShipStats` Resource; the movement and weapon systems read its values. Add weapons by extending `WeaponSpec` and the projectile/weapon behavior. Input ownership is separated from simulation. The online server simulates all ships; clients present snapshots. Prediction and lag compensation are future work.

## Automated checks actually run

- Godot headless editor import and main-menu startup. Restricted-sandbox editor debug sockets were unavailable; script imports and the real renderer completed.
- `tests/smoke_test.gd`: **38 checks passed**, including spawning, switching, abilities, commands, damage, regeneration, laser/missile impacts, momentum, boost, zone escalation, destruction, victory/defeat, timeout and menu cleanup.
- `tests/progression_test.gd`: **51 checks passed**, including catalog integrity, research costs, fitting ownership, wrong-slot/class rejection, crew transfers, Resource isolation, duplicate rewards, save/reload, backup recovery, malformed-save repair, future-version preservation, real hangar callbacks, rare appearance geometry and match reward integration.
- `tests/exploration_test.gd`: **16 checks passed**, including sector spawning, scans, repeat-reward rejection, patrol rewards, warp, hull unlocks, Bomber/Support abilities, discovery persistence, save migration and online UI creation.
- `tests/online_presentation_test.gd`: **11 checks passed** for replicated health, boost, locking, cooldowns, destruction, zone/timer, projectile cleanup, control transfer and correct team-two victory/defeat messages.
- `tests/test_service.py`: **21 Python tests passed** for authentication, single-use tickets, fitting/research rules, listing/offer escrow, simultaneous purchase rejection, public profile privacy and idempotent authoritative rewards.
- `tests/test_network_integration.py`: this build: a real dedicated-server run with **two Godot clients** (the previous build also passed six-client testing), testing authentication, ready lobbies, server-owned movement, switching/ownership, result delivery, protected reward endpoints and persisted rewards. HTTP checks also cover actual service routes for registration, profiles, fittings, offers and trade settlement.
- `tests/test_launcher.py`: a fresh copy of this build imported successfully, generated its private server key, started the account and combat services, passed readiness checks and shut down cleanly.
- `tests/ai_battle_test.gd`: an autonomous six-ship battle completed with a Ravagers victory at **20.42 simulated seconds**, dealing **545.0 total damage**.

- `tests/free_roam_test.gd`: **33 checks passed** for connected world population, indefinite flight, warp validation, repairs, exploration records, permanent rewards, recurring patrols, respawning, launch protection, actual pause and client authority.
- `tests/alien_companion_test.gd`: **22 checks passed** for crew binding, original mesh details, orbit motion, enemy selection, real projectile damage/credit, cooldowns, friendly-fire/range rejection, rare-appearance parity, host destruction/redeployment, preview behavior, save/reload and client authority.
- `tests/test_free_roam_network.py`: **two real Godot clients** verified joining an active world, replicated hull fitting and NPCs, travel, station service, a real automatic companion projectile kill, controlled PvP damage, station respawn, persisted/tradable rewards, inventory unlock and protected server endpoints. The server fixture parks AI and injects PvP damage for reproducibility; the companion projectile itself runs the normal combat code.
- `tests/render_preview.gd` and `tests/render_flight.gd`: actual **1280 × 720 OpenGL renders** inspected using Mesa software rendering. A manual interactive playtest and Internet/VPS deployment were not completed.

Run from the project directory:

```sh
godot --headless --editor --import --path . --quit
godot --headless --path . --script res://tests/smoke_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/progression_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/exploration_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/online_presentation_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/free_roam_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/alien_companion_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/ai_battle_test.gd --fixed-fps 60
python -m unittest discover -s tests -p test_service.py -v
python tests/test_network_integration.py
python tests/test_free_roam_network.py
```

If your sandbox does not allow Godot to write its user directories, set `XDG_DATA_HOME`, `XDG_CACHE_HOME`, and `XDG_CONFIG_HOME` to writable directories for those commands.

## Current limits

This is a playable prototype using primitive meshes, simple ray-based obstacle avoidance and synthesized placeholder sound effects. The modes have automated combat/network checks and inspected scripted renderer captures; manual interactive playtests and real Internet/VPS deployment have not been completed. The online server handles one arena or free-roam session per process, with basic quick-join rather than a worldwide matchmaking directory. Prediction, lag compensation, reconnecting into an ongoing Fleet Royale match, moderation, account recovery, large population scaling and a production economy remain future work. The self-hosted API needs an HTTPS reverse proxy for Internet accounts. No external service was published.
