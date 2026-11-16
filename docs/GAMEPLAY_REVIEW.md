# Gameplay review — Pathfinders

## Scope and conclusion

This is a comparison of **eight relevant games**, using published descriptions of their mechanics and a code review of Galactic Dominion v0.41. It is not an exhaustive analysis of every popular game, a current popularity ranking, or a claim that their audiences were playtested. Feature effects below are design judgments to validate with players.

Galactic Dominion already has many systems: arcade combat, fleets, companions, rare parts, planet wildlife, care, crafting, factions and optional jobs. Its largest gap was how those systems connect over several sessions. Players needed better discovery memory, personal goals, a peaceful space-to-workshop resource loop, shared navigation and a reliable way to continue.

## Comparison

| Reference and source | Useful pattern | Gap in v0.41 | Pathfinders response |
| --- | --- | --- | --- |
| [No Man's Sky: Waypoint](https://www.nomanssky.com/waypoint-update/) | Autosaves, catalogues and pinnable journey milestones | Collections persisted, but players had little guidance outside the disabled story and active jobs were session-only | Optional badges with pin/unpin, a field atlas and safe-dock checkpoints with job progress |
| [Outer Wilds: ship computer](https://www.mobiusdigitalgames.com/news/all-systems-go) | Remember discoveries without giving away the entire mystery | Discovery records existed as data, but lacked a practical exploration view | Searchable atlas, surveyed/unsurveyed landmarks, delivered creature records and personal beacons |
| [EVERSPACE 2](https://everspace-game.com/the-game/) | Exploration and resources feed ship builds | Most useful space interactions were fighting, scanning or opening caches | Mineable material seams feeding real workshop component recipes |
| [Subnautica](https://store.steampowered.com/app/264710/Subnautica/) | Gathering, home facilities and equipment support further exploration | Space and home production felt disconnected | Mine ore/crystal/alloy, bank materials atomically, fabricate reusable schematics at home |
| [Breath of the Wild: Nintendo features](https://zelda.nintendo.com/features/) | Surveying and useful destinations support self-directed exploration | The chart could warp to stations but lacked personal routes and map pins | Saved courses, distance/bearing/arrival guidance and right-click chart waypoints |
| [Deep Rock Galactic: official community wiki, Laser Pointer](https://deeprockgalactic.wiki.gg/wiki/Laser_Pointer) | Fast contextual markers communicate locations to teammates | Co-op jobs existed, but pilots had no shared spatial communication tool | Look/Danger/Regroup pings, host-derived positions, allied-only replication and expiry |
| [Minecraft: Creative vs Survival](https://www.minecraft.net/en-us/article/creative-vs-survival-mode) | Different play styles and player-created goals | Free roam needed reasons to return without imposing a linear campaign | Eight independent goals, peaceful mining and player-named destinations; larger freeform construction remains future work |
| [Sea of Thieves: official Ships of Fortune overview](https://www.youtube.com/watch?v=m-4fuUaC98Y) | Faction careers and shared activities support repeatable sessions | Basic faction standing already existed, but exploration had limited long-term structure | Journey badges sit alongside existing faction work; richer emergent encounter variety remains a priority |

Sources describe reference mechanics; the gap assessments and implementation choices are our own. No reference game's names, assets, characters, UI artwork or fictional lore were copied into the game.

## Implemented in v0.42

1. **Field atlas:** stations, named landmarks, current jobs, nearby component caches and mineral seams, saved beacons and delivered creature surveys. Search/category filters and nearest-first results. Stations are public broadcasts; resource contacts depend on sensor range, retaining Scout/observatory utility. Survey knowledge is distinct from seeing a marker.
2. **Navigation:** save a destination, follow a mint world marker and HUD bearing/distance/closing-speed ETA, or right-click the star chart for a course. Warp uses the existing combat restrictions. Arrival hints match the selected activity.
3. **Personal beacons:** up to twelve saved locations. Removing the selected beacon clears its route. Online courses are transient and do not mutate local inventory.
4. **Optional journeys:** eight independent badges for regions, landmarks, mining, components, creature surveys, sanctuary diversity, jobs and facilities. Pin one or none. Rewards are ordinary one-time salvage, with no change to extreme rarity rolls.
5. **Space mining:** twelve persistent material deposits per batch. Shoot a seam to fracture it; hold F within 75m for a second with a clear tractor path. Ore/crystal/alloy go into existing home materials. Cleared deposits and counts survive reload. Entire batches refresh. Failed saves retain the vein and materials; storage limits explain refusal.
6. **Workshop connections:** existing recipes remain, with Vector Engine and Crystal Shield blueprints added for mined materials. These are ordinary component schematics; legendary/mythic relics remain cache-only.
7. **Team pings:** P/middle click/right-stick press; Shift+P for Danger, Ctrl+P for Regroup, or choose from the atlas. The host derives a position from the controlled ship's aim/target. Two-second cooldown, three markers per pilot, eighteen total, 45-second lifetime. Server snapshots go only to allies.
8. **Continue:** station service updates a safe dock, and local checkpoints save every twelve seconds and when changing activities or quitting. Continue restores that mode at the dock and optional job timing/integrity/escort or boss progress. It starts fresh NPC fleets. Old completed job slots cannot pay from stale checkpoints.
9. **Save feedback:** visible autosave success/failure messages; failed discovery saves roll back rewards and remain retryable. Closing the game explains unsaved surface/wreck data or a failed checkpoint and permits keeping the session open.

## Save boundaries and remaining scope

Schema 11 adds `journey` and migrates schemas 1–10. Existing ships, creatures, component seeds, factions and archived stories remain. Local mining, milestones and beacons are separate from the online economy. Shared team pings and co-op space jobs are networked; mining and interiors remain solo.

Continue is **a safe-station checkpoint**, not a complete serialized universe. NPC positions, war waves, active pings and partial mineral damage restart. Completed mineral receipts and optional job progress persist. Wreck interiors restart outside the wreck; return through the airlock to secure black-box data. Unextracted surface surveys still require delivery. Cargo already in saved transport remains saved.

### Priorities still requiring substantial work

- **Encounter and biome depth:** more enemy archetypes, handcrafted discoveries, different wreck layouts and creature behaviors. A larger empty map alone will not provide the density of a finished open-world game.
- **Shared ground exploration:** authoritative planet/wreck instances, creature ownership and reconnect handling, rather than transferring local rewards into online accounts.
- **Home construction and fleet identity:** a richer building system, more distinct component visuals and meaningful long-term customization.
- **Human playtesting:** first-session comprehension, combat balance across fleet sizes, controller comfort, accessibility and frame-time profiling on target Windows PCs.
- **Commercial operation:** account recovery, diagnostics, host administration and a full online service lifecycle if this grows beyond a PC-hosted prototype.

### Playtest goals

A new player should be able to set a course, gather materials and identify a useful upgrade in ten minutes without external instructions. Two friends should locate one another's ping and complete a shared job without voice chat. Fifteen minutes of peaceful flight should offer useful discoveries without needing a legendary drop. These are targets for human testing, not results established by automated tests.
