extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var host=load("res://scenes/main.tscn").instantiate();host.profile_path="user://benchmark.json";root.add_child(host);await process_frame
 var args:=OS.get_cmdline_user_args()
 var allies:=200;var enemies:=200;var seed_value:=81337;var seconds:=90;var preset:="standard"
 for i in range(args.size()-1):
  match args[i]:
   "--allies":allies=clampi(int(args[i+1]),1,200)
   "--enemies":enemies=clampi(int(args[i+1]),1,200)
   "--seed":seed_value=int(args[i+1])
   "--seconds":seconds=clampi(int(args[i+1]),10,180)
   "--difficulty":preset=SoloDifficulty.valid(args[i+1])
 host.difficulty=preset
 if host.has_method("show_armada_setup"):host.start_armada(seed_value,allies,enemies)
 else:host.start_armada(seed_value)
 await process_frame
 var battle: BattleMatch=host.battle
 battle.pilot.set_physics_process(false);battle.pilot.ship.player_controlled=false
 battle.fleet.control_changed.connect(func(ship):ship.player_controlled=false)
 for i in range(seconds*60):
  await physics_frame
  if battle.finished:break
 var stats: Array=[]
 for team in range(2):
  var damage:=0.0;var shots:=0;var hits:=0
  for ship in battle.ships:
   if ship.team==team:damage+=ship.damage_dealt;shots+=ship.shots;hits+=ship.hits
  stats.append({"team":team,"survivors":battle.living(team),"damage":snappedf(damage,.1),"shots":shots,"hits":hits})
 print("ARMADA_AI_COMPARISON "+JSON.stringify({"version":ProjectSettings.get_setting("application/config/version"),"seed":seed_value,"difficulty":preset,"requested_fleets":[allies,enemies],"elapsed":battle.elapsed,"winner":battle.winner,"fleets":stats}))
 host.queue_free();await process_frame;await process_frame;quit()
