class_name PlayerProfile
extends RefCounted
signal changed

const VERSION := 2
const SLOTS = ["engine", "shield", "weapon", "utility", "crew", "variant"]
const DEFAULT_CREW = ["crew_astra", "crew_milo", "crew_sera"]
var save_path := "user://commander_profile.json"
var inventory: Dictionary = {}
var loadouts: Array[Dictionary] = []
var ship_classes: Array[String] = ["interceptor", "skirmisher", "guardian"]
var exploration_records: Dictionary = {}
var commander_name := "Vanguard Commander"
var salvage := 0
var battles := 0
var wins := 0
var total_kills := 0
var total_damage := 0.0
var notice := ""
var save_error := ""
var save_blocked := false
var _rng := RandomNumberGenerator.new()
var _settled_battles: Dictionary = {}

func _init(path: String = "user://commander_profile.json") -> void:
 save_path = path
 _rng.randomize()
 _defaults()

func _defaults() -> void:
 inventory.clear()
 loadouts.clear()
 for definition in CollectionCatalog.DEFINITIONS:
  if definition.starter:
   inventory[definition.id] = {"count": 1, "discovered_at": 0, "source": "Fleet issue"}
 for index in range(3):
  loadouts.append({"engine": "engine_standard", "shield": "shield_standard", "weapon": "weapon_standard", "utility": "utility_standard", "crew": DEFAULT_CREW[index], "variant": "variant_standard"})

func owns(id: String) -> bool:
 return inventory.has(id)

func owned_count() -> int:
 return inventory.size()

func load_profile() -> void:
 if not FileAccess.file_exists(save_path):
  if FileAccess.file_exists(save_path + ".bak") and _read(save_path + ".bak"):
   notice = "Recovered your profile from the backup."
  else:
   if save_blocked:
    return
   notice = "Starter fleet issued. Your discoveries will save automatically."
  save_profile()
  return
 if _read(save_path):
  return
 if save_blocked:
  return
 # Preserve corrupt input before replacing it, even if the backup is also damaged.
 var preserved := save_path + ".corrupt-" + str(Time.get_unix_time_from_system()).replace(".", "-")
 var preserve_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(preserved))
 if preserve_error != OK:
  save_blocked = true
  notice = "The save could not be read or preserved. Playing with a temporary starter fleet; saving is disabled."
  return
 if _read(save_path + ".bak"):
  notice = "Recovered your profile from backup. The unreadable save was preserved."
 else:
  if save_blocked:
   return
  _defaults()
  notice = "Unreadable save preserved. A new starter fleet has been issued."
 save_profile()

func _read(path: String) -> bool:
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null or file.get_length() > 2000000:
  return false
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK:
  return false
 var parsed = parser.data
 if not parsed is Dictionary:
  return false
 if not parsed.get("version") is float and not parsed.get("version") is int:
  return false
 if int(parsed.version) > VERSION:
  save_blocked = true
  notice = "This save belongs to a newer game version. Saving is disabled to preserve it."
  return false
 if not int(parsed.version) in [1, VERSION] or not parsed.get("inventory") is Dictionary or not parsed.get("loadouts") is Array:
  return false
 _defaults()
 for id in parsed.inventory:
  var definition := CollectionCatalog.find(str(id))
  var entry = parsed.inventory[id]
  if definition == null or not entry is Dictionary:
   continue
  var count := _integer(entry.get("count", 1), 1, 99999)
  inventory[id] = {"count": count, "discovered_at": _integer(entry.get("discovered_at", 0), 0, 4102444800), "source": str(entry.get("source", "Discovery")).left(80)}
 ship_classes = ["interceptor", "skirmisher", "guardian"]
 var saved_classes = parsed.get("ship_classes", [])
 for index in range(3):
  if saved_classes is Array and index < saved_classes.size():
   var id := str(saved_classes[index])
   if can_use_ship(id):
    ship_classes[index] = id
 exploration_records = {}
 var saved_records = parsed.get("exploration_records", {})
 if saved_records is Dictionary:
  for key in saved_records:
   if str(key).length() < 80 and saved_records[key] is Dictionary:
    exploration_records[str(key)] = {"discovered_at": _integer(saved_records[key].get("discovered_at", 0), 0, 4102444800), "name": str(saved_records[key].get("name", "Unknown")).left(80)}
 var used_crew: Array[String] = []
 for index in range(3):
  var saved_loadout: Dictionary = parsed.loadouts[index] if index < parsed.loadouts.size() and parsed.loadouts[index] is Dictionary else {}
  for slot in SLOTS:
   var id := str(saved_loadout.get(slot, loadouts[index][slot]))
   if _valid_fit(index, slot, id):
    loadouts[index][slot] = id
  var crew_id: String = loadouts[index].crew
  if crew_id in used_crew:
   loadouts[index].crew = ""
  elif not crew_id.is_empty():
   used_crew.append(crew_id)
 commander_name = str(parsed.get("commander_name", "Vanguard Commander")).strip_edges().left(32)
 if commander_name.is_empty():
  commander_name = "Vanguard Commander"
 salvage = _integer(parsed.get("salvage", 0), 0, 9999999)
 battles = _integer(parsed.get("battles", 0), 0, 9999999)
 wins = mini(battles, _integer(parsed.get("wins", 0), 0, 9999999))
 total_kills = _integer(parsed.get("total_kills", 0), 0, 9999999)
 var damage_value = parsed.get("total_damage", 0.0)
 total_damage = clampf(float(damage_value), 0, 999999999) if (damage_value is float or damage_value is int) and is_finite(float(damage_value)) else 0.0
 return true

func _integer(value: Variant, lower: int, upper: int) -> int:
 if not value is int and not value is float:
  return lower
 if not is_finite(float(value)):
  return lower
 return clampi(int(value), lower, upper)

