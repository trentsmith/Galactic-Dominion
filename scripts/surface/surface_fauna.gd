class_name SurfaceFauna
extends CharacterBody3D
var expedition: PlanetExpedition
var definition: FaunaDefinition
var home:=Vector3.ZERO
var destination:=Vector3.ZERO
var visual: Node3D
var health:=0.0
var alive:=true
var state:="roam"
var clock:=0.0
var decide_timer:=0.0
var attack_timer:=0.0
var alert:=0.0
var respawn_timer:=0.0
var rng:=RandomNumberGenerator.new()
var marker: Label3D
func _ready() -> void:
 home=position;rng.seed=definition.id.hash()+int(position.x*17+position.z*23)
 health=definition.health;collision_layer=4;collision_mask=7
 var shape:=SphereShape3D.new();shape.radius=.85*definition.size
 var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=.7;add_child(collision)
 visual=SurfaceArt.creature(self,definition);visual.scale=Vector3.ONE*definition.size
 set_meta("scan_id","fauna."+definition.id);set_meta("scan_name",definition.display_name)
 marker=Label3D.new();marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.position=Vector3(0,2.8,0);marker.font_size=28;marker.pixel_size=.009
 marker.modulate=Color(1,.5,.4) if definition.damage>0 else Color(.6,1,.8);add_child(marker)
 destination=home
func _physics_process(delta: float) -> void:
 clock+=delta
 if not alive:
  respawn_timer-=delta
  if respawn_timer<=0 and expedition.bot.global_position.distance_to(home)>18:
   position=home;alive=true;visible=true;collision_layer=4;health=definition.health;alert=0
  return
 if expedition.finished:return
 attack_timer=maxf(0,attack_timer-delta);alert=maxf(0,alert-delta);decide_timer-=delta
 var bot:=expedition.bot
 var distance:=global_position.distance_to(bot.global_position)
 var predator:=definition.damage>0
 marker.visible=distance<24
 marker.text=definition.display_name+(" / DANGER" if predator else " / PASSIVE")+"\n%d / %d" % [int(health),int(definition.health)]
 if decide_timer<=0:
  decide_timer=.25
  if Vector2(position.x,position.z).length()<13:
   state="flee";destination=Vector3(position.x,0,position.z).normalized()*25
  elif bot.alive and predator and (distance<22 or alert>0) and Vector2(bot.position.x,bot.position.z).length()>11 and expedition.clear_line(global_position,bot.global_position):
   state="chase";destination=bot.position
  elif bot.alive and not predator and (distance<9 or alert>0):
   state="flee";destination=position+(position-bot.position).normalized()*12
  elif position.distance_to(destination)<3 or state!="roam":
   state="roam";destination=home+Vector3(rng.randf_range(-14,14),0,rng.randf_range(-14,14))
  var flat:=Vector2(destination.x,destination.z).limit_length(102);destination.x=flat.x;destination.z=flat.y
 var direction:=Vector3(destination.x-position.x,0,destination.z-position.z).normalized()
 var obstacle_query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,global_position+Vector3.UP+direction*2.8,1)
 var obstacle:=get_world_3d().direct_space_state.intersect_ray(obstacle_query)
 if not obstacle.is_empty():direction=direction.rotated(Vector3.UP,1.3)
 var speed:=definition.speed*(1.0 if state in ["chase","flee"] else .5)
 velocity.x=move_toward(velocity.x,direction.x*speed,delta*15);velocity.z=move_toward(velocity.z,direction.z*speed,delta*15)
 var floating:=definition.body_style in ["bat","manta","wisp","jelly","fish","shark"]
 if floating:
  var altitude:=SurfaceWorld.height_at(position.x,position.z)+(3.5 if not expedition.definition.aquatic else 4.5)+sin(clock*1.3)*.6
  if state=="chase":altitude=bot.position.y-.4
  velocity.y=clampf((altitude-position.y)*3,-5,5)
 else:velocity.y-=20*delta
 move_and_slide()
 if direction.length_squared()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),delta*7)
 for child in visual.get_children():
  if str(child.name).begins_with("FaunaWing"):child.rotation.y=sin(clock*5)*.35
 if predator and state=="chase" and distance<2.6 and attack_timer<=0 and bot.alive:
  attack_timer=1.2;bot.hurt(definition.damage)
func hit(damage: float) -> void:
 if not alive:return
 health-=maxf(0,damage);alert=6
 SpaceEffects.burst(get_parent(),global_position+Vector3.UP,definition.glow,.7)
 if health<=0:
  alive=false;visible=false;collision_layer=0;velocity=Vector3.ZERO;respawn_timer=30
