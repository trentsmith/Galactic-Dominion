# Galactic Dominion — Planetfall Returns

A Godot 4.6.3 3D space-combat prototype with an original Nexus Archives fleet story, configurable 1–200 fighter fleets, five ship classes, persistent customization, extremely rare exploration components and self-hosted online spaceflight. Uses GDScript and procedural 3D assets; no paid assets or plugins required.

## Play the current build

Download the Windows or Linux client from [v0.40.0](https://github.com/trentsmith/Galactic-Dominion/releases/tag/v0.40.0). Extract the whole ZIP. On Windows run **GalacticDominion.exe**; no Godot installation is needed. Back up your commander profile before upgrading. Save schema remains 9, compatible with v0.39.1. Older pre-v0.39 builds cannot read it.

For source development, download/clone the `phase-40-wildlife-return` branch, open Godot 4.6.3, click **Import**, select `project.godot`, then press **F6** for the current scene or **F5** for the full project.

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

## Land, track and rescue wildlife

**Planet expeditions** and **Wildlife sanctuary** are back on the main menu. Choose any of the three worlds, then deploy an owned bot or the loaner Pixlet. You can also fly to an owned planet/outpost in solo **Free Roam**, approach outside combat and press **L** to land. **Peaceful Flight** provides friendly world control and no raids. **J** opens the chart and explorer picker. Leaving the surface restores that same orbital session.

On the ground, **T** tracks species, **G held for two seconds within 12m** scans, **LMB** stuns dangerous animals non-lethally and **C within 8m** captures a scanned, eligible creature. Dangerous fauna must reach half health first. Return to the landing ship and press **E within 10m** to deliver surveys and secured animals to the sanctuary. **B** switches the exploring bot at the ship; **F** gathers seeds. Your own creature party can be deployed with R, selected with N, ordered to attack with V and recalled with Z. Secured cargo remains saved; failed deliveries can be retried.

Wildlife uses restrained anatomical faces: smaller lateral eyes, neutral side jaw seams and no decorative brow marks. Jellyfish have distributed sensory organs; wisps have no paired face. Fish keep lidless eyes. Sanctuary and mature forms inherit the same anatomy. **Orbiting bot faces, their animations/attacks, Nexus hulls and the Fractured Relay story are unchanged.** The restored surface loop is solo-only. [Planet restoration and face notes](docs/PLANETFALL_RETURN.md).

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
- **Online:** self-hosted six-pilot space sessions and marketplace; local and online inventories remain separate. Update server and clients together to v0.40.0. [Windows hosting](server/README.md).

## Discover ship parts

Follow gold COMPONENT SALVAGE bearings in solo Free Roam, approach within **60m**, then hold **K for two seconds** with a clear path. The first recovery guarantees an uncommon part. Twelve recovered caches refresh the local batch. Parts save immediately as reusable schematics; fit them for the next deployment. Duplicates grant 15 salvage. Failed saves leave the cache available to retry.

Later cache odds: **legendary tier 1/4,096; mythic tier 1/65,536**. Four legendary and two mythic relic parts are cache-exclusive, with tradeoffs rather than automatic superiority. There is no pity guarantee. These discoveries remain solo-only. [Exact odds and components](docs/COMPONENT_DISCOVERY.md).

## Controls

W/S thrust/reverse; A/D strafe; Space/Ctrl vertical movement; mouse steering; Q/E roll; Shift boost. Left click laser, **M missiles**, R class ability, Tab target. F1–F3 switch lead ships; Fleet War supports F1–F10 and Armada additionally uses [ / ] to cycle survivors. 1–5 issue fleet commands. J star chart, G scan/service, K salvage recovery, O journal, H scenic HUD, Esc pause/menu. Online simulation continues while menus are open.

## Orbiting companions are back

In **Fleet & collection → Fleet Hangar**, select a ship and equip a discovered non-human bot in its **CREW** slot. Pixlet, Cinderbit, Lunaflutter, Orbitot and Glimbloom are available again. Orbitot and Glimbloom can also be researched through the collection panel. Human officers do not spawn an orbiting bot. Existing companion ownership and fitting data remain valid. Companions keep their existing orbital animation and AI attacks; the Nexus ship models and spaceship campaign remain active.

The independent setting `gameplay/companions_enabled=true` enables orbiters while `gameplay/wildlife_enabled=true` restores planet animals without changing the ship story. Animal-themed ship skins remain archived, preserving the Nexus hull direction.

## Independent feature settings

`gameplay/wildlife_enabled=true` restores surface landing, capturing and sanctuary care. `gameplay/companions_enabled=true` keeps orbital bots active. `gameplay/creatures_enabled=false` preserves the current Nexus story and hull art; that older bundled setting is a development/legacy-mode override, not the wildlife switch. The biological story remains preserved independently in saves. Animal-themed ship skins stay archived. See [implementation and compatibility](docs/PLANETFALL_RETURN.md).

## Validation

513 local Godot checks across twelve suites and 23 backend tests passed. These include 42 new restoration checks across all three worlds, real capture/delivery paths, saved rescues, unchanged campaigns and companion faces; 77 face/material/glTF checks; and the existing narrative/capture/care suites. Native Linux wildlife portraits, restored menu, selector and landed scene were inspected. Automated interactions are scripted; human balance and Windows GUI testing remain pending.
