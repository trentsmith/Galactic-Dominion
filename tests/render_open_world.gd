# Actual UI and 3D capture of an isolated, staged free-roam session.
extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://open-world-render.json"
 root.add_child(main)
 await process_frame
 main.start_free_roam()
 var roam: FreeRoamMatch = main.battle
 roam.set_physics_process(false)
 roam.army.set_physics_process(false)
 roam.pilot.set_physics_process(false)
 for ship in roam.ships: ship.set_physics_process(false)
 roam.war.dispatch()
 var at: Vector3 = roam.world.landmarks[6].position
 roam.pilot.ship.position = at + Vector3(0, 30, 100)
 roam.pilot.ship.rotation = Vector3.ZERO
 roam.camera.position = roam.pilot.ship.position + Vector3(0, 18, 55)
 roam.camera.look_at(at + Vector3(0, 25, 0))
 roam._update_roam_ui(.01)
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/gd14-open-world.png")
 roam.toggle_chart()
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 var capture := root.get_texture().get_image()
 capture.save_png("/tmp/gd14-chart.png")
 capture.save_webp("res://docs/images/open-world-chart.webp", true, .88)
 print("OPEN_WORLD_RENDER_PASS")
 main.queue_free()
 await process_frame
 quit(0)
