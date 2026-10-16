## v0.18.0 — Celestial space and sculpted ships

- Layered nebula sky and warm/cool stellar colors; natural ocean/coast terrain, separate slowly drifting cloud shells, soft atmosphere and fine ring bands.
- More irregular cratered asteroids, mineral surface shading and detailed wreck conduits/engine chambers.
- Sculpted low-profile ships, layered armor, inset glass, vents, seams, authored wings and tapered exhausts across every class/skin.
- Front-facing, antialiased Hangar previews with warm/cool lighting; fixed preview physics disabling after scene entry.
- Regenerated all 83 GLB/Godot model pairs; preserve existing combat, class and collection behavior.

## v0.17.0 — Every hull, every livery

- All existing skins now fit all five ship classes, retaining existing ownership and collectible rarity.
- Added researchable Orbitot/Glimbloom ship skins separately from their companion crew.
- Preserve selected hull statistics, abilities, gameplay attachments and skins across hull changes and save/reload, locally and online.
- Added animated ship orbital/crystal details and replaced block-shaped rare-skin trim with curved panels.
- Expanded the model pack to 83 GLBs and 83 bundled Godot scenes, covering every non-standard skin/hull combination.

## v0.16.0 — Orbitot and Glimbloom

- Added two reference-inspired 3D fleet companions: orbital satellites/ringed crown and faceted crystal petals/orbiting shards.
- Added researchable persistent crew, Gravity Loop tracking/slow and Prism Pulse enemy-only, obstacle-blocked splash.
- Server-authoritative effects and replicated signature projectiles; no change to rare-variant odds or save schema.
- Two additional portable GLBs and bundled Godot scenes, bringing the model pack to 40 pairs.

## v0.15.0 — A new command deck

- Redesigned main menu and pause screen with an animated 3D fleet preview, clear primary action and compact activity cards.
- Direct peaceful flight, separate utility navigation, contextual controls and explicit online pause messaging.
- Consistent mint/dark interface theme, keyboard focus and shorter flight information.
- Existing gameplay and save schema retained.

## v0.14.0 — Starlight visuals and peaceful flight

- Authored spacecraft profiles, swept wings, modular harbours and detailed wrecks.
- Sculpted wildlife with expressive eyes, tapered limbs, antlers, membranes and fins; instanced foliage and improved surface props.
- More natural planet materials and layered rings, quieter nebulae, irregular rocks, soft ion mist and restrained distant-object visibility.
- Optional peaceful solo exploration with friendly fleets, no raids and harmless ion scenery; H toggles the scenic HUD in Free Roam.
- Existing online wars and creature limits remain; the model pack regenerates all 38 pairs.

## v0.13.0 — Open world faction war

- Seven connected space regions and clickable star chart, with three new frontier landmarks and shared station travel.
- Recurring host-controlled faction ship raids and creature landing parties that contest rival worlds under existing army caps.
- Collidable wrecks and planet bodies, asteroid fields, damaging ion clouds, HUD landmark navigation and surveys.
- Captured solo worlds connect to real bot surface expeditions and return to the same suspended fleet/army/war session.
- Session-based online orbital war; shared online surfaces and permanent territorial empires remain future work.

## v0.12.0 — Creature armies and Kindred forms

- Host-controlled online/offline Free Roam armies; 50 total active creatures, 10 per pilot, cooldown-validated squad deployment and three orders.
- Three AI-garrisoned world outposts with contested 30-second captures and player recapture; creature-versus-creature/ship combat and replicated troop/attack/control state.
- Nine original friendship/love growth lines, Kindred/Radiant forms, permanent saved identity and production improvements.
- Schema 4 migration and eighteen additional editable 3D models; 38 model pairs total.
- Conquest is orbital and session-based. Sanctuary pets remain separate from expedition troops and online inventory.

# Changes

## 0.11.0 — Flying Creature Sanctuary

- Added a personal, editable 3D creature garden with resident care, nicknames, growth, production, plant seeds, habitat placement/movement/upgrades and close-up care views.
- Added expedition capture pods, weakened-predator captures, flora seed gathering, extraction delivery and cargo loss on deployment failure.
- Added a workshop and three increasingly costly flight stages, culminating in fueled travel between the three world orbits with a lift sequence.
- Migrated local save schemas 1/2 to schema 3 and persisted sanctuary materials, residents, plants, layout and flight progress.
- Validated care, production, capacity, crafting, flight gating, delivery, loss and migration; sanctuary progress remains local.

## 0.10.0 — Little Bot Planet Expeditions

- Added local single-player bot expeditions to Varkhoss Prime, the alien reef Pelagia and Ny’Zaroth, using the supplied images and Nexus Archives lore.
- Added collidable terrain, flora, landmarks, thirty wildlife creatures per planet, nine Resource-defined species, passive fleeing and dangerous pursuit/attacks with obstacle steering.
- Added bot movement, camera/aim, defensive pulses, shields/hull, sprint, swimming, scanning, extraction, destruction and lost pending surveys. Owned collectibles survive deployment loss.
- Added idempotent saved survey/completion rewards, a planet selector, a loaner bot for new players and a low-gravity reality-fracture event.
- Added nine fauna models to the GLB/Godot model pack and preserved the broader faction lore as world-continuity notes. Shared multiplayer planets and seamless orbital landings remain future work.
- Passed 264 Godot checks and 21 backend tests and inspected actual OpenGL captures of all three destinations.

## 0.9.0 — Cinderbit Comet Pup

- Added a 3D comet pup with pointed ears, crescent eyes, an open-mouth expression, four glowing paw pods and an animated volumetric flame tail.
- Added researchable Comet Pup crew with fast Meteor Nuzzle sparks and a matching cosmetic Interceptor appearance.
- Added both GLB/Godot model pairs to the model pack (eleven pairs total), matching portraits and a warm ember palette for hangar previews. Existing saves, class stats and Legendary/Mythic ticket odds remain compatible.
- Passed 224 Godot checks and 21 backend tests and inspected an actual OpenGL render of both new models.

## 0.8.0 — Lunaflutter Moon Moth

- Added Lunaflutter’s layered 3D moth wings, crystal-tipped antennae, crescent eyes, purple engines and animated wing joints.
- Added researchable Moon Moth crew with Dream Drift homing sparks and a separate cosmetic Interceptor appearance. Existing save IDs, ship stats and Legendary/Mythic ticket odds are retained.
- Added both models to the portable GLB/Godot scene pack (nine model pairs total) and matching collection portraits and purple hangar skies.
- Passed 207 Godot checks and 21 backend tests; rendered and inspected both new models with the actual OpenGL renderer.

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
