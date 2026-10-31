class_name ShipBrain
extends Node

enum State { FOLLOW, PURSUE, EVADE, RETREAT, DEFEND, REGROUP }
var ship: CombatShip
var leader: CombatShip
var command := "follow"
var commanded_target: CombatShip
var state := State.FOLLOW
var alert_time := 0.0
var retarget_timer := 0.0
var nav_timer:=0.0
var nav_avoidance:=Vector3.ZERO
var reaction_interval := .6
var precise_aim:=false
var stable_targets:=false
var aim_lead := 1.0
var fire_dot := .975
var retreat_latch := false
var retreat_duration:=INF
var retreat_elapsed:=0.0
var burst_duration:=2.0
var burst_pause:=0.0
# Defaults preserve arena behavior; free-roam ships only sense nearby opponents.
var sensor_range := INF
var roaming := false
var roam_center := Vector3.ZERO
var patrol_time := 0.0

func tick(delta: float) -> void:
 alert_time = maxf(0.0, alert_time - delta)
 patrol_time += delta
 retarget_timer -= delta
 if retarget_timer <= 0.0:
  retarget_timer = reaction_interval
  _find_target()
 var enemy := ship.targeting.target
 var destination := ship.global_position
 var radius: float = ship.get_parent().zone.radius if ship.get_parent() is BattleMatch else 600.0
 if ship.health.shield <= 0.0:
  retreat_latch = true
 if retreat_latch:retreat_elapsed+=delta
 if ship.health.shield > ship.health.max_shield * 0.35:
  retreat_latch = false;retreat_elapsed=0.0
 if command == "retreat" or (retreat_latch and retreat_elapsed<retreat_duration):
  state = State.RETREAT
  var away := Vector3(0, 30, 0)
  if is_instance_valid(enemy):
   away = enemy.global_position.direction_to(ship.global_position) * 130.0
  destination = ship.global_position + away
  if not roaming:
   destination = destination.limit_length(radius * 0.72)
  ship.movement.boost_requested = ship.movement.boost_energy > 20.0
 elif command == "regroup" and is_instance_valid(leader) and leader.alive:
  state = State.REGROUP
  destination = _formation()
 elif is_instance_valid(enemy) and enemy.alive and (ship.team == 1 or command == "attack" or alert_time > 0.0 or ship.global_position.distance_to(enemy.global_position) < (250.0 if command == "defend" else 420.0)):
  state = State.PURSUE
  var distance := ship.global_position.distance_to(enemy.global_position)
  var origin:=ship.global_position-ship.global_basis.z*5
  var lead_point:=Ballistics.aim_point(origin,enemy.global_position,enemy.velocity,ship.weapons.primary.speed,ship.weapons.primary.lifetime) if precise_aim else enemy.global_position+enemy.velocity*aim_lead*distance/ship.weapons.primary.speed
  destination = lead_point if precise_aim else enemy.global_position + enemy.velocity * 0.3
  if distance < 50.0:
   state = State.EVADE
   destination = ship.global_position + ship.global_basis.x * (80.0 if ship.fleet_slot % 2 == 0 else -80.0) - ship.global_basis.z * 60.0
  var aim := origin.direction_to(lead_point) if precise_aim else ship.global_position.direction_to(lead_point)
  var interceptable:=not precise_aim or Ballistics.intercept_time(enemy.global_position-origin,enemy.velocity,ship.weapons.primary.speed,ship.weapons.primary.lifetime)>=0
  var firing_window:=burst_pause<=0 or fmod(patrol_time+ship.fleet_slot*.4,burst_duration+burst_pause)<burst_duration
  if firing_window and interceptable and ship.weapons.laser_remaining<=0 and (-ship.global_basis.z).dot(aim) > fire_dot and distance < 650.0 and (not precise_aim or clear_shot(lead_point)):
   ship.weapons.fire()
  if firing_window and ship.weapons.missile_remaining<=0 and ship.targeting.locked() and distance < 500.0 and (not precise_aim or clear_shot(enemy.global_position)):
   ship.weapons.fire(true)
  if distance < 200.0 and ship.ability_cooldown <= 0.0:
   ship.activate_ability()
  ship.movement.boost_requested = distance > 300.0
 else:
  state = State.DEFEND if command == "defend" else State.FOLLOW
  destination = _formation() if is_instance_valid(leader) and leader.alive else (roam_center + Vector3(sin(patrol_time * 0.12 + ship.fleet_slot) * 230, sin(patrol_time * 0.09) * 70, cos(patrol_time * 0.12 + ship.fleet_slot) * 230) if roaming else Vector3.ZERO)
  ship.movement.boost_requested = false
 if not roaming and ship.global_position.length() > radius * 0.9:
  destination = Vector3.ZERO
 var match_node:=ship.get_parent() as BattleMatch
 if match_node!=null and match_node.sector_map!=null and not is_instance_valid(enemy) and command=="attack":destination=match_node.sector_map.search_position(ship,match_node.elapsed)
 SpaceNavigation.steer(ship, destination, delta)
 if state in [State.FOLLOW, State.REGROUP, State.DEFEND] and ship.global_position.distance_to(destination) < 18.0:
  ship.movement.thrust = Vector3.ZERO

func _formation() -> Vector3:
 var index := ship.fleet_slot
 # Exclude the leader so every wingmate receives a separate formation slot.
 if index > leader.fleet_slot:index -= 1
 var side := -1.0 if index % 2 == 0 else 1.0
 var row := index / 2 + 1
 return leader.global_position + leader.global_basis * Vector3(side * (24 + row * 10), 8 + (index % 3) * 12, row * 32)

func _find_target() -> void:
 if command == "attack" and is_instance_valid(commanded_target) and commanded_target.alive and ship.position.distance_squared_to(commanded_target.position)<=sensor_range*sensor_range:
  ship.targeting.select(commanded_target)
  return
 var best: CombatShip
 var score := INF
 var match_node:=ship.get_parent() as BattleMatch
 var candidates: Array=match_node.spatial.nearby(ship.position,sensor_range) if match_node!=null and match_node.spatial!=null else get_tree().get_nodes_in_group("ships")
 for candidate in candidates:
  if not candidate.alive or candidate.team == ship.team:
   continue
  var distance: float = ship.global_position.distance_squared_to(candidate.global_position)
  if distance < score and distance <= sensor_range * sensor_range:
   score = distance
   best = candidate
 if stable_targets:
  var current:=ship.targeting.target
  if is_instance_valid(current) and current.alive and current.team!=ship.team:
   var current_distance:=ship.position.distance_squared_to(current.position)
   if current_distance<=sensor_range*sensor_range and (best==null or score>current_distance*.65):best=current
 ship.targeting.select(best)

func clear_shot(at: Vector3) -> bool:
 var origin:=ship.global_position-ship.global_basis.z*5
 var query:=PhysicsRayQueryParameters3D.create(origin,at,3)
 query.exclude=[ship.get_rid()]
 var hit:=ship.get_world_3d().direct_space_state.intersect_ray(query)
 return hit.is_empty() or (hit.collider is CombatShip and hit.collider.alive and hit.collider.team!=ship.team)
