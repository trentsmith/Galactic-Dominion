class_name SanctuaryPanel
extends CanvasLayer
var garden: SanctuaryGarden
var message:="Feed, play and grow together. Bring new friends home from expeditions."
var inventory_label: Label
var info: Label
var resident_info: Label
var flight_info: Label
var message_label: Label
var residents: OptionButton
var habitats: OptionButton
var seeds: OptionButton
var build_kind: OptionButton
var craft_kind: OptionButton
var destination: OptionButton
var resident_name: LineEdit
var resident_ids: Array[int]=[]
var habitat_ids: Array[int]=[]
var seed_ids: Array[String]=[]
var build_ids:=["meadow","reef","rift","planter"]
var craft_ids:=["capture_pod","ore","fiber","food"]
func _ready() -> void:
 var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 var title:=Label.new();title.position=Vector2(20,14);title.text="PERSONAL PLANET / CREATURE SANCTUARY";title.add_theme_font_size_override("font_size",24);root.add_child(title)
 inventory_label=Label.new();inventory_label.position=Vector2(20,50);inventory_label.add_theme_font_size_override("font_size",15);root.add_child(inventory_label)
 var help:=Label.new();help.position=Vector2(20,116);help.text="RMB drag: orbit · Wheel: zoom · Click highlighted plot: build/move\nProduction runs while the sanctuary is open. Residents rest safely when away.\nUnhoused creatures wait in the nursery and do not produce.";help.add_theme_font_size_override("font_size",14);root.add_child(help)
 message_label=Label.new();message_label.position=Vector2(20,655);message_label.custom_minimum_size.x=820;message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(message_label)
 var panel:=PanelContainer.new();panel.theme=CartoonStyle.ui_theme();panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE);panel.offset_left=-390;panel.offset_right=-10;panel.offset_top=10;panel.offset_bottom=-10;root.add_child(panel)
 var scroll:=ScrollContainer.new();panel.add_child(scroll)
 var column:=VBoxContainer.new();column.custom_minimum_size.x=350;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",8);scroll.add_child(column)
 _label(column,"YOUR LITTLE WORLD",23)
 var name_edit:=LineEdit.new();name_edit.placeholder_text="Sanctuary name";name_edit.text=garden.state.name;name_edit.max_length=32;column.add_child(name_edit)
 _button(column,"RENAME PLANET",func():garden.state.name=name_edit.text.strip_edges().left(32);garden.save_and_refresh())
 var palette:=OptionButton.new();for text in ["Mint Meadow","Dream Lavender","Sunset Garden"]:palette.add_item(text)
 palette.select(garden.state.palette);palette.item_selected.connect(func(index):garden.state.palette=index;garden.save_and_refresh());column.add_child(palette)
 info=_label(column,"",15)
 _label(column,"RESIDENT CARE",20)
 residents=OptionButton.new();residents.item_selected.connect(func(index):garden.selected_resident=resident_ids[index];refresh_status());column.add_child(residents)
 resident_name=LineEdit.new();resident_name.placeholder_text="Nickname (24 characters)";resident_name.max_length=24;column.add_child(resident_name)
 _button(column,"NAME RESIDENT",func():
  for resident in garden.state.residents:
   if resident.id==garden.selected_resident:resident.name=resident_name.text.strip_edges().left(24)
  garden.save_and_refresh())
 resident_info=_label(column,"",14)
 var care_row:=HBoxContainer.new();column.add_child(care_row)
 for action in ["feed","pet","play"]:
  _button(care_row,action.to_upper(),func():
   var success:=garden.care_for_resident(action)
   message="Care given!" if success else "Not ready: check food, energy or the pet cooldown"
   garden.profile.save_profile();refresh_status())
 _button(column,"FOCUS RESIDENT / OVERVIEW",func():garden.focus_resident=not garden.focus_resident)
 _button(column,"COLLECT ALL PRODUCE",func():message="Collected %d materials" % SanctuaryState.collect(garden.state);garden.profile.save_profile();refresh_status())
 _label(column,"HABITAT DESIGN",20)
 habitats=OptionButton.new();habitats.item_selected.connect(func(index):garden.selected_habitat=habitat_ids[index];refresh_status());column.add_child(habitats)
 build_kind=OptionButton.new()
 for kind in build_ids:build_kind.add_item((SanctuaryState.HABITATS[kind].title if kind!="planter" else "Food Planter"))
 column.add_child(build_kind)
 _button(column,"BUILD / SELECT AN EMPTY PLOT",func():
  garden.focus_resident=false;garden.build_mode=build_ids[build_kind.selected];garden.move_id=0;garden.grid.visible=true
  var cost: Dictionary={"ore":3,"bloom":2} if garden.build_mode=="planter" else SanctuaryState.HABITATS[garden.build_mode].cost
  message="Click an empty plot. Cost: "+cost_text(cost);refresh_status())
 _button(column,"MOVE SELECTED HABITAT",func():garden.move_id=garden.selected_habitat;garden.build_mode="";garden.grid.visible=true;message="Click an empty plot to move this habitat";refresh_status())
 _button(column,"UPGRADE SELECTED HABITAT",func():
  var success:=SanctuaryState.upgrade(garden.state,garden.selected_habitat)
  message="Habitat upgraded: more capacity and production" if success else "Max level or insufficient ore/bloom";garden.save_and_refresh())
 _button(column,"CANCEL PLACEMENT",func():garden.move_id=0;garden.build_mode="";garden.grid.visible=false;message="Placement cancelled";refresh_status())
 _label(column,"PLANTS & WORKSHOP",20)
 seeds=OptionButton.new();column.add_child(seeds)
 _button(column,"PLANT SELECTED SEED",func():
  var success:=SanctuaryState.plant_seed(garden.state,seed_ids[seeds.selected]) if seeds.selected>=0 and seeds.selected<seed_ids.size() else false
  message="Seed planted" if success else "Need a seed and free planter capacity";garden.save_and_refresh())
 craft_kind=OptionButton.new()
 for text in ["Capture pod / 1 ore + 1 bloom","Ore / 3 food + 1 bloom","Fiber / 2 food + 2 bloom","2 food / 2 bloom"]:craft_kind.add_item(text)
 column.add_child(craft_kind)
 _button(column,"CRAFT",func():
  var success:=SanctuaryState.craft(garden.state,craft_ids[craft_kind.selected]);message="Crafted supplies" if success else "Not enough materials";garden.profile.save_profile();refresh_status())
 _label(column,"FLYING HOME BASE",20)
 flight_info=_label(column,"",14)
 _button(column,"BUILD NEXT FLIGHT UPGRADE",func():
  var success:=SanctuaryState.advance_flight(garden.state);message="Flight upgrade installed" if success else "All upgrades built or more materials needed";garden.save_and_refresh())
 destination=OptionButton.new()
 for text in ["Varkhoss Orbit","Pelagia Orbit","Ny’Zaroth Orbit"]:destination.add_item(text)
 column.add_child(destination)
 _button(column,"LAUNCH / 3 PEARL + 3 ESSENCE + 5 FOOD",func():
  if not garden.do_launch(destination.selected):message="Need all three upgrades, fuel and a different destination"
  refresh_status())
 _button(column,"SAVE & RETURN TO MAIN MENU",garden.close)
 refresh_lists()
