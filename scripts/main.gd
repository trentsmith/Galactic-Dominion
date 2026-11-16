extends Node

var online_api: OnlineAPI
var network: OnlineSession
var menu: CanvasLayer
var sanctuary_scene: SanctuaryGarden
var surface: PlanetExpedition
var parked_roam: FreeRoamMatch
var battle: BattleMatch
var story_layer: CanvasLayer
var story_previous_paused := false
var story_previous_mouse := Input.MOUSE_MODE_VISIBLE
var armada_allies:=200
var armada_enemies:=200
var difficulty := "standard"
var sensitivity := 0.0025
var inverted := false
var fullscreen := false
var volume := 0.6
var settings: ConfigFile = ConfigFile.new()
var profile: PlayerProfile
# Tests can redirect progression away from the real player's profile.
var profile_path := "user://commander_profile.json"
var quit_dialog: ConfirmationDialog

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
 FlightPreferences.install()
 get_tree().auto_accept_quit=false
 FlightPreferences.apply_node(get_tree().root)
 get_tree().node_added.connect(func(node):FlightPreferences.apply_id.call_deferred(node.get_instance_id()))
 var audio := SpaceAudio.new()
 audio.name = "Audio"
 add_child(audio)
 profile = PlayerProfile.new(profile_path)
 profile.load_profile()
 settings.load("user://settings.cfg")
 difficulty = SoloDifficulty.valid(str(settings.get_value("gameplay","difficulty","standard")))
 armada_allies=ArmadaCombat.count(settings.get_value("armada","allies",200))
 armada_enemies=ArmadaCombat.count(settings.get_value("armada","enemies",200))
 sensitivity = settings.get_value("controls", "sensitivity", 0.0025)
 inverted = settings.get_value("controls", "invert_y", false)
 fullscreen = settings.get_value("display", "fullscreen", false)
 volume = settings.get_value("audio", "volume", 0.6)
 AudioServer.set_bus_volume_db(0, linear_to_db(volume))
 _apply_display()
 if GameFeatures.campaign_enabled():
  var tracker:=StoryTracker.new();tracker.host=self;add_child(tracker)
 show_menu()
 if "--tutorial" in arguments:
  start_tutorial()
 elif "--frontier" in arguments:
  show_frontier();print("GALACTIC_FRONTIER_READY")
 elif "--atlas" in arguments or "--journey" in arguments:
  start_free_roam(true);show_frontier();var screen: FrontierScreen=story_layer.get_child(0);screen.tab=5 if "--atlas" in arguments else 6;screen.refresh();print("GALACTIC_PATHFINDERS_READY")
 elif "--story" in arguments:
  show_story();print("GALACTIC_STORY_READY stage=%d"%ShipCampaign.stage(profile))
 elif "--free-roam" in arguments:
  start_free_roam()
 elif "--armada" in arguments:
  start_armada()
 elif "--fleet-war" in arguments:
  start_fleet_war()
 elif "--battle" in arguments:
  start_battle()
 elif "--sanctuary" in arguments:
  show_sanctuary()
 elif "--planet" in arguments:
  var index:=arguments.find("--planet")
  start_planet(int(arguments[index+1]) if index+1<arguments.size() else 0,"crew_pixlet")

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("story_journal") or (is_instance_valid(story_layer) and event.is_action_pressed("pause")):
  if is_instance_valid(story_layer):close_story()
  else:show_story()
  get_viewport().set_input_as_handled();return
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

func start_tutorial() -> void:
 _clear_surface()
 network.disconnect_session()
 get_tree().paused = false
 if is_instance_valid(menu):menu.queue_free()
 if is_instance_valid(battle):
  remove_child(battle)
  battle.queue_free()
 battle = TrainingFlight.new()
 add_child(battle)
 battle.pilot.sensitivity = sensitivity
 battle.pilot.inverted = inverted

func start_armada(seed_value: int=0,allies: int=0,enemies: int=0) -> void:
 start_battle(ArmadaCombat.count(allies if allies>0 else armada_allies),"",seed_value,ArmadaCombat.count(enemies if enemies>0 else armada_enemies),true)

