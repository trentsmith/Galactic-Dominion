extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://test-ai_battle_test-" + str(Time.get_ticks_usec()) + ".json"
 root.add_child(main)
 await process_frame
 main.start_battle()
 var battle: BattleMatch = main.battle
 battle.pilot.set_physics_process(false)
 # Let the initial pilot use the same AI as the other five ships.
 battle.pilot.ship.player_controlled = false
 battle.fleet.issue_command("attack")
 var initial_position := battle.ships[3].position
 var peak_shots := 0
 for frame in range(60 * 480 + 10):
  await physics_frame
  if frame % 600 == 0:
   var damage := 0.0
   var shots := 0
   for ship in battle.ships:
    damage += ship.damage_dealt
    shots += ship.shots
   peak_shots = maxi(peak_shots, shots)
   print("AI %ds allies=%d enemies=%d shots=%d damage=%d" % [int(battle.elapsed), battle.living(0), battle.living(1), shots, int(damage)])
  if battle.finished:
   break
 var damage := 0.0
 for ship in battle.ships:
  damage += ship.damage_dealt
 var passed := peak_shots > 0 and damage > 100 and battle.ships[3].position.distance_to(initial_position) > 20 and battle.finished
 print("AI BATTLE: finished=%s winner=%d time=%.2f damage=%.1f" % [battle.finished, battle.winner, battle.elapsed, damage])
 if not passed:
  push_error("AI battle did not maneuver, exchange damage, and reach match end")
 quit(0 if passed else 1)
