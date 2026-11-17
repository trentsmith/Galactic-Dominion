extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args();var view:=str(args[0]) if args.size()>0 else "lead"
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://combat-preview.json";root.add_child(main)
 for i in range(4):await process_frame
 main.start_battle(10);var battle: BattleMatch=main.battle;battle.profile=null;battle.set_physics_process(false);battle.pilot.set_physics_process(false);battle.hud.feedback.set_process(false)
 for i in range(battle.ships.size()):
  var ship:=battle.ships[i];ship.set_physics_process(false);ship.position=Vector3(20000+i*60,20000,20000)
  if ship.companion!=null:ship.companion.set_physics_process(false)
 var origin:=Vector3(0,1200,0);var player:=battle.ships[0];var target:=battle.ships[10]
 player.position=origin;player.rotation=Vector3.ZERO;player.velocity=Vector3.ZERO;target.position=origin+Vector3(35,12,-170);target.velocity=Vector3(40,4,0);target.callsign="Bloodforged Interdictor"
 player.targeting.select(target);battle.pilot.take_control(player)
 if view=="blocked":
  var asteroid:=StaticBody3D.new();asteroid.collision_layer=2;asteroid.position=origin+Vector3(16,5,-85);battle.add_child(asteroid)
  var collision:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=24;collision.shape=shape;asteroid.add_child(collision)
  var mesh:=MeshInstance3D.new();mesh.mesh=SpaceEnvironmentArt.asteroid_mesh(44144);mesh.scale=Vector3.ONE*24;var material:=ShaderMaterial.new();material.shader=SpaceEnvironmentArt.ROCK_SHADER;mesh.material_override=material;asteroid.add_child(mesh)
 elif view=="incoming":
  var missile:=SpaceProjectile.new();missile.spec=target.weapons.secondary.duplicate();missile.spec.speed=220;missile.team=1;missile.target=player;battle.add_child(missile);missile.position=origin+Vector3(-70,5,110);missile.direction=missile.position.direction_to(player.position);missile.set_physics_process(false)
 elif view=="fleet-input":
  battle.ships[1].alive=false
  for i in range(3):await process_frame
  Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
  var key:=InputEventKey.new();key.physical_keycode=KEY_BRACKETRIGHT;key.keycode=KEY_BRACKETRIGHT;key.pressed=true
  Input.parse_input_event(key);Input.flush_buffered_events();await process_frame
  if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED or battle.pilot.ship!=battle.ships[2]:push_error("Native bracket-key selection failed");quit(1);return
  key=key.duplicate();key.pressed=false;Input.parse_input_event(key);Input.flush_buffered_events()
  print("COMBAT_NATIVE_INPUT_PASS: a captured physical bracket key switches 10v10 vessels and skips a destroyed ship")
  main.queue_free();await process_frame;await process_frame;quit();return
 for i in range(6):await process_frame
 player.targeting.tick(2);battle.hud.feedback.tick(.2)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/gd44-"+view+".png");print("COMBAT_HANDLING_RENDERED "+view)
 main.queue_free();await process_frame;await process_frame;quit()
