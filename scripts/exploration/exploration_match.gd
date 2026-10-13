class_name ExplorationMatch
extends BattleMatch
signal warp_requested(index)
const SECTORS = [preload("res://resources/sectors/vesper.tres"), preload("res://resources/sectors/kharon.tres"), preload("res://resources/sectors/auralith.tres"), preload("res://resources/sectors/ember.tres")]
var sector_index := 0
var sector: SectorDefinition
var beacons: Array[Node3D] = []
var info: Label
var prompt: Label
var log_label: Label
var map_panel: Control
var scan_progress := 0.0
var scan_index := -1

func _ready() -> void:
 sector = SECTORS[sector_index]
 var arena := SpaceArena.new()
 arena.arena_seed += sector_index * 137
 arena.planet_tint = sector.color.darkened(0.55)
 add_child(arena)
 zone = BattleZone.new()
 add_child(zone)
 zone.radius = 2000
 zone.visible = false
 camera = Camera3D.new()
 camera.far = 4000
 camera.current = true
 add_child(camera)
 pilot = PlayerPilot.new()
 pilot.camera = camera
 add_child(pilot)
 fleet = FleetManager.new()
 fleet.pilot = pilot
 add_child(fleet)
 for index in range(3):
  var ship := CombatShip.new()
  ship.stats = profile.configured_stats(index)
  ship.fleet_slot = index
  ship.callsign = "Explorer %d" % (index + 1)
  ship.position = Vector3((index - 1) * 30, index * 8, 180)
  add_child(ship)
  ships.append(ship)
  fleet.ships.append(ship)
  ship.eliminated.connect(_on_eliminated)
  ship.eliminated.connect(fleet.on_eliminated)
 for index in range(sector.enemy_count):
  var enemy := CombatShip.new()
  enemy.stats = CLASSES[index % 3]
  enemy.team = 1
  enemy.fleet_slot = index
  enemy.callsign = "Sector patrol %d" % (index + 1)
  enemy.position = Vector3(200 + index * 35, 30, -180)
  enemy.rotation.y = PI
  add_child(enemy)
  ships.append(enemy)
  enemy.eliminated.connect(_on_eliminated)
 for index in range(sector.rewards.size()):
  var beacon := Node3D.new()
  beacon.position = [Vector3(-170, 50, 30), Vector3(0, -60, -240), Vector3(260, 60, -110)][index]
  add_child(beacon)
  var visual := MeshInstance3D.new()
  var shape := TorusMesh.new()
  shape.inner_radius = 6
  shape.outer_radius = 8
  visual.mesh = shape
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = sector.color
  visual.material_override = material
  beacon.add_child(visual)
  beacons.append(beacon)
 fleet.switch_to(0)
 fleet.issue_command("follow")
 profile.record_discovery(sector.id + ".sector", sector.display_name)
 _build_hud()
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_hud() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var painter := HUDPainter.new()
 painter.battle = self
 painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(painter)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for side in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 170 if side == "top" else 210 if side == "bottom" else 30)
 layer.add_child(margin)
 var column := VBoxContainer.new()
 column.mouse_filter = Control.MOUSE_FILTER_IGNORE
 margin.add_child(column)
 info = Label.new()
 info.add_theme_font_size_override("font_size", 19)
 info.add_theme_color_override("font_color", sector.color)
 column.add_child(info)
 prompt = Label.new()
 prompt.add_theme_font_size_override("font_size", 18)
 column.add_child(prompt)
 log_label = Label.new()
 log_label.text = sector.description + "\nHold G near a signal to scan. M opens the sector map."
 log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(log_label)
 var controls := Label.new()
 controls.text = "G Hold Scan  ·  M Sector Map  ·  Esc Pause"
 column.add_child(controls)
 map_panel = PanelContainer.new()
 map_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 map_panel.position = Vector2(390, 160)
 map_panel.size = Vector2(500, 390)
 layer.add_child(map_panel)
 var map_column := VBoxContainer.new()
 map_column.add_theme_constant_override("separation", 12)
 map_panel.add_child(map_column)
 var title := Label.new()
 title.text = "GALACTIC CHART  /  %d RECORDS" % profile.exploration_records.size()
 title.add_theme_font_size_override("font_size", 22)
 map_column.add_child(title)
 for index in range(SECTORS.size()):
  var button := Button.new()
  button.text = "WARP  /  " + SECTORS[index].display_name
  button.custom_minimum_size.y = 42
  button.pressed.connect(func(): warp_requested.emit(index))
  map_column.add_child(button)
 var close := Button.new()
 close.text = "RESUME FLIGHT"
 close.pressed.connect(_toggle_map)
 map_column.add_child(close)
 var exit := Button.new()
 exit.text = "RETURN TO HANGAR"
 exit.pressed.connect(func():
  var host := get_parent()
  host.return_to_menu()
  host.show_hangar())
 map_column.add_child(exit)
 map_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("sector_map"):
  _toggle_map()

