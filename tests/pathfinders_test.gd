extends SceneTree
var failures:=0
var checks:=0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,words: String) -> void:
 checks+=1
 if not ok:failures+=1;print("FAIL: "+words)
 else:print("PASS: "+words)
func frames() -> void:
 await process_frame;await physics_frame;await process_frame
func freeze(roam: FreeRoamMatch) -> void:
 roam.set_physics_process(false);roam.pilot.set_physics_process(false);roam.frontier.set_physics_process(false);roam.mining.set_physics_process(false);roam.journey_log.set_physics_process(false);roam.pings.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://pathfinders-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 var p: PlayerProfile=main.profile
 check(not GameFeatures.campaign_enabled() and p.journey.goal.is_empty(),"Pathfinders keeps the campaign off and goals optional")
 var old:=p.to_dict();old.version=10;old.erase("journey");FileAccess.open(p.save_path,FileAccess.WRITE).store_string(JSON.stringify(old))
 var migrated:=PlayerProfile.new(p.save_path);migrated.load_profile()
 check(migrated.journey==JourneyState.defaults() and migrated.inventory==p.inventory and migrated.frontier==p.frontier,"Schema 10 migrates into the new journal without erasing progression")
 var bad:=JourneyState.sanitize({"goal":"fake","claimed":["captain","captain","unknown"],"waypoint":{"at":[1,NAN,2]},"mining":{"opened":[0,0,20],"generation":-3},"resume":{"region":999,"job":{"active":{"kind":"fake"}}}})
 check(bad.goal.is_empty() and bad.claimed==["captain"] and bad.waypoint.is_empty() and bad.mining.opened==[0] and bad.resume.region==6 and bad.resume.job.is_empty(),"Malformed markers, claims and checkpoints are bounded safely")
 p.save_profile();p.save_blocked=true;var before:=p.to_dict()
 check(not p.record_discovery("open.region.1","Kharon Belt") and p.to_dict()==before,"A failed discovery save cannot report success or mint salvage")
 check(not JourneyState.bookmark(p,Vector3(1,2,3),"Test") and p.to_dict()==before,"Failed personal beacon saves roll back atomically")
 p.save_blocked=false
 check(p.record_discovery("open.region.1","Kharon Belt") and p.record_discovery("open.region.2","Auralith Drift"),"Real exploration records feed the optional journal")
 p.record_discovery("open.region.0","Vesper Reach")
 var balance:=p.salvage;p.save_blocked=true
 check(not JourneyState.claim(p,"pathfinder") and p.salvage==balance and p.journey.claimed.is_empty(),"Failed badge payout preserves an unclaimed reward")
 p.save_blocked=false
 check(JourneyState.claim(p,"pathfinder") and p.salvage==balance+35,"Three visited regions award the one-time Pathfinder badge")
 check(not JourneyState.claim(p,"pathfinder") and p.salvage==balance+35,"Claiming the same badge again cannot duplicate salvage")
 check(JourneyState.pin(p,"collector") and p.journey.goal=="collector" and JourneyState.pin(p,""),"Players can pin or completely unpin personal goals")
 main.start_free_roam(true);await frames()
 var roam: FreeRoamMatch=main.battle;freeze(roam)
 var ship:=roam.pilot.ship
 for other in roam.ships:
  if other!=ship:other.position=Vector3(30000,30000,30000)
 var entries:=AtlasData.entries(roam)
 check(entries.filter(func(entry):return entry.kind=="station").size()==7 and entries.filter(func(entry):return entry.kind=="landmark").size()==7,"Atlas uses the actual seven stations and named landmarks")
 check(entries.filter(func(entry):return entry.kind=="mineral").size()>0 and entries.filter(func(entry):return entry.kind=="mineral").size()<12,"Atlas reveals nearby veins while distant resources remain undiscovered")
 check(roam.navigation.set_route(entries[3]) and p.journey.waypoint.id==entries[3].id,"Setting a course saves an actual world destination")
 roam.navigation.clock=0;roam.navigation._process(.2)
 check(roam.navigation.marker.visible and roam.navigation.hint.text.contains("COURSE"),"A saved course creates a world beacon and readable flight guidance")
 var chart:=GalaxyChart.new();chart.battle=roam;root.add_child(chart)
 var click:=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_RIGHT;click.position=Vector2(200,100);chart._gui_input(click)
 check(p.journey.waypoint.id=="chart-pin" and JourneyState.coordinates(p.journey.waypoint.at).size()==3,"Right-clicking the star chart sets a real navigable waypoint")
 chart.queue_free()
 for i in range(12):check(JourneyState.bookmark(p,Vector3(i*10,50,-30),"Survey %d"%i),"Personal beacon %d saves"%(i+1))
 check(not JourneyState.bookmark(p,Vector3.ZERO,"Overflow") and p.journey.bookmarks.size()==12,"Personal beacon storage enforces its twelve-marker limit")
 var id: String=p.journey.bookmarks[11].id
 check(JourneyState.remove_bookmark(p,id) and p.journey.bookmarks.size()==11 and p.journey.waypoint.is_empty(),"Deleting the selected beacon also clears its saved course")
 main.show_frontier();await frames()
 var board: FrontierScreen=main.story_layer.get_child(0);board.tab=5;board.refresh();await frames()
 check(board.find_child("AtlasSearch",true,false)!=null and board.find_child("AtlasFilter",true,false)!=null,"Field atlas search and category controls are connected in the real menu")
 var page:=board.body.get_child(0) as AtlasPage;page.category="mineral";page.search="Ferric";page.refresh()
 check(page.list.get_child_count()>=3 and page.list.get_child(0).text.contains("Ferric"),"Atlas filtering finds real resource entries")
 board.tab=6;board.refresh();await frames()
 check(board.body.get_child(0) is JourneyPage,"The real Journey tab exposes optional goals and saved checkpoints")
 main.close_story();await frames()
 var vein:=roam.mining.veins[0];vein.position=Vector3(0,7000,0);ship.position=Vector3(0,7000,40)
 vein.health=30
 var shot:=SpaceProjectile.new();shot.spec=WeaponSpec.new();shot.spec.damage=40;shot.team=ship.team;shot.shooter=ship;shot.direction=Vector3.FORWARD;roam.add_child(shot);shot.position=vein.position+Vector3(0,0,20);shot.set_physics_process(false);await frames();shot._physics_process(.06)
 check(vein.health==0 and vein.visible,"An actual laser projectile fractures a mineable asteroid")
 var ore:=int(p.sanctuary.materials.ore);p.save_blocked=true
 check(not roam.mining.collect(vein) and vein.visible and int(p.sanctuary.materials.ore)==ore and not 0 in p.journey.mining.opened,"Failed mining save retains the fractured vein and all materials")
 p.save_blocked=false
 var obstacle:=StaticBody3D.new();obstacle.collision_layer=2;obstacle.position=vein.position+Vector3(0,0,20);roam.add_child(obstacle)
 var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(12,12,4);collision.shape=box;obstacle.add_child(collision);await frames();roam.mining.tick(1.1,true)
 check(vein.visible and not 0 in p.journey.mining.opened,"A physical obstacle blocks the mining tractor interaction")
 obstacle.queue_free();await frames();roam.mining.tick(1.1,true)
 check(not vein.visible and int(p.sanctuary.materials.ore)==ore+4 and p.journey.mining.total==1,"One clear hold-F collection banks usable ore exactly once")
 check(not roam.mining.collect(vein) and int(p.sanctuary.materials.ore)==ore+4,"An already recovered vein cannot pay again")
 for i in range(1,8):
  var next:=roam.mining.veins[i];ship.position=next.position+Vector3(0,0,40);next.strike(100,ship);roam.mining.collect(next)
 check(p.journey.mining.total==8 and p.sanctuary.materials.crystal>=6,"Mining different seams yields ore, crystal and alloy")
 check(FrontierState.build(p,"workshop") and FrontierState.craft(p,"engine_vector") and p.owns("engine_vector"),"Space-mined materials fabricate a real Vector Engine blueprint")
 var reloaded:=PlayerProfile.new(p.save_path);reloaded.load_profile()
 check(reloaded.journey.mining.total==8 and reloaded.journey.bookmarks.size()==11 and reloaded.owns("engine_vector"),"Mining, beacons and the crafted component survive reloading")
 check(JourneyState.claim(p,"prospector"),"Mining contributes to an independently claimable exploration goal")
 ship.position=FreeRoamWorld.CENTERS[4]+Vector3(0,0,150);ship.health.regen_delay=0
 check(roam.service_ship(ship,true) and p.journey.resume.region==4,"Servicing a safe station records the actual Continue dock")
 roam.frontier.start({"kind":"escort","id":"resume-escort","slot":2,"generation":p.frontier.generation,"region":4,"at":FreeRoamWorld.CENTERS[4]+Vector3(200,100,-200),"title":"Persistent courier","faction":"pelagian","reward":65})
 await frames();roam.frontier.elapsed=42;roam.frontier.escort=.4;roam.frontier.integrity=73
 check(roam.journey_log.save_checkpoint() and p.journey.resume.job.elapsed==42,"A checkpoint stores optional job timing and escort integrity")
 p.save_blocked=true;var prior: Dictionary=p.journey.resume.duplicate(true);roam.frontier.elapsed=43
 check(not roam.journey_log.save_checkpoint() and p.journey.resume==prior and roam.journey_log.message.contains("FAILED"),"Failed autosaves preserve the prior checkpoint and explain the failure")
 main.quit_game();await process_frame
 check(main.quit_dialog!=null and main.quit_dialog.dialog_text.contains("could not be saved"),"Quitting after a failed save offers a clear retry-or-discard decision")
 main.quit_dialog.canceled.emit();await process_frame;p.save_blocked=false
 main.return_to_menu();await frames()
 check(main.menu.find_child("ContinueFrontier",true,false)!=null,"The title screen exposes Continue once a checkpoint exists")
 main.continue_frontier();await frames();roam=main.battle;freeze(roam);ship=roam.pilot.ship
 check(ship.position.distance_to(FreeRoamWorld.CENTERS[4])<180 and roam.peaceful,"Continue restores the selected mode at the last serviced station")
 check(roam.frontier.active.get("id","")=="resume-escort" and roam.frontier.elapsed>=43 and roam.frontier.escort==.4 and roam.frontier.integrity==73,"Continue restores elapsed job time, escort progress and damage")
 var original: Vector3=roam.frontier.active.at
 check(roam.frontier.point.position.is_equal_approx(original+Vector3(0,0,120)) and roam.frontier.goal.position.is_equal_approx(original+Vector3(0,0,300)),"Deferred placement preserves the courier's original route after resume")
 var gen:=int(p.frontier.generation);FrontierState.pay(p,gen,2,"pelagian","Paid courier",65);balance=p.salvage;main.return_to_menu();await frames();main.continue_frontier();await frames();roam=main.battle;freeze(roam);ship=roam.pilot.ship
 check(roam.frontier.active.is_empty() and p.salvage==balance,"A completed board slot cannot be replayed from a stale checkpoint")
 ship.position=Vector3(0,8000,0);ship.rotation=Vector3.ZERO
 check(roam.pings.add_ping(1,ship,1) and roam.pings.records.size()==1,"A live ship creates a danger ping from its real aiming direction")
 check(not roam.pings.add_ping(1,ship,1) and roam.pings.records.size()==1,"Host cooldown rejects repeated ping spam")
 check(roam.pings.snapshot(1).is_empty() and roam.pings.snapshot(0).size()==1,"Ping snapshots reveal markers only to the allied team")
 for i in range(5):roam.pings._physics_process(2.1);roam.pings.add_ping(1,ship,0)
 check(roam.pings.records.size()==3,"A pilot can retain at most three live pings")
 roam.pings._physics_process(46);check(roam.pings.records.is_empty(),"Expired team markers are removed from the world")
 roam.network_role="client";check(not roam.pings.add_ping(1,ship,0),"Network clients cannot authoritatively create team markers")
 roam.pings.apply_snapshot([{"kind":99,"at":[0,0,0]},{"kind":0,"at":[1,NAN,3]}]);check(roam.pings.records.is_empty(),"Malformed received marker data is ignored safely")
 roam.network_role="offline";main.queue_free();await frames();print("PATHFINDERS_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
