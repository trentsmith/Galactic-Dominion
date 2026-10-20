# Streamed wilderness

World radius is 2000 m. A 240 m square landing tile stays loaded. Moving beyond 85 m activates the streamer: a three-by-three tile neighborhood is maintained, with one queued tile built per frame. The initial landing tile is skipped because the original terrain already covers it. Terrain is deterministic and uses the same height function across tile seams.

Each new tile contains 22 large procedural plants, 700 instanced leaf tufts, three flora collection stations, four fauna and a collidable wreck or stone landmark. The foliage and species come from the planet biome. Nine active tiles bound added live fauna to 36 and instanced meadow tufts to 6300. Original landing fauna and scenery remain loaded. This is bounded scene content, not a measured frame-rate guarantee.

Unloading removes flora and animals from scan, hunt and capture lists before freeing them. Per-animal health and alive state are remembered for the expedition lifetime. Reloading dead/captured streamed wildlife does not respawn it. Flora records retain the existing three species IDs, so scanning repeated patches does not inflate survey completion or seed types. Save schema and online replication are unchanged.

Known limits: no surface multiplayer, no cross-expedition wilderness state persistence, no new creature species, no authored quests or villages. Long-range travel still uses the bot's existing sprint/swim controls. Streaming constructs a tile on the main thread; lower-end PC hitching needs hardware profiling. Vegetation has simple rendering and no per-tuft collision. Existing terrain/plant art is procedural.

## Validation run

Godot 4.6.3: wilderness 14 checks, planet expedition 40, capture rescue 37, landing/hunt 27, free roam 33 and world war 31 passed (182 total). Backend unittest: 22 passed. A distant Varkhoss area was rendered in native OpenGL and inspected; this was not a frame-rate benchmark. Windows GUI remains untested.
