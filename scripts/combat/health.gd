class_name ShipHealth
extends Node
signal destroyed(attacker)
signal hit(shield_hit: bool)

var max_hull := 140.0
var max_shield := 120.0
var hull := 140.0
var shield := 120.0
var regen_delay := 0.0
var protection := 1.0
var damage_received := 0.0
var dead := false

func configure(stats: ShipStats) -> void:
 max_hull = stats.hull
 max_shield = stats.shield
 hull = max_hull
 shield = max_shield

func tick(delta: float) -> void:
 regen_delay = maxf(0.0, regen_delay - delta)
 if regen_delay <= 0.0 and not dead:
  shield = minf(max_shield, shield + 12.0 * delta)

func damage(amount: float, attacker: CombatShip) -> void:
 if dead or amount <= 0.0:
  return
 var actual := amount * protection
 var absorbed := minf(shield, actual)
 shield -= absorbed
 var hull_loss := minf(hull, actual - absorbed)
 hull -= hull_loss
 damage_received += absorbed + hull_loss
 if is_instance_valid(attacker):
  attacker.damage_dealt += absorbed + hull_loss
 regen_delay = 4.0
 hit.emit(absorbed > 0.0)
 if hull <= 0.0:
  dead = true
  destroyed.emit(attacker)
