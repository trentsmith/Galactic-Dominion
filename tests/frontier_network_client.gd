extends SceneTree
var main: Node
var role:=""
var clock:=0.0
var launched:=false
var request_sent:=false
var switched:=false
var seen:=false
var finishing:=false
func _initialize() -> void:call_deferred("run")
func run() -> void:
 role=OS.get_environment("GD_TEST_USER")
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://co-op-"+role+".json";root.add_child(main);await process_frame
 main.network.status_changed.connect(func(words):print("COOP_STATUS ",words))
 main.online_api.base_url=OS.get_environment("GD_API_URL")
 var reply: Dictionary=await main.online_api.sign_in(role,"frontier-network-password")
 if reply.has("error"):push_error(str(reply));quit(1);return
 main.network.lobby_changed.connect(func(data):
  if data.leader==main.network.peer_id:
   var ready:=false
   for player in data.players:
    if player.peer==main.network.peer_id:ready=player.ready
   if not ready:main.network.ready_up.rpc_id(1,true)
   elif not launched:launched=true;main.network.request_start.rpc_id(1,"co_op"))
 await main.network.join_server("127.0.0.1",int(OS.get_environment("GD_TEST_PORT")))
func _process(delta: float) -> bool:
 clock+=delta
 if clock>40:push_error("Co-op client timeout "+role);quit(1);return false
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch:return false
 var roam: FreeRoamMatch=main.network.arena
 if not roam.cooperative or roam.ships[3].team!=0:push_error("Pilots are not allied");quit(1);return false
 if not switched:
  print("COOP_CLIENT_READY ",role)
  switched=true
  main.network.input_provider=func():return {"thrust":Vector3.ZERO,"steering":Vector2.ZERO,"roll":0.0,"boost":false,"laser":false,"frontier_use":seen}
  if role=="Coop_B":
   main.network.ship_event.rpc_id(1,"switch",1)
   main.network.ship_event.rpc_id(1,"frontier_start",0) # Nonleader request must be ignored.
 if role=="Coop_A" and clock>9 and not request_sent:request_sent=true;print("COOP_JOB_REQUEST");main.network.ship_event.rpc_id(1,"frontier_start",1)
 if not roam.frontier.active.is_empty():
  if not seen:print("COOP_BEACON_RECEIVED")
  seen=true
  Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;Input.action_press("frontier_use")
 elif seen and not finishing:finishing=true;finish()
 return false
func finish() -> void:
 Input.action_release("frontier_use")
 var reply: Dictionary=await main.online_api.refresh()
 var account: Dictionary=main.online_api.account
 if reply.has("error") or account.frontier.completed!=1 or account.salvage!=260:push_error("Shared reward missing "+str(account));quit(1);return
 if role=="Coop_B" and main.network._controlled_index(main.network.peer_id)!=4:push_error("Second group switched into another player's fleet");quit(1);return
 print("COOP_CLIENT_PASS: "+role+" / shared signal, allied team, switching and individual online reward")
 main.network.disconnect_session();await create_timer(.7).timeout;main.queue_free();await process_frame;quit(0)
