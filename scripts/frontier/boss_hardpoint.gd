class_name BossHardpoint
extends StaticBody3D
var boss: BossWeakpoints
var index:=0
var health:=40.0
func hit(amount: float,attacker: CombatShip) -> bool:
 if not boss.authority or health<=0 or not is_instance_valid(attacker) or attacker.team==boss.ship.team:return false
 var applied:=minf(health,maxf(0,amount));health-=applied;attacker.damage_dealt+=applied
 SpaceEffects.burst(get_parent(),global_position,Color(1,.65,.2),1)
 if health<=0:boss.refresh()
 return true
