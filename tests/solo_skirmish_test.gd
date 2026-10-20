extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://solo-skirmish-test.json";root.add_child(main)
 await process_frame
 main.start_battle(10 if "--fleet-war" in OS.get_cmdline_user_args() else 3)
 var battle: BattleMatch=main.battle;battle.max_duration=90
 battle.pilot.set_physics_process(false);battle.pilot.ship.player_controlled=false
 battle.fleet.control_changed.connect(func(ship):ship.player_controlled=false)
 for frame in range(5500):
  await physics_frame
  if battle.finished:break
 var allied_damage:=0.0;var enemy_damage:=0.0;var enemies_destroyed:=0
 for ship in battle.ships:
  if ship.team==0:allied_damage+=ship.damage_dealt
  else:
   enemy_damage+=ship.damage_dealt
   if not ship.alive:enemies_destroyed+=1
 var success:=allied_damage>0 and enemy_damage>0 and enemies_destroyed>0
 print("SOLO_SKIRMISH_RESULT elapsed=%.1f winner=%d enemies_destroyed=%d allied_damage=%.1f enemy_damage=%.1f"%[battle.elapsed,battle.winner,enemies_destroyed,allied_damage,enemy_damage])
 if not success:push_error("Skirmish must exercise combat from both fleets and destroy at least one AI opponent")
 main.queue_free();await process_frame
 print("SOLO_SKIRMISH_PASS" if success else "SOLO_SKIRMISH_FAIL");quit(0 if success else 1)
