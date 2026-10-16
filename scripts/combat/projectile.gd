class_name SpaceProjectile
extends Node3D

var shooter: CombatShip
var target: CombatShip
var spec: WeaponSpec
var direction := Vector3.FORWARD
var elapsed := 0.0
var team := 0
var companion_shot := false
var projectile_color := Color.TRANSPARENT

func _ready() -> void:
 var mesh := MeshInstance3D.new()
 var shape := SphereMesh.new()
 shape.radius = 0.28 if companion_shot else 0.32 if spec.tracking else 0.17
 shape.height = shape.radius * 2.0
 mesh.mesh = shape
 mesh.scale.z = 1.0 if companion_shot else 3.0
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_color = projectile_color if projectile_color.a > 0 else Color(1, 0.7, 0.2) if spec.tracking else (Color(0.25, 0.9, 1) if team == 0 else Color(1, 0.25, 0.25))
 mesh.material_override = mat
 add_child(mesh)
 FleetCompanionArt.attack(self,spec.impact_style)

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
   impact(body,collision.position)
   if is_instance_valid(shooter):
    shooter.hits += 1
  if not (body is CombatShip and body.team == team):
   SpaceEffects.burst(get_parent(), collision.position, Color(1.0, 0.55, 0.15), 0.9)
   queue_free()
 global_position = next
 if direction.length_squared() > 0.1:
  look_at(global_position + direction, Vector3.UP if absf(direction.y) < 0.98 else Vector3.RIGHT)

# Called only by authoritative projectiles, never by snapshot visuals.
func impact(body: CombatShip, at: Vector3) -> void:
 if not body.alive or body.team == team: return
 var attacker: CombatShip = shooter if is_instance_valid(shooter) else null
 body.health.damage(spec.damage,attacker)
 if body.alive and body.health.protection > 0 and spec.slow_duration > 0:
  body.movement.apply_gravity_slow(spec.slow_duration)
 if spec.splash_radius <= 0: return
 for candidate in get_tree().get_nodes_in_group("ships"):
  if candidate == body or not candidate.alive or candidate.team == team: continue
  if at.distance_to(candidate.global_position)>spec.splash_radius: continue
  var query := PhysicsRayQueryParameters3D.create(at+direction*0.15,candidate.global_position,3)
  var excluded: Array[RID] = [body.get_rid()]
  if is_instance_valid(shooter):excluded.append(shooter.get_rid())
  query.exclude = excluded
  var collision := get_world_3d().direct_space_state.intersect_ray(query)
  if not collision.is_empty() and collision.collider != candidate:continue
  candidate.health.damage(spec.damage*0.5,attacker)
 SpaceEffects.burst(get_parent(),at,Color(1,0.35,0.9),spec.splash_radius*0.2)
