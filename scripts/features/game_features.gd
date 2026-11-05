class_name GameFeatures
extends RefCounted
## Reversible release switch. Keep legacy code and profile data intact.
static func creatures_enabled() -> bool:
 return OS.get_environment("GD_ENABLE_CREATURES")=="1" or bool(ProjectSettings.get_setting("gameplay/creatures_enabled",false))
static func collectible_active(item: CollectibleDefinition) -> bool:
 if creatures_enabled():return true
 return not item.id in ["crew_pixlet","crew_cinderbit","crew_lunaflutter","crew_orbitot","crew_glimbloom","variant_cinderbit","variant_lunaflutter","variant_orbitot","variant_glimbloom"]
