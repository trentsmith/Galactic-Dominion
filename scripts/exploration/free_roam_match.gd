class_name FreeRoamMatch
extends BattleMatch
signal encounter_won(attacker, victim, event_id)
signal travel_requested(index)
signal army_requested(action, argument)
signal landing_requested(index)
signal dock_requested

var war: WorldWar
var war_status: Label
var surveyed: Dictionary = {}
var army: CreatureArmy
var army_status: Label
var army_species: OptionButton
var world: FreeRoamWorld
var map_panel: PanelContainer
var info: Label
var prompt: Label
var log_label: Label
var respawns: Dictionary = {}
var encounters: Array[Dictionary] = []
var beacons: Array[Node3D] = []
var scan_progress := 0.0
var scan_index := -1
var reward_sequence := 0
var current_region := -1

func _ready() -> void:
 battle_id = Crypto.new().generate_random_bytes(16).hex_encode()
 world = FreeRoamWorld.new()
 add_child(world)
 zone = BattleZone.new()
 add_child(zone)
 zone.visible = false
 zone.radius = 1000000000.0
 camera = Camera3D.new()
 camera.far = 30000
 camera.current = network_role != "server"
 add_child(camera)
 pilot = PlayerPilot.new()
 pilot.camera = camera
 add_child(pilot)
 fleet = FleetManager.new()
 fleet.pilot = pilot
 add_child(fleet)
 var count := 3 if network_role == "offline" else 6
 for index in range(count):
  var ship := CombatShip.new()
  ship.team = 0 if network_role == "offline" else index / 3
  ship.fleet_slot = index % 3
  ship.stats = profile.configured_stats(index) if profile != null else preconfigured_stats[index] if preconfigured_stats.size() == 6 else CLASSES[index % 3]
  ship.callsign = "Explorer %d" % (index + 1)
  ship.position = FreeRoamWorld.CENTERS[ship.team] + Vector3((index % 3 - 1) * 35, 0, 160)
  add_child(ship)
  ships.append(ship)
  ship.targeting.selection_range = 1400
  ship.brain.roaming = true
  ship.brain.sensor_range = 1100
  ship.brain.roam_center = FreeRoamWorld.CENTERS[ship.team] + Vector3(0, 0, -800)
  if profile != null:
   var crew := CollectionCatalog.find(str(profile.loadouts[index].crew))
   ship.crew_name = crew.display_name if crew != null else "Unassigned"
  if ship.team == 0:
   fleet.ships.append(ship)
   if network_role == "offline": ship.eliminated.connect(fleet.on_eliminated)
  ship.eliminated.connect(_on_eliminated)
  ship.set_meta("spawn_protection", 8.0)
 fleet.switch_to(0)
 fleet.issue_command("follow")
 for region in range(FreeRoamWorld.CENTERS.size()):
  _create_encounter(region)
 if network_role == "offline":
  _create_signals()
 else:
  pilot.set_physics_process(false)
  pilot.set_process_unhandled_input(false)
  fleet.set_process_unhandled_input(false)
  for ship in ships:
   ship.player_controlled = false
   ship.brain.command = "attack"
   if network_role == "client":
    ship.set_physics_process(false)
    ship.collision_layer = 0
    ship.collision_mask = 0
 hud = BattleHUD.new()
 hud.battle = self
 add_child(hud)
 army = CreatureArmy.new()
 army.battle = self
 add_child(army)
 war = WorldWar.new()
 war.battle = self
 _build_roam_ui()
 if network_role == "server":
  hud.visible = false
  map_panel.get_parent().visible = false
 else:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_encounter(region: int) -> void:
 var members: Array[CombatShip] = []
 for slot in range(3):
  var ship := CombatShip.new()
  ship.team = FreeRoamWorld.FACTIONS[region]
  ship.fleet_slot = slot
  ship.stats = CollectionCatalog.SHIP_TYPES.values()[(region + slot) % 5].duplicate(true)
  ship.stats.crew_id = ["crew_nyx", "crew_kael", "crew_orith", "crew_threx"][region % 4]
  ship.crew_name = CollectionCatalog.find(ship.stats.crew_id).display_name
  ship.callsign = ["Crimson Patrol", "Crimson Marauders", "Pelagian Wardens", "Eldritch Hunters"][region % 4] + " %d" % (slot + 1)
  ship.position = FreeRoamWorld.CENTERS[region] + Vector3(700 + slot * 35, slot * 20, -300)
  add_child(ship)
  ship.targeting.selection_range = 1400
  ship.brain.roaming = true
  ship.brain.sensor_range = 850
  ship.brain.roam_center = ship.position
  ship.brain.command = "attack"
  ship.eliminated.connect(_on_eliminated)
  ships.append(ship)
  members.append(ship)
 encounters.append({"ships": members, "region": region, "credited": false, "kills": 0, "wave": 0, "respawn": -1.0})
 if network_role != "offline": return
 var trader := CombatShip.new()
 trader.team = 0
 trader.stats = CollectionCatalog.SHIP_TYPES.support
 trader.callsign = "Civilian escort / " + FreeRoamWorld.NAMES[region]
 trader.position = FreeRoamWorld.CENTERS[region] + Vector3(-400, 120, 350)
 add_child(trader)
 trader.brain.roaming = true
 trader.brain.sensor_range = 400
 trader.brain.command = "defend"
 trader.brain.roam_center = trader.position
 trader.eliminated.connect(_on_eliminated)
 ships.append(trader)

