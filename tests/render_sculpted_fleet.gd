extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene := Node3D.new();root.add_child(scene)
 var space := SpaceEnvironmentArt.environment(12.1)
 space.environment.background_mode=Environment.BG_COLOR
 space.environment.background_color=Color(.012,.021,.045)
 scene.add_child(space)
 var key := DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,140,0);key.light_energy=1.4;scene.add_child(key)
 var fill := DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,-35,0);fill.light_color=Color(.35,.6,1);fill.light_energy=.6;scene.add_child(fill)
 var classes := ["interceptor","skirmisher","guardian","bomber","support"]
 for row in range(2):
  for column in range(5):
   var stats: ShipStats=CollectionCatalog.SHIP_TYPES[classes[column]].duplicate(true)
   var skin := CollectionCatalog.find("variant_orbitot" if row==0 else "variant_glimbloom")
   stats.variant_style=skin.visual_style;stats.color=skin.color
   var model := Node3D.new();scene.add_child(model)
   SpaceModelFactory.ship(model,stats)
   model.position=Vector3((2-column)*3.3,0,2.9 if row==0 else -2.9)
   model.scale=Vector3.ONE*.43
   model.rotation.y=-.20
 var camera := Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=10
 camera.position=Vector3(0,12,-16);scene.add_child(camera);camera.look_at(Vector3.ZERO);camera.current=true
 var layer := CanvasLayer.new();root.add_child(layer)
 for column in range(5):
  var label := Label.new();label.text=classes[column].to_upper();label.position=Vector2(100+column*235,110);label.add_theme_font_size_override("font_size",19);layer.add_child(label)
 for row in range(2):
  var label := Label.new();label.text="ORBITOT LIVERY" if row==0 else "GLIMBLOOM LIVERY";label.position=Vector2(42,42 if row==0 else 350);label.add_theme_font_size_override("font_size",24);label.add_theme_color_override("font_color",Color(.4,.9,1) if row==0 else Color(1,.6,.95));layer.add_child(label)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 var capture := root.get_texture().get_image()
 capture.save_png("/tmp/gd19-fleet.png");capture.save_webp("res://docs/images/sculpted-fleet.webp",true,.9)
 print("UNIVERSAL_LIVERIES_RENDER_PASS")
 scene.queue_free();layer.queue_free();await process_frame;quit(0)
