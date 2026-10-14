# Render actual procedural ship and companion meshes using the installed display driver.
extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene := Node3D.new()
 root.add_child(scene)
 var environment_node := WorldEnvironment.new()
 var environment := Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color(0.055,0.035,0.14)
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color(0.76,0.8,1)
 environment.ambient_light_energy = 0.35
 environment_node.environment = environment
 scene.add_child(environment_node)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-35,-25,0)
 light.light_energy = 0.9
 scene.add_child(light)
 var camera := Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 18
 camera.position = Vector3(0,12,22)
 scene.add_child(camera)
 camera.look_at(Vector3(0,0,0))
 camera.current = true
 var classes := ["interceptor","guardian","bomber"]
 for index in range(3):
  var ship := CombatShip.new()
  ship.stats = CollectionCatalog.SHIP_TYPES[classes[index]].duplicate(true)
  ship.position = Vector3((index-1)*8,0,-3)
  ship.rotation.y = PI
  scene.add_child(ship)
  ship.set_physics_process(false)
  ship.remove_from_group("ships")
 for index in range(4):
  var alien := AlienVisual.new()
  alien.definition = CollectionCatalog.find(["crew_nyx","crew_kael","crew_orith","crew_threx"][index])
  alien.position = Vector3((index-1.5)*5.5,0,5)
  alien.rotation.y = PI
  alien.scale = Vector3.ONE * 1.4
  scene.add_child(alien)
 var layer := CanvasLayer.new()
 root.add_child(layer)
 var title := Label.new()
 title.text = "GALACTIC DOMINION / LITTLE SPACE CREW"
 title.position = Vector2(55,38)
 title.add_theme_font_size_override("font_size",32)
 title.add_theme_color_override("font_color",Color(0.8,0.95,1))
 layer.add_child(title)
 var note := Label.new()
 note.text = "Rounded ships • Original alien companions • Orbiting AI attacks"
 note.position = Vector2(56,88)
 note.add_theme_font_size_override("font_size",18)
 layer.add_child(note)
 for index in range(30): await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 var error := image.save_png("/tmp/gd5-cartoon-preview.png")
 print("RENDER_PREVIEW: saved=%s size=%s" % [error == OK,image.get_size()])
 scene.queue_free()
 layer.queue_free()
 await process_frame
 quit(0 if error == OK else 1)
