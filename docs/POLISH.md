# Flight Polish — v0.43

This release repairs interactions and persistence in the existing game. It adds no new progression gate or mandatory story. Profile schema remains 11.

## Keep your current expedition

Activity changes and the window close button first try to write the solo Frontier checkpoint. If saving fails, the current scene stays alive. **KEEP PLAYING** returns to the same pause/mouse state so you can retry; **LEAVE WITHOUT UNSAVED PROGRESS** performs the requested transition once. Cancel is initially focused. This covers starting another flight, tutorial, battle, exploration or planet trip, returning to the title screen and quitting.

Undelivered surveys also prompt before leaving an active surface expedition. Already secured transport remains saved. Delivered surveys do not trigger a false warning, and finished/destroyed bots can leave normally. Changing activities from a wreck warns that console progress restarts; returning via the usual airlock retains the existing black-box reward path.

Automatic checkpoints still run every twelve seconds. When dock, mode and optional job state match the last checkpoint, a successful unchanged save is not rewritten merely to update its timestamp. Manual saves force a write, and a prior save error forces a retry. Continue still starts fresh NPC fleets at the last serviced station.

## Controls and readable guidance

Each action now stores keyboard, mouse and gamepad button overrides separately. Rebinding one device no longer overwrites another device's saved setting. Previous single-event settings still load and migrate when edited. Button bindings accept any controller device number, so reconnecting a pad does not invalidate its saved buttons. Resetting controls reports when only the current session changed because the file could not be saved. Axis bindings keep their defaults; duplicate-key conflicts are not automatically resolved.

Combat weapon/ability/target prompts and navigation/mining hints read current action bindings. HUD labels omit Godot's physical-key suffix. Tutorial and older help prose still describe default controls. Physical hardware/controller feel needs human testing.

Job courses identify a specific job, follow its live position/title and stop drawing when that job ends. A new job cannot inherit an old job's course. Recovered cache/deposit courses stop drawing too. The saved destination remains available for inspection or replacement; the HUD explains why its marker ended. Claiming a pinned badge clears the reminder, including when loading an already-claimed goal from an older profile.

An empty atlas search explains how to clear the filter and when resource or delivered-fauna contacts become visible. Clearing a course or deleting a beacon reports an actual save failure instead of claiming success. Pinned-goal totals refresh once per second instead of every course tick.

## Mining

Both hold-to-tractor input and the collection API enforce the same rules: current live offline deposit, fractured seam, living pilot, within 75m, clear path and available material storage. Failed actions explain range, obstruction, fracture, storage or save problems without consuming the seam. Mineral and component hints yield to the action being used, avoiding overlapping prompts. Existing material yields, workshop recipes and rare component odds are unchanged.

## Co-op settlement

Participation records account IDs rather than ship indices. Switching ships or replacing a departed pilot cannot transfer their contribution to someone else. At completion, connected contributors and connected allies within 150m with a clear path are eligible; simply being within the old 1km radius is insufficient. A contributor who disconnects before completion is not eligible. Once payment begins, its participant list is fixed.

The host retains the exact payment request while retrying an unavailable response. Participant departures and session closure wait until that request succeeds. Retries continue even after the world finishes because its final pilot left. Previously committed receipts can be replayed after account departure/session closure without paying twice. Leave requests are idempotent and cannot unlock a newer match. A new session waits for outstanding settlement work to drain.

This queue lives in the running host process; it does not recover after the host is killed or guarantee payment through an indefinite account-service outage. Inventory leases remain the crash fallback. Hosts are trusted; this does not introduce commercial anti-cheat or shared planet/wreck interiors. Online and solo economies stay separate.

Team ping snapshots reject duplicate IDs, and clients age out their markers when snapshots stop arriving. Existing host derivation, allied visibility, rate/cap limits and 45-second lifetime remain.

## Validation

On Godot 4.6.3/Linux, **824 checks across 25 local suites** passed. This includes 34 polish checks, 10 co-op settlement checks and three updated explicit-discard checks in the creature-loop suite. Coverage includes combat feedback, fleet switching, landing/capture/delivery on all three worlds, sanctuary, companions, saved campaign compatibility, Frontier jobs, resources, navigation, controls and checkpoint replay. Some older narrative fixtures retain their pre-existing ObjectDB teardown warnings.

**30 account-service tests** passed, including receipt replay after closure, delayed departure against a new match, and malformed job kinds. Two real HTTP/ENet runs used an account service, a combat host and two actual game clients: normal co-op and a participant disconnect while a delayed payment committed but its response was deliberately lost. The latter retried, created one receipt, paid both original participants once and released account locks afterward.

Native Linux/OpenGL renders were inspected for the departure warning, remapped weapon/mining HUD and empty atlas guidance. These are software-rendered layout checks, not GPU performance results. Windows exports, physical controllers and human balance remain distinct checks; no Windows GUI or human playtest is claimed here.

Run from the project root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/polish_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/coop_settlement_test.gd --fixed-fps 60
GD_ENABLE_CREATURES=1 godot --headless --path . --script res://tests/creature_loop_test.gd --fixed-fps 60
GD_ENABLE_CAMPAIGN=1 godot --headless --path . --script res://tests/wildlife_return_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/pathfinders_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/pathfinders_resume_test.gd --fixed-fps 60
python3 -m unittest discover -s tests -p 'test_*service.py'
python3 tests/test_frontier_network.py
GD_TEST_REWARD_DISCONNECT=1 python3 tests/test_frontier_network.py
```

The network fault fixture creates isolated temporary accounts, delays its first transaction and simulates a lost reply; it never affects an existing account database. Native rendering smoke views use `tests/render_polish.gd` with `departure`, `mining` or `empty-atlas`. Use a disposable Godot user-data directory for previews.
