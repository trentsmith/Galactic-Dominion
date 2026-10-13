class_name HangarScreen
extends Control
signal back_requested
signal deploy_requested

const CYAN := Color(0.25, 0.85, 1)
const MUTED := Color(0.6, 0.7, 0.85)
var profile: PlayerProfile
var selected_ship := 0
var chosen_definition := "crew_astra"
var fleet_buttons: Array[Button] = []
var fitting_rows: VBoxContainer
var preview: ShipPreview
var stats_label: Label
var crew_label: Label
var balance_label: Label
var message_label: Label
var inventory_list: ItemList
var detail_column: VBoxContainer
var filter: OptionButton
var tabs: TabContainer
var fleet_title: Label

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var background := ColorRect.new()
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.color = Color(0.014, 0.025, 0.055)
 add_child(background)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 24)
 add_child(margin)
 var root := VBoxContainer.new()
 root.add_theme_constant_override("separation", 12)
 margin.add_child(root)
 var header := HBoxContainer.new()
 header.add_theme_constant_override("separation", 20)
 root.add_child(header)
 var title := _label("VANGUARD  /  FLEET COMMAND", 25, CYAN)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
 balance_label = _label("", 16, CYAN)
 header.add_child(balance_label)
 _button(header, "MAIN MENU", func(): back_requested.emit())
 _button(header, "DEPLOY FLEET", func(): deploy_requested.emit())
 tabs = TabContainer.new()
 tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(tabs)
 _build_fleet_tab()
 _build_collection_tab()
 message_label = _label("Changes save automatically. Component schematics can be fitted to every ship; each crew member serves aboard one ship.", 13, MUTED)
 message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 root.add_child(message_label)
 profile.changed.connect(_refresh)
 _refresh()

