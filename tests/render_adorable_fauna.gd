extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene:=Node3D.new();root.add_child(scene)
 var world:=SpaceEnvironmentArt.environment();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.035,.05,.085);scene.add_child(world)
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-25,155,0);key.light_color=Color(1,.88,.78);key.light_energy=1.35;scene.add_child(key)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,-25,0);fill.light_color=Color(.5,.7,1);fill.light_energy=.6;scene.add_child(fill)
 var ids:=["bloodstag","duskbat","nightfang","sporehopper","manyeye","thornmanta"]
 for index in range(ids.size()):
  var species:=SanctuaryState.fauna(ids[index])
  var model:=SurfaceArt.creature(scene,species)
  model.position=Vector3((1-index%3)*4.3,2.0 if index<3 else -2.0,0)
  model.rotation.y=-.12
 var camera:=Camera3D.new();camera.position=Vector3(0,2,-14);camera.fov=43;scene.add_child(camera);camera.look_at(Vector3(0,1.7,0));camera.current=true
 var layer:=CanvasLayer.new();root.add_child(layer)
 for index in range(ids.size()):
  var text:=Label.new();text.text=SanctuaryState.fauna(ids[index]).display_name;text.position=Vector2(115+(index%3)*370,335 if index<3 else 655);text.add_theme_font_size_override("font_size",21);text.modulate=Color(.9,.88,1);layer.add_child(text)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 var capture:=root.get_texture().get_image();capture.save_png("/tmp/gd21-cute.png");capture.save_webp("res://docs/images/adorable-fauna.webp",true,.9)
 print("ADORABLE_FAUNA_RENDER_PASS")
 scene.queue_free();layer.queue_free();await process_frame;quit(0)
