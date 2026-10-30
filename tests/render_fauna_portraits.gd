extends SceneTree
## Native-render contact sheet; no gameplay or save mutations.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var path:="/tmp/fauna-portraits.png"
 var arguments:=OS.get_cmdline_user_args()
 if not arguments.is_empty():path=arguments[0]
 var form_stage:=int(arguments[1]) if arguments.size()>1 else 0
 var ids:=["bloodstag","duskbat","nightfang","sporehopper","prismgrazer","thornmanta","manyeye","veilcrawler","riftwisp"]
 var ui:=Control.new();root.add_child(ui)
 for i in range(ids.size()):
  var container:=SubViewportContainer.new();container.position=Vector2(i%3*426,i/3*240);container.size=Vector2(426,210);ui.add_child(container)
  var viewport:=SubViewport.new();viewport.size=Vector2i(426,210);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
  var stage:=Node3D.new();viewport.add_child(stage)
  var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.025,.035,.045);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.65,.73,.8);env.environment.ambient_light_energy=.55;stage.add_child(env)
  var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-30,155,0);key.light_color=Color(1,.89,.76);key.light_energy=1.5;stage.add_child(key)
  var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,-30,0);fill.light_color=Color(.55,.72,1);fill.light_energy=.7;stage.add_child(fill)
  var d:=SanctuaryState.fauna(ids[i]);SanctuaryFormArt.creature(stage,d,form_stage)
  var y:=1.65 if ids[i]!="veilcrawler" else 1.05
  if ids[i]=="bloodstag":y=2.0
  var camera:=Camera3D.new();camera.fov=32;camera.position=Vector3(2.1,y+.35,-4.4);stage.add_child(camera);camera.look_at(Vector3(0,y,-.65));camera.current=true
  var label:=Label.new();label.text=d.display_name;label.position=Vector2(i%3*426+14,i/3*240+212);label.add_theme_font_size_override("font_size",17);ui.add_child(label)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
 print("FAUNA_PORTRAITS_RENDERED "+path)
 ui.queue_free();await process_frame;quit()
