class_name WorldWar
extends RefCounted
## Advances only from the authority's free-roam tick; stable ship slots replicate normally.
var battle: FreeRoamMatch
var wave := 0
var countdown := 25.0
var dispatches := 0
var target := -1
var faction := 2
var message := "Border fleets are mobilizing."
var history: Array[String] = []
const FACTION_NAMES = {0:"Independent Fleet", 1:"Rival Pilots", 2:"Crimson Dominion", 3:"Pelagian Concord", 4:"Eldritch Host"}

func tick(delta: float) -> void:
 if battle.network_role == "client" or battle.finished: return
 countdown -= delta
 if countdown <= 0:
  countdown = 60.0
  dispatch()

func dispatch() -> void:
 if battle.network_role == "client": return
 faction = [2, 3, 4][wave % 3]
 target = -1
 for offset in range(3):
  var candidate := (wave + 1 + offset) % 3
  if battle.army.worlds[candidate].owner != faction:
   target = candidate
   break
 if target < 0:
  message = str(FACTION_NAMES[faction]) + " holds every world. Rivals are regrouping."
  wave += 1
  return
 var candidates: Array[CombatShip] = []
 for encounter in battle.encounters:
  for ship in encounter.ships:
   if ship.alive and ship.team == faction: candidates.append(ship)
 if candidates.is_empty():
  message = str(FACTION_NAMES[faction]) + " raid delayed / fleet rebuilding."
  wave += 1
  return
 var destination: Vector3 = battle.army.worlds[target].position
 for slot in range(mini(3, candidates.size())):
  var ship := candidates[slot]
  # NPC-only hyperspace arrival. Player slots and their ownership are untouched.
  ship.position = destination + Vector3(550 + slot * 45, slot * 35, 180)
  ship.velocity = Vector3.ZERO
  ship.brain.roam_center = destination
  ship.brain.command = "attack"
  ship.targeting.select(null)
 var ai_count := 0
 for unit in battle.army.units.values():
  if unit.owner < 0: ai_count += 1
 var count := mini(3, mini(24 - ai_count, CreatureArmy.CAP - battle.army.units.size()))
 for slot in range(maxi(0, count)):
  var id := battle.army.spawn(CreatureArmy.SPECIES[(faction - 2) * 3 + slot], faction, -100 - wave, destination + Vector3(-300, slot * 15, 0), target)
  if id >= 0: battle.army.units[id].order = "assault"
 dispatches += 1
 message = "%s raids %s / %d ships, %d landing troops" % [FACTION_NAMES[faction], battle.army.worlds[target].name, mini(3, candidates.size()), maxi(0, count)]
 history.push_front(message)
 if history.size() > 4: history.pop_back()
 wave += 1

func briefing() -> String:
 return "WORLD WAR / NEXT RAID %ds\n%s\n%s" % [maxi(0, ceili(countdown)), message, "\n".join(history.slice(1))]

func snapshot() -> Dictionary:
 return {"wave": wave, "countdown": countdown, "dispatches": dispatches, "target": target, "faction": faction, "message": message, "history": history.duplicate()}

func apply_snapshot(data: Dictionary) -> void:
 if battle.network_role != "client": return
 wave = int(data.get("wave", 0))
 countdown = float(data.get("countdown", 0))
 dispatches = int(data.get("dispatches", 0))
 target = int(data.get("target", -1))
 faction = int(data.get("faction", 2))
 message = str(data.get("message", ""))
 history.clear()
 for entry in data.get("history", []): history.append(str(entry))