func show_armada_setup() -> void:
 if is_instance_valid(menu):menu.queue_free()
 menu=CanvasLayer.new();menu.layer=10;add_child(menu)
 var screen:=ArmadaSetup.new();screen.host=self;menu.add_child(screen)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func launch_armada(allies: int,enemies: int) -> void:
 armada_allies=ArmadaCombat.count(allies);armada_enemies=ArmadaCombat.count(enemies)
 settings.set_value("armada","allies",armada_allies);settings.set_value("armada","enemies",armada_enemies);_save_settings()
 start_armada(0,armada_allies,armada_enemies)

func start_fleet_war() -> void:
 start_battle(10)

func start_battle(size_per_team: int = 3,mission: String = "",seed_value: int=0,opponents: int=0,armada: bool=false,replay_story: bool=false) -> void:
 _clear_surface()
 network.disconnect_session()
 get_tree().paused = false
 if is_instance_valid(menu):
  menu.queue_free()
 if is_instance_valid(battle):
  battle.get_parent().remove_child(battle)
  battle.queue_free()
 battle = BattleMatch.new()
 battle.armada_mode=armada; battle.enemy_team_size=opponents
 battle.map_seed=seed_value
 battle.team_size = size_per_team
 battle.difficulty = "veteran" if mission!="" and difficulty=="veteran" else "standard" if mission!="" else difficulty
 battle.story_mission = mission
 battle.story_replay = replay_story
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
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(460,minf(600,get_viewport().get_visible_rect().size.y-80))
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 center.add_child(scroll)
 var column := VBoxContainer.new()
 column.custom_minimum_size = Vector2(420, 0)
 column.add_theme_constant_override("separation", 16)
 scroll.add_child(column)
 var label := Label.new()
 label.text = "GAME SETTINGS"
 label.add_theme_font_size_override("font_size", 30)
 column.add_child(label)
 var difficulty_label := Label.new()
 difficulty_label.text="SOLO BATTLE DIFFICULTY"
 difficulty_label.add_theme_font_size_override("font_size",13)
 column.add_child(difficulty_label)
 var difficulty_dropdown := difficulty_choice(column)
 var description := Label.new()
 description.text = SoloDifficulty.PRESETS[difficulty].description
 description.custom_minimum_size.x=420
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(description)
 difficulty_dropdown.item_selected.connect(func(index):description.text=SoloDifficulty.PRESETS[SoloDifficulty.IDS[index]].description)
 var scope := Label.new()
 scope.text = "Solo fleet battles · applies to your next battle"
 scope.add_theme_font_size_override("font_size",13)
 column.add_child(scope)
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
 var graphics:=OptionButton.new()
 for word in ["LOW / no shadows or AA","MEDIUM / shadows and 2x AA","HIGH / shadows, 4x AA and available post effects"]:graphics.add_item(word)
 graphics.selected=["low","medium","high"].find(FlightPreferences.quality)
 graphics.item_selected.connect(func(index):FlightPreferences.quality=["low","medium","high"][index];FlightPreferences.save_display();FlightPreferences.apply_node(get_tree().root))
 column.add_child(graphics)
 var large:=CheckButton.new();large.text="Larger menu text";large.button_pressed=FlightPreferences.large_text
 large.toggled.connect(func(value):FlightPreferences.large_text=value;FlightPreferences.save_display();center.theme=CartoonStyle.ui_theme());column.add_child(large)
 var flashes:=CheckButton.new();flashes.text="Reduce explosion flashes";flashes.button_pressed=FlightPreferences.reduced_flashes
 flashes.toggled.connect(func(value):FlightPreferences.reduced_flashes=value;FlightPreferences.save_display());column.add_child(flashes)
 var bindings:=Button.new();bindings.text="CONTROLS / REBIND INPUTS";column.add_child(bindings)
 var remaps:=ControlsPanel.new();remaps.visible=false;column.add_child(remaps);bindings.pressed.connect(func():remaps.visible=not remaps.visible)
 _button(column, "BACK", func(): show_menu(paused))

