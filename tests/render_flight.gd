extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://render-flight-only.json"
 root.add_child(main)
 await process_frame
 main.profile.acquire("crew_nyx")
 main.profile.equip(0,"crew","crew_nyx")
 main.start_free_roam()
 for ship in main.battle.ships:
  ship.set_physics_process(false)
  if is_instance_valid(ship.companion): ship.companion.set_physics_process(false)
 main.battle.pilot.set_physics_process(false)
 main.battle.pilot.update_camera(1.0)
 for frame in range(45): await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 var error := image.save_png("/tmp/gd5-free-flight.png")
 print("RENDER_FLIGHT: saved=%s size=%s" % [error == OK,image.get_size()])
 main.queue_free()
 await process_frame
 await process_frame
 OS.delay_msec(50)
 quit(0 if error == OK else 1)
