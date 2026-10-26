extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 print(("PASS: " if value else "FAIL: ")+message)
 if not value:failures+=1
func run() -> void:
 var host=load("res://scenes/main.tscn").instantiate();host.profile_path="user://armada-%d.json"%Time.get_ticks_usec();root.add_child(host);await process_frame
 check(host.menu.find_child("ArmadaButton",true,false)!=null,"Experimental Armada has a command-deck entry")
 host.start_armada(81337);await process_frame
 var battle: BattleMatch=host.battle
 check(battle.ships.size()==400 and battle.living(0)==200 and battle.living(1)==200,"200 real ships spawn on each side")
 check(battle.elimination_only and battle.zone.start_radius==5200 and battle.camera.far==16000,"Armada has a larger navigable arena and elimination rules")
 check(battle.ships[150].lightweight and not battle.ships[0].lightweight,"Reinforcements use bounded hull geometry")
 var started:=Time.get_ticks_msec()
 var steps:=2400
 for i in range(steps):await physics_frame
 var seconds:=float(Time.get_ticks_msec()-started)/1000
 var damage:=0.0
 for ship in battle.ships:damage+=ship.damage_dealt
 print("ARMADA_BENCHMARK: %d frames / %.2f wall seconds / %.1f simulation fps / damage %.1f / survivors %d:%d"%[steps,seconds,steps/maxf(seconds,.001),damage,battle.living(0),battle.living(1)])
 check(damage>0,"Live fleets maneuver into combat and deal confirmed damage")
 # Freeze a still-running match for deterministic weapon and takeover checks.
 battle.finished=false;battle.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 battle.pilot.set_physics_process(false)
 var player: CombatShip=battle.ships[0]
 player.alive=true;player.health.dead=false;player.health.configure(player.stats)
 player.position=Vector3(0,2100,0);player.rotation=Vector3.ZERO
 var enemy: CombatShip=battle.ships[200]
 enemy.alive=true;enemy.health.dead=false;enemy.health.max_hull=1000;enemy.health.hull=1000;enemy.health.max_shield=0;enemy.health.shield=0;enemy.position=Vector3(0,2100,-120)
 var ally: CombatShip=battle.ships[1];ally.alive=true;ally.position=Vector3(0,2100,-70)
 var ally_before:=ally.health.hull
 battle.mega.loadouts.clear();battle.mega.grant(player,0)
 var before:=enemy.health.hull
 check(battle.mega.fire(player) and enemy.health.hull==before-130 and ally.health.hull==ally_before,"Solar Lance confirms damage and protects allies")
 check(not battle.mega.fire(player),"Mega weapon recharge prevents repeated fire")
 battle.mega.elapsed+=12;battle.mega.fire(player);battle.mega.elapsed+=12;battle.mega.fire(player)
 check(not battle.mega.loadouts.has(player.get_instance_id()) and not battle.mega.fire(player),"Three charges expire without changing permanent inventory")
 enemy.position.x=100;battle.mega.grant(player,0);before=enemy.health.hull
 check(battle.mega.fire(player) and enemy.health.hull==before,"Lance requires actual alignment rather than damaging a selected target anywhere")
 enemy.position.x=0
 var wall:=StaticBody3D.new();wall.collision_layer=2;wall.position=Vector3(0,2100,-60)
 var shape:=BoxShape3D.new();shape.size=Vector3(50,50,10)
 var collision:=CollisionShape3D.new();collision.shape=shape;wall.add_child(collision);battle.add_child(wall)
 await physics_frame;await physics_frame
 battle.mega.grant(player,0);before=enemy.health.hull
 check(battle.mega.fire(player) and enemy.health.hull==before,"Solid obstacles block mega-weapon damage")
 wall.queue_free();await physics_frame;await physics_frame
 player.health.max_hull=1000;player.health.hull=1000;player.health.shield=0;player.health.protection=1
 enemy.rotation=Vector3(0,PI,0);enemy.targeting.select(player);battle.mega.grant(enemy,0);before=player.health.hull
 battle.mega.tick(.1)
 check(player.health.hull==before-130,"An AI ship uses its acquired mega weapon against a real target")
 battle.mega.grant(player,1);before=enemy.health.hull
 check(battle.mega.fire(player) and enemy.health.hull==before-80 and enemy.movement.slow_remaining>0,"Gravity Nova damages and slows nearby enemies")
 battle.mega.loadouts.clear();player.position=battle.mega.pickups[0].actor.position
 battle.mega.pickups[0].ready=0;battle.spatial.rebuild(battle.ships);battle.mega.pickup_clock=0;battle.mega.tick(.1)
 check(battle.mega.loadouts.has(player.get_instance_id()) and not battle.mega.pickups[0].actor.visible,"A real proximity pickup grants charges and enters respawn cooldown")
 battle.ships[20].alive=true
 check(battle.fleet.switch_to(20) and not battle.ships[20].lightweight and battle.pilot.ship==battle.ships[20],"Taking over a reinforcement promotes its full ship model")
 check(battle.fleet.cycle_control(1) and battle.pilot.ship.fleet_slot==21 and battle.ships[20].lightweight,"Bracket navigation reaches ships beyond the first ten")
 battle.fleet.switch_to(0)
 for ship in battle.ships:
  if ship.team==1 and ship.alive:ship.health.damage(100000,player,"test")
 check(battle.finished and battle.winner==0,"Last fleet standing ends Armada with the correct winner")
 host.queue_free();await process_frame;await process_frame
 var online:=BattleMatch.new();online.network_role="server";online.team_size=200;root.add_child(online);await process_frame
 check(online.team_size==3 and online.ships.size()==6 and online.mega==null,"Online sessions retain the existing six-slot protocol")
 online.queue_free();await process_frame
 print("ARMADA_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