func _save_settings() -> void:
 settings.set_value("gameplay","difficulty",difficulty)
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
 battle.frontier.boarding_requested.connect(board_derelict)
 battle.pilot.sensitivity = sensitivity
 battle.pilot.inverted = inverted
 print("GALACTIC_FREE_ROAM_READY ships=%d" % battle.ships.size())


func _clear_surface() -> void:
 save_frontier()
 if is_instance_valid(parked_roam): parked_roam.queue_free()
 parked_roam = null
 if is_instance_valid(sanctuary_scene):remove_child(sanctuary_scene);sanctuary_scene.queue_free()
 sanctuary_scene=null
 if is_instance_valid(surface):
  remove_child(surface);surface.queue_free()
 surface=null

func show_planets() -> void:
 if not GameFeatures.wildlife_enabled():return_to_menu();return
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
 if not GameFeatures.wildlife_enabled():return_to_menu();return
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
 if not GameFeatures.wildlife_enabled():return_to_menu();return
 network.disconnect_session();get_tree().paused=false;_clear_surface()
 if is_instance_valid(battle):remove_child(battle);battle.queue_free();battle=null
 if is_instance_valid(menu):menu.queue_free()
 sanctuary_scene=SanctuaryGarden.new();sanctuary_scene.profile=profile;sanctuary_scene.back_requested.connect(return_to_menu);add_child(sanctuary_scene)

func land_from_roam(index: int) -> bool:
 if not GameFeatures.wildlife_enabled():return false
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
 if not GameFeatures.wildlife_enabled():return_to_menu();return
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

func difficulty_choice(parent: Control) -> OptionButton:
 var choice := OptionButton.new()
 choice.name = "DifficultyChoice"
 for id in SoloDifficulty.IDS:
  choice.add_item(SoloDifficulty.title(id))
  choice.get_popup().set_item_tooltip(choice.item_count-1,SoloDifficulty.PRESETS[id].description)
 choice.select(SoloDifficulty.IDS.find(difficulty))
 choice.tooltip_text = "Enemy AI for your next solo Fleet Royale, Fleet War or Armada. Armada Standard/Veteran use full enemy durability. Online, free roam and training are unchanged."
 choice.item_selected.connect(func(index):
  difficulty = SoloDifficulty.IDS[index]
  _save_settings())
 parent.add_child(choice)
 return choice

func show_story() -> void:
 if not GameFeatures.campaign_enabled():show_frontier();return
 if is_instance_valid(story_layer):return
 story_previous_paused=get_tree().paused
 story_previous_mouse=Input.mouse_mode
 var online:=is_instance_valid(battle) and battle.network_role!="offline"
 if not online:get_tree().paused=true
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 story_layer=CanvasLayer.new();story_layer.layer=30;story_layer.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(story_layer)
 var screen: Control=StoryScreen.new() if GameFeatures.creatures_enabled() else ShipStoryScreen.new();screen.host=self;screen.readonly=online
 var stage: int=StoryCampaign.stage(profile) if GameFeatures.creatures_enabled() else ShipCampaign.stage(profile)
 screen.npc=("sera" if stage in [2,3] else "milo" if stage==4 else "astra") if GameFeatures.creatures_enabled() else ("milo" if stage==3 else "sera" if stage in [4,5] else "astra")
 if is_instance_valid(surface) and surface.at_landing_ship():screen.npc="milo"
 story_layer.add_child(screen)

func close_story() -> void:
 if not is_instance_valid(story_layer):return
 remove_child(story_layer);story_layer.queue_free();story_layer=null
 get_tree().paused=story_previous_paused
 Input.mouse_mode=story_previous_mouse

