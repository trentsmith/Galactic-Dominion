extends SceneTree
var checks := 0
var failures := 0
var main: Node
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func freeze(e: PlanetExpedition) -> void:
 e.set_physics_process(false);e.bot.set_physics_process(false);e.party.set_physics_process(false)
 for animal in e.fauna:animal.set_physics_process(false);animal.position=Vector3(1500,50,1500)
func run() -> void:
 var path := "user://creature-loop-%d.json" % Time.get_ticks_usec()
 main=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main)
 await process_frame
 for index in range(3):
  main.start_planet(index);await process_frame
  var e: PlanetExpedition=main.surface
  freeze(e)
  check(is_instance_valid(e.home_beacon),"Planet %d has a landing-ship return beacon"%index)
  var animal: SurfaceFauna=e.fauna[0]
  for candidate in e.fauna:
   if candidate.definition.damage>0:animal=candidate;break
  animal.position=Vector3(100,30,100)
  e.bot.position=animal.position+Vector3(0,0,20)
  e.select_hunt(animal.definition.id)
  check(e.tracked_animal()==animal,"Finding a hunt selects a live animal on planet %d"%index)
  var neighbor: SurfaceFauna=e.fauna[1]
  if neighbor!=animal and neighbor.definition.id==animal.definition.id:
   neighbor.position=e.bot.position+Vector3.RIGHT
   check(e.tracked_animal()==animal,"A nearer neighbour cannot steal the active hunt")
   neighbor.position=Vector3(1500,50,1500)
  check(not e.capture_nearest() and e.status_message.contains("8m"),"Out-of-range capture explains approach distance")
  e.scan_nearest(.1)
  check(e.status_message.contains("12m"),"Out-of-range scan explains scanning distance")
  e.bot.position=animal.position+Vector3(0,0,5)
  check(not e.capture_nearest() and e.status_message.contains("SCAN"),"Unsurveyed capture explains the missing scan")
  e.scan_nearest(2.1)
  check(e.surveyed(animal),"A clear-view scan completes on planet %d"%index)
  if animal.definition.damage>0:
   check(not e.capture_nearest() and e.status_message.contains("50%"),"Dangerous fauna require weakening before capture")
   if e.party.units.is_empty():check(not e.party.attack() and e.status_message.contains("NO DEPLOYED"),"Battle refusal explains N/R deployment and stun alternative")
   e.bot.yaw=0;e.bot.pitch=0
   for shot in range(30):
    if animal.health<=animal.definition.health*.5:break
    e.bot.cooldown=0;e.bot.fire()
   check(animal.alive and animal.health<=animal.definition.health*.5,"Actual stun pulses weaken wildlife without killing it")
  var pods: int=main.profile.sanctuary.materials.capture_pod
  main.profile.save_blocked=true
  check(not e.capture_nearest() and animal.alive and e.cargo_animals.is_empty(),"Capture save failure leaves wildlife and cargo unchanged")
  check(main.profile.sanctuary.materials.capture_pod==pods and main.profile.surface_transport.animals.is_empty(),"Capture save failure rolls back both pod and manifest")
  main.profile.save_blocked=false
  check(e.capture_nearest() and not animal.alive,"Eligible wildlife enters transport on planet %d"%index)
  check(main.profile.sanctuary.materials.capture_pod==pods-1,"Each capture spends exactly one pod")
  var restored:=PlayerProfile.new(path);restored.load_profile()
  check(restored.surface_transport.animals.size()==1 and restored.surface_transport.animals[0]==animal.definition.id,"Captured transport is durable before sanctuary delivery")
  main.return_to_menu();await process_frame
  main.profile=restored;main.start_planet(index);await process_frame
  e=main.surface;freeze(e)
  check(e.cargo_animals.size()==1 and e.status_message.contains("RECOVERED"),"Reloaded expedition restores transport at the landing ship")
  e.bot.position=Vector3(30,10,0)
  check(not e.extract() and e.status_message.contains("10m"),"Delivery away from the landing ship explains where to go")
  e.bot.position=Vector3(0,1.5,5)
  main.profile.save_blocked=true
  var residents: int=main.profile.sanctuary.residents.size()
  check(not e.extract() and main.profile.sanctuary.residents.size()==residents and main.profile.surface_transport.animals.size()==1,"Failed delivery restores sanctuary and transport atomically")
  main.profile.save_blocked=false
  check(e.extract() and main.profile.sanctuary.residents.size()==residents+1,"Returning to the ship delivers the captured creature")
  check(not e.extract() and main.profile.sanctuary.residents.size()==residents+1,"Repeated delivery cannot duplicate residents")
  restored=PlayerProfile.new(path);restored.load_profile()
  check(restored.surface_transport.animals.is_empty() and restored.sanctuary.residents.size()==residents+1,"Delivered residents persist and the saved manifest is cleared")
 main.start_planet(0);await process_frame
 var seed_expedition: PlanetExpedition=main.surface
 freeze(seed_expedition)
 var plant: Node3D=seed_expedition.world.flora_nodes[0]
 plant.position=Vector3(100,30,100);seed_expedition.bot.position=plant.position+Vector3(0,0,2)
 check(seed_expedition.survey_specimen(plant) and seed_expedition.gather_nearest(),"Scanned flora seeds are secured in the same durable transport")
 check(not seed_expedition.gather_nearest() and seed_expedition.status_message.contains("ONE SEED"),"Repeated collection explains the seed-per-expedition limit")
 var seed_id: String=seed_expedition.cargo_seeds[0]
 var seed_profile:=PlayerProfile.new(path);seed_profile.load_profile()
 check(seed_profile.surface_transport.seeds==[seed_id],"Collected seed survives profile reload")
 seed_expedition.bot.position=Vector3(30,10,0);seed_expedition.bot.hull=1;seed_expedition.bot.shield=0
 seed_expedition.bot.hurt(100)
 check(seed_expedition.finished and main.profile.surface_transport.seeds==[seed_id],"Bot destruction preserves secured cargo but ends the expedition")
 main.start_planet(0);await process_frame
 seed_expedition=main.surface;freeze(seed_expedition)
 check(seed_expedition.cargo_seeds==[seed_id],"A new bot recovers transport after destruction")
 main.profile.sanctuary.seeds[seed_id]=99
 check(not seed_expedition.extract() and seed_expedition.status_message.contains("SEED STORAGE FULL"),"Full seed storage refuses delivery without silently discarding cargo")
 main.profile.sanctuary.seeds[seed_id]=0
 check(seed_expedition.extract() and main.profile.sanctuary.seeds[seed_id]==1,"Recovered seed can be delivered exactly once")
 var legacy: Dictionary=main.profile.to_dict();legacy.version=4;legacy.erase("surface_transport")
 var legacy_path:=path+"-legacy"
 var file:=FileAccess.open(legacy_path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
 var migrated:=PlayerProfile.new(legacy_path);migrated.load_profile()
 check(not migrated.save_blocked and migrated.surface_transport.animals.is_empty() and migrated.sanctuary.residents.size()==main.profile.sanctuary.residents.size(),"Version 4 saves migrate without losing sanctuary residents")
 check(PlayerProfile.sanitize_transport({"animals":[null,"invalid"],"seeds":[{},"invalid"]}).animals.is_empty(),"Invalid transport data is sanitized safely")
 main.queue_free();await process_frame
 print("CREATURE_LOOP_TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
