extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://hunt-render-only.json";root.add_child(main);await process_frame
 main.profile.acquire("crew_orbitot");main.profile.acquire("crew_glimbloom");main.profile.acquire("variant_glimbloom")
 main.profile.set_ship_class(0,"guardian");main.profile.equip(0,"variant","variant_glimbloom")
 main.start_planet(0,"crew_orbitot")
 var expedition: PlanetExpedition=main.surface
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
 expedition.select_hunt(expedition.definition.fauna[1].id)
 expedition._physics_process(.01)
 for i in range(10):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/gd20-hunt.png")
 print("LANDING_HUNT_RENDER_PASS")
 main.queue_free();await process_frame;await process_frame;quit(0)
