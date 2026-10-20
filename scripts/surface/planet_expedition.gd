class_name PlanetExpedition
extends Node3D
signal return_requested
signal sanctuary_requested
var landing_stats: ShipStats
var hunt_species := ""
var hunt_target: SurfaceFauna
var hunt_beacon: Label3D
var home_beacon: Label3D
var return_label := "RETURN TO PLANET SELECTOR"
var profile: PlayerProfile
var definition: PlanetDefinition
var bot_definition: CollectibleDefinition
var sensitivity:=.0025
var inverted:=false
var party: CreatureParty
var wilderness: WildernessStream
var world: SurfaceWorld
var bot: SurfaceBot
var fauna: Array[SurfaceFauna]=[]
var specimens: Array[Node3D]=[]
var pending: Dictionary={}
var cargo_animals: Array[String]=[]
var cargo_seeds: Array[String]=[]
var scan_progress:=0.0
var scan_target: Node3D
var elapsed:=0.0
var finished:=false
var status_message:="Explore, survey living fauna and flora, then return to the landing ship."
var hud: SurfaceHUD
var pause_panel: Control
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_PAUSABLE
 if definition==null:definition=PlanetCatalog.WORLDS[0]
 if bot_definition==null:bot_definition=CollectionCatalog.find("crew_pixlet")
 world=SurfaceWorld.new();world.definition=definition;world.landing_stats=landing_stats;add_child(world)
 hunt_species=definition.fauna[0].id
 hunt_beacon=Label3D.new();hunt_beacon.name="HuntBeacon";hunt_beacon.text="TRACKED CREATURE";hunt_beacon.billboard=BaseMaterial3D.BILLBOARD_ENABLED;hunt_beacon.no_depth_test=true;hunt_beacon.font_size=24;hunt_beacon.pixel_size=.012;hunt_beacon.modulate=Color(.5,1,.8);add_child(hunt_beacon)
 home_beacon=Label3D.new();home_beacon.text="LANDING SHIP / E: DELIVER";home_beacon.position=Vector3(0,18,0);home_beacon.billboard=BaseMaterial3D.BILLBOARD_ENABLED;home_beacon.no_depth_test=true;home_beacon.font_size=26;home_beacon.pixel_size=.02;home_beacon.modulate=Color(.5,.85,1);add_child(home_beacon)
 bot=SurfaceBot.new();bot.definition=bot_definition;bot.expedition=self;bot.position=Vector3(0,1.5,6);add_child(bot)
 var rng:=RandomNumberGenerator.new();rng.seed=definition.seed_value
 for species in range(definition.fauna.size()):
  for index in range(10):
   var animal:=SurfaceFauna.new();animal.definition=definition.fauna[species];animal.expedition=self
   var angle:float=TAU*index/10+species*.45
   var distance:float=25+index*5+species*4
   animal.position=Vector3(cos(angle)*distance,0,sin(angle)*distance)
   # First specimens are near the survey trail; predators start farther out.
   if index==0:animal.position=Vector3(-13+species*13,0,-24-species*8)
   animal.position.y=SurfaceWorld.height_at(animal.position.x,animal.position.z)+(4 if definition.aquatic else .5)
   add_child(animal);fauna.append(animal);specimens.append(animal)
 for plant in world.flora_nodes:specimens.append(plant)
 wilderness=WildernessStream.new();wilderness.expedition=self;add_child(wilderness)
 party=CreatureParty.new();party.expedition=self;add_child(party)
 var engineer:=StoryNPC.new();engineer.npc_id="milo";engineer.position=Vector3(6,SurfaceWorld.height_at(6,2)+.2,2);add_child(engineer)
 hud=SurfaceHUD.new();hud.expedition=self;add_child(hud)
 cargo_animals.assign(profile.surface_transport.animals)
 cargo_seeds.assign(profile.surface_transport.seeds)
 if not cargo_animals.is_empty() or not cargo_seeds.is_empty():status_message="TRANSPORT RECOVERED / %d animals, %d seeds / press E here at the ship to deliver" % [cargo_animals.size(),cargo_seeds.size()]
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 if profile.story.accepted and not definition.id in profile.story.visited:
  if not StoryCampaign.visit(profile,definition.id):status_message=profile.story_message
 print("GALACTIC_PLANET_READY planet=%s fauna=%d bot=%s" % [definition.id,fauna.size(),bot_definition.id])
