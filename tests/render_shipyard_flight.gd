extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var battle:=FreeRoamMatch.new();battle.profile=PlayerProfile.new();battle.peaceful=true;root.add_child(battle)
 battle.set_physics_process(false);battle.pilot.set_physics_process(false);battle.army.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 battle.pilot.ship.position=Vector3(0,0,190);battle.pilot.ship.rotation=Vector3.ZERO
 battle.camera.fov=68;battle.pilot.update_camera(1.0);battle._update_roam_ui(.1)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_webp("res://docs/images/shipyard-flight.webp",true,.9)
 print("SHIPYARD_FLIGHT_RENDER_PASS");battle.queue_free();await process_frame;quit()
