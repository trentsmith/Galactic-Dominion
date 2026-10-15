class_name PlanetExpedition
extends Node3D
signal return_requested
var profile: PlayerProfile
var definition: PlanetDefinition
var bot_definition: CollectibleDefinition
var sensitivity:=.0025
var inverted:=false
var world: SurfaceWorld
var bot: SurfaceBot
var fauna: Array[SurfaceFauna]=[]
var specimens: Array[Node3D]=[]
var pending: Dictionary={}
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
 world=SurfaceWorld.new();world.definition=definition;add_child(world)
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
 hud=SurfaceHUD.new();hud.expedition=self;add_child(hud)
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 print("GALACTIC_PLANET_READY planet=%s fauna=%d bot=%s" % [definition.id,fauna.size(),bot_definition.id])
func _physics_process(delta: float) -> void:
 if finished:return
 elapsed+=delta
 if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("scan"):
  scan_nearest(delta)
 else:scan_progress=maxf(0,scan_progress-delta*2)
 if Input.is_action_just_pressed("surface_extract"):extract()
func clear_line(a: Vector3,b: Vector3) -> bool:
 var query:=PhysicsRayQueryParameters3D.create(a+Vector3.UP*.8,b+Vector3.UP*.8,1)
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func record_id(node: Node3D) -> String:
 return "surface.%s.%s" % [definition.id,str(node.get_meta("scan_id",""))]
func surveyed(node: Node3D) -> bool:
 return profile.exploration_records.has(record_id(node)) or pending.has(record_id(node))
func nearest_specimen(unrecorded: bool=true) -> Node3D:
 var nearest: Node3D
 var distance:=INF
 for node in specimens:
  if not is_instance_valid(node) or (node is SurfaceFauna and not node.alive):continue
  if unrecorded and surveyed(node):continue
  var next:=bot.global_position.distance_squared_to(node.global_position)
  if next<distance:distance=next;nearest=node
 return nearest
func scan_nearest(delta: float) -> void:
 var nearest:=nearest_specimen()
 if nearest!=scan_target:scan_progress=0;scan_target=nearest
 if not is_instance_valid(nearest) or bot.global_position.distance_to(nearest.global_position)>12 or not clear_line(bot.global_position,nearest.global_position):
  scan_progress=0;return
 scan_progress+=delta
 if scan_progress>=2:
  survey_specimen(nearest);scan_progress=0;scan_target=null
func survey_specimen(node: Node3D) -> bool:
 if finished or not bot.alive or not is_instance_valid(node) or not node in specimens or (node is SurfaceFauna and not node.alive):return false
 if bot.global_position.distance_to(node.global_position)>12 or not clear_line(bot.global_position,node.global_position) or surveyed(node):return false
 var id:=record_id(node);pending[id]=str(node.get_meta("scan_name","Unknown specimen"))
 status_message="SURVEYED: %s / return to ship to save" % pending[id]
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
 if finished or not bot.alive or bot.position.distance_to(Vector3(0,1.5,0))>10:return false
 for id in pending:profile.record_discovery(id,pending[id])
 var complete_id:="surface.%s.complete" % definition.id
 if survey_count()>=6:profile.record_discovery(complete_id,definition.display_name+" / Complete Survey",definition.survey_reward)
 finish(true)
 return true
func finish(success: bool) -> void:
 if finished:return
 finished=true;bot.set_physics_process(false)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if not success:pending.clear()
 hud.show_result(success)
func toggle_pause() -> void:
 if finished:return
 var paused:=not get_tree().paused
 get_tree().paused=paused
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
 hud.pause_panel.visible=paused

func gravity_multiplier() -> float:
 return .3 if definition.biome=="eldritch" and fmod(elapsed,30)>22 else 1.0
