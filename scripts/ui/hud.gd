class_name BattleHUD
extends CanvasLayer

var battle: BattleMatch
var overlay: Control
var painter: HUDPainter
var results: Control

func _ready() -> void:
 overlay = Control.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(overlay)
 painter = HUDPainter.new()
 painter.battle = battle
 painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(painter)

func show_results() -> void:
 results = CenterContainer.new()
 results.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(results)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(650, 0)
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.015, 0.03, 0.07, 0.98)
 style.content_margin_left = 30
 style.content_margin_right = 30
 style.content_margin_top = 26
 style.content_margin_bottom = 26
 panel.add_theme_stylebox_override("panel", style)
 results.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 14)
 panel.add_child(column)
 var title := Label.new()
 title.text = "VICTORY  /  VANGUARD" if battle.winner == 0 else ("DEFEAT  /  RAVAGERS WIN" if battle.winner == 1 else "DRAW")
 title.add_theme_font_size_override("font_size", 32)
 title.add_theme_color_override("font_color", Color(0.3, 0.85, 1) if battle.winner == 0 else Color(1, 0.5, 0.3))
 column.add_child(title)
 var detail := Label.new()
 detail.text = "%s
Battle duration: %d:%02d" % [battle.end_reason, int(battle.elapsed) / 60, int(battle.elapsed) % 60]
 column.add_child(detail)
 var stats := Label.new()
 stats.text = "SHIP                      KILLS    DAMAGE    ACCURACY
"
 for ship in battle.ships:
  stats.text += "%s (%s)   %d    %d    %d%%
" % [ship.callsign, ship.stats.class_name_text, ship.kills, int(ship.damage_dealt), int(100.0 * ship.hits / maxf(1, ship.shots))]
 column.add_child(stats)
 if battle.profile != null:
  var loot := Label.new()
  loot.text = "DISCOVERY SALVAGE  /  " + battle.reward_summary + "\n"
  for reward in battle.rewards:
   var definition := CollectionCatalog.find(str(reward.id))
   loot.text += "%s · %s · %s\n" % [definition.rarity.to_upper(), definition.display_name, "NEW DISCOVERY" if reward.new else "Duplicate +15 salvage"]
  loot.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
  column.add_child(loot)
  if not battle.profile.save_error.is_empty():
   var warning := Label.new()
   warning.text = battle.profile.save_error
   warning.add_theme_color_override("font_color", Color(1, 0.6, 0.25))
   column.add_child(warning)
  var hangar := Button.new()
  hangar.text = "REVIEW DISCOVERIES / HANGAR"
  hangar.custom_minimum_size.y = 42
  hangar.pressed.connect(func():
   var host := battle.get_parent()
   host.return_to_menu()
   host.show_hangar())
  column.add_child(hangar)
 var replay := Button.new()
 replay.text = "DEPLOY AGAIN"
 replay.custom_minimum_size.y = 42
 replay.pressed.connect(battle.get_parent().start_battle)
 column.add_child(replay)
 var menu := Button.new()
 menu.text = "MAIN MENU"
 menu.custom_minimum_size.y = 42
 menu.pressed.connect(battle.get_parent().return_to_menu)
 column.add_child(menu)