func _label(parent: Control,text: String,font_size: int) -> Label:
 var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=330;label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label
func _button(parent: Control,text: String,callback: Callable) -> void:
 var button:=Button.new();button.text=text;button.custom_minimum_size.y=36;button.pressed.connect(callback);parent.add_child(button)
func refresh_lists() -> void:
 if not is_instance_valid(residents):return
 residents.clear();resident_ids.clear()
 for resident in garden.state.residents:
  resident_ids.append(resident.id)
  var name_text: String=resident.name if not resident.name.is_empty() else SanctuaryState.fauna(resident.species).display_name
  residents.add_item(name_text+" / "+SanctuaryState.PRODUCE[resident.species])
  if resident.id==garden.selected_resident:residents.select(residents.item_count-1)
 habitats.clear();habitat_ids.clear()
 for habitat in garden.state.habitats:
  habitat_ids.append(habitat.id);habitats.add_item(habitat.kind.capitalize()+" Lv%d / (%d,%d)" % [habitat.level,habitat.x,habitat.z])
  if habitat.id==garden.selected_habitat:habitats.select(habitats.item_count-1)
 seeds.clear();seed_ids.clear()
 for id in garden.state.seeds:
  if garden.state.seeds[id]<=0:continue
  seed_ids.append(str(id));seeds.add_item(SanctuaryState.seed_name(id)+" x%d" % garden.state.seeds[id])
 refresh_status()
func refresh_status() -> void:
 if not is_instance_valid(info):return
 var state:=garden.state
 var first:="";var second:=""
 for i in range(SanctuaryState.MATERIALS.size()):
  var key: String=SanctuaryState.MATERIALS[i];var text:="%s %d   " % [key.to_upper().replace("CAPTURE_POD","PODS"),state.materials[key]]
  if i<5:first+=text
  else:second+=text
 inventory_label.text=state.name+"\n"+first+"\n"+second
 var waiting:=0
 for resident in state.residents:
  if resident.habitat==0:waiting+=1
 info.text="%d residents / %d habitats / %d in nursery\nPlants: %d · Flight stage: %d / 3" % [state.residents.size(),state.habitats.size(),waiting,state.plants.size(),state.flight_stage]
 resident_info.text="Select a resident"
 for resident in state.residents:
  if resident.id!=garden.selected_resident:continue
  resident_info.text="Food %d / Joy %d / Energy %d\nGrowth %d / Bond %d / Stored %d / 12\n%s" % [resident.nutrition,resident.happiness,resident.energy,resident.growth,resident.bond,resident.production,"Assigned to habitat %d" % resident.habitat if resident.habitat>0 else "Needs a compatible habitat"]
 flight_info.text=""
 if state.flight_stage<3:
  var recipe: Dictionary=SanctuaryState.FLIGHT_RECIPES[state.flight_stage]
  flight_info.text="NEXT: "+recipe.title+"\n"+cost_text(recipe.cost)
 else:flight_info.text="FLIGHT READY / choose an orbit below"
 for habitat in state.habitats:
  if habitat.id==garden.selected_habitat:flight_info.text+="\nHabitat upgrade: %d ore + %d bloom" % [habitat.level*4,habitat.level*3]
 message_label.text=message+("\nSAVE ERROR: "+garden.profile.save_error if not garden.profile.save_error.is_empty() else "")
func cost_text(cost: Dictionary) -> String:
 var parts:=PackedStringArray()
 for key in cost:parts.append("%d %s" % [cost[key],key])
 return " + ".join(parts)
