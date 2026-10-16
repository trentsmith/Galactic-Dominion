class_name OnlineSession
extends Node
signal lobby_changed(data)
signal status_changed(message)
var api: OnlineAPI
var arena: BattleMatch
var server_mode := false
var members: Dictionary = {}
var slot_owners: Array[int] = [0, 0, 0, 0, 0, 0]
var inputs: Dictionary = {}
var metrics: Dictionary = {}
var ship_totals: Array[Vector2] = []
var roster: Array[Dictionary] = []
var match_id := ""
var server_key := ""
var match_mode := "royale"
var lease_clock := 0.0
var roam_joining_slots: Array[int] = []
var max_seconds := 480.0
var aim := Vector2.ZERO
var input_provider: Callable
var peer_id := 0
var joining := false
var starting := false
var snapshot_clock := 0.0
var army_snapshot_clock := 0.0
var send_clock := 0.0
var desired_states: Array = []
var pending_peers: Dictionary = {}
var client_lobby: Dictionary = {}
var loading_peers: Dictionary = {}

func _ready() -> void:
 api = get_parent().online_api
 multiplayer.peer_connected.connect(_peer_connected)
 multiplayer.peer_disconnected.connect(_peer_disconnected)
 multiplayer.connected_to_server.connect(_connected)
 multiplayer.connection_failed.connect(func():
  joining = false
  status_changed.emit("Could not connect to the combat server."))
 multiplayer.server_disconnected.connect(_server_lost)

func start_server(port: int = 7777) -> Error:
 server_mode = true
 server_key = OS.get_environment("GD_SERVER_KEY")
 if server_key.is_empty():
  push_error("Use server/launch.py to start combat with its account-service key.")
  return ERR_UNAUTHORIZED
 api.base_url = OS.get_environment("GD_API_URL") if not OS.get_environment("GD_API_URL").is_empty() else "http://127.0.0.1:8080"
 var peer := ENetMultiplayerPeer.new()
 (multiplayer as SceneMultiplayer).server_relay = false
 var error := peer.create_server(port, 6, 3)
 if error != OK:
  push_error("Could not listen on combat UDP port %d" % port)
  return error
 multiplayer.multiplayer_peer = peer
 print("GALACTIC_COMBAT_READY port=%d" % port)
 return OK

func join_server(host: String, port: int = 7777) -> bool:
 if not client_lobby.is_empty():
  status_changed.emit("Leave your current lobby before joining another.")
  return false
 if api.token.is_empty() or joining:
  return false
 joining = true
 var ticket := await api.request("/ticket")
 if ticket.has("error"):
  joining = false
  status_changed.emit(str(ticket.error))
  return false
 var peer := ENetMultiplayerPeer.new()
 var error := peer.create_client(host, port, 3)
 if error != OK:
  joining = false
  status_changed.emit("Could not create multiplayer connection.")
  return false
 set_meta("ticket", str(ticket.data.ticket))
 multiplayer.multiplayer_peer = peer
 status_changed.emit("Connecting to combat server…")
 return true

func _peer_connected(id: int) -> void:
 if server_mode:
  pending_peers[id] = 0.0

func _connected() -> void:
 peer_id = multiplayer.get_unique_id()
 authenticate.rpc_id(1, str(get_meta("ticket", "")), str(ProjectSettings.get_setting("application/config/version", "0.16.0")))

