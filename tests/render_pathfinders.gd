extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://pathfinders-preview.json";root.add_child(main)
 for i in range(8):await process_frame
 main.start_free_roam(true)
 var args:=OS.get_cmdline_user_args();var view:=str(args[0]) if args.size()>0 else "atlas"
 if view=="atlas" or view=="journey":
  main.show_frontier();var screen: FrontierScreen=main.story_layer.get_child(0);screen.tab=5 if view=="atlas" else 6;screen.refresh()
 elif view=="mining":
  var roam: FreeRoamMatch=main.battle
  roam.pilot.ship.position=Vector3(150,35,-65);roam.pilot.ship.rotation=Vector3.ZERO
  roam.navigation.set_route({"id":"first-vein","name":"Ferric ore vein","kind":"mineral","at":JourneyState.pack(roam.mining.veins[0].position)})
  roam.pilot.take_control(roam.pilot.ship)
 elif view=="continue":
  main.battle.journey_log.save_checkpoint();main.return_to_menu()
 for i in range(30):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/gd42-"+view+".png");print("PATHFINDERS_RENDERED "+view)
 main.queue_free();await process_frame;await process_frame;quit()
