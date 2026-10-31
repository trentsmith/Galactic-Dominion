class_name ArmadaSetup
extends Control
var host: Node
var allies: SpinBox
var enemies: SpinBox
var summary: Label
var launch: Button
func _ready() -> void:
 theme=CartoonStyle.ui_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg:=ColorRect.new();bg.color=Color(.015,.025,.04);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
 var panel:=VBoxContainer.new();panel.custom_minimum_size.x=650;panel.add_theme_constant_override("separation",16);center.add_child(panel)
 label(panel,"ARMADA / CHOOSE YOUR FLEETS",28)
 label(panel,"Your fleet includes you. The opposing fleet is AI-controlled.\nEach side accepts 1–200 fighters; maximum 400 ships total.",17)
 allies=counter(panel,"Your fleet (including your ship)","AlliedCount",host.armada_allies)
 enemies=counter(panel,"Enemy fleet","EnemyCount",host.armada_enemies)
 var presets:=HBoxContainer.new();panel.add_child(presets)
 for sizes in [Vector2i(200,200),Vector2i(200,50),Vector2i(50,200),Vector2i(50,50)]:
  var button:=Button.new();button.text="%d v %d"%[sizes.x,sizes.y];button.pressed.connect(func():allies.value=sizes.x;enemies.value=sizes.y);presets.add_child(button)
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
