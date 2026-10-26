class_name CommandDeck
extends Control
## Navigation and its isolated 3D preview share a single disposable menu scene.
var host: Node
var paused := false
var hero: Node3D
var preview: SubViewport
var elapsed := 0.0
var controls_popup: PopupPanel
const INK := Color(.9,.94,.95)
const MUTED := Color(.53,.64,.70)
const MINT := Color(.64,.87,.80)

func _ready() -> void:
 name = "CommandDeck"
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme = CartoonStyle.ui_theme()
 _build_preview()
 var veil := ColorRect.new()
 veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var shader := ShaderMaterial.new()
 shader.shader = preload("res://resources/shaders/menu_veil.gdshader")
 veil.material = shader
 add_child(veil)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,46)
 for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,26)
 add_child(margin)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",38)
 margin.add_child(row)
 var scroll := ScrollContainer.new()
 scroll.name = "NavigationScroll"
 scroll.custom_minimum_size.x = 440
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 row.add_child(scroll)
 var column := VBoxContainer.new()
 column.custom_minimum_size.x = 422
 column.add_theme_constant_override("separation",5)
 scroll.add_child(column)
 _label(column,"G A L A C T I C   D O M I N I O N",13,MINT)
 var title := _label(column,"Ready when\nyou are." if paused else "ARMADA\n200 v 200",46,INK)
 title.add_theme_constant_override("line_spacing",-5)
 var online: bool = is_instance_valid(host.battle) and host.battle.network_role != "offline"
 _label(column,"Online flight continues while this menu is open." if paused and online else "Your flight is paused. Take a moment among the stars." if paused else "A new sector every battle. 400 ships.\nGravity hazards. Enemies beyond your sensors.",15,MUTED)
 var primary := _button(column,"ResumeButton" if paused else "ArmadaButton","RESUME FLIGHT   >" if paused else "DEPLOY ARMADA / 200 v 200   >",host.resume if paused else host.start_armada,52)
 _primary_style(primary)
 if not paused:
  var quick := HBoxContainer.new();quick.add_theme_constant_override("separation",10);column.add_child(quick)
  _button(quick,"ExploreButton","FREE ROAM",host.start_free_roam,32).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _button(quick,"PeacefulButton","PEACEFUL FLIGHT",func():host.start_free_roam(true),32).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _button(quick,"OnlineButton","ONLINE PLAY",host.show_online,32).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var battle_options := HBoxContainer.new();column.add_child(battle_options)
  _label(battle_options,"SOLO BATTLE AI  ",11,MUTED)
  host.difficulty_choice(battle_options)
  _button(battle_options,"StoryButton","STORY / JOURNAL",host.show_story,30)
  var modes := GridContainer.new();modes.columns=2;modes.add_theme_constant_override("h_separation",10);modes.add_theme_constant_override("v_separation",8);column.add_child(modes)
  _mode(modes,"TutorialButton","Replay flight school" if host.settings.get_value("tutorial","flight_completed",false) else "Start here: flight school","Learn to fly · safe practice",host.start_tutorial)
  _mode(modes,"BattleButton","Fleet Royale","Fast 3v3 space battles",host.start_battle)
  _mode(modes,"FleetWarButton","Fleet War","10v10 · last fleet standing",host.start_fleet_war)
  _mode(modes,"PlanetsButton","Planet expeditions","Meet the wild frontier",host.show_planets)
  _mode(modes,"SanctuaryButton","Your little planet","Care, grow and belong",host.show_sanctuary)
  _mode(modes,"HangarButton","Fleet & collection","Make every ship yours",host.show_hangar)
  _mode(modes,"SurveyButton","Discovery missions","Follow a distant signal",func():host.start_exploration(0))
  _mode(modes,"MarketButton","Galactic community","Online fleets & trading",host.show_online)
  var progress := _label(column,"%s  /  %d discoveries  /  %d salvage" % [host.profile.commander_name,host.profile.owned_count(),host.profile.salvage],12,MUTED)
  progress.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  progress.custom_minimum_size.x=400
  if not host.profile.notice.is_empty() or not host.profile.save_error.is_empty():
   var status := _label(column,host.profile.save_error if not host.profile.save_error.is_empty() else host.profile.notice,12,Color(1,.73,.48))
   status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   status.custom_minimum_size.x=400
 else:
  if host.battle is TrainingFlight and not host.battle.completed:
   _button(column,"RetryLessonButton","RETRY THIS LESSON",func():host.battle.retry_lesson();host.resume(),40)
  _button(column,"ReturnButton","SKIP TRAINING / COMMAND DECK" if host.battle is TrainingFlight else "RETURN TO COMMAND DECK",host.return_to_menu,40)
 var footer := HBoxContainer.new();footer.add_theme_constant_override("separation",12);column.add_child(footer)
 _button(footer,"SettingsButton","Settings",func():host.show_settings(paused),30).flat=true
 _button(footer,"ControlsButton","Flight controls",_show_controls,30).flat=true
 _button(footer,"QuitButton","Quit",func():get_tree().quit(),30).flat=true
 var right := Control.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(right)
 var mark := _label(right,"E X P L O R E   /   C O L L E C T   /   B E L O N G",11,MINT)
 mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);mark.position=Vector2(-360,6)
 var caption := VBoxContainer.new();caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);caption.position=Vector2(-370,-105);caption.custom_minimum_size=Vector2(360,90);caption.add_theme_constant_override("separation",8);right.add_child(caption)
 _label(caption,"YOUR NEXT CHAPTER STARTS HERE",11,MINT)
 _label(caption,"A small ship.\nAn extraordinary universe.",25,INK)
 _label(caption,"Build a fleet, find a friend, follow your curiosity.",12,MUTED)

