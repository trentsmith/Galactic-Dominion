extends SceneTree
var checks:=0
var failures:=0
var main: Node
const EXPECTED=[Vector2i(200,50),Vector2i(200,200),Vector2i(50,200)]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,words: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+words)
 if not ok:failures+=1
func frames() -> void:await process_frame;await physics_frame;await process_frame
func freeze(battle: BattleMatch) -> void:
 battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 if battle.sector_map!=null:battle.sector_map.set_physics_process(false)
 if battle.mega!=null:battle.mega.set_physics_process(false)
 for ship in battle.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func valid_counts(battle: BattleMatch,sizes: Vector2i) -> bool:
 return battle.is_armada() and battle.team_size==sizes.x and battle.enemy_team_size==sizes.y and battle.ships.size()==sizes.x+sizes.y and battle.living(0)==sizes.x and battle.living(1)==sizes.y
func run() -> void:
 check(not GameFeatures.campaign_enabled(),"Requested Armada formats are available in the default free-roam build")
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://armada-presets-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames();main.difficulty="standard"
 var entry:=main.menu.find_child("ArmadaSetupButton",true,false) as Button
 check(entry!=null and entry.text.contains("200 v 200") and root.get_visible_rect().encloses(entry.get_global_rect()),"A prominent 200-ship Armada entry is visible on the opening screen")
 var utilities_visible:=true
 for id in ["SettingsButton","ControlsButton","QuitButton"]:
  utilities_visible=utilities_visible and root.get_visible_rect().encloses(main.menu.find_child(id,true,false).get_global_rect())
 check(utilities_visible,"Settings, controls and quit stay visible in a fixed footer below the scrolling modes")
 for sizes in EXPECTED:
  var button:=main.menu.find_child("ArmadaPreset%dv%d"%[sizes.x,sizes.y],true,false) as Button
  check(button!=null and root.get_visible_rect().encloses(button.get_global_rect()),"The %d v %d shortcut is visible without scrolling"%[sizes.x,sizes.y])
 main.armada_allies=73;main.armada_enemies=111;entry.pressed.emit();await frames()
 var setup:=main.menu.get_child(0) as ArmadaSetup
 check(setup!=null and setup.allies.value==73 and setup.enemies.value==111,"General Armada setup retains the commander's custom fleet sizes")
 setup.choose_preset(Vector2i(200,50));main.return_to_menu();await frames()
 check(main.armada_allies==73 and main.armada_enemies==111,"Previewing a preset does not overwrite saved choices before launching")
 for sizes in EXPECTED:
  main.menu.find_child("ArmadaPreset%dv%d"%[sizes.x,sizes.y],true,false).pressed.emit();await frames();setup=main.menu.get_child(0) as ArmadaSetup
  check(setup.allies.value==sizes.x and setup.enemies.value==sizes.y,"The %d v %d menu shortcut preselects both fleet counters"%[sizes.x,sizes.y])
  check(setup.launch.text=="LAUNCH %d v %d"%[sizes.x,sizes.y] and setup.summary.text.contains("you + %d AI"%(sizes.x-1)),"The launch summary explains which fleet includes the player")
  var preset:=setup.find_child("Preset%dv%d"%[sizes.x,sizes.y],true,false) as Button
  check(preset!=null and preset.button_pressed,"The matching preset is visibly selected")
  # A pending SpinBox edit must not undo the subsequently selected preset.
  setup.allies.get_line_edit().text="7";setup.enemies.get_line_edit().text="9";preset.pressed.emit()
  check(setup.allies.get_line_edit().text==str(sizes.x) and setup.enemies.get_line_edit().text==str(sizes.y),"Choosing a preset replaces stale, uncommitted counter text")
  setup.launch.pressed.emit();var battle: BattleMatch=main.battle;freeze(battle);await frames()
  check(valid_counts(battle,sizes),"Launching %d v %d creates exactly %d real ships"%[sizes.x,sizes.y,sizes.x+sizes.y])
  check(battle.ships.filter(func(ship):return ship.player_controlled).size()==1 and battle.pilot.ship.team==0,"One allied vessel belongs to the player; the remaining fleets use AI")
  check(battle.sector_map!=null and battle.spatial!=null and battle.mega!=null and battle.elimination_only,"Each requested format uses full Armada terrain, hazards, relics and elimination rules")
  check(battle.mode_name()=="%dv%d"%[sizes.x,sizes.y] and DifficultyPlaytest.summary(battle).mode==battle.mode_name(),"HUD/report identity retains the asymmetric fleet numbers")
  check(battle.ships[sizes.x].health.max_hull==battle.ships[sizes.x].stats.hull,"Standard Armada keeps its existing full-durability enemy tuning")
  battle.profile=null;battle.finish(0,"Preset replay verification")
  battle.hud.results.find_child("ReplayBattleButton",true,false).pressed.emit();freeze(main.battle);await frames()
  check(valid_counts(main.battle,sizes),"Deploy Again preserves the %d v %d format"%[sizes.x,sizes.y])
  main.return_to_menu();await frames()
 main.show_armada_setup();await frames();setup=main.menu.get_child(0) as ArmadaSetup
 check(setup.allies.min_value==1 and setup.allies.max_value==200 and setup.enemies.min_value==1 and setup.enemies.max_value==200,"Independent custom fleet counts still support the full 1–200 range")
 setup.allies.get_line_edit().text="73";setup.enemies.get_line_edit().text="111";setup.launch.pressed.emit();freeze(main.battle);await frames()
 check(valid_counts(main.battle,Vector2i(73,111)),"Typed custom counts remain editable and launch a genuine 73 v 111 battle")
 var config:=ConfigFile.new();config.load("user://settings.cfg")
 check(config.get_value("armada","allies")==73 and config.get_value("armada","enemies")==111,"The launched custom counts persist on disk")
 main.return_to_menu();await frames();main.show_armada_setup();await frames();setup=main.menu.get_child(0) as ArmadaSetup
 check(setup.allies.value==73 and setup.enemies.value==111,"Reopening Armada restores the last launched fleet sizes")
 main.return_to_menu();await frames();main.menu.find_child("FleetWarButton",true,false).pressed.emit();freeze(main.battle);await frames()
 check(main.battle.team_size==10 and main.battle.enemy_team_size==10 and not main.battle.is_armada(),"Fleet War remains a separate 10v10 mode")
 main.return_to_menu();await frames();main.menu.find_child("BattleButton",true,false).pressed.emit();freeze(main.battle);await frames()
 check(main.battle.ships.size()==6 and not main.battle.is_armada(),"The existing 3v3 Fleet Royale remains available")
 main.queue_free();await frames();print("ARMADA_PRESETS_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
