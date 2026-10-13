extends Node

var menu: CanvasLayer
var battle: BattleMatch
var sensitivity := 0.0025
var inverted := false
var fullscreen := false
var settings: ConfigFile = ConfigFile.new()
var profile: PlayerProfile
# Tests can redirect progression away from the real player's profile.
var profile_path := "user://commander_profile.json"

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 profile = PlayerProfile.new(profile_path)
 profile.load_profile()
 settings.load("user://settings.cfg")
 sensitivity = settings.get_value("controls", "sensitivity", 0.0025)
 inverted = settings.get_value("controls", "invert_y", false)
 fullscreen = settings.get_value("display", "fullscreen", false)
 _apply_display()
 show_menu()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("pause") and is_instance_valid(battle) and not battle.finished:
  if get_tree().paused:
   resume()
  else:
   get_tree().paused = true
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
   show_menu(true)
  get_viewport().set_input_as_handled()

func start_battle() -> void:
 get_tree().paused = false
 if is_instance_valid(menu):
  menu.queue_free()
 if is_instance_valid(battle):
  remove_child(battle)
  battle.queue_free()
 battle = BattleMatch.new()
 battle.profile = profile
 add_child(battle)
 battle.pilot.sensitivity = sensitivity
 battle.pilot.inverted = inverted

func resume() -> void:
 if is_instance_valid(menu):
  menu.queue_free()
 get_tree().paused = false
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func return_to_menu() -> void:
 get_tree().paused = false
 if is_instance_valid(battle):
  remove_child(battle)
  battle.queue_free()
 battle = null
 show_menu()

func show_menu(paused: bool = false) -> void:
 if is_instance_valid(menu):
  menu.queue_free()
 menu = CanvasLayer.new()
 menu.layer = 10
 add_child(menu)
 var backdrop := ColorRect.new()
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.color = Color(0.015, 0.025, 0.065, 0.95)
 menu.add_child(backdrop)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.add_child(center)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 95)
 center.add_child(row)
 var column := VBoxContainer.new()
 column.custom_minimum_size = Vector2(400, 0)
 column.add_theme_constant_override("separation", 16)
 row.add_child(column)
 var eyebrow := Label.new()
 eyebrow.text = "G D   /   FLIGHT PROGRAM 01"
 eyebrow.add_theme_color_override("font_color", Color(0.2, 0.85, 1))
 column.add_child(eyebrow)
 var title := Label.new()
 title.text = "GALACTIC
DOMINION"
 title.add_theme_font_size_override("font_size", 54)
 column.add_child(title)
 var subtitle := Label.new()
 subtitle.text = "FLEET ROYALE  •  HANGAR & DISCOVERY
Three ships. One command. Hold the stars."
 subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
 column.add_child(subtitle)
 _button(column, "RESUME FLIGHT" if paused else "PLAY  /  DEPLOY FLEET", resume if paused else start_battle)
 if not paused:
  _button(column, "FLEET HANGAR / COLLECTION", show_hangar)
  var progress := Label.new()
  progress.text = "%s · %d / %d discoveries · %d salvage" % [profile.commander_name, profile.owned_count(), CollectionCatalog.DEFINITIONS.size(), profile.salvage]
  progress.add_theme_font_size_override("font_size", 13)
  progress.add_theme_color_override("font_color", Color(0.55, 0.8, 0.9))
  column.add_child(progress)
  if not profile.notice.is_empty() or not profile.save_error.is_empty():
   var status := Label.new()
   status.text = profile.save_error if not profile.save_error.is_empty() else profile.notice
   status.custom_minimum_size.x = 400
   status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
   status.add_theme_font_size_override("font_size", 12)
   column.add_child(status)
 _button(column, "SETTINGS", func(): show_settings(paused))
 if paused:
  _button(column, "RETURN TO MAIN MENU", return_to_menu)
 _button(column, "QUIT", func(): get_tree().quit())
 var help := Label.new()
 help.text = "PILOT BRIEFING

W / S    Forward / reverse
A / D    Strafe    •    Space / Ctrl    Vertical
Mouse    Steer    •    Q / E    Roll
Shift    Boost    •    R    Class ability

Left click    Laser
Tab    Cycle target
Right click    Missile (requires target lock)

F1 / F2 / F3    Switch ships
1    Follow    •    2    Attack target
3    Defend    •    4    Regroup    •    5    Retreat
Esc    Pause

Keep the enemy in the central reticle to lock.
The safe zone contracts after 30 seconds."
 help.add_theme_font_size_override("font_size", 17)
 help.add_theme_color_override("font_color", Color(0.65, 0.76, 0.9))
 row.add_child(help)

func _button(parent: Control, text: String, callback: Callable) -> void:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size = Vector2(320, 44)
 button.pressed.connect(callback)
 parent.add_child(button)

func show_settings(paused: bool) -> void:
 if is_instance_valid(menu):
  menu.queue_free()
 menu = CanvasLayer.new()
 menu.layer = 11
 add_child(menu)
 var bg := ColorRect.new()
 bg.color = Color(0.015, 0.025, 0.065)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.add_child(bg)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.add_child(center)
 var column := VBoxContainer.new()
 column.custom_minimum_size = Vector2(420, 0)
 column.add_theme_constant_override("separation", 20)
 center.add_child(column)
 var label := Label.new()
 label.text = "FLIGHT SETTINGS"
 label.add_theme_font_size_override("font_size", 30)
 column.add_child(label)
 var value := Label.new()
 value.text = "Mouse sensitivity: %.2f" % (sensitivity * 1000)
 column.add_child(value)
 var slider := HSlider.new()
 slider.min_value = 0.5
 slider.max_value = 6.0
 slider.step = 0.1
 slider.value = sensitivity * 1000
 slider.value_changed.connect(func(v):
  sensitivity = v / 1000.0
  value.text = "Mouse sensitivity: %.2f" % v
  _save_settings())
 column.add_child(slider)
 var invert := CheckButton.new()
 invert.text = "Invert vertical mouse steering"
 invert.button_pressed = inverted
 invert.toggled.connect(func(v):
  inverted = v
  _save_settings())
 column.add_child(invert)
 var full := CheckButton.new()
 full.text = "Fullscreen"
 full.button_pressed = fullscreen
 full.toggled.connect(func(v):
  fullscreen = v
  _apply_display()
  _save_settings())
 column.add_child(full)
 _button(column, "BACK", func(): show_menu(paused))

func _save_settings() -> void:
 settings.set_value("controls", "sensitivity", sensitivity)
 settings.set_value("controls", "invert_y", inverted)
 settings.set_value("display", "fullscreen", fullscreen)
 settings.save("user://settings.cfg")
 if is_instance_valid(battle):
  battle.pilot.sensitivity = sensitivity
  battle.pilot.inverted = inverted

func _apply_display() -> void:
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func show_hangar() -> void:
 if is_instance_valid(menu):
  remove_child(menu)
  menu.queue_free()
 menu = CanvasLayer.new()
 menu.layer = 10
 add_child(menu)
 var hangar := HangarScreen.new()
 hangar.profile = profile
 hangar.back_requested.connect(show_menu)
 hangar.deploy_requested.connect(start_battle)
 menu.add_child(hangar)
