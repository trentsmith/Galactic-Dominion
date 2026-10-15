extends Node

var online_api: OnlineAPI
var network: OnlineSession
var menu: CanvasLayer
var surface: PlanetExpedition
var battle: BattleMatch
var sensitivity := 0.0025
var inverted := false
var fullscreen := false
var volume := 0.6
var settings: ConfigFile = ConfigFile.new()
var profile: PlayerProfile
# Tests can redirect progression away from the real player's profile.
var profile_path := "user://commander_profile.json"

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 online_api = OnlineAPI.new()
 online_api.name = "OnlineAPI"
 add_child(online_api)
 network = OnlineSession.new()
 network.name = "Network"
 add_child(network)
 var arguments := OS.get_cmdline_user_args()
 if "--server" in arguments:
  var port := 7777
  if "--port" in arguments:
   port = int(arguments[arguments.find("--port") + 1])
  if "--match-seconds" in arguments:
   network.max_seconds = clampf(float(arguments[arguments.find("--match-seconds") + 1]), 1, 480)
  var error := network.start_server(port)
  if error != OK:
   get_tree().quit(1)
  return
 var audio := SpaceAudio.new()
 audio.name = "Audio"
 add_child(audio)
 profile = PlayerProfile.new(profile_path)
 profile.load_profile()
 settings.load("user://settings.cfg")
 sensitivity = settings.get_value("controls", "sensitivity", 0.0025)
 inverted = settings.get_value("controls", "invert_y", false)
 fullscreen = settings.get_value("display", "fullscreen", false)
 volume = settings.get_value("audio", "volume", 0.6)
 AudioServer.set_bus_volume_db(0, linear_to_db(volume))
 _apply_display()
 show_menu()
 if "--free-roam" in arguments:
  start_free_roam()
 elif "--battle" in arguments:
  start_battle()
 elif "--planet" in arguments:
  var index:=arguments.find("--planet")
  start_planet(int(arguments[index+1]) if index+1<arguments.size() else 0,"crew_pixlet")

func _unhandled_input(event: InputEvent) -> void:
 if is_instance_valid(surface) and event.is_action_pressed("pause"):
  surface.toggle_pause()
  get_viewport().set_input_as_handled()
  return
 if event.is_action_pressed("pause") and is_instance_valid(battle) and not battle.finished:
  if get_tree().paused or (battle.network_role != "offline" and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE):
   resume()
  else:
   get_tree().paused = battle.network_role == "offline"
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
   show_menu(true)
  get_viewport().set_input_as_handled()

func start_battle() -> void:
 _clear_surface()
 network.disconnect_session()
 get_tree().paused = false
 if is_instance_valid(menu):
  menu.queue_free()
 if is_instance_valid(battle):
  battle.get_parent().remove_child(battle)
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
 _clear_surface()
 network.disconnect_session()
 get_tree().paused = false
 if is_instance_valid(battle):
  battle.get_parent().remove_child(battle)
  battle.queue_free()
 battle = null
 show_menu()

func show_menu(paused: bool = false) -> void:
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
 center.theme = CartoonStyle.ui_theme()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.add_child(center)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 95)
 center.add_child(row)
 var column := VBoxContainer.new()
 column.custom_minimum_size = Vector2(400, 0)
 column.add_theme_constant_override("separation", 10)
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
 subtitle.text = "OPEN SPACE  •  YOUR LITTLE SPACE CREW
Explore, collect companions, and fly together."
 subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
 column.add_child(subtitle)
 _button(column, "RESUME FLIGHT" if paused else "PLAY  /  DEPLOY FLEET", resume if paused else start_battle)
 if not paused:
  _button(column, "FREE ROAM / OPEN SPACE", start_free_roam)
  _button(column, "PLANET EXPEDITIONS / LITTLE BOTS", show_planets)
  _button(column, "GALACTIC EXPLORATION", func(): start_exploration(0))
  _button(column, "ONLINE / LOBBY / MARKETPLACE", show_online)
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
 button.pressed.connect(func(): SpaceAudio.play("click"))
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
 center.theme = CartoonStyle.ui_theme()
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
 var volume_label := Label.new()
 volume_label.text = "MASTER VOLUME"
 column.add_child(volume_label)
 var volume_slider := HSlider.new()
 volume_slider.min_value = 0
 volume_slider.max_value = 1
 volume_slider.step = 0.05
 volume_slider.value = volume
 volume_slider.value_changed.connect(func(v):
  volume = v
  AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))
  _save_settings())
 column.add_child(volume_slider)
 _button(column, "BACK", func(): show_menu(paused))

func _save_settings() -> void:
 settings.set_value("audio", "volume", volume)
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

func start_exploration(index: int) -> void:
 _clear_surface()
 get_tree().paused = false
 if is_instance_valid(menu):
  menu.queue_free()
 if is_instance_valid(battle):
  battle.get_parent().remove_child(battle)
  battle.queue_free()
 var exploration := ExplorationMatch.new()
 exploration.profile = profile
 exploration.sector_index = clampi(index, 0, ExplorationMatch.SECTORS.size() - 1)
 exploration.warp_requested.connect(start_exploration)
 battle = exploration
 add_child(battle)
 battle.pilot.sensitivity = sensitivity
 battle.pilot.inverted = inverted

func show_online() -> void:
 if is_instance_valid(menu):
  remove_child(menu)
  menu.queue_free()
 menu = CanvasLayer.new()
 menu.layer = 10
 add_child(menu)
 var hub := OnlineHub.new()
 hub.api = online_api
 hub.session = network
 hub.back_requested.connect(show_menu)
 menu.add_child(hub)

func start_free_roam() -> void:
 _clear_surface()
 network.disconnect_session()
 get_tree().paused = false
 if is_instance_valid(menu): menu.queue_free()
 if is_instance_valid(battle):
  battle.get_parent().remove_child(battle)
  battle.queue_free()
 battle = FreeRoamMatch.new()
 battle.profile = profile
 add_child(battle)
 battle.pilot.sensitivity = sensitivity
 battle.pilot.inverted = inverted
 print("GALACTIC_FREE_ROAM_READY ships=%d" % battle.ships.size())


func _clear_surface() -> void:
 if is_instance_valid(surface):
  remove_child(surface);surface.queue_free()
 surface=null

func show_planets() -> void:
 network.disconnect_session();get_tree().paused=false
 _clear_surface()
 if is_instance_valid(battle):
  remove_child(battle);battle.queue_free();battle=null
 if is_instance_valid(menu):menu.queue_free()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 menu=CanvasLayer.new();menu.layer=10;add_child(menu)
 var selector:=PlanetSelector.new();selector.profile=profile
 selector.back_requested.connect(show_menu);selector.launched.connect(start_planet);menu.add_child(selector)

func start_planet(index: int,bot_id: String="") -> void:
 network.disconnect_session();get_tree().paused=false
 _clear_surface()
 if is_instance_valid(battle):remove_child(battle);battle.queue_free();battle=null
 if is_instance_valid(menu):menu.queue_free()
 var available:=PlanetCatalog.available_bots(profile)
 var chosen:=CollectionCatalog.find(bot_id)
 if chosen==null or chosen.kind!="crew" or chosen.species=="Human" or not profile.owns(chosen.id):
  chosen=available[0] if not available.is_empty() else CollectionCatalog.find("crew_pixlet")
 surface=PlanetExpedition.new();surface.profile=profile;surface.definition=PlanetCatalog.WORLDS[clampi(index,0,2)]
 surface.bot_definition=chosen;surface.sensitivity=sensitivity;surface.inverted=inverted
 surface.return_requested.connect(show_planets);add_child(surface)