func _create_signals() -> void:
 for region in range(FreeRoamWorld.CENTERS.size()):
  for slot in range(3):
   var signal_node := Node3D.new()
   signal_node.position = FreeRoamWorld.CENTERS[region] + [Vector3(-500, 120, -200), Vector3(0, -180, -800), Vector3(650, 150, 600)][slot]
   var mesh := MeshInstance3D.new()
   var shape := TorusMesh.new()
   shape.inner_radius = 6
   shape.outer_radius = 8
   mesh.mesh = shape
   signal_node.add_child(mesh)
   add_child(signal_node)
   beacons.append(signal_node)

func _build_roam_ui() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var column := VBoxContainer.new()
 column.position = Vector2(30, 170)
 column.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(column)
 info = Label.new()
 info.add_theme_font_size_override("font_size", 18)
 column.add_child(info)
 prompt = Label.new()
 column.add_child(prompt)
 log_label = Label.new()
 log_label.text = "Fly freely between regions. M: chart / warp. G: station service or scan.\nTab: target ships. Battles do not end the world; destroyed ships redeploy."
 column.add_child(log_label)
 map_panel = PanelContainer.new()
 map_panel.theme = CartoonStyle.ui_theme()
 var chart_style := StyleBoxFlat.new()
 chart_style.bg_color = Color(.02, .028, .065, .98)
 chart_style.border_color = Color(.2, .55, .8)
 chart_style.set_border_width_all(1)
 chart_style.set_corner_radius_all(10)
 chart_style.content_margin_left = 10
 chart_style.content_margin_right = 10
 chart_style.content_margin_top = 10
 chart_style.content_margin_bottom = 10
 map_panel.add_theme_stylebox_override("panel", chart_style)
 map_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 map_panel.position = (get_viewport().get_visible_rect().size - Vector2(600, 560)) / 2
 map_panel.size = Vector2(600, 560)
 layer.add_child(map_panel)
 var choices := VBoxContainer.new()
 choices.add_theme_constant_override("separation", 12)
 var chart_scroll := ScrollContainer.new()
 chart_scroll.custom_minimum_size = Vector2(580, 540)
 map_panel.add_child(chart_scroll)
 choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 chart_scroll.add_child(choices)
 var title := Label.new()
 title.text = "FREE-ROAM STAR CHART / CONNECTED SPACE"
 title.add_theme_font_size_override("font_size", 22)
 choices.add_child(title)
 var chart := GalaxyChart.new()
 chart.battle = self
 chart.course_requested.connect(func(region):
  if network_role == "client": travel_requested.emit(region)
  else: travel_fleet(region))
 choices.add_child(chart)
 var destinations := OptionButton.new()
 for index in range(FreeRoamWorld.CENTERS.size()):
  destinations.add_item(FreeRoamWorld.NAMES[index] + " / " + FreeRoamWorld.DESCRIPTIONS[index])
 choices.add_child(destinations)
 var warp := Button.new()
 warp.text = "WARP TO SELECTED STATION / OR CLICK A MAP DOT"
 warp.pressed.connect(func():
  if network_role == "client": travel_requested.emit(destinations.selected)
  else: travel_fleet(destinations.selected))
 choices.add_child(warp)
 war_status = Label.new()
 war_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 war_status.custom_minimum_size.x = 550
 choices.add_child(war_status)
 for index in range(3):
  var land := Button.new()
  land.text = "LAND BOT / " + PlanetCatalog.WORLDS[index].display_name
  land.disabled = network_role != "offline"
  land.tooltip_text = "Solo: capture this outpost and approach within 650m outside combat. Return to the same space session after exploring."
  land.pressed.connect(func(): landing_requested.emit(index))
  choices.add_child(land)
 var note := Label.new()
 note.text = "You can also fly directly between stations. Warp and service require\nno hostiles within 650m and no recent damage. Warp preserves health."
 choices.add_child(note)
 army_species = OptionButton.new()
 for species in CreatureArmy.SPECIES:
  army_species.add_item(SanctuaryForms.form_name(species, 0))
 choices.add_child(army_species)
 for action in ["deploy", "follow", "assault", "recall"]:
  var order := Button.new()
  order.text = {"deploy":"DEPLOY 5 CREATURES", "follow":"ARMY / FOLLOW SHIP", "assault":"ARMY / ASSAULT NEAREST WORLD", "recall":"ARMY / RECALL TROOPS"}[action]
  order.pressed.connect(func():
   if network_role == "client": army_requested.emit(action, army_species.selected)
   else: log_label.text = army_action(1, pilot.ship, action, army_species.selected))
  choices.add_child(order)
 army_status = Label.new()
 choices.add_child(army_status)
 var close := Button.new()
 close.text = "RESUME FREE FLIGHT"
 close.pressed.connect(toggle_chart)
 choices.add_child(close)
 map_panel.visible = false

