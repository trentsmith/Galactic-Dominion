class_name BattleHUD
extends CanvasLayer

var battle: BattleMatch
var overlay: Control
var painter: HUDPainter
var results: Control
var feedback: CombatFeedback

func _ready() -> void:
 feedback = CombatFeedback.new()
 feedback.battle = battle
 add_child(feedback)
 overlay = Control.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(overlay)
 painter = HUDPainter.new()
 painter.battle = battle
 painter.feedback = feedback
 painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(painter)

func show_results() -> void:
 overlay.hide()
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
 var layout := VBoxContainer.new()
 layout.add_theme_constant_override("separation",10)
 panel.add_child(layout)
 var content_scroll := ScrollContainer.new()
 content_scroll.custom_minimum_size = Vector2(640,maxf(120,minf(310,get_viewport().get_visible_rect().size.y-410)))
 content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 layout.add_child(content_scroll)
 var column := VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation", 14)
 content_scroll.add_child(column)
 var title := Label.new()
 if battle.winner == -1:
  title.text = "DRAW"
 elif battle.winner == battle.local_team():
  title.text = "VICTORY  /  TEAM %d" % (battle.winner + 1) if battle.network_role == "client" else "VICTORY  /  VANGUARD"
 else:
  title.text = "DEFEAT  /  TEAM %d WINS" % (battle.winner + 1) if battle.network_role == "client" else "DEFEAT  /  RAVAGERS WIN"
 title.add_theme_font_size_override("font_size", 32)
 title.add_theme_color_override("font_color", Color(0.3, 0.85, 1) if battle.winner == battle.local_team() else Color(1, 0.5, 0.3))
 layout.add_child(title)
 layout.move_child(title,0)
 var detail := Label.new()
 detail.text = "%s
Battle duration: %d:%02d" % [battle.end_reason, int(battle.elapsed) / 60, int(battle.elapsed) % 60]
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail.custom_minimum_size.x = 600
 if battle.network_role=="offline" and not battle.training and not battle is FreeRoamMatch and not battle is ExplorationMatch:detail.text += "\nDifficulty: "+SoloDifficulty.title(battle.difficulty)
 layout.add_child(detail)
 layout.move_child(detail,1)
 var explanation := Label.new()
 explanation.name = "BattleExplanation"
 explanation.text = feedback.battle_summary()
 explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 explanation.custom_minimum_size.x = 600
 explanation.add_theme_font_size_override("font_size",13)
 column.add_child(explanation)
 if battle.network_role=="offline" and not battle.training and not battle is FreeRoamMatch and not battle is ExplorationMatch:
  _playtest_feedback(column)
 var stats := Label.new()
 stats.text = "SHIP                      KILLS    DAMAGE    ACCURACY
"
 for ship in battle.ships:
  stats.text += "%s (%s)   %d    %d    %d%%
" % [ship.callsign, ship.stats.class_name_text, ship.kills, int(ship.damage_dealt), int(100.0 * ship.hits / maxf(1, ship.shots))]
  if not ship.alive and not ship.health.damage_history.is_empty():
   stats.text += "  Lost to %s\n" % CombatFeedback.damage_cause(ship.health.damage_history.back())
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
  layout.add_child(hangar)
 var replay := Button.new()
 replay.text = "DEPLOY AGAIN"
 replay.custom_minimum_size.y = 42
 replay.pressed.connect(battle.get_parent().start_battle.bind(battle.team_size))
 layout.add_child(replay)
 var menu := Button.new()
 menu.text = "MAIN MENU"
 menu.custom_minimum_size.y = 42
 menu.pressed.connect(battle.get_parent().return_to_menu)
 layout.add_child(menu)

func _playtest_feedback(column: VBoxContainer) -> void:
 var status := Label.new()
 status.text = "Optional: how did the enemy difficulty feel?"
 column.add_child(status)
 var row := HBoxContainer.new();column.add_child(row)
 for option in [["Too easy","too_easy"],["About right","about_right"],["Too hard","too_hard"]]:
  var button := Button.new();button.text=option[0];button.name="Rate_"+option[1]
  button.pressed.connect(func():
   var error := DifficultyPlaytest.save(battle,option[1])
   status.text = "Feedback saved on this PC. Thank you!" if error==OK else "Could not save feedback. You can keep playing.")
  row.add_child(button)
 var open := Button.new();open.text="OPEN LOCAL PLAYTEST REPORTS"
 open.pressed.connect(func():OS.shell_open(ProjectSettings.globalize_path("user://playtests")))
 column.add_child(open)
 if DifficultyPlaytest.save(battle)!=OK:status.text="Could not save the local report. Check folder permissions; you can keep playing."