func _build_fleet_tab() -> void:
 var scroller := ScrollContainer.new()
 scroller.name = "Fleet Hangar"
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 tabs.add_child(scroller)
 var split := HBoxContainer.new()
 split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 split.add_theme_constant_override("separation", 32)
 scroller.add_child(split)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 460
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 left.add_theme_constant_override("separation", 12)
 split.add_child(left)
 var buttons := HBoxContainer.new()
 left.add_child(buttons)
 for index in range(3):
  var button := Button.new()
  button.text = "F%d  %s" % [index + 1, CollectionCatalog.CLASS_STATS[index].class_name_text]
  button.toggle_mode = true
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.pressed.connect(func():
   selected_ship = index
   _refresh_fitting())
  buttons.add_child(button)
  fleet_buttons.append(button)
 preview = ShipPreview.new()
 left.add_child(preview)
 fleet_title = _label("", 20, CYAN)
 left.add_child(fleet_title)
 crew_label = _label("", 15, MUTED)
 left.add_child(crew_label)
 stats_label = _label("", 15)
 stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 left.add_child(stats_label)
 var right := VBoxContainer.new()
 right.custom_minimum_size.x = 475
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 right.add_theme_constant_override("separation", 12)
 split.add_child(right)
 right.add_child(_label("LOADOUT  /  SIX FITTING SLOTS", 20, CYAN))
 right.add_child(_label("Select discovered equipment. Locked items appear in Collection.", 13, MUTED))
 fitting_rows = VBoxContainer.new()
 fitting_rows.add_theme_constant_override("separation", 12)
 right.add_child(fitting_rows)
 var ability := _label("R activates your class ability. Variants change appearance only.
Fleet changes take effect when you deploy a new match.", 13, MUTED)
 ability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(ability)

func _build_collection_tab() -> void:
 var column := VBoxContainer.new()
 column.name = "Collection & Commander"
 column.add_theme_constant_override("separation", 12)
 tabs.add_child(column)
 var identity := HBoxContainer.new()
 identity.add_theme_constant_override("separation", 14)
 column.add_child(identity)
 identity.add_child(_label("COMMANDER", 15, CYAN))
 var name_edit := LineEdit.new()
 name_edit.text = profile.commander_name
 name_edit.max_length = 32
 name_edit.custom_minimum_size.x = 280
 identity.add_child(name_edit)
 _button(identity, "SAVE NAME", func(): profile.rename_commander(name_edit.text))
 filter = OptionButton.new()
 for title in ["All discoveries", "Components", "Crew", "Ship variants", "Undiscovered"]:
  filter.add_item(title)
 filter.item_selected.connect(func(_index): _refresh_collection())
 identity.add_child(filter)
 var split := HSplitContainer.new()
 split.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(split)
 inventory_list = ItemList.new()
 inventory_list.custom_minimum_size = Vector2(425, 0)
 inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 inventory_list.item_selected.connect(func(index):
  chosen_definition = str(inventory_list.get_item_metadata(index))
  _refresh_detail())
 split.add_child(inventory_list)
 var scroller := ScrollContainer.new()
 scroller.custom_minimum_size.x = 470
 scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 split.add_child(scroller)
 detail_column = VBoxContainer.new()
 detail_column.add_theme_constant_override("separation", 14)
 detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroller.add_child(detail_column)

func _refresh() -> void:
 if not is_node_ready():
  return
 balance_label.text = "%d SALVAGE  /  %d OF %d DISCOVERED" % [profile.salvage, profile.owned_count(), CollectionCatalog.DEFINITIONS.size()]
 _refresh_fitting()
 _refresh_collection()
 if not profile.save_error.is_empty():
  message_label.text = profile.save_error
  message_label.modulate = Color(1, 0.65, 0.3)

func _clear(parent: Node) -> void:
 for child in parent.get_children():
  parent.remove_child(child)
  child.queue_free()

func _refresh_fitting() -> void:
 for index in range(3):
  fleet_buttons[index].set_pressed_no_signal(index == selected_ship)
 _clear(fitting_rows)
 var stats := profile.configured_stats(selected_ship)
 preview.show_stats(stats)
 fleet_title.text = "%s  /  %s" % [stats.class_name_text.to_upper(), stats.variant_name]
 var crew := CollectionCatalog.find(str(profile.loadouts[selected_ship].crew))
 crew_label.text = "CREW  /  %s" % ("Unassigned" if crew == null else crew.display_name + " · " + crew.species)
 stats_label.text = "HULL  %d     SHIELDS  %d     REGEN  %.1f/s
SPEED  %.1f m/s     TURN  %.2f     BOOST  %d
LASER  %.1f dmg / %.2fs     MISSILE  %.1f dmg / %.1fs
ABILITY RECHARGE  %.1fs" % [stats.hull, stats.shield, stats.shield_regen, stats.speed, stats.turn_speed, stats.boost_capacity, stats.laser_damage, stats.laser_cooldown, stats.missile_damage, stats.missile_cooldown, stats.ability_recharge]
 for slot in PlayerProfile.SLOTS:
  var row := VBoxContainer.new()
  row.add_theme_constant_override("separation", 3)
  fitting_rows.add_child(row)
  row.add_child(_label(slot.to_upper(), 12, MUTED))
  var chooser := OptionButton.new()
  chooser.custom_minimum_size.y = 34
  chooser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var selected_id: String = profile.loadouts[selected_ship][slot]
  if slot == "crew":
   chooser.add_item("Unassigned")
   chooser.set_item_metadata(0, "")
  for definition in CollectionCatalog.for_slot(slot, stats.class_name_text):
   if not profile.owns(definition.id):
    continue
   var assigned := -1
   if slot == "crew":
    for other in range(3):
     if other != selected_ship and profile.loadouts[other].crew == definition.id:
      assigned = other
   var item_index := chooser.item_count
   chooser.add_item(definition.display_name + ("  [aboard F%d]" % (assigned + 1) if assigned >= 0 else ""))
   chooser.set_item_metadata(item_index, definition.id)
   chooser.set_item_disabled(item_index, assigned >= 0)
   if definition.id == selected_id:
    chooser.select(item_index)
  chooser.item_selected.connect(func(index):
   var id := str(chooser.get_item_metadata(index))
   if profile.equip(selected_ship, slot, id):
    message_label.text = "Loadout updated and saved." if profile.save_error.is_empty() else profile.save_error
   else:
    message_label.text = "Cannot fit this item. Crew must be unassigned from their current ship first.")
  row.add_child(chooser)
  var fitted := CollectionCatalog.find(selected_id)
  var description := _label(fitted.modifier_text() if fitted != null else "No crew bonus", 12, fitted.rarity_color() if fitted != null else MUTED)
  description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  row.add_child(description)

func _refresh_collection() -> void:
 inventory_list.clear()
 var selected_index := -1
 for definition in CollectionCatalog.DEFINITIONS:
  var owned := profile.owns(definition.id)
  var include := true
  match filter.selected:
   1: include = definition.kind == "component"
   2: include = definition.kind == "crew"
   3: include = definition.kind == "variant"
   4: include = not owned
  if not include:
   continue
  var item_index := inventory_list.item_count
  inventory_list.add_item(("✓ " if owned else "◇ ") + definition.display_name + "  /  " + definition.rarity.to_upper())
  inventory_list.set_item_metadata(item_index, definition.id)
  inventory_list.set_item_custom_fg_color(item_index, definition.rarity_color() if owned else Color(0.42, 0.48, 0.57))
  if definition.id == chosen_definition:
   selected_index = item_index
 if selected_index < 0 and inventory_list.item_count > 0:
  selected_index = 0
  chosen_definition = str(inventory_list.get_item_metadata(0))
 if selected_index >= 0:
  inventory_list.select(selected_index)
 else:
  chosen_definition = ""
 _refresh_detail()

func _refresh_detail() -> void:
 _clear(detail_column)
 var definition := CollectionCatalog.find(chosen_definition)
 if definition == null:
  detail_column.add_child(_label("All entries in this category have been discovered.", 17, MUTED))
  return
 var portrait := CollectiblePortrait.new()
 portrait.definition = definition
 detail_column.add_child(portrait)
 detail_column.add_child(_label(definition.display_name.to_upper(), 23, definition.rarity_color()))
 detail_column.add_child(_label("%s  /  %s  %s" % [definition.rarity.to_upper(), definition.kind.to_upper(), definition.species], 14, MUTED))
 var desc := _label(definition.description, 16)
 desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_column.add_child(desc)
 var bonus := _label(definition.modifier_text(), 14, CYAN)
 bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_column.add_child(bonus)
 if not definition.ship_class.is_empty():
  detail_column.add_child(_label("COMPATIBLE WITH  /  " + definition.ship_class.to_upper(), 13, MUTED))
 if profile.owns(definition.id):
  var discovery: Dictionary = profile.inventory[definition.id]
  var discovered := "Fleet issue" if int(discovery.discovered_at) == 0 else Time.get_datetime_string_from_unix_time(int(discovery.discovered_at)).replace("T", " ") + " UTC"
  detail_column.add_child(_label("DISCOVERED  /  " + discovered + "
SOURCE  /  " + str(discovery.source) + "
RECOVERED  /  " + str(discovery.count) + " times", 13, MUTED))
  if definition.kind != "variant" or definition.ship_class.is_empty() or definition.ship_class == CollectionCatalog.CLASS_STATS[selected_ship].class_name_text:
   _button(detail_column, "FIT TO F%d %s" % [selected_ship + 1, CollectionCatalog.CLASS_STATS[selected_ship].class_name_text.to_upper()], func():
    if profile.equip(selected_ship, definition.slot, definition.id):
     tabs.current_tab = 0
     message_label.text = "Fitted " + definition.display_name + "." if profile.save_error.is_empty() else profile.save_error
    else:
     message_label.text = "This crew member already serves aboard another ship. Unassign them in Fleet Hangar first.")
 else:
  detail_column.add_child(_label("UNDISCOVERED", 15, MUTED))
  if definition.research_cost > 0:
   var button := _button(detail_column, "RESEARCH  /  %d SALVAGE" % definition.research_cost, func():
    if profile.research(definition.id):
     message_label.text = "Discovered " + definition.display_name + " through research." if profile.save_error.is_empty() else profile.save_error
    else:
     message_label.text = "Not enough salvage for this research.")
   button.disabled = profile.salvage < definition.research_cost
  else:
   detail_column.add_child(_label("Discovery through free battle salvage only.", 14, MUTED))
 var stats := _label("COMMAND RECORD  /  %s
%d battles · %d victories · %d kills · %d total damage" % [profile.commander_name, profile.battles, profile.wins, profile.total_kills, int(profile.total_damage)], 13, MUTED)
 stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_column.add_child(stats)
 var odds := _label("FREE BATTLE DISCOVERIES
Victory: 2 rolls +60 salvage. Defeat/draw: 1 roll +30.
Duplicate discoveries yield +15 salvage.
Per roll: Common 70% · Uncommon 24% · Rare 5%
Exotic appearance 0.9% · Mythic appearance 0.1%
Each tier selects uniformly among its entries.
Rare appearances do not improve combat power.", 12, MUTED)
 odds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_column.add_child(odds)

func _label(value: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 return label

func _button(parent: Control, value: String, callback: Callable) -> Button:
 var button := Button.new()
 button.text = value
 button.custom_minimum_size.y = 36
 button.pressed.connect(callback)
 parent.add_child(button)
 return button

func _unhandled_input(event: InputEvent) -> void:
 for index in range(3):
  if event.is_action_pressed("ship_%d" % (index + 1)):
   selected_ship = index
   tabs.current_tab = 0
   _refresh_fitting()
   get_viewport().set_input_as_handled()
 if event.is_action_pressed("pause"):
  back_requested.emit()
  get_viewport().set_input_as_handled()
