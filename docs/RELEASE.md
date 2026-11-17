Galactic Dominion v0.44.0 — Dogfight Upgrade

A more readable and dependable version of the existing combat game. Free roam, wildlife expeditions, sanctuary, orbiting companions and self-hosted online play remain available; the scripted story stays disabled by default.

- **Aim ahead of moving ships:** Tab favors enemies near your aim, and a lead diamond uses actual laser interception. Amber means turn toward it; mint indicates the existing assistance cone. Player lasers use the same solution, with no damage or cone bonus.
- **Use cover:** missile locks require a clear path within 600m. Blocked, out-of-range, misaligned and reloading shots explain their refusal; a blocked launch does not spend its cooldown.
- **Read incoming threats:** directional missile alerts show bearing, distance and an approximate closing estimate, prioritizing urgent threats. Old hull warnings clear when switching ships.
- **Command every survivor:** [ / ] cycle all offline allies in 10v10 and Armada. Fleet rows show valid keys and vessel numbers; co-op allied rows stay separate and identify your ownership group.
- **Steadier flight:** boost recovery prevents rapid empty-reserve pulses, HUD/FOV follow actual thrust, and the chase camera avoids scenery with frame-independent smoothing.
- **Comfort options:** Settings adds reduced camera motion and a lead-guide toggle. Existing save protections, atlas routes, co-op reward retries and rare component odds remain.

**Windows:** download Galactic-Dominion-Windows.zip, extract the entire folder and run GalacticDominion.exe. **Linux:** extract Galactic-Dominion-Linux.zip and run GalacticDominion.x86_64. Players do not need Godot. M fires missiles; Tab selects targets; F1–F3 select your first ships; [ / ] cycle offline survivors. All actions can be rebound in Settings.

Schema remains 11; existing collections and progression are retained. Update online clients and hosts together to v0.44.0. Large fleet modes use AI; online still supports six humans. Shared planet/wreck interiors and pending-payment recovery after killing a host remain unfinished.

Validation: 903 local Godot checks across 28 suites, including a real moving-target laser impact; native Linux HUD views and captured bracket-key input; real two-client HTTP/ENet arena and co-op runs. Release CI runs backend, difficulty, disconnect/retry and packaged Linux/server checks. Windows GUI, physical controllers, target-PC performance and human combat balance still need playtests.

[Combat guide and validation details](https://github.com/trentsmith/Galactic-Dominion/blob/phase-44-combat/docs/COMBAT_HANDLING.md).
