extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://army-render-only.json"
 root.add_child(main)
 await process_frame
 main.start_free_roam()
 var arena: FreeRoamMatch = main.battle
 arena.set_physics_process(false)
 arena.pilot.set_physics_process(false)
 for ship in arena.ships:
  ship.set_physics_process(false)
  ship.visible = false
 var army := arena.army
 army.set_physics_process(false)
 army.units.clear()
 var center: Vector3 = army.worlds[0].position
 for side in range(2):
  for i in range(6):
   var id := army.spawn(CreatureArmy.SPECIES[side * 3 + i % 3], side, side + 10, center + Vector3((i % 3 - 1) * 25, i / 3 * 25, side * 65 - 30))
   army.units[id].flash = .15
   army.units[id].target = center + Vector3((i % 3 - 1) * 25, i / 3 * 25, (1-side)*65-30)
 army.worlds[0].progress = 12
 army._sync_visuals(1)
 army._update_labels()
 arena.camera.position = center + Vector3(90, 75, -125)
 arena.camera.look_at(center + Vector3(0, 15, 10))
 arena.hud.visible = false
 arena.info.get_parent().visible = false
 army.labels[0].position = center + Vector3(0, 70, 10)
 var layer := CanvasLayer.new()
 root.add_child(layer)
 var title := Label.new()
 title.text = "CREATURE ARMIES / WORLD CONQUEST"
 title.position = Vector2(25, 20)
 title.add_theme_font_size_override("font_size", 28)
 layer.add_child(title)
 var caption := Label.new()
 caption.text = "AI squads · Shared online world control · 50 active creatures maximum"
 caption.position = Vector2(25, 60)
 layer.add_child(caption)
 for i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 var capture := root.get_texture().get_image()
 capture.save_png("/tmp/gd13-army.png")
 capture.save_webp("res://docs/images/creature-armies.webp", true, .88)
 print("ARMY_RENDER_PASS")
 main.queue_free()
 layer.queue_free()
 await process_frame
 quit(0)