@rpc("any_peer", "call_remote", "reliable")
func authenticate(ticket: String, version: String = "") -> void:
 if not server_mode:
  return
 var sender := multiplayer.get_remote_sender_id()
 if version != str(ProjectSettings.get_setting("application/config/version", "0.16.0")):
  reject.rpc_id(sender, "Different game build. Download the same version as the server.")
  multiplayer.multiplayer_peer.disconnect_peer(sender)
  return
 if not pending_peers.has(sender) or ticket.length() > 128 or starting or (is_instance_valid(arena) and not arena.finished and not arena is FreeRoamMatch):
  reject.rpc_id(sender, "The current arena is busy. Try again after its match.")
  multiplayer.multiplayer_peer.disconnect_peer(sender)
  return
 pending_peers.erase(sender)
 var reply := await api.request("/server/ticket", {"ticket": ticket}, HTTPClient.METHOD_POST, server_key)
 if not multiplayer.get_peers().has(sender):
  return
 if starting or (is_instance_valid(arena) and not arena.finished and not arena is FreeRoamMatch):
  reject.rpc_id(sender, "The arena has started. Join after the current match.")
  multiplayer.multiplayer_peer.disconnect_peer(sender)
  return
 if reply.has("error"):
  reject.rpc_id(sender, str(reply.error))
  multiplayer.multiplayer_peer.disconnect_peer(sender)
  return
 for existing in members.values():
  if existing.profile.user_id == reply.data.user_id:
   reject.rpc_id(sender, "This account is already in the lobby.")
   multiplayer.multiplayer_peer.disconnect_peer(sender)
   return
 if arena is FreeRoamMatch and not arena.finished:
  _join_running_roam(sender, reply.data)
  return
 var used_slots: Array[int] = []
 for existing in members.values():
  used_slots.append(int(existing.index))
 var index := -1
 for candidate in [0, 3, 1, 4, 2, 5]:
  if not candidate in used_slots:
   index = candidate
   break
 if index < 0:
  reject.rpc_id(sender, "Lobby is full.")
  multiplayer.multiplayer_peer.disconnect_peer(sender)
  return
 members[sender] = {"profile": reply.data, "index": index, "ready": false}
 _broadcast_lobby()

@rpc("authority", "call_remote", "reliable")
func reject(message: String) -> void:
 joining = false
 status_changed.emit(message)

func _broadcast_lobby() -> void:
 var entries: Array = []
 for id in members:
  entries.append({"peer": id, "name": members[id].profile.commander_name, "team": int(members[id].index) / 3, "slot": int(members[id].index) % 3, "ready": members[id].ready})
 var leader: int = members.keys()[0] if not members.is_empty() else 0
 for id in members:
  if not _connected_peer(id):
   continue
  receive_lobby.rpc_id(id, {"players": entries, "leader": leader, "active": is_instance_valid(arena) and not arena.finished})

@rpc("authority", "call_remote", "reliable")
func receive_lobby(data: Dictionary) -> void:
 joining = false
 client_lobby = data
 lobby_changed.emit(data)
 status_changed.emit("Lobby connected. Ready up; the first pilot can launch with AI filling empty slots.")

@rpc("any_peer", "call_remote", "reliable")
func ready_up(ready: bool) -> void:
 var sender := multiplayer.get_remote_sender_id()
 if server_mode and members.has(sender) and not starting and not (is_instance_valid(arena) and not arena.finished):
  members[sender].ready = ready
  _broadcast_lobby()

