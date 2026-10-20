class_name CombatFeedback
extends Node
## Cosmetic feedback consumes confirmed damage; it never changes combat outcomes.
var battle: BattleMatch
var active_ship: CombatShip
var directions: Array[Dictionary] = []
var hit_remaining := 0.0
var hit_hull := false
var hit_amount := 0.0
var notice := ""
var notice_remaining := 0.0
var notice_color := Color.WHITE
var damage_label := ""
var damage_remaining := 0.0
var incoming_count := 0
var threat_clock := 0.0
var incoming_clock := 0.0
var lock_clock := 0.0
var locked_before := false
var previous_target: CombatShip
var audio_events: Array[String] = []

func _ready() -> void:
 for ship in battle.ships:watch_ship(ship)
 if battle is FreeRoamMatch:battle.ship_replaced.connect(func(index):watch_ship(battle.ships[index]))
 active_ship = battle.pilot.ship

func watch_ship(ship: CombatShip) -> void:
 if ship.health.damaged.is_connected(on_damage.bind(ship)):return
 ship.health.damaged.connect(on_damage.bind(ship))
 ship.weapons.rejected.connect(_on_rejected.bind(ship))
 ship.eliminated.connect(_on_eliminated)

func _process(delta: float) -> void:
 tick(delta)

func tick(delta: float) -> void:
 if battle.network_role == "server":return
 var controlled := battle.pilot.ship
 if controlled != active_ship:
  active_ship = controlled
  directions.clear()
  damage_remaining = 0
  hit_remaining = 0
  locked_before = false
  previous_target = null
 if not is_instance_valid(controlled):return
 hit_remaining = maxf(0,hit_remaining-delta)
 notice_remaining = maxf(0,notice_remaining-delta)
 damage_remaining = maxf(0,damage_remaining-delta)
 lock_clock = maxf(0,lock_clock-delta)
 incoming_clock = maxf(0,incoming_clock-delta)
 for index in range(directions.size()-1,-1,-1):
  directions[index].remaining -= delta
  if directions[index].remaining <= 0:directions.remove_at(index)
 if battle.finished:return
 var target := controlled.targeting.target
 var locked := controlled.targeting.locked()
 if target != previous_target:locked_before = false
 if locked and not locked_before and lock_clock <= 0:
  sound("lock")
  notify("TARGET LOCKED · MISSILE RELOADING" if controlled.weapons.missile_remaining>0 else "MISSILE LOCK READY · PRESS M",Color(.3,1,.85),1.2)
  lock_clock = 1.0
 locked_before = locked
 previous_target = target
 threat_clock -= delta
 if threat_clock <= 0:
  threat_clock = .12
  incoming_count = count_incoming()
 if incoming_count > 0 and incoming_clock <= 0:
  sound("incoming")
  incoming_clock = 1.5

func sound(event: String) -> void:
 audio_events.append(event)
 if audio_events.size()>12:audio_events.pop_front()
 SpaceAudio.play(event)

func notify(message: String, color: Color = Color.WHITE, seconds: float = 1.5) -> void:
 notice = message
 notice_color = color
 notice_remaining = seconds

func on_damage(report: Dictionary, victim: CombatShip) -> void:
 if battle.network_role == "server":return
 var controlled := battle.pilot.ship
 if not is_instance_valid(controlled):return
 if victim == controlled:
  if bool(report.get("directional",false)):
   directions.append({"position":report.position,"remaining":1.2,"hull":float(report.hull)>0})
   if directions.size()>6:directions.pop_front()
   damage_label = "HIT FROM " + direction_label(report.position)
  else:
   damage_label = str(report.get("source","environment")).to_upper() + " DAMAGE"
  damage_remaining = 1.2
  sound("hull_hit" if float(report.hull)>0 else "shield")
  if report.get("shield_broken",false):
   sound("shield_break")
   notify("SHIELDS DOWN · BREAK AWAY TO RECHARGE",Color(1,.7,.3),2.4)
  if report.get("critical",false):
   sound("critical")
   notify("CRITICAL HULL · SWITCH SHIPS OR RETREAT",Color(1,.35,.25),2.8)
  if report.get("fatal",false):
   notify("%s LOST · %s" % [victim.callsign.to_upper(),damage_cause(report)],Color(1,.4,.3),3.5)
 elif int(report.get("attacker_id",0)) == controlled.get_instance_id():
  hit_amount = hit_amount + float(report.shield) + float(report.hull) if hit_remaining>0 else float(report.shield)+float(report.hull)
  hit_remaining = .3
  hit_hull = float(report.hull)>0
  sound("hit_hull" if hit_hull else "hit_shield")
  if report.get("shield_broken",false):notify("TARGET SHIELDS BROKEN",Color(1,.8,.4),1.3)
 if report.get("fatal",false) and victim != controlled:
  if victim.team == battle.local_team():notify(victim.callsign.to_upper()+" LOST · "+damage_cause(report),Color(1,.5,.3),2.4)
  elif victim == previous_target:notify("TARGET DESTROYED · TAB FOR NEXT",Color(.5,1,.75),2)

