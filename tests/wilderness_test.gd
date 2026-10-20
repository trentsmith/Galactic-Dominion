extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func run() -> void:
 var expedition:=PlanetExpedition.new();expedition.profile=PlayerProfile.new();expedition.definition=PlanetCatalog.WORLDS[0];root.add_child(expedition)
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false);expedition.wilderness.set_process(false)
 check(SurfaceWorld.RADIUS==2000,"Surface diameter is four kilometres")
 check(expedition.fauna.size()==30,"Landing survey wildlife remains available")
 var stream:=expedition.wilderness
 stream.update_center(Vector3(600,0,0))
 while not stream.queue.is_empty():stream.load_tile(stream.queue.pop_front())
 check(stream.chunks.size()==9,"Only nine nearby wilderness tiles are loaded")
 check(expedition.fauna.size()==66,"Nearby tiles add thirty-six interactive creatures")
 check(expedition.world.flora_nodes.size()==30,"Each tile adds three collectible flora stations")
 var key: Vector2i=stream.chunks.keys()[0]
 var animal: SurfaceFauna=stream.chunks[key].animals[0]
 var id:=str(animal.get_meta("wilderness_id"))
 animal.set_meta("battle_xp_awarded",true)
 animal.health=1;animal.alive=false;animal.respawn_timer=1
 animal._physics_process(60)
 check(not animal.alive,"Captured streamed wildlife stays absent even without unloading")
 stream.unload_tile(key)
 await process_frame
 stream.load_tile(key)
 var restored: SurfaceFauna=stream.chunks[key].animals[0]
 check(str(restored.get_meta("wilderness_id"))==id and not restored.alive,"Captured wildlife cannot be duplicated by unloading and revisiting")
 check(restored.health==1,"Unloaded wildlife health survives revisiting")
 check(restored.has_meta("battle_xp_awarded"),"Tile revisits cannot duplicate creature battle experience")
 var seed:=stream.tile_seed(key)
 check(seed==stream.tile_seed(key) and seed!=stream.tile_seed(key+Vector2i.ONE),"World generation seeds are stable and tile-specific")
 stream.update_center(Vector3(-1500,0,900))
 while not stream.queue.is_empty():stream.load_tile(stream.queue.pop_front())
 await process_frame
 check(stream.chunks.size()==9 and expedition.fauna.size()==66,"Long travel unloads old tiles and keeps live wildlife bounded")
 check(expedition.specimens.size()==96,"Unloaded specimens are removed from scan and capture lists")
 var query:=PhysicsRayQueryParameters3D.create(Vector3(-1440,100,960),Vector3(-1440,-100,960),1)
 await physics_frame
 check(not expedition.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"Distant wilderness has real terrain collision")
 expedition.queue_free();await process_frame
 for index in [1,2]:
  var other:=PlanetExpedition.new();other.profile=PlayerProfile.new();other.definition=PlanetCatalog.WORLDS[index];root.add_child(other)
  other.set_physics_process(false);other.bot.set_physics_process(false);other.wilderness.set_process(false)
  other.wilderness.load_tile(Vector2i(2,-2))
  check(other.fauna.size()==34 and other.world.flora_nodes.size()==6,"Wilderness supports "+other.definition.display_name)
  other.queue_free();await process_frame
 print("WILDERNESS TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
