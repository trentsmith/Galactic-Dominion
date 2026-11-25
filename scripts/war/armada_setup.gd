class_name ArmadaSetup
extends Control
var host: Node
var allies: SpinBox
var enemies: SpinBox
var summary: Label
var launch: Button
var initial_fleets:=Vector2i.ZERO
var preset_buttons: Dictionary={}
func _ready() -> void:
 theme=CartoonStyle.ui_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg:=ColorRect.new();bg.color=Color(.015,.025,.04);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
 var panel:=VBoxContainer.new();panel.custom_minimum_size.x=650;panel.add_theme_constant_override("separation",16);center.add_child(panel)
 label(panel,"ARMADA / UP TO 200 v 200",28)
 label(panel,"Your fleet includes you. The opposing fleet is AI-controlled.\nEach side accepts 1–200 fighters; maximum 400 ships total.",17)
 allies=counter(panel,"Your fleet (including your ship)","AlliedCount",ArmadaCombat.count(initial_fleets.x) if initial_fleets.x>0 else host.armada_allies)
 enemies=counter(panel,"Enemy fleet","EnemyCount",ArmadaCombat.count(initial_fleets.y) if initial_fleets.y>0 else host.armada_enemies)
 var presets:=HBoxContainer.new();panel.add_child(presets)
 for sizes in ArmadaCombat.FEATURED_FLEETS+[Vector2i(50,50)]:
  var button:=Button.new();button.name="Preset%dv%d"%[sizes.x,sizes.y];button.text="%d v %d"%[sizes.x,sizes.y];button.toggle_mode=true;button.pressed.connect(choose_preset.bind(sizes));preset_buttons[sizes]=button;presets.add_child(button)
 var row:=HBoxContainer.new();panel.add_child(row);label(row,"ENEMY DIFFICULTY  ",16);host.difficulty_choice(row)
 label(panel,"Standard: full enemy durability and predictive aiming.\nVeteran: faster reactions and more sustained pressure.\nRelaxed keeps reduced enemy durability and longer pauses.",16)
 summary=label(panel,"",17)
 launch=Button.new();launch.name="LaunchArmadaButton";launch.custom_minimum_size.y=50;launch.pressed.connect(func():allies.apply();enemies.apply();host.launch_armada(int(allies.value),int(enemies.value)));panel.add_child(launch)
 var back:=Button.new();back.text="BACK TO COMMAND DECK";back.pressed.connect(host.return_to_menu);panel.add_child(back)
 allies.value_changed.connect(func(_value):refresh());enemies.value_changed.connect(func(_value):refresh());refresh()
func label(parent: Node,text: String,size: int) -> Label:
 var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",size);parent.add_child(node);return node
func counter(parent: Node,text: String,id: String,value: int) -> SpinBox:
 var row:=HBoxContainer.new();parent.add_child(row);var title:=label(row,text,18);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var input:=SpinBox.new();input.name=id;input.min_value=1;input.max_value=200;input.step=1;input.rounded=true;input.value=value;input.custom_minimum_size.x=150;row.add_child(input);return input
func refresh() -> void:
 summary.text="%d allies (you + %d AI) against %d enemies"%[int(allies.value),int(allies.value)-1,int(enemies.value)]
 launch.text="LAUNCH %d v %d"%[int(allies.value),int(enemies.value)]
 for sizes in preset_buttons:preset_buttons[sizes].set_pressed_no_signal(Vector2i(int(allies.value),int(enemies.value))==sizes)
func choose_preset(sizes: Vector2i) -> void:
 allies.value=sizes.x;enemies.value=sizes.y
 # Replace pending text as well as the numeric value before Launch applies edits.
 allies.get_line_edit().text=str(int(allies.value));enemies.get_line_edit().text=str(int(enemies.value));refresh()
