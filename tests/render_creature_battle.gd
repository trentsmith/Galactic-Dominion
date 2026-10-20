extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var expedition:=PlanetExpedition.new();expedition.profile=PlayerProfile.new();expedition.profile.save_path="user://render-battle.json"
 expedition.profile.sanctuary.residents.append(SanctuaryState.new_resident(2,"sporehopper","Pearl"))
 expedition.profile.sanctuary.residents.append(SanctuaryState.new_resident(3,"nightfang","Flare"))
 root.add_child(expedition);expedition.set_physics_process(false);expedition.bot.set_physics_process(false);expedition.party.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
 expedition.bot.position=Vector3(0,2,-24)
 expedition.party.deploy(1);expedition.party.deploy(2);expedition.party.deploy(3)
 for key in expedition.party.units:
  var actor: Node3D=expedition.party.units[key].actor;actor.global_position=Vector3((key-2)*4,SurfaceWorld.height_at((key-2)*4,-31)+.2,-31);actor.rotation.y=PI
 var target:=expedition.fauna[20];target.position=Vector3(0,SurfaceWorld.height_at(0,-39)+.5,-39);target.visual.rotation.y=PI
 expedition.hunt_species="nightfang";expedition.party.target=target
 var camera:=expedition.bot.camera;camera.global_position=Vector3(9,10,-14);camera.look_at(Vector3(0,2,-33))
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_webp("res://docs/images/creature-battle.webp",true,.9)
 print("CREATURE_BATTLE_RENDER_PASS");expedition.queue_free();await process_frame;quit()