@rpc("any_peer", "call_remote", "reliable")
func request_start(mode: String = "royale") -> void:
 var sender := multiplayer.get_remote_sender_id()
 if not server_mode or starting or members.is_empty() or sender != members.keys()[0] or (is_instance_valid(arena) and not arena.finished):
  return
 for member in members.values():
  if not member.ready:
   reject.rpc_id(sender, "All connected pilots must be ready.")
   return
 if mode not in ["royale", "free_roam"]: return
 match_mode = mode
 starting = true
 roster.clear()
 match_id = Crypto.new().generate_random_bytes(16).hex_encode()
 for member in members.values():
  roster.append({"user_id": member.profile.user_id, "team": int(member.index) / 3})
 var reply := await api.request("/server/start", {"match_id": match_id, "roster": roster, "mode": match_mode}, HTTPClient.METHOD_POST, server_key)
 if reply.has("error"):
  starting = false
  for id in members:
   reject.rpc_id(id, str(reply.error))
  return
 if is_instance_valid(arena):
  remove_child(arena)
  arena.queue_free()
 inputs.clear()
 metrics.clear()
 ship_totals.clear()
 var stats_list: Array[ShipStats] = []
 var names: Array[String] = []
 var crew_names: Array[String] = []
 slot_owners = [0, 0, 0, 0, 0, 0]
 for index in range(6):
  var stats: ShipStats = BattleMatch.CLASSES[index % 3]
  var ship_name := "AI %d" % (index + 1)
  var crew_name := "AI flight computer"
  for id in members:
   if members[id].index == index:
    var data: Dictionary = members[id].profile
    # start_match refreshes and locks inventory before any stats are built.
    for fresh in reply.data.get("profiles", []):
     if fresh.user_id == data.user_id:
      data = fresh
    var profile := PlayerProfile.new()
    profile.inventory = data.inventory
    profile.ship_classes.clear()
    for hull in data.ship_classes:
     profile.ship_classes.append(str(hull))
    profile.loadouts.clear()
    for fitting in data.loadouts:
     profile.loadouts.append(fitting)
    stats = profile.configured_stats(index % 3)
    ship_name = str(data.commander_name)
    var crew := CollectionCatalog.find(str(data.loadouts[index % 3].crew))
    crew_name = crew.display_name if crew != null else "Unassigned"
    slot_owners[index] = id
    metrics[id] = {"kills": 0.0, "damage": 0.0, "user_id": data.user_id}
  stats_list.append(stats)
  names.append(ship_name)
  crew_names.append(crew_name)
  ship_totals.append(Vector2.ZERO)
 arena = FreeRoamMatch.new() if match_mode == "free_roam" else BattleMatch.new()
 arena.name = "Arena"
 arena.network_role = "server"
 arena.preconfigured_stats = stats_list
 arena.max_duration = max_seconds
 add_child(arena)
 while slot_owners.size() < arena.ships.size():
  slot_owners.append(0)
  ship_totals.append(Vector2.ZERO)
 if arena is FreeRoamMatch:
  arena.encounter_won.connect(_roam_encounter_won)
 for index in range(6):
  arena.ships[index].callsign = names[index]
  arena.ships[index].crew_name = crew_names[index]
  arena.ships[index].player_controlled = slot_owners[index] != 0
 for ship in arena.ships:
  ship.brain.command = "attack"
 arena.ended.connect(_server_finished)
 arena.set_physics_process(false)
 for ship in arena.ships:
  ship.set_physics_process(false)
 loading_peers.clear()
 for id in members:
  loading_peers[id] = 0.0
 var serialized: Array = []
 for stats in stats_list:
  var entry := {}
  for property in stats.get_property_list():
   if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
    entry[property.name] = stats.get(property.name)
  serialized.append(entry)
 for id in members:
  if _connected_peer(id):
   begin_match.rpc_id(id, serialized, names, slot_owners, crew_names, match_mode)
 starting = false

@rpc("authority", "call_remote", "reliable")
func begin_match(serialized: Array, names: Array, owners: Array, crew_names: Array, mode: String = "royale") -> void:
 if server_mode or serialized.size() != 6:
  return
 var host := get_parent()
 if is_instance_valid(host.menu):
  host.menu.queue_free()
 if is_instance_valid(arena):
  remove_child(arena)
  arena.queue_free()
 match_mode = mode
 arena = FreeRoamMatch.new() if mode == "free_roam" else BattleMatch.new()
 arena.name = "Arena"
 arena.network_role = "client"
 for entry in serialized:
  var stats := ShipStats.new()
  for key in entry:
   stats.set(key, entry[key])
  arena.preconfigured_stats.append(stats)
 add_child(arena)
 host.battle = arena
 if arena is FreeRoamMatch:
  arena.travel_requested.connect(func(index): ship_event.rpc_id(1, "warp", index))
  arena.army_requested.connect(func(action, argument): ship_event.rpc_id(1, "army_" + action, argument))
  arena.dock_requested.connect(func(): ship_event.rpc_id(1, "dock"))
 slot_owners.clear()
 for owner in owners:
  slot_owners.append(int(owner))
 for index in range(6):
  arena.ships[index].callsign = str(names[index])
  arena.ships[index].crew_name = str(crew_names[index])
 _choose_client_ship()
 arena.fleet.current_command = "attack"
 aim = Vector2.ZERO
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 status_changed.emit("Online free-roam running" if match_mode == "free_roam" else "Online match running")
 match_loaded.rpc_id(1)

func _choose_client_ship() -> void:
 for index in range(6):
  if slot_owners[index] == peer_id:
   arena.pilot.take_control(arena.ships[index])
   arena.fleet.ships.clear()
   var team := arena.ships[index].team
   for ship in arena.ships:
    if ship.team == team:
     arena.fleet.ships.append(ship)
   return

func _controlled_index(id: int) -> int:
 return slot_owners.find(id)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func send_input(thrust: Vector3, steering: Vector2, roll: float, boost: bool, laser: bool) -> void:
 if not server_mode or not is_instance_valid(arena) or arena.finished:
  return
 var sender := multiplayer.get_remote_sender_id()
 if _controlled_index(sender) < 0 or not thrust.is_finite() or not steering.is_finite() or not is_finite(roll):
  return
 inputs[sender] = {"thrust": thrust.limit_length(), "steering": steering.limit_length(0.8), "roll": clampf(roll, -1, 1), "boost": boost, "laser": laser, "age": 0.0}

