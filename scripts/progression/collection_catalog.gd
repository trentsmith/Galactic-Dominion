class_name CollectionCatalog
extends RefCounted

const DEFINITIONS = [
 preload("res://resources/collectibles/engine_standard.tres"),
 preload("res://resources/collectibles/shield_standard.tres"),
 preload("res://resources/collectibles/weapon_standard.tres"),
 preload("res://resources/collectibles/utility_standard.tres"),
 preload("res://resources/collectibles/engine_sprint.tres"),
 preload("res://resources/collectibles/engine_vector.tres"),
 preload("res://resources/collectibles/shield_bulwark.tres"),
 preload("res://resources/collectibles/shield_recovery.tres"),
 preload("res://resources/collectibles/weapon_focus.tres"),
 preload("res://resources/collectibles/weapon_swarm.tres"),
 preload("res://resources/collectibles/utility_reserve.tres"),
 preload("res://resources/collectibles/utility_relay.tres"),
 preload("res://resources/collectibles/crew_astra.tres"),
 preload("res://resources/collectibles/crew_milo.tres"),
 preload("res://resources/collectibles/crew_sera.tres"),
 preload("res://resources/collectibles/crew_lyra.tres"),
 preload("res://resources/collectibles/crew_nyx.tres"),
 preload("res://resources/collectibles/crew_kael.tres"),
 preload("res://resources/collectibles/crew_orith.tres"),
 preload("res://resources/collectibles/crew_nyx_prism.tres"),
 preload("res://resources/collectibles/crew_astra_solar.tres"),
 preload("res://resources/collectibles/variant_standard.tres"),
 preload("res://resources/collectibles/variant_aurora.tres"),
 preload("res://resources/collectibles/variant_celestial.tres"),
 preload("res://resources/collectibles/variant_void.tres")
]
const CLASS_STATS = [preload("res://resources/ships/interceptor.tres"), preload("res://resources/ships/skirmisher.tres"), preload("res://resources/ships/guardian.tres")]
const MODIFIABLE_STATS = ["hull", "shield", "speed", "acceleration", "turn_speed", "laser_damage", "laser_cooldown", "missile_damage", "missile_cooldown", "shield_regen", "boost_capacity", "boost_regen", "ability_recharge"]

static func find(id: String) -> CollectibleDefinition:
 for entry in DEFINITIONS:
  if entry.id == id:
   return entry
 return null

static func for_slot(slot: String, ship_class: String = "") -> Array[CollectibleDefinition]:
 var output: Array[CollectibleDefinition] = []
 for entry in DEFINITIONS:
  if entry.slot == slot and (entry.ship_class.is_empty() or entry.ship_class == ship_class):
   output.append(entry)
 return output

static func roll(rng: RandomNumberGenerator) -> CollectibleDefinition:
 # Free battle salvage: per roll, not per item. Mythic appearances have no power bonus.
 var chance := rng.randf()
 var rarity := "common"
 if chance < 0.001:
  rarity = "mythic"
 elif chance < 0.01:
  rarity = "exotic"
 elif chance < 0.06:
  rarity = "rare"
 elif chance < 0.30:
  rarity = "uncommon"
 var pool: Array[CollectibleDefinition] = []
 for entry in DEFINITIONS:
  if entry.rarity == rarity:
   pool.append(entry)
 return pool[rng.randi_range(0, pool.size() - 1)]
