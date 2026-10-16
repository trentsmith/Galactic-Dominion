extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
 for i in range(6): await process_frame
 await RenderingServer.frame_post_draw
 var picture:=root.get_texture().get_image()
 picture.save_png("/tmp/"+path+".png")
 picture.save_webp("res://docs/images/"+path+".webp",true,.9)
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate()
 main.profile_path="user://starlight-render-only.json";root.add_child(main);await process_frame
 main.start_free_roam(true)
 var roam: FreeRoamMatch=main.battle
 roam.set_physics_process(false);roam.pilot.set_physics_process(false);roam.army.set_physics_process(false)
 for ship in roam.ships:ship.set_physics_process(false)
 roam.pilot.ship.position=Vector3(150,100,350)
 roam.pilot.update_camera(1)
 var event:=InputEventAction.new();event.action="scenic_hud";event.pressed=true
 roam._unhandled_input(event)
 await capture("starlight-flight")
 # Close-up character lineup, made from the actual new in-game fauna meshes.
 main.return_to_menu();await process_frame
 if is_instance_valid(main.menu):main.menu.visible=false
 var scene:=Node3D.new();root.add_child(scene);scene.add_child(SpaceEnvironmentArt.environment())
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,145,0);key.light_color=Color(1,.86,.73);key.light_energy=1.4;scene.add_child(key)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,-25,0);fill.light_color=Color(.45,.65,1);fill.light_energy=.7;scene.add_child(fill)
 for i in range(3):
  var definition:=SanctuaryState.fauna(["bloodstag","nightfang","duskbat"][i])
  var model:=SurfaceArt.creature(scene,definition);model.position=Vector3((1-i)*4.4,0,0);model.rotation.y=-.25
 var camera:=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,4,-14);camera.look_at(Vector3(0,1.4,0));camera.fov=48;camera.current=true
 await capture("starlight-creatures")
 scene.queue_free();main.queue_free();await process_frame;quit(0)
