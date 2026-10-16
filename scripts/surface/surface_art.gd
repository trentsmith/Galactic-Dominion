class_name SurfaceArt
extends RefCounted
static func ball(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
 var node:=CartoonStyle.ball(parent,at,dimensions,color,glow)
 if not glow:
  var mat:=node.material_override as StandardMaterial3D
  mat.roughness=.95;mat.metallic=0;mat.metallic_specular=.12
 return node
static func post(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
 var shape := CylinderMesh.new()
 shape.top_radius = radius*0.65;shape.bottom_radius = radius;shape.height = height
 shape.radial_segments = 8
 return SpaceModelFactory.mesh(parent,shape,at,color)
static func plant(parent: Node3D, biome: String, at: Vector3, color: Color, glow: Color, style: int) -> Node3D:
 return FoliageArt.build(parent,biome,at,color,glow,style)
static func creature(parent: Node3D, definition: FaunaDefinition) -> Node3D:
 return FaunaSculpt.build(parent,definition)
