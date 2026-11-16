# Pathfinders — v0.42

Choose **Enter the Frontier**, press **O**, then select **Field atlas** or **Journey & badges**. The campaign remains disabled by default.

## Explore and remember

The atlas lists real scene destinations. Filter by station, landmark, job, salvage, mineral, beacon or recorded fauna, or search a name/region. Resource locations appear within current sensor range. Stations broadcast coordinates; landmarks become surveyed only after you visit and G-scan them. Delivered animal surveys reveal entries linking back to that species' planet.

**Set course** creates a mint world marker and flight guidance with distance, direction and ETA when you are moving toward it. **Warp to region** sets that course and requests the normal safe warp; it does not bypass combat checks. Right-click on the **J** chart to set a custom course. **Save beacon here** records a named location at the current ship; up to twelve persist across sessions. Personal marker deletion and courses save atomically. Online courses stay transient.

## Mine and fabricate

Look for luminous ore, crystal or alloy seams. They appear in the atlas when in sensor range. Aim and fire lasers to fracture the deposit, approach within **75m**, then **hold F for one second** with an unobstructed tractor path. Ore yields four units; crystal and alloy yield two. A failed save leaves the fractured vein ready to retry. Material storage is shared with your solo sanctuary; these materials cannot mint online items.

Each batch has twelve deposits spread across the seven regions. Completed deposits persist; clearing all twelve produces another batch. Partial fracture damage is session-only. The workshop can turn **10 ore + 6 crystal** into the Vector Engine schematic, or **8 ore + 6 alloy + 4 crystal** into the Crystal Shield schematic. Build a workshop first. Known blueprints cannot consume materials again. Fit components in Fleet Hangar for your next deployment. Legendary/mythic odds and cache-exclusive relics are unchanged.

## Choose a journey

Eight optional badges use existing gameplay progress. Claim each once for salvage. Pin a single goal for a small HUD reminder or unpin it entirely. Progress uses saved discoveries/deliveries, so past valid progress also counts. There is no daily login requirement, timed season or mandatory story.

## Coordinate

**P**, middle click or gamepad right-stick press marks your aim. **Shift+P** sends Danger; **Ctrl+P** sends Regroup. Atlas buttons offer all three choices. Shared online markers are created by the host from your controlled ship's aim; clients do not submit coordinates. Markers expire after 45 seconds, with a two-second cooldown and at most three per pilot/eighteen overall. Opposing teams do not receive them.

## Continue safely

Service a station with **G** outside combat to update your Continue dock. Local free-roam checkpoints also save job progress every twelve seconds, when leaving the activity and when quitting. The title screen's **Continue** returns to that serviced station, with optional job timers/integrity/escort or boss progress retained. NPC fleets start a fresh session. A stale checkpoint cannot pay a completed job again. No offline time is deducted from job timers.

The game does not serialize every moving object. Pings, NPC positions/war waves and partial mineral damage restart. A wreck resumes outside its interior; return through the airlock before quitting to secure its black box. Unextracted surveys must be delivered at the landing ship. Secured transport cargo remains saved. Quit warnings explain these differences.

## Development and validation

New systems are in `scripts/journey/`, with bounded `JourneyState` persistence, `AtlasData` destinations, atlas/journey UI pages, a reusable `MineralVein` and `MiningField`, `NavigationBeacon`, `JourneyRecorder` and `TeamPings`. Shared resource sensing is centralized in `JourneySensors`. Health/weapons, Frontier jobs, existing crafting and component rarity logic remain separate.

Run Godot 4.6.3:

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/pathfinders_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/pathfinders_resume_test.gd --fixed-fps 60
python3 tests/test_frontier_network.py
```

The scripted tests exercise real scene nodes and laser/tractor interactions, failed-save rollback, migration, repeat claims, filters, crafting, checkpoint replay and allied ping limits. The network test uses two actual ENet clients plus the HTTP account service. Native Linux renders check layout; they do not establish Windows performance or human controller/balance results. See [comparison and future priorities](GAMEPLAY_REVIEW.md).