func _on_rejected(reason: String, ship: CombatShip) -> void:
 if ship == battle.pilot.ship:notify(reason,Color(1,.8,.4))

func _on_eliminated(ship: CombatShip, _attacker: CombatShip) -> void:
 if battle.network_role == "server" or ship.team == battle.local_team():return
 if ship == previous_target:notify("TARGET DESTROYED · TAB FOR NEXT",Color(.5,1,.75),2)

func direction_label(world_position: Vector3) -> String:
 var local := battle.camera.global_basis.inverse() * (world_position - battle.pilot.ship.global_position)
 if absf(local.z)>maxf(absf(local.x),absf(local.y)):return "REAR" if local.z>0 else "FRONT"
 if absf(local.x)>absf(local.y):return "RIGHT" if local.x>0 else "LEFT"
 return "ABOVE" if local.y>0 else "BELOW"

func indicator_direction(world_position: Vector3) -> Vector2:
 var local := battle.camera.global_basis.inverse() * (world_position - battle.pilot.ship.global_position)
 var projected := Vector2(local.x,-local.y)
 if projected.length()<maxf(.001,absf(local.z)*.3):return Vector2.DOWN if local.z>0 else Vector2.UP
 return projected.normalized()

func count_incoming() -> int:
 var count := 0
 var ship := battle.pilot.ship
 if not is_instance_valid(ship) or not ship.alive:return 0
 for node in battle.get_children():
  if node.is_queued_for_deletion():continue
  if node is SpaceProjectile:
   if node.spec.tracking and node.target == ship and node.team != ship.team and node.elapsed < node.spec.lifetime and node.global_position.distance_to(ship.global_position)<900:count+=1
  elif node.has_meta("network_projectile") and node.get_meta("incoming_target",-1) == battle.ships.find(ship):
   if node.get_meta("missile",false) and int(node.get_meta("team",ship.team)) != ship.team and node.global_position.distance_to(ship.global_position)<900:count+=1
 return count

static func damage_cause(report: Dictionary) -> String:
 var cause := str(report.get("source","unknown")).to_upper()
 var attacker := str(report.get("attacker_name",""))
 return cause + (" / " + attacker if not attacker.is_empty() else "")

func battle_summary() -> String:
 var allied_damage := 0.0
 var enemy_damage := 0.0
 var shield_taken := 0.0
 var hull_taken := 0.0
 var environmental := 0.0
 var shots := 0
 var hits := 0
 var opponents_alive := 0
 for ship in battle.ships:
  if ship.team == battle.local_team():
   allied_damage += ship.damage_dealt
   shield_taken += ship.health.shield_damage
   hull_taken += ship.health.hull_damage
   environmental += ship.health.environment_damage
   shots += ship.shots;hits += ship.hits
  else:
   enemy_damage += ship.damage_dealt
   if ship.alive:opponents_alive += 1
 var result := "Survivors: your fleet %d · opponents %d\nDamage dealt: your fleet %d · opponents %d\nYour fleet absorbed %d shield / %d hull damage · %d environmental" % [battle.living(battle.local_team()),opponents_alive,int(allied_damage),int(enemy_damage),int(shield_taken),int(hull_taken),int(environmental)]
 if battle.end_reason.begins_with("Time limit"):
  var scores := [0.0,0.0]
  for ship in battle.ships:
   if ship.alive:scores[ship.team]+=ship.health.hull/maxf(1,ship.health.max_hull)+ship.health.shield/maxf(1,ship.health.max_shield)
  result += "\nTime-limit survival score: %.2f vs %.2f" % [scores[battle.local_team()],scores[1-battle.local_team()]]
 if environmental>0 and environmental>hull_taken*.3:result += "\nFlight tip: leave hazards and return inside the safe zone."
 elif shots>10 and float(hits)/shots<.25:result += "\nFlight tip: keep targets near the reticle; lock missiles before firing."
 else:result += "\nFlight tip: switch to a healthy wingmate when shields collapse."
 return result
