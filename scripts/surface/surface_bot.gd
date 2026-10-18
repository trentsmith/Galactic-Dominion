class_name SurfaceBot
extends CharacterBody3D
var expedition: PlanetExpedition
var definition: CollectibleDefinition
var visual: AlienVisual
var hull:=60.0
var shield:=35.0
var stamina:=100.0
var hit_delay:=0.0
var cooldown:=0.0
var yaw:=0.0
var pitch:=0.0
var camera: Camera3D
var shots:=0
var alive:=true
# Allows deterministic controller tests and future alternate input devices.
var input_provider: Callable
func _ready() -> void:
 collision_layer=2;collision_mask=5
 var shape:=CapsuleShape3D.new();shape.radius=.65;shape.height=1.6
 var collision:=CollisionShape3D.new();collision.shape=shape;add_child(collision)
 visual=AlienVisual.new();visual.definition=definition;visual.scale=Vector3.ONE*.57;add_child(visual)
 camera=Camera3D.new();camera.top_level=true;camera.fov=62;add_child(camera);camera.current=true
 update_camera(1)
func _unhandled_input(event: InputEvent) -> void:
 if alive and not expedition.finished and not get_tree().paused and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
  Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;get_viewport().set_input_as_handled();return
 if not alive or Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:return
 if event is InputEventMouseMotion:
  yaw-=event.relative.x*expedition.sensitivity
  pitch=clampf(pitch+event.relative.y*expedition.sensitivity*( -1 if expedition.inverted else 1),-.9,.9)
func _physics_process(delta: float) -> void:
 if not alive:return
 cooldown=maxf(0,cooldown-delta);hit_delay=maxf(0,hit_delay-delta)
 if hit_delay<=0:shield=minf(35,shield+delta*6)
 var controls:=read_controls()
 var input: Vector2=controls.get("move",Vector2.ZERO)
 var direction:=Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
 var sprint:=bool(controls.get("sprint",false)) and stamina>0 and direction.length()>.1
 stamina=clampf(stamina+delta*(-24 if sprint else 16),0,100)
 var speed:=15.0 if sprint else 9.0
 velocity.x=move_toward(velocity.x,direction.x*speed,delta*32)
 velocity.z=move_toward(velocity.z,direction.z*speed,delta*32)
 if expedition.definition.aquatic:
  var vertical:float=float(controls.get("vertical",0))
  velocity.y=move_toward(velocity.y,vertical*speed*.75,delta*20)
 else:
  velocity.y-=20*expedition.gravity_multiplier()*delta
  if is_on_floor() and bool(controls.get("jump",false)):velocity.y=8 if expedition.gravity_multiplier()>.5 else 12
 move_and_slide()
 var flat:=Vector2(position.x,position.z).limit_length(SurfaceWorld.RADIUS)
 position.x=flat.x;position.z=flat.y
 if expedition.definition.aquatic:position.y=clampf(position.y,SurfaceWorld.height_at(position.x,position.z)+1.2,24)
 visual.rotation.y=lerp_angle(visual.rotation.y,yaw,delta*12)
 if bool(controls.get("fire",false)):fire()
 update_camera(delta)
func update_camera(delta: float) -> void:
 var desired:=global_position+Basis(Vector3.UP,yaw)*Vector3(0,3.5+pitch*4,9)
 var origin:=global_position+Vector3.UP*1.5
 if is_inside_tree():
  var query:=PhysicsRayQueryParameters3D.create(origin,desired,1)
  var hit:=get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty():desired=hit.position+hit.normal*.4
 camera.global_position=camera.global_position.lerp(desired,minf(1,delta*12))
 camera.look_at(global_position+Vector3.UP*1.2+aim_direction()*10,Vector3.UP)
func hurt(amount: float) -> void:
 if not alive or amount<=0 or Vector2(position.x,position.z).length()<10:return
 var absorbed:=minf(shield,amount);shield-=absorbed;hull=maxf(0,hull-(amount-absorbed));hit_delay=5
 SpaceEffects.burst(get_parent(),global_position,Color(1,.22,.16),.7)
 if hull<=0:
  alive=false;visual.visible=false;expedition.finish(false)
func fire() -> bool:
 if not alive or cooldown>0 or expedition.finished:return false
 cooldown=.35;shots+=1
 var heading:=aim_direction()
 var target: SurfaceFauna
 var score:=.63
 for animal in expedition.fauna:
  if not is_instance_valid(animal) or not animal.alive:continue
  var offset:=animal.global_position-global_position
  if offset.length()>42:continue
  var alignment:=heading.dot(offset.normalized())
  if alignment>score and expedition.clear_line(global_position,animal.global_position):
   score=alignment;target=animal
 var end:=global_position+heading*16
 if is_instance_valid(target):end=target.global_position;target.hit(16,true)
 var curve:=Curve3D.new();curve.bake_interval=2;curve.add_point(global_position);curve.add_point(end)
 var beam:=Node3D.new();get_parent().add_child(beam)
 SpaceModelFactory.tube(beam,curve,Vector3.ZERO,.04,definition.color.lightened(.3),true)
 var tween:=beam.create_tween();tween.tween_interval(.09);tween.tween_callback(beam.queue_free)
 return true

func read_controls() -> Dictionary:
 if input_provider.is_valid():return input_provider.call()
 if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:return {}
 return {"move":Input.get_vector("strafe_left","strafe_right","forward","reverse"),"sprint":Input.is_action_pressed("boost"),"vertical":float(Input.is_action_pressed("up"))-float(Input.is_action_pressed("down")),"jump":Input.is_action_just_pressed("up"),"fire":Input.is_action_pressed("laser"),"scan":Input.is_action_pressed("scan"),"capture":Input.is_action_just_pressed("surface_capture"),"extract":Input.is_action_just_pressed("surface_extract"),"gather":Input.is_action_just_pressed("surface_gather"),"next_hunt":Input.is_action_just_pressed("surface_next_hunt"),"next_bot":Input.is_action_just_pressed("surface_next_bot")}

func aim_direction() -> Vector3:
 return Basis(Vector3.UP,yaw)*Vector3(0,-sin(pitch),-cos(pitch))

func switch_definition(chosen: CollectibleDefinition) -> void:
 definition=chosen
 if is_instance_valid(visual):remove_child(visual);visual.queue_free()
 visual=AlienVisual.new();visual.definition=chosen;visual.scale=Vector3.ONE*.57;visual.rotation.y=yaw;add_child(visual)
