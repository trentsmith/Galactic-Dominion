extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var path:="user://landing-hunt-%d.json"%Time.get_ticks_usec()
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main);await process_frame
 main.profile.acquire("crew_orbitot");main.profile.acquire("crew_glimbloom");main.profile.acquire("variant_glimbloom")
 main.profile.set_ship_class(0,"guardian");main.profile.equip(0,"variant","variant_glimbloom")
 main.start_free_roam(true);await process_frame
 var roam: FreeRoamMatch=main.battle
 roam.set_physics_process(false);roam.pilot.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if is_instance_valid(ship.companion):ship.companion.set_physics_process(false)
 var orbit_id:=roam.get_instance_id()
 var picker:=roam.find_child("LandingBotPicker",true,false) as OptionButton
 var chosen_index:=-1
 for index in range(picker.item_count):
  if picker.get_item_metadata(index)=="crew_glimbloom":chosen_index=index
 picker.item_selected.emit(chosen_index)
 check(roam.landing_bot_id=="crew_glimbloom","The orbital landing picker selects an owned exploring bot")
 roam.pilot.ship.position=FreeRoamWorld.CENTERS[0]+Vector3(-1000,-600,-1400)+Vector3(0,400,0)
 roam.pilot.ship.health.regen_delay=0
 check(roam.can_land(0),"A controlled planet accepts landing from its actual orbital approach")
 var event:=InputEventAction.new();event.action="surface_land";event.pressed=true
 roam._unhandled_input(event);await process_frame
 var expedition: PlanetExpedition=main.surface
 check(expedition!=null and main.parked_roam==roam,"L lands and retains the exact orbital session")
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
 check(expedition.bot_definition.id=="crew_glimbloom","The selected bot deploys to the surface")
 check(expedition.landing_stats.class_name_text=="Guardian" and expedition.landing_stats.variant_style=="glimbloom","Surface landing retains the piloted hull and livery")
 check(expedition.world.get_node("LandedShip").get_meta("ship_class")=="Guardian","The actual fitted Guardian is visible at the landing refuge")
 expedition.bot.hull=33;expedition.bot.shield=12;expedition.bot.stamina=44
 check(expedition.switch_bot("crew_orbitot") and expedition.bot.definition.id=="crew_orbitot","An owned bot can take over at the landing ship")
 check(expedition.bot.hull==33 and expedition.bot.shield==12 and expedition.bot.stamina==44,"Bot switching cannot refill health, shield or energy")
 check(not expedition.switch_bot("crew_astra") and not expedition.switch_bot("crew_cinderbit"),"Human and unowned bots are rejected")
 expedition.bot.position=Vector3(0,2,-30)
 check(not expedition.switch_bot("crew_glimbloom"),"Bot switching requires the landing refuge")
 var animal: SurfaceFauna
 for candidate in expedition.fauna:
  if candidate.definition.damage==0 and animal==null:animal=candidate
  else:candidate.position=Vector3(500,5,500)
 var species:=animal.definition.id
 expedition.bot.position=animal.position+Vector3(0,1,3)
 check(expedition.select_hunt(species) and expedition.tracked_animal()==animal,"Species tracking selects the nearest living matching animal")
 check(not expedition.select_hunt("unknown_species"),"Unknown hunt species cannot be selected")
 expedition._physics_process(.01)
 check(expedition.hunt_beacon.visible and expedition.hunt_beacon.global_position.distance_to(animal.global_position)<5,"The active hunt has a real world-space guide")
 var current:=expedition.hunt_species;expedition.cycle_hunt()
 check(current!=expedition.hunt_species,"T cycles to another local species")
 expedition.select_hunt(species)
 check(not expedition.capture_nearest(),"A tracked creature must be scanned before capture")
 check(expedition.survey_specimen(animal) and expedition.capture_nearest(),"A real scanned creature can enter the transport")
 check(expedition.cargo_animals.size()==1 and main.profile.sanctuary.residents.size()==1,"Capture does not deliver a resident before extraction")
 expedition.bot.position=Vector3(0,1.5,5)
 check(expedition.switch_bot("crew_glimbloom") and expedition.cargo_animals.size()==1,"Changing bots preserves captured cargo")
 expedition.hud.refresh_choices()
 var hunt_choice:=expedition.hud.pause_panel.find_child("ActiveHuntChoice",true,false) as OptionButton
 hunt_choice.item_selected.emit(2)
 check(expedition.hunt_species==expedition.definition.fauna[2].id,"Pause-menu hunt choices are wired to the real objective")
 main.profile.save_blocked=true
 check(not expedition.extract() and not expedition.finished,"A failed save does not complete extraction")
 check(main.profile.sanctuary.residents.size()==1 and expedition.cargo_animals.size()==1,"Failed delivery rolls back sanctuary intake and retains cargo for retry")
 main.profile.save_blocked=false
 check(expedition.extract() and main.profile.sanctuary.residents.size()==2,"Successful extraction delivers captured fauna to the sanctuary")
 check(not expedition.extract() and main.profile.sanctuary.residents.size()==2,"Repeated extraction cannot duplicate a capture")
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(restored.sanctuary.residents.size()==2 and restored.sanctuary.residents[1].species==species,"Delivered creatures survive a real save/reload")
 expedition.sanctuary_requested.emit();await process_frame
 check(main.surface==null and main.sanctuary_scene!=null and main.parked_roam==roam,"The sanctuary visit preserves the parked space session")
 check(main.sanctuary_scene.state.residents.size()==2,"The captured creature appears in the actual sanctuary scene")
 main.sanctuary_scene.close();await process_frame
 check(main.battle.get_instance_id()==orbit_id and main.surface==null and main.sanctuary_scene==null,"Leaving the sanctuary restores the same orbit session")
 main.queue_free();await process_frame;await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("LANDING HUNT TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
