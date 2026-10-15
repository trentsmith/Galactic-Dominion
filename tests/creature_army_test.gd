extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
 else: print("PASS: " + message)
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://army-test-%d.json" % Time.get_ticks_usec()
 root.add_child(main)
 await process_frame
 main.start_free_roam()
 await process_frame
 var roam: FreeRoamMatch = main.battle
 roam.set_physics_process(false)
 roam.pilot.set_physics_process(false)
 for ship in roam.ships: ship.set_physics_process(false)
 var army := roam.army
 army.set_physics_process(false)
 var ship := roam.pilot.ship
 check(army.units.size() == 18 and army.worlds.size() == 3, "Three worlds have six defending creatures each")
 check(army.deploy(11, ship, -1).contains("Invalid") and army.units.size() == 18, "Unknown species requests cannot spawn units")
 check(army.deploy(11, ship, 0).contains("Deployed 5") and army.owned_count(11) == 5, "A squad deploys with authenticated owner identity")
 army.deploy(11, ship, 0)
 check(army.owned_count(11) == 5, "Host cooldown prevents deployment spam")
 army.cooldowns.clear()
 army.deploy(11, ship, 1)
 army.cooldowns.clear()
 army.deploy(11, ship, 2)
 check(army.owned_count(11) == 10, "Ten creature personal limit is enforced")
 for owner in range(12, 20): army.deploy(owner, ship, 2)
 check(army.units.size() == 50, "All player and AI creatures share the hard cap of 50")
 check(army.spawn("nightfang", 0, 999, Vector3.ZERO) == -1, "Raw host spawning also respects the global cap")
 army.remove_owner(11)
 check(army.units.size() == 40 and army.owned_count(11) == 0, "Disconnect cleanup releases capacity")
 army.units.clear()
 army.cooldowns.clear()
 ship.position = army.worlds[0].position
 army.deploy(11, ship, 2)
 check(not army.command(12, ship, "recall") or army.owned_count(11) == 5, "Another player cannot recall your creatures")
 check(army.command(11, ship, "assault"), "Nearby living command ship can order an assault")
 var troop: Dictionary = army.units.values()[0]
 check(troop.order == "assault" and troop.world == 0, "Assault orders select the nearest real world")
 army.command(11, ship, "follow")
 check(troop.order == "follow" and troop.leader == roam.ships.find(ship), "Follow orders restore command ship escort")
 ship.position = Vector3(99999, 0, 0)
 check(not army.command(11, ship, "assault"), "Distant world assaults are rejected")
 ship.position = army.worlds[0].position
 ship.alive = false
 check(not army.command(11, ship, "assault") and army.deploy(31, ship, 0).contains("living"), "Dead ships cannot deploy or command troops")
 ship.alive = true
 army.units.clear()
 var at: Vector3 = army.worlds[0].position
 var a := army.spawn("nightfang", 0, 11, at)
 var b := army.spawn("nightfang", 2, -1, at + Vector3(25, 0, 0))
 var initial: float = army.units[b].hp
 army.tick(0.1)
 check(army.units[b].hp < initial and army.units[a].hp < 45, "Opposing creatures independently target and damage each other")
 check(army.units[a].flash > 0, "Real attacks produce replicated attack flashes")
 army.units.clear()
 for world in army.worlds:
  world.owner = 2
  world.progress = 0.0
 a = army.spawn("nightfang", 0, 11, at)
 army._capture(15)
 check(army.worlds[0].owner == 2 and army.worlds[0].progress == 15, "An uncontested army starts capture without instantly winning")
 b = army.spawn("bloodstag", 1, 12, at)
 army._capture(20)
 check(army.worlds[0].progress == 15 and army._contested(0), "Enemy troops contest and freeze capture")
 army.units.erase(b)
 army._capture(15)
 check(army.worlds[0].owner == 0 and army.worlds[0].captures == 1, "Thirty uncontested seconds transfers world control")
 army.units.erase(a)
 b = army.spawn("nightfang", 1, 12, at)
 army._capture(30)
 check(army.worlds[0].owner == 1 and army.worlds[0].captures == 2, "Other players can recapture conquered worlds")
 army.units.clear()
 a = army.spawn("nightfang", 0, 11, at)
 army._capture(10)
 army.units.clear()
 army._capture(3)
 check(army.worlds[0].progress == 7, "Abandoned capture progress decays")
 for candidate in roam.ships: candidate.position = Vector3(100000, 0, 0)
 ship.position = at
 ship.team = 0
 ship.health.protection = 1
 ship.set_meta("spawn_protection", 0.0)
 b = army.spawn("nightfang", 2, -1, at + Vector3(30, 0, 0))
 var hp_before := ship.health.hull + ship.health.shield
 army.tick(.1)
 check(ship.health.hull + ship.health.shield < hp_before, "Hostile troops can damage real ship shields and hull")
 check(army.units[b].hp < 45, "Nearby ships automatically fire back at hostile creatures")
 army.units[b].hp = 1
 army.tick(1)
 check(not army.units.has(b), "Destroyed troops are removed and immediately free capacity")
 var snap := army.snapshot()
 snap.worlds[0].owner = 99
 check(army.worlds[0].owner != 99, "Snapshots do not alias authoritative state")
 var server_count := army.units.size()
 army.apply_snapshot({"units": [], "worlds": []})
 check(army.units.size() == server_count, "Host refuses client-style snapshot application")
 roam.network_role = "client"
 check(army.spawn("nightfang", 0, 1, at) == -1 and army.deploy(1, ship, 0).contains("Invalid"), "Client cannot create authoritative troops")
 army.apply_snapshot(snap)
 check(army.worlds[0].owner == 99, "Client display accepts host world state")
 check(roam.army_species.item_count == 9 and roam.army_status != null, "Star chart provides all nine troop models and army status")
 main.queue_free()
 await process_frame
 await process_frame
 print("CREATURE ARMY TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
