extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://render-frontier.json";root.add_child(main)
 var args:=OS.get_cmdline_user_args();var view:=str(args[0]) if args.size()>0 else "board"
 for i in range(10):await process_frame
 if view=="board":main.start_free_roam(true);main.show_frontier()
 elif view=="wreck":
  main.start_free_roam(true)
  var director: FrontierDirector=main.battle.frontier
  director.start({"kind":"wreck","id":"preview","slot":3,"generation":0,"region":0,"at":Vector3(0,0,130),"title":"The sealed cargo hold","faction":"frontier","reward":75})
  director.active.stage="boarding";main.board_derelict()
 elif view=="settings":main.show_settings(false)
 elif view=="home":
  main.profile.frontier.facilities={"repair":2,"observatory":2,"workshop":2};main.show_sanctuary()
 elif view=="flight":
  main.start_free_roam(true);main.battle.frontier.accept(0)
 for i in range(30):await process_frame
 await RenderingServer.frame_post_draw
 var path:="/tmp/gd41-"+view+".png"
 root.get_texture().get_image().save_png(path);print("FRONTIER_RENDERED "+path);main.queue_free();await process_frame;quit()
