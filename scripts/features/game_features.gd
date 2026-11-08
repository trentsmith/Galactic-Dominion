class_name GameFeatures
extends RefCounted
## Legacy bundled mode remains available; surface wildlife is independent.
static func creatures_enabled() -> bool:
 return OS.get_environment("GD_ENABLE_CREATURES")=="1" or bool(ProjectSettings.get_setting("gameplay/creatures_enabled",false))
static func wildlife_enabled() -> bool:
 if creatures_enabled():return true
 if OS.has_environment("GD_ENABLE_WILDLIFE"):return OS.get_environment("GD_ENABLE_WILDLIFE")=="1"
 return bool(ProjectSettings.get_setting("gameplay/wildlife_enabled",true))
static func companions_enabled() -> bool:
 if OS.has_environment("GD_ENABLE_COMPANIONS"):return OS.get_environment("GD_ENABLE_COMPANIONS")=="1"
 return bool(ProjectSettings.get_setting("gameplay/companions_enabled",true))
static func collectible_active(item: CollectibleDefinition) -> bool:
 if creatures_enabled():return true
 if item.id in ["crew_pixlet","crew_cinderbit","crew_lunaflutter","crew_orbitot","crew_glimbloom"]:return companions_enabled()
 return not item.id in ["variant_cinderbit","variant_lunaflutter","variant_orbitot","variant_glimbloom"]
