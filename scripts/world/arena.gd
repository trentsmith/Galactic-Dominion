class_name SpaceArena
extends Node3D
var star_radius := 1700.0
var arena_seed := 81023
var planet_tint := Color(0.12, 0.25, 0.48)

func _ready() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = arena_seed
 var environment_node := WorldEnvironment.new()
 var environment := Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color(0.045, 0.028, 0.1)
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color(0.4, 0.5, 0.8)
 environment.ambient_light_energy = 0.38
 environment_node.environment = environment
 add_child(environment_node)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-35, -30, 0)
 sun.light_color = Color(0.65, 0.8, 1)
 sun.light_energy = 0.9
 add_child(sun)
 # One MultiMesh draw call for the deterministic star field.
 var stars := MultiMeshInstance3D.new()
 var multimesh := MultiMesh.new()
 multimesh.transform_format = MultiMesh.TRANSFORM_3D
 var star_mesh := SphereMesh.new()
 star_mesh.radius = 1.5
 star_mesh.height = 3.0
 star_mesh.radial_segments = 4
 star_mesh.rings = 2
 multimesh.mesh = star_mesh
 multimesh.instance_count = 1200
 for index in range(1200):
  var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
  multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, direction * rng.randf_range(star_radius, star_radius + 600)))
 stars.multimesh = multimesh
 var star_material := StandardMaterial3D.new()
 star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 star_material.albedo_color = Color(1, 0.91, 0.72)
 stars.material_override = star_material
 add_child(stars)
 var planet := MeshInstance3D.new()
 var planet_mesh := SphereMesh.new()
 planet_mesh.radius = 320
 planet_mesh.height = 640
 planet.mesh = planet_mesh
 planet.position = Vector3(-1100, -450, -1600)
 var planet_material := StandardMaterial3D.new()
 planet_material.albedo_color = planet_tint
 planet_material.roughness = 0.9
 planet.material_override = planet_material
 add_child(planet)
 var ring := MeshInstance3D.new()
 var ring_mesh := TorusMesh.new()
 ring_mesh.inner_radius = 420
 ring_mesh.outer_radius = 465
 ring.mesh = ring_mesh
 ring.material_override = CartoonStyle.material(planet_tint.lightened(0.45))
 planet.add_child(ring)
 ring.rotation_degrees.z = 18
 for index in range(34):
  var position := Vector3(rng.randf_range(-420, 420), rng.randf_range(-160, 160), rng.randf_range(-320, 320))
  if absf(position.x) < 55 and absf(position.y) < 45:
   position.y += 90
  _asteroid(position, rng.randf_range(6, 22), rng)
 for index in range(22):
  var debris := MeshInstance3D.new()
  var box := BoxMesh.new()
  box.size = Vector3(rng.randf_range(1, 5), 0.7, rng.randf_range(2, 8))
  debris.mesh = box
  debris.position = Vector3(rng.randf_range(-360, 360), rng.randf_range(-140, 140), rng.randf_range(-300, 300))
  debris.rotation = Vector3(rng.randf() * PI, rng.randf() * PI, rng.randf() * PI)
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(0.23, 0.3, 0.38)
  mat.metallic = 0.8
  debris.material_override = mat
  add_child(debris)

func _asteroid(position: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
 var body := StaticBody3D.new()
 body.collision_layer = 2
 body.collision_mask = 1
 body.position = position
 var visual := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = radius
 sphere.height = radius * 2.0
 sphere.radial_segments = 9
 sphere.rings = 5
 visual.mesh = sphere
 visual.scale = Vector3(1, rng.randf_range(0.65, 1.2), 1)
 var material := CartoonStyle.material(Color(0.48, 0.41, 0.63))
 material.roughness = 1.0
 visual.material_override = material
 body.add_child(visual)
 var collision := CollisionShape3D.new()
 var shape := SphereShape3D.new()
 shape.radius = radius
 collision.shape = shape
 body.add_child(collision)
 add_child(body)
