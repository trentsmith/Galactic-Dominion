# Staged populated garden for visual review, using an isolated preview profile.
extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://sanctuary-render-only.json";root.add_child(main);await process_frame
 var state:=SanctuaryState.defaults()
 for key in SanctuaryState.MATERIALS:state.materials[key]=100
 SanctuaryState.build(state,"reef",0,-1);SanctuaryState.build(state,"rift",1,-1)
 SanctuaryState.intake(state,["duskbat","nightfang","sporehopper","prismgrazer","thornmanta","riftwisp","manyeye","veilcrawler"],["varkhoss.0","viridia.0"])
 SanctuaryState.plant_seed(state,"varkhoss.0");SanctuaryState.plant_seed(state,"viridia.0")
 state.flight_stage=2;main.profile.sanctuary=state;main.show_sanctuary()
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image();var error:=image.save_png("/tmp/gd11-sanctuary.png")
 image.save_webp("res://docs/images/sanctuary-garden.webp",true,.85)
 main.sanctuary_scene.selected_resident=3;main.sanctuary_scene.panel.refresh_lists()
 main.sanctuary_scene.focus_resident=true
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var closeup:=root.get_texture().get_image();closeup.save_png("/tmp/gd11-resident-care.png");closeup.save_webp("res://docs/images/sanctuary-care.webp",true,.85)
 print("SANCTUARY_RENDER saved=%s" % [error==OK]);main.queue_free();await process_frame;quit(0 if error==OK else 1)
