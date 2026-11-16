# Galactic Dominion — The Frontier

A Godot 4.6.3 space-combat and exploration prototype with configurable 1–200 fighter fleets, five ship classes, Nexus faction hulls, orbiting companions, wildlife expeditions, a personal sanctuary and self-hosted online play. GDScript and procedural 3D assets; no paid packages required.

## Play

Download [v0.41.0](https://github.com/trentsmith/Galactic-Dominion/releases/tag/v0.41.0), extract the entire client ZIP, and run **GalacticDominion.exe** on Windows or **GalacticDominion.x86_64** on Linux. Players do not need Godot. Back up your commander profile before upgrading: schema 10 reads previous saves, but older builds cannot read new saves.

For source development, clone the `phase-41-frontier` branch. Open **Godot 4.6.3 → Import → project.godot → Import & Edit**, then press **F5**. Open-world flight is now the main menu's primary action.

## Fly your own course

Choose **Enter the Frontier**, then **O** for optional jobs, faction standing, companion protocols and home facilities. There is no mandatory campaign checklist. Peaceful Flight keeps raids and environmental damage off.

- Rescue pods and repair disabled vessels: **hold F** with a clear path within **90m** (three or four seconds).
- Escort couriers: stay within **150m** and clear hostile jammers inside **110m**.
- Board a wreck: **F within 100m**, outside combat. Walk with your bot, hold **G within 4m for two seconds** at each of three consoles, avoid the pulsed security grid, then **E within 6m of the airlock** to return with the black box.
- Decode component rumors after your first job or observatory upgrade. Recover the indicated real cache with **K**; clues do not guarantee a rare part.
- After three completed jobs, combat-board batches can offer a siege captain. Break its three amber anchors to remove armor, then defeat it. Peaceful batches offer couriers instead.

Five completed slots generate a new board. Jobs have six-minute windows. Completed rewards save immediately and retry if saving fails. Abandoning, timing out or leaving an unfinished job gives no reward; active job progress restarts when the session ends. [Frontier guide and implementation](docs/FRONTIER.md).

## Reputation, companions and home

Job completion adds **8 standing** with its patron; destroying a faction patrol costs **4**. At **+24** its patrols become friendly in solo space. At **−20** a faction intercepts you when you enter its sectors, once per sector per flight.

Equip a non-human officer in **Fleet & collection → Crew** to spawn an orbiter. Choose its protocol in O: **Striker**, **Scout**, **Guardian** or **Engineer**. Protocols apply on the next deployment. Human crew do not spawn bots. Scouts extend salvage sensing; guardians intercept a nearby hostile missile every eight seconds; engineers repair hull after incoming damage stops. Support roles trade some attack damage for their utility.

Spend salvage on a **repair dock**, **observatory/gallery** or **workshop** (three levels each). The workshop consumes sanctuary ore, fiber and bloom to fabricate selected permanent standard blueprints. Fit them in Fleet Hangar for your next deployment. Local facilities and roles stay separate from online accounts.

## Land, track and rescue wildlife

Choose **Planet expeditions**, or approach an owned planet in solo flight and press **L**. **J** opens the chart and landing bot picker. **T** selects a species to track; its recent movement leaves a bounded footprint trail. Distant predators can hunt nearby passive wildlife away from your current encounter.

Hold **G for two seconds within 12m** to scan. **LMB** stuns dangerous animals non-lethally; **C within 8m** captures a surveyed eligible creature. Dangerous fauna must reach half health first. **E within 10m of your landing ship** delivers surveys and secured cargo to the sanctuary. **B** switches exploring bots at the ship; **F** gathers seeds. R/N/V/Z deploy, select, attack with and recall your surface creature party. Delivery failures remain retryable. Creatures stay out of space combat; orbiting bot companions remain active.

Planet animals retain restrained biological faces. Your bot companions keep their expressive faces. Landed trips return to the same orbital session.

## Online and other modes

**Online → Launch Co-op Frontier** creates one allied team for up to six human pilots, with AI in empty ship slots. The lobby leader starts shared rescue, repair or escort work from O. The combat host validates participation, and the account service grants each eligible pilot a fixed reward once per event. Players may join an already running space session. PvP Free Roam, Fleet Royale, public profiles and trading remain available. Update clients and server together. [Windows PC hosting](server/README.md).

**Planet and wreck interiors are solo-only.** Online has six pilot slots, not 400 human players; Armada's extra fighters are AI. Host authority is trusted, not a hardened commercial anti-cheat service.

**Armada:** choose 1–200 fighters per side, asymmetric fleets, randomized sectors, asteroids, stars, black holes and temporary mega weapons. **Fleet Royale/Fleet War:** 3v3 or 10v10 last fleet standing. **Flight School:** safe interactive tutorial. [Armada](docs/ARMADA.md), [AI tuning](docs/ARMADA_AI.md).

## Rare ship parts

Hold **K for two seconds within 60m** of a gold space cache (6m on a planet). The first cache guarantees an uncommon part; twelve discoveries refresh a batch. Schematics save immediately, and duplicates grant 15 salvage. Later odds remain **legendary tier 1/4,096; mythic tier 1/65,536**. No pity guarantee or rumor bonus changes these rolls. Local discoveries remain separate from the online marketplace. [Exact odds](docs/COMPONENT_DISCOVERY.md).

## Controls and settings

W/S thrust/reverse; A/D strafe; Space/Ctrl vertical movement; mouse aim; Q/E roll; Shift boost. LMB laser, **M missile**, R ability, Tab target. F1–F3 switch fleet ships; 1–5 give orders. Armada also uses [ / ] to cycle survivors. J chart, G scan/service, K recover parts, F job interaction, O Frontier board, H scenic HUD, Esc menu. Online flight continues while menus are open.

Settings has **Low/Medium/High** graphics, larger menu text, reduced explosion flashes, mouse sensitivity/inversion, volume, fullscreen and input rebinding. Gamepad defaults: left stick moves, right stick aims, triggers fire, bumpers move vertically, A boosts, Y targets, X activates abilities, D-pad up scans/interacts, Back opens the Frontier board, B captures on planets. Other actions can be assigned under **Controls / Rebind Inputs**. Axis defaults remain fixed; key, mouse and gamepad button bindings can be changed. Hardware controller feel still needs human playtesting.

## Archived campaign

The authored **Fractured Relay** and biological story are retained with their saves. `gameplay/campaign_enabled=false` disables campaign guidance and progression hooks by default. Developers can re-enable it with that setting or `GD_ENABLE_CAMPAIGN=1`; the older `GD_ENABLE_CREATURES=1` development mode also enables its campaign. Wildlife and companion flags remain independent.

Past endings have small free-roam consequences: Seal adds a reconstruction tender's repair aura near Vesper; Preserve adds a contained memory echo and longer salvage bearings. No previous campaign is required to explore or progress. [Archived narrative](docs/NEXUS_FLEET_CAMPAIGN.md).

## Validation

706 Godot checks across 21 suites and 27 account-service tests passed locally, plus a real two-client HTTP/ENet co-op session. Linux Frontier board, wreck and settings renders were inspected. See [Frontier validation and remaining scope](docs/FRONTIER.md). Windows GUI, physical gamepad testing and human balance playtests remain pending.