func _physics_process(delta: float) -> void:
 if finished:return
 home_beacon.visible=not at_landing_ship()
 home_beacon.text="LANDING SHIP / %dm / E: DELIVER" % int(bot.position.length())
 var controls:=bot.read_controls()
 var tracked:=tracked_animal()
 hunt_beacon.visible=is_instance_valid(tracked)
 if is_instance_valid(tracked):hunt_beacon.global_position=tracked.global_position+Vector3.UP*4
 if bool(controls.get("next_hunt",false)):cycle_hunt()
 if bool(controls.get("next_bot",false)):cycle_bot()
 if bool(controls.get("deploy_creature",false)):party.deploy()
 if bool(controls.get("cycle_creature",false)):party.cycle()
 if bool(controls.get("attack_creature",false)):party.attack()
 if bool(controls.get("recall_creatures",false)):party.recall()
 elapsed+=delta
 if bool(controls.get("scan",false)):
  scan_nearest(delta)
 else:scan_progress=maxf(0,scan_progress-delta*2)
 if bool(controls.get("extract",false)):extract()
 if bool(controls.get("capture",false)):capture_nearest()
 if bool(controls.get("gather",false)):gather_nearest()
func clear_line(a: Vector3,b: Vector3) -> bool:
 var query:=PhysicsRayQueryParameters3D.create(a+Vector3.UP*.8,b+Vector3.UP*.8,1)
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func record_id(node: Node3D) -> String:
 return "surface.%s.%s" % [definition.id,str(node.get_meta("scan_id",""))]
func surveyed(node: Node3D) -> bool:
 return profile.exploration_records.has(record_id(node)) or pending.has(record_id(node))
func nearest_specimen(unrecorded: bool=true) -> Node3D:
 var tracked:=tracked_animal()
 if unrecorded and is_instance_valid(tracked) and not surveyed(tracked) and bot.position.distance_to(tracked.position)<=12:return tracked
 var nearest: Node3D
 var distance:=INF
 for node in specimens:
  if not is_instance_valid(node) or (node is SurfaceFauna and not node.alive):continue
  if unrecorded and surveyed(node):continue
  var next:=bot.global_position.distance_squared_to(node.global_position)
  if next<distance:distance=next;nearest=node
 return nearest
func scan_nearest(delta: float) -> void:
 if not action_available("SCAN"):return
 # A moving neighbor must not steal an in-progress scan.
 var nearest: Node3D=scan_target if scan_eligible(scan_target) else null
 if nearest==null:
  var tracked:=tracked_animal()
  if scan_eligible(tracked):nearest=tracked
 if nearest==null:
  var distance:=INF
  for specimen in specimens:
   if not scan_eligible(specimen):continue
   var next:=bot.global_position.distance_squared_to(specimen.global_position)
   if next<distance:distance=next;nearest=specimen
 if nearest!=scan_target:scan_progress=0;scan_target=nearest
 if not is_instance_valid(nearest) or bot.global_position.distance_to(nearest.global_position)>12 or not clear_line(bot.global_position,nearest.global_position):
  scan_progress=0
  var obstructed:=nearest_specimen()
  var known_hunt:=tracked_animal()
  if is_instance_valid(known_hunt) and surveyed(known_hunt) and bot.position.distance_to(known_hunt.position)<=12:status_message="SPECIES ALREADY SCANNED / "+capture_hint(known_hunt)
  elif is_instance_valid(obstructed) and bot.global_position.distance_to(obstructed.global_position)<=12 and not clear_line(bot.global_position,obstructed.global_position):status_message="SCAN BLOCKED / move around the obstacle for a clear view"
  elif is_instance_valid(obstructed):status_message="SCAN / approach %s within 12m, then hold G for 2 seconds" % str(obstructed.get_meta("scan_name","specimen"))
  else:status_message="SCAN / nearby species already surveyed; T to track another, or C to capture scanned fauna"
  return
 if nearest is SurfaceFauna and nearest.definition.damage<=0:nearest.scan_interest_remaining=.35
 scan_progress+=delta
 if scan_progress>=2:
  survey_specimen(nearest);scan_progress=0;scan_target=null
func survey_specimen(node: Node3D) -> bool:
 if finished or not bot.alive or not is_instance_valid(node) or not node in specimens or (node is SurfaceFauna and not node.alive):return false
 if bot.global_position.distance_to(node.global_position)>12 or not clear_line(bot.global_position,node.global_position) or surveyed(node):return false
 var id:=record_id(node);pending[id]=str(node.get_meta("scan_name","Unknown specimen"))
 if node is SurfaceFauna and node.definition.damage<=0:node.scan_interest_remaining=3.0
 status_message="SURVEYED: %s / C within 8m to capture fauna; E at ship saves surveys" % pending[id]
 SpaceEffects.burst(self,node.global_position+Vector3.UP,definition.glow_color,1.0)
 return true
