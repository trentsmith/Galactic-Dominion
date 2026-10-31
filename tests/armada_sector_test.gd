extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func run() -> void:
 var a:=ArmadaSector.new();a.seed_value=81337;a.generate()
 var b:=ArmadaSector.new();b.seed_value=81337;b.generate()
 var c:=ArmadaSector.new();c.seed_value=91231;c.generate()
 check(a.anchors==b.anchors and a.hazards==b.hazards and a.fields==b.fields,"A seed reproduces the whole sector layout")
 check(a.anchors!=c.anchors and a.hazards!=c.hazards,"Different seeds change terrain and spawn locations")
 var safe:=true
 for team in range(2):
  for slot in range(200):
   var at:=a.spawn_position(team,slot)
   safe=safe and at.length()<ArmadaSector.RADIUS and a.safe(at,120)
 check(safe,"All 400 spawn points are inside the battle zone and outside gravity hazards")
 var star: Dictionary=a.hazards[0]
 var hole: Dictionary=a.hazards[2]
 check(a.gravity(star.position+Vector3(300,0,0)).x<0 and absf(a.gravity(star.position+Vector3(300,0,0)).z)>0,"Stellar gravity creates both inward pull and sideways drift")
 check(a.gravity(hole.position+Vector3(300,0,0)).x<0 and a.gravity(Vector3(0,7000,0))==Vector3.ZERO,"Black-hole pull is local and points toward the core")
 a.free();b.free();c.free()
 var host=load("res://scenes/main.tscn").instantiate();host.profile_path="user://sector-%d.json"%Time.get_ticks_usec();root.add_child(host);await process_frame
 var button:=host.menu.find_child("ArmadaButton",true,false) as Button
 check(button!=null and button.text.contains("ARMADA") and button.custom_minimum_size.y>=50,"The title screen prominently offers configurable Armada")
 host.start_armada(81337,200,200);await process_frame
 var battle: BattleMatch=host.battle
 battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 check(battle.sector_map.asteroid_count>250,"The sector has hundreds of physical asteroids")
 check(battle.pilot.ship.targeting.target==null,"Initial spawning does not reveal an enemy fleet across the map")
 var chart: ArmadaChart=battle.find_children("","ArmadaChart",true,false)[0]
 var player:=battle.ships[0];var enemy:=battle.ships[200]
 var at:=Vector3(0,4000,0);player.position=at;enemy.position=at+Vector3(0,0,-1500)
 enemy.alive=true;enemy.health.dead=false
 check(not chart.detected(enemy),"The sector chart hides an enemy beyond sensor range")
 player.targeting.select(enemy);player.targeting.tick(.1)
 check(player.targeting.target==null,"Target selection cannot retain a hidden enemy")
 enemy.position=at+Vector3(0,0,-500)
 check(chart.detected(enemy),"Nearby enemies appear as sensor contacts")
 battle.spatial.rebuild(battle.ships)
 var nearby:=battle.spatial.nearby(at,600)
 check(enemy in nearby and nearby.size()<battle.ships.size()/2,"Shared spatial queries find nearby ships without scanning the entire fleet")
 player.brain.sensor_range=ArmadaSector.SENSOR;player.brain.commanded_target=null;player.brain._find_target()
 check(player.targeting.target==enemy,"AI target acquisition uses the same local sensor rules")
 var gravity_star: Dictionary=battle.sector_map.hazards[0]
 player.position=gravity_star.position+Vector3(300,0,0);battle.sector_map.tick(.1)
 player.movement.tick(.1)
 check(player.movement.external_acceleration.length()>0 and player.movement.field_drift.length()>0,"Gravity produces persistent drift in actual ship movement")
 player.health.max_hull=1000;player.health.hull=1000;player.health.shield=0;player.health.protection=1
 player.position=gravity_star.position+Vector3(50,0,0);battle.sector_map.tick(.1)
 check(player.alive and player.health.hull<1000 and player.health.damage_history.back().source=="stellar corona","A star's hot core deals labelled environmental damage")
 var hole_data: Dictionary=battle.sector_map.hazards[2]
 enemy.position=hole_data.position;enemy.health.configure(enemy.stats);battle.sector_map.tick(.1)
 check(not enemy.alive and enemy.health.damage_history.back().source=="black hole","Crossing an event horizon destroys a ship with a clear damage cause")
 var base: CombatShip=battle.ships[3]
 var twin: CombatShip=battle.ships[8]
 check(base.find_child("ArmadaHull",true,false).mesh==twin.find_child("ArmadaHull",true,false).mesh,"Reinforcements of one class share merged mesh geometry")
 check(ArmadaArt.hulls.size()<=5 and base.find_child("ArmadaHull",true,false).mesh.get_surface_count()==1,"Class hulls use one shared geometry surface rather than many part draws")
 check(base.get_child_count()<15,"Detailed reinforcement hulls retain a bounded node count")
 var cached:=player.brain.nav_timer
 player.position=at;player.movement.external_acceleration=Vector3.ZERO
 SpaceNavigation.steer(player,at+Vector3(0,0,-100),.016)
 check(player.brain.nav_timer>cached,"Armada caches obstacle probes instead of recasting every physics tick")
 var key:=InputEventKey.new();key.physical_keycode=KEY_J;key.pressed=true
 chart._unhandled_input(key)
 check(chart.visible,"J opens the randomized sector chart")
 chart._unhandled_input(key)
 check(not chart.visible,"J closes the chart without pausing combat")
 battle.finished=true;chart.visible=true;chart._process(.016)
 check(not chart.visible,"The chart automatically closes so it cannot obscure battle results")
 host.queue_free();await process_frame;await process_frame
 print("ARMADA_SECTOR_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
