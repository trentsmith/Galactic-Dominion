extends SceneTree
var checks:=0
var failures:=0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func freeze(e: PlanetExpedition) -> void:
 e.set_physics_process(false);e.bot.set_physics_process(false);e.party.set_physics_process(false)
 for animal in e.fauna:animal.set_physics_process(false);animal.position=Vector3(1000,30,1000)
func run() -> void:
 var path:="user://story-test-%d.json"%Time.get_ticks_usec()
 main=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main);await process_frame
 check(main.menu.find_child("StoryButton",true,false)!=null,"The command deck offers a clear story entry")
 check(StoryCampaign.stage(main.profile)==0 and main.profile.sanctuary.residents.size()==1,"The starter resident does not skip the rescue story")
 main.menu.find_child("StoryButton",true,false).pressed.emit();await process_frame
 check(paused and main.story_layer.get_child(0) is StoryScreen,"Story opens a paused, interactive NPC journal")
 var screen: StoryScreen=main.story_layer.get_child(0)
 check(screen.portrait_world.find_children("","StoryNPC",true,false).size()==1,"Comms display an actual 3D NPC portrait")
 var speech_before:=screen.speech.text;screen.say("lore")
 check(screen.speech.text!=speech_before and screen.speech.text.contains("Nexus"),"Dialogue topics reveal original Nexus Archives lore")
 var pods: int=main.profile.sanctuary.materials.capture_pod
 main.profile.save_blocked=true
 check(not StoryCampaign.accept(main.profile) and not main.profile.story.accepted and main.profile.sanctuary.materials.capture_pod==pods,"Failed mission acceptance grants neither flags nor free supplies")
 main.profile.save_blocked=false;main.story_action()
 check(StoryCampaign.stage(main.profile)==1 and main.profile.sanctuary.materials.capture_pod==pods+2,"Accepting Astra's mission grants supplies once and points to Varkhoss")
 check(not StoryCampaign.accept(main.profile) and main.profile.sanctuary.materials.capture_pod==pods+2,"Repeated acceptance cannot farm pods")
 main.story_action();await process_frame
 check(main.battle is FreeRoamMatch and main.surface==null,"Story begins in roaming space rather than silently teleporting to a planet")
 var roam: FreeRoamMatch=main.battle
 var tracker: StoryTracker=main.find_children("","StoryTracker",true,false)[0]
 check(tracker.waypoint().text.contains("VARKHOSS"),"Roaming story exposes a named landing waypoint")
 main.show_story();main.story_action()
 check(main.battle==roam,"Reopening the objective resumes the same roaming fleet")
 main.battle.pilot.ship.position=main.battle.army.worlds[0].position+Vector3(0,0,100)
 main.battle.army.worlds[0].owner=2
 check(main.battle.can_land(0),"Astra's exploration clearance avoids a conquest softlock")
 check(main.land_from_roam(0),"Following the landing waypoint allows actual story ship landing")
 await process_frame
 var e: PlanetExpedition=main.surface;freeze(e)
 check(not paused and StoryCampaign.stage(main.profile)==2 and e.definition.id=="varkhoss","Actual deployment records the planet visit and advances the goal")
 check(e.find_children("","StoryNPC",true,false).size()==1,"Milo has a field hologram near the landing ship")
 var prey: SurfaceFauna=e.fauna[10]
 prey.position=Vector3(100,30,100);e.bot.position=prey.position+Vector3(0,0,5)
 e.select_hunt(prey.definition.id);e.scan_nearest(2.1)
 if prey.definition.damage>0:prey.hit(10000,true)
 check(e.capture_nearest() and StoryCampaign.stage(main.profile)==2,"Capture alone does not count as sanctuary delivery")
 main.show_story();await process_frame
 check(not main.story_can_travel() and is_instance_valid(main.surface),"Journal travel refuses to silently discard unbanked survey work")
 main.close_story();e.bot.position=Vector3(0,1.5,5)
 main.profile.save_blocked=true
 check(not e.extract() and not main.profile.story.rescued,"Failed delivery cannot advance the rescue objective")
 main.profile.save_blocked=false
 check(e.extract() and StoryCampaign.stage(main.profile)==3,"A real successful creature delivery advances Sera's debrief")
 check(StoryCampaign.debrief(main.profile) and main.profile.story.kit and StoryCampaign.stage(main.profile)==4,"Sera reserves mission parts after the rescue")
 check(not StoryCampaign.debrief(main.profile),"Sera's kit cannot be claimed twice")
 var materials: Dictionary=main.profile.sanctuary.materials.duplicate(true)
 main.profile.save_blocked=true
 check(not StoryCampaign.craft(main.profile,"engine_sprint") and main.profile.story.kit and not main.profile.owns("engine_sprint"),"Failed crafting preserves the kit and does not grant an engine")
 main.profile.save_blocked=false
 check(StoryCampaign.craft(main.profile,"engine_sprint") and main.profile.owns("engine_sprint") and not main.profile.story.kit,"Milo crafts a real permanent Sprint Drive blueprint")
 check(main.profile.sanctuary.materials==materials,"Reserved mission parts avoid consuming unrelated sanctuary supplies")
 check(StoryCampaign.stage(main.profile)==4,"Owning the component is not enough; it must be fitted")
 check(StoryCampaign.fit_engine(main.profile) and StoryCampaign.stage(main.profile)==5,"Actual lead-ship fitting unlocks the patrol encounter")
 check(main.profile.configured_stats(0).speed>CollectionCatalog.SHIP_TYPES[main.profile.ship_classes[0]].speed,"The crafted drive changes actual ship performance")
 var owned: int=main.profile.inventory.engine_sprint.count
 check(not StoryCampaign.craft(main.profile,"engine_sprint") and main.profile.inventory.engine_sprint.count==owned,"Known component blueprints cannot be crafted for duplicate farming")
 main.start_battle(3)
 var unrelated: BattleMatch=main.battle
 unrelated.set_physics_process(false);unrelated.pilot.set_physics_process(false)
 for vessel in unrelated.ships:vessel.set_physics_process(false)
 unrelated.finish(0,"Fleet eliminated")
 check(StoryCampaign.stage(main.profile)==5,"An unrelated arena victory cannot complete the story patrol")
 main.difficulty="relaxed"
 check(main.start_story_encounter(),"The unlocked story launches a dedicated encounter")
 var battle: BattleMatch=main.battle
 battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 check(battle.story_mission=="crimson_interdiction" and battle.difficulty=="standard" and battle.ships[3].callsign.contains("Crimson"),"The patrol has its own identity and explicitly uses at least Standard resistance")
 battle.finish(1,"Fleet eliminated")
 check(StoryCampaign.stage(main.profile)==5,"Defeat preserves the objective for retry")
 check(main.start_story_encounter(),"A defeated patrol mission can be retried")
 battle=main.battle;battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 for ship in battle.ships:
  if ship.team==1:ship.health.damage(100000,battle.ships[0])
 check(battle.finished and battle.winner==0 and StoryCampaign.stage(main.profile)==6,"Actual enemy fleet elimination advances the story victory flag")
 var salvage: int=main.profile.salvage
 main.profile.save_blocked=true
 check(not StoryCampaign.complete(main.profile) and not main.profile.story.complete and main.profile.salvage==salvage,"Failed final debrief rolls back its reward and completion")
 main.profile.save_blocked=false
 check(StoryCampaign.complete(main.profile) and main.profile.salvage==salvage+75,"Astra archives the signal and grants the one-time chapter reward")
 check(not StoryCampaign.complete(main.profile) and main.profile.salvage==salvage+75,"Repeated final dialogue cannot duplicate the reward")
 main.profile.loadouts[0].engine="engine_standard"
 check(StoryCampaign.stage(main.profile)==7,"Changing fittings after completion does not reopen old objectives")
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(restored.story.complete and restored.exploration_records.has("story.lantern_signal"),"Chapter completion and its lore discovery survive reload")
 var before: int=main.profile.sanctuary.materials.ore
 main.profile.sanctuary.materials.ore=0
 check(not StoryCampaign.craft(main.profile,"shield_recovery") and main.profile.story_message.contains("NEED MATERIALS"),"Workshop recipes explain insufficient materials")
 main.profile.sanctuary.materials.ore=before
 main.profile.sanctuary.materials.ore=10;main.profile.sanctuary.materials.bloom=10;main.profile.sanctuary.materials.fiber=10
 check(StoryCampaign.craft(main.profile,"shield_recovery") and main.profile.owns("shield_recovery") and main.profile.sanctuary.materials.ore==5 and main.profile.sanctuary.materials.bloom==7,"Non-story workshop recipes consume their actual materials")
 var sanctuary_reference: Dictionary=main.profile.sanctuary
 main.profile.save_blocked=true
 check(not StoryCampaign.craft(main.profile,"utility_reserve") and sanctuary_reference.materials.ore==5 and not main.profile.owns("utility_reserve"),"Failed regular crafting preserves live sanctuary references and ownership")
 main.profile.save_blocked=false
 var legacy: Dictionary=main.profile.to_dict();legacy.version=5;legacy.erase("story")
 var file:=FileAccess.open(path+"-legacy",FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
 var migrated:=PlayerProfile.new(path+"-legacy");migrated.load_profile()
 check(not migrated.save_blocked and StoryCampaign.stage(migrated)==0 and migrated.owns("engine_sprint"),"Schema 5 migration preserves inventory and starts the optional new story")
 main.return_to_menu();await process_frame
 main.show_story();await process_frame
 var close:=InputEventAction.new();close.action="pause";close.pressed=true;main._unhandled_input(close)
 check(not paused and not is_instance_valid(main.story_layer),"Escape closes comms and restores the prior pause state")
 var open_event:=InputEventKey.new();open_event.physical_keycode=KEY_O;open_event.keycode=KEY_O;open_event.pressed=true
 main._unhandled_input(open_event)
 check(is_instance_valid(main.story_layer),"The real O input binding opens the journal")
 main._unhandled_input(open_event)
 check(not is_instance_valid(main.story_layer) and not paused,"O toggles the journal without leaving the game paused")
 main.start_battle();main.battle.network_role="client"
 main.battle.set_physics_process(false);main.battle.pilot.set_physics_process(false)
 for ship in main.battle.ships:ship.set_physics_process(false)
 main.show_story();await process_frame
 check(not paused and main.story_layer.get_child(0).readonly and main.story_layer.find_child("StoryObjectiveButton",true,false)==null,"Online comms do not pause simulation or expose local progression actions")
 main.close_story()
 main.queue_free();await process_frame
 print("STORY_CAMPAIGN_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
