class_name SpaceArena
extends Node3D
var star_radius := 1700.0
var arena_seed := 81023
var planet_tint := Color(0.12, 0.25, 0.48)

func _ready() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = arena_seed
 add_child(SpaceEnvironmentArt.environment(float(arena_seed % 100)/10.0))
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-35, -30, 0)
 sun.light_color = Color(1, 0.91, 0.78)
 sun.light_energy = 1.15
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
 SpaceEnvironmentArt.planet(self,Vector3(-1100,-450,-1600),430,Color(0.04,0.25,0.75),float(arena_seed),true)
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
  var mat := CartoonStyle.material(SpaceModelFactory.PEARL.darkened(0.4))
  debris.material_override = mat
  add_child(debris)

func _asteroid(position: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
 var body := StaticBody3D.new()
 body.collision_layer = 2
 body.collision_mask = 1
 body.position = position
 var visual := MeshInstance3D.new()
 visual.mesh = SpaceEnvironmentArt.asteroid_mesh(rng.randi())
 visual.scale = Vector3(radius,radius*rng.randf_range(0.75,1.15),radius)
 var material := ShaderMaterial.new()
 material.shader = SpaceEnvironmentArt.ROCK_SHADER
 visual.material_override = material
 body.add_child(visual)
 var collision := CollisionShape3D.new()
 var shape := SphereShape3D.new()
 shape.radius = radius
 collision.shape = shape
 body.add_child(collision)
 add_child(body)
