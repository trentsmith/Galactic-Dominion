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
var retreat_latch := false

func tick(delta: float) -> void:
 alert_time = maxf(0.0, alert_time - delta)
 retarget_timer -= delta
 if retarget_timer <= 0.0:
  retarget_timer = 0.6
  _find_target()
 var enemy := ship.targeting.target
 var destination := ship.global_position
 var radius: float = ship.get_parent().zone.radius if ship.get_parent() is BattleMatch else 600.0
 if ship.health.shield <= 0.0:
  retreat_latch = true
 if ship.health.shield > ship.health.max_shield * 0.35:
  retreat_latch = false
 if command == "retreat" or retreat_latch:
  state = State.RETREAT
  var away := Vector3(0, 30, 0)
  if is_instance_valid(enemy):
   away = enemy.global_position.direction_to(ship.global_position) * 130.0
  destination = (ship.global_position + away).limit_length(radius * 0.72)
  ship.movement.boost_requested = ship.movement.boost_energy > 20.0
 elif command == "regroup" and is_instance_valid(leader) and leader.alive:
  state = State.REGROUP
  destination = _formation()
 elif is_instance_valid(enemy) and enemy.alive and (ship.team == 1 or command == "attack" or alert_time > 0.0 or ship.global_position.distance_to(enemy.global_position) < (250.0 if command == "defend" else 420.0)):
  state = State.PURSUE
  var distance := ship.global_position.distance_to(enemy.global_position)
  destination = enemy.global_position + enemy.velocity * 0.3
  if distance < 50.0:
   state = State.EVADE
   destination = ship.global_position + ship.global_basis.x * (80.0 if ship.fleet_slot % 2 == 0 else -80.0) - ship.global_basis.z * 60.0
  var aim := ship.global_position.direction_to(enemy.global_position + enemy.velocity * distance / ship.weapons.primary.speed)
  if (-ship.global_basis.z).dot(aim) > 0.975 and distance < 650.0:
   ship.weapons.fire()
  if ship.targeting.locked() and distance < 500.0:
   ship.weapons.fire(true)
  if distance < 200.0 and ship.ability_cooldown <= 0.0:
   ship.activate_ability()
  ship.movement.boost_requested = distance > 300.0
 else:
  state = State.DEFEND if command == "defend" else State.FOLLOW
  destination = _formation() if is_instance_valid(leader) and leader.alive else Vector3.ZERO
  ship.movement.boost_requested = false
 if ship.global_position.length() > radius * 0.9:
  destination = Vector3.ZERO
 SpaceNavigation.steer(ship, destination, delta)
 if state in [State.FOLLOW, State.REGROUP, State.DEFEND] and ship.global_position.distance_to(destination) < 18.0:
  ship.movement.thrust = Vector3.ZERO

func _formation() -> Vector3:
 var side := -1.0 if ship.fleet_slot == 1 else 1.0
 return leader.global_position + leader.global_basis * Vector3(side * 24, 8, 28)

func _find_target() -> void:
 if command == "attack" and is_instance_valid(commanded_target) and commanded_target.alive:
  ship.targeting.select(commanded_target)
  return
 var best: CombatShip
 var score := INF
 for candidate in get_tree().get_nodes_in_group("ships"):
  if not candidate.alive or candidate.team == ship.team:
   continue
  var distance: float = ship.global_position.distance_squared_to(candidate.global_position)
  if distance < score:
   score = distance
   best = candidate
 ship.targeting.select(best)