func toggle_chart() -> void:
 map_panel.visible = not map_panel.visible
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_panel.visible else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
 if network_role == "server": return
 if event.is_action_pressed("sector_map"):
  toggle_chart()
 if event.is_action_pressed("scan") and network_role == "client":
  dock_requested.emit()

func _physics_process(delta: float) -> void:
 if finished: return
 if network_role != "client":
  elapsed += delta
  update_auras()
  war.tick(delta)
  for vessel in ships:
   if vessel.alive and world.hazard_at(vessel.position): vessel.health.damage(delta * 5, null)
  for ship in ships:
   var protection := maxf(0, float(ship.get_meta("spawn_protection", 0)) - delta)
   ship.set_meta("spawn_protection", protection)
   if protection > 0:
    ship.health.protection = 0
  for ship in respawns.keys():
   respawns[ship] -= delta
   if respawns[ship] <= 0:
    var region := FreeRoamWorld.nearest_region(ship.position)
    ship.redeploy(FreeRoamWorld.CENTERS[region] + Vector3(ship.fleet_slot * 35, 0, 160))
    respawns.erase(ship)
    if network_role == "offline" and fleet.ships.has(ship) and not pilot.ship.alive:
     fleet.switch_to(ship.fleet_slot)
  for encounter in encounters:
   if encounter.respawn >= 0:
    encounter.respawn -= delta
    if encounter.respawn <= 0:
     for slot in range(encounter.ships.size()):
      var member: CombatShip = encounter.ships[slot]
      member.redeploy(FreeRoamWorld.CENTERS[encounter.region] + Vector3(700 + slot * 35, slot * 20, -300))
      member.brain.roam_center = member.position
     encounter.respawn = -1.0
     encounter.credited = false
     encounter.kills = 0
     encounter.wave += 1
 _update_roam_ui(delta)

func _update_roam_ui(delta: float) -> void:
 if network_role == "server" or not is_instance_valid(pilot.ship): return
 var ship := pilot.ship
 if is_instance_valid(army_status):
  var owner := 1 if network_role == "offline" else multiplayer.get_unique_id()
  army_status.text = "ARMY %d/10 / SERVER %d/50\n" % [army.owned_count(owner), army.units.size()]
  for outpost in army.worlds:
   army_status.text += "%s: Team %d / %d%%\n" % [outpost.name, outpost.owner + 1, int(outpost.progress / CreatureArmy.CAPTURE_SECONDS * 100)]
 if is_instance_valid(war_status): war_status.text = war.briefing()
 var region := FreeRoamWorld.nearest_region(ship.position)
 if region != current_region:
  current_region = region
  if profile != null:
   profile.record_discovery("open.region.%d" % region, FreeRoamWorld.NAMES[region])
 var nearby: Dictionary = army.worlds[army.nearest_world(ship.position)]
 info.text = "%s / FREE SPACE / %dm TO STATION\nARMIES %d/50 / %s / TEAM %d / %dm / M: ARMY ORDERS" % [FreeRoamWorld.NAMES[region].to_upper(), int(ship.position.distance_to(FreeRoamWorld.CENTERS[region])), army.units.size(), nearby.name, nearby.owner + 1, int(ship.position.distance_to(nearby.position))]
 info.text += "\n" + war.briefing().split("\n")[0]
 info.text += " / %s %dm" % [world.landmarks[region].name, int(ship.position.distance_to(world.landmarks[region].position))]
 if not ship.alive:
  prompt.text = "SHIP LOST / REDEPLOYING AT NEAREST STATION"
  return
 if ship.position.distance_to(FreeRoamWorld.CENTERS[region]) < 180:
  prompt.text = "G / DOCK: REPAIR AND REFILL YOUR FLEET" if safe_to_service(ship) else "STATION SERVICE BLOCKED / HOSTILES OR RECENT DAMAGE"
  if network_role == "offline" and Input.is_action_just_pressed("scan") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
   service_ship(ship, true)
 else:
  prompt.text = "M / CHART, WAR & LANDING · TAB / TARGET · G / SURVEY LANDMARK"
  if world.hazard_at(ship.position): prompt.text = "ION STORM / TAKING DAMAGE / LEAVE THE GLOWING CLOUD"
  if network_role == "offline" and Input.is_action_just_pressed("scan") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
   var result := survey_landmark(1, ship)
   if not result.is_empty(): log_label.text = result
  if profile != null:
   _scan_nearby(delta)