@rpc("any_peer", "call_remote", "reliable")
func ship_event(action: String, argument: int = 0) -> void:
 if not server_mode or not is_instance_valid(arena) or arena.finished:
  return
 var sender := multiplayer.get_remote_sender_id()
 var index := _controlled_index(sender)
 if index < 0:
  return
 var ship := arena.ships[index]
 if action == "switch":
  var requested := ship.team * 3 + clampi(argument, 0, 2)
  if slot_owners[requested] != 0 and slot_owners[requested] != sender or not arena.ships[requested].alive:
   return
  slot_owners[index] = 0
  ship.player_controlled = false
  slot_owners[requested] = sender
  arena.ships[requested].player_controlled = true
  inputs.erase(sender)
 elif ship.alive:
  if arena is FreeRoamMatch:
   if action.begins_with("army_"):
    army_notice.rpc_id(sender, arena.army_action(sender, ship, action.trim_prefix("army_"), argument))
    return
   if action == "warp":
    var moved: bool = arena.travel_ship(ship, argument)
    roam_notice.rpc_id(sender, "Arrived / " + FreeRoamWorld.NAMES[argument] if moved else "Warp denied: leave combat before travelling.")
    return
   if action == "dock":
    var survey: String = arena.survey_landmark(sender, ship)
    if not survey.is_empty():
     army_notice.rpc_id(sender, survey)
     return
    var serviced: bool = arena.service_ship(ship)
    roam_notice.rpc_id(sender, "Station service complete." if serviced else "Service denied: approach a station outside combat.")
    return
  match action:
   "target": ship.targeting.cycle()
   "missile": ship.weapons.fire(true)
   "ability": ship.activate_ability()
   "command":
    var commands := ["follow", "attack", "defend", "regroup", "retreat"]
    if argument < 0 or argument >= commands.size():
     return
    for ally in arena.ships:
     if ally.team == ship.team and not ally.player_controlled:
      ally.brain.command = commands[argument]
      ally.brain.leader = ship
      ally.brain.commanded_target = ship.targeting.target

func _unhandled_input(event: InputEvent) -> void:
 if server_mode or not is_instance_valid(arena) or arena.finished:
  return
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  aim = (aim + event.relative * get_parent().sensitivity).limit_length(0.8)
 for index in range(3):
  if event.is_action_pressed("ship_%d" % (index + 1)):
   ship_event.rpc_id(1, "switch", index)
 for index in range(5):
  if event.is_action_pressed("command_%d" % (index + 1)):
   arena.fleet.current_command = ["follow", "attack", "defend", "regroup", "retreat"][index]
   ship_event.rpc_id(1, "command", index)
 for action in ["target", "missile", "ability"]:
  if event.is_action_pressed(action):
   ship_event.rpc_id(1, action)

