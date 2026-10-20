Galactic Dominion v0.28 — Clearer Combat Feedback

- Camera-relative directional hit warnings; separate labels for zone, collision and ion-storm damage.
- Distinct shield-break and critical-hull alerts, plus confirmed outgoing hit markers and damage amounts.
- Bigger enemy shield/hull bars and a selected-target card with numeric health and lock progress.
- Lock-ready chime, incoming hostile tracking-missile alerts, and explanations when M cannot fire.
- Original layered weapon/impact/alarm sounds, with throttling and existing master-volume support.
- Results explain survivor counts, damage, environmental losses, final damage sources and time-limit scores. Navigation remains visible while reports scroll.
- Confirmed feedback replicates online; final authoritative ship states make survivor counts accurate.

Existing saves, ship statistics and controls are preserved. Missiles remain M; star chart remains J. Extract Galactic-Dominion-Windows.zip and run GalacticDominion.exe. Update hosts and clients together to v0.28.

Validation includes projectile hits, camera-relative warnings, shield/hull thresholds, missile-threat filtering, lock/reload feedback, bounded history, non-silent unclipped PCM generation, replacement ships, online event deduplication, results layout, existing regressions and a real two-client match. Native Linux HUD/results renders were inspected; the renderer still reports two texture leaks during shutdown as in v0.27. Windows GUI, human sound preference and human difficulty assessment remain untested.
