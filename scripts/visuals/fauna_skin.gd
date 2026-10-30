class_name FaunaSkin
extends RefCounted
## Shared habitat materials and a portable macro-color bake for glTF export.
static var cache: Dictionary={}
static func material(d: FaunaDefinition,head: bool=false) -> ShaderMaterial:
 var key:=d.id+str(d.color)+str(d.glow)+str(head)
 if cache.has(key):return cache[key]
 var mat:=ShaderMaterial.new();mat.shader=preload("res://resources/shaders/fauna_skin.gdshader")
 mat.set_shader_parameter("coat",d.color.lightened(.10).lerp(Color(.48,.44,.4),.08))
 mat.set_shader_parameter("marking",Color(.92,.84,.70).lerp(d.glow,.10))
 mat.set_shader_parameter("face_region",1.0 if head else 0.0)
 mat.set_shader_parameter("pattern",float(posmod(d.id.hash(),2)))
 mat.set_shader_parameter("skin_kind",1 if d.body_style in ["fish","shark"] else 2 if d.body_style in ["watcher","crawler"] else 3 if d.body_style in ["jelly","wisp"] else 0)
 cache[key]=mat;return mat
static func hash3(p: Vector3) -> float:
 return fposmod(sin(p.dot(Vector3(127.1,311.7,74.7)))*43758.5453,1.0)
static func noise3(p: Vector3) -> float:
 var i:=p.floor();var f:=p-i;f=f*f*(Vector3.ONE*3-f*2)
 var low:=lerpf(lerpf(hash3(i),hash3(i+Vector3(1,0,0)),f.x),lerpf(hash3(i+Vector3(0,1,0)),hash3(i+Vector3(1,1,0)),f.x),f.y)
 var high:=lerpf(lerpf(hash3(i+Vector3(0,0,1)),hash3(i+Vector3(1,0,1)),f.x),lerpf(hash3(i+Vector3(0,1,1)),hash3(i+Vector3(1,1,1)),f.x),f.y)
 return lerpf(low,high,f.z)
static func bake_color(p: Vector3,mat: ShaderMaterial) -> Color:
 var coat: Color=mat.get_shader_parameter("coat");var marking: Color=mat.get_shader_parameter("marking")
 var organic:=noise3(p*3)
 var stripes:=pow(.5+.5*sin(p.z*11.+organic*2.4),10.)
 var spots:=smoothstep(.68,.87,noise3(p*5))
 var blend: float=spots if float(mat.get_shader_parameter("pattern"))<.5 else stripes
 var belly:=1.-smoothstep(.55,1.15,p.y)
 var grain:=noise3(p*Vector3(65,110,65))
 var muzzle: float=(1.-smoothstep(-1.45,-.9,p.z))*(1.-smoothstep(1.35,1.62,p.y))*float(mat.get_shader_parameter("face_region"))
 var color:=coat.lerp(marking,clampf(blend*.18+belly*.30+muzzle*.28,0,.55))*(.96+grain*.07)
 color.a=1;return color

# Godot scenes retain the procedural skin. glTF receives a vertex-color bake.
static func bake_model(node: Node) -> void:
 for child in node.get_children():bake_model(child)
 if not node is MeshInstance3D or not node.material_override is ShaderMaterial:return
 var shader: ShaderMaterial=node.material_override
 if shader.shader!=preload("res://resources/shaders/fauna_skin.gdshader"):return
 var mesh:=ArrayMesh.new()
 for surface in range(node.mesh.get_surface_count()):
  var arrays: Array=node.mesh.surface_get_arrays(surface)
  var colors:=PackedColorArray()
  for p in arrays[Mesh.ARRAY_VERTEX]:
   colors.append(FaunaSkin.bake_color(p,shader))
  arrays[Mesh.ARRAY_COLOR]=colors;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=[.82,.48,.64,.35][int(shader.get_shader_parameter("skin_kind"))];material.cull_mode=BaseMaterial3D.CULL_DISABLED
 node.mesh=mesh;node.material_override=material

