class_name PlanetSelector
extends Control
signal launched(index: int,bot_id: String)
signal back_requested
var profile: PlayerProfile
var bots: OptionButton
var bot_ids: Array[String]=[]
func _ready() -> void:
 theme=CartoonStyle.ui_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg:=ColorRect.new();bg.color=Color(.02,.025,.06);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,28)
 add_child(margin)
 var scroll:=ScrollContainer.new();margin.add_child(scroll)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);scroll.add_child(column);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var title:=Label.new();title.text="PLANET EXPEDITIONS / LITTLE BOT SURVEYS";title.add_theme_font_size_override("font_size",30);column.add_child(title)
 var tip:=Label.new();tip.text="Single-player: choose your bot, then track species with T. Hold G to scan; C captures within 8m.\nWeaken dangerous fauna first. Return to the ship and press E to deliver animals to your sanctuary.";column.add_child(tip)
 bots=OptionButton.new();column.add_child(bots)
 var owned:=PlanetCatalog.available_bots(profile)
 if owned.is_empty():
  bot_ids.append("crew_pixlet");bots.add_item("Loaner Pixlet / survey deployment only")
 else:
  for item in owned:bot_ids.append(item.id);bots.add_item(item.display_name)
  for loadout in profile.loadouts:
   var index:=bot_ids.find(str(loadout.crew))
   if index>=0:bots.select(index);break
 var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",18);column.add_child(row)
 for index in range(PlanetCatalog.WORLDS.size()):
  var planet: PlanetDefinition=PlanetCatalog.WORLDS[index]
  var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(card)
  var body:=VBoxContainer.new();body.add_theme_constant_override("separation",14);card.add_child(body)
  var name_label:=Label.new();name_label.text="%d / %s" % [index+1,planet.display_name];name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.custom_minimum_size.x=300;name_label.add_theme_font_size_override("font_size",23);name_label.modulate=planet.glow_color;body.add_child(name_label)
  var description:=Label.new();description.text=planet.description;description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size=Vector2(300,100);body.add_child(description)
  var animals:=Label.new();animals.text="WILDLIFE / 30 ACTIVE CREATURES\n";animals.add_theme_font_size_override("font_size",16)
  for item in planet.fauna:animals.text+="• "+item.display_name+(" [DANGER]" if item.damage>0 else " [PASSIVE]")+"\n"
  animals.text+="\n3 fauna + 3 flora surveys\n"+("SWIM / Space up · Ctrl down" if planet.aquatic else "GROUND / WASD · Space jump")
  body.add_child(animals)
  var reward:=CollectionCatalog.find(planet.survey_reward)
  var reward_label:=Label.new();reward_label.text="Complete survey reward:\n"+reward.display_name;body.add_child(reward_label)
  var button:=Button.new();button.text="DEPLOY BOT";button.custom_minimum_size.y=46
  button.pressed.connect(func():launched.emit(index,bot_ids[bots.selected]));body.add_child(button)
 var back:=Button.new();back.text="BACK";back.custom_minimum_size.y=44;back.pressed.connect(func():back_requested.emit());column.add_child(back)
