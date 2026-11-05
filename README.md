# Galactic Dominion — Nexus Fleet Campaign

A Godot 4.6.3 3D space-combat prototype with an original Nexus Archives fleet story, configurable 1–200 fighter fleets, five ship classes, persistent customization, extremely rare exploration components and self-hosted online spaceflight. Uses GDScript and procedural 3D assets; no paid assets or plugins required.

## Play the current build

Download the Windows or Linux client from [v0.39](https://github.com/trentsmith/Galactic-Dominion/releases/tag/v0.39.0). Extract the whole ZIP. On Windows run **GalacticDominion.exe**; no Godot installation is needed. Back up your commander profile before upgrading. Saves migrate to schema 9, which older builds cannot read.

For source development, download/clone the `phase-39-nexus-story` branch, open Godot 4.6.3, click **Import**, select `project.godot`, then press **F6** for the current scene or **F5** for the full project.

## Start with Story / Journal

Press **O** or choose **STORY / JOURNAL**. **The Fractured Relay** now follows a frontier evacuation network caught between Marshal Veyr's Crimson fleet and the voices aboard a returned Eldritch ship. Sera is looking for her missing brother; Astra has concealed the expedition orders; Milo wants every journey to have a way home.

1. Accept Astra's commission.
2. **Lanterns over Varkhoss, 3v3:** defeat the Interdictors, then hold **G for three seconds within 95m** of the civilian relay to transmit its routes. Nearby Interdictors jam and drain it. Preserve at least 70% integrity for a one-time Lantern Keeper commendation (+25 salvage). The commission unlocks the Sprint Drive and Bloodforged hull.
3. Recover a component cache in solo Free Roam: **hold K for two seconds within 60m** of a gold beacon. A journal waypoint points to the nearest available cache.
4. Fit a non-standard engine to F1 in Fleet Hangar. The Sprint Drive is already owned; fitting applies on launch.
5. **The ship that came home, 3v3:** defeat Mnemosyne's wardens, avoid the four-second anomaly warning, then hold **G for four seconds within 95m** of the returned vessel. The decoded recording unlocks the living hull and reveals the missing expedition's fate.
6. **A door, not a weapon, 10v10:** choose a fracture protocol before launch. **Seal** requires three conduit handshakes (G, two seconds within 95m). **Preserve** requires escorting a memory core to its beacon: stay within 150m and clear enemy jammers inside 110m. Both require the enemy fleet defeated. Launching locks your chapter's choice.
7. Read your debrief, then archive the transmission with Astra for the one-time **100 salvage** reward and your route's epilogue.

In-flight radio never pauses combat. The journal has Briefing, Recordings, Nexus dossiers and Sortie record tabs. Completed missions can be replayed from Sortie record. Replays keep your progression and do not repeat commission unlocks or chapter payouts; ordinary battle salvage still applies. A first-time commendation may be earned on a replay.

Your choice changes the final objective, transmissions and ending. This is a text-led solo opening chapter with three authored sorties, not a voiced cinematic campaign or an online story. Each sortie has an eight-minute deadline. Defeat leaves its objective retryable; save failures explain that progress was not recorded. Older completed saves retain their completion and can access enhanced replays without being paid twice. [Narrative, migration and controls](docs/NEXUS_FLEET_CAMPAIGN.md).

## Nexus faction ships

**Varkhoss Prime / Crimson Dominion:** angular blood-red armor, jagged fins, reactor seams and siege pylons. Campaign enemies trade speed and shielding for stronger hulls and laser fire.

**Ny'Zaroth / Eldritch World:** curved chitin plates, crescent silhouettes, luminous veins and cosmic cores. Campaign enemies have more speed and shield regeneration with lower hull/shield capacity.

Both faction appearances work across Interceptor, Skirmisher, Guardian, Bomber and Support. Class geometry and existing class abilities remain distinct. Faction unlocks are cosmetic; campaign AI stat tuning belongs to its encounter. Full teleportation and reality-fracture mechanics are not implemented. Armada reinforcement meshes remain shared by class/faction for efficiency.

## Other modes

- **Armada:** independently choose 1–200 fighters on each side, including asymmetric fights. The player's fleet count includes the pilot. Random sectors, sensor-limited contacts, asteroids, stars, black holes and temporary mega weapons. [Armada guide](docs/ARMADA.md), [AI tuning](docs/ARMADA_AI.md).
- **Fleet Royale / Fleet War:** 3v3 or 10v10 last-fleet-standing combat.
- **Flight School:** safe interactive flight/combat tutorial.
- **Free Roam / Peaceful Flight:** space exploration, signals, faction ships, stations and salvage recovery.
- **Fleet & collection:** permanent hulls, components, human/alien officers and appearances. Orbiting bot crew are selectable and eligible for rewards again; animal-themed ship skins remain archived.
- **Online:** self-hosted six-pilot space sessions and marketplace; local and online inventories remain separate. Update server and clients together to v0.39. [Windows hosting](server/README.md).

## Discover ship parts

Follow gold COMPONENT SALVAGE bearings in solo Free Roam, approach within **60m**, then hold **K for two seconds** with a clear path. The first recovery guarantees an uncommon part. Twelve recovered caches refresh the local batch. Parts save immediately as reusable schematics; fit them for the next deployment. Duplicates grant 15 salvage. Failed saves leave the cache available to retry.

Later cache odds: **legendary tier 1/4,096; mythic tier 1/65,536**. Four legendary and two mythic relic parts are cache-exclusive, with tradeoffs rather than automatic superiority. There is no pity guarantee. These discoveries remain solo-only. [Exact odds and components](docs/COMPONENT_DISCOVERY.md).

## Controls

W/S thrust/reverse; A/D strafe; Space/Ctrl vertical movement; mouse steering; Q/E roll; Shift boost. Left click laser, **M missiles**, R class ability, Tab target. F1–F3 switch lead ships; Fleet War supports F1–F10 and Armada additionally uses [ / ] to cycle survivors. 1–5 issue fleet commands. J star chart, G scan/service, K salvage recovery, O journal, H scenic HUD, Esc pause/menu. Online simulation continues while menus are open.

## Orbiting companions are back

In **Fleet & collection → Fleet Hangar**, select a ship and equip a discovered non-human bot in its **CREW** slot. Pixlet, Cinderbit, Lunaflutter, Orbitot and Glimbloom are available again. Orbitot and Glimbloom can also be researched through the collection panel. Human officers do not spawn an orbiting bot. Existing companion ownership and fitting data remain valid. Companions keep their existing orbital animation and AI attacks; the Nexus ship models and spaceship campaign remain active.

The independent setting `gameplay/companions_enabled=true` enables orbiters while `gameplay/creatures_enabled=false` keeps planet animals out. Animal-themed ship skins remain archived, preserving the Nexus hull direction.

## Creatures are archived, not deleted

Wildlife spawning, surface landing, capturing, sanctuary activities and the biological story are disabled in the default release. Their scripts, scenes, resources and saved records remain intact. A single feature switch restores the archived mode for development; no data conversion is needed. [Restoration instructions and implementation](docs/NEXUS_FLEET_CAMPAIGN.md), [historical feature guide](docs/ARCHIVED_FEATURE_GUIDE.md).

## Validation

320 local Godot checks across ten suites and 23 backend tests passed. These include 52 controlled narrative checks covering both endings, objective gating, range/occlusion, real health damage, escort movement/jamming, radio pause, save rollback, older-save migration and online read-only behavior. Native Linux journal and mission HUD rendering was inspected. Combat completions in tests are scripted; this is not human difficulty calibration or Windows GUI playtesting.