func story_action() -> void:
 if not GameFeatures.campaign_enabled():return
 if not GameFeatures.creatures_enabled():ship_story_action();return
 var stage:=StoryCampaign.stage(profile)
 match stage:
  0:StoryCampaign.accept(profile)
  1,2:
   if is_instance_valid(surface) and (stage==2 or surface.definition.id=="varkhoss"):
    if stage==1 and not StoryCampaign.visit(profile,"varkhoss"):
     story_layer.get_child(0).refresh();return
    close_story();return
   if is_instance_valid(surface) and not story_can_travel():return
   if is_instance_valid(battle) and battle is FreeRoamMatch:
    close_story();return
   if stage==1:
    close_story();start_free_roam(true);return
   story_travel("planet");return
  3:StoryCampaign.debrief(profile)
  4:
   if is_instance_valid(story_layer):story_layer.get_child(0).npc="milo"
  5:
   if not story_can_travel():return
   close_story();start_story_encounter();return
  6:StoryCampaign.complete(profile)
  7:story_travel("roam");return
 if is_instance_valid(story_layer):story_layer.get_child(0).refresh()

func story_can_travel() -> bool:
 if is_instance_valid(battle) and battle.network_role!="offline":profile.story_message="Leave online play before launching a local story activity.";return false
 if is_instance_valid(surface) and not surface.finished and not surface.pending.is_empty():
  profile.story_message="Deliver your surveys with E at the landing ship before changing activities. Secured cargo is already saved."
  if is_instance_valid(story_layer):story_layer.get_child(0).refresh()
  return false
 return true

func story_travel(destination: String) -> void:
 if not story_can_travel():return
 close_story()
 match destination:
  "planet":start_planet(0)
  "sanctuary":show_sanctuary()
  "hangar":
   return_to_menu();show_hangar()
  "roam":start_free_roam()

func start_story_encounter() -> bool:
 if not GameFeatures.creatures_enabled():return start_ship_story_encounter()
 if is_instance_valid(battle) and battle.network_role!="offline":
  profile.story_message="Story encounters are local; leave online play first.";return false
 if StoryCampaign.stage(profile)!=5:
  profile.story_message="Complete the rescue and lead-ship upgrade before challenging the patrol.";return false
 start_battle(3, "crimson_interdiction")
 for ship in battle.ships:
  if ship.team==1:ship.callsign="Crimson Interdictor %d"%(ship.fleet_slot+1);ship.crew_name="Crimson Dominion pilot"
 return true

func ship_story_busy() -> bool:
 return is_instance_valid(battle) and battle.story_mission.begins_with("nexus_") and not battle.finished

func ship_story_action() -> void:
 if not GameFeatures.campaign_enabled():return
 if is_instance_valid(battle) and battle.network_role!="offline":return
 if ship_story_busy():close_story();return
 var step:=ShipCampaign.stage(profile)
 if step==0:ShipCampaign.accept(profile)
 elif step in [1,4,5]:
  if start_ship_story_encounter():close_story()
  return
 elif step in [2,7]:
  if not story_can_travel():return
  close_story()
  if not battle is FreeRoamMatch:start_free_roam(true)
  return
 elif step==3:story_travel("hangar");return
 elif step==6:ShipCampaign.complete(profile)
 if is_instance_valid(story_layer):story_layer.get_child(0).refresh()

func choose_ship_protocol(value: String) -> void:
 if ship_story_busy() or (is_instance_valid(battle) and battle.network_role!="offline"):return
 ShipCampaign.choose(profile,value)
 if is_instance_valid(story_layer):story_layer.get_child(0).refresh()

func replay_ship_story(mission: String) -> bool:
 if ship_story_busy() or not ShipCampaign.can_replay(profile,mission):return false
 return launch_ship_sortie(mission,true)

func start_ship_story_encounter() -> bool:
 if not GameFeatures.campaign_enabled():return false
 var step:=ShipCampaign.stage(profile)
 if not ShipCampaign.MISSIONS.has(step):return false
 return launch_ship_sortie(ShipCampaign.MISSIONS[step],false)

