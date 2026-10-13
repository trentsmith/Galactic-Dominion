class_name CollectionCatalog
extends RefCounted

const DEFINITIONS = [
 preload("res://resources/collectibles/ship_interceptor.tres"),
 preload("res://resources/collectibles/ship_skirmisher.tres"),
 preload("res://resources/collectibles/ship_guardian.tres"),
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
 preload("res://resources/collectibles/variant_void.tres"),
 preload("res://resources/collectibles/ship_bomber.tres"),
 preload("res://resources/collectibles/ship_support.tres"),
 preload("res://resources/collectibles/crew_threx.tres"),
 preload("res://resources/collectibles/crew_iola.tres"),
 preload("res://resources/collectibles/weapon_lance.tres"),
 preload("res://resources/collectibles/shield_crystal.tres"),
 preload("res://resources/collectibles/variant_bomber.tres"),
 preload("res://resources/collectibles/variant_support.tres")
]
const CLASS_STATS = [preload("res://resources/ships/interceptor.tres"), preload("res://resources/ships/skirmisher.tres"), preload("res://resources/ships/guardian.tres")]
const SHIP_TYPES = {"interceptor": CLASS_STATS[0], "skirmisher": CLASS_STATS[1], "guardian": CLASS_STATS[2], "bomber": preload("res://resources/ships/bomber.tres"), "support": preload("res://resources/ships/support.tres")}
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
 var rarity := rarity_for_ticket(rng.randi_range(0, 16383))
 var pool: Array[CollectibleDefinition] = []
 for entry in DEFINITIONS:
  if entry.rarity == rarity:
   pool.append(entry)
 return pool[rng.randi_range(0, pool.size() - 1)]

# Disjoint tickets: Mythic 1/16384, Legendary 4/16384 = 1/4096.
static func rarity_for_ticket(ticket: int) -> String:
 if ticket == 0:
  return "mythic"
 if ticket < 5:
  return "legendary"
 if ticket < 824:
  return "rare"
 if ticket < 4756:
  return "uncommon"
 return "common"

static func victory_ship(rng: RandomNumberGenerator) -> String:
 var classes := SHIP_TYPES.keys()
 return "ship_" + str(classes[rng.randi_range(0, classes.size() - 1)])
