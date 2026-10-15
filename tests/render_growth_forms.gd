# Actual 3D lineup of the three original growth forms; no gameplay save is edited.
extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene:=Node3D.new();root.add_child(scene);scene.add_child(SpaceEnvironmentArt.environment())
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-25,140,0);sun.light_energy=1.5;scene.add_child(sun)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-30,-35,0);fill.light_color=Color(.45,.7,1);fill.light_energy=.65;scene.add_child(fill)
 var definition:=SanctuaryState.fauna("bloodstag")
 for stage in [0,1,2]:
  var model:=SanctuaryFormArt.creature(scene,definition,stage);model.position=Vector3((stage-1)*4.4,0,0);model.rotation.y=-.4
  var label:=Label3D.new();label.text=["BASE","KINDRED","RADIANT"][stage]+"\n"+SanctuaryForms.form_name(definition.id,stage);label.position=Vector3((stage-1)*4.4,-.3,-.8);label.font_size=34;label.pixel_size=.008;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;scene.add_child(label)
 var camera:=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,5,-15);camera.fov=49;camera.look_at(Vector3(0,1.2,0));camera.current=true
 var layer:=CanvasLayer.new();root.add_child(layer)
 var title:=Label.new();title.text="FRIENDSHIP & LOVE / ORIGINAL GROWTH FORMS";title.position=Vector2(30,22);title.add_theme_font_size_override("font_size",28);layer.add_child(title)
 var subtitle:=Label.new();subtitle.text="Nurture a bond · Choose when to awaken · Keep your companion’s identity";subtitle.position=Vector2(31,65);layer.add_child(subtitle)
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var capture:=root.get_texture().get_image();var error:=capture.save_png("/tmp/gd12-growth-forms.png");capture.save_webp("res://docs/images/growth-forms.webp",true,.88)
 print("GROWTH_RENDER saved=%s" % [error==OK]);scene.queue_free();layer.queue_free();await process_frame;quit(0 if error==OK else 1)
