extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args();var view:=str(args[0]) if args.size()>0 else "menu"
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://armada-preset-preview.json";root.add_child(main)
 for i in range(5):await process_frame
 if view=="setup":main.show_armada_setup(200,50)
 for i in range(10):await process_frame
 await RenderingServer.frame_post_draw
 var capture:=root.get_texture().get_image();capture.save_png("/tmp/gd45-"+view+".png")
 if "--docs" in args:capture.save_webp("res://docs/images/armada-"+view+".webp",true,.9)
 print("ARMADA_PRESETS_RENDERED ",view)
 main.queue_free();await process_frame;await process_frame;quit()
