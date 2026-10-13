extends SceneTree
var failures := 0
var checks := 0
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
 for index in range(count):
  await process_frame
func run() -> void:
 path = "user://exploration-test-%d.json" % Time.get_ticks_usec()
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = path
 root.add_child(main)
 await frames()
 main.start_exploration(0)
 await frames()
 var sector: ExplorationMatch = main.battle
 check(sector.beacons.size() == 3 and sector.fleet.living_count() == 3, "Exploration spawns fleet and three scan signals")
 check(main.profile.exploration_records.has("vesper.sector"), "Entering a sector records discovery")
 check(sector.discover_beacon(0) and main.profile.owns("crew_nyx"), "Scanning a signal discovers an alien crew member")
 var salvage: int = main.profile.salvage
 check(not sector.discover_beacon(0) and main.profile.salvage == salvage, "Repeated scan cannot farm the same discovery reward")
 check(not sector.discover_beacon(-1), "Invalid discovery index is rejected")
 for ship in sector.ships:
  if ship.team == 1: ship.health.damage(10000, null)
 check(main.profile.exploration_records.has("vesper.patrol") and main.profile.owns("shield_recovery"), "Defeating a patrol grants its one-time salvage reward")
 main.start_exploration(1)
 await frames()
 sector = main.battle
 check(sector.sector.display_name == "Kharon Belt" and sector.living(1) == 2, "Warp changes sector and patrol strength")
 sector.discover_beacon(2)
 check(main.profile.owns("ship_bomber") and main.profile.set_ship_class(0, "bomber"), "Exploration unlocks the Bomber hull for fitting")
 check(main.profile.configured_stats(0).ability == "barrage", "Bomber uses missile barrage ability")
 var bomber: ShipStats = main.profile.configured_stats(0)
 main.return_to_menu()
 main.start_battle()
 await frames()
 var ship: CombatShip = main.battle.ships[0]
 check(ship.stats.class_name_text == "Bomber", "Customized Bomber deploys in the normal combat arena")
 ship.targeting.select(main.battle.ships[3])
 ship.targeting.lock_time = 1.2
 ship.activate_ability()
 ship.weapons.fire(true)
 check(ship.weapons.missile_remaining <= bomber.missile_cooldown * 0.31, "Barrage reduces missile reload while active")
 main.return_to_menu()
 main.start_exploration(2)
 await frames()
 sector = main.battle
 sector.discover_beacon(1)
 check(main.profile.owns("ship_support") and main.profile.set_ship_class(0, "support"), "Auralith exploration unlocks Support hull")
 main.return_to_menu()
 main.start_battle()
 await frames()
 ship = main.battle.ships[0]
 var friend: CombatShip = main.battle.ships[1]
 friend.position = ship.position + Vector3(10, 0, 0)
 friend.health.hull -= 25
 var before := friend.health.hull
 ship.activate_ability()
 await physics_frame
 await physics_frame
 check(friend.health.hull > before, "Support ability repairs nearby allied hull")
 main.return_to_menu()
 var restored := PlayerProfile.new(path)
 restored.load_profile()
 check(restored.ship_classes[0] == "support" and restored.exploration_records.has("kharon.signal.2"), "Ship class selection and discovery records survive reload")
 var legacy := restored.to_dict()
 legacy.version = 1
 legacy.erase("ship_classes")
 legacy.erase("exploration_records")
 var file := FileAccess.open(path, FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy));file.close()
 var migrated := PlayerProfile.new(path)
 migrated.load_profile()
 check(migrated.ship_classes[0] == "interceptor" and migrated.owns("ship_bomber"), "Phase 2 saves migrate without losing the inventory")
 main.show_online()
 await frames()
 check(main.menu.get_child(0) is OnlineHub, "Online lobby, profile and marketplace UI instantiates")
 main.queue_free()
 await frames()
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 print("EXPLORATION TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
