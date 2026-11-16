class_name BossWeakpoints
extends Node3D
var ship: CombatShip
var authority:=true
var points: Array[BossHardpoint]=[]
var enraged:=false
var original_scales: Dictionary={}
var original_shapes: Dictionary={}
var original_cooldown:=0.0
func _ready() -> void:
 name="SiegeWeakpoints"
 original_cooldown=ship.weapons.primary.cooldown
 for child in ship.get_children():
  if child is Node3D and not child is CollisionShape3D and child!=self and not child is AlienCompanion:
   original_scales[child]=child.scale
   child.scale*=3
 for child in ship.get_children():
  if child is CollisionShape3D and child.shape is SphereShape3D:
   original_shapes[child]=child.shape
   child.shape=child.shape.duplicate();child.shape.radius=7
 for i in range(3):
  var point:=BossHardpoint.new();point.boss=self;point.index=i;point.position=[Vector3(-9,1,0),Vector3(9,1,0),Vector3(0,6,-3)][i];point.collision_layer=2 if authority else 0;point.collision_mask=0;add_child(point);points.append(point)
  var collision:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=2;collision.shape=sphere;point.add_child(collision)
  SpaceModelFactory.ball(point,Vector3.ZERO,Vector3.ONE*1.8,Color(1,.6,.12),"ExposedReactor",true)
  var label:=Label3D.new();label.text="ANCHOR %d"%(i+1);label.position.y=3;label.pixel_size=.04;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;point.add_child(label)
 ship.set_meta("boss_damage_scale",.2)
func refresh() -> void:
 var active:=0
 for point in points:
  point.visible=point.health>0
  if point.health>0:active+=1
  elif authority:point.set_deferred("collision_layer",0)
 ship.set_meta("boss_damage_scale",.2 if active>0 else 1.0)
 if active==0 and not enraged:
  enraged=true
  if authority:ship.weapons.primary.cooldown*=.65
func remaining() -> int:
 var count:=0
 for point in points:
  if point.health>0:count+=1
 return count
func snapshot() -> Array:
 return points.map(func(point):return point.health)
func apply(values: Array) -> void:
 if authority:return
 for i in range(mini(values.size(),points.size())):points[i].health=clampf(float(values[i]),0,40)
 refresh()
func dispose() -> void:
 for child in original_scales:
  if is_instance_valid(child):child.scale=original_scales[child]
 for child in original_shapes:
  if is_instance_valid(child):child.shape=original_shapes[child]
 if is_instance_valid(ship):
  ship.set_meta("boss_damage_scale",1.0)
  ship.remove_meta("frontier_enemy")
  ship.weapons.primary.cooldown=original_cooldown
 for point in points:point.set_deferred("collision_layer",0)
 hide();queue_free()
