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
 await process_frame;await physics_frame;await process_frame
func freeze(roam: FreeRoamMatch) -> void:
 roam.set_physics_process(false);roam.pilot.set_physics_process(false);roam.frontier.set_physics_process(false);roam.mining.set_physics_process(false);roam.journey_log.set_physics_process(false);roam.pings.set_physics_process(false)
 for child in roam.get_children():
  if child is ComponentSalvage:child.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func has_key(action: String,key: Key) -> bool:
 for event in InputMap.action_get_events(action):
  if event is InputEventKey and (event.keycode==key or event.physical_keycode==key):return true
 return false
func has_mouse(action: String,button: MouseButton) -> bool:
 for event in InputMap.action_get_events(action):
  if event is InputEventMouseButton and event.button_index==button:return true
 return false
func has_pad(action: String,button: JoyButton) -> bool:
 for event in InputMap.action_get_events(action):
  if event is InputEventJoypadButton and event.button_index==button:return true
 return false
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://polish-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 var p: PlayerProfile=main.profile
 main.start_free_roam(true);await frames();var roam: FreeRoamMatch=main.battle;freeze(roam)
 roam.frontier.start({"kind":"repair","id":"preserve-this","slot":1,"generation":0,"region":0,"title":"Keep this expedition","faction":"frontier","at":Vector3(0,6000,0),"reward":55})
 await frames();p.save_blocked=true
 main.start_battle();await process_frame
 check(main.battle==roam and main.quit_dialog!=null and roam.frontier.active.id=="preserve-this","A failed checkpoint cannot silently discard a flight when starting a battle")
 main.quit_dialog.canceled.emit();await frames()
 check(main.battle==roam and not paused and main.quit_dialog==null,"Canceling a failed transition preserves the exact flight and pause state")
 check(not main.start_free_roam(false) and main.battle==roam and main.quit_dialog!=null,"Restarting free roam also honors the save failure guard")
 main.quit_dialog.confirmed.emit();await frames()
 check(main.battle!=roam and main.battle is FreeRoamMatch and not main.battle.peaceful and main.quit_dialog==null,"Explicit discard performs the requested transition exactly once")
 p.save_blocked=false;roam=main.battle;freeze(roam)
 check(roam.journey_log.save_checkpoint(true),"A manual checkpoint writes normally")
 p.journey.resume.saved_at=123;p.save_profile()
 check(roam.journey_log.save_checkpoint() and p.journey.resume.saved_at==123,"An unchanged automatic checkpoint skips rewriting the save")
 p.save_error="A previous write failed"
 check(roam.journey_log.save_checkpoint() and p.journey.resume.saved_at>123 and p.save_error.is_empty(),"A prior save error triggers a real retry even when the flight is unchanged")
 var original_path:=FlightPreferences.save_path;FlightPreferences.save_path="user://polish-controls-%d.cfg"%Time.get_ticks_usec();FlightPreferences.install()
 var key:=InputEventKey.new();key.keycode=KEY_Y
 var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT
 var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_X;pad.device=7
 check(FlightPreferences.replace("missile",key)==OK and FlightPreferences.replace("missile",mouse)==OK and FlightPreferences.replace("missile",pad)==OK,"Keyboard, mouse and gamepad overrides can be saved for one action")
 FlightPreferences.install()
 check(has_key("missile",KEY_Y) and has_mouse("missile",MOUSE_BUTTON_RIGHT) and has_pad("missile",JOY_BUTTON_X),"All three device bindings survive a settings reload")
 check(FlightPreferences.label_for("missile")=="Y","HUD binding labels follow the actual remapped keyboard action")
 var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_X;event.device=2;event.pressed=true;Input.parse_input_event(event);await frames()
 check(Input.is_action_pressed("missile"),"A saved gamepad binding works after the controller device number changes")
 event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
 var legacy:=ConfigFile.new();var legacy_key:=InputEventKey.new();legacy_key.keycode=KEY_J;legacy.set_value("bindings","target",legacy_key);legacy.save(FlightPreferences.save_path)
 FlightPreferences.install();check(has_key("target",KEY_J),"Existing single-device settings still load")
 FlightPreferences.replace("target",mouse);FlightPreferences.install()
 check(has_key("target",KEY_J) and has_mouse("target",MOUSE_BUTTON_RIGHT),"Adding a device to an older setting preserves its original binding")
 FlightPreferences.save_path="user://missing-polish-folder/controls.cfg"
 check(FlightPreferences.reset()!=OK and has_key("missile",KEY_M),"A failed reset save still restores session controls without falsely reporting success")
 FlightPreferences.save_path=original_path;FlightPreferences.install()
 check(FlightPreferences.label_for("missile")=="M","Default physical-key bindings show clean HUD labels")
 var job:={"kind":"repair","id":"route-one","slot":1,"generation":0,"region":0,"title":"Original route","faction":"frontier","at":Vector3(0,6500,0),"reward":55}
 roam.frontier.start(job);await frames();var entry: Dictionary=AtlasData.entries(roam).filter(func(item):return item.kind=="job")[0]
 check(entry.id=="job:route-one" and roam.navigation.set_route(entry),"Job courses identify the specific accepted job")
 roam.frontier.active.title="Updated live title";roam.navigation.clock=0;roam.navigation._process(.2)
 check(roam.navigation.hint.text.contains("Updated live title") and p.journey.waypoint.name=="Original route","Live course labels update without mutating the saved destination")
 roam.frontier.cancel();roam.navigation.clock=0;roam.navigation._process(.2)
 check(not roam.navigation.marker.visible and roam.navigation.hint.text.contains("JOB ENDED"),"Ended jobs stop drawing a misleading active course marker")
 job.id="route-two";job.title="A different job";roam.frontier.start(job);await frames();roam.navigation.clock=0;roam.navigation._process(.2)
 check(not roam.navigation.marker.visible,"An old course never silently follows a newly accepted job")
 roam.frontier.cancel()
 for i in range(3):p.record_discovery("open.region.%d"%i,"Region %d"%i)
 JourneyState.pin(p,"pathfinder");check(JourneyState.claim(p,"pathfinder") and p.journey.goal.is_empty(),"Claiming a pinned badge clears its completed reminder")
 var sanitized:=JourneyState.sanitize({"goal":"pathfinder","claimed":["pathfinder"]})
 check(sanitized.goal.is_empty(),"Older saves do not restore an already claimed goal as ready to claim")
 var vein:=roam.mining.veins[0];vein.position=Vector3(0,7000,0);var ship:=roam.pilot.ship;ship.position=Vector3(0,7000,80);vein.strike(100,ship)
 check(not roam.mining.collect(vein) and roam.mining.message.contains("OUT OF RANGE"),"A refused tractor action explains the exact collection range")
 ship.position=Vector3(0,7000,40)
 var obstacle:=StaticBody3D.new();obstacle.collision_layer=2;obstacle.position=Vector3(0,7000,20);roam.add_child(obstacle)
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(12,12,4);shape.shape=box;obstacle.add_child(shape);await frames()
 var ore:=int(p.sanctuary.materials.ore)
 check(not roam.mining.collect(vein) and int(p.sanctuary.materials.ore)==ore and roam.mining.message.contains("BLOCKED"),"Direct collection validates obstacles as well as the hold-to-collect controller")
 obstacle.queue_free();await frames()
 roam.navigation.set_route({"id":"vein-0-0","name":"Test deposit","kind":"mineral","at":JourneyState.pack(vein.position)})
 check(roam.mining.collect(vein),"A clear nearby fractured vein remains collectable")
 roam.navigation.clock=0;roam.navigation._process(.2)
 check(not roam.navigation.marker.visible and roam.navigation.hint.text.contains("DEPOSIT RECOVERED"),"A recovered deposit produces useful completion guidance")
 var salvage: ComponentSalvage
 for child in roam.get_children():
  if child is ComponentSalvage:salvage=child
 var cache: Dictionary=AtlasData.entries(roam).filter(func(item):return item.kind=="station")[0]
 cache={"id":"cache-%d-0"%salvage.generation,"name":"Test cache","kind":"salvage","at":JourneyState.pack(salvage.caches[0].position)}
 roam.navigation.set_route(cache);salvage.recover(0);roam.navigation.clock=0;roam.navigation._process(.2)
 check(not roam.navigation.marker.visible and roam.navigation.hint.text.contains("CACHE RECOVERED"),"Recovered component courses stop pointing at empty cache locations")
 main.show_frontier();await frames();var screen: FrontierScreen=main.story_layer.get_child(0);screen.tab=5;screen.refresh();await frames()
 var atlas:=screen.body.get_child(0) as AtlasPage;atlas.search="no-such-contact-in-this-galaxy";atlas.refresh()
 check(atlas.list.find_child("NoAtlasContacts",true,false)!=null,"An empty atlas search explains filters and sensor requirements")
 p.save_blocked=true
 for button in atlas.find_children("","Button",true,false):
  if button.text=="CLEAR COURSE":button.pressed.emit()
 check(not p.journey.waypoint.is_empty() and atlas.notice.text.contains("could not save"),"Clearing a course reports a failed save and preserves the saved destination")
 p.save_blocked=false
 main.close_story();roam.network_role="client";roam.pings.apply_snapshot([{"id":1,"kind":0,"at":[0,0,0],"remaining":1},{"id":1,"kind":2,"at":[0,0,0],"remaining":1}])
 check(roam.pings.records.size()==1,"Repeated ping IDs cannot create contradictory duplicate markers")
 roam.pings._physics_process(1.1);check(roam.pings.records.is_empty(),"Client ping markers expire even when snapshots stop arriving")
 roam.network_role="offline";p.journey.resume={"region":2,"peaceful":true,"saved_at":123,"job":{}};p.save_profile();p.save_blocked=true
 main.continue_frontier();await process_frame
 check(main.battle==roam and main.quit_dialog!=null,"Continue also preserves the current flight when its departure save fails")
 main.quit_dialog.confirmed.emit();await frames();roam=main.battle;freeze(roam)
 check(roam.journey_log.region==2 and roam.peaceful,"Confirming a deferred Continue retains the requested checkpoint instead of starting a fresh journey")
 p.save_blocked=false
 main.start_planet(0,"crew_pixlet");await frames();var surface: PlanetExpedition=main.surface;surface.set_physics_process(false);surface.bot.set_physics_process(false);surface.pending["pending-polish"]="A pending survey"
 main.return_to_menu();await process_frame
 check(main.surface==surface and main.quit_dialog!=null,"Changing activities preserves undelivered surveys until a decision is made")
 main.quit_dialog.canceled.emit();await frames()
 check(main.surface==surface and surface.pending.has("pending-polish"),"Canceling a survey transition returns to the same exploring bot")
 main.queue_free();await frames();print("POLISH_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
