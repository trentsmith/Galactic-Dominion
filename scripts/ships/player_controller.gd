class_name PlayerPilot
extends Node

var ship: CombatShip
var camera: Camera3D
var sensitivity := 0.0025
var aim_offset := Vector2.ZERO
var inverted := false

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  aim_offset += event.relative * sensitivity
  aim_offset = aim_offset.limit_length(0.8)

func _physics_process(delta: float) -> void:
 if not is_instance_valid(ship) or not ship.alive:
  return
 if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  ship.rotate_object_local(Vector3.UP, -aim_offset.x * ship.stats.turn_speed * delta)
  ship.rotate_object_local(Vector3.RIGHT, -aim_offset.y * ship.stats.turn_speed * delta * (-1.0 if inverted else 1.0))
  ship.rotate_object_local(Vector3.FORWARD, Input.get_axis("roll_left", "roll_right") * 1.8 * delta)
  ship.basis = ship.basis.orthonormalized()
  aim_offset = aim_offset.move_toward(Vector2.ZERO, delta * 0.75)
  ship.movement.thrust = Vector3(Input.get_axis("strafe_left", "strafe_right"), Input.get_axis("down", "up"), Input.get_axis("forward", "reverse"))
  ship.movement.boost_requested = Input.is_action_pressed("boost")
  if Input.is_action_pressed("laser"):
   ship.weapons.fire()
  if Input.is_action_just_pressed("missile"):
   ship.weapons.fire(true)
  if Input.is_action_just_pressed("target"):
   ship.targeting.cycle()
  if Input.is_action_just_pressed("ability"):
   ship.activate_ability()
 else:
  ship.movement.thrust = Vector3.ZERO
  ship.movement.boost_requested = false
 var desired := ship.global_position + ship.global_basis * Vector3(0, 5.5, 18.0) + ship.velocity * 0.025
 camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-8.0 * delta))
 var desired_basis := ship.global_basis
 camera.global_basis = camera.global_basis.slerp(desired_basis, 1.0 - exp(-12.0 * delta)).orthonormalized()
 camera.fov = lerpf(camera.fov, 82.0 if ship.movement.boost_requested else 72.0, delta * 3.0)

func take_control(next: CombatShip) -> void:
 if is_instance_valid(ship):
  ship.player_controlled = false
  ship.movement.boost_requested = false
 ship = next
 ship.player_controlled = true
 aim_offset = Vector2.ZERO
 camera.global_position = ship.global_position + ship.global_basis * Vector3(0, 5.5, 18)
 camera.global_basis = ship.global_basis
