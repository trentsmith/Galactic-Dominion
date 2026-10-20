class_name SoloDifficulty
extends RefCounted
## Solo arena presets. Network, exploration and training use their own rules.
const IDS := ["relaxed","standard","veteran"]
const PRESETS := {
 "relaxed":{"title":"Relaxed","description":"Slower reactions, shorter attacks and more breathing room.","hull":.75,"cooldown":1.4,"regen":.3,"reaction":1.1,"lead":.65,"fire_dot":.99,"turn":.85,"burst":1.4,"pause":1.3,"retreat":2.5},
 "standard":{"title":"Standard","description":"The existing solo balance, with steady enemy pressure.","hull":.85,"cooldown":1.15,"regen":.5,"reaction":.6,"lead":1.0,"fire_dot":.975,"turn":1.0,"burst":2.0,"pause":.65,"retreat":3.5},
 "veteran":{"title":"Veteran","description":"Faster reactions and sustained attacks; no extra enemy health.","hull":.85,"cooldown":1.0,"regen":.5,"reaction":.25,"lead":1.0,"fire_dot":.97,"turn":1.12,"burst":3.0,"pause":.15,"retreat":4.0}
}
static func valid(id: String) -> String:
 return id if id in IDS else "standard"
static func title(id: String) -> String:
 return PRESETS[valid(id)].title
static func enemy_stats(base: ShipStats,id: String) -> ShipStats:
 var tuning: Dictionary = PRESETS[valid(id)]
 var result := base.duplicate(true) as ShipStats
 result.hull *= tuning.hull;result.shield *= tuning.hull
 result.laser_cooldown *= tuning.cooldown;result.missile_cooldown *= tuning.cooldown
 result.turn_speed *= tuning.turn
 result.crew_id = ""
 return result
static func configure_enemy(ship: CombatShip,id: String) -> void:
 var tuning: Dictionary = PRESETS[valid(id)]
 ship.health.regen_rate *= tuning.regen
 ship.brain.reaction_interval = tuning.reaction
 ship.brain.aim_lead = tuning.lead
 ship.brain.fire_dot = tuning.fire_dot
 ship.brain.retreat_duration = tuning.retreat
 ship.brain.burst_duration = tuning.burst
 ship.brain.burst_pause = tuning.pause
