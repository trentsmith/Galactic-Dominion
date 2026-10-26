class_name SpaceNavigation
extends RefCounted

static func steer(ship: CombatShip, destination: Vector3, delta: float) -> void:
 var direction := ship.global_position.direction_to(destination)
 if direction.length_squared() < 0.001:
  ship.movement.thrust = Vector3.ZERO
  return
 # Cast ahead and toward both wings. Static obstacles use layer 2.
 var match_node:=ship.get_parent() as BattleMatch
 var indexed:=match_node!=null and match_node.spatial!=null
 ship.brain.nav_timer-=delta
 var avoidance:=ship.brain.nav_avoidance if indexed else Vector3.ZERO
 if not indexed or ship.brain.nav_timer<=0:
  avoidance=Vector3.ZERO
  for offset in [Vector3.ZERO, ship.global_basis.x * 5.0, -ship.global_basis.x * 5.0]:
   var start: Vector3 = ship.global_position + offset
   var query := PhysicsRayQueryParameters3D.create(start, start + direction * (30.0 + ship.velocity.length() * 0.7), 2)
   var collision := ship.get_world_3d().direct_space_state.intersect_ray(query)
   if not collision.is_empty():avoidance += collision.normal * 2.0 + ship.global_basis.y
  if indexed:
   avoidance+=match_node.sector_map.avoidance(ship.position)
   ship.brain.nav_timer=.18+float(ship.fleet_slot%4)*.02
   ship.brain.nav_avoidance=avoidance
 direction = (direction + avoidance).normalized()
 var up := Vector3.UP if absf(direction.y) < 0.97 else Vector3.RIGHT
 var desired := Basis.looking_at(direction, up)
 ship.global_basis = ship.global_basis.slerp(desired, minf(1.0, ship.stats.turn_speed * delta)).orthonormalized()
 var alignment := (-ship.global_basis.z).dot(direction)
 ship.movement.thrust = Vector3(0, 0, -clampf(alignment, 0.2, 1.0))