func to_dict() -> Dictionary:
 return {"version": VERSION, "commander_name": commander_name, "inventory": inventory.duplicate(true), "loadouts": loadouts.duplicate(true), "ship_classes": ship_classes.duplicate(), "exploration_records": exploration_records.duplicate(true), "salvage": salvage, "battles": battles, "wins": wins, "total_kills": total_kills, "total_damage": total_damage}

func save_profile() -> bool:
 save_error = ""
 if save_blocked:
  save_error = "Saving disabled; the original profile has been preserved."
  return false
 var path := ProjectSettings.globalize_path(save_path)
 var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
 if file == null:
  save_error = "Cannot write your profile. Check folder permissions."
  return false
 file.store_string(JSON.stringify(to_dict(), "  "))
 file.flush()
 var write_error := file.get_error()
 file.close()
 if write_error != OK:
  save_error = "Profile write failed. The previous save is unchanged."
  return false
 if FileAccess.file_exists(save_path):
  var backup_error := DirAccess.copy_absolute(path, path + ".bak")
  if backup_error != OK:
   save_error = "Could not create a save backup. The previous save is unchanged."
   return false
 var replace_error := DirAccess.rename_absolute(path + ".tmp", path)
 if replace_error != OK:
  save_error = "Could not replace the profile. Your previous save and backup are preserved."
  return false
 return true

func _valid_fit(index: int, slot: String, id: String) -> bool:
 if slot == "crew" and id.is_empty():
  return true
 var definition := CollectionCatalog.find(id)
 if definition == null or not owns(id) or definition.slot != slot:
  return false
 return definition.ship_class.is_empty() or definition.ship_class == CollectionCatalog.SHIP_TYPES[ship_classes[index]].class_name_text

func equip(index: int, slot: String, id: String) -> bool:
 if index < 0 or index > 2 or not slot in SLOTS or not _valid_fit(index, slot, id):
  return false
 if slot == "crew" and not id.is_empty():
  for other in range(3):
   if other != index and loadouts[other].crew == id:
    return false
 loadouts[index][slot] = id
 save_profile()
 changed.emit()
 return true

func rename_commander(value: String) -> void:
 commander_name = value.strip_edges().left(32)
 if commander_name.is_empty():
  commander_name = "Vanguard Commander"
 save_profile()
 changed.emit()

func configured_stats(index: int) -> ShipStats:
 var stats := CollectionCatalog.SHIP_TYPES[ship_classes[index]].duplicate(true) as ShipStats
 for slot in SLOTS:
  var definition := CollectionCatalog.find(str(loadouts[index].get(slot, "")))
  if definition == null:
   continue
  for key in definition.modifiers:
   if key in CollectionCatalog.MODIFIABLE_STATS:
    stats.set(key, float(stats.get(key)) * float(definition.modifiers[key]))
  if definition.kind == "crew":
   stats.crew_id = definition.id
  if definition.kind == "component":
   stats.set(definition.slot + "_style", definition.visual_style)
  if definition.kind == "variant" and definition.visual_style != "standard":
   stats.color = definition.color
   stats.variant_style = definition.visual_style
   stats.variant_name = definition.display_name
 return stats

func acquire(id: String, source: String = "Battle salvage") -> Dictionary:
 var definition := CollectionCatalog.find(id)
 if definition == null:
  return {}
 var is_new := not owns(id)
 if is_new:
  inventory[id] = {"count": 1, "discovered_at": int(Time.get_unix_time_from_system()), "source": source}
 else:
  inventory[id].count = mini(99999, int(inventory[id].count) + 1)
  salvage += 15
 return {"id": id, "new": is_new, "duplicate_salvage": 0 if is_new else 15}

func research(id: String) -> bool:
 var definition := CollectionCatalog.find(id)
 if definition == null or owns(id) or definition.research_cost <= 0 or salvage < definition.research_cost:
  return false
 salvage -= definition.research_cost
 acquire(id, "Hangar research")
 save_profile()
 changed.emit()
 return true

func settle_battle(battle_id: String, winner: int, kills: int, damage: float) -> Array[Dictionary]:
 if _settled_battles.has(battle_id):
  return []
 _settled_battles[battle_id] = true
 battles += 1
 if winner == 0:
  wins += 1
 salvage += 60 if winner == 0 else 30
 total_kills += maxi(0, kills)
 total_damage += maxf(0.0, damage)
 var rewards: Array[Dictionary] = []
 if winner == 0:
  rewards.append(acquire(CollectionCatalog.victory_ship(_rng), "Victory ship — permanent ownership"))
 for index in range(2 if winner == 0 else 1):
  rewards.append(acquire(CollectionCatalog.roll(_rng).id))
 save_profile()
 changed.emit()
 return rewards

func can_use_ship(id: String) -> bool:
 return id in ["interceptor", "skirmisher", "guardian"] or (CollectionCatalog.SHIP_TYPES.has(id) and owns("ship_" + id))

func set_ship_class(index: int, id: String) -> bool:
 if index < 0 or index > 2 or not can_use_ship(id):
  return false
 ship_classes[index] = id
 for slot in SLOTS:
  if not _valid_fit(index, slot, str(loadouts[index][slot])):
   loadouts[index][slot] = "variant_standard" if slot == "variant" else ""
 save_profile()
 changed.emit()
 return true

func record_discovery(id: String, label: String, reward_id: String = "") -> bool:
 if exploration_records.has(id):
  return false
 exploration_records[id] = {"name": label, "discovered_at": int(Time.get_unix_time_from_system())}
 salvage += 25
 if not reward_id.is_empty():
  acquire(reward_id, "Galactic exploration")
 save_profile()
 changed.emit()
 return true
