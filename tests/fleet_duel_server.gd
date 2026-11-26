extends SceneTree
## Deterministic network fixture: freeze AI, preserve pilot movement, then
## credit a real health-system elimination to a wingmate between snapshots.
var main: Node
var stage := 0
var clock := 0.0
var feedback_sent := false
var switched: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
func _process(delta: float) -> bool:
 clock += delta
 if clock>55: push_error("DUEL_SERVER_TIMEOUT");quit(1);return false
 if not is_instance_valid(main) or not is_instance_valid(main.network.arena):return false
 var session: OnlineSession=main.network
 var arena: BattleMatch=session.arena
 var left:=int(OS.get_environment("GD_TEST_DUEL_LEFT"))
 var right:=int(OS.get_environment("GD_TEST_DUEL_RIGHT"))
 if stage==0:
  if not arena.fleet_duel or arena.ships.size()!=left+right:
   push_error("DUEL_SERVER_WRONG_COUNT");quit(1);return false
  for team in range(2):
   var data: Dictionary=session.members[session.fleet_commanders[team]].profile
   var vessels:=FleetManifest.battle_vessels(data)
   var base:=0 if team==0 else left
   for i in range(vessels.size()):
    var expected:=FleetManifest.vessel_stats(data,vessels[i])
    if arena.ships[base+i].callsign!=str(vessels[i].name) or not is_equal_approx(arena.ships[base+i].stats.speed,expected.speed) or not is_equal_approx(arena.ships[base+i].stats.laser_damage,expected.laser_damage):
     push_error("DUEL_SERVER_FITTING_MISMATCH");quit(1);return false
  print("DUEL_SERVER_MANIFEST_PASS: ",left," vs ",right," owned and fitted vessels")
  stage=1
 for ship in arena.ships:
  # The fixture freezes AI, so taking over a previously frozen wingmate must
  # explicitly restore its physics. Production matches never freeze their AI.
  ship.set_physics_process(ship.player_controlled and session.loading_peers.is_empty() and not arena.finished)
  if ship.companion!=null:ship.companion.set_physics_process(false)
 var controls_confirmed := true
 for team in range(2):
  var id: int = session.fleet_commanders[team]
  var base := 0 if team == 0 else left
  var count := left if team == 0 else right
  var index := session._controlled_index(id)
  if index == base + count - 1: switched[id] = true
  controls_confirmed = controls_confirmed and switched.has(id) and index == base
 if arena.elapsed>.7 and not feedback_sent:
  feedback_sent=true
  arena.ships[0].health.damage(3,arena.ships.back(),"laser")
  arena.ships[left].health.damage(3,arena.ships[left-2],"laser")
 if stage==1 and arena.elapsed>3 and controls_confirmed and OS.get_environment("GD_TEST_DUEL_FORFEIT")!="1":
  stage=2
  var wing:=arena.ships[left-2]
  for index in range(left,arena.ships.size()):arena.ships[index].health.damage(10000,wing,"laser")
 if arena.finished and session.battle_result_pending.is_empty() and not session.battle_result_busy and stage!=3:
  if arena.winner!=0:push_error("DUEL_SERVER_WRONG_WINNER");quit(1);return false
  if OS.get_environment("GD_TEST_DUEL_FORFEIT")!="1" and session.metrics[session.fleet_commanders[0]].kills!=right:
   push_error("DUEL_SERVER_WING_CREDIT_MISSING");quit(1);return false
  print("DUEL_SERVER_PASS: correct winner, wingmate metrics and settled match")
  stage=3
 return false