func _physics_process(delta: float) -> void:
 if server_mode:
  for id in pending_peers.keys():
   pending_peers[id] += delta
   if pending_peers[id] > 15:
    pending_peers.erase(id)
    multiplayer.multiplayer_peer.disconnect_peer(id)
  if not is_instance_valid(arena) or arena.finished:
   return
  if not loading_peers.is_empty():
   for id in loading_peers.keys():
    loading_peers[id] += delta
    if loading_peers[id] > 20:
     loading_peers.erase(id)
     multiplayer.multiplayer_peer.disconnect_peer(id)
   _start_if_loaded()
   return
  for id in members:
   var index := _controlled_index(id)
   if index < 0:
    continue
   var ship := arena.ships[index]
   if arena is FreeRoamMatch:
    for troop in arena.army.units.values():
     if troop.owner == id and troop.order == "follow": troop.leader = index
   if not ship.alive:
    for candidate in range(ship.team * 3, ship.team * 3 + 3):
     if arena.ships[candidate].alive and slot_owners[candidate] == 0:
      slot_owners[index] = 0
      slot_owners[candidate] = id
      arena.ships[candidate].player_controlled = true
      break
    continue
   var input: Dictionary = inputs.get(id, {"thrust": Vector3.ZERO, "steering": Vector2.ZERO, "roll": 0.0, "boost": false, "laser": false, "age": 1.0})
   input.age += delta
   var active: bool = input.age < 0.3
   ship.movement.thrust = input.thrust if active else Vector3.ZERO
   ship.movement.boost_requested = input.boost and active
   if active:
    ship.rotate_object_local(Vector3.UP, -input.steering.x * ship.stats.turn_speed * delta)
    ship.rotate_object_local(Vector3.RIGHT, -input.steering.y * ship.stats.turn_speed * delta)
    ship.rotate_object_local(Vector3.FORWARD, input.roll * 1.8 * delta)
    ship.basis = ship.basis.orthonormalized()
    if input.laser:
     ship.weapons.fire()
  if match_mode == "free_roam":
   lease_clock += delta
   if lease_clock >= 60:
    lease_clock = 0
    _renew_roam_lease()
  army_snapshot_clock += delta
  snapshot_clock += delta
  if snapshot_clock >= 1.0 / 15.0:
   snapshot_clock = 0
   var states: Array = []
   for index in range(arena.ships.size()):
    var ship := arena.ships[index]
    var owner := slot_owners[index]
    var totals := Vector2(ship.kills, ship.damage_dealt)
    if metrics.has(owner):
     metrics[owner].kills += maxf(0, totals.x - ship_totals[index].x)
     metrics[owner].damage += maxf(0, totals.y - ship_totals[index].y)
    ship_totals[index] = totals
    states.append({"position": ship.position, "rotation": ship.basis.get_rotation_quaternion(), "velocity": ship.velocity, "hull": ship.health.hull, "shield": ship.health.shield, "boost": ship.movement.boost_energy, "boosting": ship.movement.boost_requested, "alive": ship.alive, "laser": ship.weapons.laser_remaining, "missile": ship.weapons.missile_remaining, "ability": ship.ability_remaining, "recharge": ship.ability_cooldown, "target": arena.ships.find(ship.targeting.target), "lock": ship.targeting.lock_time, "flash": ship.muzzle_flash})
   var bullets: Array = []
   for child in arena.get_children():
    if child is SpaceProjectile:
     bullets.append({"position": child.position, "direction": child.direction, "team": child.team, "missile": child.spec.tracking, "companion": child.companion_shot, "color": child.projectile_color, "style": child.spec.impact_style})
   for id in members:
    if _connected_peer(id):
     if arena is FreeRoamMatch and army_snapshot_clock >= 0.2:
      receive_army.rpc_id(id, arena.army.snapshot())
     receive_snapshot.rpc_id(id, states, slot_owners, arena.elapsed, arena.zone.radius, bullets)
   if army_snapshot_clock >= 0.2: army_snapshot_clock = 0.0
 else:
  if not is_instance_valid(arena) or arena.finished:
   return
  for index in range(mini(arena.ships.size(), desired_states.size())):
   var ship := arena.ships[index]
   var state: Dictionary = desired_states[index]
   ship.position = state.position if ship.position.distance_to(state.position) > 1000 else ship.position.lerp(state.position, minf(1, delta * 18))
   ship.basis = ship.basis.slerp(Basis(state.rotation), minf(1, delta * 18)).orthonormalized()
  arena.pilot.update_camera(delta)
  aim = aim.move_toward(Vector2.ZERO, delta * 0.75)
  send_clock += delta
  if send_clock >= 1.0 / 30.0:
   send_clock = 0
   var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
   var thrust := Vector3(Input.get_axis("strafe_left", "strafe_right"), Input.get_axis("down", "up"), Input.get_axis("forward", "reverse")) if captured else Vector3.ZERO
   var steering := aim * Vector2(1, -1 if get_parent().inverted else 1) if captured else Vector2.ZERO
   if input_provider.is_valid():
    var supplied: Dictionary = input_provider.call()
    send_input.rpc_id(1, supplied.thrust, supplied.steering, supplied.roll, supplied.boost, supplied.laser)
   else:
    send_input.rpc_id(1, thrust, steering, Input.get_axis("roll_left", "roll_right") if captured else 0.0, captured and Input.is_action_pressed("boost"), captured and Input.is_action_pressed("laser"))

