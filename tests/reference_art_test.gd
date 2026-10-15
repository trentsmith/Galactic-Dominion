extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: " + message)
 else: failures += 1;push_error("FAIL: " + message)
func run() -> void:
 var definition := CollectionCatalog.find("crew_pixlet")
 check(definition != null and definition.species == "Pebble" and definition.kind == "crew", "Pixlet is a real collectible crew resource")
 var model := AlienVisual.new()
 model.definition = definition
 root.add_child(model)
 check(model.find_children("*ThrusterPod*","Node3D",true,false).size() == 3, "Pixlet has three separate 3D thruster pods")
 check(model.find_child("GlossyVisor",true,false) != null and model.eyes.size() == 2, "Pixlet has a glossy visor and two animated luminous eyes")
 check(model.find_children("*SweptFin*","Node3D",true,false).size() == 2, "Pixlet fins use thick curved mesh geometry")
 model._process(4.1)
 check(model.eyes[0].scale.y < 0.1, "The redesigned face retains blinking animation")
 var document := GLTFDocument.new()
 var state := GLTFState.new()
 var loaded := document.append_from_file("res://art/models/pixlet_pebble_scout.glb",state) == OK
 check(loaded, "Pixlet GLB opens as valid glTF 2.0")
 var imported: Node3D = document.generate_scene(state) if loaded else null
 check(imported != null and imported.find_children("","MeshInstance3D",true,false).size() > 25, "Portable GLB contains real editable mesh parts")
 if imported != null: imported.free()
 var stats: ShipStats = CollectionCatalog.SHIP_TYPES.interceptor
 var ship := Node3D.new()
 SpaceModelFactory.ship(ship,stats)
 root.add_child(ship)
 check(ship.find_child("PilotCanopy",true,false) != null and ship.find_child("MainEngine",true,false) != null, "New spacecraft has a separate canopy and working engine attachment")
 var world := Node3D.new()
 root.add_child(world)
 var planet := SpaceEnvironmentArt.planet(world,Vector3.ZERO,5,Color(0.04,0.3,0.8),2.0,true)
 check(planet.find_child("TerrainGlobe",true,false) != null and planet.find_child("AtmosphereRim",true,false) != null, "Planet is 3D terrain with a separate atmosphere shell")
 var background := SpaceEnvironmentArt.environment()
 check(background.environment.background_mode == Environment.BG_SKY, "Starfield uses a nebula sky instead of a flat background")
 background.free()
 var a: PackedVector3Array = SpaceEnvironmentArt.asteroid_mesh(20).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 var b: PackedVector3Array = SpaceEnvironmentArt.asteroid_mesh(21).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 check(a != b and a.size() > 100, "Cratered asteroids have distinct generated 3D geometry")
 var profile := PlayerProfile.new("user://pixlet-art-test-%d.json" % Time.get_ticks_usec())
 profile.load_profile()
 profile.acquire("crew_pixlet")
 check(profile.equip(0,"crew","crew_pixlet") and profile.configured_stats(0).crew_id == "crew_pixlet", "Pixlet can be fitted through the existing crew system")
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(profile.save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path+suffix))
 model.queue_free();ship.queue_free();world.queue_free()
 await process_frame
 print("REFERENCE ART TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
