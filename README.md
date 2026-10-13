# Galactic Dominion — Phase 2: Hangar & Discovery

A single-player Godot 4.x 3D Fleet Royale game prototype with a persistent fleet hangar, collectible crew, interchangeable components and rare appearances. Uses only primitive meshes and GDScript. Validated with Godot 4.6.3. No plugins, paid assets, or network access required.

## Open and play

1. Install Godot 4.x (the standard version; .NET is not required).
2. Extract the project folder if downloaded as a ZIP.
3. In Godot's Project Manager click **Import**, select `project.godot`, and open it.
4. Press **F5** (Run Project).
5. Click **PLAY / DEPLOY FLEET**. The mouse is captured for steering; **Esc** pauses and releases it.

From a terminal: `godot --path /path/to/galactic-dominion`.


## New in this build: Hangar & Discovery

From the main menu open **FLEET HANGAR / COLLECTION**. Use the fleet buttons or F1–F3 to inspect your three ships, then select fittings from the dropdowns. The rotating 3D preview shows fitted hardware and ship variants. Your base Interceptor, Skirmisher and Guardian remain available permanently.

Each ship has six slots: engine, shield, weapon, utility, crew and variant. The hangar displays the resulting hull, shields, regeneration, speed, turning, boost capacity, laser/missile output and ability recharge. Loadouts affect your next deployed battle. Component schematics can be fitted to multiple ships; a named crew member can serve aboard only one ship. To transfer a crew member, first set their current ship's crew to **Unassigned**.

There are **25 catalog entries**:

- 12 component schematics: four standard and eight alternative fittings, with bonuses and trade-offs.
- 9 crew collectibles: five human astronaut appearances and four alien appearances from three species (Vesperi, Kharon and Auralith).
- 4 ship liveries: the standard fleet livery and three class-specific rare variants.

A new commander starts with four standard component schematics, three astronauts and the standard fleet livery: **8 discovered entries**. Open **Collection & Commander** to filter items, inspect portraits and bonuses, edit your commander name, review lifetime combat totals, or research undiscovered standard equipment and crew with salvage.

Complete a battle to gain free discovery rolls and salvage. Victory gives **2 rolls and 60 salvage**; defeat or draw gives **1 roll and 30 salvage**. A duplicate adds **15 salvage** and increases that entry's recovery count. Abandoning a match grants no reward. Research provides a predictable route to non-cosmetic equipment and standard crew; appearance variants can only be discovered in battle salvage.

Per-roll rarity chances: **Common 70%, Uncommon 24%, Rare 5%, Exotic 0.9%, Mythic 0.1%**. The selected tier picks uniformly among its entries. Exotic and Mythic items are appearance variants; variant crew have the same combat bonus as their standard counterpart. Rare ship variants add distinctive hull colors, fins, trim, rings or energy ribbons without a power bonus.

## Local saving and updates

Loadouts, inventory, discovery timestamps, commander name, salvage and battle statistics save automatically to `user://commander_profile.json`. On Windows this is normally:

```text
%APPDATA%\Godot\app_userdata\Galactic Dominion\commander_profile.json
```

Paste `%APPDATA%\Godot\app_userdata\Galactic Dominion` into File Explorer's address bar to find the folder. Settings remain in `settings.cfg`. There is no cloud synchronization or trading server.

Updates use the same Godot application name, so extracting a new build to another folder retains your local profile. The save uses a versioned format, a temporary file for replacement, and a `.bak` copy of the previous save. Unreadable primary saves are preserved as `.corrupt-*` files before recovery; newer unsupported save versions are preserved with saving disabled. The menu and hangar display save failures rather than silently claiming success. This is a local prototype; saves are editable and not suitable as authoritative multiplayer inventory.

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
| Esc | Pause, settings, or main menu |

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
- `scripts/ai`: behavior states and separate steering/obstacle avoidance.
- `scripts/fleet`: control ownership, switching and command propagation.
- `scripts/match`: spawning, ability aura aggregation, timer, team elimination and results.
- `scripts/world`: deterministic arena, safe zone and transient combat effects.
- `scripts/ui`: HUD, projected health/target markers, results, fleet hangar, 3D preview and primitive crew portraits.
- `scripts/progression`: collectible definitions, catalog, fitting validation, stat composition, reward settlement and local profile persistence.
- `resources/collectibles`: 25 reusable `.tres` collectible definitions.
- `resources/ships`: Interceptor, Skirmisher and Guardian `.tres` definitions.

Add a ship class by creating another `ShipStats` Resource; the movement and weapon systems read its values. Add weapons by extending `WeaponSpec` and the projectile/weapon behavior. Input ownership is separated from simulation, but multiplayer authority, replication and reconciliation are not implemented.

## Automated checks actually run

- Godot headless editor import and main-menu startup.
- `tests/smoke_test.gd`: **38 checks passed**, including spawning, switching, abilities, commands, damage, regeneration, laser/missile impacts, momentum, boost, zone escalation, destruction, victory/defeat, timeout and menu cleanup.
- `tests/progression_test.gd`: **48 checks passed**, including catalog integrity, research costs, fitting ownership, wrong-slot/class rejection, crew transfers, Resource isolation, duplicate rewards, save/reload, backup recovery, malformed-save repair, future-version preservation, real hangar callbacks, rare appearance geometry and match reward integration.
- `tests/ai_battle_test.gd`: an autonomous six-ship battle completed with a Vanguard victory at **235 simulated seconds**, dealing **3644.3 total damage**.

Run from the project directory:

```sh
godot --headless --editor --import --path . --quit
godot --headless --path . --script res://tests/smoke_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/progression_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/ai_battle_test.gd --fixed-fps 60
```

If your sandbox does not allow Godot to write its user directories, set `XDG_DATA_HOME`, `XDG_CACHE_HOME`, and `XDG_CONFIG_HOME` to writable directories for those commands.

## Current limits

This is a prototype with placeholder meshes, simple AI and no audio. A graphical, interactive playtest was not completed in the development environment; camera feel, visual readability, balance and obstacle behavior require manual testing. Collision avoidance is heuristic rather than path planning. Collection and customization now work locally. Galactic exploration, trading, public online profiles and multiplayer remain future milestones. The new hangar and portraits were checked through headless UI integration tests; a rendered interactive playtest of this expansion has not been completed.