@rpc("authority", "call_remote", "reliable", 2)
func receive_snapshot(states: Array, owners: Array, elapsed: float, radius: float, bullets: Array) -> void:
 if not is_instance_valid(arena) or states.size() != arena.ships.size() or owners.size() != arena.ships.size():
  return
 desired_states = states
 var old_index := _controlled_index(peer_id)
 slot_owners.clear()
 for owner in owners:
  slot_owners.append(int(owner))
 if _controlled_index(peer_id) != old_index:
  _choose_client_ship()
 arena.elapsed = elapsed
 arena.zone.radius = radius
 for ring in arena.zone.rings:
  ring.scale = Vector3.ONE * radius
 for index in range(arena.ships.size()):
  var ship := arena.ships[index]
  var state: Dictionary = states[index]
  if ship.alive and not state.alive:
   SpaceEffects.burst(arena, ship.position, Color(1, 0.5, 0.2), 12)
  ship.alive = state.alive
  ship.visible = state.alive
  if state.alive and (state.shield < ship.health.shield or state.hull < ship.health.hull):
   SpaceEffects.burst(arena, ship.position, Color(0.15, 0.7, 1) if state.shield < ship.health.shield else Color(1, 0.45, 0.1), 4 if state.shield < ship.health.shield else 1.8)
  if ship == arena.pilot.ship:
   if state.shield < ship.health.shield or state.hull < ship.health.hull:
    SpaceAudio.play("shield")
   if state.flash > 0 and not ship.muzzle_mesh.visible:
    SpaceAudio.play("laser")
  ship.health.hull = state.hull
  ship.health.shield = state.shield
  ship.velocity = state.velocity
  ship.movement.boost_energy = state.boost
  ship.movement.boost_requested = state.boosting
  ship.health.dead = not state.alive
  ship.weapons.laser_remaining = state.laser
  ship.weapons.missile_remaining = state.missile
  ship.ability_remaining = state.ability
  ship.ability_cooldown = state.recharge
  ship.targeting.target = arena.ships[int(state.target)] if state.target >= 0 else null
  ship.targeting.lock_time = state.lock
  ship.muzzle_mesh.visible = state.flash > 0
  ship.shield_mesh.visible = state.ability > 0 and ship.stats.ability == "aegis"
  ship.outside_time = 1.0 if ship.position.length() > radius else 0.0
 # Render server-owned projectiles; clients never apply damage.
 for child in arena.get_children():
  if child.has_meta("network_projectile"):
   child.queue_free()
 for bullet in bullets:
  var mesh := MeshInstance3D.new()
  mesh.set_meta("network_projectile", true)
  mesh.set_meta("companion", bullet.get("companion", false))
  var shape := SphereMesh.new()
  shape.radius = 0.28 if bullet.get("companion", false) else 0.32 if bullet.missile else 0.18
  shape.height = shape.radius * 2
  mesh.mesh = shape
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = bullet.color if bullet.get("color", Color.TRANSPARENT).a > 0 else Color(1, 0.7, 0.2) if bullet.missile else Color(0.2, 0.8, 1) if bullet.team == 0 else Color(1, 0.3, 0.2)
  mesh.material_override = material
  arena.add_child(mesh)
  mesh.position = bullet.position
  FleetCompanionArt.attack(mesh,str(bullet.get("style","")))

func _server_finished(winner: int, reason: String) -> void:
 if match_mode == "free_roam":
  await api.request("/server/roam/end", {"match_id": match_id}, HTTPClient.METHOD_POST, server_key)
  return
 var results := {}
 for entry in roster:
  results[entry.user_id] = {"kills": 0, "damage": 0.0}
  for id in metrics:
   if metrics[id].user_id == entry.user_id:
    results[entry.user_id] = metrics[id]
 var reply := await api.request("/server/finish", {"match_id": match_id, "winner": winner, "metrics": results}, HTTPClient.METHOD_POST, server_key)
 var message := reason + (" · Online rewards saved" if reply.has("data") else " · Reward save failed: " + str(reply.get("error", "unknown")))
 var statistics: Array = []
 for ship in arena.ships:
  statistics.append({"kills": ship.kills, "damage": ship.damage_dealt, "shots": ship.shots, "hits": ship.hits})
 for id in members:
  if _connected_peer(id):
   var personal_message := message
   var prizes: Dictionary = reply.get("data", {}).get("victory_ships", {})
   var prize := CollectionCatalog.find(str(prizes.get(members[id].profile.user_id, "")))
   if prize != null:
    personal_message += "\nPERMANENT VICTORY SHIP: " + prize.display_name + " — available in Online Fleet / Marketplace"
   receive_result.rpc_id(id, winner, personal_message, statistics)

