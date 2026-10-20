extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene:=Node3D.new();root.add_child(scene);scene.add_child(SpaceEnvironmentArt.environment(12.1))
 var rift:=RiftAnomalyArt.build(scene,Vector3(-8,8,-48));rift.scale=Vector3.ONE*.055
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-30,-25,0);key.light_color=Color(1,.55,.28);key.light_energy=2;scene.add_child(key)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,140,0);fill.light_color=Color(.25,.5,1);fill.light_energy=1.2;scene.add_child(fill)
 var ship:=Node3D.new();ship.position=Vector3(7,-1,0);ship.rotation=Vector3(.16,-.4,-.3);ship.scale=Vector3.ONE*1.4;scene.add_child(ship);SpaceModelFactory.ship(ship,CollectionCatalog.SHIP_TYPES.interceptor)
 var random:=RandomNumberGenerator.new();random.seed=92
 for i in range(26):
  var rock:=MeshInstance3D.new();rock.mesh=SpaceEnvironmentArt.asteroid_mesh(900+i);rock.position=Vector3(random.randf_range(-25,25),random.randf_range(-14,16),random.randf_range(-48,0));rock.scale=Vector3.ONE*random.randf_range(.25,1.7)
  var mat:=ShaderMaterial.new();mat.shader=SpaceEnvironmentArt.ROCK_SHADER;rock.material_override=mat;scene.add_child(rock)
 var camera:=Camera3D.new();camera.position=Vector3(0,6,22);camera.far=2000;camera.fov=55;scene.add_child(camera);camera.look_at(Vector3(0,5,-20));camera.current=true
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_webp("res://docs/images/rift-flight.webp",true,.9)
 print("REFERENCE_SPACE_RENDER_PASS");scene.queue_free();await process_frame;quit()
