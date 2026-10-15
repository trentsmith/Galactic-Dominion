extends SceneTree
var main: Node
var elapsed := 0.0
var sent := false
var launched := false
var units_seen := false
var enemy_seen := false
var attack_seen := false
var captured := false
var notices: PackedStringArray = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://army-network-%s.json" % OS.get_environment("GD_TEST_USER")
 root.add_child(main)
 await process_frame
 main.online_api.base_url = OS.get_environment("GD_API_URL")
 var reply: Dictionary = await main.online_api.sign_in(OS.get_environment("GD_TEST_USER"), "integration-test-password")
 if reply.has("error"): quit(1); return
 main.network.status_changed.connect(func(message): notices.append(message))
 main.network.lobby_changed.connect(func(data):
  var ready := false
  for player in data.players:
   if player.peer == main.network.peer_id: ready = player.ready
  if not ready: main.network.ready_up.rpc_id(1, true)
  if data.leader == main.network.peer_id and data.players.size() == 2 and not launched:
   var all_ready := true
   for player in data.players: all_ready = all_ready and player.ready
   if all_ready:
    launched = true
    main.network.request_start.rpc_id(1, "free_roam"))
 await main.network.join_server("127.0.0.1", int(OS.get_environment("GD_TEST_PORT")))
func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 65:
  push_error("ARMY_CLIENT_TIMEOUT %s units=%s enemies=%s attack=%s capture=%s" % [notices, units_seen, enemy_seen, attack_seen, captured]); quit(1); return false
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch: return false
 var arena: FreeRoamMatch = main.network.arena
 if not sent:
  sent = true
  main.network.ship_event.rpc_id(1, "army_deploy", 2)
  main.network.ship_event.rpc_id(1, "army_deploy", 2)
 var army := arena.army
 var me: int = main.network.peer_id
 units_seen = units_seen or army.owned_count(me) == 5
 for unit in army.units.values():
  if unit.owner > 0 and unit.owner != me: enemy_seen = true
  if unit.flash > 0: attack_seen = true
 captured = army.worlds[0].owner == 0 and army.worlds[0].captures >= 1
 if units_seen and enemy_seen and attack_seen and captured:
  print("ARMY_CLIENT_PASS: authenticated deploy, cooldown, other player troops, AI combat and replicated world conquest")
  main.network.disconnect_session()
  quit(0)
 return false