@rpc("authority", "call_remote", "reliable")
func receive_result(winner: int, reason: String, statistics: Array) -> void:
 if is_instance_valid(arena):
  for index in range(mini(6, statistics.size())):
   arena.ships[index].kills = int(statistics[index].kills)
   arena.ships[index].damage_dealt = float(statistics[index].damage)
   arena.ships[index].shots = int(statistics[index].shots)
   arena.ships[index].hits = int(statistics[index].hits)
  arena.finish(winner, reason)
 await api.refresh()

func _peer_disconnected(id: int) -> void:
 if not server_mode:
  return
 pending_peers.erase(id)
 if match_mode == "free_roam" and members.has(id):
  _leave_roam_account(str(members[id].profile.user_id))
 if arena is FreeRoamMatch:
  arena.army.remove_owner(id)
 members.erase(id)
 inputs.erase(id)
 loading_peers.erase(id)
 _start_if_loaded()
 var index := _controlled_index(id)
 if index >= 0:
  slot_owners[index] = 0
  if is_instance_valid(arena):
   arena.ships[index].player_controlled = false
   arena.ships[index].movement.boost_requested = false
 if members.is_empty() and is_instance_valid(arena) and not arena.finished:
  arena.finish(-1, "All pilots disconnected")
 if not is_instance_valid(arena):
  _broadcast_lobby()

func _server_lost() -> void:
 joining = false
 if not server_mode:
  status_changed.emit("Combat server disconnected. Return to the online menu to reconnect.")
  if is_instance_valid(arena) and not arena.finished:
   arena.finish(-1, "Combat server disconnected")

func disconnect_session() -> void:
 if server_mode:
  return
 joining = false
 arena = null
 desired_states.clear()
 client_lobby.clear()
 var old_peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
 if old_peer != null and old_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
  old_peer.disconnect_peer(1)
  await get_tree().create_timer(0.5).timeout
  old_peer.close()
  if multiplayer.multiplayer_peer == old_peer:
   multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
 elif old_peer != null:
  old_peer.close()
  multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func return_to_menu() -> void:
 disconnect_session()
 get_parent().return_to_menu()

func start_battle() -> void:
 disconnect_session()
 get_parent().return_to_menu()
 get_parent().show_online()

