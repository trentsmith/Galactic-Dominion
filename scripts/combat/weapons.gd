class_name ShipWeapons
extends Node
signal fired(missile: bool)

var ship: CombatShip
var primary: WeaponSpec
var secondary: WeaponSpec
var laser_remaining := 0.0
var missile_remaining := 0.0
var overcharge := false
var aim_assist_dot:=0.985

func configure(stats: ShipStats) -> void:
 primary = WeaponSpec.new()
 primary.damage = stats.laser_damage
 primary.cooldown = stats.laser_cooldown
 secondary = WeaponSpec.new()
 secondary.damage = stats.missile_damage
 secondary.cooldown = stats.missile_cooldown
 secondary.speed = 125.0
 secondary.lifetime = 8.0
 secondary.tracking = true

func tick(delta: float) -> void:
 laser_remaining = maxf(0.0, laser_remaining - delta)
 missile_remaining = maxf(0.0, missile_remaining - delta)

func fire(missile: bool = false) -> bool:
 if (missile_remaining if missile else laser_remaining) > 0.0 or not ship.alive:
  return false
 if missile and not ship.targeting.locked():
  return false
 # Firing ends spawn protection so it cannot be used to attack invulnerably.
 if float(ship.get_meta("spawn_protection", 0)) > 0:
  ship.set_meta("spawn_protection", 0.0)
  ship.health.protection = 1.0
 var base := secondary if missile else primary
 var spec := base.duplicate() as WeaponSpec
 if overcharge:
  spec.damage *= 1.65
 if missile:
  missile_remaining = spec.cooldown * (0.3 if ship.stats.ability == "barrage" and ship.ability_remaining > 0.0 else 1.0)
 else:
  laser_remaining = spec.cooldown * (0.65 if overcharge else 1.0)
 var projectile := SpaceProjectile.new()
 projectile.spec = spec
 projectile.shooter = ship
 projectile.team = ship.team
 projectile.target = ship.targeting.target if missile else null
 projectile.direction = -ship.global_basis.z
 # Aim assist only within the reticle cone; pilot must still align the ship.
 var target := ship.targeting.target
 if not missile and is_instance_valid(target) and target.alive:
  var distance := ship.global_position.distance_to(target.global_position)
  var predicted := target.global_position + target.velocity * distance / spec.speed
  var aim := ship.global_position.direction_to(predicted)
  if projectile.direction.dot(aim) > aim_assist_dot:
   projectile.direction = aim
 ship.get_parent().add_child(projectile)
 projectile.global_position = ship.global_position - ship.global_basis.z * 5.0
 if ship.player_controlled:
  SpaceAudio.play("missile" if missile else "laser")
 ship.shots += 1
 ship.muzzle_flash = 0.07
 fired.emit(missile)
 return true
