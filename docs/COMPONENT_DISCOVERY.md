# Component discovery

Solo Free Roam and the Varkhoss, Viridia and Nyzaroth expeditions contain twelve gold salvage caches per location. Follow the nearest bearing; hold K for two seconds within 60m in space or 6m on the surface with a clear line of sight. All caches look alike before recovery. Clear a batch to generate another. H scenic mode hides their labels and HUD hints.

Parts are permanent, reusable hangar schematics. Fit them for the next deployment. Unlike animals, they uplink immediately and need no cargo delivery. Duplicate discoveries grant 15 salvage. The first successful recovery guarantees an unowned introductory uncommon part when available.

## Exact subsequent recovery odds

A uniform 65,536-ticket roll allocates 62,259 tickets to uncommon, 3,260 to rare, 16 to legendary and one to mythic. The four legendary parts are equally likely within their tier: 1/16,384 per individual part. The two mythic parts are equally likely: 1/131,072 per individual part. Tier chances are 1/4,096 legendary and 1/65,536 mythic. No pity guarantee; these are probabilities, not promised discovery counts. Pools choose uniformly within their tier.

| Part | Rarity | Benefits | Tradeoff |
|---|---|---|---|
| Solarweave Drive | Legendary | Speed and boost regeneration +18% | Hull -8% |
| Eclipse Bulwark | Legendary | Shield +25% | Regeneration -15%, speed -6% |
| Starforged Emitter | Legendary | Laser damage +25% | Laser cooldown +10%, boost capacity -10% |
| Ancient Wayfinder | Legendary | Turning +16%, ability cooldown -10% | Hull -6% |
| Voidwake Heart | Mythic | Speed +22%, acceleration +20% | Shield -10% |
| Singularity Crucible | Mythic | Missile damage +35% | Missile cooldown +15%, laser damage -5% |

These six have exploration-only definitions, cannot be researched/crafted and are excluded from ordinary battle reward rolls. All five ship classes accept them. Purple/gold coils, capacitors, rails or arrays identify fitted relics. Ordinary research and battle drops retain their existing paths.

## Persistence and scope

Schema 7 stores a random seed, successful recovery count and bounded per-world batch/opened state. Old schemas migrate; older games refuse schema 7. Save a backup before upgrading. Rewards use the saved seed, world, generation and cache index, so reloading an existing cache does not reroll it. This is a local progression feature, not tamper-proof anti-cheat.

Recovery snapshots inventory, currency, discoveries and cache state, saves the result, then consumes the visible cache. Failure restores the snapshot and permits retry. Surface and space share the service. Cache placement probes nearby scenery for accessible positions. Extreme procedural placement edge cases still need human exploration testing.

Online inventory is server-authoritative and separate. Local cache recovery is disabled in network worlds. The service catalog excludes the six solo relics; no client-minted rare items are admitted to online trading.

## Validation

The component suite has 26 checks covering all rarity tickets, actual mythic recovery, reload persistence, save failure/retry, duplicate currency, batch rollover, migration, all five ship classes, visible fittings, range/occlusion and both world controllers. Nine additional local Godot suites bring this pass to 365 checks; 22 backend tests passed. Native Linux world and hangar images were inspected. Known GPU texture cleanup errors occurred at shutdown. No Windows GUI or human rarity/balance playtest is claimed.
