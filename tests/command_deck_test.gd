extends SceneTree
var main: Node
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func frames() -> void:
 await process_frame;await process_frame;await process_frame
func current() -> CommandDeck:return main.menu.get_child(0) as CommandDeck
func run() -> void:
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://command-deck-test.json";root.add_child(main);await frames()
 var deck:=current()
 check(deck!=null and deck.preview.own_world_3d,"The command deck loads an isolated 3D fleet preview")
 check(deck.hero.find_child("PilotCanopy",true,false)!=null,"The menu uses the actual configured ship model")
 var buttons_ok:=true
 for id in ["ExploreButton","PeacefulButton","OnlineButton","BattleButton","PlanetsButton","SanctuaryButton","HangarButton","SurveyButton","MarketButton","SettingsButton","ControlsButton","QuitButton"]:
  var button:=deck.find_child(id,true,false) as Button
  buttons_ok=buttons_ok and button!=null and button.pressed.get_connections().size()>=2
 check(buttons_ok,"Every mode and utility has a connected navigation button")
 var primary:=deck.find_child("ExploreButton",true,false) as Button
 primary.grab_focus()
 check(root.gui_get_focus_owner()==primary,"Primary navigation supports keyboard focus")
 var bounds_ok:=true
 for id in ["ExploreButton","PeacefulButton","BattleButton","SettingsButton","ControlsButton","QuitButton"]:
  var button:=deck.find_child(id,true,false) as Button
  bounds_ok=bounds_ok and root.get_visible_rect().encloses(button.get_global_rect())
 check(bounds_ok,"Main menu actions fit completely inside the 1280x720 viewport")
 deck.find_child("ControlsButton",true,false).pressed.emit();await frames()
 check(is_instance_valid(deck.controls_popup) and deck.controls_popup.visible,"Flight controls open from the redesigned menu")
 deck.controls_popup.find_child("CloseControlsButton",true,false).pressed.emit()
 check(not deck.controls_popup.visible,"The controls panel closes without leaving the menu")
 primary.pressed.emit();await frames()
 check(main.battle is FreeRoamMatch and not main.battle.peaceful,"The primary button starts normal open-world flight")
 check(not is_instance_valid(deck),"Leaving the menu frees the preview scene")
 main.return_to_menu();await frames()
 current().find_child("PeacefulButton",true,false).pressed.emit();await frames()
 check(main.battle is FreeRoamMatch and main.battle.peaceful,"Peaceful exploration starts directly from the command deck")
 var pause_event:=InputEventAction.new();pause_event.action="pause";pause_event.pressed=true
 main._unhandled_input(pause_event);await frames()
 check(paused and current().paused,"Pausing flight opens the dedicated pause layout")
 current().find_child("ResumeButton",true,false).pressed.emit();await frames()
 check(not paused and main.battle!=null,"Resume returns to the existing flight")
 main.return_to_menu();await frames()
 current().find_child("PlanetsButton",true,false).pressed.emit();await frames()
 check(main.menu.get_child(0) is PlanetSelector,"The planet expedition card opens the real planet selector")
 main.return_to_menu();await frames()
 current().find_child("SanctuaryButton",true,false).pressed.emit();await frames()
 check(main.sanctuary_scene!=null,"The personal planet card opens the live sanctuary")
 main.return_to_menu();await frames()
 current().find_child("HangarButton",true,false).pressed.emit();await frames()
 check(main.menu.get_child(0) is HangarScreen,"The collection card opens the actual fleet hangar")
 main.return_to_menu();await frames()
 current().find_child("OnlineButton",true,false).pressed.emit();await frames()
 check(main.menu.get_child(0) is OnlineHub,"Online play opens the account, lobby and marketplace hub")
 main.return_to_menu();await frames()
 current().find_child("BattleButton",true,false).pressed.emit();await frames()
 check(main.battle!=null and not main.battle is FreeRoamMatch,"Fleet Royale remains accessible through its card")
 main.return_to_menu();await frames()
 current().find_child("SettingsButton",true,false).pressed.emit();await frames()
 check(main.menu.find_children("","HSlider",true,false).size()>0,"Settings retain their functional sliders")
 main.queue_free();await frames()
 print("COMMAND DECK TEST: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
