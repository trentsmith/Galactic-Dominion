class_name CreatureArmy
extends Node3D
## Host owns spawning, damage, orders and capture. Clients display snapshots only.
const CAP := 50
const PILOT_CAP := 10
const CAPTURE_SECONDS := 30.0
const SPECIES := ["bloodstag", "duskbat", "nightfang", "sporehopper", "prismgrazer", "thornmanta", "riftwisp", "manyeye", "veilcrawler"]
const REGIONS := [0, 2, 3]
const RADIUS := 330.0
var battle: FreeRoamMatch
var units: Dictionary = {}
var worlds: Array[Dictionary] = []
var visuals: Dictionary = {}
var labels: Array[Label3D] = []
var cooldowns: Dictionary = {}
var sequence := 0
var network_clock := 0.0
signal changed

func _ready() -> void:
 for index in range(3):
  var center: Vector3 = FreeRoamWorld.CENTERS[REGIONS[index]] + Vector3(0, 0, -1100)
  worlds.append({"name": PlanetCatalog.WORLDS[index].display_name, "position": center, "owner": index + 2, "challenger": -1, "progress": 0.0, "captures": 0})
  SpaceEnvironmentArt.planet(self, center + Vector3(0, -170, 0), 110, PlanetCatalog.WORLDS[index].glow_color, 41.0 + index, index == 2)
  battle.world._solid_sphere(center + Vector3(0, -170, 0), 110)
  var label := Label3D.new()
  label.position = center + Vector3(0, 100, 0)
  label.font_size = 38
  label.pixel_size = 0.12
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  add_child(label)
  labels.append(label)
  if battle.network_role != "client":
   for slot in range(6):
    spawn(SPECIES[index * 3 + slot % 3], index + 2, -index - 1, center + Vector3(cos(slot * TAU / 6) * 110, 0, sin(slot * TAU / 6) * 110), index)
 _update_labels()

func spawn(species: String, team: int, owner: int, at: Vector3, world: int = -1) -> int:
 if battle.network_role == "client" or units.size() >= CAP or species not in SPECIES:
  return -1
 sequence += 1
 units[sequence] = {"id": sequence, "species": species, "team": team, "owner": owner, "position": at, "hp": 65.0 if species in ["bloodstag", "prismgrazer", "manyeye"] else 45.0, "cooldown": 0.0, "order": "defend" if world >= 0 else "follow", "world": world, "leader": -1, "flash": 0.0, "target": at}
 return sequence

func owned_count(owner: int) -> int:
 var count := 0
 for unit in units.values():
  if unit.owner == owner: count += 1
 return count

func deploy(owner: int, ship: CombatShip, species_index: int) -> String:
 if battle.network_role == "client" or species_index < 0 or species_index >= SPECIES.size(): return "Invalid troop request."
 if not is_instance_valid(ship) or not ship.alive: return "A living command ship is required."
 if float(cooldowns.get(owner, 0)) > 0: return "Reinforcements cooling down."
 var available := mini(5, mini(PILOT_CAP - owned_count(owner), CAP - units.size()))
 if available <= 0: return "Army limit reached / 10 per pilot / 50 total including garrisons."
 for slot in range(available):
  var id := spawn(SPECIES[species_index], ship.team, owner, ship.position + Vector3(slot * 12 - 24, 20, 30))
  units[id].leader = battle.ships.find(ship)
 cooldowns[owner] = 20.0
 changed.emit()
 return "Deployed %d expedition troops / %d of 50 active." % [available, units.size()]

func command(owner: int, ship: CombatShip, order: String) -> bool:
 if battle.network_role == "client" or order not in ["follow", "assault", "recall"] or not is_instance_valid(ship) or not ship.alive: return false
 var world := nearest_world(ship.position)
 if order == "assault" and ship.position.distance_to(worlds[world].position) > 1600: return false
 for id in units.keys():
  if units[id].owner != owner: continue
  if order == "recall":
   units.erase(id)
  else:
   units[id].order = order
   units[id].world = world if order == "assault" else -1
   units[id].leader = battle.ships.find(ship)
 changed.emit()
 return true

func remove_owner(owner: int) -> void:
 for id in units.keys():
  if units[id].owner == owner: units.erase(id)
 cooldowns.erase(owner)

func nearest_world(at: Vector3) -> int:
 var result := 0
 for index in range(1, worlds.size()):
  if at.distance_squared_to(worlds[index].position) < at.distance_squared_to(worlds[result].position): result = index
 return result

func _physics_process(delta: float) -> void:
 if battle.finished or (battle.network_role != "client" and not battle.is_physics_processing()): return
 if battle.network_role != "client": tick(delta)
 _sync_visuals(delta)
 _update_labels()

