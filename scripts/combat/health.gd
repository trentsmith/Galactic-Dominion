class_name ShipHealth
extends Node
signal destroyed(attacker)
signal hit(shield_hit: bool)
signal damaged(report: Dictionary)

var max_hull := 140.0
var max_shield := 120.0
var hull := 140.0
var shield := 120.0
var regen_delay := 0.0
var regen_rate := 12.0
var protection := 1.0
var damage_received := 0.0
var damage_by_attacker: Dictionary = {}
var dead := false
var damage_sequence := 0
var damage_history: Array[Dictionary] = []
var shield_damage := 0.0
var hull_damage := 0.0
var environment_damage := 0.0

func configure(stats: ShipStats) -> void:
 regen_rate = stats.shield_regen
 max_hull = stats.hull
 max_shield = stats.shield
 hull = max_hull
 shield = max_shield
 damage_history.clear()
 shield_damage = 0
 hull_damage = 0
 environment_damage = 0

func tick(delta: float) -> void:
 regen_delay = maxf(0.0, regen_delay - delta)
 if regen_delay <= 0.0 and not dead:
  shield = minf(max_shield, shield + regen_rate * delta)

func damage(amount: float, attacker: CombatShip, source: String = "weapon") -> void:
 if dead or amount <= 0.0:
  return
 var actual := amount * protection
 if actual <= 0:
  return
 var previous_shield := shield
 var previous_hull := hull
 var absorbed := minf(shield, actual)
 shield -= absorbed
 var hull_loss := minf(hull, actual - absorbed)
 hull -= hull_loss
 damage_received += absorbed + hull_loss
 if is_instance_valid(attacker):
  attacker.damage_dealt += absorbed + hull_loss
  var id := attacker.get_instance_id()
  damage_by_attacker[id] = float(damage_by_attacker.get(id, 0)) + absorbed + hull_loss
 shield_damage += absorbed
 hull_damage += hull_loss
 var damage_source := source if is_instance_valid(attacker) or source != "weapon" else "environment"
 if damage_source in ["environment","battle zone","collision","ion storm"]:environment_damage += absorbed + hull_loss
 damage_sequence += 1
 var report := {"sequence":damage_sequence,"shield":absorbed,"hull":hull_loss,
  "source":damage_source,
  "attacker_id":attacker.get_instance_id() if is_instance_valid(attacker) else 0,
  "attacker_name":attacker.callsign if is_instance_valid(attacker) else "",
  "position":attacker.global_position if is_instance_valid(attacker) else Vector3.ZERO,
  "directional":is_instance_valid(attacker),
  "shield_broken":previous_shield > 0 and shield <= 0,
  "critical":previous_hull > max_hull * .25 and hull <= max_hull * .25,
  "fatal":hull <= 0}
 damage_history.append(report)
 if damage_history.size() > 8:damage_history.pop_front()
 regen_delay = 4.0
 damaged.emit(report)
 hit.emit(absorbed > 0.0)
 if hull <= 0.0:
  dead = true
  destroyed.emit(attacker)
