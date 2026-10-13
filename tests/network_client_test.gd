extends SceneTree
var main: Node
var launched := false
var match_seen := false
var initial_position := Vector3.ZERO
var initial_slot := -1
var moved := false
var switched := false
var switch_sent := false
var elapsed := 0.0
var finished_wait := 0.0
var completing := false
var expected_clients := 2

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://network-test-%d.json" % Time.get_ticks_usec()
 root.add_child(main)
 await process_frame
 expected_clients = int(OS.get_environment("GD_TEST_CLIENTS")) if not OS.get_environment("GD_TEST_CLIENTS").is_empty() else 2
 main.online_api.base_url = OS.get_environment("GD_API_URL")
 var response: Dictionary = await main.online_api.sign_in(OS.get_environment("GD_TEST_USER"), "integration-test-password")
 if response.has("error"):
  push_error("TEST_LOGIN_FAILED: " + str(response.error))
  quit(1)
  return
 main.network.lobby_changed.connect(_lobby)
 var joined: bool = await main.network.join_server("127.0.0.1", int(OS.get_environment("GD_TEST_PORT")))
 if not joined:
  quit(1)
  return
 print("CLIENT_AUTHENTICATED")

func _lobby(data: Dictionary) -> void:
 var all_ready: bool = data.players.size() == expected_clients
 var ready := false
 for player in data.players:
  if player.peer == main.network.peer_id:
   ready = player.ready
  all_ready = all_ready and player.ready
 if not ready:
  main.network.ready_up.rpc_id(1, true)
 if all_ready and data.leader == main.network.peer_id and not launched:
  launched = true
  main.network.request_start.rpc_id(1)

func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 35:
  push_error("NETWORK_TEST_TIMEOUT")
  quit(1)
  return false
 if not is_instance_valid(main) or not is_instance_valid(main.network.arena):
  return false
 var arena: BattleMatch = main.network.arena
 if not match_seen:
  match_seen = true
  initial_position = arena.pilot.ship.position
  initial_slot = main.network._controlled_index(main.network.peer_id)
  print("CLIENT_MATCH_STARTED")
  main.network.input_provider = func(): return {"thrust": Vector3(0, 0, -1), "steering": Vector2.ZERO, "roll": 0.0, "boost": false, "laser": true}
  main.network.ship_event.rpc_id(1, "target")
 if arena.pilot.ship.position.distance_to(initial_position) > 3:
  moved = true
 if arena.elapsed > 1 and not switch_sent:
  switch_sent = true
  main.network.ship_event.rpc_id(1, "switch", (initial_slot + 1) % 3 if expected_clients == 6 else 1)
 if main.network._controlled_index(main.network.peer_id) != initial_slot:
  switched = true
 if completing:
  return false
 if arena.finished:
  finished_wait += delta
  if finished_wait > 0.5:
   completing = true
   complete()
 return false

func complete() -> void:
   var reply: Dictionary = await main.online_api.refresh()
   if reply.has("data") and main.online_api.account.battles == 1 and moved and (switched if expected_clients == 2 else not switched):
    print("NETWORK_CLIENT_PASS: authoritative movement, %s, results and persistent rewards" % ("switching" if expected_clients == 2 else "occupied-ship ownership protection"))
    main.network.disconnect_session()
    await create_timer(0.65).timeout
    quit(0)
   else:
    push_error("NETWORK_CLIENT_FAIL: moved=%s switched=%s profile=%s" % [moved, switched, main.online_api.account.get("battles", -1)])
    quit(1)
