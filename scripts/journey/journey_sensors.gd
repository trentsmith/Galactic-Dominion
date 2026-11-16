class_name JourneySensors
extends RefCounted
static func range_for(profile: PlayerProfile,ship: CombatShip=null) -> float:
 var scout:=is_instance_valid(ship) and ship.stats.companion_role=="scout" and is_instance_valid(ship.companion)
 return 1000.0+float(profile.frontier.facilities.observatory)*750.0+(1000.0 if scout else 0.0)+(500.0 if profile.ship_story.ending=="preserve" else 0.0)
