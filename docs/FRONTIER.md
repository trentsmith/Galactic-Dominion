# The Frontier — v0.41

Historical notes: v0.42 adds a field atlas, mining and optional job checkpoints. See [Pathfinders](PATHFINDERS.md) for current save behavior.

The campaign is disabled through `GameFeatures.campaign_enabled()`, rather than deleting or commenting out interdependent files. Its profile records and source remain available. Optional jobs never gate landing, hangar access, factions or facilities. O opens the Frontier board; the title screen starts open-world flight.

## Implemented update ideas

| Idea | Current implementation |
| --- | --- |
| Distress signals | Repeatable deterministic five-slot boards: rescue, repair, escort, wreck and component rumor. Six-minute deadlines, explicit interactions, cancellation and completion messages. |
| Faction reputation | Four standings, rewards/kill penalties, friendly patrols at +24 and wanted interceptions at −20 in solo Free Roam. Existing NPC slots are reused. |
| Companion roles | Striker full damage; Scout 70% damage and +1000m salvage sensing; Guardian 60% damage and one missile interception per 8s inside 35m; Engineer 50% damage and +2 hull/s after damage stops. Crew fitting is unchanged. |
| Boardable derelicts | One reusable local interior, three sequential consoles, two power-controlled doors, pulsing damaging grid, black-box extraction and exact return to the parked orbital session. Bot destruction forfeits unsecured wreck data; existing bot ownership remains. |
| Wildlife tracking/ecology | Up to 16 real-position trail marks for the tracked animal. One ambient predator/prey pair at a time, outside the player's nearby encounter and excluding the tracked animal. This is a bounded local simulation, not a persistent planetary food web. |
| Boss weak points | Reused siege captain NPC with three exposed damageable anchors, 80% hull-hit mitigation until broken and faster guns afterward. Destroying anchors uses projectile ray collisions. Cleanup restores the reusable ship's geometry/cooldown. |
| Rare discovery clues | Observatory/scout bearings and a rumor pointing at an existing component cache. The same seeded recovery code and original rarity odds remain authoritative. |
| Prior ending consequences | Seal: visible Vesper reconstruction tender plus 0.6 hull/s outside combat within 500m. Preserve: contained echo, observatory core display and +500m salvage bearing range. Saves without endings have neither benefit and need neither. |
| Functional home facilities | Three upgradeable modules, 50/100/150 salvage per level. Repair dock +0.6 hull/s per level outside combat, observatory +750m salvage bearings per level and fitted-ship gallery, workshop recipes consuming sanctuary materials for standard permanent blueprints. |
| Co-op expeditions | Allied six-pilot space sessions; shared rescue/repair/escort jobs, authoritative interaction/range checks, snapshots and per-account idempotent rewards. **Shared planetary/wreck interiors are unfinished.** |
| Controls/accessibility/settings | Scripted gamepad flight and surface look support, device button/key remapping and reset, fixed axis defaults, graphics presets controlling AA/shadows/post effects, larger menu font and reduced explosion flashes. Physical-device certification and a full accessibility audit remain unfinished. |

## Save and authority boundaries

Local schema 10 adds a sanitized `frontier` dictionary. Schemas 1–9 migrate, preserving campaign, sanctuary, transport, collection and component seeds. A failed reward, fabrication or facility save rolls changes back; a completed active job stays available to retry its reward. A current board slot/generation may pay only once. All five slots advance to a fresh batch. Active mission progress itself is session-only.

Facilities and crafted schematics apply locally. Online accounts keep their own frontier totals, salvage and collections. Local JSON cannot grant online rewards. No online planetary landing is silently substituted with local progression.

Co-op uses existing FreeRoamMatch NPC/ship slots, with all six pilot hulls on team 0. F1–F3 switching uses the pilot's three-slot ownership group rather than team number, so pilots in the second group cannot seize the first group's hulls. Only the lobby leader starts shared jobs. The server checks nearby live pilots/held interactions; the service accepts only its server-key endpoint and a fixed job-kind reward table. `(match_id,event_id)` receipts include the exact kind and participant set; matching concurrent/retried requests settle once, altered receipts are rejected. Online rescue/repair/escort grant 50/60/70 salvage per eligible account and +8 council standing. Account progress survives restarting the host; active space jobs and positions do not.

## Modules

- `scripts/frontier/frontier_state.gd`: bounded persistent progression and save transactions.
- `frontier_data.gd`: deterministic job offers and presentation data.
- `frontier_director.gd`: world actors, mission rules, local reputation, rewards and co-op snapshots.
- `frontier_screen.gd`: optional board, standings, roles, facilities and log UI.
- `boss_weakpoints.gd` / `boss_hardpoint.gd`: reusable boss components.
- `derelict_expedition.gd`: interior using the existing surface bot controller.
- `wildlife_ecology.gd`: bounded wildlife trails and ambient encounters.
- `frontier_home_art.gd`: facility and gallery models.
- `flight_preferences.gd` / `controls_panel.gd`: runtime device bindings and display settings.

## Reproduce checks

Use Godot 4.6.3. Redirect XDG data/config directories for test isolation if testing on your own Linux computer.

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tools/export_models.gd
godot --headless --path . --script res://tests/frontier_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/frontier_jobs_test.gd --fixed-fps 60
python3 -m unittest discover -s tests -p 'test_*service.py'
python3 tests/test_frontier_network.py
GD_ENABLE_CAMPAIGN=1 godot --headless --path . --script res://tests/wildlife_return_test.gd --fixed-fps 60
GD_ENABLE_CAMPAIGN=1 godot --headless --path . --script res://tests/nexus_narrative_test.gd --fixed-fps 60
```

`frontier_test.gd` exercises actual scenes, projectile/anchor collisions, range refusal, completed-reward retry, migrations, crafting, patrol allegiance, missile interception, sequential wreck scans/doors/hazards/extraction and scripted input. The network fixture runs a real HTTP account service and two actual ENet clients; it positions ships reproducibly near the job and parks unrelated AI. It does not substitute for player flight/balance tests.

Local validation passed 45 Frontier checks, 20 additional job-path checks, 641 regression checks across 19 existing suites, and 27 account-service tests. A two-client HTTP/ENet test passed shared repair, live joining, allegiance, group-safe switching, per-account saving and endpoint protection. Native Linux board, interior and settings renders were inspected.

Human balance, Windows GUI and physical controller playtests are still needed. Interiors and the new home economy are prototypes with procedural geometry. There is no commercial account recovery, production moderation or official hosted service in this release.
