# Changes

## 0.7.0 — Pixlet & Pearl Space Art

- Added original Pixlet companion and five redesigned ship classes with pearl armor, gold trim, cyan faces, sculpted fins and engine pods.
- Added a blue nebula sky, painted planets with atmosphere rims, cratered asteroid geometry and a matching service station.
- Added reproducible GLB and self-contained Godot scene exports for seven models, packaged separately from the native game. Models are static; gameplay scripts animate companions.
- Added Pixlet to local and server collection catalogs, keeping existing save IDs and rarity rules.

## 0.6.0 — Playable PC Release

- Added Windows/Linux standalone exports, embedded game packs, release ZIP packaging, checksums and an automated GitHub prerelease workflow.
- Added a one-click Windows host package with official portable Python, exported game engine, LAN address display and optional local-subnet firewall rules.
- Added saved server/commander preferences and a one-address LAN shortcut without storing passwords or tokens.
- Added standalone free-roam/battle startup options and immediate server readiness log flushing.
- Windows files are cross-exported and checked structurally; interactive Windows execution remains untested in the Linux development environment.

## 0.5.0 — Free Roam & Little Space Crew

- Added a connected four-region world, service stations, direct flight, validated warp, local scan signals and recurring AI patrols, with no shrinking zone or match timeout.
- Added offline fleet redeployment and continuous online free roam with six human pilot slots plus twelve AI raiders, live joining, server-owned travel/service/respawn and persistent encounter rewards.
- Added transactional encounter receipts, inventory leases, leave/end cleanup and database migration preserving existing accounts.
- Added original rounded spacecraft, bubble cockpits, cartoon materials/outlines, cute alien meshes, matching portraits and rounded UI panels.
- Equipped alien crew now orbit their ship and fire species-specific automatic projectiles; damage is credited to the host and remains server-authoritative online. Rare appearances retain normal attack stats.
- Fixed offline pause to stop battle/exploration/free-roam simulation; reduced distant HUD clutter and free-roam target cycling.
- Verified 171 Godot checks, 21 backend tests, real two-client Royale/free-roam runs and inspected OpenGL renderer captures. Manual interactive and Internet/VPS playtesting remain outstanding.

## 0.4.0 — Fast Combat & Victory Ships

- Reduced hull/shields and regeneration; increased laser/missile damage across all five distinct ship roles.
- Added permanent random hull rewards for every local or online victory; duplicate hull copies remain owned and online copies can be traded.
- Added Interceptor, Skirmisher and Guardian reward hull Resources, bringing the catalog to 36 entries.
- Renamed Exotic appearances to Legendary; Legendary odds are 1/4,096 and Mythic odds are 1/16,384 per discovery roll. Existing owned items retain their IDs.
- Verified save persistence, exact rarity boundaries, duplicate reward prevention and permanent hull marketplace transfers.

## 0.3.0 — Galaxy & Network

- Added four Resource-defined exploration sectors, scan signals, patrol encounters, one-time discovery rewards, sector travel and a Galactic Records screen.
- Added Bomber and Support hulls, new abilities, equipment, crew and rare variants; catalog now contains 33 entries.
- Added version-2 local saves with migration from the previous build.
- Added synthesized combat audio and master volume control.
- Added ENet dedicated-server 3v3 combat, team selection, readiness, AI-filled slots, bounded control input, server-owned damage and snapshot interpolation.
- Added account registration/login, authoritative online inventory, fitting/research, public discovery profiles and SQLite marketplace listings/offers with escrow.
- Added a Windows server launcher, cross-platform startup, LAN/VPS instructions and an HTTPS reverse-proxy example.
- Verified 113 Godot regression/exploration/presentation checks, 14 Python service tests, an autonomous battle and real multi-client server tests. Rendered and external Internet playtesting remains outstanding.

## 0.2.0 — Hangar & Discovery

- Added a persistent hangar for fitting engines, shields, weapons, utilities, crew and class-compatible ship appearances.
- Added 25 Resource-backed collectibles, including human astronauts and three alien species.
- Added visible fitted hardware, rotating ship previews, primitive crew portraits and rare ship geometry.
- Added free battle discovery rewards, duplicate salvage, targeted research and lifetime commander statistics.
- Added local profile saving, previous-save backups, corrupted-save preservation and version checks.
- Verified 38 combat smoke checks, 48 progression checks and a complete autonomous battle.

## 0.1.0 — Fleet Royale Prototype

- Added six-ship 3D battles, player flight, weapons, shields, fleet switching, AI, class abilities, arena, shrinking zone, HUD and menus.
