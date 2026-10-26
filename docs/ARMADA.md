# Uncharted Armada — 200v200

Choose DEPLOY ARMADA on the title screen, or use `-- --armada`. The match contains one human pilot, 199 AI allies and 200 AI enemies. Online remains six pilot slots. Existing solo 3v3, 10v10 and story modes remain separate.

## Sector and sensors

The safe sphere begins at radius 5,200m. Each match picks a new seed and scatters forty ten-ship squadrons, sixteen asteroid fields (up to 448 collision asteroids), two stars, two black holes and eight relic sites. Terrain variants and materials are shared instead of generating a unique mesh for every rock. The seed is shown on the chart for diagnostics; tests can supply a seed to `start_armada(seed)`.

Enemies are initially beyond sensor range. Tab and AI target selection use an 1,100m range. J opens the X/Z chart: allied positions and mapped terrain are visible, enemy positions require local detection. Flight continues; J closes it. The chart closes automatically at the results screen. Sensors are range-based, not an asteroid-occlusion stealth simulation.

Stars influence ships within 650m, producing inward pull and sideways drift. Their 110m hot core deals 55 damage/second through normal shields and protection. Black holes pull within 800m; their 65m event horizon destroys ships. Hazards affect both teams; AI tries to avoid them. Drift is capped and decays outside fields, and boost can help escape. These are accessible arcade rules rather than orbital physics. Damage reports identify stellar corona and black hole causes.

## Fleet and relics

F1–F10 selects the first ten allies; [ and ] cycles through all survivors. Commands 1–5 apply to the fleet. No respawns; the last fleet standing wins. The zone contracts and collapses after eight minutes under the existing elimination rules.

Approach a relic within 32m if the ship has none. B fires; three charges, 12 seconds between shots, pickup respawn after 90 seconds. Equipment belongs to that live ship and never enters permanent inventory. Both sides can collect and use it.

- Solar Lance: aligned 1,100m beam, 16m target tolerance, 130 damage per enemy. Static obstacles block it and allies are protected. AI waits for alignment within 900m.
- Gravity Nova: 80 damage and a brief slow to enemies within 140m, blocked by obstacles. Allies are protected.

## Architecture and measured limits

`ArmadaSector` owns seeded layouts, hazards, spawn/search points and gravity. `ArmadaChart` presents range-limited contacts. `BattleSpatialIndex` rebuilds alive-ship cells at 10 Hz with conservative margins; exact range tests follow. AI search, Guardian support and repairs use nearby candidates. Obstacle probes run about five times per second in Armada, with cached steering between probes. Relic proximity checks run five times per second and only loaded weapons need AI firing checks.

`ArmadaArt` merges the authored class hull geometry into five shared meshes and team materials. Decorative transparent engine cards are omitted from the merged hull. Taking over promotes a reinforcement to its full model; releasing it restores the merged model. Main fitted ships retain full visuals. Armour palettes and panel wear are refined across ship classes.

Local final benchmark: 2,400 physics frames / 40 simulated seconds in 30.21 wall seconds, 3,243.6 confirmed damage, 190 allied and 182 opposing survivors. This is headless simulation on a shared development machine. It does not measure GPU FPS, prove 400-player networking or replace human playtests.

Run `godot --headless --path . --script res://tests/armada_test.gd --fixed-fps 60` and `res://tests/armada_sector_test.gd` for live combat and sector checks. Test actual Windows graphics, long matches and balance before treating this experimental mode as production-ready.
