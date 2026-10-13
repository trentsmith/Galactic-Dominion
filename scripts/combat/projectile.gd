class_name SpaceProjectile
extends Node3D

var shooter: CombatShip
var target: CombatShip
var spec: WeaponSpec
var direction := Vector3.FORWARD
var elapsed := 0.0
var team := 0

func _ready() -> void:
 var mesh := MeshInstance3D.new()
 var shape := SphereMesh.new()
 shape.radius = 0.32 if spec.tracking else 0.17
 shape.height = shape.radius * 2.0
 mesh.mesh = shape
 mesh.scale.z = 3.0
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_color = Color(1, 0.7, 0.2) if spec.tracking else (Color(0.25, 0.9, 1) if team == 0 else Color(1, 0.25, 0.25))
 mesh.material_override = mat
 add_child(mesh)

func _physics_process(delta: float) -> void:
 elapsed += delta
 if elapsed > spec.lifetime:
  queue_free()
  return
 if spec.tracking and is_instance_valid(target) and target.alive:
  var desired := global_position.direction_to(target.global_position)
  direction = direction.slerp(desired, minf(1.0, spec.turn_rate * delta)).normalized()
 var next := global_position + direction * spec.speed * delta
 var query := PhysicsRayQueryParameters3D.create(global_position, next, 3)
 if is_instance_valid(shooter):
  query.exclude = [shooter.get_rid()]
 var collision := get_world_3d().direct_space_state.intersect_ray(query)
 if not collision.is_empty():
  var body = collision.collider
  if body is CombatShip and body.team != team:
   body.health.damage(spec.damage, shooter if is_instance_valid(shooter) else null)
   if is_instance_valid(shooter):
    shooter.hits += 1
  if not (body is CombatShip and body.team == team):
   SpaceEffects.burst(get_parent(), collision.position, Color(1.0, 0.55, 0.15), 0.9)
   queue_free()
 global_position = next
 if direction.length_squared() > 0.1:
  look_at(global_position + direction, Vector3.UP if absf(direction.y) < 0.98 else Vector3.RIGHT)
