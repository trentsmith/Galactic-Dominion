extends SceneTree
var checks:=0
var failures:=0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,words: String) -> void:
 checks+=1
 if not ok:failures+=1;print("FAIL: "+words)
 else:print("PASS: "+words)
func frames() -> void:
 await process_frame;await process_frame;await physics_frame;await process_frame
func freeze(roam: FreeRoamMatch) -> void:
 roam.set_physics_process(false);roam.pilot.set_physics_process(false);roam.frontier.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func run() -> void:
 check(not GameFeatures.campaign_enabled() and GameFeatures.wildlife_enabled() and GameFeatures.companions_enabled(),"Frontier disables guidance while keeping wildlife and orbiters")
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://frontier-test.json";root.add_child(main);await frames()
 main.profile._defaults();main.profile.save_profile()
 var p: PlayerProfile=main.profile
 var malformed:=FrontierState.sanitize({"role":"cheat","facilities":{"repair":999},"reputation":{"crimson":"bad"},"done":[0,0,-1,7]})
 check(malformed.role=="striker" and malformed.facilities.repair==3 and malformed.reputation.crimson==0 and malformed.done==[0],"Malformed saves are bounded without inventing hostile standing")
 var old:=p.to_dict();old.version=9;old.erase("frontier");FileAccess.open(p.save_path,FileAccess.WRITE).store_string(JSON.stringify(old))
 var migrated:=PlayerProfile.new(p.save_path);migrated.load_profile()
 check(migrated.frontier.completed==0 and migrated.ship_story==p.ship_story and migrated.inventory==p.inventory,"Version 9 saves migrate without erasing collection or story")
 p.save_profile()
 p.save_blocked=true
 var before:=p.to_dict()
 check(not FrontierState.pay(p,0,0,"frontier","test",45) and p.to_dict()==before,"Failed job save rolls every reward back")
 p.save_blocked=false
 check(FrontierState.pay(p,0,0,"frontier","test",45),"An optional job saves salvage, intel and standing")
 var paid:=p.salvage
 check(not FrontierState.pay(p,0,0,"frontier","test",45) and p.salvage==paid,"A repeated completion cannot grant a second reward")
 p.frontier.done.clear();p.frontier.completed=0;p.frontier.intel=0
 var a:=FrontierData.offers(p);var b:=FrontierData.offers(p)
 check(a==b and a[0].kind=="rescue" and a[0].region==0,"Offered jobs persist deterministically with an accessible first rescue")
 p.acquire("crew_nyx");p.equip(0,"crew","crew_nyx")
 main.show_frontier();await frames()
 check(main.story_layer.get_child(0) is FrontierScreen and main.find_child("StoryTracker",true,false)==null,"O opens optional Frontier board without a forced story tracker")
 main.close_story();main.start_free_roam(true);await frames()
 var roam: FreeRoamMatch=main.battle;freeze(roam)
 var director:=roam.frontier;var ship:=roam.pilot.ship
 check(director.accept(0),"A board offer starts a real world distress beacon")
 await frames()
 ship.position=director.point.position+Vector3(0,0,100);director.tick(4,true)
 check(not director.active.is_empty() and director.progress==0,"Holding F outside rescue range cannot complete a job")
 ship.position=director.point.position+Vector3(0,0,40);director.tick(1,false)
 check(director.progress==0,"Flying past a pod without interacting gives no reward")
 director.point.position=Vector3(0,5000,0);ship.position=Vector3(0,5000,40)
 await frames()
 p.save_blocked=true;director.tick(3.1,true)
 check(director.completed and not director.active.is_empty() and not 0 in p.frontier.done,"A completed rescue survives a save failure for retry")
 p.save_blocked=false;director.tick(.1,false)
 check(director.active.is_empty() and 0 in p.frontier.done,"Retry claims the completed job exactly once")
 var saved:=p.to_dict();var reloaded:=PlayerProfile.new(p.save_path);reloaded.load_profile()
 check(reloaded.frontier.done==p.frontier.done and reloaded.salvage==p.salvage,"Job progression survives reload")
 p.salvage=1000;p.sanctuary.materials.merge({"ore":20,"fiber":20,"bloom":20},true)
 check(FrontierState.build(p,"workshop") and FrontierState.craft(p,"shield_recovery") and p.owns("shield_recovery"),"A built workshop consumes materials to unlock a usable blueprint")
 var mats: Dictionary=p.sanctuary.materials.duplicate();check(not FrontierState.craft(p,"shield_recovery") and p.sanctuary.materials==mats,"Known blueprints cannot consume materials again")
 check(FrontierState.build(p,"observatory") and FrontierState.build(p,"repair"),"Salvage constructs working home facilities")
 var cache: ComponentSalvage
 for child in roam.get_children():
  if child is ComponentSalvage:cache=child
 check(cache.bearing_range()==1750,"Observatory extends real component bearing range")
 check(FrontierState.role(p,"scout") and p.configured_stats(0).companion_role=="scout" and cache.bearing_range()==2750,"Scout protocol affects equipped ship stats and exploration sensing")
 ship.health.hull-=5;ship.health.regen_delay=0;var hull:=ship.health.hull;director.timer=0;director.tick(.5,false)
 check(ship.health.hull>hull,"Repair dock restores hull outside combat")
 ship.stats.companion_role="engineer";ship.set_physics_process(true);ship.companion._physics_process(.5);ship.set_physics_process(false)
 check(ship.health.hull>hull+.5,"Engineer companion provides authoritative hull repair")
 ship.stats.companion_role="guardian";ship.set_physics_process(true)
 var missile:=SpaceProjectile.new();missile.spec=WeaponSpec.new();missile.spec.tracking=true;missile.team=2;roam.add_child(missile);missile.position=ship.position+Vector3(0,0,20);missile.set_physics_process(false)
 ship.companion.support_clock=0;ship.companion._physics_process(.1);ship.set_physics_process(false)
 check(missile.is_queued_for_deletion() and ship.companion.support_clock==8,"Guardian intercepts a real hostile missile with a cooldown")
 await frames()
 var group: Dictionary=roam.encounters[1];p.frontier.reputation.crimson=24;roam.peaceful=false;director.apply_reputation()
 check(group.ships[0].team==0,"Allied reputation changes actual faction patrol allegiance")
 director.record_destruction(group.ships[0],ship)
 check(p.frontier.reputation.crimson==20,"Destroying a faction vessel lowers its recorded standing")
 p.frontier.reputation.crimson=-20;ship.position=FreeRoamWorld.CENTERS[1];director.wanted_interception()
 check(director.intercepted.has(1) and group.ships[0].position.distance_to(ship.position)<1000,"Wanted standing dispatches an existing interception patrol")
 var captain: CombatShip=group.ships[0];var visual:=captain.get_child(0) as Node3D
 var original_scale:=visual.scale if visual!=null else Vector3.ONE
 director.start({"kind":"boss","id":"boss","slot":2,"generation":p.frontier.generation,"region":1,"at":Vector3(0,6000,0),"title":"Test siege","faction":"crimson","reward":65})
 var weak:=director.boss;var cooldown:=captain.weapons.primary.cooldown
 check(weak.remaining()==3 and captain.get_meta("boss_damage_scale")==.2,"Siege captain exposes three damageable anchors and armored hull")
 var anchor: BossHardpoint=weak.points[0]
 await frames()
 var shot:=SpaceProjectile.new();shot.spec=WeaponSpec.new();shot.spec.damage=50;shot.team=ship.team;shot.shooter=ship;shot.direction=Vector3.FORWARD;roam.add_child(shot);shot.position=anchor.global_position+Vector3(0,0,12);shot.set_physics_process(false);shot._physics_process(.04)
 check(anchor.health<=0,"An actual laser ray strikes and destroys an exposed anchor")
 for reactor in weak.points:reactor.hit(50,ship)
 await frames()
 check(weak.remaining()==0 and captain.get_meta("boss_damage_scale")==1.0 and captain.weapons.primary.cooldown<cooldown,"Breaking anchors removes armor and accelerates boss weapons")
 director.cancel();await frames()
 check(captain.weapons.primary.cooldown==cooldown and not captain.has_meta("frontier_enemy") and (visual==null or visual.scale==original_scale),"Leaving a boss job restores reusable NPC visuals and weapons")
 roam.peaceful=true;director.apply_reputation();ship.health.regen_delay=0
 for other in roam.ships:other.position=Vector3(40000,40000,40000)
 ship.position=Vector3(0,5000,0)
 director.start({"kind":"wreck","id":"wreck","slot":3,"generation":p.frontier.generation,"region":0,"at":ship.position+Vector3(0,0,-40),"title":"Test wreck","faction":"frontier","reward":75})
 await frames();check(director.can_board(),"An out-of-combat wreck accepts boarding")
 var orbit_id:=roam.get_instance_id();director.active.stage="boarding";main.board_derelict();await frames()
 var room: DerelictExpedition=main.surface as DerelictExpedition
 check(room!=null and room.doors.size()==2 and main.parked_roam==roam,"Boarding parks the exact orbital session and creates a walkable wreck")
 if room!=null:
  room.set_physics_process(false);room.bot.set_physics_process(false)
  room.bot.input_provider=func():return {"scan":true}
  for at in room.terminals:room.bot.position=at;room._physics_process(2.1)
  await frames()
  check(room.secured and room.terminal_index==3 and room.doors[0].get_child(0).disabled,"Sequential real console scans open doors and secure the black box")
  room.bot.position=Vector3(0,1,-18);room.elapsed=4.6;var shields:=room.bot.shield;room._physics_process(.1)
  check(room.bot.shield<shields,"Wreck security discharge damages the exploring bot")
  room.bot.position=Vector3(0,1,4);room.bot.input_provider=func():return {"extract":true}
  room._physics_process(.1);await frames()
  check(main.surface==null and main.battle.get_instance_id()==orbit_id and director.active.is_empty() and 3 in p.frontier.done,"Airlock extraction restores orbit and saves the black-box reward")
 main.start_planet(0,"crew_pixlet");await frames()
 var planet: PlanetExpedition=main.surface
 planet.set_physics_process(false);planet.bot.set_physics_process(false);planet.wilderness.set_process(false)
 for animal in planet.fauna:animal.set_physics_process(false)
 var animal:=planet.tracked_animal();planet.ecology.set_physics_process(false);planet.ecology.clock=0;planet.ecology._physics_process(2)
 check(planet.ecology.tracks.size()>0,"Tracking stamps actual wildlife positions into a bounded footprint trail")
 for i in range(25):animal.position.x+=4;planet.ecology.clock=0;planet.ecology._physics_process(2)
 check(planet.ecology.tracks.size()==16,"Wildlife trails stay bounded during long explorations")
 var binding:=InputEventKey.new();binding.keycode=KEY_P
 check(FlightPreferences.replace("missile",binding)==OK and InputMap.action_has_event("missile",binding),"Settings rebind real input actions and persist them")
 FlightPreferences.install();check(InputMap.action_has_event("missile",binding),"Custom bindings reload correctly")
 var stick:=InputEventJoypadMotion.new();stick.axis=JOY_AXIS_RIGHT_X;stick.axis_value=.9;Input.parse_input_event(stick);await frames()
 check(FlightPreferences.look().x>.5,"Scripted gamepad right-stick input reaches flight aiming")
 stick.axis_value=0;Input.parse_input_event(stick);FlightPreferences.reset()
 var light:=DirectionalLight3D.new();root.add_child(light);light.shadow_enabled=true;FlightPreferences.quality="low";FlightPreferences.apply_node(light)
 check(not light.shadow_enabled,"Low graphics quality disables actual shadow rendering")
 FlightPreferences.quality="high";FlightPreferences.apply_node(light);check(light.shadow_enabled,"Returning to high quality restores original shadows")
 light.queue_free();main.queue_free();await frames()
 print("FRONTIER_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
