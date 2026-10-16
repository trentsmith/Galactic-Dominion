class_name WeaponSpec
extends Resource

@export var damage := 16.0
@export var cooldown := 0.22
@export var speed := 260.0
@export var lifetime := 3.0
@export var tracking := false
@export var turn_rate := 2.6

# Optional impact behavior; regular ship weapons keep their existing defaults.
@export var impact_style := ""
@export var splash_radius := 0.0
@export var slow_duration := 0.0
