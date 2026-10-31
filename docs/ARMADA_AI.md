# Armada targeting and challenge

Armada Standard and Veteran no longer inherit the reduced enemy health, shield regeneration and longer reloads used by the smaller accessibility-oriented solo arenas. Standard uses base hull/shields/regen and base cooldowns, with a modest turn improvement. Veteran adds faster turning, shorter cooldowns, quicker target reactions and more sustained bursts. Raw weapon damage remains unchanged. Relaxed retains reduced durability and longer pauses. The existing 3v3/10v10 tuning remains separate.

## Targeting corrections

Previously the brain steered toward a short 0.3-second lead while the firing check used a different distance/speed lead. Both could disagree with the actual moving-target interception point. `Ballistics` now solves the constant-velocity projectile interception equation using the muzzle position, actual projectile speed and lifetime. Armada steering and weapon assistance share this solution. Projectiles do not inherit shooter velocity, so the solver does not subtract shooter velocity. Unreachable laser targets do not receive a false firing solution.

Armada retains a current living target unless a new one is substantially closer. This avoids resetting missile locks whenever two nearby opponents exchange nearest-distance order. Orders, target death and sensor limits still apply. Fire-ready shots test obstacles and friendly hulls before launching. Standard/Veteran enemy missiles match allied speed, tracking and lock timing. Shots remain physical projectiles: manoeuvring and cover can defeat a constant-velocity prediction.

## Automated comparison

The same seed (81337), Standard difficulty, 200v200 fleets and 90 simulated seconds were run against the committed v0.34 baseline and this update. All ships were AI-controlled for the comparison, including the normally human-controlled vessel. Both matches were still running at the cutoff.

| Metric at 90 seconds | v0.34 baseline | Updated AI |
| --- | ---: | ---: |
| Enemy damage dealt | 11,232.9 | 15,091.8 |
| Allied survivors | 131 | 117 |
| Enemy survivors | 80 | 99 |
| Allied damage dealt | 17,225.9 | 18,224.6 |
| Enemy shots / confirmed hit events | 3,424 / 378 | 5,240 / 527 |

Enemy damage increased about 34% in this one scenario. Changes include both aiming behavior and enemy balance; this does not isolate one cause, establish a human win rate or prove all seeds are balanced. Hit-event counts include multiple weapon types and are not a clean laser accuracy measurement.

`tests/armada_custom_test.gd` separately fires a real laser at a moving ship, verifies impact, tests target retention and blocked firing, launches asymmetric fleets and checks replay. For further comparisons run:

`godot --headless --path . --script res://tests/armada_ai_benchmark.gd --fixed-fps 60 -- --allies 200 --enemies 200 --difficulty standard --seed 81337 --seconds 90`

Use several seeds and human playtests to calibrate further. For a deliberate numerical disadvantage, choose 50 allies versus 200 enemies; Veteran adds more pressure. Fleet counts include the player on the allied side.
