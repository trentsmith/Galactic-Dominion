class_name SpaceEnvironmentArt
extends RefCounted
const SKY_SHADER = preload("res://resources/shaders/nebula_sky.gdshader")
const PLANET_SHADER = preload("res://resources/shaders/painted_planet.gdshader")
const ATMOSPHERE = preload("res://resources/shaders/atmosphere.gdshader")
const ROCK_SHADER = preload("res://resources/shaders/painted_rock.gdshader")

static func environment(seed_value: float = 8.1) -> WorldEnvironment:
 var node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 sky.radiance_size = Sky.RADIANCE_SIZE_256
 sky.process_mode = Sky.PROCESS_MODE_QUALITY
 var material := ShaderMaterial.new()
 material.shader = SKY_SHADER
 material.set_shader_parameter("nebula_seed",seed_value)
 sky.sky_material = material
 env.sky = sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(0.40,0.60,1.0)
 env.ambient_light_energy = 0.48
 node.environment = env
 return node

static func planet(parent: Node3D, at: Vector3, radius: float, tint: Color, seed_value: float, with_ring: bool = false) -> Node3D:
 var root := Node3D.new()
 root.name = "PaintedPlanet"
 root.position = at
 parent.add_child(root)
 var sphere := SphereMesh.new()
 sphere.radius = radius
 sphere.height = radius*2
 sphere.radial_segments = 64
 sphere.rings = 32
 var globe := MeshInstance3D.new()
 globe.name = "TerrainGlobe"
 globe.mesh = sphere
 var surface := ShaderMaterial.new()
 surface.shader = PLANET_SHADER
 surface.set_shader_parameter("ocean",Color(0.008,0.045,0.16))
 surface.set_shader_parameter("land",tint.lightened(0.22))
 surface.set_shader_parameter("cloud_color",tint.lightened(0.55))
 surface.set_shader_parameter("terrain_seed",seed_value)
 globe.material_override = surface
 root.add_child(globe)
 var atmosphere := MeshInstance3D.new()
 atmosphere.name = "AtmosphereRim"
 atmosphere.mesh = sphere
 atmosphere.scale = Vector3.ONE*1.035
 var rim := ShaderMaterial.new()
 rim.shader = ATMOSPHERE
 rim.set_shader_parameter("glow_color",tint.lightened(0.3))
 atmosphere.material_override = rim
 root.add_child(atmosphere)
 if with_ring:
  var ring := SpaceModelFactory.ring(root,Vector3.ZERO,radius*1.43,radius*0.035,tint.lightened(0.35),"PlanetaryRing",true)
  ring.rotation = Vector3(0.32,0,0.23)
 return root

static func asteroid_mesh(seed_value: int) -> ArrayMesh:
 var base := SphereMesh.new()
 base.radius = 1
 base.height = 2
 base.radial_segments = 20
 base.rings = 12
 var arrays := base.get_mesh_arrays()
 var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 var noise := FastNoiseLite.new()
 noise.seed = seed_value
 noise.frequency = 2.0
 var rng := RandomNumberGenerator.new()
 rng.seed = seed_value
 var craters: Array[Vector3] = []
 for index in range(5):craters.append(Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)).normalized())
 for index in range(vertices.size()):
  var normal := vertices[index].normalized()
  var radius := 0.90+noise.get_noise_3dv(normal)*0.15
  for crater in craters:
   var distance := normal.distance_to(crater)
   radius -= exp(-distance*distance/0.025)*0.14
   radius += exp(-pow((distance-0.25)/0.055,2))*0.035
  vertices[index] = normal*radius
 arrays[Mesh.ARRAY_VERTEX] = vertices
 var temporary := ArrayMesh.new()
 temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var surface := SurfaceTool.new()
 surface.create_from(temporary,0)
 surface.generate_normals()
 return surface.commit()
