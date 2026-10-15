extends SceneTree
var checks := 0
var failures := 0
var main: Node
var path := ""
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: " + message)
 else:
  failures += 1
  push_error("FAIL: " + message)
func frames(count: int = 3) -> void:
 for index in range(count): await process_frame
func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 path = "user://companion-test-%d.json" % Time.get_ticks_usec()
 main.profile_path = path
 root.add_child(main)
 await frames()
 main.profile.acquire("crew_nyx")
 check(main.profile.equip(0,"crew","crew_nyx"),"An owned alien can be equipped in the existing crew slot")
 check(main.profile.configured_stats(0).crew_id == "crew_nyx","Crew identity reaches reusable ship statistics")
 main.start_battle()
 await frames()
 var battle: BattleMatch = main.battle
 battle.set_physics_process(false)
 battle.pilot.set_physics_process(false)
 for candidate in battle.ships:
  candidate.set_physics_process(false)
  if is_instance_valid(candidate.companion): candidate.companion.set_physics_process(false)
 var ship: CombatShip = battle.ships[0]
 var companion: AlienCompanion = ship.companion
 check(is_instance_valid(companion) and companion.definition.species == "Vesperi","Equipped alien creates a real 3D orbiting companion")
 check(not is_instance_valid(battle.ships[1].companion),"Astronaut crew do not create alien companions")
 check(battle.ships[3].companion != null,"Enemy crew can also fly and attack as companions")
 battle.elapsed = 0
 companion._process(0.1)
 var first := companion.position
 battle.elapsed = 1
 companion._process(0.1)
 check(first.distance_to(companion.position) > 2 and absf(Vector2(companion.position.x,companion.position.z).length() - 5.8) < 0.01,"Companion moves in a stable orbit around its host")
 check(companion.visual.get_child_count() > 12,"Original alien mesh has a rounded body, eyes, cheeks and species details")
 var hull_material := (ship.get_child(6) as MeshInstance3D).material_override if ship.get_child(6) is MeshInstance3D else null
 var outlined := false
 for child in ship.get_children():
  if child is MeshInstance3D and child.material_override is StandardMaterial3D:
   if child.material_override.next_pass is ShaderMaterial: outlined = true
 check(outlined,"Ship meshes use cartoon shading and outline passes")
 var target: CombatShip = battle.ships[3]
 target.position = ship.position + Vector3(5,2,-40)
 target.health.shield = 0
 target.health.hull = target.health.max_hull
 ship.targeting.select(target)
 check(companion.choose_target() == target,"Companion prioritizes the selected enemy within attack range")
 check(not companion.fire_at(battle.ships[1]),"Companion refuses to attack friendly ships")
 ship.set_physics_process(true)
 companion.attack_cooldown = 0
 var damage_before := ship.damage_dealt
 var hull_before := target.health.hull
 check(companion.fire_at(target),"Companion fires a real combat projectile")
 check(not companion.fire_at(target),"Attack cooldown prevents duplicate firing")
 for index in range(40): await physics_frame
 check(target.health.hull < hull_before and ship.damage_dealt > damage_before,"Companion projectiles damage enemies and credit the host ship")
 check(companion.attacks == 1,"One attack creates one credited shot")
 target.position = ship.position + Vector3(0,0,-1000)
 companion.attack_cooldown = 0
 check(not companion.fire_at(target),"Companion cannot fire outside its attack range")
 var rare := AlienCompanion.new()
 rare.ship = ship
 rare.definition = CollectionCatalog.find("crew_nyx_prism")
 ship.add_child(rare)
 rare.set_physics_process(false)
 check(rare.attack_damage == companion.attack_damage and rare.attack_interval == companion.attack_interval,"Legendary appearances do not give a stronger companion attack")
 rare.queue_free()
 var luna := AlienCompanion.new()
 luna.ship = ship
 luna.definition = CollectionCatalog.find("crew_lunaflutter")
 ship.add_child(luna)
 luna.set_physics_process(false)
 target.position = ship.position + Vector3(0,0,-40)
 check(luna.attack_damage == 5 and is_equal_approx(luna.attack_interval,1.6), "Dream Drift has its own balanced attack cadence")
 check(luna.fire_at(target), "Lunaflutter fires Dream Drift at an enemy")
 var dream: SpaceProjectile
 for node in battle.get_children():
  if node is SpaceProjectile and node.shooter == ship: dream = node
 check(is_instance_valid(dream) and dream.spec.tracking and dream.spec.speed == 125 and dream.spec.turn_rate == 1.8, "Dream Drift creates a slow gently tracking projectile")
 var lunar_hull_before := target.health.hull
 for index in range(40): await physics_frame
 check(target.health.hull < lunar_hull_before, "Dream Drift reaches and damages a real enemy")
 battle.network_role = "client"
 luna.attack_cooldown = 0
 check(not luna.fire_at(target), "Moon Moth clients cannot generate authoritative damage")
 battle.network_role = "local"
 luna.queue_free()
 ship.health.protection = 1
 ship.health.damage(100000,null)
 companion._process(0.1)
 check(not companion.visible and not companion.fire_at(target),"Companion disappears and stops attacking when its host is destroyed")
 ship.redeploy(ship.position)
 companion._process(0.1)
 check(companion.visible,"Companion returns with its redeployed ship")
 battle.network_role = "client"
 target.position = ship.position + Vector3(0,0,-40)
 check(not companion.fire_at(target),"Replicated companions cannot generate client-side damage")
 main.return_to_menu()
 main.show_hangar()
 await frames()
 var hangar: HangarScreen = main.menu.get_child(0)
 check(is_instance_valid(hangar.preview.ship.companion),"The hangar preview shows the fitted alien companion")
 check(not hangar.preview.ship.companion.fire_at(null),"Hangar preview companions cannot fire")
 var restored := PlayerProfile.new(path)
 restored.load_profile()
 check(restored.configured_stats(0).crew_id == "crew_nyx","Alien crew fitting survives save/reload")
 main.queue_free()
 await frames()
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 OS.delay_msec(50)
 print("ALIEN COMPANION TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
