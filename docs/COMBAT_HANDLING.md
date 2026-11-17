# Dogfight Upgrade — v0.44

This update makes the existing fights easier to read and the ships more dependable to control. Damage, hull/shield statistics, difficulty presets, collectible odds and profile schema 11 remain unchanged. Cover and boost behavior affect combat outcomes, so human balance testing is still needed.

## Acquire, lead and fire

**Tab** (or your rebound target action) first favors enemies near the ship's forward weapon axis, while respecting the current sensor boundary. Rapid repeated presses use a stable order so moving ships do not make the selection jump unpredictably. After a two-second pause, acquisition considers your new aim direction. Ships from another arena and vessels that become friendly are ineligible.

The selected enemy has a **laser lead diamond**. Amber means turn toward it; mint means the predicted point lies inside the existing aim-assistance cone. The guide uses the real muzzle position, target velocity, projectile speed and lifetime. Player laser assistance uses the same interception solution in solo and on the authoritative online host. It grants no extra damage, projectile speed or wider assistance cone. Ordinary small-match AI retains its existing lead tuning; Armada keeps its precise solver.

A target that cannot be reached before the laser expires has no false lead solution. Cover suppresses the guide. Prediction assumes constant target velocity; a maneuver, collision, obstacle or network delay can still make a shot miss. Guidance is local presentation, not client-side damage or lag compensation. Disable it with **Settings → Show laser lead guide** if you prefer.

## Missile locks and threats

Acquisition requires an enemy within **600m**, inside the forward cone and with an unobstructed muzzle-to-target path. Cover, range and alignment failures explain what to change. A lost line of sight drains existing progress. Acquisition visibility is cached for 0.12 seconds per ship; actual missile launches always recheck the path. A refused shot consumes no cooldown or shot count. Existing solo/online lock durations, homing and reload tuning remain in effect.

An incoming missile alert shows the most urgent threat's **bearing**, **distance** and an approximate **closing estimate**, with an amber direction arrow. A closing missile is prioritized over a nearby missile travelling away. The estimate divides distance by current relative closing speed; it is not a guaranteed impact countdown. Evasive movement and missile turning can change it. Friendly missiles and missiles targeting someone else do not create an alert. Changing ships clears notices and threats from the previous hull.

Clients use the host's projectile direction and missile speed for this presentation. The host owns locks, firing, boost and damage. Snapshot visuals never apply damage. Less urgent course/journey text yields while a missile warning is present; the course's world marker remains visible.

## Take over your surviving fleet

**F1–F3** select the first three local fleet ships. **[ / ]** now cycle all living offline allies in both **10v10 and Armada**, skipping destroyed vessels and wrapping at either end. Extra fleet rows show vessel numbers instead of advertising nonexistent F4–F10 actions. Binding labels follow saved remaps.

Online switching retains its existing three-ship ownership group and host validation. Co-op allied rows no longer overlap when two groups share local slot numbers. **ALLY** identifies the other group, **PILOT** identifies an occupied hull in your group, and your usable F1–F3 bindings are shown on your own available ships. Online does not advertise offline survivor cycling.

## Steadier boost and camera

The HUD and boost FOV use actual active thrust instead of the held button. Stationary or exhausted ships no longer display a false boost effect. An empty reserve enters **BOOST RECHARGING**, then resumes once it has at least 15% of capacity (minimum eight energy). Holding the key through exhaustion no longer causes rapid per-frame speed pulses. The same rule applies to AI and authoritative online movement.

Camera follow and FOV use exponential smoothing that does not overshoot on a long frame. A ray from the ship to the camera shortens chase distance when terrain/asteroids intervene, including on a control switch; follow distance returns smoothly after the obstruction clears. The camera trace considers scenery rather than other ships.

**Settings → Reduce camera motion (fixed FOV)** removes the velocity-based camera offset and boost FOV expansion. It retains ordinary ship orientation and chase smoothing; it does not eliminate all camera rotation. This preference and the lead-guide preference save separately from account data.

## Validation and limits

**903 local Godot checks across 28 suites** passed on Godot 4.6.3/Linux. The 47-check combat suite covers acquisition/cycling, friendly and foreign-arena rejection, range and physical cover, a real moving-target laser impact, bounded visibility polling, urgent missile direction/time estimates, recovery without boost pulses, frame-independent camera follow, real scenery collision, 10v10 survivor input, settings persistence and authoritative snapshot presentation. Existing combat, tutorial, Armada, frontier, landing/capture, sanctuary, companions, saved narrative compatibility and co-op settlement suites also passed. Some older fixtures retain their existing ObjectDB teardown warnings.

Native Linux/OpenGL rendering checked incoming-threat/lead layout and the obscured-target card. A native captured physical **]** key switched ships in 10v10 and skipped a destroyed vessel. This native input check is separate from the headless test's explicit captured-input context: the headless display cannot capture a mouse.

Real HTTP/ENet tests exercised two-player arena play and co-op. Release CI also runs the 30 account-service tests, disconnected/lost-reply co-op regression, three 10v10 difficulty simulations and packaged Linux client/server startup checks. Windows builds are exported; Windows GUI, physical-controller feel, Internet latency and human combat balance remain unverified. Software-rendered layout checks do not establish target-PC frame rates. Online remains six human slots; large fleets are AI.

Run from the project root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/combat_handling_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_feedback_test.gd --fixed-fps 60
godot --headless --path . --script res://tests/online_presentation_test.gd --fixed-fps 60
GD_ENABLE_CREATURES=1 godot --headless --path . --script res://tests/armada_custom_test.gd --fixed-fps 60
python3 tests/test_network_integration.py
python3 tests/test_frontier_network.py
```

For native checks, run `tests/render_combat_handling.gd` on an actual display with `incoming`, `blocked`, `lead` or `fleet-input` after `--`. Use a disposable Godot user-data directory. All online clients and hosts must update together to **v0.44.0**. Solo and online inventories remain separate; story guidance remains disabled by default.
