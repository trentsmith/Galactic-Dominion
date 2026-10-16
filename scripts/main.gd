extends Node

var online_api: OnlineAPI
var network: OnlineSession
var menu: CanvasLayer
var sanctuary_scene: SanctuaryGarden
var surface: PlanetExpedition
var parked_roam: FreeRoamMatch
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
 elif "--sanctuary" in arguments:
  show_sanctuary()
 elif "--planet" in arguments:
  var index:=arguments.find("--planet")
  start_planet(int(arguments[index+1]) if index+1<arguments.size() else 0,"crew_pixlet")

func _unhandled_input(event: InputEvent) -> void:
 if is_instance_valid(sanctuary_scene) and event.is_action_pressed("pause"):
  sanctuary_scene.close();get_viewport().set_input_as_handled();return
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
 var deck := CommandDeck.new()
 deck.host = self
 deck.paused = paused
 menu.add_child(deck)

func _button(parent: Control, text: String, callback: Callable) -> void:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size = Vector2(320, 40)
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

func start_free_roam(peaceful: bool = false) -> void:
 _clear_surface()
 network.disconnect_session()
 get_tree().paused = false
 if is_instance_valid(menu): menu.queue_free()
 if is_instance_valid(battle):
  battle.get_parent().remove_child(battle)
  battle.queue_free()
 battle = FreeRoamMatch.new()
 battle.peaceful = peaceful
 battle.profile = profile
 add_child(battle)
 battle.landing_requested.connect(land_from_roam)
 battle.pilot.sensitivity = sensitivity
 battle.pilot.inverted = inverted
 print("GALACTIC_FREE_ROAM_READY ships=%d" % battle.ships.size())


func _clear_surface() -> void:
 if is_instance_valid(parked_roam): parked_roam.queue_free()
 parked_roam = null
 if is_instance_valid(sanctuary_scene):remove_child(sanctuary_scene);sanctuary_scene.queue_free()
 sanctuary_scene=null
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
 surface.return_requested.connect(show_planets);surface.sanctuary_requested.connect(visit_captured_creatures);surface.landing_stats=profile.configured_stats(0);add_child(surface)

func show_sanctuary() -> void:
 network.disconnect_session();get_tree().paused=false;_clear_surface()
 if is_instance_valid(battle):remove_child(battle);battle.queue_free();battle=null
 if is_instance_valid(menu):menu.queue_free()
 sanctuary_scene=SanctuaryGarden.new();sanctuary_scene.profile=profile;sanctuary_scene.back_requested.connect(return_to_menu);add_child(sanctuary_scene)

func land_from_roam(index: int) -> bool:
 if not battle is FreeRoamMatch or not battle.can_land(index):
  if battle is FreeRoamMatch: battle.log_label.text = "Landing denied / own the world, approach its planet or outpost, and leave combat. Try Peaceful Flight for relaxed landings. Solo mode only."
  return false
 get_tree().paused=false
 var chosen_bot:=CollectionCatalog.find(battle.landing_bot_id)
 var landed_stats: ShipStats=battle.pilot.ship.stats.duplicate(true)
 parked_roam = battle
 remove_child(parked_roam)
 battle = null
 if is_instance_valid(menu): menu.queue_free()
 var available := PlanetCatalog.available_bots(profile)
 surface = PlanetExpedition.new()
 surface.profile = profile
 surface.definition = PlanetCatalog.WORLDS[index]
 surface.bot_definition = chosen_bot if chosen_bot!=null and chosen_bot in available else available[0] if not available.is_empty() else CollectionCatalog.find("crew_pixlet")
 surface.landing_stats=landed_stats
 surface.sensitivity = sensitivity
 surface.inverted = inverted
 surface.return_label = "RETURN TO ORBIT"
 surface.return_requested.connect(return_from_planet)
 surface.sanctuary_requested.connect(visit_captured_creatures)
 add_child(surface)
 return true

func return_from_planet() -> void:
 get_tree().paused = false
 if is_instance_valid(surface):
  remove_child(surface)
  surface.queue_free()
 surface = null
 if not is_instance_valid(parked_roam):
  show_menu()
  return
 battle = parked_roam
 parked_roam = null
 add_child(battle)
 battle.camera.current = true
 battle.map_panel.visible = false
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 battle.log_label.text = "Returned to orbit / the same fleet, war and armies await."

func visit_captured_creatures() -> void:
 if not is_instance_valid(surface) or not surface.finished:return
 get_tree().paused=false
 remove_child(surface);surface.queue_free();surface=null
 sanctuary_scene=SanctuaryGarden.new();sanctuary_scene.profile=profile
 sanctuary_scene.back_requested.connect(return_from_sanctuary_trip)
 add_child(sanctuary_scene)

func return_from_sanctuary_trip() -> void:
 if is_instance_valid(sanctuary_scene):remove_child(sanctuary_scene);sanctuary_scene.queue_free()
 sanctuary_scene=null
 if is_instance_valid(parked_roam):return_from_planet()
 else:show_planets()
