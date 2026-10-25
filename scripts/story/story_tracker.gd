class_name StoryTracker
extends CanvasLayer
var host: Node
var objective: Label
var marker: Label
func _ready() -> void:
 layer=4;process_mode=Node.PROCESS_MODE_ALWAYS
 var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 objective=Label.new();objective.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);objective.position=Vector2(24,-22);objective.mouse_filter=Control.MOUSE_FILTER_IGNORE
 objective.add_theme_font_size_override("font_size",12);objective.add_theme_color_override("font_outline_color",Color(.01,.015,.025));objective.add_theme_constant_override("outline_size",4);root.add_child(objective)
 marker=Label.new();marker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;marker.custom_minimum_size.x=400;marker.size=Vector2(400,70);marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;marker.add_theme_color_override("font_color",Color(1,.82,.38));marker.add_theme_constant_override("outline_size",5);marker.add_theme_color_override("font_outline_color",Color(.01,.015,.025));root.add_child(marker)
func _process(_delta: float) -> void:
 if host.profile==null:return
 objective.text="O · STORY JOURNAL / "+StoryCampaign.TITLES[StoryCampaign.stage(host.profile)]
 objective.visible=not is_instance_valid(host.menu) and not is_instance_valid(host.story_layer)
 marker.visible=false
 if not objective.visible:return
 var goal:=waypoint()
 if goal.is_empty():return
 var camera: Camera3D=goal.camera
 var at: Vector3=goal.at
 var screen:=camera.unproject_position(at)
 var viewport_size:=get_viewport().get_visible_rect().size
 var behind:=camera.is_position_behind(at)
 if behind:screen=viewport_size-screen
 marker.text=("TURN TOWARD " if behind else "◆ ")+str(goal.text)+" / %dm"%int((goal.from as Vector3).distance_to(at))
 marker.position=Vector2(clampf(screen.x,24,viewport_size.x-424),clampf(screen.y,210,viewport_size.y-230))
 marker.visible=true

func waypoint() -> Dictionary:
 if not host.profile.story.accepted:return {}
 var stage:=StoryCampaign.stage(host.profile)
 if stage==1 and is_instance_valid(host.battle) and host.battle is FreeRoamMatch:
  return {"at":host.battle.army.worlds[0].position,"from":host.battle.pilot.ship.position,"camera":host.battle.camera,"text":"VARKHOSS LANDING / L WITHIN 650m"}
 if stage==2 and is_instance_valid(host.surface) and not host.surface.finished:
  var surface: PlanetExpedition=host.surface
  if not surface.cargo_animals.is_empty():return {"at":Vector3(0,3,0),"from":surface.bot.position,"camera":surface.bot.camera,"text":"DELIVER RESCUE / E AT LANDING SHIP"}
  var best: SurfaceFauna=surface.tracked_animal()
  if is_instance_valid(best):return {"at":best.position+Vector3.UP*2,"from":surface.bot.position,"camera":surface.bot.camera,"text":"RESCUE / "+best.definition.display_name+" / HOLD G · C"}
 return {}
