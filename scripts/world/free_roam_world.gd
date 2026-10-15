class_name FreeRoamWorld
extends Node3D

const CENTERS = [Vector3.ZERO, Vector3(3600, 200, -1200), Vector3(-3000, -400, -3000), Vector3(1000, 700, -5400)]
const NAMES = ["Vesper Reach", "Kharon Belt", "Auralith Drift", "Ember Frontier"]
const COLORS = [Color(0.2, 0.8, 1), Color(1, 0.6, 0.3), Color(0.65, 0.45, 1), Color(1, 0.35, 0.3)]
var stations: Array[Node3D] = []

func _ready() -> void:
 var backdrop := SpaceArena.new()
 backdrop.star_radius = 20000
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
  station.add_child(model)
  SpaceModelFactory.station(model,COLORS[index])
  var label := Label3D.new()
  label.text = NAMES[index] + " / SERVICE STATION"
  label.position = Vector3(0, 95, 0)
  label.font_size = 48
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.no_depth_test = true
  station.add_child(label)
  if index > 0:
   SpaceEnvironmentArt.planet(self,CENTERS[index]+Vector3(-1000,-600,-1400),330,COLORS[index],float(index)*7.0,index==2)
  for asteroid in range(18):
   var offset := Vector3(rng.randf_range(-1200, 1200), rng.randf_range(-400, 400), rng.randf_range(-1200, 1200))
   if offset.length() < 300:
    offset.z -= 400
   backdrop._asteroid(CENTERS[index] + offset, rng.randf_range(8, 28), rng)

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
