extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func run() -> void:
 check(GameFeatures.companions_enabled() and not GameFeatures.creatures_enabled(),"Companions are enabled independently of wildlife")
 var profile:=PlayerProfile.new("user://orbiting-restore-%d.json"%Time.get_ticks_usec());profile.load_profile()
 var all_available:=true
 for id in ["crew_pixlet","crew_cinderbit","crew_lunaflutter","crew_orbitot","crew_glimbloom"]:
  var definition:=CollectionCatalog.find(id)
  all_available=all_available and GameFeatures.collectible_active(definition) and definition in CollectionCatalog.for_slot("crew","Skirmisher")
 check(all_available,"All five little bots are selectable in the crew fitting catalog")
 profile.acquire("crew_orbitot");profile.equip(0,"crew","crew_orbitot");profile.save_profile()
 var restored:=PlayerProfile.new(profile.save_path);restored.load_profile()
 check(restored.configured_stats(0).crew_id=="crew_orbitot","Selected companion survives save and reload")
 var ship:=CombatShip.new();ship.stats=restored.configured_stats(0);root.add_child(ship);ship.set_physics_process(false)
 check(is_instance_valid(ship.companion) and ship.companion.definition.id=="crew_orbitot","An equipped bot spawns around the live Nexus ship")
 var before:=ship.companion.position;ship.companion._process(.5)
 check(not before.is_equal_approx(ship.companion.position) and ship.companion.visual!=null,"The companion visibly orbits with its real 3D model")
 check(ship.find_child("NexusBloodforgedHull",true,false)!=null,"Restoring bots retains the Nexus ship design")
 check(not GameFeatures.collectible_active(CollectionCatalog.find("variant_orbitot")),"Animal-themed ship skins remain archived")
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path=profile.save_path;root.add_child(main);await process_frame;await process_frame
 check(main.menu.find_child("PlanetsButton",true,false)==null and main.menu.find_child("SanctuaryButton",true,false)==null,"Animal exploration and sanctuary activities remain absent")
 main.start_free_roam(true);await process_frame
 check(not main.battle.can_land(0) and main.battle.map_panel.find_child("LandingBotPicker",true,false)==null,"Restoring orbiters does not enable animal expeditions or bot landing")
 check(is_instance_valid(main.battle.pilot.ship.companion),"Equipped companion also appears in peaceful Free Roam")
 main.return_to_menu();await process_frame;main.show_story();await process_frame
 check(main.story_layer.get_child(0) is ShipStoryScreen,"The spaceship campaign remains the active story")
 main.queue_free();ship.queue_free();await process_frame;await process_frame;await process_frame
 print("ORBITING_RESTORE_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
