class_name CollectibleDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("component", "crew", "variant", "ship") var kind: String = "component"
@export_enum("common", "uncommon", "rare", "legendary", "mythic") var rarity: String = "common"
@export var slot: String = ""
@export var species: String = ""
@export var ship_class: String = ""
@export var modifiers: Dictionary = {}
@export var color: Color = Color(0.25, 0.8, 1)
@export var accent: Color = Color(0.8, 0.95, 1)
@export var visual_style: String = "standard"
@export var starter: bool = false
@export var research_cost: int = 0

func rarity_color() -> Color:
 match rarity:
  "uncommon": return Color(0.4, 0.85, 0.6)
  "rare": return Color(0.5, 0.65, 1)
  "legendary": return Color(0.85, 0.5, 1)
  "mythic": return Color(1, 0.75, 0.25)
  _: return Color(0.65, 0.75, 0.85)

func modifier_text() -> String:
 if modifiers.is_empty():
  return "Standard specification" if kind == "component" else "Appearance only" if kind == "variant" else "No combat bonus"
 var parts: PackedStringArray = []
 for stat in modifiers:
  var percent := (float(modifiers[stat]) - 1.0) * 100.0
  parts.append("%s %+.0f%%" % [str(stat).replace("_", " ").capitalize(), percent])
 return " · ".join(parts)
