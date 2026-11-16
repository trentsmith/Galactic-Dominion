extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;print("FAIL: "+message)
 else:print("PASS: "+message)
func frames() -> void:
 await process_frame;await physics_frame;await process_frame
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://frontier-job-paths-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 main.start_free_roam(true);await frames()
 var roam: FreeRoamMatch=main.battle;roam.set_physics_process(false);roam.pilot.set_physics_process(false);roam.frontier.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false);ship.position=Vector3(40000,40000,40000)
  if ship.companion!=null:ship.companion.set_physics_process(false)
 var p: PlayerProfile=main.profile;var director:=roam.frontier;var pilot:=roam.pilot.ship
 check(not director.accept(4) and director.message.contains("decode"),"Rumor explains the intel requirement without starting")
 var salvage:=p.salvage
 check(director.accept(1),"Repair job starts without campaign progress")
 director.elapsed=359.9;director.tick(.2,false)
 check(director.active.is_empty() and p.salvage==salvage,"Expired distress signals grant no salvage")
 check(director.accept(1) and director.cancel() and p.salvage==salvage,"An abandoned board slot stays replayable without a reward")
 director.start({"kind":"repair","id":"repair","slot":1,"generation":p.frontier.generation,"region":0,"at":Vector3(0,7000,0),"title":"Repair test","faction":"frontier","reward":55})
 await frames();pilot.position=director.point.position+Vector3(0,0,40)
 var obstacle:=StaticBody3D.new();obstacle.collision_layer=2;roam.add_child(obstacle);obstacle.position=director.point.position+Vector3(0,0,20)
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(10,10,5);shape.shape=box;obstacle.add_child(shape);await frames()
 director.tick(4.1,true)
 check(not director.active.is_empty() and director.progress==0,"A solid object blocks repair interaction through geometry")
 obstacle.queue_free();await frames();director.tick(4.1,true)
 check(director.active.is_empty() and p.salvage==salvage+55,"A clear four-second repair pays its exact reward")
 var at:=Vector3(0,8000,0)
 director.start({"kind":"escort","id":"escort","slot":2,"generation":p.frontier.generation,"region":0,"at":at,"title":"Escort test","faction":"frontier","reward":65});await frames()
 pilot.position=at+Vector3(0,0,1000);director.tick(2,false)
 check(director.escort==0,"An unattended courier does not progress")
 var jammer:=roam.ships[6];jammer.team=2;jammer.position=director.point.position+Vector3(50,0,0);pilot.position=director.point.position+Vector3(0,0,40);director.tick(10,false)
 check(director.escort==0 and director.integrity<100,"A real nearby hostile jams and damages the courier")
 jammer.position=Vector3(40000,40000,40000);director.tick(15,false)
 check(director.escort==.5 and director.point.position.distance_to(at)>140,"A nearby escort advances the actual courier toward its destination")
 pilot.position=director.point.position+Vector3(0,0,40);director.tick(15,false)
 check(director.active.is_empty() and 2 in p.frontier.done,"A completed escort saves the board slot")
 check(director.accept(4),"Recovered intel unlocks a component rumor")
 await frames()
 var recovery: ComponentSalvage
 for child in roam.get_children():
  if child is ComponentSalvage:recovery=child;recovery.set_physics_process(false)
 var index:=int(director.active.cache)
 check(director.point.position==recovery.caches[index].global_position,"Rumor points at the actual existing component cache")
 var result:=recovery.recover(index);director.tick(.1,false)
 check(result.ok and director.active.is_empty() and 4 in p.frontier.done,"Original cache recovery completes the rumor and saves its ordinary discovery")
 var story:=p.ship_story.duplicate(true);p.frontier.done=[0,1,2,4];p.frontier.generation=0
 check(FrontierState.pay(p,0,3,"frontier","Fifth test",75) and p.frontier.generation==1 and p.frontier.done.is_empty(),"Five distinct saved slots generate a fresh repeatable board")
 check(not FrontierState.pay(p,0,3,"frontier","Old test",75),"A previous batch receipt cannot be replayed into the next board")
 var loaded:=PlayerProfile.new(p.save_path);loaded.load_profile()
 check(loaded.frontier.generation==1 and loaded.ship_story==story,"New board generation preserves the archived narrative")
 var normal_range:=recovery.bearing_range();p.ship_story.ending="preserve"
 check(recovery.bearing_range()==normal_range+500,"A preserved campaign ending changes exploration sensing without changing rarity")
 p.ship_story.ending="seal";pilot.position=Vector3(240,60,-160);pilot.health.hull-=10;pilot.health.regen_delay=0;director.timer=0;var before:=pilot.health.hull;director.tick(.5,false)
 check(is_equal_approx(pilot.health.hull,before+.3),"A sealed ending adds a real local reconstruction repair aura")
 pilot.position=Vector3(5000,5000,0);director.timer=0;before=pilot.health.hull;director.tick(.5,false)
 check(pilot.health.hull==before,"Reconstruction aura does not repair a fleet outside its radius")
 var objects:=roam.ships.size();director.accept(0);director.cancel()
 check(roam.ships.size()==objects,"Distress jobs reuse world actors without growing the combat ship pool")
 main.queue_free();await frames();print("FRONTIER_JOBS_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
