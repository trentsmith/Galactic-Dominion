class_name ArmadaArt
extends RefCounted
## Detailed class silhouettes baked into one shared mesh per class.
static var hulls: Dictionary={}
static var paints: Dictionary={}
static var engine_shape: BoxMesh
static var flash_shape: SphereMesh
static var shield_shape: SphereMesh
static func build(ship: CombatShip) -> void:
 var key:=ship.stats.class_name_text
 if not hulls.has(key):
  var source:=Node3D.new()
  var stats: ShipStats=ship.stats.duplicate(true);stats.variant_style="standard";stats.crew_id=""
  SpaceModelFactory.ship(source,stats,0)
  var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  merge(source,Transform3D.IDENTITY,surface)
  surface.index();hulls[key]=surface.commit();source.free()
 if not paints.has(ship.team):
  var paint:=StandardMaterial3D.new();paint.vertex_color_use_as_albedo=true;paint.albedo_color=Color(.85,.95,1) if ship.team==0 else Color(1,.68,.6);paint.roughness=.48;paint.metallic=.55;paint.cull_mode=BaseMaterial3D.CULL_DISABLED
  paints[ship.team]=paint
 var body:=MeshInstance3D.new();body.name="ArmadaHull";body.mesh=hulls[key];body.material_override=paints[ship.team];body.visibility_range_end=3000;ship.add_child(body)
 if engine_shape==null:
  engine_shape=BoxMesh.new();engine_shape.size=Vector3(3.7,.28,.35)
  flash_shape=SphereMesh.new();flash_shape.radius=.4;flash_shape.height=.8;flash_shape.radial_segments=6;flash_shape.rings=3
  shield_shape=SphereMesh.new();shield_shape.radius=3;shield_shape.height=6;shield_shape.radial_segments=8;shield_shape.rings=4
 SpaceModelFactory.mesh(ship,engine_shape,Vector3(0,-.1,2.2),Color(.2,.85,1) if ship.team==0 else Color(1,.35,.15),"MainEngine",true)
 SpaceModelFactory.mesh(ship,flash_shape,Vector3(0,0,-3.3),Color(1,.8,.2),"MuzzleFlash",true).visible=false
 SpaceModelFactory.mesh(ship,shield_shape,Vector3.ZERO,Color(.2,.7,1,.15),"ShieldShell",true).visible=false
static func merge(node: Node3D,parent_transform: Transform3D,surface: SurfaceTool) -> void:
 if node.name in ["MainEngine","MuzzleFlash","ShieldShell","EngineBloom"]:return
 var transform:=parent_transform*node.transform
 if node is MeshInstance3D and node.mesh!=null:
  var tint:=Color.WHITE
  if node.material_override is StandardMaterial3D:tint=node.material_override.albedo_color
  for index in range(node.mesh.get_surface_count()):
   var arrays: Array=node.mesh.surface_get_arrays(index)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL]!=null else PackedVector3Array()
   var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
   var count:=indices.size() if not indices.is_empty() else vertices.size()
   var normal_transform:=transform.basis.inverse().transposed()
   for i in range(count):
    var vertex:=indices[i] if not indices.is_empty() else i
    surface.set_color(tint)
    surface.set_normal((normal_transform*normals[vertex]).normalized() if normals.size()>vertex else Vector3.UP)
    surface.add_vertex(transform*vertices[vertex])
 for child in node.get_children():
  if child is Node3D:merge(child,transform,surface)
