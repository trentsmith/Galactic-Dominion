extends SceneTree
var main: Node
var prepared:=false
var passed:=false
func _initialize() -> void:call_deferred("run")
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
func _process(_delta: float) -> bool:
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch:return false
 var arena: FreeRoamMatch=main.network.arena
 for ship in arena.ships:
  ship.set_physics_process(false);ship.position=Vector3(90000,0,0)
 if main.network.members.size()==2:
  arena.ships[0].position=arena.army.worlds[0].position
  if not prepared:
   prepared=true
   print("ARMY_HOST_COMBAT_PASS: no creature units in space")
  if not passed and arena.army.worlds[0].owner==0 and arena.army.worlds[0].captures>=1:
   passed=true;print("ARMY_HOST_CONQUEST_PASS: ships capture outposts")
 return false
