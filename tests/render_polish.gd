extends SceneTree
## Native Linux render smoke check; run with a disposable XDG_DATA_HOME.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.gui_embed_subwindows=true
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://polish-preview.json";root.add_child(main)
 for i in range(8):await process_frame
 main.start_free_roam(true)
 var args:=OS.get_cmdline_user_args();var view:=str(args[0]) if args.size()>0 else "departure"
 if view=="departure":
  main.profile.save_blocked=true;main.return_to_menu()
 elif view=="mining":
  var key:=InputEventKey.new();key.keycode=KEY_I;FlightPreferences.replace("missile",key,false)
  var roam: FreeRoamMatch=main.battle
  roam.pilot.ship.position=Vector3(150,35,-65);roam.pilot.ship.rotation=Vector3.ZERO;roam.pilot.take_control(roam.pilot.ship)
  roam.navigation.set_route({"id":"vein-0-0","name":"Ferric ore vein","kind":"mineral","at":JourneyState.pack(roam.mining.veins[0].position)})
 elif view=="empty-atlas":
  main.show_frontier();var screen: FrontierScreen=main.story_layer.get_child(0);screen.tab=5;screen.refresh()
  var atlas:=screen.body.get_child(0) as AtlasPage;var query:=atlas.find_child("AtlasSearch",true,false) as LineEdit;query.text="unmatched contact";query.text_changed.emit(query.text)
 for i in range(30):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/gd43-"+view+".png");print("POLISH_RENDERED "+view)
 main.queue_free();await process_frame;await process_frame;quit()