func survey_count() -> int:
 var total:=0
 for item in definition.fauna:
  var id:="surface.%s.fauna.%s" % [definition.id,item.id]
  if pending.has(id) or profile.exploration_records.has(id):total+=1
 for i in range(definition.flora.size()):
  var id:="surface.%s.flora.%d" % [definition.id,i]
  if pending.has(id) or profile.exploration_records.has(id):total+=1
 return total
func extract() -> bool:
 if not action_available("DELIVERY"):return false
 if bot.position.distance_to(Vector3(0,1.5,0))>10:
  status_message="DELIVERY / return within 10m of the landing ship (%dm away), then E" % int(bot.position.distance_to(Vector3(0,1.5,0)));return false
 if profile.sanctuary.residents.size()+cargo_animals.size()>48:
  status_message="SANCTUARY FULL / make room for %d creatures, then retry E; transport retained" % cargo_animals.size();return false
 for seed in cargo_seeds:
  if int(profile.sanctuary.seeds.get(seed,0))>=99:
   status_message="SEED STORAGE FULL / plant existing seeds in sanctuary, then retry E; cargo retained";return false
 var before_sanctuary:=profile.sanctuary.duplicate(true)
 var before_records:=profile.exploration_records.duplicate(true)
 var before_inventory:=profile.inventory.duplicate(true)
 var before_salvage:=profile.salvage
 var before_transport:=profile.surface_transport.duplicate(true)
 var before_story:=profile.story.duplicate(true)
 SanctuaryState.intake(profile.sanctuary,cargo_animals,cargo_seeds)
 for id in pending:
  if not profile.exploration_records.has(id):
   profile.exploration_records[id]={"name":pending[id],"discovered_at":int(Time.get_unix_time_from_system())};profile.salvage+=25
 var complete_id:="surface.%s.complete" % definition.id
 if survey_count()>=6 and not profile.exploration_records.has(complete_id):
  profile.exploration_records[complete_id]={"name":definition.display_name+" / Complete Survey","discovered_at":int(Time.get_unix_time_from_system())}
  profile.salvage+=25;profile.acquire(definition.survey_reward,"Galactic exploration")
 profile.surface_transport={"animals":[],"seeds":[]}
 if not cargo_animals.is_empty() and profile.story.accepted:profile.story.rescued=true
 if not profile.save_profile():
  profile.surface_transport=before_transport
  profile.story=before_story
  profile.sanctuary=before_sanctuary;profile.exploration_records=before_records;profile.inventory=before_inventory;profile.salvage=before_salvage
  status_message="DELIVERY NOT SAVED / "+profile.save_error+" / cargo retained; retry E"
  return false
 profile.changed.emit()
 finish(true)
 return true
func finish(success: bool) -> void:
 if finished:return
 finished=true;bot.set_physics_process(false)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if not success:
  pending.clear();cargo_animals.clear();cargo_seeds.clear()
 hud.show_result(success)
func toggle_pause() -> void:
 if finished:return
 var paused:=not get_tree().paused
 get_tree().paused=paused
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
 hud.refresh_choices()
 hud.pause_panel.visible=paused

func gravity_multiplier() -> float:
 return .3 if definition.biome=="eldritch" and fmod(elapsed,30)>22 else 1.0

func capture_nearest() -> bool:
 if not action_available("CAPTURE"):return false
 if cargo_animals.size()>=4:
  status_message="TRANSPORT FULL / 4 of 4 animals / E at the landing ship to deliver";return false
 if profile.sanctuary.residents.size()+cargo_animals.size()>=48:
  status_message="SANCTUARY FULL / 48 residents including transport; make room before capturing";return false
 if profile.sanctuary.materials.capture_pod<1:
  status_message="NO CAPTURE PODS / at the ship: Esc, craft a pod with 1 ore + 1 bloom";return false
 var candidate:=capture_target()
 if not is_instance_valid(candidate):
  var tracked := tracked_animal()
  if is_instance_valid(tracked) and bot.position.distance_to(tracked.position)>8:
   status_message="CAPTURE / approach %s within 8m (%dm away)" % [tracked.definition.display_name,int(bot.position.distance_to(tracked.position))]
  else:status_message="CAPTURE / track a living animal with T and approach within 8m"
  for animal in fauna:
   if is_instance_valid(animal) and animal.alive and bot.position.distance_to(animal.position)<=8 and not clear_line(bot.position,animal.position):
    status_message="CAPTURE BLOCKED / move around the obstacle for a clear view";break
  return false
 if not surveyed(candidate):status_message="SCAN THIS SPECIES WITH G BEFORE CAPTURE";return false
 if candidate.definition.damage>0 and candidate.health>candidate.definition.health*.5:
  status_message="DANGEROUS FAUNA / weaken to 50% health or less before capture";return false
 profile.sanctuary.materials.capture_pod-=1
 var next_animals:=cargo_animals.duplicate()
 next_animals.append(candidate.definition.id)
 if not save_transport(next_animals,cargo_seeds):
  profile.sanctuary.materials.capture_pod+=1;return false
 cargo_animals.assign(next_animals)
 if hunt_target==candidate:hunt_target=null
 if is_instance_valid(party) and party.target==candidate:party.target=null
 SpaceEffects.burst(self,candidate.global_position,Color(.3,1,.7),1.2)
 candidate.alive=false;candidate.visible=false;candidate.collision_layer=0;candidate.respawn_timer=30;candidate.velocity=Vector3.ZERO
 status_message="SECURED IN TRANSPORT: %s / E at the landing ship delivers it to sanctuary" % candidate.definition.display_name
 return true
