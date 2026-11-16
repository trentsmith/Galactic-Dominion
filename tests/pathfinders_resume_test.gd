extends SceneTree
var checks:=0
var failures:=0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,words: String) -> void:
 checks+=1
 if ok:print("PASS: "+words)
 else:failures+=1;print("FAIL: "+words)
func frames() -> void:
 await process_frame;await physics_frame;await process_frame;await physics_frame;await process_frame
func freeze(roam: FreeRoamMatch) -> void:
 roam.set_physics_process(false);roam.frontier.set_physics_process(false);roam.pilot.set_physics_process(false);roam.journey_log.set_physics_process(false);roam.mining.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://resume-details-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 main.start_free_roam(true);await frames();var roam: FreeRoamMatch=main.battle;freeze(roam);var p: PlayerProfile=main.profile
 roam.frontier.start({"kind":"boss","id":"saved-captain","slot":2,"generation":0,"region":1,"at":Vector3(0,6000,0),"title":"Saved siege captain","faction":"crimson","reward":65})
 await frames();var captain:=roam.frontier.enemy
 roam.frontier.boss.points[0].hit(40,roam.pilot.ship);roam.frontier.boss.points[1].hit(20,roam.pilot.ship)
 captain.health.hull=captain.health.max_hull*.6;captain.health.shield=captain.health.max_shield*.4;roam.frontier.elapsed=27
 check(roam.journey_log.save_checkpoint(),"A damaged siege captain can be checkpointed")
 main.return_to_menu();await frames();main.continue_frontier();await frames();roam=main.battle;freeze(roam);captain=roam.frontier.enemy
 check(roam.frontier.active.get("id","")=="saved-captain" and roam.frontier.boss.remaining()==2,"Continue restores a siege captain with its destroyed anchor")
 check(roam.frontier.boss.points[1].health==20 and float(captain.get_meta("boss_damage_scale"))==.2,"Partially damaged anchors and remaining hull mitigation survive reload")
 check(absf(captain.health.hull/captain.health.max_hull-.6)<.01 and absf(captain.health.shield/captain.health.max_shield-.4)<.02,"Boss hull and shield damage are retained, allowing normal regen")
 roam.frontier.cancel();p.frontier.intel=1
 check(roam.frontier.accept(4),"A decoded component rumor starts after canceling the siege sortie")
 var salvage: ComponentSalvage
 for child in roam.get_children():
  if child is ComponentSalvage:salvage=child;salvage.set_physics_process(false)
 var index:=8;roam.frontier.active.cache=index;roam.frontier.active.cache_generation=salvage.generation;roam.frontier.active.at=salvage.caches[index].position;roam.frontier.point.position=salvage.caches[index].position
 var reward:=ComponentDiscovery.reward(p,"space",index)
 check(roam.journey_log.save_checkpoint(),"A non-default cache rumor has a persistent checkpoint")
 main.return_to_menu();await frames();main.continue_frontier();await frames();roam=main.battle;freeze(roam)
 for child in roam.get_children():
  if child is ComponentSalvage:salvage=child;salvage.set_physics_process(false)
 check(roam.frontier.active.get("cache",-1)==8 and roam.frontier.point.position.is_equal_approx(salvage.caches[8].position),"Rumor resume tracks its exact original cache after collision placement")
 check(ComponentDiscovery.reward(p,"space",8)==reward,"Resuming a rumor preserves its original seeded rarity/item roll")
 var before:=int(p.component_discovery.total);var result:=salvage.recover(8);roam.frontier.tick(.1,false)
 check(result.ok and int(p.component_discovery.total)==before+1 and roam.frontier.active.is_empty() and 4 in p.frontier.done,"Recovering the original cache completes its resumed rumor once")
 p.journey.mining.opened=[1,2,3,4,5,6,7,8,9,10,11]
 var vein:=roam.mining.veins[0];roam.pilot.ship.position=vein.position+Vector3(0,0,40);vein.strike(100,roam.pilot.ship)
 check(roam.mining.collect(vein) and int(p.journey.mining.generation)==1 and p.journey.mining.opened.is_empty(),"Recovering the twelfth deposit starts a new persistent mineral batch")
 check(not roam.mining.collect(vein),"An old-generation deposit cannot pay into the next batch")
 roam.mining._physics_process(.01);await frames()
 check(roam.mining.veins.size()==12 and roam.mining.veins[0].generation==1,"The mineral field rebuilds exactly twelve new deposit actors")
 main.start_planet(0,"crew_pixlet");await frames();main.surface.set_physics_process(false);main.surface.bot.set_physics_process(false)
 main.surface.pending["unextracted-test"]="Unextracted survey"
 main.quit_game();await process_frame
 check(main.quit_dialog!=null and main.quit_dialog.dialog_text.contains("surveys") and not p.exploration_records.has("unextracted-test"),"Quit warnings preserve the distinction between surveys and delivered discoveries")
 main.quit_dialog.canceled.emit();await process_frame
 check(main.surface.pending.has("unextracted-test") and not paused,"Canceling quit returns to the same live expedition with its pending work")
 main.queue_free();await frames();print("PATHFINDERS_RESUME_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
