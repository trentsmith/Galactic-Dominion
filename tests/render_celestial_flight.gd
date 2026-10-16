extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate()
 main.profile_path="user://celestial-flight-render.json";root.add_child(main);await process_frame
 main.start_free_roam(true)
 var roam: FreeRoamMatch=main.battle
 roam.set_physics_process(false);roam.pilot.set_physics_process(false);roam.army.set_physics_process(false)
 for ship in roam.ships:ship.set_physics_process(false)
 roam.pilot.ship.position=Vector3(150,100,350)
 roam.pilot.update_camera(1)
 var event:=InputEventAction.new();event.action="scenic_hud";event.pressed=true;roam._unhandled_input(event)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/gd19-flight.png")
 print("CELESTIAL_FLIGHT_RENDER_PASS")
 main.queue_free()
 for i in range(16):await process_frame
 await RenderingServer.frame_post_draw
 quit(0)
