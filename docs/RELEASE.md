Galactic Dominion v0.33 — Uncharted Armada

- Main title-screen action: DEPLOY ARMADA / 200 v 200. One human pilot, 199 AI allies, 200 AI enemies. Existing solo modes remain; online stays six pilot slots.
- New randomized sectors: scattered squadrons, 10.4km starting safe-zone diameter, sixteen asteroid fields, hundreds of physical asteroids, two stars, two black holes and eight relic sites.
- Enemies stay hidden beyond 1,100m sensors. J opens the sector chart, showing mapped hazards and local enemy contacts rather than every opponent.
- Stars cause persistent drift and hot-core damage. Black-hole cores destroy ships. Warnings and combat reports identify the danger; AI tries to steer away.
- Detailed class hulls merge into shared geometry. Shared spatial queries, cached obstacle probes and bounded relic scans reduce redundant simulation and rendering work. Full controlled hulls and fitted appearances remain.
- Cleaner hull palettes/panel wear, stable story crafting tests, and stricter CI error detection.

Extract Galactic-Dominion-Windows.zip and run GalacticDominion.exe. Choose DEPLOY ARMADA. Tab targets detected enemies; J chart; B relic weapon; [ / ] cycles surviving allies. Update hosts and clients together to v0.33. Existing local save schema is unchanged.

444 local Godot checks and 22 backend tests passed. A live 400-ship simulation and native Linux visual inspection were run. Headless simulation timing is not rendered FPS. This mode remains experimental: Windows graphics performance, human balance and long-session playtesting remain pending.
