extends SceneTree
var main: Node
var elapsed := 0.0
var seen := false
var launched := false
var initial := Vector3.ZERO
var moved := false
var warp_sent := false
var warped := false
var dock_sent := false
var was_dead := false
var original_slot := -1
var appeared := false
var companion_shot_seen := false
var completing := false
var role := ""
var notices: PackedStringArray = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
 role = OS.get_environment("GD_TEST_USER")
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://roam-network-%d.json" % Time.get_ticks_usec()
 root.add_child(main)
 await process_frame
 main.online_api.base_url = OS.get_environment("GD_API_URL")
 var reply: Dictionary = await main.online_api.sign_in(role,"integration-test-password")
 if reply.has("error"): push_error(str(reply.error));quit(1);return
 main.network.status_changed.connect(func(message): notices.append(message))
 main.network.lobby_changed.connect(func(data):
  if data.leader == main.network.peer_id:
   var ready := false
   for player in data.players:
    if player.peer == main.network.peer_id: ready = player.ready
   if not ready: main.network.ready_up.rpc_id(1,true)
   elif not launched:
    launched = true
    main.network.request_start.rpc_id(1,"free_roam"))
 if not await main.network.join_server("127.0.0.1",int(OS.get_environment("GD_TEST_PORT"))): quit(1)
func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 45: push_error("ROAM_CLIENT_TIMEOUT " + str(notices));quit(1);return false
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch: return false
 var roam: FreeRoamMatch = main.network.arena
 if not seen:
  seen = true
  initial = roam.pilot.ship.position
  original_slot = main.network._controlled_index(main.network.peer_id)
  main.network.input_provider = func(): return {"thrust":Vector3(0,0,-1) if not warp_sent else Vector3.ZERO,"steering":Vector2.ZERO,"roll":0.0,"boost":false,"laser":false}
  print("ROAM_CLIENT_STARTED " + role)
 if roam.pilot.ship.position.distance_to(initial) > 3: moved = true
 if moved and not warp_sent:
  warp_sent = true
  main.network.ship_event.rpc_id(1,"warp",2 if role == "Roam_A" else 6)
 if warp_sent and roam.pilot.ship.position.distance_to(FreeRoamWorld.CENTERS[2 if role == "Roam_A" else 6]) < 250: warped = true
 if role == "Roam_A" and warped and roam.pilot.ship.health.hull < roam.pilot.ship.health.max_hull and not dock_sent:
  dock_sent = true
  main.network.ship_event.rpc_id(1,"dock")
 if original_slot >= 0 and not roam.ships[original_slot].alive: was_dead = true
 if roam.ships.size() == 27 and roam.ships[3].stats.ability == "barrage": appeared = true
 for child in roam.get_children():
  if child.has_meta("network_projectile") and child.get_meta("companion",false): companion_shot_seen = true
 if not completing and elapsed > (26 if role == "Roam_A" else 28) and was_dead and roam.ships[original_slot].alive:
  completing = true
  complete()
 return false
func complete() -> void:
 var reply: Dictionary = await main.online_api.refresh()
 var account_ok: bool = reply.has("data") and (main.online_api.account.wins == 2 if role == "Roam_A" else main.online_api.account.wins == 0)
 var world_ok: bool = not main.network.arena.finished and not main.network.arena.zone.visible
 if account_ok and world_ok and moved and warped and was_dead and appeared and (companion_shot_seen if role == "Roam_A" else true):
  print("ROAM_CLIENT_PASS: %s / movement, travel, late-join hull, PvE/PvP destruction, station respawn and permanent rewards" % role)
  main.network.disconnect_session()
  await create_timer(0.65).timeout
  main.queue_free()
  await process_frame
  await process_frame
  OS.delay_msec(50)
  quit(0)
 else:
  push_error("ROAM_CLIENT_FAIL account=%s world=%s moved=%s warp=%s death=%s hull=%s notices=%s" % [account_ok,world_ok,moved,warped,was_dead,appeared,str(notices)])
  quit(1)
