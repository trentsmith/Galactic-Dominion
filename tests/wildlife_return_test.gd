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
func freeze_surface(expedition: PlanetExpedition) -> void:
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 expedition.wilderness.set_process(false);expedition.wilderness.set_physics_process(false)
 expedition.party.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
func run() -> void:
 check(GameFeatures.wildlife_enabled() and GameFeatures.companions_enabled() and not GameFeatures.creatures_enabled(),"Wildlife and orbiters are enabled without the old bundled story/art mode")
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://wildlife-return-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 check(main.menu.find_child("PlanetsButton",true,false)!=null and main.menu.find_child("SanctuaryButton",true,false)!=null,"Default navigation restores expeditions and sanctuary")
 main.show_story();await frames()
 check(main.story_layer.get_child(0) is ShipStoryScreen,"The Fractured Relay remains the active campaign")
 main.close_story()
 var profile: PlayerProfile=main.profile
 ShipCampaign.accept(profile);profile.story.accepted=true;profile.save_profile()
 var campaign:=profile.ship_story.duplicate(true);var legacy:=profile.story.duplicate(true)
 profile.acquire("crew_orbitot");profile.equip(0,"crew","crew_orbitot")
 main.start_free_roam(true);await frames()
 var roam: FreeRoamMatch=main.battle
 var orbit_id:=roam.get_instance_id()
 roam.set_physics_process(false);roam.pilot.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
 check(roam.pilot.ship.find_child("NexusBloodforgedHull",true,false)!=null and roam.pilot.ship.companion!=null,"Nexus hulls and orbital companions coexist with restored landing")
 check(roam.find_child("LandingBotPicker",true,false)!=null,"The chart restores the live explorer selector")
 var controls:=roam.find_child("LandingBotPicker",true,false) as OptionButton
 for i in range(controls.item_count):
  if controls.get_item_metadata(i)=="crew_orbitot":controls.item_selected.emit(i)
 var starting_residents: int=profile.sanctuary.residents.size()
 for world_index in range(3):
  var region: int=[0,2,3][world_index]
  roam.pilot.ship.position=FreeRoamWorld.CENTERS[region]+Vector3(-1000,-200,-1400)
  roam.pilot.ship.health.regen_delay=2
  check(not roam.can_land(world_index),"World %d refuses landing after recent damage"%world_index)
  roam.pilot.ship.health.regen_delay=0
  check(roam.can_land(world_index),"World %d accepts its real peaceful orbital approach"%world_index)
  var input:=InputEventAction.new();input.action="surface_land";input.pressed=true
  roam._unhandled_input(input);await frames()
  var surface: PlanetExpedition=main.surface
  check(surface!=null and surface.definition==PlanetCatalog.WORLDS[world_index] and surface.fauna.size()>=30,"L deploys the selected bot into the correct populated world %d"%world_index)
  if surface==null:main.queue_free();await frames();quit(1);return
  freeze_surface(surface)
  check(surface.bot.definition.id=="crew_orbitot" and surface.bot.visual.eyes.size()==2,"Surface bot retains the companion's original expressive face on world %d"%world_index)
  check(surface.world.get_node("LandedShip").find_child("NexusBloodforgedHull",true,false)!=null,"The landed ship keeps its Nexus design on world %d"%world_index)
  var target: SurfaceFauna
  for animal in surface.fauna:
   if target==null and animal.definition.damage<=0:target=animal
   else:animal.position=Vector3(500,5,500)
  surface.select_hunt(target.definition.id)
  surface.bot.position=target.position+Vector3(0,1,3)
  check(surface.survey_specimen(target),"An actual nearby animal can be surveyed on world %d"%world_index)
  if world_index==0:
   var surface_id:=surface.get_instance_id();main.show_story();main.ship_story_action();await frames()
   check(is_instance_valid(main.surface) and main.surface.get_instance_id()==surface_id and main.profile.story_message.contains("Deliver"),"Ship-story travel refuses to discard unextracted surface surveys")
   main.close_story()
  check(surface.capture_nearest() and surface.cargo_animals.size()==1,"A surveyed animal can enter saved transport on world %d"%world_index)
  surface.bot.position=Vector3(0,1.5,5)
  if world_index==0:
   profile.save_blocked=true
   check(not surface.extract() and surface.cargo_animals.size()==1 and profile.sanctuary.residents.size()==starting_residents,"Failed sanctuary delivery leaves the rescue retryable")
   profile.save_blocked=false
  check(surface.extract() and profile.sanctuary.residents.size()==starting_residents+world_index+1,"Delivery banks the rescued animal on world %d"%world_index)
  main.return_from_planet();await frames()
  check(main.battle==roam and main.battle.get_instance_id()==orbit_id and main.surface==null,"Departure restores the same orbital session after world %d"%world_index)
 check(profile.ship_story==campaign and profile.story==legacy,"Wildlife exploration cannot overwrite either campaign's recorded progress")
 var restored:=PlayerProfile.new(profile.save_path);restored.load_profile()
 check(restored.sanctuary.residents.size()==starting_residents+3 and restored.surface_transport.animals.is_empty(),"Three delivered rescues survive reload without duplicated transport")
 main.show_sanctuary();await frames()
 check(main.sanctuary_scene!=null and main.sanctuary_scene.actors.size()==starting_residents+3,"The sanctuary displays all preserved and new residents")
 main.return_to_menu();await frames()
 var gallery:=Node3D.new();root.add_child(gallery)
 var no_masks:=true;var anatomy:=true;var eyes_small:=true;var mature:=true
 for planet in PlanetCatalog.WORLDS:
  for definition in planet.fauna:
   var model:=SurfaceArt.creature(gallery,definition)
   no_masks=no_masks and model.find_child("LittleSmile",true,false)==null and model.find_child("RosyCheek*",true,false)==null and model.find_child("MoonBrow",true,false)==null
   var count:=model.find_children("EyeAnchor*","Node3D",true,false).size()
   anatomy=anatomy and count==(0 if definition.body_style in ["jelly","wisp"] else 2)
   for eye in model.find_children("EyeSocket*","MeshInstance3D",true,false):eyes_small=eyes_small and eye.scale.x<.1 and eye.scale.y<.065
   var grown:=SanctuaryFormArt.creature(gallery,definition,2)
   mature=mature and grown.find_children("EyeAnchor*","Node3D",true,false).size()==count
   grown.free();model.free()
 check(no_masks,"Wild animals have no pasted smiles, rosy cheeks or brow decorations")
 check(anatomy,"Jellies and wisps have no paired face; other species keep biological eyes")
 check(eyes_small,"Wildlife eyes use restrained proportions instead of oversized cartoon eyes")
 check(mature,"Mature sanctuary forms inherit the same neutral wildlife anatomy")
 var bot:=AlienVisual.new();bot.definition=CollectionCatalog.find("crew_lunaflutter");root.add_child(bot)
 check(bot.eyes.size()==2 and bot.eyes[0].name.begins_with("HappyCrescentEye"),"The companion face generator is unchanged")
 bot.queue_free();gallery.queue_free();main.queue_free();await frames()
 print("WILDLIFE_RETURN_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
