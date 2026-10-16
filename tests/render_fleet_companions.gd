extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene := Node3D.new()
 root.add_child(scene)
 scene.add_child(SpaceEnvironmentArt.environment(12.1))
 var key := DirectionalLight3D.new()
 key.rotation_degrees = Vector3(-28,145,0)
 key.light_color = Color(1,0.88,0.74)
 key.light_energy = 1.5
 scene.add_child(key)
 var fill := DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(-15,-35,0)
 fill.light_color = Color(0.3,0.55,1)
 fill.light_energy = 0.7
 scene.add_child(fill)
 SpaceEnvironmentArt.planet(scene,Vector3(-16,9,32),6,Color(0.26,0.10,0.5),5)
 for index in range(2):
  var bot := AlienVisual.new()
  bot.definition = CollectionCatalog.find("crew_orbitot" if index==0 else "crew_glimbloom")
  bot.position = Vector3(2.65 if index==0 else -2.65,0,0)
  bot.rotation = Vector3(-0.08,-0.18 if index==0 else 0.18,0)
  scene.add_child(bot)
  bot._process(0.25)
  bot.set_process(false)
 var camera := Camera3D.new()
 camera.fov = 43
 camera.position = Vector3(0,1.6,-11.5)
 scene.add_child(camera)
 camera.look_at(Vector3(0,0.6,0))
 camera.current = true
 var layer := CanvasLayer.new()
 root.add_child(layer)
 for index in range(2):
  var label := Label.new()
  label.text = "ORBITOT\nGravity Loop" if index==0 else "GLIMBLOOM\nPrism Pulse"
  label.position = Vector2(170 if index==0 else 790,570)
  label.add_theme_font_size_override("font_size",27)
  label.add_theme_color_override("font_color",Color(0.4,0.92,1) if index==0 else Color(1,0.65,0.95))
  layer.add_child(label)
 for index in range(8):await process_frame
 await RenderingServer.frame_post_draw
 var capture := root.get_texture().get_image()
 capture.save_webp("res://docs/images/orbitot-glimbloom.webp",true,0.9)
 var error := capture.save_png("/tmp/gd17-companions.png")
 print("FLEET_COMPANIONS_RENDER: ",error)
 scene.queue_free();layer.queue_free()
 await process_frame
 quit(error)
