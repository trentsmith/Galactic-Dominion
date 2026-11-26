class_name FleetManifest
extends RefCounted
## Read only projection of the account service's locked deployment snapshot.
## Local PlayerProfile saves never become online ownership evidence.

static func configured_stats(data: Dictionary, slot: int) -> ShipStats:
 var profile := PlayerProfile.new()
 profile.inventory = data.inventory
 profile.ship_classes.assign(data.ship_classes)
 profile.loadouts.assign(data.loadouts)
 return profile.configured_stats(slot)

static func vessel_name(data: Dictionary, slot: int) -> String:
 var active: Array = data.get("active_ships", [])
 if slot < active.size():
  for ship in data.get("fleet_roster", []):
   if ship.id == active[slot]: return str(ship.name)
 return str(data.ship_classes[slot]).capitalize()

static func crew_name(data: Dictionary, slot: int) -> String:
 var crew := CollectionCatalog.find(str(data.loadouts[slot].crew))
 return crew.display_name if crew != null else "AI flight computer"

static func summary(data: Dictionary) -> String:
 var lines: PackedStringArray = []
 for slot in range(mini(3, data.get("ship_classes", []).size())):
  lines.append("F%d  %s · %s" % [slot + 1, vessel_name(data, slot), str(data.ship_classes[slot]).capitalize()])
 return "\n".join(lines)

static func battle_vessels(data: Dictionary) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for sid in data.get("battle_fleet", data.get("active_ships", [])):
  for ship in data.get("fleet_roster", []):
   if ship.id == sid:
    result.append(ship)
    break
 return result

static func vessel_stats(data: Dictionary, vessel: Dictionary) -> ShipStats:
 var profile := PlayerProfile.new()
 profile.inventory = data.inventory
 profile.ship_classes[0] = str(vessel.hull)
 profile.loadouts[0] = vessel.loadout
 return profile.configured_stats(0)
