extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var expedition:=PlanetExpedition.new();expedition.profile=PlayerProfile.new();expedition.definition=PlanetCatalog.WORLDS[0];root.add_child(expedition)
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false);expedition.wilderness.set_process(false);expedition.hud.visible=false
 for key in [Vector2i(2,0),Vector2i(2,-1),Vector2i(1,0)]:expedition.wilderness.load_tile(key)
 for animal in expedition.fauna:animal.set_physics_process(false)
 expedition.bot.position=Vector3(480,SurfaceWorld.height_at(480,20)+1.5,20)
 for i in range(3):
  var animal: SurfaceFauna=expedition.wilderness.chunks[Vector2i(2,0)].animals[i]
  animal.position=Vector3(474+i*6,SurfaceWorld.height_at(474+i*6,-1)+.5,-1-i*4);animal.visual.rotation.y=PI
 var camera:=expedition.bot.camera;camera.global_position=Vector3(490,17,34);camera.look_at(Vector3(480,5,-14))
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_webp("res://docs/images/wilderness.webp",true,.9)
 print("WILDERNESS_RENDER_PASS");expedition.queue_free();await process_frame;quit()