func safe_to_service(ship: CombatShip) -> bool:
 if not ship.alive or ship.health.regen_delay > 0 or world.hazard_at(ship.position):
  return false
 for unit in army.units.values():
  if unit.team != ship.team and unit.position.distance_to(ship.position) < 350: return false
 for enemy in ships:
  if enemy.alive and enemy.team != ship.team and enemy.position.distance_to(ship.position) < 650:
   return false
 return true

func service_ship(ship: CombatShip, whole_fleet: bool = false) -> bool:
 var region := FreeRoamWorld.nearest_region(ship.position)
 if ship.position.distance_to(FreeRoamWorld.CENTERS[region]) >= 180 or not safe_to_service(ship):
  log_label.text = "Service denied: approach a station and disengage from combat."
  return false
 var serviced: Array[CombatShip] = []
 if whole_fleet:
  serviced.assign(fleet.ships)
 else:
  serviced.append(ship)
 for member in serviced:
  if member.alive and member.position.distance_to(ship.position) < 250 and safe_to_service(member):
   member.health.configure(member.stats)
   member.movement.boost_energy = member.stats.boost_capacity
 log_label.text = "Station service complete / hull, shields and boost restored."
 return true

func travel_ship(ship: CombatShip, region: int) -> bool:
 if region < 0 or region >= FreeRoamWorld.CENTERS.size() or not safe_to_service(ship):
  log_label.text = "Warp denied: disengage from nearby enemies and wait for damage to stop."
  return false
 ship.position = FreeRoamWorld.CENTERS[region] + Vector3(ship.fleet_slot * 35, 0, 160)
 ship.velocity = Vector3.ZERO
 ship.movement.thrust = Vector3.ZERO
 ship.targeting.select(null)
 ship.brain.roam_center = FreeRoamWorld.CENTERS[region] + Vector3(0, 0, -800)
 return true

func travel_fleet(region: int) -> bool:
 if not is_instance_valid(pilot.ship) or not travel_ship(pilot.ship, region): return false
 for member in fleet.ships:
  if member != pilot.ship and member.alive:
   member.position = pilot.ship.position + Vector3((member.fleet_slot - 1) * 35, 10, 35)
   member.velocity = Vector3.ZERO
   member.targeting.select(null)
 map_panel.visible = false
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 log_label.text = "Arrived / " + FreeRoamWorld.NAMES[region] + ". Fly, scan signals, dock or engage ships."
 return true

func _scan_nearby(delta: float) -> void:
 var selected := -1
 for index in range(beacons.size()):
  var definition: SectorDefinition = ExplorationMatch.SECTORS[(index / 3) % 4]
  if not profile.exploration_records.has(signal_record(index)) and pilot.ship.position.distance_to(beacons[index].position) < 35:
   selected = index
   break
 if selected < 0:
  scan_progress = 0
  return
 if scan_index != selected: scan_progress = 0
 scan_index = selected
 scan_progress = scan_progress + delta if Input.is_action_pressed("scan") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else 0
 prompt.text = "HOLD G / SCAN SIGNAL / %d%%" % int(scan_progress / 2 * 100)
 if scan_progress >= 2:
  discover_signal(selected)
  scan_progress = 0

func discover_signal(index: int) -> bool:
 if profile == null or index < 0 or index >= beacons.size(): return false
 var definition: SectorDefinition = ExplorationMatch.SECTORS[(index / 3) % 4]
 var id := definition.rewards[index % 3]
 if not profile.record_discovery(signal_record(index), CollectionCatalog.find(id).display_name, id): return false
 log_label.text = "DISCOVERY / " + CollectionCatalog.find(id).display_name + " / Saved to your collection"
 return true

