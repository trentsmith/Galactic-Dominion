class_name FreeRoamWorld
extends Node3D

const CENTERS = [Vector3.ZERO, Vector3(3600, 200, -1200), Vector3(-3000, -400, -3000), Vector3(1000, 700, -5400), Vector3(-6200, 500, -800), Vector3(6500, -350, -4200), Vector3(-3200, 1100, -8000)]
const NAMES = ["Vesper Reach", "Kharon Belt", "Auralith Drift", "Ember Frontier", "Pelagian Veil", "Bloodforge Expanse", "Dreaming Rift"]
const COLORS = [Color(0.2, 0.8, 1), Color(1, 0.6, 0.3), Color(0.65, 0.45, 1), Color(1, 0.35, 0.3), Color(.15, .95, .7), Color(.95, .12, .24), Color(.65, .25, .95)]
const LANDMARK_NAMES = ["Vesper Listening Spire", "Kharon Broken Refinery", "Auralith Stargate", "Ember Warship Graveyard", "Pelagian Coral Moon", "Bloodforge Siege Foundry", "Ny’Zaroth Echo Monolith"]
const DESCRIPTIONS = ["Verdant survey lanes", "Dense mining asteroid belt", "Ancient alien ruins", "Wrecks on the war frontier", "Turquoise ocean moons", "Crimson volcanic industry", "Violet rifts and impossible ruins"]
const FACTIONS = [2, 2, 3, 4, 3, 2, 4]
var landmarks: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var obstacle_count := 0
var stations: Array[Node3D] = []

func _ready() -> void:
 var backdrop := SpaceArena.new()
 backdrop.star_radius = 20000
 backdrop.open_space = true
 add_child(backdrop)
 var rng := RandomNumberGenerator.new()
 rng.seed = 54012
 for index in range(CENTERS.size()):
  var station := Node3D.new()
  station.name = "Station%d" % index
  station.position = CENTERS[index]
  add_child(station)
  stations.append(station)
  var model := Node3D.new()
  model.name = "StationAssembly"
  model.scale = Vector3.ONE*23
  model.rotation = Vector3(.18,.55,.15)
  station.add_child(model)
  SpaceModelFactory.station(model,COLORS[index])
  var label := Label3D.new()
  label.text = NAMES[index] + " / SERVICE STATION"
  label.position = Vector3(0, 95, 0)
  label.font_size = 48
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.no_depth_test = true
  station.add_child(label)
  var tint: Color = [Color(.12,.30,.24),Color(.42,.28,.15),Color(.23,.24,.39),Color(.42,.12,.09),Color(.08,.30,.30),Color(.34,.10,.11),Color(.28,.18,.40)][index]
  SpaceEnvironmentArt.planet(self,CENTERS[index]+Vector3(-1000,-600,-1400),330,tint,float(index)*7.0,index==0 or index==2)
  _solid_sphere(CENTERS[index] + Vector3(-1000, -600, -1400), 330)
  for asteroid in range(18):
   var offset := Vector3(rng.randf_range(-1200, 1200), rng.randf_range(-400, 400), rng.randf_range(-1200, 1200))
   if offset.length() < 300:
    offset.z -= 400
   backdrop._asteroid(CENTERS[index] + offset, rng.randf_range(8, 28), rng)
   obstacle_count += 1
  _frontier(index, rng)
 RiftAnomalyArt.build(self,CENTERS[6]+Vector3(0,260,-1250))

func _frontier(region: int, rng: RandomNumberGenerator) -> void:
 var center: Vector3 = CENTERS[region]
 var at := center + Vector3(-550, 80, -650)
 landmarks.append({"name": LANDMARK_NAMES[region], "position": at, "region": region})
 var landmark := Node3D.new()
 landmark.position = at
 add_child(landmark)
 var hub := Node3D.new()
 hub.scale = Vector3.ONE * (14 if region % 2 == 0 else 9)
 landmark.add_child(hub)
 SpaceModelFactory.station(hub, COLORS[region])
 if region >= 4:
  var relic := Node3D.new()
  relic.position.y = 30
  relic.scale = Vector3.ONE * 12
  landmark.add_child(relic)
  if region == 4:
   for i in range(3): SurfaceArt.plant(relic, "alien", Vector3((i-1)*2,0,0), COLORS[region], Color(.3,1,.8), i)
  elif region == 5:
   for i in range(3):
    SurfaceArt.post(relic, Vector3((i-1)*2, 2, 0), .7, 4+i, Color(.2,.08,.12))
    SurfaceArt.ball(relic, Vector3((i-1)*2, 4, 0), Vector3(.4,.4,.4), COLORS[region], true)
  else:
   for i in range(3): SpaceModelFactory.moon_crystal(relic, Vector3((i-1)*2, i, 0), 2+i*.5)
 var label := Label3D.new()
 label.text = LANDMARK_NAMES[region] + " / G TO SURVEY WITHIN 100m"
 label.position.y = 65
 label.font_size = 32
 label.pixel_size = .12
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 landmark.add_child(label)
 # Collidable wrecks flank survey lanes, leaving the landmark and station clear.
 for slot in range(12):
  var offset := Vector3(rng.randf_range(-220, 220), rng.randf_range(-100, 100), rng.randf_range(-220, 220))
  if offset.length() < 100: offset.x += 180
  var body := StaticBody3D.new()
  body.collision_layer = 2
  body.collision_mask = 1
  body.position = at + offset
  body.rotation = Vector3(rng.randf(), rng.randf(), rng.randf()) * PI
  var size := Vector3(rng.randf_range(12, 35), 8, rng.randf_range(18, 50))
  SceneryArt.wreck(body, size)
  var shape := BoxShape3D.new()
  shape.size = size
  var collision := CollisionShape3D.new()
  collision.shape = shape
  body.add_child(collision)
  add_child(body)
  obstacle_count += 1
 var cloud_at := center + Vector3(420, 80, -720)
 hazards.append({"position": cloud_at, "radius": 110.0})
 var cloud := CartoonStyle.ball(self, cloud_at, Vector3.ONE * 110, COLORS[region], true)
 var material := ShaderMaterial.new()
 material.shader = preload("res://resources/shaders/ion_cloud.gdshader")
 material.set_shader_parameter("tint", COLORS[region])
 cloud.material_override = material
 cloud.scale *= Vector3(1.8,.65,1.2)
 var warning := Label3D.new()
 warning.text = "ION STORM / SHIELD & HULL DAMAGE"
 warning.position = cloud_at + Vector3(0, 130, 0)
 warning.font_size = 32
 warning.pixel_size = .13
 warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 add_child(warning)

func hazard_at(at: Vector3) -> bool:
 for hazard in hazards:
  if at.distance_to(hazard.position) < hazard.radius: return true
 return false

func _visual(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> void:
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = at
 var material := CartoonStyle.material(color)
 material.albedo_color = color
 material.emission_enabled = true
 material.emission = color * 0.25
 instance.material_override = material
 parent.add_child(instance)

static func nearest_region(at: Vector3) -> int:
 var result := 0
 var distance := INF
 for index in range(CENTERS.size()):
  var candidate: float = at.distance_squared_to(CENTERS[index])
  if candidate < distance:
   result = index
   distance = candidate
 return result

func _solid_sphere(at: Vector3, radius: float) -> void:
 var body := StaticBody3D.new()
 body.collision_layer = 2
 body.collision_mask = 1
 body.position = at
 var shape := SphereShape3D.new()
 shape.radius = radius
 var collision := CollisionShape3D.new()
 collision.shape = shape
 body.add_child(collision)
 add_child(body)
