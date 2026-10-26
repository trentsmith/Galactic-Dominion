class_name ShipMovement
extends Node

var ship: CombatShip
var thrust := Vector3.ZERO
var boost_requested := false
var boost_energy := 100.0
var ability_multiplier := 1.0
var external_acceleration:=Vector3.ZERO
var field_drift:=Vector3.ZERO
var slow_remaining := 0.0

func apply_gravity_slow(duration: float) -> void:
 slow_remaining = maxf(slow_remaining,clampf(duration,0,1.5))


func tick(delta: float) -> void:
 slow_remaining = maxf(0,slow_remaining-delta)
 var boosting := boost_requested and boost_energy > 1.0 and thrust.length_squared() > 0.01
 boost_energy = clampf(boost_energy + (-32.0 if boosting else ship.stats.boost_regen) * delta, 0.0, ship.stats.boost_capacity)
 var top_speed := ship.stats.speed * ability_multiplier * (1.8 if boosting else 1.0) * (0.65 if slow_remaining>0 else 1.0)
 var desired := ship.global_basis * thrust.limit_length() * top_speed
 # Mild drag preserves a short drift while still making stopping accessible.
 var response := ship.stats.acceleration if thrust.length_squared() > 0.01 else ship.stats.acceleration * 0.38
 var controlled_velocity:=ship.velocity-field_drift
 field_drift=(field_drift+external_acceleration*delta).limit_length(120)*exp(-(.25 if external_acceleration.length_squared()>.01 else .8)*delta)
 ship.velocity = controlled_velocity.move_toward(desired, response * delta)+field_drift
 ship.move_and_slide()
 for index in ship.get_slide_collision_count():
  var collision := ship.get_slide_collision(index)
  if collision.get_collider() is StaticBody3D and ship.velocity.length() > 15.0:
   ship.health.damage(8.0 * delta, null, "collision")
   ship.velocity = ship.velocity.slide(collision.get_normal()) * 0.8