func tick(delta: float) -> void:
 for owner in cooldowns.keys(): cooldowns[owner] = maxf(0, cooldowns[owner] - delta)
 # Stage damage until all units have decided, so iteration order gives no extra turn.
 var damage: Dictionary = {}
 for id in units.keys():
  var unit: Dictionary = units[id]
  if unit.hp <= 0: continue
  unit.cooldown = maxf(0, unit.cooldown - delta)
  unit.flash = maxf(0, unit.flash - delta)
  var destination: Vector3 = unit.position
  if unit.world >= 0: destination = worlds[unit.world].position
  elif unit.leader >= 0 and unit.leader < battle.ships.size():
   var leader := battle.ships[int(unit.leader)]
   if leader.alive: destination = leader.position + Vector3(cos(id) * 45, 25, sin(id) * 45)
  var target_id := -1
  var nearest := 250.0 * 250.0
  for other_id in units:
   var other: Dictionary = units[other_id]
   if other.team == unit.team or other.hp <= 0: continue
   var distance: float = unit.position.distance_squared_to(other.position)
   if distance < nearest:
    nearest = distance
    target_id = other_id
  var victim: CombatShip = null
  # Follow troops defend their ship; assault troops prioritize the world garrison.
  if target_id < 0:
   for candidate in battle.ships:
    if not candidate.alive or candidate.team == unit.team: continue
    var distance: float = unit.position.distance_squared_to(candidate.position)
    if distance < nearest:
     nearest = distance
     victim = candidate
  if target_id >= 0: destination = units[target_id].position
  elif is_instance_valid(victim): destination = victim.position
  var speed := 100.0 if unit.species in ["duskbat", "thornmanta", "riftwisp"] else 75.0
  if unit.position.distance_to(destination) > 65:
   unit.position = unit.position.move_toward(destination, speed * delta)
  if (target_id >= 0 or is_instance_valid(victim)) and unit.position.distance_to(destination) < 90 and unit.cooldown <= 0:
   unit.cooldown = 0.9
   unit.flash = 0.18
   unit.target = destination
   var power := 10.0 if unit.species in ["nightfang", "thornmanta", "veilcrawler"] else 7.0
   if target_id >= 0: damage[target_id] = float(damage.get(target_id, 0)) + power
   elif victim.get_meta("spawn_protection", 0.0) <= 0:
    # Army kills do not mint ship encounter rewards or trust client damage reports.
    victim.health.damage(power * 0.4, null)
  # Ships can retaliate automatically at nearby hostile creatures.
  for ship in battle.ships:
   if ship.alive and ship.team != unit.team and unit.position.distance_to(ship.position) < 190:
    damage[id] = float(damage.get(id, 0)) + delta * 9.0
 for id in damage:
  if units.has(id): units[id].hp -= damage[id]
 for id in units.keys():
  if units[id].hp <= 0: units.erase(id)
 _capture(delta)

func _capture(delta: float) -> void:
 for world in worlds:
  var present: Dictionary = {}
  for unit in units.values():
   if unit.position.distance_to(world.position) < RADIUS: present[unit.team] = true
  if present.size() != 1:
   # Contested progress freezes; abandoned progress decays.
   if present.is_empty(): world.progress = maxf(0, world.progress - delta)
   continue
  var team: int = present.keys()[0]
  if team == world.owner:
   world.progress = maxf(0, world.progress - delta * 2)
   continue
  if world.challenger != team:
   world.challenger = team
   world.progress = 0.0
  world.progress += delta
  if world.progress >= CAPTURE_SECONDS:
   world.owner = team
   world.progress = 0.0
   world.challenger = -1
   world.captures += 1
   changed.emit()

func snapshot() -> Dictionary:
 return {"units": units.values().duplicate(true), "worlds": worlds.duplicate(true), "war": battle.war.snapshot() if battle.war != null else {}}

func apply_snapshot(data: Dictionary) -> void:
 if battle.network_role != "client": return
 if battle.war != null: battle.war.apply_snapshot(data.get("war", {}))
 units.clear()
 for unit in data.get("units", []):
  if units.size() >= CAP: break
  units[int(unit.id)] = unit.duplicate(true)
 var incoming: Array = data.get("worlds", [])
 if incoming.size() == 3:
  for index in range(3): worlds[index] = incoming[index].duplicate(true)

func _sync_visuals(delta: float) -> void:
 for id in visuals.keys():
  if not units.has(id):
   visuals[id].queue_free()
   visuals.erase(id)
 for id in units:
  var unit: Dictionary = units[id]
  if not visuals.has(id):
   var definition: Resource
   for planet in PlanetCatalog.WORLDS:
    for fauna in planet.fauna:
     if fauna.id == unit.species: definition = fauna
   var actor := SurfaceArt.creature(self, definition)
   actor.scale = Vector3.ONE * 8
   actor.position = unit.position
   var badge := Label3D.new()
   badge.name = "Badge"
   badge.position.y = 2.8
   badge.font_size = 20
   badge.pixel_size = 0.018
   badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   actor.add_child(badge)
   visuals[id] = actor
  var actor: Node3D = visuals[id]
  actor.position = actor.position.lerp(unit.position, minf(1, delta * 15))
  actor.get_node("Badge").text = str(maxi(0, int(unit.hp)))
  actor.get_node("Badge").modulate = Color(.3, .85, 1) if unit.team == 0 else Color(1, .45, .5)
  if unit.flash > 0:
   # Brief visible energy streak, no client-side damage.
   var line := ImmediateMesh.new()
   line.surface_begin(Mesh.PRIMITIVE_LINES)
   line.surface_add_vertex(Vector3.ZERO)
   line.surface_add_vertex((unit.target - unit.position) / 8)
   line.surface_end()
   var beam := actor.get_node_or_null("Beam") as MeshInstance3D
   if beam == null:
    beam = MeshInstance3D.new()
    beam.name = "Beam"
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(1, .75, .3)
    beam.material_override = material
    actor.add_child(beam)
   beam.mesh = line
  var beam := actor.get_node_or_null("Beam")
  if beam != null: beam.visible = unit.flash > 0

func _update_labels() -> void:
 for index in range(labels.size()):
  var world: Dictionary = worlds[index]
  labels[index].text = "%s / %s\n%s / %d%%" % [world.name, WorldWar.FACTION_NAMES.get(world.owner, "Unknown Fleet"), "CONTESTED" if _contested(index) else "CAPTURE", int(world.progress / CAPTURE_SECONDS * 100)]

func _contested(index: int) -> bool:
 var teams := {}
 for unit in units.values():
  if unit.position.distance_to(worlds[index].position) < RADIUS: teams[unit.team] = true
 return teams.size() > 1
