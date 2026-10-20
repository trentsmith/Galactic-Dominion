# Solo difficulty and human playtesting

Choose **Solo Battle AI** on the command deck, or **Settings → Solo Battle Difficulty**. The choice is saved and applies to the next Fleet Royale (3v3) or Fleet War (10v10). Changing settings while paused does not retune the battle in progress. Training, free roam, planet encounters and online play keep their own rules.

| Preset | Enemy target reaction | Attack burst / pause | Enemy cooldown multiplier | Durability relative to base hull |
| --- | --- | --- | --- | --- |
| Relaxed | 1.1 s | 1.4 / 1.3 s | 1.40 | 75% |
| Standard | 0.6 s | 2.0 / 0.65 s | 1.15 | 85% |
| Veteran | 0.25 s | 3.0 / 0.15 s | 1.00 | 85% |

Standard preserves v0.29's solo tuning. Relaxed also reduces predictive lead, turning speed and shield regeneration. Veteran turns faster and fires in a slightly wider alignment window. Enemy raw weapon damage is unchanged. Player lock timing, laser assistance and allied missile handling remain available on every preset. Veteran adds no health above Standard. AI still obeys range, line-of-flight collisions, locks, cooldowns and finite shield-depletion retreats.

## What has actually been tested

Godot headless tests verify selection, persistence, both match sizes, next-match scope, unchanged catalog resources, online/training isolation, and saved local ratings. Native Linux menu/settings/results views were inspected.

One fixed-arena AI-controlled 10v10 comparison per preset produced:

| Preset | Duration | Enemy damage | Outcome |
| --- | --- | --- | --- |
| Relaxed | 21.7 s | 306.5 | Allied victory |
| Standard | 26.4 s | 832.5 | Allied victory |
| Veteran | 41.5 s | 1043.1 | Allied victory |

These are automated sanity checks with an AI controlling the player ship. They are not human playtests, win-rate estimates, performance benchmarks or proof of human difficulty calibration. Human balance tuning and Windows hands-on testing remain pending.

## Gather human feedback

1. Include players new to the game and players comfortable with space combat. Complete Flight School first.
2. Keep the same fleet fittings while comparing presets. Rotate the order so learning does not always favor Veteran.
3. Try at least two 10v10 matches per preset, then check 3v3. Note whether losses involved aiming, controls, target locks, focus fire or zone damage.
4. After each match choose **Too easy**, **About right** or **Too hard**. Ratings can be changed; they update the same report.
5. Click **Open Local Playtest Reports** and share the relevant JSON files with the developer. Nothing uploads automatically.

Reports contain game version, preset, mode, duration, outcome, team damage/shots/hits/survivors and optional rating. They omit account IDs, credentials and commander names. An unrated summary is saved locally at match end. On Windows the folder is `%APPDATA%/Godot/app_userdata/Galactic Dominion/playtests`.

Use multiple human sessions before retuning. Separate control confusion from AI difficulty. Compare 3v3 and 10v10 separately; ten-ship focus fire can feel different even when per-ship values are identical. Reward rules do not change by difficulty in this alpha.
