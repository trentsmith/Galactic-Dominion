# Actual 3D render used to review the supplied Lunaflutter art direction.
extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene := Node3D.new()
 root.add_child(scene)
 var environment := SpaceEnvironmentArt.environment(12.1)
 environment.environment.sky.sky_material.set_shader_parameter("moon_palette",1.0)
 scene.add_child(environment)
 var key := DirectionalLight3D.new()
 key.rotation_degrees = Vector3(-28,145,0)
 key.light_color = Color(1,0.84,0.62)
 key.light_energy = 1.45
 scene.add_child(key)
 var fill := DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(-15,-35,0)
 fill.light_color = Color(0.12,0.55,1)
 fill.light_energy = 0.8
 scene.add_child(fill)
 SpaceEnvironmentArt.planet(scene,Vector3(-14,7,18),7.5,Color(0.34,0.08,0.66),5.0)
 SpaceEnvironmentArt.planet(scene,Vector3(16,-8,23),7.0,Color(0.62,0.12,0.55),12.0)
 var pixlet := AlienVisual.new()
 pixlet.definition = CollectionCatalog.find("crew_lunaflutter")
 pixlet.position = Vector3(-1.9,-0.10,0)
 pixlet.rotation = Vector3(-0.06,-0.28,-0.12)
 scene.add_child(pixlet)
 pixlet.set_process(false)
 var ship := CombatShip.new()
 ship.stats = CollectionCatalog.SHIP_TYPES.interceptor.duplicate()
 ship.stats.variant_style = "moon_moth"
 ship.stats.color = Color(0.82,0.22,1)
 ship.position = Vector3(4.4,1.95,7)
 ship.rotation = Vector3(-0.08,-0.38,-0.20)
 ship.scale = Vector3.ONE*0.51
 scene.add_child(ship)
 ship.set_physics_process(false)
 ship.remove_from_group("ships")
 for index in range(5):
  var rock := MeshInstance3D.new()
  rock.mesh = SpaceEnvironmentArt.asteroid_mesh(92+index*5)
  rock.position = [Vector3(-6,-2,4),Vector3(7,4,9),Vector3(-9,3,10),Vector3(5,-4,7),Vector3(-2,5,15)][index]
  rock.scale = Vector3.ONE * (0.5+index*0.12)
  var material := ShaderMaterial.new()
  material.shader = SpaceEnvironmentArt.ROCK_SHADER
  rock.material_override = material
  scene.add_child(rock)
 var camera := Camera3D.new()
 camera.fov = 48
 camera.position = Vector3(0,1.3,-12.0)
 scene.add_child(camera)
 camera.look_at(Vector3(0,0.65,1.3))
 camera.current = true
 var layer := CanvasLayer.new()
 root.add_child(layer)
 var title := Label.new()
 title.text = "LUNAFLUTTER / MOON MOTH"
 title.position = Vector2(42,38)
 title.add_theme_font_size_override("font_size",30)
 title.add_theme_color_override("font_color",Color(1,0.73,1))
 layer.add_child(title)
 var subtitle := Label.new()
 subtitle.text = "Petal wings · Crystal antennae · Dream Drift"
 subtitle.position = Vector2(43,80)
 layer.add_child(subtitle)
 for index in range(5): await process_frame
 await RenderingServer.frame_post_draw
 var screenshot := root.get_texture().get_image()
 screenshot.save_webp("res://docs/images/lunaflutter-space-art.webp",true,0.88)
 var error := screenshot.save_png("/tmp/gd8-lunaflutter.png")
 print("REFERENCE_RENDER: saved=%s" % (error==OK))
 scene.queue_free();layer.queue_free()
 await process_frame
 quit(0 if error==OK else 1)
