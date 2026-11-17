extends SceneTree
class SightProbe extends ShipTargeting:
 var traces:=0
 func clear_line(point: Vector3,candidate: CombatShip=null) -> bool:
  traces+=1;return super.clear_line(point,candidate)
var checks:=0
var failures:=0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,words: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+words)
 if not ok:failures+=1
func frames() -> void:await process_frame;await physics_frame;await process_frame
func wall(parent: Node3D,at: Vector3) -> StaticBody3D:
 var body:=StaticBody3D.new();body.position=at;body.collision_layer=2;parent.add_child(body)
 var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(30,30,2);collision.shape=shape;body.add_child(collision);return body
func freeze(battle: BattleMatch) -> void:
 battle.set_physics_process(false);battle.pilot.set_physics_process(false);battle.hud.feedback.set_process(false)
 for ship in battle.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://handling-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 main.start_battle(10);await frames();var battle: BattleMatch=main.battle;freeze(battle)
 for i in range(battle.ships.size()):battle.ships[i].position=Vector3(20000+i*50,20000,20000)
 var player:=battle.ships[0];var target:=battle.ships[10];var side:=battle.ships[11];var rear:=battle.ships[12]
 var origin:=Vector3(0,6000,0);player.position=origin;player.rotation=Vector3.ZERO;player.velocity=Vector3.ZERO
 target.position=origin+Vector3(0,0,-240);side.position=origin+Vector3(40,0,-30);rear.position=origin+Vector3(0,0,40)
 var targeting:=player.targeting;targeting.selection_range=1000;targeting.enforce_range=true;targeting.select(null);targeting.cycle_order.clear();targeting.cycle()
 check(targeting.target==target,"Target acquisition favors the ship under the weapon axis over nearer offscreen ships")
 targeting.cycle();check(targeting.target==side,"A quick second target press advances to another enemy")
 side.position=origin+Vector3(240,0,0);targeting.cycle()
 check(targeting.target==rear,"Rapid target cycling keeps its order as ships move")
 player.look_at(side.global_position);targeting.cycle_age=3;targeting.cycle()
 check(targeting.target==side,"After a pause target acquisition follows the new aim direction")
 for ship in [target,side,rear]:ship.position=origin+Vector3(0,0,-1500)
 var other:=Node3D.new();root.add_child(other);var foreign:=CombatShip.new();foreign.stats=BattleMatch.CLASSES[0].duplicate(true);foreign.team=1;foreign.position=origin+Vector3(0,0,-20);other.add_child(foreign);foreign.set_physics_process(false)
 targeting.select(null);targeting.cycle()
 check(targeting.target==null,"Sensor limits apply and targets from another arena cannot enter the cycle")
 other.queue_free();await frames();target.position=origin+Vector3(0,0,-200);player.rotation=Vector3.ZERO
 targeting.select(target);target.team=0;targeting.tick(.1)
 check(targeting.target==null,"A faction vessel that becomes friendly loses its hostile target lock")
 target.team=1;targeting.select(target);target.position=origin+Vector3(0,0,-1200);targeting.tick(.1)
 check(targeting.target==null,"An enforced sensor boundary releases a departed target")
 target.position=origin+Vector3(0,0,-200);targeting.select(target);await frames();targeting.tick(targeting.lock_duration+.1)
 check(targeting.locked(),"A visible forward enemy can still acquire a full missile lock")
 var cover:=wall(battle,origin+Vector3(0,0,-100));await frames();targeting.tick(.13)
 check(not targeting.locked() and targeting.lock_reason.contains("OBSCURED"),"Cover interrupts acquisition and explains the obstruction")
 targeting.lock_time=targeting.lock_duration;player.weapons.missile_remaining=0;var shots:=player.shots
 check(not player.weapons.fire(true) and player.shots==shots and player.weapons.missile_remaining==0,"An immediate launch rechecks cover without spending a shot or cooldown")
 check(battle.hud.feedback.notice.contains("OBSCURED"),"The real weapon rejection reaches combat feedback")
 cover.queue_free();await frames();targeting.tick(targeting.lock_duration+.1)
 check(targeting.locked(),"Leaving cover allows the same enemy to lock again")
 var probe:=SightProbe.new();probe.ship=player;battle.add_child(probe);probe.select(target)
 for i in range(100):probe.tick(.001)
 check(probe.traces==1,"A burst of lock ticks shares one cached visibility trace")
 for i in range(30):probe.tick(.001)
 check(probe.traces==2,"Visibility is refreshed after the bounded polling interval")
 probe.queue_free()
 target.position=origin+Vector3(0,0,-650);targeting.tick(.13)
 check(not player.weapons.fire(true) and battle.hud.feedback.notice.contains("600m"),"Out-of-range missile attempts explain the real acquisition range")
 target.position=origin+Vector3(100,0,0);targeting.tick(.13)
 check(not targeting.locked() and targeting.lock_reason.contains("AHEAD"),"An off-axis target cannot retain a ready lock")
 target.position=origin+Vector3(10,0,-180);target.velocity=Vector3(45,0,-15);target.health.hull=500;target.health.max_hull=500;target.health.shield=0
 var solution:=player.weapons.laser_solution();player.look_at(solution.at);solution=player.weapons.laser_solution()
 check(solution.reachable and solution.at.x>target.position.x and solution.time>0,"The guide predicts a reachable moving target from the actual muzzle")
 player.weapons.laser_remaining=0;check(player.weapons.fire(),"A player laser with a moving-target solution launches")
 var laser: SpaceProjectile
 for child in battle.get_children():
  if child is SpaceProjectile and not child.spec.tracking:laser=child
 if is_instance_valid(laser):laser.set_physics_process(false)
 check(is_instance_valid(laser) and laser.direction.distance_to(solution.direction)<.0001,"The player laser and the guide share the exact interception direction")
 var hull:=target.health.hull
 for i in range(100):
  target.position+=target.velocity/60.0;await physics_frame
  if not is_instance_valid(laser) or laser.is_queued_for_deletion():break
  laser._physics_process(1.0/60.0)
  if target.health.hull<hull:break
 check(target.health.hull<hull,"A real predicted laser collides with and damages the moving ship")
 for child in battle.get_children():
  if child is SpaceProjectile:child.queue_free()
 await frames();target.position=origin+Vector3(0,0,-180);player.rotation=Vector3.ZERO;target.velocity=Vector3(0,0,-1000)
 check(not player.weapons.laser_solution().get("reachable",true),"A target faster than the projectile does not get a false lead solution")
 target.velocity=Vector3.ZERO;cover=wall(battle,origin+Vector3(0,0,-90));await frames();battle.hud.feedback.tick(.2)
 check(battle.hud.feedback.lead.get("reachable",false) and not battle.hud.feedback.lead.get("clear",true),"The lead guide knows when cover blocks the predicted shot")
 cover.queue_free();await frames();player.velocity=Vector3.ZERO
 var incoming:=SpaceProjectile.new();incoming.spec=target.weapons.secondary.duplicate();incoming.spec.speed=200;incoming.target=player;incoming.team=1;incoming.direction=Vector3.BACK;battle.add_child(incoming);incoming.position=origin+Vector3(0,0,-120);incoming.set_physics_process(false)
 var feedback:=battle.hud.feedback
 check(feedback.count_incoming()==1 and feedback.direction_label(feedback.incoming_position)=="FRONT" and absf(feedback.incoming_eta-.6)<.001,"Incoming missile guidance includes its actual bearing and closing estimate")
 var away:=SpaceProjectile.new();away.spec=incoming.spec.duplicate();away.target=player;away.team=1;away.direction=Vector3.BACK;battle.add_child(away);away.position=origin+Vector3(0,0,20);away.set_physics_process(false)
 check(feedback.count_incoming()==2 and feedback.incoming_position==incoming.position,"A closing threat takes priority over a nearer missile travelling away")
 away.direction=Vector3.FORWARD
 check(feedback.count_incoming()==2 and feedback.direction_label(feedback.incoming_position)=="REAR" and feedback.incoming_eta<.11,"The most urgent rear missile takes over directional guidance")
 feedback.notify("OLD SHIP ALERT");battle.fleet.switch_to(2);feedback.tick(.2)
 check(feedback.incoming_count==0 and feedback.notice_remaining==0,"Switching vessels clears the old ship's notices and missile warnings")
 incoming.queue_free();away.queue_free();battle.fleet.switch_to(0);player.position=origin;player.rotation=Vector3.ZERO;player.velocity=Vector3.ZERO
 var movement:=player.movement;movement.boost_energy=player.stats.boost_capacity;movement.boost_requested=true;movement.thrust=Vector3.ZERO;movement.tick(.1);battle.camera.fov=68;battle.pilot.update_camera(1)
 check(not movement.boost_active and is_equal_approx(battle.camera.fov,68),"Holding boost while stationary does not invent a camera speed effect")
 movement.thrust=Vector3.FORWARD;movement.boost_energy=1;movement.tick(.1)
 check(movement.boost_recovering and not movement.boost_active and movement.boost_energy==0,"Exhausting reserve enters a distinct boost recovery state")
 var pulsed:=false
 for i in range(10):movement.tick(.01);pulsed=pulsed or movement.boost_active
 check(not pulsed and movement.boost_energy>0,"Holding boost with an empty reserve recharges without rapid speed pulses")
 movement.boost_energy=maxf(8,player.stats.boost_capacity*.15)+1;movement.tick(.01)
 check(movement.boost_active and not movement.boost_recovering,"Boost resumes after building a usable reserve")
 battle.camera.fov=68;battle.pilot.update_camera(2)
 check(battle.camera.fov>68 and battle.camera.fov<78,"A long frame approaches boost FOV without overshooting it")
 FlightPreferences.reduced_camera_motion=true;battle.pilot.update_camera(2)
 check(absf(battle.camera.fov-68)<.1,"Reduced camera motion keeps the normal field of view during real boost")
 FlightPreferences.reduced_camera_motion=false;movement.boost_requested=false;movement.boost_active=false;player.velocity=Vector3.ZERO
 battle.camera.fov=68;battle.pilot.update_camera(1);var once:=battle.camera.global_position
 battle.camera.global_position=origin+Vector3(40,20,45);battle.camera.fov=68;var start:=battle.camera.global_position;battle.pilot.update_camera(1);once=battle.camera.global_position
 battle.camera.global_position=start
 for i in range(60):battle.pilot.update_camera(1.0/60.0)
 check(battle.camera.global_position.distance_to(once)<.001,"Chase-camera follow gives the same result at different frame rates")
 cover=wall(battle,player.position+Vector3(0,0,8));await frames();battle.pilot.take_control(player)
 check(battle.camera.global_position.z<origin.z+7,"A ship-switch camera snap stays in front of an intervening asteroid wall")
 cover.queue_free();await frames();battle.pilot.update_camera(.3)
 check(battle.camera.global_position.z>origin.z+7 and battle.camera.global_position.z<=origin.z+14.51,"The camera returns smoothly to chase distance when cover clears")
 battle.ships[1].alive=false;battle.fleet.switch_to(0);Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 var next:=InputEventAction.new();next.action="fleet_next";next.pressed=true;battle.fleet.handle_flight_input(next,false)
 check(battle.pilot.ship==player,"Fleet selection remains inactive while menus own flight input")
 battle.fleet.handle_flight_input(next,true)
 check(battle.pilot.ship==battle.ships[2],"The real next-ship action works in 10v10 and skips destroyed vessels")
 var previous:=InputEventAction.new();previous.action="fleet_previous";previous.pressed=true;battle.fleet.handle_flight_input(previous,true)
 check(battle.pilot.ship==player,"Previous-ship input also skips destroyed vessels")
 battle.fleet.switch_to(9);battle.fleet.handle_flight_input(next,true)
 check(battle.pilot.ship==player,"Fleet cycling wraps across all ten ships")
 var key:=InputEventKey.new();key.physical_keycode=KEY_W;key.pressed=true;battle.fleet.handle_flight_input(key,true)
 check(battle.pilot.ship==player and battle.hud.painter.fleet_binding(4)=="05","Ordinary fleet input avoids undefined F4-F10 actions and the HUD labels extra ships honestly")
 var old_path:=FlightPreferences.save_path;FlightPreferences.save_path="user://handling-controls.cfg";FlightPreferences.install();FlightPreferences.reduced_camera_motion=true;FlightPreferences.show_lead_guide=false
 check(FlightPreferences.save_display()==OK,"Camera comfort and lead-guide choices can be saved")
 FlightPreferences.reduced_camera_motion=false;FlightPreferences.show_lead_guide=true;FlightPreferences.install()
 check(FlightPreferences.reduced_camera_motion and not FlightPreferences.show_lead_guide,"Camera comfort and lead-guide preferences survive a reload")
 FlightPreferences.save_path=old_path;FlightPreferences.install()
 main.network.set_physics_process(false);var client:=BattleMatch.new();client.network_role="client";main.network.add_child(client);main.network.arena=client;main.network.peer_id=2;main.network.slot_owners.assign([2,0,0,0,0,0]);freeze(client)
 var states: Array=[]
 for ship in client.ships:states.append({"position":ship.position,"rotation":Quaternion.IDENTITY,"velocity":Vector3.ZERO,"hull":50.0,"shield":40.0,"boost":10.0,"boosting":false,"boost_recovering":true,"alive":true,"laser":0.0,"missile":0.0,"ability":0.0,"recharge":0.0,"target":3,"lock":1.2,"lock_reason":"TARGET OBSCURED / MOVE AROUND COVER","flash":0.0})
 var bullets:=[{"position":client.ships[0].position+Vector3(0,0,60),"direction":Vector3.FORWARD,"team":1,"missile":true,"target":0,"speed":250.0}]
 main.network.receive_snapshot(states,[2,0,0,0,0,0],0,1000,bullets)
 check(client.ships[0].movement.boost_recovering and not client.ships[0].movement.boost_active and client.ships[0].targeting.lock_reason.contains("OBSCURED"),"Host snapshots replicate real boost recovery and lock refusals to clients")
 var state:=Vector2(client.ships[0].health.hull,client.ships[0].health.shield)
 check(client.hud.feedback.count_incoming()==1 and absf(client.hud.feedback.incoming_eta-.24)<.001,"A network missile proxy uses the host's projectile speed for its closing estimate")
 check(Vector2(client.ships[0].health.hull,client.ships[0].health.shield)==state,"Network threat guidance never applies client-side damage")
 for ship in client.ships:ship.team=0
 client.fleet.ships.assign(client.ships);main.network.slot_owners.assign([11,0,0,2,0,0]);client.pilot.take_control(client.ships[3])
 check(client.hud.painter.fleet_binding(0,client.ships[0])=="ALLY" and client.hud.painter.fleet_binding(0,client.ships[3])=="F1","Co-op fleet labels distinguish another pilot's group from your own switch bindings")
 check(not client.hud.painter.can_cycle_fleet(),"Online co-op does not advertise offline-only survivor cycling")
 main.network.arena=null;main.queue_free();await frames();print("COMBAT_HANDLING_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
