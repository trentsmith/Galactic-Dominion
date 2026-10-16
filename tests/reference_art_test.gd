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
 var lunar_definition := CollectionCatalog.find("crew_lunaflutter")
 var lunar_model := AlienVisual.new()
 lunar_model.definition = lunar_definition
 root.add_child(lunar_model)
 check(lunar_model.wings.size() == 4, "Lunaflutter has four independent articulated 3D wings")
 check(lunar_model.find_children("*AntennaGem*","Node3D",true,false).size() == 2, "Lunaflutter has two faceted crystal antenna tips")
 check(lunar_model.eyes.size() == 2 and lunar_model.eyes[0].name.begins_with("HappyCrescentEye"), "Moon Moth uses glowing crescent eyes")
 var rest: Vector3 = lunar_model.wings[0].rotation
 lunar_model._process(0.35)
 check(rest.distance_to(lunar_model.wings[0].rotation) > 0.02, "Lunaflutter wing joints flutter at runtime")
 var moon_stats: ShipStats = stats.duplicate()
 moon_stats.variant_style = "moon_moth"
 var moon_ship := Node3D.new()
 SpaceModelFactory.ship(moon_ship,moon_stats)
 root.add_child(moon_ship)
 check(moon_ship.find_children("*MoonWing*","Node3D",true,false).size() >= 4 and moon_ship.find_child("MainEngine",true,false) != null, "Lunar Interceptor has real wings and preserves gameplay attachments")
 for model_name in ["lunaflutter_moon_moth","ship_lunaflutter_scout"]:
  var lunar_document := GLTFDocument.new()
  var lunar_state := GLTFState.new()
  check(lunar_document.append_from_file("res://art/models/"+model_name+".glb",lunar_state) == OK, model_name+" exports as valid portable glTF")
 var lunar_profile := PlayerProfile.new("user://lunar-model-test-%d.json" % Time.get_ticks_usec())
 lunar_profile.load_profile()
 lunar_profile.salvage = 500
 check(lunar_profile.research("crew_lunaflutter") and lunar_profile.research("variant_lunaflutter") and lunar_profile.salvage == 160, "Lunaflutter crew and scout appearance can be researched")
 var original := lunar_profile.configured_stats(0)
 check(lunar_profile.equip(0,"variant","variant_lunaflutter") and lunar_profile.equip(1,"variant","variant_lunaflutter"), "Lunar appearance fits Interceptors and Skirmishers")
 var fitted := lunar_profile.configured_stats(0)
 check(fitted.variant_style == "moon_moth" and fitted.speed == original.speed and fitted.laser_damage == original.laser_damage and fitted.hull == original.hull, "The moth ship appearance does not change combat statistics")
 check(lunar_profile.equip(0,"crew","crew_lunaflutter"), "Moon Moth crew fits the existing companion slot")
 var restored := PlayerProfile.new(lunar_profile.save_path)
 restored.load_profile()
 check(restored.configured_stats(0).crew_id == "crew_lunaflutter" and restored.configured_stats(0).variant_style == "moon_moth", "Moon Moth crew and ship appearance persist through saving")
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(lunar_profile.save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(lunar_profile.save_path+suffix))
 lunar_model.queue_free();moon_ship.queue_free()
 model.queue_free();ship.queue_free();world.queue_free()
 await process_frame
 print("REFERENCE ART TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
