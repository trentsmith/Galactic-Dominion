# Planetfall returns / v0.40

## Scope and controls

Restore solo planetary landings, three wildlife expeditions, capture/transport/delivery, sanctuary care and the existing creature party. The Nexus ship story and hull renderer remain current. Orbital and surface bot faces are unchanged; the requested face revision applies only to wildlife.

Start from Planet expeditions for direct deployment or Peaceful Flight for an orbital approach. In normal Free Roam, control the world/outpost, approach it, leave combat and press L. Recent damage, hostiles, distance and online mode still restrict orbital landing. J exposes the explorer selector and landing buttons. A surface departure or completed sanctuary visit restores the parked orbital instance rather than spawning a new match.

T chooses a hunt; hold G within 12m for a scan with clear view. C within 8m secures a scanned creature; dangerous fauna also needs health at or below 50%. LMB supplies a non-lethal stun. Return within 10m of the landing ship and press E to deliver. Capture consumes a pod and saves the transport; delivery adds the resident and clears the manifest only after a successful save. B changes an owned exploring bot at the ship. F gathers seeds. N/R/V/Z select, deploy, command and recall owned surface creatures. The pre-existing caps, production, growth and care systems remain intact.

The ground save/capture loop remains independent of online account inventory. There is no new networked surface authority in this release.

## Neutral wildlife anatomy

All nine species share the updated procedural fauna generator in the wild, in parties and in the sanctuary. Mammal-like species have smaller, more lateral eyes and a jaw seam along the muzzle sides instead of a front-facing mouth arc. Bat/prowler heads and ears have less infant-like proportions. Iris saturation and catchlights are restrained. Decorative bat brow patches are removed. Fish/sharks retain lateral eyes without mammal lids or blinking. Jellyfish use eight distributed rhopalia rather than a paired face; wisps have a central energy structure without eyes. Crawler/watcher feeding structures replace the mouth-like seam. Growth emblems sit away from the face.

These remain original stylized procedural models, not scanned photorealistic animals. Bot companion art, its happy crescent eyes/expressions, the character portraits and Nexus ship geometry are not changed. Species IDs, stats, affinities, levels, care progress and collectible ownership are unchanged. Exported model release packs regenerate from this same source; glTF round-trip tests verify the revised anatomy.

## Independent flags and saved progress

- `gameplay/wildlife_enabled=true`: normal surface/landing/sanctuary access. For development, GD_ENABLE_WILDLIFE=0 disables it without changing ships or story.
- `gameplay/companions_enabled=true`: orbiting bot visuals/AI, independently configurable as before.
- `gameplay/creatures_enabled=false`: keeps the Nexus story/ship art. Enabling this older bundled setting (or GD_ENABLE_CREATURES=1) restores the legacy art/story mode for development; it also enables wildlife.

Schema stays at 9. v0.39.1 saves load directly, including sanctuary residents, saved capture transport, both story dictionaries and fitted ships. Normal wildlife visits/deliveries do not mutate the old biological story; only explicit legacy mode uses its old objectives. New ship-story launch/replay/travel paths use the existing surface delivery guard, preventing unextracted surveys from silently disappearing. New local wildlife access does not re-enable cute animal-themed ship skins.

## Validation

42 new end-to-end checks exercise all three planetary approaches, input landing, explorer selection, populated worlds, actual surveys/captures/deliveries, retry after failed saving, restored orbit instances, saved sanctuary residents, separate story states, neutral fauna and unchanged companion faces. 77 anatomy/material checks include exporting and reloading all nine species as glTF. Capture, creature-loop, landing/hunt, sanctuary forms, fleet companions, current story and legacy story suites also passed: 513 local Godot checks across twelve suites, plus 23 backend tests. A migration assertion compares nested care state with numeric tolerance because a running sanctuary advances fractional time. Native Linux before/after portraits and the restored menu/selector/landing scene were inspected. No human balance or Windows GUI playtest is claimed.
