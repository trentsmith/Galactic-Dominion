class_name GameFeatures
extends RefCounted
## Reversible release switch. Keep legacy code and profile data intact.
static func creatures_enabled() -> bool:
 return OS.get_environment("GD_ENABLE_CREATURES")=="1" or bool(ProjectSettings.get_setting("gameplay/creatures_enabled",false))
static func companions_enabled() -> bool:
 if OS.has_environment("GD_ENABLE_COMPANIONS"):return OS.get_environment("GD_ENABLE_COMPANIONS")=="1"
 return bool(ProjectSettings.get_setting("gameplay/companions_enabled",true))
static func collectible_active(item: CollectibleDefinition) -> bool:
 if creatures_enabled():return true
 if item.id in ["crew_pixlet","crew_cinderbit","crew_lunaflutter","crew_orbitot","crew_glimbloom"]:return companions_enabled()
 return not item.id in ["variant_cinderbit","variant_lunaflutter","variant_orbitot","variant_glimbloom"]
