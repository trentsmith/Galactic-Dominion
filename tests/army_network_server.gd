# Deterministic fixture: parks ships and arranges the two real pilot squads
# around a world; production CreatureArmy.tick performs all combat and capture.
extends SceneTree
var main: Node
var elapsed := 0.0
var prepared := false
var combat_checked := false
func _initialize() -> void: call_deferred("run")
func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 65: push_error("ARMY_SERVER_TIMEOUT");quit(1);return false
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch: return false
 var arena: FreeRoamMatch = main.network.arena
 var army := arena.army
 for ship in arena.ships:
  ship.set_physics_process(false)
  ship.position = Vector3(90000, 0, 0)
 if not prepared and main.network.members.size() == 2:
  var ids: Array = main.network.members.keys()
  if army.owned_count(ids[0]) != 5 or army.owned_count(ids[1]) != 5: return false
  var center: Vector3 = army.worlds[0].position
  for unit in army.units.values():
   if unit.owner < 0: unit.position += Vector3(0, 10000, 0)
   else:
    unit.order = "assault"
    unit.world = 0
    unit.position = center + Vector3((unit.id % 5) * 10, 0, unit.team * 35)
    # Keep equal-sized squads, but team zero gets a fixture endurance bonus
    # so capture has a deterministic victor after real AI combat.
    if unit.team == 0: unit.hp = 500
  prepared = true
  print("ARMY_NETWORK_READY")
 if prepared and not combat_checked:
  var enemy_left := false
  var battle_damage := false
  for unit in army.units.values():
   if unit.owner > 0 and unit.team == 1: enemy_left = true
   if unit.owner > 0 and unit.team == 0 and unit.hp < 500: battle_damage = true
  if not enemy_left and battle_damage:
   combat_checked = true
   print("ARMY_HOST_COMBAT_PASS")
 if combat_checked and army.worlds[0].owner == 0:
  print("ARMY_HOST_CONQUEST_PASS")
 return false
