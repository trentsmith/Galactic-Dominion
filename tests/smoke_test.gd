extends SceneTree

var checks := 0
var failures := 0
var main: Node
var battle: BattleMatch

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error("FAIL: " + message)
 else:
  print("PASS: " + message)

func frames(count: int) -> void:
 for index in range(count):
  await physics_frame

func freeze_ships() -> void:
 battle.pilot.set_physics_process(false)
 for ship in battle.ships:
  ship.set_physics_process(false)
  ship.velocity = Vector3.ZERO

func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 check(is_instance_valid(main.menu), "Main menu scene loads")
 main.start_battle()
 battle = main.battle
 await frames(3)
 check(battle.ships.size() == 6 and battle.living(0) == 3 and battle.living(1) == 3, "3v3 fleets spawn")
 check(battle.pilot.ship == battle.ships[0], "Player starts in Interceptor")
 check(battle.fleet.switch_to(1), "Switch to Skirmisher")
 check(not battle.ships[0].player_controlled and battle.ships[1].player_controlled, "Previous ship transfers to AI")
 check(battle.fleet.switch_to(2), "Switch to Guardian")
 var guardian := battle.pilot.ship
 check(guardian.activate_ability(), "Guardian ability activates")
 await frames(2)
 check(guardian.health.protection < 1.0, "Guardian aura reduces damage")
 check(not guardian.activate_ability(), "Ability cooldown prevents spam")
 battle.fleet.switch_to(0)
 var player := battle.pilot.ship
 var enemy := battle.ships[3]
 player.targeting.select(enemy)
 battle.fleet.issue_command("attack")
 check(battle.ships[1].brain.commanded_target == enemy, "Attack command propagates selected target")
 for command in ["follow", "defend", "regroup", "retreat"]:
  battle.fleet.issue_command(command)
  check(battle.ships[1].brain.command == command, "Fleet command: " + command)
 freeze_ships()
 battle.set_physics_process(false)
 var health := ShipHealth.new()
 health.configure(player.stats)
 root.add_child(health)
 health.damage(20.0, null)
 check(is_equal_approx(health.hull, health.max_hull) and is_equal_approx(health.shield, health.max_shield - 20), "Shields absorb damage before hull")
 health.damage(health.shield + 10.0, null)
 check(is_equal_approx(health.shield, 0) and is_equal_approx(health.hull, health.max_hull - 10), "Excess damage reaches hull")
 health.tick(5.0)
 check(health.shield > 0.0, "Shield regeneration after delay")
 health.queue_free()
 player.position = Vector3(0, 0, 0)
 player.basis = Basis.IDENTITY
 enemy.position = Vector3(0, 0, -65)
 enemy.basis = Basis.IDENTITY
 player.targeting.select(enemy)
 player.targeting.lock_time = 0
 await frames(2)
 check(not player.weapons.fire(true), "Missile requires lock")
 player.targeting.tick(1.3)
 check(player.targeting.locked(), "Target locks in forward cone")
 var shield_before := enemy.health.shield
 check(player.weapons.fire(), "Laser fires")
 check(not player.weapons.fire(), "Laser cooldown blocks duplicate shot")
 await frames(30)
 check(enemy.health.shield < shield_before, "Laser ray sweep hits enemy")
 shield_before = enemy.health.shield
 check(player.weapons.fire(true), "Locked missile fires")
 await frames(50)
 check(enemy.health.shield < shield_before or enemy.health.hull < enemy.health.max_hull, "Tracking missile hits target")
 player.movement.thrust = Vector3(0, 0, -1)
 player.movement.tick(0.2)
 check(player.velocity.z < 0, "Forward thrust accelerates along ship axis")
 var speed := player.velocity.length()
 player.movement.thrust = Vector3.ZERO
 player.movement.tick(0.01)
 check(player.velocity.length() > 0 and player.velocity.length() < speed, "Momentum persists with drag")
 player.movement.boost_requested = true
 player.movement.thrust = Vector3(0, 0, -1)
 player.movement.tick(0.5)
 check(player.movement.boost_energy < 100, "Boost consumes energy")
 player.activate_ability()
 player.set_physics_process(true)
 await frames(2)
 check(player.movement.ability_multiplier > 1, "Interceptor speed ability works")
 player.set_physics_process(false)
 battle.fleet.switch_to(1)
 battle.pilot.ship.activate_ability()
 battle.pilot.ship.set_physics_process(true)
 await frames(2)
 check(battle.pilot.ship.weapons.overcharge, "Skirmisher weapon overcharge works")
 battle.pilot.ship.set_physics_process(false)
 battle.zone.elapsed = 240
 player.position = Vector3(900, 0, 0)
 var zone_before := player.health.shield + player.health.hull
 battle.zone.tick(1.0, battle.ships)
 var first_damage := zone_before - player.health.shield - player.health.hull
 zone_before = player.health.shield + player.health.hull
 battle.zone.tick(1.0, battle.ships)
 var second_damage := zone_before - player.health.shield - player.health.hull
 check(battle.zone.radius < 600 and first_damage > 0 and second_damage > first_damage, "Zone shrinks and outside damage escalates")
 player.position = Vector3.ZERO
 battle.zone.tick(0.1, battle.ships)
 check(player.outside_time == 0, "Returning to safe zone resets exposure")
 # Removing controlled ship automatically promotes a surviving fleet member.
 var controlled := battle.pilot.ship
 controlled.health.damage(10000, enemy)
 check(battle.pilot.ship != controlled and battle.pilot.ship.alive, "Destroyed player ship automatically switches to survivor")
 check(not battle.fleet.switch_to(controlled.fleet_slot), "Cannot switch into destroyed ship")
 for ship in battle.ships:
  if ship.team == 1:
   ship.health.damage(10000, player)
 check(battle.finished and battle.winner == 0, "Enemy elimination ends match in victory")
 check(is_instance_valid(battle.hud.results), "Results UI is created")
 main.start_battle()
 battle = main.battle
 await frames(2)
 freeze_ships()
 battle.elapsed = 479.99
 battle._physics_process(0.02)
 check(battle.finished and battle.winner == -1, "Eight-minute equal-score timeout yields draw")
 main.start_battle()
 battle = main.battle
 await frames(2)
 freeze_ships()
 for ship in battle.ships:
  if ship.team == 0:
   ship.health.damage(10000, null)
 check(battle.finished and battle.winner == 1, "Allied elimination ends match in defeat")
 main.return_to_menu()
 await frames(2)
 check(main.battle == null and is_instance_valid(main.menu), "Return to menu cleans up battle")
 print("SMOKE TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures > 0 else 0)
