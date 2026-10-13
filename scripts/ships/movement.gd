class_name ShipMovement
extends Node

var ship: CombatShip
var thrust := Vector3.ZERO
var boost_requested := false
var boost_energy := 100.0
var ability_multiplier := 1.0

func tick(delta: float) -> void:
 var boosting := boost_requested and boost_energy > 1.0 and thrust.length_squared() > 0.01
 boost_energy = clampf(boost_energy + (-32.0 if boosting else ship.stats.boost_regen) * delta, 0.0, ship.stats.boost_capacity)
 var top_speed := ship.stats.speed * ability_multiplier * (1.8 if boosting else 1.0)
 var desired := ship.global_basis * thrust.limit_length() * top_speed
 # Mild drag preserves a short drift while still making stopping accessible.
 var response := ship.stats.acceleration if thrust.length_squared() > 0.01 else ship.stats.acceleration * 0.38
 ship.velocity = ship.velocity.move_toward(desired, response * delta)
 ship.move_and_slide()
 for index in ship.get_slide_collision_count():
  var collision := ship.get_slide_collision(index)
  if collision.get_collider() is StaticBody3D and ship.velocity.length() > 15.0:
   ship.health.damage(8.0 * delta, null)
   ship.velocity = ship.velocity.slide(collision.get_normal()) * 0.8
