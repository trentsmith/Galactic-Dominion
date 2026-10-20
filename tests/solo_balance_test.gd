extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func run() -> void:
 var missile_events:=InputMap.action_get_events("missile")
 var chart_events:=InputMap.action_get_events("sector_map")
 check(missile_events.size()==1 and missile_events[0] is InputEventKey and missile_events[0].physical_keycode==KEY_M,"Missile action is bound to M")
 check(chart_events[0].physical_keycode==KEY_J,"Star chart moved to J to avoid a missile conflict")
 var battle:=BattleMatch.new();root.add_child(battle)
 battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 check(battle.fleet.current_command=="attack","Friendly wingmates engage from match start")
 var ally:=battle.ships[0];var enemy:=battle.ships[3]
 check(enemy.stats.hull<BattleMatch.CLASSES[0].hull and enemy.stats.shield<BattleMatch.CLASSES[0].shield,"Solo opponents have reduced hull and shields")
 check(BattleMatch.CLASSES[0].hull==50 and BattleMatch.CLASSES[0].shield==40,"Solo tuning does not mutate shared ship resources")
 check(enemy.companion==null,"Solo opponents do not receive free alien attack companions")
 check(enemy.weapons.primary.cooldown>ally.weapons.primary.cooldown,"Solo opponents fire at a slower rate")
 check(enemy.health.regen_rate<ally.health.regen_rate,"Opponents regenerate shields more slowly")
 check(ally.weapons.secondary.speed>BattleMatch.CLASSES[0].speed*1.8,"Allied missiles can overtake a normally boosting interceptor")
 check(ally.weapons.aim_assist_dot<enemy.weapons.aim_assist_dot,"Allied lasers get a wider aim-assist cone")
 check(ally.targeting.lock_duration==.8 and enemy.targeting.lock_duration==1.2,"Solo player missiles acquire targets faster")
 for ship in battle.ships:ship.position=Vector3(20000+ship.fleet_slot*30,0,ship.team*1000)
 ally.position=Vector3.ZERO;ally.rotation=Vector3.ZERO;enemy.position=Vector3(0,0,-80);enemy.rotation=Vector3.ZERO
 ally.targeting.select(enemy);ally.targeting.tick(.8)
 check(ally.targeting.locked(),"A real forward target locks after 0.8 seconds")
 var key:=InputEventKey.new();key.physical_keycode=KEY_M;key.keycode=KEY_M;key.pressed=true;Input.parse_input_event(key)
 Input.flush_buffered_events();await process_frame
 check(Input.is_action_pressed("missile") and not Input.is_action_pressed("sector_map"),"M requests missiles without opening the chart")
 check(ally.weapons.fire(true),"The locked missile weapon actually fires")
 var released:=key.duplicate() as InputEventKey;released.pressed=false;Input.parse_input_event(released)
 Input.flush_buffered_events()
 var missile: SpaceProjectile
 for node in battle.get_children():
  if node is SpaceProjectile and node.spec.tracking:missile=node
 check(is_instance_valid(missile) and missile.target==enemy,"The missile tracks the selected AI opponent")
 var before:=enemy.health.hull+enemy.health.shield
 missile.impact(enemy,enemy.global_position)
 check(enemy.health.hull+enemy.health.shield<before,"Missiles deal real shield and hull damage")
 missile.queue_free();await process_frame
 ally.position=Vector3(5000,1000,0);ally.rotation=Vector3.ZERO
 enemy.redeploy(Vector3(5000,1000,-80),0)
 ally.targeting.select(enemy);ally.targeting.lock_time=ally.targeting.lock_duration;ally.weapons.missile_remaining=0
 var full_health:=enemy.health.hull+enemy.health.shield
 ally.weapons.fire(true)
 for frame in range(240):
  enemy.position.z-=enemy.stats.speed*1.8/60.0
  await physics_frame
  if enemy.health.hull+enemy.health.shield<full_health:break
 check(enemy.health.hull+enemy.health.shield<full_health,"A real homing projectile catches and damages a boosting AI target")
 enemy.redeploy(Vector3(0,0,-80),0);ally.position=Vector3.ZERO
 enemy.health.shield=0;enemy.brain.retreat_latch=false;enemy.brain.retreat_elapsed=0;enemy.targeting.select(ally)
 enemy.brain.tick(.1)
 check(enemy.brain.state==ShipBrain.State.RETREAT,"Depleted opponents can still retreat briefly")
 enemy.brain.tick(4)
 check(enemy.brain.state!=ShipBrain.State.RETREAT,"Depleted opponents stop indefinitely fleeing after the retreat window")
 enemy.brain.command="retreat";enemy.brain.tick(1)
 check(enemy.brain.state==ShipBrain.State.RETREAT,"Explicit retreat orders remain functional")
 battle.queue_free();await process_frame
 var online:=BattleMatch.new();online.network_role="server";root.add_child(online)
 online.set_physics_process(false)
 check(online.ships[3].stats.hull==BattleMatch.CLASSES[0].hull and online.ships[0].targeting.lock_duration==1.2,"Online matches retain original hull durability and lock timing")
 check(online.ships[0].weapons.secondary.speed==125 and online.ships[3].brain.burst_pause==0,"Online weapon and AI balance remain unchanged")
 online.queue_free();await process_frame
 print("SOLO BALANCE TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
