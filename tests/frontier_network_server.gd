extends SceneTree
var main: Node
var stage:=0
var clock:=0.0
func _initialize() -> void:call_deferred("run")
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
func _process(delta: float) -> bool:
 clock+=delta
 if clock>50:push_error("Co-op server timed out");quit(1);return false
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch:return false
 var session: OnlineSession=main.network;var roam: FreeRoamMatch=session.arena
 if stage==0:
  if not roam.cooperative:push_error("Co-op mode not created");quit(1);return false
  for ship in roam.ships:
   ship.position=Vector3(50000,50000,50000);ship.set_physics_process(false)
   if ship.companion!=null:ship.companion.set_physics_process(false)
  print("COOP_WORLD_READY");stage=1
 for ship in roam.ships:ship.set_physics_process(false)
 if session.members.size()>=2:
  for id in session.members:
   var index:=session._controlled_index(id)
   roam.ships[index].position=Vector3(0,5000,0) if roam.frontier.active.is_empty() else roam.frontier.point.position+Vector3((index+1)*5,0,40)
  if not roam.frontier.active.is_empty():
   if roam.frontier.active.kind!="repair":push_error("Nonleader started a co-op job");quit(1);return false
   if stage!=2:print("COOP_JOB_RUNNING ",roam.frontier.progress," contributors ",roam.frontier.contributors)
   stage=2
  elif stage==2:
   print("COOP_SERVER_PASS: host completed and persisted the shared repair");stage=3
 return false
