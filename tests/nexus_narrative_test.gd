extends SceneTree
var checks:=0
var failures:=0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func frames() -> void:
 await process_frame;await process_frame;await process_frame
func freeze(battle: BattleMatch) -> void:
 battle.set_physics_process(false);battle.narrative.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 if battle.narrative.placement_pending:battle.narrative.place_clear();battle.narrative.placement_pending=false
func clear_foes(battle: BattleMatch) -> void:
 for ship in battle.ships:
  if ship.team==1 and ship.alive:ship.health.damage(100000,null,"simulated combat")
func open_sortie(mission: String,replay: bool=false) -> BattleMatch:
 main.start_battle(int(NexusStoryData.MISSIONS[mission].size),mission,0,0,false,replay)
 await frames();freeze(main.battle)
 return main.battle
func secure_scans(battle: BattleMatch) -> void:
 for point in battle.narrative.points:
  battle.pilot.ship.position=point
  battle.narrative.tick(4.1,true)
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://narrative-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 var p: PlayerProfile=main.profile
 var legacy:=p.story.duplicate(true);var residents:=p.sanctuary.duplicate(true)
 ShipCampaign.accept(p)
 var b: BattleMatch=await open_sortie("nexus_blockade")
 var d:=b.narrative
 check(d!=null and d.actors.size()==1,"Blockade creates a real relay objective alongside six fighters")
 var radio_time:=d.comms.remaining
 main.show_story();await frames()
 check(paused and is_equal_approx(d.comms.remaining,radio_time),"Solo journal pauses radio timing with the battle")
 main.close_story();await frames()
 check(not paused and d.comms.remaining<radio_time,"Closing comms resumes radio and preserves the existing sortie")
 check(b.ships.size()==6 and b.zone.final_radius==420,"Mission objects preserve fleet counts and remain inside the safe sector")
 check(b.get_child(0).planet_tint==NexusStoryData.MISSIONS.nexus_blockade.tint,"Story encounters use their authored world palette")
 b.finish(0,"attempted skip")
 check(not b.finished and ShipCampaign.stage(p)==1,"A generic victory call cannot bypass hostile and relay objectives")
 b.pilot.ship.position=d.points[0];d.tick(4,true)
 check(d.completed_points.is_empty(),"The relay cannot uplink while hostile ships jam its network")
 clear_foes(b)
 check(not b.finished,"Clearing the enemy fleet alone does not transmit civilian routes")
 b.pilot.ship.position=d.points[0]+Vector3(150,0,0);d.tick(4,true)
 check(d.completed_points.is_empty(),"Uplink refuses scans outside its advertised range")
 b.pilot.ship.position=d.points[0]+Vector3(40,0,0)
 var wall:=StaticBody3D.new();wall.collision_layer=2;b.add_child(wall);wall.position=d.points[0]+Vector3(20,0,0)
 var box:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(5,80,80);box.shape=shape;wall.add_child(box)
 await physics_frame;await physics_frame;d.tick(4,true)
 check(d.completed_points.is_empty() and d.message.contains("BLOCKED"),"A physical obstacle blocks mission scanning with a readable reason")
 wall.free();await physics_frame
 d.tick(1,true);d.tick(.1,false)
 check(d.scan_progress==0,"Releasing G resets an incomplete handshake")
 d.tick(3.1,true)
 check(b.finished and b.winner==0 and ShipCampaign.stage(p)==2,"A real in-range relay handshake completes the sortie")
 check(p.ship_story.reports.nexus_blockade.success and p.ship_story.reports.nexus_blockade.heard.has("b_done"),"The decoded recording and actual outcome persist in the sortie report")
 check("lantern_keeper" in p.ship_story.honors,"A protected relay earns the one-time optional commendation")
 check(not d.layer.visible and not d.comms.is_processing(),"Mission overlays and unseen radio stop when results open")
 check(b.hud.results.find_child("StoryDebrief",true,false)!=null,"Results explain the story outcome separately from damage statistics")
 var honors_before:=p.salvage
 check(ShipCampaign.resolve(p,"nexus_blockade",d.report(true),true) and p.salvage==honors_before,"Replay cannot repeat the commendation or commission reward")
 var failed: BattleMatch=await open_sortie("nexus_blockade",true)
 failed.narrative.integrity=0;failed.narrative.tick(.1,false)
 check(failed.finished and failed.winner==1 and p.ship_story.crimson,"Losing a relay fails the replay without rolling back prior completion")
 check(p.ship_story.reports.nexus_blockade.heard.has("b_done"),"A failed replay cannot erase an already recovered transmission")
 var blocked: BattleMatch=await open_sortie("nexus_blockade",true)
 var previous_report: Dictionary=p.ship_story.reports.nexus_blockade.duplicate(true)
 p.save_blocked=true;clear_foes(blocked);secure_scans(blocked)
 check(blocked.finished and not blocked.story_saved and p.ship_story.reports.nexus_blockade==previous_report,"A failed actual sortie save retains its old report and exposes retry status")
 p.save_blocked=false
 var timed: BattleMatch=await open_sortie("nexus_blockade",true)
 timed.elapsed=480;timed._physics_process(.1)
 check(timed.finished and timed.winner==1,"Unfinished story sorties fail at the eight-minute deadline")
 ComponentDiscovery.recover(p,"space",0);p.equip(0,"engine","engine_sprint")
 var abyss: BattleMatch=await open_sortie("nexus_abyss")
 abyss.pilot.ship.position=abyss.narrative.points[0]
 var health_before:=abyss.pilot.ship.health.shield+abyss.pilot.ship.health.hull
 abyss.narrative.hazard_clock=19;abyss.narrative.tick(1.1,false)
 check(abyss.pilot.ship.health.shield+abyss.pilot.ship.health.hull==health_before and abyss.narrative.status.text.contains("WARNING"),"The anomaly warns before damage is applied")
 abyss.narrative.tick(4,false)
 check(abyss.pilot.ship.health.shield+abyss.pilot.ship.health.hull<health_before,"Remaining inside the telegraphed field causes real shield or hull damage")
 clear_foes(abyss);secure_scans(abyss)
 check(abyss.finished and ShipCampaign.stage(p)==5 and p.ship_story.reports.nexus_abyss.heard.has("a_astra"),"Decoding Mnemosyne reveals Astra's admission and unlocks the final briefing")
 check(not main.start_ship_story_encounter(),"The final encounter cannot launch before choosing a protocol")
 p.save_blocked=true
 check(not ShipCampaign.choose(p,"seal") and p.ship_story.decision.is_empty(),"A failed choice save restores the prior protocol")
 p.save_blocked=false
 check(ShipCampaign.choose(p,"seal") and ShipCampaign.lock_decision(p),"Protocol selection is saved and locked before deployment")
 check(not ShipCampaign.choose(p,"preserve"),"A launched chapter cannot silently change its chosen protocol")
 var seal: BattleMatch=await open_sortie("nexus_warfront")
 check(seal.narrative.points.size()==3 and seal.ships.size()==20,"Seal produces three actual conduits in a 10v10 battle")
 var commanders: Array=seal.ships.filter(func(ship):return ship.callsign.begins_with("Marshal Veyr"))
 check(commanders.size()==1 and commanders[0].stats.variant_style=="nexus_crimson" and commanders[0].stats.ability=="aegis","Veyr consistently commands a Crimson Guardian in the mixed-faction warfront")
 clear_foes(seal);seal.pilot.ship.position=seal.narrative.points[0];seal.narrative.tick(2.1,true)
 check(not seal.finished and seal.narrative.completed_points.size()==1,"One conduit cannot stand in for all three phase links")
 secure_scans(seal)
 check(seal.finished and seal.winner==0 and p.ship_story.ending=="seal","Severing all links records the Seal resolution")
 p.loadouts[0].engine="engine_standard"
 check(ShipCampaign.stage(p)==6,"Changing an engine after a won milestone cannot undo story progress")
 ShipCampaign.complete(p)
 var restored:=PlayerProfile.new(p.save_path);restored.load_profile()
 check(restored.ship_story.ending=="seal" and restored.ship_story.decision_locked and restored.ship_story.reports.size()==3,"Choice, ending and bounded mission records survive reload")
 # A second independent commander exercises the other gameplay branch.
 var other:=PlayerProfile.new("user://narrative-preserve-%d.json"%Time.get_ticks_usec());other.load_profile()
 other.ship_story.accepted=true;other.ship_story.crimson=true;other.ship_story.eldritch=true
 main.profile=other
 check(ShipCampaign.choose(other,"preserve") and ShipCampaign.lock_decision(other),"A separate commander can commit to Preserve")
 var escort: BattleMatch=await open_sortie("nexus_warfront")
 var core:=escort.narrative
 check(core.points.size()==1 and core.goal!=null and core.choice=="preserve","Preserve creates a movable memory core and jump beacon")
 escort.pilot.ship.position=Vector3(500,0,0);core.tick(2,false)
 check(core.escort_progress==0,"The core does not fly itself home while its commander is absent")
 var foe: CombatShip=escort.ships.filter(func(s):return s.team==1)[0]
 for ship in escort.ships:
  if ship.team==1:ship.position=Vector3(900,0,0)
 foe.position=core.points[0];escort.pilot.ship.position=core.points[0];core.tick(2,false)
 check(core.escort_progress==0 and core.integrity<100,"Nearby enemy jammers stall and damage the core")
 clear_foes(escort)
 check(not escort.finished,"Fleet elimination alone cannot replace the escort objective")
 escort.pilot.ship.position=core.points[0];core.tick(1,false)
 check(core.escort_progress>0 and core.actors[0].position!=core.archive_start,"A nearby pilot guides the actual 3D core along its route")
 for i in range(36):escort.pilot.ship.position=core.points[0];core.tick(1,false)
 check(escort.finished and escort.winner==0 and other.ship_story.ending=="preserve","The core must arrive before Preserve wins and saves its ending")
 check(NexusStoryData.ending("seal")!=NexusStoryData.ending("preserve"),"The two objectives lead to distinct authored epilogues")
 check(p.story==legacy and p.sanctuary==residents,"The new narrative leaves archived animal and biological-story data intact")
 main.return_to_menu();await frames();main.show_story();await frames()
 var screen: ShipStoryScreen=main.story_layer.get_child(0)
 var action: Button=screen.find_child("ShipStoryObjectiveButton",true,false)
 check(action!=null and root.get_visible_rect().encloses(action.get_global_rect()),"The primary story action fits in the default viewport")
 var tabs: TabBar=screen.find_child("NexusJournalTabs",true,false)
 tabs.current_tab=1;await frames()
 check(screen.content.get_child_count()>2,"Recordings render retrieved transmissions without reopening dialogue loops")
 tabs.current_tab=3;await frames()
 check(screen.find_child("Replay_nexus_blockade",true,false)!=null,"The journal exposes replay controls alongside sortie reports")
 main.close_story();main.profile=p;main.return_to_menu();await frames()
 main.start_battle();await frames()
 check(main.battle.narrative==null and main.battle.zone.final_radius==95,"Ordinary fleet battles retain their original rules without a mission director")
 main.battle.network_role="client";main.show_story();await frames()
 check(not paused and main.story_layer.get_child(0).readonly and main.story_layer.find_child("ShipStoryObjectiveButton",true,false).disabled,"Online journals remain read-only and do not pause the server")
 main.close_story();main.return_to_menu();await frames()
 # Legacy v0.38 completion remains valid and replays do not repay its finale.
 var old_data:=p.to_dict();old_data.version=8;old_data.ship_story={"accepted":true,"crimson":true,"eldritch":true,"rift":true,"complete":true,"cache_baseline":0}
 var old_path:="user://narrative-legacy-%d.json"%Time.get_ticks_usec();var file:=FileAccess.open(old_path,FileAccess.WRITE);file.store_string(JSON.stringify(old_data));file.close()
 var old:=PlayerProfile.new(old_path);old.load_profile()
 check(ShipCampaign.stage(old)==7 and ShipCampaign.can_replay(old,"nexus_warfront") and old.ship_story.ending.is_empty(),"Version-eight completions migrate with replay access and no invented ending")
 var before_old:=old.salvage
 check(not ShipCampaign.complete(old) and old.salvage==before_old,"Old completed profiles cannot claim the chapter payout again")
 check(ShipCampaign.choose(old,"preserve"),"A legacy completion can choose a protocol for its first enhanced replay")
 var clean:=ShipCampaign.sanitize({"decision":"hack","reports":{"unknown":{},"nexus_blockade":{"heard":["b_start","fake","b_start"],"seconds":INF}},"honors":["hack"]})
 check(clean.decision.is_empty() and clean.reports.size()==1 and clean.reports.nexus_blockade.heard==["b_start"] and clean.honors.is_empty(),"Untrusted narrative data is bounded to known choices, missions and transmissions")
 var radio:=NexusComms.new();root.add_child(radio);radio.enqueue("b_start");radio.enqueue("b_start");radio.enqueue("unknown");radio.advance()
 check(radio.history==["b_start"] and radio.queue.is_empty(),"Radio delivery rejects unknown IDs and duplicate chatter")
 radio.queue_free();main.queue_free();await frames()
 print("NEXUS_NARRATIVE_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
