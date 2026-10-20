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
  worlds.append({"name": PlanetCatalog.WORLDS[index].display_name, "position": center, "owner": 0 if battle.peaceful else index + 2, "challenger": -1, "progress": 0.0, "captures": 0})
  SpaceEnvironmentArt.planet(self, center + Vector3(0, -170, 0), 110, PlanetCatalog.WORLDS[index].glow_color, 41.0 + index, index == 2)
  battle.world._solid_sphere(center + Vector3(0, -170, 0), 110)
  var label := Label3D.new()
  label.position = center + Vector3(0, 100, 0)
  label.font_size = 38
  label.pixel_size = 0.12
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  add_child(label)
  labels.append(label)
 _update_labels()

func spawn(_species: String, _team: int, _owner: int, _at: Vector3, _world: int = -1) -> int:
 return -1 # Creature combat belongs to planet expeditions.

func owned_count(owner: int) -> int:
 var count := 0
 for unit in units.values():
  if unit.owner == owner: count += 1
 return count

func deploy(_owner: int, _ship: CombatShip, _species_index: int) -> String:
 return "Creature deployment moved to planets / land and deploy sanctuary creatures."

func command(_owner: int, _ship: CombatShip, _order: String) -> bool:
 return false

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
 units.clear()
 _capture(delta)

func _capture(delta: float) -> void:
 for world in worlds:
  var present: Dictionary = {}
  for ship in battle.ships:
   if ship.alive and ship.position.distance_to(world.position)<RADIUS:present[ship.team]=true
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
 return {"units": [], "worlds": worlds.duplicate(true), "war": battle.war.snapshot() if battle.war != null else {}}

func apply_snapshot(data: Dictionary) -> void:
 if battle.network_role != "client": return
 if battle.war != null: battle.war.apply_snapshot(data.get("war", {}))
 units.clear()
 var incoming: Array = data.get("worlds", [])
 if incoming.size() == 3:
  for index in range(3): worlds[index] = incoming[index].duplicate(true)

func _sync_visuals(delta: float) -> void:
 if battle.network_role == "server": return
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
  actor.visible = actor.global_position.distance_to(battle.camera.global_position) < 1800
  actor.position = actor.position.lerp(unit.position, minf(1, delta * 15))
  actor.get_node("Badge").visible = not battle.scenic_hud
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
 for ship in battle.ships:
  if ship.alive and ship.position.distance_to(worlds[index].position)<RADIUS:teams[ship.team]=true
 return teams.size() > 1
