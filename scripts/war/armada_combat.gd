class_name ArmadaCombat
extends RefCounted
static func count(value: Variant) -> int:
 if not value is int and not value is float:return 200
 if not is_finite(float(value)):return 200
 return clampi(int(value),1,200)
static func enemy_stats(base: ShipStats,id: String) -> ShipStats:
 if id=="relaxed":return SoloDifficulty.enemy_stats(base,id)
 var result:=base.duplicate(true) as ShipStats
 result.crew_id=""
 result.turn_speed*=1.18 if id=="veteran" else 1.08
 result.laser_cooldown*=.9 if id=="veteran" else 1.0
 result.missile_cooldown*=.9 if id=="veteran" else 1.0
 return result
static func configure(ship: CombatShip,id: String) -> void:
 ship.brain.precise_aim=true;ship.brain.stable_targets=true;ship.weapons.precise_intercept=true
 if ship.team!=1:return
 var relaxed:=id=="relaxed";var veteran:=id=="veteran"
 ship.health.regen_rate=ship.stats.shield_regen*(.3 if relaxed else 1.0)
 ship.brain.reaction_interval=1.1 if relaxed else .16 if veteran else .35
 ship.brain.fire_dot=.99 if relaxed else .985
 ship.brain.aim_lead=.65 if relaxed else 1.0
 ship.brain.burst_duration=1.4 if relaxed else 4.0 if veteran else 3.0
 ship.brain.burst_pause=1.3 if relaxed else .05 if veteran else .2
 ship.brain.retreat_duration=2.5 if relaxed else 3.5 if veteran else 2.8
 ship.weapons.aim_assist_dot=.99 if relaxed else .985
 ship.weapons.secondary.speed=175 if relaxed else 220
 ship.weapons.secondary.turn_rate=3 if relaxed else 4.5
 ship.targeting.lock_duration=1.2 if relaxed else .8
