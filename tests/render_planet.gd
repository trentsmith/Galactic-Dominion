extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 var index:=int(args[args.find("--world")+1]) if "--world" in args else 0
 var main: Node=load("res://scenes/main.tscn").instantiate()
 main.profile_path="user://planet-render-only.json";root.add_child(main);await process_frame
 var bot_id: String=["crew_pixlet","crew_lunaflutter","crew_cinderbit"][index]
 main.profile.acquire(bot_id);main.start_planet(index,bot_id);await process_frame
 var expedition: PlanetExpedition=main.surface
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
 expedition.bot.position=Vector3(0,SurfaceWorld.height_at(0,-15)+1.4,-15)
 expedition.bot.visual.rotation.y=PI
 var camera:=expedition.bot.camera
 camera.global_position=Vector3(8,9,0);camera.look_at(Vector3(0,2,-30))
 for species in range(3):
  var animal: SurfaceFauna=expedition.fauna[species*10]
  animal.position=Vector3(-7+species*7,0,-24-species*3)
  animal.position.y=SurfaceWorld.height_at(animal.position.x,animal.position.z)+(3 if expedition.definition.aquatic or species==0 else .5)
  animal.visual.rotation.y=PI
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var capture:=root.get_texture().get_image()
 var id:=expedition.definition.id
 var error:=capture.save_png("/tmp/gd10-planet-"+id+".png")
 capture.save_webp("res://docs/images/planet-"+id+".webp",true,.85)
 print("PLANET_RENDER saved=%s world=%s" % [error==OK,id])
 main.queue_free();await process_frame;quit(0 if error==OK else 1)
