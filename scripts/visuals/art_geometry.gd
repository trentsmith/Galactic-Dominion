class_name ArtGeometry
extends RefCounted
## Reusable authored profiles: closed, smooth 3D surfaces rather than scaled primitives.
static var cache: Dictionary = {}

static func loft(profile: Array[Vector4], segments: int = 32) -> ArrayMesh:
 var key := str(profile) + str(segments)
 if cache.has(key): return cache[key]
 var st := SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for ring in range(profile.size()-1):
  for i in range(segments):
   for corner in [Vector2i(ring,i),Vector2i(ring+1,i),Vector2i(ring,i+1),Vector2i(ring,i+1),Vector2i(ring+1,i),Vector2i(ring+1,i+1)]:
    var p := profile[corner.x]
    var a: float = TAU * corner.y / segments
    var normal := Vector3(cos(a)/maxf(.01,p.x),sin(a)/maxf(.01,p.y),0).normalized()
    var other := profile[mini(corner.x+1,profile.size()-1)]
    if other.z != p.z: normal.z = -(other.x-p.x)/(other.z-p.z)*absf(cos(a)) - (other.y-p.y)/(other.z-p.z)*absf(sin(a))
    st.set_normal(normal.normalized())
    st.set_uv(Vector2(float(corner.y)/segments,float(corner.x)/(profile.size()-1)))
    st.set_color(Color.WHITE * (.90 + .10 * (sin(a)*.5+.5)))
    st.add_vertex(Vector3(cos(a)*p.x,sin(a)*p.y+p.w,p.z))
 for end in [0,profile.size()-1]:
  var p := profile[end]
  for i in range(segments):
   for point in [Vector3(0,p.w,p.z),Vector3(cos(TAU*i/segments)*p.x,sin(TAU*i/segments)*p.y+p.w,p.z),Vector3(cos(TAU*(i+1)/segments)*p.x,sin(TAU*(i+1)/segments)*p.y+p.w,p.z)]:
    st.set_normal(Vector3(0,0,-1 if end==0 else 1));st.set_color(Color.WHITE);st.set_uv(Vector2.ZERO);st.add_vertex(point)
 st.index()
 var result := st.commit()
 cache[key] = result
 return result

static func part(parent: Node3D, profile: Array[Vector4], color: Color, title: String) -> MeshInstance3D:
 var node := SpaceModelFactory.mesh(parent,loft(profile),Vector3.ZERO,color,title)
 var mat := node.material_override as StandardMaterial3D
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 mat.vertex_color_use_as_albedo = true
 return node

static func sweep(parent: Node3D, points: Array[Vector3], radii: Array[float], color: Color, title: String = "SculptedBranch") -> MeshInstance3D:
 var key := str(points)+str(radii)
 var shape: ArrayMesh
 if cache.has(key): shape=cache[key]
 else:
  var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var frames: Array[Basis]=[]
  for i in range(points.size()):
   var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
   frames.append(Basis.looking_at(tangent,Vector3.RIGHT if absf(tangent.y)>.95 else Vector3.UP))
  for ring in range(points.size()-1):
   for i in range(12):
    for corner in [Vector2i(ring,i),Vector2i(ring,i+1),Vector2i(ring+1,i),Vector2i(ring,i+1),Vector2i(ring+1,i+1),Vector2i(ring+1,i)]:
     var a: float=TAU*corner.y/12
     var n:=frames[corner.x]*Vector3(cos(a),sin(a),0)
     st.set_normal(n);st.set_color(Color.WHITE);st.set_uv(Vector2(float(corner.y)/12,float(corner.x)/points.size()))
     st.add_vertex(points[corner.x]+n*radii[corner.x])
  st.index();shape=st.commit();cache[key]=shape
 var node:=SpaceModelFactory.mesh(parent,shape,Vector3.ZERO,color,title)
 (node.material_override as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
 return node

static func wing(parent: Node3D, side: int, color: Color) -> Node3D:
 var root:=Node3D.new();root.name="FaunaWing"+str(side);root.position=Vector3(side*.35,1.25,0);root.scale.x=side;parent.add_child(root)
 var points: Array[Vector2]=[Vector2(0,0),Vector2(.45,-.55),Vector2(1.3,-.8),Vector2(2.1,-.35),Vector2(1.85,.12),Vector2(1.45,.02),Vector2(1.25,.65),Vector2(.85,.38),Vector2(.55,.95),Vector2(.2,.45)]
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()):
  for p in [Vector2(.75,.05),points[i],points[(i+1)%points.size()]]:
   st.set_normal(Vector3.UP);st.set_color(Color.WHITE);st.set_uv(p)
   st.add_vertex(Vector3(p.x,sin(p.x*1.7)*.20,p.y))
 var skin:=SpaceModelFactory.mesh(root,st.commit(),Vector3.ZERO,color,"ScallopedWingMembrane")
 var mat:=skin.material_override as StandardMaterial3D;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.next_pass=null
 for tip in [Vector3(2.1,-.1,-.35),Vector3(1.25,.12,.65),Vector3(.55,.12,.95)]:
  sweep(root,[Vector3.ZERO,Vector3(.6,.2,-.2),tip],[.09,.065,.008],color.lightened(.25),"WingFinger")
 return root

static func annulus(inner: float, outer: float) -> ArrayMesh:
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(18):
  for i in range(160):
   for corner in [Vector2i(row,i),Vector2i(row+1,i),Vector2i(row,i+1),Vector2i(row,i+1),Vector2i(row+1,i),Vector2i(row+1,i+1)]:
    var t:=float(corner.x)/18
    var a: float=TAU*corner.y/160
    var r:=lerpf(inner,outer,t)
    var band:=.55+.45*absf(sin(t*65))
    st.set_normal(Vector3.UP);st.set_uv(Vector2(float(corner.y)/160,t))
    st.set_color(Color(band,band,band,sin(t*PI)*.68))
    st.add_vertex(Vector3(cos(a)*r,0,sin(a)*r))
 return st.commit()
