extends SceneTree
var checks := 0
var failures := 0
var main: Node
func _initialize() -> void:
 call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: " + message)
 else:
  failures += 1
  push_error("FAIL: " + message)
func frames(count: int = 3) -> void:
 for index in range(count): await process_frame
func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://presentation-test-%d.json" % Time.get_ticks_usec()
 root.add_child(main)
 await frames()
 main.network.set_physics_process(false)
 var arena := BattleMatch.new()
 arena.network_role = "client"
 arena.name = "Arena"
 main.network.add_child(arena)
 main.network.arena = arena
 main.network.peer_id = 2
 main.network.slot_owners.assign([2, 0, 0, 0, 0, 0])
 var states: Array = []
 for index in range(6):
  states.append({"position": Vector3(index * 10, 0, index * 20), "rotation": Quaternion.IDENTITY, "velocity": Vector3(0, 0, -35), "hull": 70.0, "shield": 65.0, "boost": 55.0, "boosting": true, "alive": index != 4, "laser": 0.1, "missile": 2.0, "ability": 3.0, "recharge": 17.0, "target": 3, "lock": 1.2, "flash": 0.05})
 var bullets := [{"position": Vector3(0, 0, -5), "direction": Vector3.FORWARD, "team": 0, "missile": false}]
 main.network.receive_snapshot(states, [2, 0, 0, 0, 0, 0], 100, 125, bullets)
 await frames()
 check(arena.ships[0].health.hull == 70 and arena.ships[0].health.shield == 65, "Server health snapshot updates presentation")
 check(arena.ships[0].movement.boost_requested and arena.ships[0].movement.boost_energy == 55, "Boost state reaches the chase-camera and HUD")
 check(arena.ships[0].targeting.target == arena.ships[3] and arena.ships[0].targeting.locked(), "Server target and missile lock reach the client")
 check(arena.ships[0].weapons.missile_remaining == 2 and arena.ships[0].ability_cooldown == 17, "Weapon and ability cooldowns are replicated")
 check(not arena.ships[4].alive and not arena.ships[4].visible and arena.ships[4].health.dead, "Destroyed ship state is presented without client damage simulation")
 check(arena.zone.radius == 125 and arena.elapsed == 100, "Battle timer and spherical zone are replicated")
 var projectile_count := 0
 for child in arena.get_children():
  if child.has_meta("network_projectile"): projectile_count += 1
 check(projectile_count == 1, "Server-owned projectiles have visual proxies")
 main.network.receive_snapshot(states, [0, 0, 0, 2, 0, 0], 101, 120, [])
 await frames()
 check(arena.pilot.ship == arena.ships[3] and arena.fleet.ships.size() == 3 and arena.local_team() == 1, "Control transfer selects the correct camera and friendly fleet")
 projectile_count = 0
 for child in arena.get_children():
  if child.has_meta("network_projectile"): projectile_count += 1
 check(projectile_count == 0, "Removed server projectiles are cleaned up")
 arena.finish(1, "Presentation check")
 var victory := false
 for label in arena.hud.results.find_children("", "Label", true, false):
  if label.text.begins_with("VICTORY"): victory = true
 check(victory, "Team-two player receives victory when team two wins")
 arena.winner = 0
 arena.hud.show_results()
 var defeat := false
 for label in arena.hud.results.find_children("", "Label", true, false):
  if label.text.begins_with("DEFEAT"): defeat = true
 check(defeat, "Team-two player receives defeat when team one wins")
 var path: String = main.profile_path
 main.queue_free()
 await frames()
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 OS.delay_msec(50) # Let the audio mixer release stopped playback after this accelerated test.
 print("ONLINE PRESENTATION TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
