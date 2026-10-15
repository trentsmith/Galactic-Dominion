class_name SurfaceHUD
extends CanvasLayer
var expedition: PlanetExpedition
var info: Label
var prompt: Label
var notes: Label
var panel: Control
var pause_panel: Control
func label(parent: Node,text: String,position: Vector2,font_size: int=18) -> Label:
 var node:=Label.new();node.text=text;node.position=position;node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_outline_color",Color(.015,.015,.025));node.add_theme_constant_override("outline_size",5)
 parent.add_child(node);return node
func _ready() -> void:
 panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
 label(panel,expedition.definition.display_name.to_upper(),Vector2(25,20),24)
 info=label(panel,"",Vector2(25,60),17)
 notes=label(panel,"",Vector2(25,112),15)
 label(panel,"WASD move · Mouse look · Shift sprint · LMB defensive pulse\nG hold: scan · C: capture animal · F: gather seed · E: extract · Esc: pause\n"+("Space/Ctrl: swim up/down" if expedition.definition.aquatic else "Space: jump"),Vector2(25,180),14)
 prompt=label(panel,"",Vector2(25,610),18)
 var cross:=label(panel,"+",Vector2(630,345),24);cross.modulate=Color(.65,1,1)
 pause_panel=_menu("EXPEDITION PAUSED",false)
 pause_panel.visible=false
func _process(_delta: float) -> void:
 if not is_instance_valid(expedition.bot):return
 var bot:=expedition.bot
 info.text="%s / HULL %d  SHIELD %d  ENERGY %d\nSURVEY %d / 6  ·  %d UNEXTRACTED  ·  SHIP %dm" % [bot.definition.display_name,int(bot.hull),int(bot.shield),int(bot.stamina),expedition.survey_count(),expedition.pending.size(),int(bot.position.length())]
 notes.text=expedition.status_message+"\nTRANSPORT %d / 4  ·  SEEDS %d  ·  CAPTURE PODS %d" % [expedition.cargo_animals.size(),expedition.cargo_seeds.size(),expedition.profile.sanctuary.materials.capture_pod]
 if expedition.gravity_multiplier()<.5:notes.text+="\nREALITY FRACTURE / LOW GRAVITY / jump with care"
 var nearest:=expedition.nearest_specimen()
 if expedition.finished:prompt.text=""
 elif bot.position.distance_to(Vector3(0,1.5,0))<10:prompt.text="SAFE REFUGE / E: EXTRACT AND SAVE DISCOVERIES"
 elif is_instance_valid(nearest):
  var distance:=bot.global_position.distance_to(nearest.global_position)
  var danger:=" / DANGEROUS" if nearest is SurfaceFauna and nearest.definition.damage>0 else ""
  prompt.text="%s%s / %dm / %s" % [nearest.get_meta("scan_name","Unknown"),danger,int(distance),"HOLD G  %d%%" % int(expedition.scan_progress/2*100) if distance<=12 else "APPROACH WITHIN 12m TO SCAN"]
 else:prompt.text="ALL SPECIES SURVEYED / return to the landing ship"
func _menu(title: String,result: bool) -> Control:
 var center:=CenterContainer.new();center.process_mode=Node.PROCESS_MODE_ALWAYS;center.theme=CartoonStyle.ui_theme()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
 var box:=PanelContainer.new();box.custom_minimum_size=Vector2(560,260);center.add_child(box)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",16);box.add_child(column)
 var title_label:=Label.new();title_label.text=title;title_label.add_theme_font_size_override("font_size",28);column.add_child(title_label)
 if result:
  var detail:=Label.new();detail.text=expedition.status_message;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.x=520;column.add_child(detail)
 else:_button(column,"RESUME",expedition.toggle_pause)
 _button(column,"RETURN TO PLANET SELECTOR",func():
  get_tree().paused=false;expedition.return_requested.emit())
 return center
func _button(parent: Control,text: String,callback: Callable) -> void:
 var button:=Button.new();button.text=text;button.custom_minimum_size.y=44;button.pressed.connect(callback);parent.add_child(button)
func show_result(success: bool) -> void:
 if success:
  expedition.status_message="%d new surveys saved. Planet survey: %d / 6.\nDelivered %d animals and %d seeds to your sanctuary.\n%s" % [expedition.pending.size(),expedition.survey_count(),expedition.cargo_animals.size(),expedition.cargo_seeds.size(),expedition.profile.save_error]
 else:expedition.status_message="The expedition bot was destroyed. Unextracted surveys were lost.\nYour owned bots and previously saved discoveries remain available."
 _menu("EXTRACTION COMPLETE" if success else "BOT DESTROYED",true)
