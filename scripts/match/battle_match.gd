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
var network_role := "offline"
var preconfigured_stats: Array[ShipStats] = []
var max_duration := 480.0
var profile: PlayerProfile
var rewards: Array[Dictionary] = []
var reward_summary := ""
var battle_id := ""

func _ready() -> void:
 battle_id = "%d-%d" % [Time.get_ticks_usec(), get_instance_id()]
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
   ship.stats = profile.configured_stats(slot) if team_index == 0 and profile != null else CLASSES[slot]
   if team_index == 0 and profile != null:
    var crew := CollectionCatalog.find(str(profile.loadouts[slot].crew))
    ship.crew_name = crew.display_name if crew != null else "Unassigned"
   if preconfigured_stats.size() == 6:
    ship.stats = preconfigured_stats[team_index * 3 + slot]
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
 if network_role != "offline":
  pilot.set_physics_process(false)
  pilot.set_process_unhandled_input(false)
  fleet.set_process_unhandled_input(false)
  for ship in ships:
   ship.player_controlled = false
  if network_role == "client":
   set_physics_process(false)
   for ship in ships:
    ship.set_physics_process(false)
    ship.collision_layer = 0
    ship.collision_mask = 0
 if network_role == "server":
  hud.visible = false
 else:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
 if finished:
  return
 elapsed += delta
 update_auras()
 zone.tick(delta, ships)
 if elapsed >= max_duration:
  var scores := [0.0, 0.0]
  for ship in ships:
   if ship.alive:
    scores[ship.team] += ship.health.hull / ship.health.max_hull + ship.health.shield / ship.health.max_shield
  finish(0 if scores[0] > scores[1] else (1 if scores[1] > scores[0] else -1), "Time limit · surviving hull and shields decide")

func update_auras() -> void:
 # Reset and aggregate Guardian auras once per simulation tick.
 for ship in ships:
  ship.health.protection = 1.0
 for guardian in ships:
  if guardian.alive and guardian.stats.ability == "aegis" and guardian.ability_remaining > 0.0:
   for friend in ships:
    if friend.alive and friend.team == guardian.team and friend.global_position.distance_to(guardian.global_position) < 90.0:
     friend.health.protection = 0.45

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
 if profile != null:
  var kills := 0
  var damage := 0.0
  for ally in fleet.ships:
   kills += ally.kills
   damage += ally.damage_dealt
  rewards = profile.settle_battle(battle_id, winner, kills, damage)
  reward_summary = "+%d salvage · %d discovery rolls" % [60 if winner == 0 else 30, 2 if winner == 0 else 1]
 ended.emit(team, reason)
 if network_role != "server":
  hud.show_results()

func local_team() -> int:
 return pilot.ship.team if is_instance_valid(pilot.ship) else 0
