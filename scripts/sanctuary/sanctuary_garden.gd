class_name SanctuaryGarden
extends Node3D
signal back_requested
var profile: PlayerProfile
var state: Dictionary
var camera: Camera3D
var scenery: Node3D
var residents_root: Node3D
var actors: Dictionary={}
var resident_eyes: Dictionary={}
var plant_actors: Array[Node3D]=[]
var build_mode:=""
var move_id:=0
var selected_resident:=1
var selected_habitat:=1
var clock:=0.0
var save_clock:=0.0
var refresh_clock:=0.0
var travel_remaining:=0.0
var camera_yaw:=0.0
var focus_resident:=false
var care_bounce: Dictionary={}
var panel: SanctuaryPanel
var grid: Node3D
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_PAUSABLE
 state=profile.sanctuary
 var background:=SpaceEnvironmentArt.environment(9.8);add_child(background)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-48,-30,0);light.light_energy=1.1;add_child(light)
 camera=Camera3D.new();camera.fov=56;camera.h_offset=9;add_child(camera);camera.current=true
 residents_root=Node3D.new();add_child(residents_root)
 var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;floor_body.collision_mask=0
 var floor_shape:=BoxShape3D.new();floor_shape.size=Vector3(55,.2,55)
 var collision:=CollisionShape3D.new();collision.shape=floor_shape;floor_body.add_child(collision);add_child(floor_body)
 panel=SanctuaryPanel.new();panel.garden=self;add_child(panel)
 refresh_world();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 print("GALACTIC_SANCTUARY_READY residents=%d habitats=%d flight=%d" % [state.residents.size(),state.habitats.size(),state.flight_stage])
func refresh_world() -> void:
 if is_instance_valid(scenery):remove_child(scenery);scenery.queue_free()
 scenery=Node3D.new();add_child(scenery)
 SanctuaryArt.island(scenery,state.palette)
 for habitat in state.habitats:
  var model:=SanctuaryArt.habitat(scenery,habitat.kind,habitat.level)
  model.position=Vector3(habitat.x*9,0,habitat.z*9)
 var hub:=Node3D.new();hub.scale=Vector3.ONE*1.1;hub.position=Vector3(0,2,0);scenery.add_child(hub)
 SpaceModelFactory.station(hub,Color(.4,.9,1))
 for i in range(state.flight_stage*2):
  var a:=TAU*i/maxi(1,state.flight_stage*2)
  var engine:=SpaceModelFactory.pod(scenery,Vector3(cos(a)*20,-4,sin(a)*20),2.0,Color(.3,.85,1));engine.rotation.x=PI/2
 grid=Node3D.new();scenery.add_child(grid)
 for x in range(-2,3):
  for z in range(-2,3):
   if x==0 and z==0:continue
   var ring:=SpaceModelFactory.ring(grid,Vector3(x*9,.1,z*9),3.8,.025,Color(.7,.95,1),"BuildPlot",true);ring.rotation=Vector3.ZERO
 grid.visible=not build_mode.is_empty() or move_id>0
 for child in residents_root.get_children():residents_root.remove_child(child);child.queue_free()
 actors.clear();resident_eyes.clear()
 for resident in state.residents:
  var actor:=SanctuaryFormArt.creature(residents_root,SanctuaryState.fauna(resident.species),resident.form_stage);actors[resident.id]=actor;resident_eyes[resident.id]=FaunaFace.eyes(actor)
 plant_actors.clear()
 var slots: Array[Vector3]=[]
 for habitat in state.habitats:
  if habitat.kind!="planter":continue
  for slot in range(habitat.level*3):slots.append(Vector3(habitat.x*9+(slot%2*2-1)*1.1,.8,habitat.z*9-1.4+floorf(float(slot)/2)*1.1))
 for index in range(state.plants.size()):
  var plant: Dictionary=state.plants[index]
  var at: Vector3=slots[index] if index<slots.size() else Vector3(0,.8,18)
  var id: String=plant.id
  var model: Node3D
  if id=="starter.berry":
   model=Node3D.new();scenery.add_child(model);model.position=at
   SurfaceArt.ball(model,Vector3.ZERO,Vector3(.4,.7,.4),Color(.35,.85,.5))
   SurfaceArt.ball(model,Vector3.UP*.7,Vector3(.25,.25,.25),Color(1,.6,.75),true)
  else:
   var biome:="vampire" if id.begins_with("varkhoss.") else "alien" if id.begins_with("viridia.") else "eldritch"
   model=SurfaceArt.plant(scenery,biome,at,Color(.35,.65,.5),Color(.65,.9,.8),int(id.get_slice(".",1)))
  plant_actors.append(model)
 var sky:=get_child(0) as WorldEnvironment
 sky.environment.sky.sky_material.set_shader_parameter("moon_palette",1.0 if state.location==2 else 0.0)
 sky.environment.sky.sky_material.set_shader_parameter("comet_palette",1.0 if state.location==0 else 0.0)
 panel.refresh_lists()
