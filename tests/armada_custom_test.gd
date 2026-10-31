extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func freeze(battle: BattleMatch) -> void:
 battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
func run() -> void:
 var time:=Ballistics.intercept_time(Vector3(0,0,-400),Vector3(80,0,0),260,3)
 check(time>0 and absf((Vector3(0,0,-400)+Vector3(80,0,0)*time).length()-260*time)<.001,"Quadratic interception meets a laterally moving target")
 check(Ballistics.intercept_time(Vector3(0,0,-400),Vector3(0,0,-300),260,3)<0,"An unreachable target has no false firing solution")
 check(Ballistics.intercept_time(Vector3(0,0,-1000),Vector3.ZERO,260,3)<0,"The firing solution respects projectile lifetime")
 check(ArmadaCombat.count(0)==1 and ArmadaCombat.count(500)==200 and ArmadaCombat.count("bad")==200,"Both fleet counts are bounded and invalid saved values are safe")
 var host=load("res://scenes/main.tscn").instantiate();host.profile_path="user://custom-%d.json"%Time.get_ticks_usec();root.add_child(host);await process_frame
 host.difficulty="standard";host.armada_allies=200;host.armada_enemies=200
 host.menu.find_child("ArmadaButton",true,false).pressed.emit();await process_frame
 var setup:=host.menu.get_child(0) as ArmadaSetup
 check(setup!=null and setup.allies.max_value==200 and setup.enemies.min_value==1,"The title action opens independent editable fleet counts")
 setup.allies.value=200;setup.enemies.value=50
 check(setup.launch.text.contains("200 v 50") and setup.summary.text.contains("199 AI"),"The setup explains which fleet contains the player")
 setup.enemies.value=200
 setup.enemies.get_line_edit().text="50"
 setup.launch.pressed.emit();await process_frame
 var battle: BattleMatch=host.battle;freeze(battle)
 check(battle.ships.size()==250 and battle.living(0)==200 and battle.living(1)==50 and battle.is_armada(),"Launching 200v50 creates exactly the requested fleets")
 check(battle.mode_name()=="200v50" and DifficultyPlaytest.summary(battle).mode=="200v50","Reports use the actual asymmetric matchup")
 var saved:=ConfigFile.new();saved.load("user://settings.cfg")
 check(saved.get_value("armada","allies")==200 and saved.get_value("armada","enemies")==50,"Fleet sizes persist for later launches")
 var enemy: CombatShip=battle.ships[200]
 check(enemy.health.max_hull==BattleMatch.CLASSES[0].hull and enemy.health.regen_rate==enemy.stats.shield_regen,"Standard Armada removes enemy durability and regeneration handicaps")
 check(enemy.weapons.secondary.speed==220 and enemy.targeting.lock_duration==.8,"Enemy missiles receive matching flight and lock capabilities")
 battle.finish(0,"test replay")
 battle.hud.results.find_child("ReplayBattleButton",true,false).pressed.emit();await process_frame
 check(host.battle.mode_name()=="200v50" and host.battle.ships.size()==250,"Replay preserves both fleet counts")
 host.start_armada(81337,50,200);await process_frame;freeze(host.battle)
 check(host.battle.living(0)==50 and host.battle.living(1)==200 and host.battle.ships[249].fleet_slot==199,"The reversed 50v200 matchup creates the larger enemy fleet correctly")
 host.start_armada(81337,3,1);await process_frame;battle=host.battle;freeze(battle)
 check(battle.ships.size()==4 and battle.sector_map!=null and battle.elimination_only,"Small custom fleets still use Armada terrain and elimination rules")
 var shooter: CombatShip=battle.ships[3];var target: CombatShip=battle.ships[0]
 shooter.position=Vector3(0,3500,0);shooter.rotation=Vector3.ZERO
 target.position=Vector3(0,3500,-400);target.velocity=Vector3(80,0,0)
 target.health.max_hull=2000;target.health.hull=2000;target.health.max_shield=0;target.health.shield=0;target.health.protection=1
 shooter.targeting.select(target)
 var origin:=shooter.position-Vector3.BACK*5
 var aim:=Ballistics.aim_point(origin,target.position,target.velocity,shooter.weapons.primary.speed,shooter.weapons.primary.lifetime)
 shooter.look_at(aim)
 await physics_frame;await physics_frame
 var hp:=target.health.hull
 check(shooter.weapons.fire(),"An AI ship fires a real predictive laser projectile")
 for i in range(140):
  target.position+=target.velocity/60
  await physics_frame
 check(target.health.hull<hp,"The actual laser hits a moving ship rather than its old lead point")
 # Target retention: tiny nearest-distance changes must not restart missile locks.
 var first:=battle.ships[1];var second:=battle.ships[2]
 first.position=Vector3(0,3500,-100);second.position=Vector3(0,3500,-92);target.position=Vector3(2000,3500,0)
 shooter.position=Vector3(0,3500,0);shooter.targeting.select(first);shooter.targeting.lock_time=.6
 battle.spatial.rebuild(battle.ships);shooter.brain.commanded_target=null;shooter.brain._find_target()
 check(shooter.targeting.target==first and shooter.targeting.lock_time==.6,"Minor distance changes retain the target and preserve missile lock progress")
 second.position=Vector3(0,3500,-35);battle.spatial.rebuild(battle.ships);shooter.brain._find_target()
 check(shooter.targeting.target==second,"A substantially better nearby target can still be selected")
 var wall:=StaticBody3D.new();wall.position=Vector3(0,3500,-15);wall.collision_layer=2
 var shape:=BoxShape3D.new();shape.size=Vector3(30,30,4);var collision:=CollisionShape3D.new();collision.shape=shape;wall.add_child(collision);battle.add_child(wall)
 shooter.rotation=Vector3.ZERO
 await physics_frame;await physics_frame
 check(not shooter.brain.clear_shot(second.position),"AI refuses a firing path blocked by an asteroid-like obstacle")
 var standard:=ArmadaCombat.enemy_stats(BattleMatch.CLASSES[0],"standard")
 var veteran:=ArmadaCombat.enemy_stats(BattleMatch.CLASSES[0],"veteran")
 var relaxed:=ArmadaCombat.enemy_stats(BattleMatch.CLASSES[0],"relaxed")
 check(veteran.turn_speed>standard.turn_speed and veteran.laser_cooldown<standard.laser_cooldown and veteran.laser_damage==standard.laser_damage,"Veteran pressure comes from tracking and firing rather than raw damage")
 check(relaxed.hull<standard.hull and BattleMatch.CLASSES[0].hull==50,"Relaxed remains accessible and catalog resources stay unchanged")
 host.queue_free();await process_frame;await process_frame
 print("ARMADA_CUSTOM_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
