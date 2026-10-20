class_name SurfaceHUD
extends CanvasLayer
var expedition: PlanetExpedition
var info: Label
var prompt: Label
var notes: Label
var panel: Control
var pause_panel: Control
var hunt_label: Label
func label(parent: Node,text: String,position: Vector2,font_size: int=18) -> Label:
 var node:=Label.new();node.text=text;node.position=position;node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_outline_color",Color(.015,.015,.025));node.add_theme_constant_override("outline_size",5)
 parent.add_child(node);return node
func _ready() -> void:
 panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
 label(panel,expedition.definition.display_name.to_upper(),Vector2(25,20),24)
 info=label(panel,"",Vector2(25,60),17)
 notes=label(panel,"",Vector2(25,112),15)
 label(panel,"WASD move · Mouse look · Shift sprint · LMB non-lethal stun pulse\nG hold: scan · C: capture animal · F: gather seed · E: deliver cargo\nB: change bot at ship · T: next hunt · Esc: expedition choices\n"+("Space/Ctrl: swim up/down" if expedition.definition.aquatic else "Space: jump"),Vector2(25,180),14)
 hunt_label=label(panel,"",Vector2(900,25),16)
 hunt_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hunt_label.custom_minimum_size.x=340;hunt_label.size.x=340
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
 var tracked:=expedition.tracked_animal()
 hunt_label.text="ACTIVE HUNT / T: CHANGE SPECIES\n"
 if is_instance_valid(tracked):
  hunt_label.text+="%s / %dm\nHEALTH %d / %d\n"%[tracked.definition.display_name,int(bot.position.distance_to(tracked.position)),int(tracked.health),int(tracked.definition.health)]
  hunt_label.text+="Hold G within 12m to scan" if not expedition.surveyed(tracked) else "LMB: stun to half health, then C" if tracked.definition.damage>0 and tracked.health>tracked.definition.health*.5 else "C within 8m: capture and transport"
 else:hunt_label.text+="No living target nearby / choose another species"
 var catchable:=expedition.capture_target()
 if is_instance_valid(catchable):
  hunt_label.text+="\n\nC TARGET / "+catchable.definition.display_name
  hunt_label.text+="\nREADY TO CAPTURE" if expedition.capture_ready(catchable) else "\nSCAN WITH G FIRST" if not expedition.surveyed(catchable) else "\nSTUN WITH LMB FIRST"
 var nearest:=expedition.nearest_specimen()
 if expedition.finished:prompt.text=""
 elif Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and not get_tree().paused:prompt.text="CLICK THE SCENE TO RESUME EXPLORING / G: scan · C: capture"
 elif bot.position.distance_to(Vector3(0,1.5,0))<10:prompt.text="LANDING SHIP / E: DELIVER TO SANCTUARY · B: CHANGE BOT"
 elif is_instance_valid(nearest):
  var distance:=bot.global_position.distance_to(nearest.global_position)
  var danger:=" / DANGEROUS" if nearest is SurfaceFauna and nearest.definition.damage>0 else ""
  prompt.text="%s%s / %dm / %s" % [nearest.get_meta("scan_name","Unknown"),danger,int(distance),"HOLD G  %d%%" % int(expedition.scan_progress/2*100) if distance<=12 else "APPROACH WITHIN 12m TO SCAN"]
 else:prompt.text="ALL SPECIES SURVEYED / return to the landing ship"
 if not expedition.finished and expedition.bot.position.length()>100:prompt.text+="  / HOME: %dm · 4km WILDERNESS" % int(expedition.bot.position.length())
func _menu(title: String,result: bool) -> Control:
 var center:=CenterContainer.new();center.process_mode=Node.PROCESS_MODE_ALWAYS;center.theme=CartoonStyle.ui_theme()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
 var box:=PanelContainer.new();box.custom_minimum_size=Vector2(560,260);center.add_child(box)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",16);box.add_child(column)
 var title_label:=Label.new();title_label.text=title;title_label.add_theme_font_size_override("font_size",28);column.add_child(title_label)
 if result:
  var detail:=Label.new();detail.text=expedition.status_message;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.x=520;column.add_child(detail)
 else:
  var warning:=Label.new();warning.text="Deliver captures with E at the ship before leaving.\nChanging bots preserves current health and cargo.";column.add_child(warning)
  var bots:=OptionButton.new();bots.name="ActiveBotChoice";column.add_child(bots)
  var choices:=expedition.available_bot_choices()
  for item in choices:
   bots.add_item(item.display_name)
   if item.id==expedition.bot_definition.id:bots.select(bots.item_count-1)
  bots.disabled=not expedition.at_landing_ship()
  bots.tooltip_text="Return to the landing ship to switch bots."
  bots.item_selected.connect(func(index):expedition.switch_bot(choices[index].id))
  var hunts:=OptionButton.new();hunts.name="ActiveHuntChoice";column.add_child(hunts)
  for species in expedition.definition.fauna:
   hunts.add_item("TRACK / "+species.display_name)
   if species.id==expedition.hunt_species:hunts.select(hunts.item_count-1)
  hunts.item_selected.connect(func(index):expedition.select_hunt(expedition.definition.fauna[index].id))
  _button(column,"CRAFT CAPTURE POD / 1 ORE + 1 BLOOM",expedition.craft_capture_pod)
  _button(column,"RESUME",expedition.toggle_pause)
 _button(column,expedition.return_label,func():
  get_tree().paused=false;expedition.return_requested.emit())
 return center
func _button(parent: Control,text: String,callback: Callable) -> void:
 var button:=Button.new();button.text=text;button.custom_minimum_size.y=44;button.pressed.connect(callback);parent.add_child(button)
func show_result(success: bool) -> void:
 if success:
  expedition.status_message="%d new surveys saved. Planet survey: %d / 6.\nDelivered %d animals and %d seeds to your sanctuary.\n%s" % [expedition.pending.size(),expedition.survey_count(),expedition.cargo_animals.size(),expedition.cargo_seeds.size(),expedition.profile.save_error]
 else:expedition.status_message="The expedition bot was destroyed. Unextracted surveys were lost.\nYour owned bots and previously saved discoveries remain available."
 var result:=_menu("EXTRACTION COMPLETE" if success else "BOT DESTROYED",true)
 if success:
  var column: VBoxContainer=result.get_child(0).get_child(0)
  _button(column,"VISIT SANCTUARY / MEET YOUR CAPTURES",func():expedition.sanctuary_requested.emit())

func refresh_choices() -> void:
 var bots:=pause_panel.find_child("ActiveBotChoice",true,false) as OptionButton
 if bots!=null:
  bots.disabled=not expedition.at_landing_ship()
  var choices:=expedition.available_bot_choices()
  for index in range(choices.size()):
   if choices[index].id==expedition.bot_definition.id:bots.select(index)
 var hunts:=pause_panel.find_child("ActiveHuntChoice",true,false) as OptionButton
 if hunts!=null:
  for index in range(expedition.definition.fauna.size()):
   if expedition.definition.fauna[index].id==expedition.hunt_species:hunts.select(index)
