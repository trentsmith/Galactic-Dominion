extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var world := Node3D.new();root.add_child(world)
 for hull in CollectionCatalog.SHIP_TYPES:
  var model := Node3D.new();world.add_child(model)
  SpaceModelFactory.ship(model,CollectionCatalog.SHIP_TYPES[hull])
  check(model.find_child("BlueRearArmor",true,false).mesh is ArrayMesh,hull+" uses a sculpted rear deck instead of a sphere")
  check(model.find_child("CanopyEye",true,false)==null,hull+" standard cockpit has no face")
  check(model.find_children("SplitEnginePod*","Node3D",true,false).size()==2,hull+" has two mechanical split nacelles")
  var glass: StandardMaterial3D=model.find_child("FlightDeckGlass",true,false).material_override
  check(glass.clearcoat_enabled and glass.roughness<.25,hull+" has a layered glass cockpit material")
  check(model.find_children("RecessedCoolingVent*","MeshInstance3D",true,false).size()==8,hull+" has recessed cooling details")
  check(model.find_child("MainEngine",true,false).mesh is ArrayMesh and model.find_child("AftIonAperture",true,false)!=null,hull+" has a tapered exhaust and recessed aperture")
 var rift:=RiftAnomalyArt.build(world,Vector3.ZERO)
 check(rift.get_child_count()==4 and rift.find_children("VioletEnergyFilament*","MeshInstance3D",true,false).size()==2,"Rift energy filaments use two meshes, not thousands of cylinder nodes")
 var planet := SpaceEnvironmentArt.planet(world,Vector3.ZERO,40,Color(.1,.3,.2),8.2,true)
 check(planet.get_node("CloudLayer").scale.x>1 and planet.get_node("CloudLayer").scale.x<planet.get_node("AtmosphereRim").scale.x,"Planet clouds occupy a separate shell beneath the atmosphere")
 check(planet.get_node("CloudLayer").material_override.shader==SpaceEnvironmentArt.CLOUDS,"Cloud patterns use an independent animated material")
 check(planet.get_node("PlanetaryRing").material_override.shader==SpaceEnvironmentArt.RINGS,"Planet rings have fine bands and a transparent gap")
 check(planet.get_node("TerrainGlobe").visibility_range_end==400,"Planet visual polish retains its distance visibility budget")
 var rock_a:=SpaceEnvironmentArt.asteroid_mesh(20)
 var rock_b:=SpaceEnvironmentArt.asteroid_mesh(21)
 check(rock_a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=rock_b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"Asteroid geometry retains deterministic seed variation")
 var wreck := Node3D.new();world.add_child(wreck);SceneryArt.wreck(wreck,Vector3(12,8,20))
 check(wreck.find_child("EmptyEngineBell",true,false)!=null and wreck.find_children("SeveredConduit*","MeshInstance3D",true,false).size()==2,"Wrecks have a recessed engine and severed conduits")
 var preview := ShipPreview.new();root.add_child(preview)
 preview.show_stats(CollectionCatalog.SHIP_TYPES.guardian)
 await process_frame
 check(preview.viewport.msaa_3d==Viewport.MSAA_4X and preview.viewport.own_world_3d,"The Hangar preview uses antialiasing in an isolated world")
 var cameras := preview.scene.find_children("*","Camera3D",true,false)
 check(cameras.size()==1 and cameras[0].position.z<0,"Hangar framing starts in front of the ship")
 check(preview.scene.find_children("*","DirectionalLight3D",true,false).size()==2,"Hangar preview has independent key and rim lighting")
 check(not preview.ship.is_physics_processing() and not preview.ship.is_in_group("ships"),"Visual previews stay out of combat simulation")
 preview.queue_free();world.queue_free();await process_frame;await process_frame
 print("CELESTIAL ART TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
