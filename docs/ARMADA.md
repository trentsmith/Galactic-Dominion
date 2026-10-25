# Experimental Armada

100 ships on each side, offline only. One human pilot can take over any surviving ally; the rest are AI. Existing online sessions remain six pilot slots. No new backend protocol is claimed.

Choose 100v100 ALPHA beside the difficulty selector, or launch with `-- --armada`. F1–F10 selects the first ten allies; [ and ] cycles through all living allies. Commands 1–5 apply to the fleet. No respawns; the last fleet standing wins. The safe sphere begins at radius 3,000m, contracts and collapses after eight minutes using the existing elimination rules.

Six relics begin near the central contested region. Approach within 32m to collect one if your ship has none. Each provides three charges and 12 seconds between shots. An exhausted relic disappears from the ship. The physical pickup reappears 90 seconds after collection. Equipment is tied to a particular live ship and never saved or traded. Both teams can acquire and use relics.

- **Solar Lance:** B fires a 1,100m aligned beam with 16m target tolerance, dealing 130 damage per enemy in its path. Static obstacles block each target's damage. The beam can pierce multiple enemies; allies are protected. AI waits for alignment and a target within 900m.
- **Gravity Nova:** B damages enemies within 140m for 80 damage and applies the existing brief gravity slow. Obstacles protect targets. Allies are protected.

Damage still passes through normal shields, hull and Guardian protection. These are powerful match pickups, not guaranteed kills. The HUD shows the active ship's relic, charges and recharge state.

## Rendering and testing

Reinforcements use bounded lightweight hull geometry. Taking control promotes that hull to the full model; leaving it restores the lightweight model. The original three fitted ships keep full geometry. HUD lists the first ten allies and limits distant unselected markers. All 200 ships still use real movement, health, AI and projectiles.

The automated suite runs 2,400 live physics frames before checking weapons and takeover. Final local measurement: 40 simulated seconds in 19.39 wall seconds, 13,675.3 confirmed damage, 77 allied / 57 opposing survivors. This measures headless simulation on a shared development machine; it does not measure graphical frame rate, networking scale or human enjoyment.

Run `godot --headless --path . --script res://tests/armada_test.gd --fixed-fps 60`. Test actual Windows graphics, long matches, controller comfort and balance before treating Armada as production-ready. The art remains an original procedural prototype.
