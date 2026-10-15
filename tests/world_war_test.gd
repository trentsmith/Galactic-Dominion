extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if not value: failures += 1; push_error("FAIL: " + message)
 else: print("PASS: " + message)
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://world-war-%d.json" % Time.get_ticks_usec()
 root.add_child(main)
 await process_frame
 main.start_free_roam()
 await process_frame
 var roam: FreeRoamMatch = main.battle
 roam.set_physics_process(false)
 roam.army.set_physics_process(false)
 roam.pilot.set_physics_process(false)
 for ship in roam.ships: ship.set_physics_process(false)
 roam.toggle_chart()
 await process_frame
 await process_frame
 check(roam.map_panel.position.x >= 0 and roam.map_panel.position.y >= 0 and roam.map_panel.get_rect().end.x <= root.get_visible_rect().size.x and roam.map_panel.get_rect().end.y <= root.get_visible_rect().size.y, "The interactive chart is completely inside the game viewport")
 roam.toggle_chart()
 check(roam.world.stations.size() == 7 and roam.encounters.size() == 7, "Seven connected regions contain service stations and living patrols")
 check(roam.ships.size() == 31 and roam.world.landmarks.size() == 7, "Expanded map contains 21 enemy ships, seven escorts and seven landmarks")
 check(roam.world.obstacle_count == 210, "Each region includes eighteen collidable asteroids and twelve wreck obstacles")
 check(roam.world.hazards.size() == 7, "Every region has a visible ion storm hazard")
 var ship := roam.pilot.ship
 ship.position = Vector3(50000, 0, 0)
 check(roam.travel_fleet(6) and ship.position.distance_to(FreeRoamWorld.CENTERS[6]) < 200, "The final frontier region can be reached by validated station warp")
 check(not roam.travel_fleet(7), "Out-of-range frontier travel is rejected")
 ship.position = roam.world.hazards[6].position
 ship.health.protection = 1
 ship.set_meta("spawn_protection", 0.0)
 var before := ship.health.hull + ship.health.shield
 roam._physics_process(.2)
 check(ship.health.hull + ship.health.shield < before, "Host-controlled ion storms damage real shields and hull")
 check(not roam.world.hazard_at(FreeRoamWorld.CENTERS[6]), "Station arrival corridors are outside ion storms")
 ship.position = roam.world.landmarks[6].position
 check(roam.survey_landmark(1, ship).contains("SURVEY COMPLETE"), "Approaching a landmark allows a real survey")
 check(roam.survey_landmark(1, ship).contains("already"), "Repeated landmark surveys are recognized")
 check(main.profile.exploration_records.has("open.landmark.6"), "Solo landmark discoveries are saved to the profile")
 check(roam.discover_signal(18) and not roam.discover_signal(18), "New frontier signals pay once and retain unique discovery identities")
 check(roam.signal_record(18) != roam.signal_record(6), "New signals cannot alias older region records")
 var war := roam.war
 war.countdown = .1
 var old_positions: Array[Vector3] = []
 for friendly in roam.fleet.ships: old_positions.append(friendly.position)
 war.tick(.2)
 check(war.dispatches == 1 and war.wave == 1 and war.countdown == 60, "The war director dispatches a raid after its countdown")
 check(war.target >= 0 and roam.army.worlds[war.target].owner != war.faction, "Faction raids target a world held by an opponent")
 var raiders := 0
 for encounter in roam.encounters:
  for npc in encounter.ships:
   if npc.team == war.faction and npc.brain.roam_center == roam.army.worlds[war.target].position: raiders += 1
 check(raiders == 3, "Three real AI ships receive the invasion destination")
 var unchanged := true
 for index in range(3): unchanged = unchanged and roam.fleet.ships[index].position == old_positions[index]
 check(unchanged, "AI raid dispatch never moves the player's fleet")
 var party := 0
 for unit in roam.army.units.values():
  if unit.owner == -100 and unit.order == "assault": party += 1
 check(party == 3 and roam.army.units.size() <= 50, "AI landing parties enter creature combat under the global cap")
 for i in range(12): war.dispatch()
 var ai := 0
 for unit in roam.army.units.values():
  if unit.owner < 0: ai += 1
 check(ai <= 24 and roam.army.units.size() <= 50, "Repeated AI invasions respect their budget and the 50-creature cap")
 check(war.history.size() <= 4, "The war briefing keeps a bounded event history")
 var snap := roam.army.snapshot()
 check(snap.war.dispatches == war.dispatches, "Army snapshots include the shared war timeline")
 var old_wave := war.wave
 roam.network_role = "client"
 war.tick(1000);war.dispatch()
 check(war.wave == old_wave, "Clients cannot advance or dispatch the authoritative war")
 roam.army.apply_snapshot(snap)
 check(war.dispatches == snap.war.dispatches, "Clients display the host's war state")
 check(not roam.can_land(0), "Online clients cannot enter local surface expeditions")
 roam.network_role = "offline"
 # Move opponents away to exercise landing gates independently from combat.
 for npc in roam.ships:
  if npc.team != ship.team: npc.position = Vector3(50000, 1000, 0)
 for unit in roam.army.units.values():
  if unit.team != ship.team: unit.position += Vector3(0, 10000, 0)
 ship.position = roam.army.worlds[0].position
 ship.health.regen_delay = 0
 roam.army.worlds[0].owner = 2
 check(not main.land_from_roam(0), "A hostile world must be captured before landing from free roam")
 roam.army.worlds[0].owner = ship.team
 var instance_id := roam.get_instance_id()
 var units_before := roam.army.units.size()
 check(main.land_from_roam(0), "A controlled world accepts a nearby peaceful solo landing")
 await process_frame
 check(main.surface != null and main.surface.definition.id == "varkhoss" and not roam.is_inside_tree(), "Landing opens the real bot surface expedition and suspends the orbital session")
 main.return_from_planet()
 await process_frame
 check(main.battle.get_instance_id() == instance_id and main.battle.army.units.size() == units_before, "Returning from the surface restores the exact same fleet, army and war session")
 check(main.surface == null and main.parked_roam == null, "Surface scene and suspended reference are cleaned up after returning")
 main.return_to_menu()
 await process_frame
 check(not is_instance_valid(roam), "Leaving the expanded world cleans up its scene")
 main.queue_free()
 await process_frame
 await process_frame
 print("WORLD WAR TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
