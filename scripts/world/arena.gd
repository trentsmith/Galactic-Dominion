class_name SpaceArena
extends Node3D
var battle_scale := 1.0
var open_space := false
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
 sun.light_energy = 1.25
 sun.shadow_enabled = true
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
 multimesh.use_colors = true
 multimesh.instance_count = 1200
 for index in range(1200):
  var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
  var size := .35+float((index*73)%100)/100.0
  multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size), direction * rng.randf_range(star_radius, star_radius + 600)))
  multimesh.set_instance_color(index,Color(.57,.73,1).lerp(Color(1,.84,.65),float((index*31)%100)/100.0))
 stars.multimesh = multimesh
 var star_material := StandardMaterial3D.new()
 star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 star_material.albedo_color = Color.WHITE
 star_material.vertex_color_use_as_albedo = true
 stars.material_override = star_material
 add_child(stars)
 if open_space: return
 SpaceEnvironmentArt.planet(self,Vector3(-1100,-450,-1600)*maxf(1,battle_scale),430*maxf(1,battle_scale*.5),Color(0.04,0.25,0.75),float(arena_seed),true)
 for index in range(int(34 * battle_scale)):
  var position := Vector3(rng.randf_range(-420, 420), rng.randf_range(-160, 160), rng.randf_range(-320, 320))
  if absf(position.x) < 55 and absf(position.y) < 45:
   position.y += 90
  _asteroid(position * battle_scale, rng.randf_range(6, 22), rng)
 for index in range(int(22 * battle_scale)):
  var debris := Node3D.new()
  debris.position = Vector3(rng.randf_range(-360, 360), rng.randf_range(-140, 140), rng.randf_range(-300, 300))
  debris.position *= battle_scale
  debris.rotation = Vector3(rng.randf() * PI, rng.randf() * PI, rng.randf() * PI)
  add_child(debris)
  SceneryArt.wreck(debris,Vector3(rng.randf_range(2,5),1,rng.randf_range(4,9)))

func _asteroid(position: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
 var body := StaticBody3D.new()
 body.collision_layer = 2
 body.collision_mask = 1
 body.position = position
 var visual := MeshInstance3D.new()
 visual.visibility_range_end = 2400
 visual.mesh = SpaceEnvironmentArt.asteroid_mesh(rng.randi())
 visual.scale = Vector3(radius*rng.randf_range(.7,1.2),radius*rng.randf_range(.55,1.1),radius*rng.randf_range(.65,1.25))
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
