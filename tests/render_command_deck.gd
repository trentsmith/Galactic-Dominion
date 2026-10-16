extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://deck-render-only.json";root.add_child(main)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 var capture:=root.get_texture().get_image();capture.save_png("/tmp/gd16-command-deck.png");capture.save_webp("res://docs/images/command-deck.webp",true,.9)
 print("COMMAND_DECK_RENDER_PASS")
 main.queue_free();await process_frame;await process_frame;quit(0)
