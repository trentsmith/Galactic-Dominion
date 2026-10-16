extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var profile := PlayerProfile.new("user://fleet-companions-%d.json"%Time.get_ticks_usec())
 profile.load_profile()
 profile.salvage = 1000
 for id in ["orbitot","glimbloom"]:
  var definition := CollectionCatalog.find("crew_"+id)
  check(definition != null and definition.research_cost==180 and definition.rarity=="uncommon",id+" is researchable without changing rare variant odds")
  check(profile.research(definition.id) and profile.equip(0,"crew",definition.id),id+" is researchable and fits the crew slot")
  var restored := PlayerProfile.new(profile.save_path)
  restored.load_profile()
  check(restored.configured_stats(0).crew_id==definition.id,id+" persists across save/reload")
  var visual := AlienVisual.new()
  visual.definition = definition
  root.add_child(visual)
  check(visual.eyes.size()==2,id+" has two animated luminous eyes")
  check(visual.orbit_pivots.size()>=1,id+" exposes independent orbit pivots")
  var first := visual.orbit_pivots[0].quaternion
  visual._process(0.5)
  check(not first.is_equal_approx(visual.orbit_pivots[0].quaternion),id+" satellites animate in real 3D")
  if id=="orbitot":
   check(visual.find_children("SatelliteCasing*","MeshInstance3D",true,false).size()==6,"Orbitot has six satellites on two separate tilted orbits")
   check(visual.find_child("CrownPlanetRing",true,false)!=null,"Orbitot carries a ringed planet crown")
  else:
   check(visual.wings.size()==6,"Glimbloom has six articulated crystal petals")
   check(visual.find_child("ForeheadPrism",true,false)!=null and visual.find_children("OrbitingPrism*","Node3D",true,false).size()==5,"Glimbloom has a forehead gem and five independent orbital shards")
  for suffix in [".glb",".tscn"]:
   var file: String = "res://art/models/"+id+"_fleet_companion"+suffix
   if suffix==".glb":
    var doc := GLTFDocument.new();var state := GLTFState.new()
    var error := doc.append_from_file(file,state)
    var imported := doc.generate_scene(state) if error==OK else null
    check(imported!=null,id+" is a valid portable GLB")
    if imported!=null:imported.free()
   else:check(load(file) is PackedScene,id+" has an editable self-contained Godot scene")
  visual.queue_free()
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = profile.save_path
 root.add_child(main)
 await process_frame
 main.start_battle()
 await process_frame
 var battle: BattleMatch = main.battle
 battle.set_physics_process(false)
 battle.pilot.set_physics_process(false)
 for ship in battle.ships:
  ship.set_physics_process(false)
  if is_instance_valid(ship.companion):ship.companion.set_physics_process(false)
 var ship: CombatShip = battle.ships[0]
 var target: CombatShip = battle.ships[3]
 var nearby: CombatShip = battle.ships[4]
 var ally: CombatShip = battle.ships[1]
 target.position = ship.position+Vector3(0,0,-40)
 nearby.position = target.position+Vector3(8,0,0)
 ally.position = target.position+Vector3(-8,0,0)
 target.health.protection=1;nearby.health.protection=1
 target.health.shield=0;nearby.health.shield=0
 for id in ["orbitot","glimbloom"]:
  var bot := AlienCompanion.new()
  bot.ship=ship;bot.definition=CollectionCatalog.find("crew_"+id)
  ship.add_child(bot)
  bot.set_physics_process(false);bot.set_process(false)
  ship.set_physics_process(true)
  check(bot.fire_at(target) and not bot.fire_at(target),id+" fires with an enforced cooldown")
  ship.set_physics_process(false)
  var shot: SpaceProjectile
  for child in battle.get_children():
   if child is SpaceProjectile and child.shooter==ship:shot=child
  check(shot!=null and shot.spec.impact_style==( "gravity_loop" if id=="orbitot" else "prism_pulse"),id+" uses its distinct projectile and impact")
  var before := target.health.hull
  var splash_before := nearby.health.hull
  var friendly_before := ally.health.shield
  # Exercise collision/flight, not just the impact helper.
  for index in range(50):await physics_frame
  check(target.health.hull<before,id+" projectile hits a real enemy")
  if id=="orbitot":
   check(target.movement.slow_remaining>0,"Gravity Loop applies a bounded movement slow")
   target.movement.apply_gravity_slow(99)
   check(target.movement.slow_remaining==1.5,"Gravity slow is capped and never stacks")
   target.movement.tick(2)
   check(target.movement.slow_remaining==0,"Gravity slow expires through the normal movement system")
   target.position=ship.position+Vector3(0,0,-40)
  else:
   check(nearby.health.hull<splash_before and ally.health.shield==friendly_before,"Prism Pulse splashes nearby enemies while protecting allies")
  check(ship.damage_dealt>0,id+" credits damage to its owning ship")
  bot.attack_cooldown=0
  ship.set_physics_process(true)
  var saved_position := target.position
  target.position=ship.position+Vector3(0,0,-1000)
  check(not bot.fire_at(target),id+" respects its maximum attack range")
  target.position=saved_position
  battle.network_role="client"
  ship.set_physics_process(true)
  check(not bot.fire_at(target),id+" cannot create damage from a network client")
  battle.network_role="local"
  ship.set_meta("spawn_protection",3)
  check(not bot.fire_at(target),id+" cannot attack through spawn protection")
  ship.set_meta("spawn_protection",0)
  ship.set_physics_process(false)
  bot.queue_free()
 # Verify splash line-of-sight independently of direct projectile collision.
 var wall := StaticBody3D.new()
 var collider := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(1,10,10)
 collider.shape=box;wall.add_child(collider);battle.add_child(wall)
 wall.position=target.position+Vector3(4,0,0)
 await physics_frame
 await physics_frame
 var pulse := SpaceProjectile.new()
 pulse.spec=WeaponSpec.new();pulse.spec.damage=8;pulse.spec.splash_radius=14
 pulse.team=ship.team;pulse.shooter=ship
 battle.add_child(pulse);pulse.set_physics_process(false)
 var blocked_before := nearby.health.hull
 pulse.impact(target,target.global_position)
 check(nearby.health.hull==blocked_before,"A solid obstacle blocks Prism Pulse splash")
 target.movement.slow_remaining=0
 target.health.protection=0
 pulse.spec.splash_radius=0;pulse.spec.slow_duration=1.5
 pulse.impact(target,target.global_position)
 check(target.movement.slow_remaining==0,"An invulnerable enemy cannot be slowed through spawn protection")
 main.queue_free()
 await process_frame
 await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(profile.save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path+suffix))
 print("FLEET COMPANIONS TEST: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
