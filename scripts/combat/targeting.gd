class_name ShipTargeting
extends Node

var ship: CombatShip
var target: CombatShip
var lock_time := 0.0
var lock_duration:=1.2
var selection_range := INF
var enforce_range:=false

func tick(delta: float) -> void:
 if not is_instance_valid(target) or not target.alive:
  target = null
  lock_time = 0.0
  return
 if enforce_range and ship.position.distance_squared_to(target.position)>selection_range*selection_range:
  select(null);return
 var direction := ship.global_position.direction_to(target.global_position)
 if (-ship.global_basis.z).dot(direction) > 0.90 and ship.global_position.distance_to(target.global_position) < 600.0:
  lock_time = minf(lock_duration, lock_time + delta)
 else:
  lock_time = maxf(0.0, lock_time - delta * 2.0)

func locked() -> bool:
 return is_instance_valid(target) and target.alive and lock_time >= lock_duration

func select(candidate: CombatShip) -> void:
 if target != candidate:
  target = candidate
  lock_time = 0.0

func cycle() -> void:
 var enemies: Array[CombatShip] = []
 for node in get_tree().get_nodes_in_group("ships"):
  if node.alive and node.team != ship.team and ship.global_position.distance_to(node.global_position) <= selection_range:
   enemies.append(node)
 if enemies.is_empty():
  select(null)
  return
 enemies.sort_custom(func(a, b): return ship.global_position.distance_squared_to(a.global_position) < ship.global_position.distance_squared_to(b.global_position))
 var index := enemies.find(target)
 select(enemies[(index + 1) % enemies.size()])
