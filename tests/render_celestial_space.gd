extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene := Node3D.new();root.add_child(scene)
 scene.add_child(SpaceEnvironmentArt.environment(8.1))
 var key := DirectionalLight3D.new();key.rotation_degrees=Vector3(-30,130,0);key.light_color=Color(1,.88,.72);key.light_energy=1.6;scene.add_child(key)
 var fill := DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,-35,0);fill.light_color=Color(.3,.5,.8);fill.light_energy=.25;scene.add_child(fill)
 SpaceEnvironmentArt.planet(scene,Vector3(-16,5,35),12,Color(.09,.27,.23),8.2,true)
 SpaceEnvironmentArt.planet(scene,Vector3(14,9,60),8.5,Color(.26,.19,.32),13.7)
 for index in range(8):
  var rock := MeshInstance3D.new();rock.mesh=SpaceEnvironmentArt.asteroid_mesh(811+index*13)
  rock.position=[Vector3(9,-3,1),Vector3(-12,-4,5),Vector3(15,4,8),Vector3(-7,9,15),Vector3(7,6,20),Vector3(-2,-7,10),Vector3(18,-2,22),Vector3(-18,3,4)][index]
  rock.scale=Vector3(1.8,1.2,1.5)*(0.6+index*.08)
  rock.rotation=Vector3(index*.3,index*.8,.2)
  var mat := ShaderMaterial.new();mat.shader=SpaceEnvironmentArt.ROCK_SHADER;rock.material_override=mat;scene.add_child(rock)
 var wreck := Node3D.new();scene.add_child(wreck);wreck.position=Vector3(8,-2,7);wreck.rotation=Vector3(.2,.5,-.4);SceneryArt.wreck(wreck,Vector3(3,1.5,5))
 var ship := Node3D.new();scene.add_child(ship);ship.position=Vector3(1,-2,0);ship.rotation=Vector3(-.05,.55,-.15);ship.scale=Vector3.ONE*.65
 SpaceModelFactory.ship(ship,CollectionCatalog.SHIP_TYPES.interceptor)
 var camera := Camera3D.new();camera.position=Vector3(0,3,-20);camera.fov=50;camera.far=1000;scene.add_child(camera);camera.look_at(Vector3(0,2,12));camera.current=true
 var layer := CanvasLayer.new();root.add_child(layer)
 var title := Label.new();title.text="A QUIETER KIND OF INFINITY";title.position=Vector2(42,40);title.add_theme_font_size_override("font_size",23);title.add_theme_color_override("font_color",Color(.72,.88,.89));layer.add_child(title)
 for i in range(12):await process_frame
 await RenderingServer.frame_post_draw
 var capture := root.get_texture().get_image()
 capture.save_png("/tmp/gd19-celestial.png");capture.save_webp("res://docs/images/celestial-space.webp",true,.9)
 print("CELESTIAL_RENDER_PASS")
 scene.queue_free();layer.queue_free();await process_frame;quit(0)
