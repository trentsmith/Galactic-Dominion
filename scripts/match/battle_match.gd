class_name BattleMatch
extends Node3D
signal ended(winner, reason)

const CLASSES = [preload("res://resources/ships/interceptor.tres"), preload("res://resources/ships/skirmisher.tres"), preload("res://resources/ships/guardian.tres")]
var ships: Array[CombatShip] = []
var fleet: FleetManager
var pilot: PlayerPilot
var zone: BattleZone
var camera: Camera3D
var elapsed := 0.0
var finished := false
var winner := -1
var end_reason := ""
var hud: BattleHUD

func _ready() -> void:
 var arena := SpaceArena.new()
 add_child(arena)
 zone = BattleZone.new()
 add_child(zone)
 camera = Camera3D.new()
 camera.far = 4000.0
 camera.current = true
 add_child(camera)
 pilot = PlayerPilot.new()
 pilot.camera = camera
 add_child(pilot)
 fleet = FleetManager.new()
 fleet.pilot = pilot
 add_child(fleet)
 for team_index in range(2):
  for slot in range(3):
   var ship := CombatShip.new()
   ship.stats = CLASSES[slot]
   ship.team = team_index
   ship.fleet_slot = slot
   ship.callsign = ("Vanguard" if team_index == 0 else "Ravager") + " %d" % (slot + 1)
   ship.position = Vector3((slot - 1) * 40.0, slot * 12.0, 230.0 if team_index == 0 else -230.0)
   if team_index == 1:
    ship.rotation.y = PI
   add_child(ship)
   ships.append(ship)
   ship.eliminated.connect(_on_eliminated)
   if team_index == 0:
    fleet.ships.append(ship)
    ship.eliminated.connect(fleet.on_eliminated)
 fleet.switch_to(0)
 fleet.issue_command("follow")
 pilot.ship.targeting.cycle()
 hud = BattleHUD.new()
 hud.battle = self
 add_child(hud)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
 if finished:
  return
 elapsed += delta
 # Reset and aggregate Guardian auras once per simulation tick.
 for ship in ships:
  ship.health.protection = 1.0
 for guardian in ships:
  if guardian.alive and guardian.stats.ability == "aegis" and guardian.ability_remaining > 0.0:
   for friend in ships:
    if friend.alive and friend.team == guardian.team and friend.global_position.distance_to(guardian.global_position) < 90.0:
     friend.health.protection = 0.45
 zone.tick(delta, ships)
 if elapsed >= 480.0:
  var scores := [0.0, 0.0]
  for ship in ships:
   if ship.alive:
    scores[ship.team] += ship.health.hull / ship.health.max_hull + ship.health.shield / ship.health.max_shield
  finish(0 if scores[0] > scores[1] else (1 if scores[1] > scores[0] else -1), "Time limit · surviving hull and shields decide")

func _on_eliminated(_ship: CombatShip, _attacker: CombatShip) -> void:
 if finished:
  return
 var allies := living(0)
 var enemies := living(1)
 if allies == 0 or enemies == 0:
  finish(0 if enemies == 0 and allies > 0 else (1 if allies == 0 and enemies > 0 else -1), "Fleet eliminated")

func living(team: int) -> int:
 var count := 0
 for ship in ships:
  if ship.team == team and ship.alive:
   count += 1
 return count

func finish(team: int, reason: String) -> void:
 if finished:
  return
 finished = true
 winner = team
 end_reason = reason
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 # Freeze simulation for a stable results screen without pausing UI.
 for ship in ships:
  ship.set_physics_process(false)
 pilot.set_physics_process(false)
 fleet.set_process_unhandled_input(false)
 for child in get_children():
  if child is SpaceProjectile:
   child.set_physics_process(false)
 ended.emit(team, reason)
 hud.show_results()
