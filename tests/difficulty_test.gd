extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func freeze(battle: BattleMatch) -> void:
 battle.set_physics_process(false);battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://difficulty-test.json";root.add_child(main)
 await process_frame
 var catalog_turn: float=BattleMatch.CLASSES[0].turn_speed
 var selector:=main.menu.find_child("DifficultyChoice",true,false) as OptionButton
 check(selector!=null and selector.item_count==3,"Command deck offers all three solo difficulties")
 selector.select(2);selector.item_selected.emit(2)
 var saved:=ConfigFile.new();saved.load("user://settings.cfg")
 check(main.difficulty=="veteran" and saved.get_value("gameplay","difficulty")=="veteran","Selecting Veteran persists the preference")
 var enemy_health: Array[float]=[]
 var reactions: Array[float]=[]
 var pauses: Array[float]=[]
 for id in SoloDifficulty.IDS:
  main.difficulty=id
  main.start_battle(10)
  var battle: BattleMatch=main.battle
  freeze(battle)
  var enemy:=battle.ships[10]
  enemy_health.append(enemy.health.max_hull);reactions.append(enemy.brain.reaction_interval);pauses.append(enemy.brain.burst_pause)
  check(battle.ships.size()==20 and battle.difficulty==id,"10v10 starts with the selected "+id+" preset")
  check(enemy.stats.laser_damage==BattleMatch.CLASSES[0].laser_damage,"Enemy raw weapon damage is unchanged on "+id)
  check(battle.ships[0].weapons.secondary.speed==220 and battle.ships[0].targeting.lock_duration==.8,"Player aiming and missile assistance remains available on "+id)
  main.start_battle(3);freeze(main.battle)
  check(main.battle.ships.size()==6 and main.battle.difficulty==id,"3v3 starts with the selected "+id+" preset")
 check(reactions[0]>reactions[1] and reactions[1]>reactions[2] and pauses[0]>pauses[1] and pauses[1]>pauses[2],"Reaction and firing pressure scale across all three presets")
 check(main.battle.hud.feedback.indicator_direction(main.battle.pilot.ship.position).length()>0,"Coincident damage sources still produce a valid warning direction")
 check(main.battle.hud.painter.feedback_anchor(Vector2(1e12,1e12))==main.battle.hud.painter.size/2,"Offscreen weapon projections keep damage arrows inside the viewport")
 check(enemy_health[1]==enemy_health[2],"Veteran adds no health above Standard")
 check(BattleMatch.CLASSES[0].hull==50 and BattleMatch.CLASSES[0].turn_speed==catalog_turn,"Difficulty leaves catalog resources unchanged")
 var current: BattleMatch=main.battle
 main.show_settings(false);await process_frame
 var settings_selector:=main.menu.find_child("DifficultyChoice",true,false) as OptionButton
 settings_selector.select(0);settings_selector.item_selected.emit(0)
 check(main.difficulty=="relaxed" and current.difficulty=="veteran","Settings changes apply to the next battle, not mid-match")
 main.start_battle(10);freeze(main.battle)
 check(main.battle.difficulty=="relaxed","The next battle consumes the updated preference")
 main.battle.profile=null;main.battle.finish(0,"Test result")
 await process_frame
 var rate:=main.battle.hud.results.find_child("Rate_about_right",true,false) as Button
 check(rate!=null,"Solo results offer optional local playtest ratings")
 rate.pressed.emit()
 var report=JSON.parse_string(FileAccess.get_file_as_string(main.battle.playtest_path))
 check(report.rating=="about_right" and report.difficulty=="relaxed" and report.mode=="10v10" and report.teams.size()==2,"Playtest report saves the actual mode, preset and battle metrics")
 check(not report.has("commander_name") and not report.has("user_id"),"Reports omit player identity and account credentials")
 var online:=BattleMatch.new();online.network_role="server";online.difficulty="veteran";root.add_child(online);freeze(online)
 check(online.ships[3].stats.hull==50 and online.ships[3].brain.reaction_interval==.6 and online.ships[3].brain.burst_pause==0,"Online AI and ship balance ignore solo difficulty")
 online.queue_free()
 main.start_tutorial();freeze(main.battle)
 check(main.battle.training and main.battle.ships[3].brain.reaction_interval==.6,"Training remains safe and independent of selected difficulty")
 main.difficulty="standard";main._save_settings()
 main.queue_free();await process_frame
 print("DIFFICULTY_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
