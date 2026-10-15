class_name PlanetCatalog
extends RefCounted
const WORLDS = [preload("res://resources/planets/varkhoss.tres"),preload("res://resources/planets/viridia.tres"),preload("res://resources/planets/nyzaroth.tres")]
static func available_bots(profile: PlayerProfile) -> Array[CollectibleDefinition]:
 var result: Array[CollectibleDefinition] = []
 for item in CollectionCatalog.DEFINITIONS:
  if item.kind == "crew" and item.species != "Human" and profile.owns(item.id):result.append(item)
 return result