func _process(delta: float) -> void:
 clock+=delta;save_clock+=delta;refresh_clock+=delta
 SanctuaryState.tick(state,delta)
 if travel_remaining>0:travel_remaining=maxf(0,travel_remaining-delta)
 scenery.position.y=sin((5-travel_remaining)/5*PI)*5 if travel_remaining>0 else 0
 residents_root.position.y=scenery.position.y
 var orbit:=Basis(Vector3.UP,camera_yaw)*Vector3(37,36,43)
 if focus_resident and is_instance_valid(actors.get(selected_resident)):
  var target: Vector3=actors[selected_resident].global_position+Vector3.UP
  camera.h_offset=1.5;camera.position=target+Basis(Vector3.UP,camera_yaw)*Vector3(8,6,10);camera.look_at(target)
 else:
  camera.h_offset=9;camera.position=orbit+Vector3(0,sin(clock*3)*.15 if travel_remaining>0 else 0,0)
  camera.look_at(Vector3(4,0,0))
 for resident in state.residents:
  var actor: Node3D=actors.get(resident.id)
  if not is_instance_valid(actor):continue
  FaunaFace.blink(resident_eyes[resident.id],clock+float(resident.id)*.47)
  var center:=Vector3(0,1,16)
  for habitat in state.habitats:
   if habitat.id==resident.habitat:center=Vector3(habitat.x*9,.5,habitat.z*9)
  var phase: float=clock*.35+resident.id*2.1
  var floating: bool=SanctuaryState.habitat_for(resident.species)=="reef" or resident.species in ["duskbat","riftwisp"]
  actor.position=center+Vector3(cos(phase)*1.8,1.0+sin(phase*2)*.3 if floating else 0,sin(phase)*1.8)
  actor.rotation.y=-phase-PI/2
  var bounce: float=maxf(0,float(care_bounce.get(resident.id,0))-delta);care_bounce[resident.id]=bounce
  actor.position.y+=absf(sin(bounce*PI*4))*.5 if bounce>0 else 0
  actor.scale=Vector3.ONE*(.8+resident.growth*.006)*(1+resident.form_stage*.08)
 for index in range(plant_actors.size()):
  plant_actors[index].scale=Vector3.ONE*(.18+float(state.plants[index].growth)*.003)
 if refresh_clock>=.5:refresh_clock=0;panel.refresh_status()
 if save_clock>=10:save_clock=0;profile.save_profile()
func _unhandled_input(event: InputEvent) -> void:
 if travel_remaining>0:return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):camera_yaw-=event.relative.x*.006
 if event is InputEventMouseButton and event.pressed:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP:camera.fov=clampf(camera.fov-2,35,68)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera.fov=clampf(camera.fov+2,35,68)
  elif event.button_index==MOUSE_BUTTON_LEFT:
   var origin:=camera.project_ray_origin(event.position);var end:=origin+camera.project_ray_normal(event.position)*200
   var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,end,1))
   if hit.is_empty():return
   var x:=roundi(hit.position.x/9);var z:=roundi(hit.position.z/9)
   if not build_mode.is_empty():
    var success:=SanctuaryState.build(state,build_mode,x,z);panel.message="Habitat built" if success else "Cannot build here or insufficient materials"
    if success:build_mode="";save_and_refresh()
   elif move_id>0:
    var success:=SanctuaryState.move_habitat(state,move_id,x,z);panel.message="Habitat moved" if success else "Choose an empty plot"
    if success:move_id=0;save_and_refresh()
   else:
    for habitat in state.habitats:
     if habitat.x==x and habitat.z==z:selected_habitat=habitat.id;panel.refresh_lists()
func save_and_refresh() -> void:
 profile.save_profile();refresh_world()
func close() -> void:
 profile.save_profile();back_requested.emit()
func _exit_tree() -> void:
 if profile!=null and not state.is_empty():profile.save_profile()
func do_launch(destination: int) -> bool:
 if travel_remaining>0 or not SanctuaryState.launch(state,destination):return false
 travel_remaining=5;panel.message="SANCTUARY IN FLIGHT / arriving in the selected orbit";save_and_refresh();return true

func care_for_resident(action: String) -> bool:
 var success:=SanctuaryState.care(state,selected_resident,action)
 if not success:return false
 care_bounce[selected_resident]=1.0
 var actor: Node3D=actors.get(selected_resident)
 if is_instance_valid(actor):
  SpaceEffects.burst(self,actor.global_position+Vector3.UP,Color(1,.5,.8),.5)
  var bubble:=Label3D.new();bubble.text="JOY +";bubble.font_size=40;bubble.pixel_size=.025;bubble.billboard=BaseMaterial3D.BILLBOARD_ENABLED;bubble.modulate=Color(1,.7,.9);add_child(bubble)
  bubble.global_position=actor.global_position+Vector3.UP*2
  var tween:=bubble.create_tween();tween.tween_property(bubble,"position:y",bubble.position.y+1.5,1.0);tween.tween_callback(bubble.queue_free)
 profile.save_profile();return true

func awaken_resident() -> bool:
 var previous: Node3D=actors.get(selected_resident)
 var previous_position: Vector3=previous.position if is_instance_valid(previous) else Vector3.ZERO
 var success:=SanctuaryState.awaken(state,selected_resident)
 if not success:panel.message="More friendship, love, growth or happy care is needed";panel.refresh_status();return false
 var new_name:=""
 for resident in state.residents:
  if resident.id==selected_resident:new_name=SanctuaryForms.form_name(resident.species,resident.form_stage)
 panel.message="A NEW BOND / "+new_name
 save_and_refresh();care_bounce[selected_resident]=2.0
 var actor: Node3D=actors.get(selected_resident)
 if is_instance_valid(actor):
  actor.position=previous_position
  SpaceEffects.burst(self,actor.global_position+Vector3.UP,Color(1,.7,.9),2.0)
 return true
