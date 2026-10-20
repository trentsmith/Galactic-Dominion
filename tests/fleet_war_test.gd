extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:failures += 1;push_error(message)
 else:print("PASS: " + message)
func freeze(battle: BattleMatch) -> void:
 battle.set_physics_process(false)
 battle.pilot.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://fleet-war-test.json"
 root.add_child(main)
 await process_frame
 var card := main.menu.find_child("FleetWarButton",true,false) as Button
 check(card != null,"Fleet War can be launched from the menu")
 card.pressed.emit()
 await process_frame
 var battle: BattleMatch = main.battle
 freeze(battle)
 check(battle.ships.size() == 20 and battle.living(0) == 10 and battle.living(1) == 10,"Fleet War spawns ten ships per team")
 check(battle.zone.radius == 1050 and battle.elimination_only,"Fleet War has an enlarged elimination arena")
 var classes := {}
 for ship in battle.fleet.ships:classes[ship.stats.class_name_text] = true
 check(classes.size() == 5,"Reinforcements include all five ship classes")
 check(main.profile.loadouts.size() == 3,"Reinforcements do not alter persistent three-ship loadouts")
 var key := InputEventKey.new()
 key.physical_keycode = KEY_F10
 key.pressed = true
 check(key.is_action_pressed("ship_10"),"F10 maps to the tenth fleet slot")
 # Headless display cannot capture the mouse; validate switching separately.
 battle.fleet.switch_to(9)
 check(battle.pilot.ship == battle.fleet.ships[9] and battle.fleet.ships[0].player_controlled == false,"Player can take control of a reinforcement and release the previous ship to AI")
 var formation_positions := {}
 for ship in battle.fleet.ships:
  if ship != battle.pilot.ship:formation_positions[ship.brain._formation()] = true
 check(formation_positions.size() == 9,"Every wingmate has a distinct formation position")
 battle.elapsed = 479.99
 battle._physics_process(.02)
 check(not battle.finished,"Eight-minute Fleet War deadline does not award a hull-score victory")
 battle.zone.elapsed = 510
 for ship in battle.ships:ship.position = Vector3.ZERO
 var health_before := battle.ships[0].health.hull + battle.ships[0].health.shield
 battle.zone.tick(.1,battle.ships)
 check(battle.ships[0].health.hull + battle.ships[0].health.shield < health_before,"Final collapse damages even ships at the centre")
 # Kill the controlled ship: automatic replacement must cover all ten slots.
 battle.pilot.ship.health.damage(10000,null)
 check(battle.pilot.ship.alive and battle.pilot.ship.fleet_slot != 9,"Destroyed controlled reinforcements automatically transfer control")
 for ship in battle.ships:
  if ship.team == 1 and ship.fleet_slot < 9:ship.health.damage(10000,null)
 check(not battle.finished and battle.living(1) == 1,"One remaining opponent keeps elimination running without respawns")
 battle.ships[19].health.damage(10000,null)
 check(battle.finished and battle.winner == 0 and battle.living(1) == 0,"Last enemy destruction ends the twenty-ship battle")
 check(battle.hud.results != null,"Twenty-ship results screen is created")
 var buttons := battle.hud.results.find_children("", "Button", true, false)
 for button in buttons:
  if button.text == "DEPLOY AGAIN":button.pressed.emit();break
 await process_frame
 check(main.battle.team_size == 10 and main.battle.ships.size() == 20,"Deploy Again preserves the 10v10 mode")
 main.start_battle()
 await process_frame
 freeze(main.battle)
 check(main.battle.ships.size() == 6 and not main.battle.elimination_only,"Standard 3v3 remains available")
 main.queue_free()
 await process_frame
 print("FLEET_WAR_TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
