# Galactic Dominion — Nexus Fleet Campaign

A Godot 4.6.3 3D space-combat prototype with an original Nexus Archives fleet story, configurable 1–200 fighter fleets, five ship classes, persistent customization, extremely rare exploration components and self-hosted online spaceflight. Uses GDScript and procedural 3D assets; no paid assets or plugins required.

## Play the current build

Download the Windows or Linux client from [v0.37](https://github.com/trentsmith/Galactic-Dominion/releases/tag/v0.37.0). Extract the whole ZIP. On Windows run **GalacticDominion.exe**; no Godot installation is needed. Back up your commander profile before upgrading. Saves migrate to schema 8, which older builds cannot read.

For source development, download/clone the `phase-37-nexus-fleet-campaign` branch, open Godot 4.6.3, click **Import**, select `project.godot`, then press **F6** for the current scene or **F5** for the full project.

## Start with Story / Journal

Press **O** or choose **STORY / JOURNAL**. **The Fractured Relay** follows Commander Astra, Archivist Sera and Engineer Milo into the Crimson–Eldritch War:

1. Accept the Nexus fleet commission.
2. Win the 3v3 Crimson blockade; unlock a Sprint Drive and Bloodforged hull.
3. Recover a component cache in solo Free Roam.
4. Fit an upgraded engine to F1 in Fleet Hangar.
5. Win the 3v3 Dreaming Abyss encounter; unlock the Eldritch living hull.
6. Win the mixed-faction 10v10 Rift Warfront.
7. Debrief with Astra for a one-time 100-salvage reward.

Losing does not advance the story. Retry from the results screen or journal. Mission wins are derived from real fleet-match results, not dialogue alone. Faction encounters use at least Standard AI; Veteran remains Veteran. This is a local opening chapter, not an online campaign or a complete galaxy-length story.

## Nexus faction ships

**Varkhoss Prime / Crimson Dominion:** angular blood-red armor, jagged fins, reactor seams and siege pylons. Campaign enemies trade speed and shielding for stronger hulls and laser fire.

**Ny'Zaroth / Eldritch World:** curved chitin plates, crescent silhouettes, luminous veins and cosmic cores. Campaign enemies have more speed and shield regeneration with lower hull/shield capacity.

Both faction appearances work across Interceptor, Skirmisher, Guardian, Bomber and Support. Class geometry and existing class abilities remain distinct. Faction unlocks are cosmetic; campaign AI stat tuning belongs to its encounter. Full teleportation and reality-fracture mechanics are not implemented. Armada reinforcement meshes remain shared by class/faction for efficiency.

## Other modes

- **Armada:** independently choose 1–200 fighters on each side, including asymmetric fights. The player's fleet count includes the pilot. Random sectors, sensor-limited contacts, asteroids, stars, black holes and temporary mega weapons. [Armada guide](docs/ARMADA.md), [AI tuning](docs/ARMADA_AI.md).
- **Fleet Royale / Fleet War:** 3v3 or 10v10 last-fleet-standing combat.
- **Flight School:** safe interactive flight/combat tutorial.
- **Free Roam / Peaceful Flight:** space exploration, signals, faction ships, stations and salvage recovery.
- **Fleet & collection:** permanent hulls, components, human/alien officers and appearances. Pet collectibles are hidden and excluded from new random rewards while archived.
- **Online:** self-hosted six-pilot space sessions and marketplace; local and online inventories remain separate. Update server and clients together to v0.37. [Windows hosting](server/README.md).

## Discover ship parts

Follow gold COMPONENT SALVAGE bearings in solo Free Roam, approach within **60m**, then hold **K for two seconds** with a clear path. The first recovery guarantees an uncommon part. Twelve recovered caches refresh the local batch. Parts save immediately as reusable schematics; fit them for the next deployment. Duplicates grant 15 salvage. Failed saves leave the cache available to retry.

Later cache odds: **legendary tier 1/4,096; mythic tier 1/65,536**. Four legendary and two mythic relic parts are cache-exclusive, with tradeoffs rather than automatic superiority. There is no pity guarantee. These discoveries remain solo-only. [Exact odds and components](docs/COMPONENT_DISCOVERY.md).

## Controls

W/S thrust/reverse; A/D strafe; Space/Ctrl vertical movement; mouse steering; Q/E roll; Shift boost. Left click laser, **M missiles**, R class ability, Tab target. F1–F3 switch lead ships; Fleet War supports F1–F10 and Armada additionally uses [ / ] to cycle survivors. 1–5 issue fleet commands. J star chart, G scan/service, K salvage recovery, O journal, H scenic HUD, Esc pause/menu. Online simulation continues while menus are open.

## Creatures are archived, not deleted

Creature spawning, orbiting companions, surface landing, capturing, sanctuary activities and the biological story are disabled in the default release. Their scripts, scenes, resources and saved records remain intact. A single feature switch restores the archived mode for development; no data conversion is needed. [Restoration instructions and implementation](docs/NEXUS_FLEET_CAMPAIGN.md), [historical feature guide](docs/ARCHIVED_FEATURE_GUIDE.md).

## Validation

242 local Godot checks across eight suites passed, including 30 new ship-campaign checks and the archived story/menu suites with the switch enabled. 23 backend tests passed. Native Linux menu, faction hull and journal rendering was inspected. Automated checks do not establish human balance calibration or Windows GUI testing. This is an alpha prototype.