func launch_ship_sortie(mission: String,replay: bool) -> bool:
 if not GameFeatures.campaign_enabled():return false
 if not NexusStoryData.MISSIONS.has(mission) or (is_instance_valid(battle) and battle.network_role!="offline"):return false
 if not story_can_travel():return false
 if mission=="nexus_warfront" and not ShipCampaign.lock_decision(profile):
  if is_instance_valid(story_layer):story_layer.get_child(0).refresh()
  return false
 close_story()
 start_battle(int(NexusStoryData.MISSIONS[mission].size),mission,0,0,false,replay)
 return true

func show_frontier() -> void:
 if is_instance_valid(story_layer):return
 story_previous_paused=get_tree().paused;story_previous_mouse=Input.mouse_mode
 if not (is_instance_valid(battle) and battle.network_role!="offline"):get_tree().paused=true
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 story_layer=CanvasLayer.new();story_layer.layer=30;story_layer.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(story_layer)
 var board:=FrontierScreen.new();board.host=self;story_layer.add_child(board)

func board_derelict() -> void:
 if not battle is FreeRoamMatch or battle.network_role!="offline" or not battle.frontier.can_board():return
 parked_roam=battle;remove_child(parked_roam);battle=null
 if is_instance_valid(menu):menu.queue_free()
 var room:=DerelictExpedition.new();room.profile=profile
 var bots:=PlanetCatalog.available_bots(profile);room.bot_definition=bots[0] if not bots.is_empty() else CollectionCatalog.find("crew_pixlet")
 surface=room;room.return_requested.connect(return_from_derelict);add_child(room)

func return_from_derelict() -> void:
 if not surface is DerelictExpedition:return
 var secured: bool=surface.secured
 return_from_planet()
 if battle is FreeRoamMatch:battle.frontier.return_boarding(secured)

func _exit_tree() -> void:
 # A landed session is deliberately detached; it still belongs to this host.
 if is_instance_valid(parked_roam):parked_roam.free()
 parked_roam=null

func continue_frontier() -> void:
 if profile==null or profile.journey.resume.is_empty():return
 var checkpoint: Dictionary=profile.journey.resume.duplicate(true)
 start_free_roam(bool(checkpoint.get("peaceful",false)))
 battle.journey_log.restore(checkpoint)

func save_frontier() -> bool:
 var flight: FreeRoamMatch=battle as FreeRoamMatch if battle is FreeRoamMatch else parked_roam
 return flight.journey_log.save_checkpoint() if is_instance_valid(flight) and flight.network_role=="offline" else true

func quit_game() -> void:
 if is_instance_valid(quit_dialog):return
 var reason:=""
 if not save_frontier():reason="Your journey could not be saved. "+profile.save_error+"\nKeep playing to retry from O, or quit without saving the latest progress."
 elif is_instance_valid(surface) and not surface.pending.is_empty():reason="Unextracted surveys will be lost. Keep playing and deliver with E at the landing ship, or quit without these surveys. Secured transport stays saved."
 elif surface is DerelictExpedition:reason="Your orbital job is saved, but wreck console progress and unsecured black-box data will restart. Keep exploring to return through the airlock, or quit now."
 if reason.is_empty():get_tree().quit();return
 var previous_mouse:=Input.mouse_mode
 var previous_pause:=get_tree().paused
 if not (is_instance_valid(battle) and battle.network_role!="offline"):get_tree().paused=true
 quit_dialog=ConfirmationDialog.new();quit_dialog.title="Leave this expedition?";quit_dialog.dialog_text=reason;quit_dialog.ok_button_text="QUIT WITHOUT UNSAVED PROGRESS";quit_dialog.cancel_button_text="KEEP PLAYING";add_child(quit_dialog)
 quit_dialog.confirmed.connect(func():get_tree().quit())
 quit_dialog.canceled.connect(func():quit_dialog.queue_free();quit_dialog=null;get_tree().paused=previous_pause;Input.mouse_mode=previous_mouse)
 quit_dialog.popup_centered(Vector2i(600,180));Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST and profile!=null:quit_game()