func _build_preview() -> void:
 var display := SubViewportContainer.new()
 display.name="FleetPreview"
 display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 display.stretch=true;display.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(display)
 preview=SubViewport.new();preview.size=Vector2i(1280,720);preview.own_world_3d=true
 preview.msaa_3d=Viewport.MSAA_4X;preview.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 display.add_child(preview)
 var scene:=Node3D.new();preview.add_child(scene)
 scene.add_child(SpaceEnvironmentArt.environment(6.3))
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-28,145,0);key.light_color=Color(1,.84,.65);key.light_energy=1.6;scene.add_child(key)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-10,-35,0);fill.light_color=Color(.35,.63,1);fill.light_energy=.7;scene.add_child(fill)
 SpaceEnvironmentArt.planet(scene,Vector3(-8,-4,14),5,Color(.12,.29,.30),8.2,true)
 hero=Node3D.new();hero.name="YourFleetPreview";hero.position=Vector3(-3.6,.35,0);hero.rotation=Vector3(-.12,-.4,-.14);hero.scale=Vector3.ONE*.76;scene.add_child(hero)
 SpaceModelFactory.ship(hero,host.profile.configured_stats(0))
 var pet:=Node3D.new();pet.position=Vector3(-6.2,1.9,-.2);pet.rotation.y=.3;pet.scale=Vector3.ONE*.5;scene.add_child(pet)
 SpaceModelFactory.companion(pet,CollectionCatalog.find("crew_pixlet"))
 var camera:=Camera3D.new();camera.position=Vector3(0,2.3,-15);camera.fov=44;scene.add_child(camera);camera.look_at(Vector3(0,.65,0));camera.current=true

func _process(delta: float) -> void:
 elapsed+=delta
 if is_instance_valid(hero):
  hero.position.y=.35+sin(elapsed*.6)*.12
  hero.rotation.y=-.4+sin(elapsed*.23)*.10

func _label(parent: Node,content: String,size_value: int,color: Color) -> Label:
 var label:=Label.new();label.text=content;label.add_theme_font_size_override("font_size",size_value);label.add_theme_color_override("font_color",color);parent.add_child(label);return label

func _button(parent: Node,id: String,content: String,callback: Callable,height: float) -> Button:
 var button:=Button.new();button.name=id;button.text=content;button.custom_minimum_size.y=height
 button.add_theme_font_size_override("font_size",13)
 button.pressed.connect(func():SpaceAudio.play("click"));button.pressed.connect(callback)
 parent.add_child(button);return button

func _mode(parent: Node,id: String,title: String,detail: String,callback: Callable) -> void:
 var button:=_button(parent,id,title+"\n"+detail,callback,48)
 button.custom_minimum_size.x=204;button.alignment=HORIZONTAL_ALIGNMENT_LEFT
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL

func _primary_style(button: Button) -> void:
 for state in ["normal","hover","pressed","focus"]:
  var style:=StyleBoxFlat.new();style.bg_color=MINT.lightened(.08) if state=="hover" else MINT.darkened(.08) if state=="pressed" else MINT
  style.set_corner_radius_all(8);style.content_margin_left=20;style.content_margin_right=20
  style.border_color=Color(.95,.82,.55);style.set_border_width_all(2 if state=="focus" else 0)
  button.add_theme_stylebox_override(state,style)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:button.add_theme_color_override(state,Color(.03,.10,.13))
 button.alignment=HORIZONTAL_ALIGNMENT_LEFT

func _show_controls() -> void:
 if is_instance_valid(controls_popup):controls_popup.queue_free()
 controls_popup=PopupPanel.new();controls_popup.title="Flight controls";add_child(controls_popup)
 var margin:=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
 controls_popup.add_child(margin)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);margin.add_child(column)
 _label(column,"A LITTLE FLIGHT SCHOOL",23,MINT)
 _label(column,"W / S    Forward / reverse\nA / D    Strafe · Space / Ctrl    Vertical\nMouse    Steer · Q / E    Roll\nShift    Boost · R    Ship ability\n\nLeft click    Laser · M    Missile\nTab    Target · F1–F3    Switch ship\nFleet War: F1–F10    Any allied ship\n1–5    Fleet commands\n\nJ    Star chart · G    Scan / service\nH    Scenic HUD · Esc    Pause / menu",15,INK)
 _label(column,"Peaceful flight has no raids or ion damage.\nFleet Royale has a shrinking battle zone.\nOnline play continues while menus are open.",13,MUTED)
 _button(column,"CloseControlsButton","GOT IT / BACK TO THE STARS",func():controls_popup.hide(),40)
 controls_popup.popup_centered(Vector2i(470,520))