func gather_nearest() -> bool:
 if not action_available("SEED COLLECTION"):return false
 var candidate: Node3D
 var distance:=7.0
 for plant in world.flora_nodes:
  var next:=bot.position.distance_to(plant.position)
  if next<distance and clear_line(bot.position,plant.position):distance=next;candidate=plant
 if not is_instance_valid(candidate):status_message="APPROACH A SURVEY PLANT WITHIN 7m";return false
 if not surveyed(candidate):status_message="SCAN THIS FLORA WITH G BEFORE COLLECTING A SEED";return false
 var id:="%s.%s" % [definition.id,str(candidate.get_meta("scan_id")).trim_prefix("flora.")]
 if cargo_seeds.has(id):status_message="ONE SEED PER FLORA TYPE PER EXPEDITION";return false
 var next_seeds:=cargo_seeds.duplicate();next_seeds.append(id)
 if not save_transport(cargo_animals,next_seeds):return false
 cargo_seeds.assign(next_seeds);status_message="SEED COLLECTED / extract to plant it in your sanctuary";return true

func at_landing_ship() -> bool:
 return is_instance_valid(bot) and bot.alive and bot.position.distance_to(Vector3(0,1.5,0))<10

func available_bot_choices() -> Array[CollectibleDefinition]:
 var choices:=PlanetCatalog.available_bots(profile)
 if choices.is_empty():choices.append(CollectionCatalog.find("crew_pixlet"))
 return choices

func switch_bot(id: String) -> bool:
 if finished or not at_landing_ship():
  status_message="BOT SWITCH / return to the landing ship first";return false
 var chosen: CollectibleDefinition
 for item in available_bot_choices():
  if item.id==id:chosen=item
 if chosen==null:status_message="BOT UNAVAILABLE / choose an owned bot or the loaner";return false
 bot_definition=chosen;bot.switch_definition(chosen)
 status_message="ACTIVE BOT / "+chosen.display_name+" / hull, energy and cargo preserved"
 return true

func cycle_bot() -> void:
 var choices:=available_bot_choices()
 for index in range(choices.size()):
  if choices[index].id==bot_definition.id:
   switch_bot(choices[(index+1)%choices.size()].id);return
 switch_bot(choices[0].id)

func select_hunt(id: String) -> bool:
 for species in definition.fauna:
  if species.id==id:
   hunt_species=id;hunt_target=null;scan_progress=0;scan_target=null
   status_message="TRACKING / "+species.display_name+" / scan, capture, return to ship"
   return true
 status_message="HUNT UNAVAILABLE / choose a species on this planet"
 return false

func cycle_hunt() -> void:
 for index in range(definition.fauna.size()):
  if definition.fauna[index].id==hunt_species:
   select_hunt(definition.fauna[(index+1)%definition.fauna.size()].id);return

func tracked_animal() -> SurfaceFauna:
 if is_instance_valid(hunt_target) and hunt_target.alive and hunt_target.definition.id==hunt_species:return hunt_target
 var best: SurfaceFauna
 var distance:=INF
 for animal in fauna:
  if not is_instance_valid(animal) or not animal.alive or animal.definition.id!=hunt_species:continue
  var next:=bot.position.distance_squared_to(animal.position)
  if next<distance:distance=next;best=animal
 hunt_target=best
 return best

func capture_ready(animal: SurfaceFauna) -> bool:
 return is_instance_valid(animal) and animal.alive and surveyed(animal) and (animal.definition.damage<=0 or animal.health<=animal.definition.health*.5)

