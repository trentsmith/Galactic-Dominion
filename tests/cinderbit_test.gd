extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var definition := CollectionCatalog.find("crew_cinderbit")
 check(definition != null and definition.species == "Comet Pup", "Cinderbit is a collectible Comet Pup crew member")
 var model := AlienVisual.new()
 model.definition = definition
 root.add_child(model)
 check(model.find_children("*CometPaw*","Node3D",true,false).size() == 4, "Cinderbit has four separate paw pods")
 check(model.find_children("*LuminousToeBean*","MeshInstance3D",true,false).size() == 12, "Every paw has three glowing toe beans")
 check(model.find_children("*CometEar*","Node3D",true,false).size() == 2 and model.eyes.size() == 2, "Cinderbit has two sculpted ears and animated eyes")
 var tail := model.comet_tail
 var rest := tail.rotation
 model._process(0.3)
 check(rest.distance_to(tail.rotation) > 0.05 and tail.find_child("WhiteHotFlame",true,false) != null, "The volumetric comet tail swishes at runtime")
 for name_text in ["cinderbit_comet_pup","ship_cinderbit_scout"]:
  var document := GLTFDocument.new()
  var state := GLTFState.new()
  var loaded := document.append_from_file("res://art/models/"+name_text+".glb",state) == OK
  var imported := document.generate_scene(state) if loaded else null
  check(imported != null and imported.find_child("CometTail",true,false) != null, name_text+" is a valid GLB containing actual flame geometry")
  if imported != null:imported.free()
 var profile := PlayerProfile.new("user://cinderbit-test-%d.json" % Time.get_ticks_usec())
 profile.load_profile()
 profile.salvage = 500
 check(profile.research("crew_cinderbit") and profile.research("variant_cinderbit") and profile.salvage == 160, "Both Cinderbit items can be researched through existing progression")
 var original := profile.configured_stats(0)
 check(profile.equip(0,"variant","variant_cinderbit") and profile.equip(1,"variant","variant_cinderbit"), "The Comet Pup appearance fits Interceptors and Skirmishers")
 var fitted := profile.configured_stats(0)
 check(fitted.speed == original.speed and fitted.hull == original.hull and fitted.laser_damage == original.laser_damage, "Cinderbit ship styling is cosmetic")
 profile.equip(0,"crew","crew_cinderbit")
 var restored := PlayerProfile.new(profile.save_path)
 restored.load_profile()
 check(restored.configured_stats(0).crew_id == "crew_cinderbit" and restored.configured_stats(0).variant_style == "comet_pup", "Cinderbit crew and ship appearance persist through save/reload")
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = profile.save_path
 root.add_child(main)
 await process_frame
 main.start_battle()
 await process_frame
 var battle: BattleMatch = main.battle
 battle.set_physics_process(false)
 battle.pilot.set_physics_process(false)
 for candidate in battle.ships:
  candidate.set_physics_process(false)
  if is_instance_valid(candidate.companion):candidate.companion.set_physics_process(false)
 var ship: CombatShip = battle.ships[0]
 var companion := ship.companion
 check(is_instance_valid(companion) and companion.attack_damage == 9 and companion.attack_interval == 2 and companion.attack_range == 260, "Meteor Nuzzle has distinct attack stats and range")
 var target: CombatShip = battle.ships[3]
 target.position = ship.position+Vector3(0,0,-40)
 target.health.shield = 0
 var hull_before := target.health.hull
 ship.set_physics_process(true)
 check(companion.fire_at(target) and not companion.fire_at(target), "Meteor Nuzzle fires once and respects its cooldown")
 ship.set_physics_process(false)
 var spark: SpaceProjectile
 for child in battle.get_children():
  if child is SpaceProjectile and child.shooter == ship:spark = child
 check(is_instance_valid(spark) and spark.spec.speed == 230 and not spark.spec.tracking, "Meteor Nuzzle uses a fast amber spark rather than a homing attack")
 for index in range(25):await physics_frame
 check(target.health.hull < hull_before and ship.damage_dealt >= 9, "Meteor Nuzzle hits an enemy and credits its host ship")
 ship.set_physics_process(true)
 companion.attack_cooldown = 0
 target.position = ship.position+Vector3(0,0,-500)
 check(not companion.fire_at(target), "Meteor Nuzzle cannot fire outside its shorter range")
 target.position = ship.position+Vector3(0,0,-40)
 battle.network_role = "client"
 check(not companion.fire_at(target), "Cinderbit clients cannot generate authoritative damage")
 main.queue_free();model.queue_free()
 await process_frame
 await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(profile.save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path+suffix))
 print("CINDERBIT TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
