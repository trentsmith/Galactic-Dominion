extends SceneTree
var checks := 0
var failures := 0
var main: Node
var path := ""
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
 path = "user://free-roam-test-%d.json" % Time.get_ticks_usec()
 main.profile_path = path
 root.add_child(main)
 await frames()
 main.start_free_roam()
 await frames()
 var roam: FreeRoamMatch = main.battle
 # Test navigation and rewards without unrelated AI races.
 for ship in roam.ships: ship.set_physics_process(false)
 roam.pilot.set_physics_process(false)
 roam.set_physics_process(false)
 check(roam.fleet.ships.size() == 3 and roam.ships.size() == 31, "Offline free roam spawns three fleet ships, twenty-one patrol ships and seven escorts")
 check(roam.world.stations.size() == 7 and roam.beacons.size() == 21, "Seven connected regions contain stations and discovery signals")
 check(not roam.zone.visible and roam.zone.radius > 1000000, "Free roam has no shrinking zone or damage boundary")
 check(roam.hud.painter != null and roam.map_panel != null, "Flight HUD and star chart are connected")
 var ship: CombatShip = roam.pilot.ship
 var health_before := ship.health.hull
 ship.position = Vector3(6000, 2000, 9000)
 roam._physics_process(500)
 check(not roam.finished and ship.health.hull == health_before and ship.outside_time == 0, "Flying far away beyond eight minutes does not finish or damage the fleet")
 ship.health.hull -= 10
 health_before = ship.health.hull
 check(roam.travel_fleet(2), "Out-of-combat warp moves the fleet to another region in the same world")
 check(ship.position.distance_to(FreeRoamWorld.CENTERS[2]) < 200 and ship.health.hull == health_before, "Warp preserves existing hull damage")
 check(roam.fleet.ships[1].position.distance_to(ship.position) < 100, "AI teammates travel with the offline fleet")
 check(not roam.travel_fleet(-1) and not roam.travel_fleet(7), "Invalid warp destinations are rejected")
 var hostile: CombatShip = roam.encounters[2].ships[0]
 var old_position := hostile.position
 hostile.position = ship.position + Vector3(100, 0, 0)
 check(not roam.travel_fleet(0) and not roam.service_ship(ship), "Nearby hostiles block both warp and station repair")
 hostile.position = old_position
 ship.health.regen_delay = 2
 check(not roam.travel_fleet(0), "Recent damage prevents escaping combat by warp")
 ship.health.regen_delay = 0
 check(roam.service_ship(ship, true) and ship.health.hull == ship.health.max_hull, "Docking outside combat restores hull, shields and boost")
 ship.health.hull -= 5
 check(roam.service_ship(ship) and ship.health.hull == ship.health.max_hull, "Station service also supports one online pilot ship")
 ship.position += Vector3(0, 0, 400)
 check(not roam.service_ship(ship), "Repairs require being near a station")
 check(roam.discover_signal(6) and main.profile.owns("crew_orith"), "Free-roam discovery signals grant persistent collection rewards")
 var salvage: int = main.profile.salvage
 check(not roam.discover_signal(6) and main.profile.salvage == salvage, "Signals share existing exploration records and cannot pay twice")
 var encounter: Dictionary = roam.encounters[0]
 var wins: int = main.profile.wins
 for victim in encounter.ships: victim.health.damage(100000, ship)
 check(main.profile.wins == wins + 1 and roam.rewards.size() == 3, "Defeating a patrol grants one permanent ship and two discovery rolls")
 check(main.profile.owns(str(roam.rewards[0].id)), "Victory ship is kept in the collection")
 check(not roam.finished and encounter.respawn == 45, "Winning an encounter leaves the world running and schedules a new patrol")
 roam._on_eliminated(encounter.ships[0], ship)
 check(main.profile.wins == wins + 1, "Repeated destruction notifications do not duplicate encounter rewards")
 roam._physics_process(46)
 check(encounter.ships[0].alive and encounter.wave == 1, "Patrol reinforcements return for recurring fights")
 # Respawning does not change permanent ownership or the current session.
 ship.health.protection = 1
 ship.health.damage(100000, null)
 check(not ship.alive and roam.respawns.has(ship), "Fleet ship destruction schedules station redeployment")
 roam._physics_process(13)
 check(ship.alive and not ship.health.dead and ship.health.hull == ship.health.max_hull, "Destroyed ship redeploys with restored combat systems")
 roam._physics_process(0.1)
 health_before = ship.health.hull
 ship.health.damage(100000, null)
 check(ship.alive and ship.health.hull == health_before, "Temporary launch protection prevents immediate repeat deaths")
 ship.weapons.fire()
 check(float(ship.get_meta("spawn_protection")) == 0 and ship.health.protection == 1, "Firing removes launch protection")
 var restored := PlayerProfile.new(path)
 restored.load_profile()
 check(restored.owns(str(roam.rewards[0].id)) and restored.exploration_records.has("auralith.signal.0"), "Free-roam rewards survive save and reload")
 ship.targeting.cycle()
 check(ship.targeting.target == null or ship.position.distance_to(ship.targeting.target.position) <= 1400, "Free-roam target cycling ignores distant regions")
 roam.set_physics_process(true)
 var pause_event := InputEventAction.new()
 pause_event.action = "pause"
 pause_event.pressed = true
 main._unhandled_input(pause_event)
 var paused_time := roam.elapsed
 await frames(6)
 check(paused and roam.elapsed == paused_time, "Offline pause actually stops the free-roam simulation")
 main.resume()
 check(not paused, "Resuming restores flight after a free-roam pause")
 var saved_roam := roam
 main.return_to_menu()
 await frames()
 check(main.battle == null and not is_instance_valid(saved_roam), "Leaving free roam cleans up ships and world")
 # Replicated world uses the same ordered population and client-side presentation.
 var client := FreeRoamMatch.new()
 client.network_role = "client"
 root.add_child(client)
 await frames()
 check(client.ships.size() == 27 and client.encounters.size() == 7, "Online world includes six pilot slots plus twenty-one AI ships")
 check(not client.ships[10].is_physics_processing() and client.ships[10].collision_layer == 0, "AI snapshots cannot simulate damage on the client")
 var previous := client.ships[0]
 client.replace_pilot_ship(0, CollectionCatalog.SHIP_TYPES.bomber, "Late pilot", "Astra", false)
 await frames()
 check(client.ships[0].callsign == "Late pilot" and client.ships[0].stats.ability == "barrage" and not is_instance_valid(previous), "Drop-in pilot replacement applies their actual hull and cleans up the AI slot")
 client.queue_free()
 main.queue_free()
 await frames()
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 OS.delay_msec(50)
 print("FREE ROAM TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
