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
func run() -> void:
 check(not GameFeatures.creatures_enabled(),"Shipping defaults disable creatures reversibly")
 var path:="user://ship-campaign-%d.json"%Time.get_ticks_usec()
 main=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main);await frames()
 var p: PlayerProfile=main.profile
 var legacy:=p.story.duplicate(true);var sanctuary:=p.sanctuary.duplicate(true);var cargo:=p.surface_transport.duplicate(true)
 check(main.menu.find_child("PlanetsButton",true,false)==null and main.menu.find_child("SanctuaryButton",true,false)==null,"Creature activities are absent from default navigation")
 check(main.menu.find_child("StoryButton",true,false)!=null,"Fleet commission remains accessible")
 var excluded:=true
 for i in range(1000):excluded=excluded and GameFeatures.collectible_active(CollectionCatalog.roll(p._rng))
 check(excluded,"Default battle rewards exclude archived animal-themed hulls")
 main.show_story();await frames()
 check(main.story_layer.get_child(0) is ShipStoryScreen,"Story opens the ship commission journal")
 p.save_blocked=true;check(not ShipCampaign.accept(p) and ShipCampaign.stage(p)==0,"Failed commission saves roll back acceptance")
 p.save_blocked=false;main.ship_story_action()
 check(ShipCampaign.stage(p)==1,"Accepting commission starts the blockade objective")
 check(not ShipCampaign.victory(p,"nexus_abyss"),"Unrelated encounters cannot skip objectives")
 main.ship_story_action();await frames()
 check(main.battle.story_mission=="nexus_blockade" and main.battle.ships.size()==6,"Journal launches the real 3v3 blockade")
 var enemies: Array=main.battle.ships.filter(func(s):return s.team==1)
 check(enemies.all(func(s):return s.stats.variant_style=="nexus_crimson" and s.companion==null),"Crimson enemies use war hulls without orbiting creatures")
 main.battle.finish(1,"test defeat");await frames()
 check(ShipCampaign.stage(p)==1,"Losing the fleet fight allows retry without progress")
 main.start_story_encounter();await frames();main.battle.finish(0,"test win");await frames()
 check(ShipCampaign.stage(p)==2 and p.owns("engine_sprint") and p.owns("variant_nexus_crimson"),"Blockade victory saves a Sprint Drive and Bloodforged hull")
 main.return_to_menu();await frames();main.show_story();main.ship_story_action();await frames()
 check(main.battle is FreeRoamMatch and not main.battle.can_land(0),"Recovery objective enters space without surface landing")
 check(main.battle.map_panel.find_child("LandingBotPicker",true,false)==null,"Star chart hides bot deployment")
 var result:=ComponentDiscovery.recover(p,"space",0)
 check(result.ok and ShipCampaign.stage(p)==3,"Actual cache recovery advances fleet preparation")
 check(p.equip(0,"engine","engine_sprint") and ShipCampaign.stage(p)==4,"Normal hangar fitting unlocks the Abyss encounter")
 main.start_story_encounter();await frames()
 check(main.battle.story_mission=="nexus_abyss" and main.battle.ships.filter(func(s):return s.team==1).all(func(s):return s.stats.variant_style=="nexus_eldritch"),"Ny'Zaroth encounter contains actual living-hull enemies")
 main.battle.finish(0,"test win");await frames()
 check(ShipCampaign.stage(p)==5 and p.owns("variant_nexus_eldritch"),"Abyss victory unlocks the living faction hull")
 var fit_all:=true
 for key in CollectionCatalog.SHIP_TYPES:
  var stats: ShipStats=CollectionCatalog.SHIP_TYPES[key].duplicate(true)
  for style in ["nexus_crimson","nexus_eldritch"]:
   stats.variant_style=style;var model:=Node3D.new();NexusShipArt.build(model,stats)
   fit_all=fit_all and model.find_child("NexusLivingHull" if style=="nexus_eldritch" else "NexusBloodforgedHull",true,false)!=null and model.find_child("MuzzleFlash",true,false)!=null
   model.free()
 check(fit_all,"Both faction models build for all five ship classes")
 main.start_story_encounter();await frames()
 check(main.battle.ships.size()==20 and main.battle.story_mission=="nexus_warfront","Final commission launches a 10v10 fleet fight")
 main.battle.finish(0,"test win");await frames()
 check(ShipCampaign.stage(p)==6,"Only winning the warfront enables final debrief")
 var salvage:=p.salvage;p.save_blocked=true
 check(not ShipCampaign.complete(p) and p.salvage==salvage and ShipCampaign.stage(p)==6,"Failed final reward saves preserve the retry")
 p.save_blocked=false;check(ShipCampaign.complete(p) and p.salvage==salvage+100,"Final archive grants one saved chapter reward")
 check(not ShipCampaign.complete(p) and p.salvage==salvage+100,"Repeated debrief cannot duplicate the reward")
 check(p.story==legacy and p.sanctuary==sanctuary and p.surface_transport==cargo,"Archived creature story, sanctuary and transported animals remain untouched")
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(ShipCampaign.stage(restored)==7 and restored.owns("variant_nexus_eldritch"),"New campaign and faction unlocks survive reload")
 main.return_to_menu();await frames();main.show_planets();await frames()
 check(not is_instance_valid(main.surface),"Direct surface entry is safely disabled")
 main.show_sanctuary();await frames();check(not is_instance_valid(main.sanctuary_scene),"Direct sanctuary entry is safely disabled")
 ProjectSettings.set_setting("gameplay/creatures_enabled",true)
 check(GameFeatures.creatures_enabled() and GameFeatures.collectible_active(CollectionCatalog.find("crew_pixlet")),"One feature switch restores archived creature paths")
 ProjectSettings.set_setting("gameplay/creatures_enabled",false)
 # A schema-7 profile migrates independently of its old creature objective.
 var migration:=p.to_dict();migration.version=7;migration.erase("ship_story")
 var file:=FileAccess.open(path+"-old",FileAccess.WRITE);file.store_string(JSON.stringify(migration));file.close()
 var old:=PlayerProfile.new(path+"-old");old.load_profile()
 check(ShipCampaign.stage(old)==0 and old.story==legacy and old.sanctuary==sanctuary,"Schema-seven migration preserves biological records without skipping the fleet story")
 main.queue_free();await frames()
 print("SHIP_CAMPAIGN_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
