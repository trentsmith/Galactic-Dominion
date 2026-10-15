extends SceneTree
var checks:=0
var failures:=0
var main: Node
var path:=""
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func rich(state: Dictionary) -> void:
 for key in SanctuaryState.MATERIALS:state.materials[key]=100
func frames(count: int=3) -> void:
 for i in range(count):await process_frame
func freeze(expedition: PlanetExpedition) -> void:
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
func run() -> void:
 var state:=SanctuaryState.defaults()
 check(state.residents.size()==1 and state.habitats.size()==2 and state.plants.size()==1,"A sanctuary starts with one resident, a meadow and a food planter")
 var food_before: int=state.materials.food
 check(SanctuaryState.care(state,1,"feed") and state.materials.food==food_before-1 and state.residents[0].nutrition==100,"Feeding spends food and restores nutrition")
 check(not SanctuaryState.care(state,1,"feed") and state.materials.food==food_before-1,"Full residents cannot waste more food")
 check(SanctuaryState.care(state,1,"pet") and not SanctuaryState.care(state,1,"pet"),"Affection has a cooldown")
 var energy: float=state.residents[0].energy
 check(SanctuaryState.care(state,1,"play") and state.residents[0].energy<energy and state.residents[0].growth>0,"Playing costs energy and grows the resident")
 for i in range(15):SanctuaryState.tick(state,5)
 check(state.residents[0].production>0 and state.plants[0].stored>0,"Cared-for fauna and plants produce stored materials")
 var bloom: int=state.materials.bloom
 check(SanctuaryState.collect(state)>0 and state.materials.bloom>bloom,"Harvesting converts stored produce into materials")
 check(SanctuaryState.collect(state)==0,"Repeated harvesting cannot duplicate materials")
 state.residents[0].nutrition=0;state.residents[0].clock=0
 SanctuaryState.tick(state,5)
 check(state.residents[0].clock==0,"Hungry residents pause production")
 rich(state)
 var cost_before: int=state.materials.ore
 check(not SanctuaryState.build(state,"reef",-1,0) and state.materials.ore==cost_before,"Occupied plots reject building without charging materials")
 check(not SanctuaryState.build(state,"reef",0,0) and not SanctuaryState.build(state,"reef",3,0),"The central hub and outside plots cannot be built on")
 SanctuaryState.intake(state,["sporehopper"],["viridia.0"])
 check(state.residents[1].habitat==0,"Aquatic arrivals wait in the nursery until a reef is built")
 check(SanctuaryState.build(state,"reef",0,-1) and state.materials.ore==cost_before-4,"Habitat construction spends the advertised materials")
 check(state.residents[1].habitat>0,"Compatible housing automatically accepts waiting residents")
 check(SanctuaryState.move_habitat(state,3,1,1) and state.habitats[2].x==1,"A habitat can be moved to an empty plot")
 check(not SanctuaryState.move_habitat(state,3,1,0),"Moving cannot overlap an existing building")
 check(SanctuaryState.upgrade(state,3) and state.habitats[2].level==2,"Habitat upgrades increase production level and capacity")
 SanctuaryState.upgrade(state,3)
 check(not SanctuaryState.upgrade(state,3),"Habitat levels have a cap")
 check(SanctuaryState.plant_seed(state,"viridia.0") and state.seeds["viridia.0"]==0,"Collected seeds can be planted and are consumed once")
 check(not SanctuaryState.plant_seed(state,"viridia.0"),"Unowned seeds cannot be planted")
 var pods: int=state.materials.capture_pod
 check(SanctuaryState.craft(state,"capture_pod") and state.materials.capture_pod==pods+1,"Workshop materials craft transport pods")
 var snapshot: Dictionary=state.materials.duplicate()
 check(not SanctuaryState.launch(state,0) and state.materials==snapshot,"Flight requires all three upgrades")
 state.materials.ore=0
 check(not SanctuaryState.advance_flight(state) and state.flight_stage==0,"An unaffordable flight upgrade does not advance progress")
 rich(state)
 for stage in range(3):check(SanctuaryState.advance_flight(state) and state.flight_stage==stage+1,"Flight stages install in increasing order")
 var pearls: int=state.materials.pearl
 check(SanctuaryState.launch(state,0) and state.location==0 and state.materials.pearl==pearls-3,"The upgraded sanctuary consumes fuel and travels to another orbit")
 var fuel: int=state.materials.essence
 check(not SanctuaryState.launch(state,0) and state.materials.essence==fuel,"Launching to the current orbit cannot consume more fuel")
 var corrupted:=state.duplicate(true);corrupted.materials.food=-100;corrupted.residents.append({"id":999,"species":"missing"});corrupted.flight_stage=999
 var cleaned:=SanctuaryState.sanitize(corrupted)
 check(cleaned.materials.food==0 and cleaned.residents.size()==2 and cleaned.flight_stage==3,"Malformed saved sanctuary data is clamped and unknown species are rejected")
 path="user://sanctuary-test-%d.json" % Time.get_ticks_usec()
 var profile:=PlayerProfile.new(path);profile.load_profile();profile.sanctuary=state;profile.save_profile()
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(restored.sanctuary.residents.size()==2 and restored.sanctuary.location==0 and restored.sanctuary.habitats[2].level==3,"Sanctuary residents, habitat upgrades and flight location survive saving")
 var old:=profile.to_dict();old.version=2;old.erase("sanctuary")
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
 restored=PlayerProfile.new(path);restored.load_profile()
 check(not restored.save_blocked and restored.sanctuary.residents.size()==1 and restored.owned_count()==profile.owned_count(),"Version-two saves migrate without losing the existing collection")
 # Fresh player tests real expedition delivery and loss rather than direct inventory grants.
 for suffix in ["", ".bak"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 main=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main);await frames()
 main.start_planet(0);await frames()
 var expedition: PlanetExpedition=main.surface;freeze(expedition)
 var animal: SurfaceFauna=expedition.fauna[10]
 expedition.bot.position=animal.position+Vector3(0,1,3)
 check(not expedition.capture_nearest(),"Capturing fauna requires scanning its species first")
 expedition.survey_specimen(animal)
 check(expedition.capture_nearest() and not animal.alive and expedition.cargo_animals.size()==1,"A scanned passive animal enters transport")
 check(main.profile.sanctuary.residents.size()==1 and main.profile.sanctuary.materials.capture_pod==2,"Capture spends a pod but does not deliver the creature before extraction")
 var plant: Node3D=expedition.world.flora_nodes[0]
 expedition.bot.position=plant.position+Vector3(0,1,3)
 check(not expedition.gather_nearest(),"Flora must be surveyed before a seed is gathered")
 expedition.survey_specimen(plant)
 check(expedition.gather_nearest() and not expedition.gather_nearest(),"Only one seed of a flora type can be taken per expedition")
 var predator: SurfaceFauna=expedition.fauna[20]
 expedition.bot.position=predator.position+Vector3(0,1,3);expedition.survey_specimen(predator)
 check(not expedition.capture_nearest(),"Dangerous animals must be weakened before capture")
 predator.hit(20)
 check(expedition.capture_nearest() and expedition.cargo_animals.size()==2,"A weakened predator can be safely transported")
 expedition.bot.shield=0;expedition.bot.hull=1;expedition.bot.hurt(100)
 check(expedition.finished and expedition.cargo_animals.is_empty() and expedition.cargo_seeds.is_empty(),"Bot destruction loses transported creatures and seeds")
 check(main.profile.sanctuary.residents.size()==1 and main.profile.sanctuary.materials.capture_pod==1,"Failed expeditions do not duplicate residents or refund used pods")
 var after_loss:=PlayerProfile.new(path);after_loss.load_profile()
 check(after_loss.sanctuary.materials.capture_pod==1 and after_loss.sanctuary.residents.size()==1,"Used capture pods and undelivered residents remain correct after reloading")
 main.start_planet(1);await frames();expedition=main.surface;freeze(expedition)
 animal=expedition.fauna[0];expedition.bot.position=animal.position+Vector3(0,1,3);expedition.survey_specimen(animal)
 check(expedition.capture_nearest(),"An alien reef creature can be captured with the remaining pod")
 plant=expedition.world.flora_nodes[0];expedition.bot.position=plant.position+Vector3(0,1,3);expedition.survey_specimen(plant);expedition.gather_nearest()
 expedition.bot.position=Vector3(0,1.5,5)
 check(expedition.extract() and main.profile.sanctuary.residents.size()==2 and main.profile.sanctuary.seeds.has("viridia.0"),"Successful extraction delivers both fauna and seeds to the sanctuary")
 check(not expedition.extract() and main.profile.sanctuary.residents.size()==2,"Repeated extraction cannot duplicate transported creatures")
 main.show_sanctuary();await frames()
 var garden: SanctuaryGarden=main.sanctuary_scene
 check(is_instance_valid(garden) and garden.actors.size()==2 and garden.panel.residents.item_count==2,"The real 3D garden and resident-care interface load delivered fauna")
 garden.focus_resident=true;garden._process(.1)
 check(garden.camera.global_position.distance_to(garden.actors[garden.selected_resident].global_position)<18,"Resident focus provides a close-up care camera")
 rich(garden.state);garden.state.flight_stage=3
 check(garden.do_launch(1) and not garden.do_launch(2) and garden.travel_remaining>0,"A launch sequence prevents a second launch while already in flight")
 garden.close();await frames()
 check(not is_instance_valid(main.sanctuary_scene),"Leaving the garden saves and cleans up its scene")
 main.queue_free();await frames()
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("SANCTUARY TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