func _connected_peer(id: int) -> bool:
 if not id in multiplayer.get_peers():
  return false
 var packet_peer := (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(id)
 return packet_peer != null and packet_peer.get_state() == ENetPacketPeer.STATE_CONNECTED

@rpc("any_peer", "call_remote", "reliable")
func match_loaded() -> void:
 if not server_mode:
  return
 var sender := multiplayer.get_remote_sender_id()
 loading_peers.erase(sender)
 _start_if_loaded()

func _start_if_loaded() -> void:
 if server_mode and loading_peers.is_empty() and is_instance_valid(arena) and not arena.finished:
  arena.set_physics_process(true)
  for ship in arena.ships:
   ship.set_physics_process(true)

@rpc("any_peer", "call_remote", "reliable")
func choose_team(team: int) -> void:
 var sender := multiplayer.get_remote_sender_id()
 if not server_mode or not members.has(sender) or team not in [0, 1] or starting or (is_instance_valid(arena) and not arena.finished):
  return
 var used: Array[int] = []
 for id in members:
  if id != sender:
   used.append(int(members[id].index))
 for index in range(team * 3, team * 3 + 3):
  if not index in used:
   members[sender].index = index
   members[sender].ready = false
   _broadcast_lobby()
   return
 reject.rpc_id(sender, "That team already has three pilots.")

func _renew_roam_lease() -> void:
 var reply := await api.request("/server/roam/lease", {"match_id": match_id}, HTTPClient.METHOD_POST, server_key)
 if reply.has("error"):
  push_error("Free-roam inventory lease failed: " + str(reply.error))

func _roam_encounter_won(attacker: CombatShip, victim: CombatShip, event_id: String) -> void:
 var index := arena.ships.find(attacker)
 if index < 0: return
 var owner := slot_owners[index]
 if not members.has(owner): return
 var reply := await api.request("/server/roam/reward", {"match_id": match_id, "event_id": event_id, "user_id": members[owner].profile.user_id, "damage": float(victim.health.damage_by_attacker.get(attacker.get_instance_id(), 0))}, HTTPClient.METHOD_POST, server_key)
 if not _connected_peer(owner): return
 if reply.has("error"):
  roam_notice.rpc_id(owner, "Encounter reward could not save: " + str(reply.error))
 elif reply.data.has("ship"):
  var prize := CollectionCatalog.find(str(reply.data.ship))
  roam_notice.rpc_id(owner, "ENCOUNTER WON / PERMANENT SHIP: " + prize.display_name + " / +60 salvage and 2 discoveries saved online")

@rpc("authority", "call_remote", "reliable")
func roam_notice(message: String) -> void:
 if arena is FreeRoamMatch:
  arena.log_label.text = message
  arena.map_panel.visible = false
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 status_changed.emit(message)

func _leave_roam_account(user_id: String) -> void:
 await api.request("/server/roam/leave", {"match_id": match_id, "user_id": user_id}, HTTPClient.METHOD_POST, server_key)

func _join_running_roam(id: int, account: Dictionary) -> void:
 var index := -1
 for candidate in [0, 3, 1, 4, 2, 5]:
  if slot_owners[candidate] == 0 and not candidate in roam_joining_slots:
   index = candidate
   break
 if index < 0:
  reject.rpc_id(id, "Free-roam session has six pilots already.")
  multiplayer.multiplayer_peer.disconnect_peer(id)
  return
 roam_joining_slots.append(index)
 var session_id := match_id
 var reply := await api.request("/server/roam/join", {"match_id": session_id, "user_id": account.user_id, "team": index / 3}, HTTPClient.METHOD_POST, server_key)
 roam_joining_slots.erase(index)
 if reply.has("error"):
  if _connected_peer(id): reject.rpc_id(id, str(reply.error))
  return
 if not _connected_peer(id) or not arena is FreeRoamMatch or arena.finished or match_id != session_id:
  await api.request("/server/roam/leave", {"match_id": session_id, "user_id": account.user_id}, HTTPClient.METHOD_POST, server_key)
  return
 account = reply.data.profile
 var profile := PlayerProfile.new()
 profile.inventory = account.inventory
 profile.ship_classes.clear()
 for hull in account.ship_classes: profile.ship_classes.append(str(hull))
 profile.loadouts.clear()
 for fitting in account.loadouts: profile.loadouts.append(fitting)
 var stats := profile.configured_stats(index % 3)
 var crew := CollectionCatalog.find(str(account.loadouts[index % 3].crew))
 var crew_name := crew.display_name if crew != null else "Unassigned"
 members[id] = {"profile": account, "index": index, "ready": true}
 metrics[id] = {"kills": 0.0, "damage": 0.0, "user_id": account.user_id}
 slot_owners[index] = id
 arena.replace_pilot_ship(index, stats, str(account.commander_name), crew_name, true)
 ship_totals[index] = Vector2.ZERO
 var serialized := _serialize_stats(stats)
 for other in members:
  if other != id and _connected_peer(other):
   refit_roam_ship.rpc_id(other, index, serialized, str(account.commander_name), crew_name)
 var configurations: Array = []
 var names: Array[String] = []
 var crew_names: Array[String] = []
 for slot in range(6):
  configurations.append(_serialize_stats(arena.ships[slot].stats))
  names.append(arena.ships[slot].callsign)
  crew_names.append(arena.ships[slot].crew_name)
 begin_match.rpc_id(id, configurations, names, slot_owners, crew_names, "free_roam")

func _serialize_stats(stats: ShipStats) -> Dictionary:
 var result := {}
 for property in stats.get_property_list():
  if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
   result[property.name] = stats.get(property.name)
 return result

@rpc("authority", "call_remote", "reliable")
func refit_roam_ship(index: int, serialized: Dictionary, callsign: String, crew_name: String) -> void:
 if not arena is FreeRoamMatch or index < 0 or index >= 6: return
 var stats := ShipStats.new()
 for key in serialized: stats.set(key, serialized[key])
 arena.replace_pilot_ship(index, stats, callsign, crew_name, false)

@rpc("authority", "call_remote", "reliable", 2)
func receive_army(data: Dictionary) -> void:
 if not server_mode and arena is FreeRoamMatch:
  arena.army.apply_snapshot(data)

@rpc("authority", "call_remote", "reliable")
func army_notice(message: String) -> void:
 if arena is FreeRoamMatch: arena.log_label.text = message
 status_changed.emit(message)
