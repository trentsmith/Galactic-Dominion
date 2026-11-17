Galactic Dominion v0.43.0 — Flight Polish

This update improves the existing flight, exploration, controls and co-op loops. Free roam remains the default; wildlife, sanctuary trips and orbiting companions remain available, and the scripted campaign stays optional and disabled by default.

- A failed checkpoint keeps the current expedition open. Before changing activities or quitting, choose to keep playing or explicitly leave without unsaved progress. Undelivered surveys receive the same protection; completed deliveries return to orbit normally.
- Keyboard, mouse and gamepad button remaps save independently, including migration from previous settings. Combat and course prompts reflect the current bindings.
- Completed jobs, recovered components and mined deposits stop drawing stale course markers. Claimed badges clear their pinned goal, and empty atlas searches explain filters and sensor requirements.
- Mining gives specific distance, obstruction and fracture guidance; mineral and component recovery prompts avoid overlapping.
- Co-op job participation follows accounts rather than mutable ship slots. Payments retry before departures/session closure, including when a participant disconnects during payment or a committed payment's reply is lost. Duplicate payment receipts remain idempotent. Team pings expire even if updates stop.
- Unchanged automatic checkpoints avoid redundant file writes; manual saves and failed-write retries remain active.

Download the appropriate client ZIP, extract the entire folder, and run **GalacticDominion.exe** on Windows or **GalacticDominion.x86_64** on Linux. No Godot installation is required for players. Existing controls remain: **M** missiles, **O** Frontier/atlas/journey, **J** chart, lasers fracture deposits, **hold F** within 75m to tractor materials, **K** recover components, **G** service stations, **L** land at eligible planets.

Save schema stays at 11 and reads existing profiles. Update online hosts and every client together to v0.43.0. Local and online inventories stay separate. Legendary/mythic component odds are unchanged. Shared planet/wreck interiors and durable recovery of pending payments after a server restart remain unfinished. Windows GUI, physical-controller and human balance playtests remain pending.

Validation: 824 local Godot checks across 25 suites; 30 account-service tests; normal and fault-injected real two-client HTTP/ENet runs. Native Linux renders inspected for departure warnings, remapped combat prompts and empty atlas guidance. See [the polish guide](https://github.com/trentsmith/Galactic-Dominion/blob/phase-43-polish/docs/POLISH.md) for details and reproduction commands.
