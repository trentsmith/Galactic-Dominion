class_name StoryTracker
extends CanvasLayer
var host: Node
var objective: Label
func _ready() -> void:
 layer=4;process_mode=Node.PROCESS_MODE_ALWAYS
 var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 objective=Label.new();objective.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);objective.position=Vector2(24,-22);objective.mouse_filter=Control.MOUSE_FILTER_IGNORE
 objective.add_theme_font_size_override("font_size",12);objective.add_theme_color_override("font_outline_color",Color(.01,.015,.025));objective.add_theme_constant_override("outline_size",4);root.add_child(objective)
func _process(_delta: float) -> void:
 if host.profile==null:return
 objective.text="O · STORY JOURNAL / "+StoryCampaign.TITLES[StoryCampaign.stage(host.profile)]
 objective.visible=not is_instance_valid(host.menu) and not is_instance_valid(host.story_layer)