func _toggle_map() -> void:
 map_panel.visible = not map_panel.visible
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_panel.visible else Input.MOUSE_MODE_CAPTURED
 # Exploration keeps simulating while chart is open; return to hangar or warp to disengage.

func _physics_process(delta: float) -> void:
 elapsed += delta
 update_auras()
 if not is_instance_valid(pilot.ship):
  return
 var ship := pilot.ship
 info.text = "%s  /  %d PATROLS  /  %d SALVAGE" % [sector.display_name.to_upper(), living(1), profile.salvage]
 var nearest := -1
 var distance := INF
 for index in range(beacons.size()):
  beacons[index].rotate_y(delta * 0.5)
  var d := ship.global_position.distance_to(beacons[index].global_position)
  if d < distance and not profile.exploration_records.has(_beacon_id(index)):
   nearest = index
   distance = d
 if nearest < 0:
  prompt.text = "All signals recorded in this sector. Open M to explore another sector."
 elif distance > 35:
  var local := ship.global_basis.inverse() * ship.global_position.direction_to(beacons[nearest].global_position)
  prompt.text = "UNIDENTIFIED SIGNAL  /  %dm  ·  %s  ·  %s" % [int(distance), "LEFT" if local.x < 0 else "RIGHT", "BELOW" if local.y < 0 else "ABOVE"]
  scan_progress = 0
 else:
  if scan_index != nearest:
   scan_progress = 0
   scan_index = nearest
  if Input.is_action_pressed("scan") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
   scan_progress += delta
  else:
   scan_progress = maxf(0, scan_progress - delta)
  prompt.text = "HOLD G TO SCAN  /  %d%%" % int(scan_progress / 2 * 100)
  if scan_progress >= 2:
   discover_beacon(nearest)
   scan_progress = 0

func _beacon_id(index: int) -> String:
 return "%s.signal.%d" % [sector.id, index]

func discover_beacon(index: int) -> bool:
 if index < 0 or index >= sector.rewards.size():
  return false
 var definition := CollectionCatalog.find(sector.rewards[index])
 var discovered := profile.record_discovery(_beacon_id(index), definition.display_name, definition.id)
 if discovered:
  log_label.text = "DISCOVERY  /  %s\n%s\n+25 salvage · Collection updated" % [definition.display_name, definition.description]
 return discovered

func _on_eliminated(_ship: CombatShip, _attacker: CombatShip) -> void:
 if living(1) == 0:
  profile.record_discovery(sector.id + ".patrol", "Patrol defeated: " + sector.display_name, sector.encounter_reward)
  log_label.text = "Sector patrol defeated. Salvage recorded. Continue scanning or open M to warp."
 if living(0) == 0:
  finished = true
  pilot.set_physics_process(false)
  map_panel.visible = true
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  log_label.text = "Fleet lost. Discoveries are saved; return to hangar or warp to redeploy."
