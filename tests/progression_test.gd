extends SceneTree

var checks := 0
var failures := 0
var temp_paths: Array[String] = []
var main: Node
var test_path := ""

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, message: String) -> void:
 checks += 1
 if condition:
  print("PASS: " + message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func new_path(label: String) -> String:
 var path := "user://progression-test-%s-%d.json" % [label, Time.get_ticks_usec()]
 temp_paths.append(path)
 return path

func write_json(path: String, data: Variant) -> void:
 var file := FileAccess.open(path, FileAccess.WRITE)
 file.store_string(JSON.stringify(data))
 file.close()

func frames(count: int = 3) -> void:
 for index in range(count):
  await process_frame

func run() -> void:
 var ids: Dictionary = {}
 var catalog_valid := true
 for entry in CollectionCatalog.DEFINITIONS:
  if ids.has(entry.id) or entry.id.is_empty():
   catalog_valid = false
  ids[entry.id] = true
  for key in entry.modifiers:
   if not key in CollectionCatalog.MODIFIABLE_STATS or float(entry.modifiers[key]) <= 0:
    catalog_valid = false
 check(catalog_valid and ids.size() == 39, "Catalog has 39 unique, valid Resource definitions")
 var path := new_path("roundtrip")
 var profile := PlayerProfile.new(path)
 profile.load_profile()
 check(profile.owned_count() == 8 and profile.loadouts.size() == 3, "New profile starts with three crew, four components, and standard livery")
 check(FileAccess.file_exists(path), "Starter profile saves to disk")
 check(not profile.equip(0, "engine", "engine_sprint"), "Cannot fit undiscovered component")
 profile.salvage = 100
 check(profile.research("engine_sprint") and profile.salvage == 20, "Research spends salvage and unlocks schematic")
 check(not profile.research("engine_sprint") and profile.salvage == 20, "Research cannot charge for an already-owned schematic")
 check(profile.equip(0, "engine", "engine_sprint"), "Discovered component fits compatible slot")
 var stats := profile.configured_stats(0)
 check(is_equal_approx(stats.speed, 103.5) and is_equal_approx(stats.hull, 47.0), "Engine trade-offs modify generated ship stats")
 check(stats.engine_style == "sprint", "Component visual metadata follows the selected fitting")
 check(is_equal_approx(CollectionCatalog.CLASS_STATS[0].speed, 90), "Loadout does not mutate shared class Resource")
 check(not profile.equip(0, "shield", "engine_sprint"), "Wrong-slot component is rejected")
 check(not profile.equip(-1, "engine", "engine_standard"), "Invalid ship index is rejected")
 check(not profile.equip(0, "crew", "crew_milo"), "Cannot assign crew serving aboard another ship")
 check(profile.equip(1, "crew", "") and profile.equip(0, "crew", "crew_milo"), "Crew transfers after unassignment")
 profile.acquire("crew_nyx")
 check(profile.equip(1, "crew", "crew_nyx"), "Discovered alien can pilot a ship")
 check(is_equal_approx(profile.configured_stats(1).shield_regen, 6.6), "Alien crew bonus reaches ship statistics")
 profile.acquire("variant_void")
 check(not profile.equip(1, "variant", "variant_void"), "Variant cannot fit the wrong ship class")
 check(profile.equip(0, "variant", "variant_void"), "Rare ship appearance fits its class")
 stats = profile.configured_stats(0)
 check(stats.variant_style == "voidglass" and stats.variant_name == "Voidglass Interceptor", "Variant changes appearance metadata")
 var before := profile.salvage
 var reward := profile.acquire("variant_void")
 check(not reward.new and profile.salvage == before + 15 and profile.inventory.variant_void.count == 2, "Duplicate discovery yields salvage and increments record")
 profile.rename_commander("  Commander Nova  ")
 var restored := PlayerProfile.new(path)
 restored.load_profile()
 check(restored.commander_name == "Commander Nova" and restored.owns("crew_nyx"), "Inventory and commander name survive save/reload")
 check(restored.loadouts[0].engine == "engine_sprint" and restored.loadouts[0].variant == "variant_void", "Loadout survives save/reload")
 check(restored.loadouts[1].crew == "crew_nyx", "Alien crew assignment survives save/reload")
 check(int(restored.inventory.crew_nyx.discovered_at) > 0, "Discovery records contain timestamps")
 before = restored.salvage
 var rolls := restored.settle_battle("match-a", 0, 3, 400)
 check(rolls.size() == 3 and restored.battles == 1 and restored.wins == 1 and restored.salvage >= before + 60, "Victory pays salvage and a permanent ship and two discovery rolls")
 check(restored.settle_battle("match-a", 0, 3, 400).is_empty() and restored.battles == 1, "Same match cannot pay rewards twice")
 check(restored.settle_battle("match-b", 1, 0, 10).size() == 1 and restored.battles == 2, "Defeat still grants a discovery roll")
 var rng := RandomNumberGenerator.new()
 rng.seed = 88371
 var counts := {"common": 0, "uncommon": 0, "rare": 0, "legendary": 0, "mythic": 0}
 for index in range(100000):
  counts[CollectionCatalog.roll(rng).rarity] += 1
 check(counts.mythic > 0 and counts.mythic < 20 and counts.legendary > 5 and counts.legendary < 60, "Seeded sampler exercises shiny-style Legendary and Mythic odds")
 check(CollectionCatalog.rarity_for_ticket(0) == "mythic" and CollectionCatalog.rarity_for_ticket(1) == "legendary" and CollectionCatalog.rarity_for_ticket(4) == "legendary" and CollectionCatalog.rarity_for_ticket(5) == "rare", "Exact rarity boundaries keep Mythic and Legendary tiers disjoint")
 check(str(rolls[0].id).begins_with("ship_") and restored.owns(rolls[0].id), "Victory guarantees permanent hull ownership")
 var prize_reload := PlayerProfile.new(path)
 prize_reload.load_profile()
 check(prize_reload.owns(rolls[0].id), "Victory hull survives restart")
 print("RARITY SAMPLE: ", counts)
 # Save twice to create a known-good backup, corrupt primary, then recover it.
 restored.save_profile()
 var file := FileAccess.open(path, FileAccess.WRITE)
 file.store_string("not valid json")
 file.close()
 var recovered := PlayerProfile.new(path)
 recovered.load_profile()
 check(recovered.owns("variant_void") and recovered.notice.contains("backup"), "Corrupt primary recovers known-good backup")
 check(not recovered.save_blocked and recovered.save_profile(), "Recovered profile can save safely")
 var malformed_path := new_path("malformed")
 var malformed := restored.to_dict()
 malformed.inventory["unknown_future_id"] = {"count": 10}
 malformed.inventory["engine_sprint"] = {"count": "broken"}
 malformed.salvage = "not a number"
 malformed.total_damage = []
 malformed.loadouts[0].shield = "weapon_focus"
 malformed.loadouts[0].crew = "crew_nyx"
 malformed.loadouts[1].crew = "crew_nyx"
 write_json(malformed_path, malformed)
 var sanitized := PlayerProfile.new(malformed_path)
 sanitized.load_profile()
 check(not sanitized.owns("unknown_future_id") and sanitized.salvage == 0 and sanitized.total_damage == 0, "Unknown and malformed save fields are sanitized")
 check(sanitized.loadouts[0].shield == "shield_standard" and sanitized.loadouts[1].crew == "", "Invalid fittings and duplicate crew are repaired on load")
 var partial_path := new_path("partial")
 var partial := restored.to_dict()
 partial.loadouts = [null, {"crew": "crew_astra"}]
 write_json(partial_path, partial)
 var partial_profile := PlayerProfile.new(partial_path)
 partial_profile.load_profile()
 check(partial_profile.loadouts[0].crew == "crew_astra" and partial_profile.loadouts[1].crew == "", "Partial saved fleet cannot assign duplicate starter crew")
 var future_path := new_path("future")
 write_json(future_path, {"version": 99, "inventory": {}, "loadouts": []})
 var future := PlayerProfile.new(future_path)
 future.load_profile()
 check(future.save_blocked and not future.save_profile(), "Future save version is preserved without overwrite")
 check(JSON.parse_string(FileAccess.get_file_as_string(future_path)).version == 99, "Unsupported save remains intact on disk")
 # Instantiate real UI and deploy a configured ship to verify dependencies.
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = new_path("ui")
 root.add_child(main)
 await frames()
 main.profile.acquire("engine_sprint")
 main.profile.acquire("variant_void")
 main.profile.equip(0, "engine", "engine_sprint")
 main.profile.equip(0, "variant", "variant_void")
 main.show_hangar()
 await frames()
 var hangar: HangarScreen = main.menu.get_child(0)
 check(hangar.inventory_list.item_count == 39 and is_instance_valid(hangar.preview.ship), "Hangar and 3D preview load with complete collection")
 check(get_nodes_in_group("ships").is_empty(), "Preview ships do not enter the combat target group")
 for index in range(3):
  hangar.selected_ship = index
  hangar._refresh_fitting()
  await frames(1)
 check(hangar.preview.ship.stats.class_name_text == "Guardian", "All three fleet fittings and previews can be opened")
 hangar.fleet_buttons[0].pressed.emit()
 check(hangar.selected_ship == 0, "Fleet buttons select the correct ship through their callbacks")
 hangar.fleet_buttons[2].pressed.emit()
 var engine_choice: OptionButton = hangar.fitting_rows.get_child(0).get_child(1)
 var engine_index := -1
 for index in range(engine_choice.item_count):
  if engine_choice.get_item_metadata(index) == "engine_sprint":
   engine_index = index
 if engine_index >= 0:
  engine_choice.item_selected.emit(engine_index)
 check(main.profile.loadouts[2].engine == "engine_sprint" and main.profile.loadouts[2].variant == "variant_standard", "Fitting dropdown callback changes its own slot on the selected ship")
 hangar.filter.select(2)
 hangar._refresh_collection()
 check(hangar.inventory_list.item_count == 13, "Collection crew filter lists astronauts and aliens")
 hangar.chosen_definition = "crew_nyx_prism"
 hangar._refresh_detail()
 await frames()
 check(hangar.detail_column.get_child(0) is CollectiblePortrait, "Rare crew appearance portrait is connected")
 main.start_battle()
 await frames()
 var battle: BattleMatch = main.battle
 check(is_equal_approx(battle.ships[0].stats.speed, 103.5) and battle.ships[0].stats.variant_style == "voidglass", "Saved loadout is applied when deploying fleet")
 check(battle.ships[0].crew_name == "Astra Vale", "Assigned astronaut appears on deployed ship")
 var ship_meshes := 0
 for child in battle.ships[0].get_children():
  if child is MeshInstance3D:
   ship_meshes += 1
 check(ship_meshes > 6, "Rare ship variant adds visible geometry")
 var previous_battles: int = main.profile.battles
 battle.finish(0, "Progression integration check")
 check(main.profile.battles == previous_battles + 1 and battle.rewards.size() == 3, "Match completion connects to persistent rewards")
 battle.finish(0, "Duplicate finish")
 check(main.profile.battles == previous_battles + 1, "Repeated finish cannot duplicate persistent reward")
 # Emulate the results screen's Review Discoveries button.
 var results_buttons := battle.hud.results.find_children("", "Button", true, false)
 var review: Button
 for button in results_buttons:
  if button.text.begins_with("REVIEW DISCOVERIES"):
   review = button
 if review != null:
  review.pressed.emit()
  await frames()
 check(main.battle == null and main.menu.get_child(0) is HangarScreen, "Results Review Discoveries button returns directly to hangar")
 main.queue_free()
 await frames()
 for file_path in temp_paths:
  var absolute := ProjectSettings.globalize_path(file_path)
  var directory := DirAccess.open(absolute.get_base_dir())
  for filename in directory.get_files():
   if filename.begins_with(absolute.get_file()):
    DirAccess.remove_absolute(absolute.get_base_dir().path_join(filename))
 print("PROGRESSION TEST: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