func _on_eliminated(ship: CombatShip, attacker: CombatShip) -> void:
 if network_role == "client": return
 if network_role == "server":
  respawns[ship] = 12.0
  if is_instance_valid(attacker) and attacker.team != ship.team:
   reward_sequence += 1
   encounter_won.emit(attacker, ship, battle_id + "-" + str(reward_sequence))
  return
 if fleet.ships.has(ship):
  respawns[ship] = 12.0
  return
 for encounter in encounters:
  if not encounter.ships.has(ship): continue
  if encounter.respawn >= 0: return
  if is_instance_valid(attacker) and fleet.ships.has(attacker):
   encounter.credited = true
   encounter.kills += 1
  var survivors := 0
  for member in encounter.ships:
   if member.alive: survivors += 1
  if survivors == 0 and encounter.respawn < 0:
   encounter.respawn = 45.0
   if encounter.credited:
    var kills := 0
    var damage := 0.0
    for member in encounter.ships:
     for friendly in fleet.ships:
      damage += float(member.health.damage_by_attacker.get(friendly.get_instance_id(), 0))
    kills = int(encounter.kills)
    rewards = profile.settle_battle(battle_id + "-%d-%d" % [encounter.region, encounter.wave], 0, kills, damage)
    var prize := CollectionCatalog.find(str(rewards[0].id))
    log_label.text = "ENCOUNTER WON / PERMANENT SHIP: " + prize.display_name + "\n+60 salvage and 2 discovery rolls. Patrols return in 45 seconds."
  return
 # Civilian escorts return to service after destruction too.
 respawns[ship] = 30.0

func replace_pilot_ship(index: int, stats: ShipStats, callsign: String, crew_name: String, controlled: bool) -> void:
 var previous := ships[index]
 var ship := CombatShip.new()
 ship.team = previous.team
 ship.fleet_slot = previous.fleet_slot
 ship.stats = stats
 ship.callsign = callsign
 ship.crew_name = crew_name
 ship.position = FreeRoamWorld.CENTERS[ship.team] + Vector3(ship.fleet_slot * 35, 0, 160)
 add_child(ship)
 ship.targeting.selection_range = 1400
 ship.set_meta("spawn_protection", 8.0)
 ship.brain.roaming = true
 ship.brain.sensor_range = 1100
 ship.brain.roam_center = ship.position + Vector3(0, 0, -800)
 ship.brain.command = "attack"
 ship.player_controlled = controlled
 ship.eliminated.connect(_on_eliminated)
 ships[index] = ship
 var fleet_index := fleet.ships.find(previous)
 if fleet_index >= 0: fleet.ships[fleet_index] = ship
 if pilot.ship == previous: pilot.take_control(ship)
 respawns.erase(previous)
 remove_child(previous)
 previous.queue_free()
 if network_role == "client":
  ship.set_physics_process(false)
  ship.collision_layer = 0
  ship.collision_mask = 0

func army_action(owner: int, ship: CombatShip, action: String, argument: int = 0) -> String:
 if network_role == "client": return "Orders require the host."
 if action == "deploy": return army.deploy(owner, ship, argument)
 if army.command(owner, ship, action): return "Army order / " + action
 return "Order denied / approach a world outpost within 1600m and use a living ship."

func signal_record(index: int) -> String:
 if index < 12:
  return "%s.signal.%d" % [ExplorationMatch.SECTORS[index / 3].id, index % 3]
 return "open.region.%d.signal.%d" % [index / 3, index % 3]

func survey_landmark(owner: int, ship: CombatShip) -> String:
 if network_role == "client" or not ship.alive: return ""
 for landmark in world.landmarks:
  if ship.position.distance_to(landmark.position) > 100: continue
  var record := "%d.%d" % [owner, landmark.region]
  if surveyed.has(record): return "Landmark already surveyed this session."
  surveyed[record] = true
  if profile != null: profile.record_discovery("open.landmark.%d" % landmark.region, landmark.name)
  return "SURVEY COMPLETE / " + landmark.name
 return ""

func can_land(index: int) -> bool:
 if network_role != "offline" or index < 0 or index >= army.worlds.size() or not is_instance_valid(pilot.ship): return false
 var ship := pilot.ship
 return ship.alive and army.worlds[index].owner == ship.team and ship.position.distance_to(army.worlds[index].position) < 650 and safe_to_service(ship)