func capture_target() -> SurfaceFauna:
 # Prefer the tracked animal when ready; never let an ineligible hunt block
 # another scanned creature already inside the capture radius.
 var tracked:=tracked_animal()
 if capture_ready(tracked) and bot.position.distance_to(tracked.position)<=8.0 and clear_line(bot.position,tracked.position):return tracked
 var ready: SurfaceFauna
 var nearest: SurfaceFauna
 var distance:=8.001
 var ready_distance:=8.001
 for animal in fauna:
  if not is_instance_valid(animal) or not animal.alive:continue
  var next:=bot.position.distance_to(animal.position)
  if next>8.0 or not clear_line(bot.position,animal.position):continue
  if next<distance:distance=next;nearest=animal
  if capture_ready(animal) and next<ready_distance:ready_distance=next;ready=animal
 return ready if is_instance_valid(ready) else nearest

func scan_eligible(node: Node3D) -> bool:
 return is_instance_valid(node) and node in specimens and not surveyed(node) and not (node is SurfaceFauna and not node.alive) and bot.global_position.distance_to(node.global_position)<=12 and clear_line(bot.global_position,node.global_position)

func craft_capture_pod() -> bool:
 if finished or not at_landing_ship():status_message="POD WORKSHOP / return to the landing ship";return false
 var before:=profile.sanctuary.duplicate(true)
 if not SanctuaryState.craft(profile.sanctuary,"capture_pod"):
  status_message="POD WORKSHOP / requires 1 ore + 1 bloom";return false
 if not profile.save_profile():
  profile.sanctuary=before;status_message=profile.save_error;return false
 status_message="CAPTURE POD READY / "+str(profile.sanctuary.materials.capture_pod)+" available"
 return true

func action_available(action: String) -> bool:
 if finished:status_message=action+" UNAVAILABLE / expedition ended; start another expedition";return false
 if not is_instance_valid(bot) or not bot.alive:status_message=action+" UNAVAILABLE / bot disabled; redeploy from the planet selector";return false
 return true

func save_transport(animals: Array,seeds: Array) -> bool:
 var before:=profile.surface_transport.duplicate(true)
 profile.surface_transport={"animals":animals.duplicate(),"seeds":seeds.duplicate()}
 if not profile.save_profile():
  profile.surface_transport=before
  status_message="TRANSPORT SAVE FAILED / "+profile.save_error+" / nothing consumed or captured; retry when saving works"
  return false
 return true

func hunt_guidance() -> String:
 var animal:=tracked_animal()
 if not is_instance_valid(animal):return "FIND / T chooses another species; explore the wilderness"
 var distance:=bot.position.distance_to(animal.position)
 if not surveyed(animal):return "SCAN / within 12m, clear view, hold G for 2 seconds (%dm)" % int(distance)
 if animal.definition.damage>0 and animal.health>animal.definition.health*.5:return "WEAKEN / LMB stun, or N select · R deploy · V attack; reduce health to 50%"
 return "CAPTURE / C within 8m with a clear view; E at the ship delivers cargo"

func capture_hint(animal: SurfaceFauna) -> String:
 if cargo_animals.size()>=4:return "TRANSPORT FULL / E at ship to deliver 4 animals"
 if profile.sanctuary.residents.size()+cargo_animals.size()>=48:return "SANCTUARY LIMIT / 48 residents including transport"
 if profile.sanctuary.materials.capture_pod<1:return "NO PODS / at ship: Esc, craft with 1 ore + 1 bloom"
 if not is_instance_valid(animal):return "T: track wildlife; approach within 8m"
 if not surveyed(animal):return "SCAN WITH G FIRST / hold 2 seconds within 12m"
 if not capture_ready(animal):return "WEAKEN TO 50% / LMB stun or R deploy + V attack"
 return "READY / C captures %s; E at ship delivers" % animal.definition.display_name

func home_guidance() -> String:
 var distance:=bot.position.distance_to(Vector3(0,1.5,0))
 if distance<=10:return "AT LANDING SHIP / E delivers cargo to sanctuary"
 var local:=bot.camera.global_basis.inverse()*(Vector3(0,1.5,0)-bot.global_position)
 var direction:="BEHIND / TURN AROUND" if local.z>absf(local.x) else "LEFT" if local.x < -absf(local.z)*.4 else "RIGHT" if local.x>absf(local.z)*.4 else "AHEAD"
 return "LANDING SHIP %s / %dm / E within 10m" % [direction,int(distance)]
