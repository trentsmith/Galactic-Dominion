class_name FaunaFace
extends RefCounted
## Wildlife anatomy only. No emotive face mask; companions use separate art.
static var fibre_cache: Dictionary={}
static func section(profile: Array[Vector4],z: float) -> Vector4:
 for i in range(profile.size()-1):
  if z>=profile[i].z and z<=profile[i+1].z:return profile[i].lerp(profile[i+1],inverse_lerp(profile[i].z,profile[i+1].z,z))
 return profile[0] if z<profile[0].z else profile.back()
static func finish(node: MeshInstance3D,wet: bool=false) -> MeshInstance3D:
 var mat:=node.material_override as StandardMaterial3D
 mat.next_pass=null;mat.metallic=0;mat.roughness=.13 if wet else .76;mat.metallic_specular=.5 if wet else .18
 mat.clearcoat_enabled=wet;mat.clearcoat=.45 if wet else 0;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 node.set_meta("natural_face",true)
 return node
static func build(root: Node3D,d: FaunaDefinition,profile: Array[Vector4]) -> void:
 var style:=d.body_style
 # Bell animals use distributed sensory organs; wisps have no paired face.
 if style=="jelly":
  for i in range(8):
   var angle:=TAU*i/8
   finish(SpaceModelFactory.ball(root,Vector3(cos(angle)*.72,1.12,sin(angle)*.62),Vector3(.022,.018,.022),Color(.16,.24,.2),"Rhopalium"))
  return
 if style=="wisp":
  finish(SpaceModelFactory.ball(root,Vector3(0,1.2,.1),Vector3(.12,.24,.10),d.glow.darkened(.3),"AetherNucleus"))
  return
 var station: float=-1.10
 var yaw: float=45
 var cross_y: float=.45
 var width: float=.105
 var height: float=.085
 if style=="stag":station=-1.12;yaw=78;cross_y=.32;width=.075;height=.046
 elif style=="bat":station=-1.02;yaw=56;cross_y=.40;width=.066;height=.052
 elif style=="wolf":station=-1.12;yaw=54;cross_y=.48;width=.09;height=.052
 elif style=="crawler":station=-1.05;yaw=70;cross_y=.35;width=.057;height=.035
 elif style=="watcher":station=-1.08;yaw=62;cross_y=.48;width=.073;height=.044
 elif style in ["fish","shark"]:station=-1.05;yaw=82;cross_y=.30;width=.065 if style=="fish" else .054;height=.052 if style=="fish" else .037
 elif style=="jelly":station=-.28;yaw=74;cross_y=.36;width=.05;height=.05
 elif style=="wisp":station=-.42;yaw=58;cross_y=.43;width=.085;height=.07
 var ring:=section(profile,station)
 var cross_x:=sqrt(1.0-cross_y*cross_y)
 var iris_color:=Color(.25,.19,.11).lerp(d.glow,.10)
 if style in ["fish","shark","watcher","crawler","wisp"]:iris_color=Color(.22,.27,.18).lerp(d.glow,.08)
 var lid_color:=d.color.lightened(.15)
 for side in [-1,1]:
  var normal:=Vector3(side*sin(deg_to_rad(yaw)),.12,-cos(deg_to_rad(yaw))).normalized()
  var anchor:=Node3D.new();anchor.name="EyeAnchor";anchor.position=Vector3(side*ring.x*cross_x,ring.w+ring.y*cross_y,station)+normal*.008
  anchor.basis=Basis.looking_at(normal,Vector3.UP);anchor.set_meta("eye_open_y",1.0);anchor.set_meta("surface_station",station);anchor.set_meta("blinkable",not style in ["fish","shark"]);root.add_child(anchor,true)
  var depth:=width*.5
  finish(SpaceModelFactory.ball(anchor,Vector3.ZERO,Vector3(width,height,depth),Color(.035,.029,.024),"EyeSocket"),true)
  finish(SpaceModelFactory.ball(anchor,Vector3(0,0,-depth*.86),Vector3(width*.63,height*.73,.014),iris_color,"Iris"),true)
  var pupil_size:=Vector3(width*.30,height*.55,.008)
  if style=="stag":pupil_size=Vector3(width*.54,height*.18,.008)
  elif style in ["crawler","watcher","shark"]:pupil_size=Vector3(width*.14,height*.61,.008)
  finish(SpaceModelFactory.ball(anchor,Vector3(0,0,-depth-.009),pupil_size,Color(.006,.009,.008),"Pupil"),true)
  # Radial iris fibres stay portable geometry rather than a flat glowing sticker.
  var fibres:=finish(SpaceModelFactory.mesh(anchor,iris_fibres(width,height,depth),Vector3.ZERO,iris_color.lightened(.17),"IrisFibres"),true)
  (fibres.material_override as StandardMaterial3D).vertex_color_use_as_albedo=true
  finish(SpaceModelFactory.ball(anchor,Vector3(-width*.20,height*.28,-depth-.019),Vector3(width*.055,height*.07,.003),Color(.62,.71,.76),"EyeCatchlight"),true)
  for upper in ([] if style in ["fish","shark"] else [true,false]):
   var points: Array[Vector3]=[];var radii: Array[float]=[]
   for i in range(9):
    var a:=PI*float(i)/8*(1 if upper else -1)
    points.append(Vector3(cos(a)*width*1.08,sin(a)*height*1.08,-depth*.16))
    radii.append(width*(.14 if upper else .085))
   finish(ArtGeometry.sweep(anchor,points,radii,lid_color,"UpperLid" if upper else "LowerLid"))
  finish(SpaceModelFactory.ball(anchor,Vector3(width*.92,0,-.008),Vector3(width*.14,height*.14,.014),d.color.lerp(Color(.55,.28,.27),.25),"TearDuct"))
 if style in ["stag","wolf","bat","grazer","hopper"]:
  var tip:=profile[0]
  var nose_at:=Vector3(0,tip.w+.015,tip.z-.025)
  var nose_size:=Vector3(.145,.085,.065) if style!="wolf" else Vector3(.17,.105,.075)
  finish(SpaceModelFactory.ball(root,nose_at,nose_size,Color(.085,.055,.047),"NaturalNose"),true)
  for side in [-1,1]:finish(SpaceModelFactory.ball(root,nose_at+Vector3(side*nose_size.x*.55,.005,-nose_size.z*.85),Vector3(.022,.014,.009),Color(.009,.012,.012),"Nostril"),true)
  # Jaw seams follow the sides of the muzzle, not a front-facing smile.
  for side in [-1,1]:
   var jaw: Array[Vector3]=[]
   for z in [tip.z+.06,tip.z+.22,tip.z+.42]:
    var jaw_ring:=section(profile,z)
    jaw.append(Vector3(side*jaw_ring.x*.89,jaw_ring.w-jaw_ring.y*.46,z))
   finish(ArtGeometry.sweep(root,jaw,[.006,.008,.004],d.color.darkened(.6),"AnatomicalMouth"))
  finish(ArtGeometry.sweep(root,[nose_at+Vector3(0,-.035,-.06),Vector3(0,tip.w-.115,tip.z-.03)],[.007,.005],Color(.12,.07,.06),"Philtrum"))
  if style=="bat":
   var leaf:=ArtGeometry.part(root,[Vector4(.06,.025,tip.z-.05,tip.w+.04),Vector4(.10,.035,tip.z-.01,tip.w+.14),Vector4(.01,.01,tip.z+.04,tip.w+.32)],d.color.lightened(.15),"NasalLeaf")
   finish(leaf)
 elif style in ["fish","shark"]:
  finish(ArtGeometry.sweep(root,[Vector3(-.16,.96,-1.35),Vector3(0,.96,-1.46),Vector3(.16,.96,-1.35)],[.008,.012,.008],d.color.darkened(.55),"AnatomicalMouth"))
  for side in [-1,1]:finish(SpaceModelFactory.ball(root,Vector3(side*.14,1.13,-1.43),Vector3(.027,.014,.013),d.color.darkened(.65),"Nares"))
 elif style in ["crawler","watcher"]:
  for side in [-1,1]:
   finish(ArtGeometry.sweep(root,[Vector3(side*.12,ring.w-.12,station-.18),Vector3(side*.17,ring.w-.23,station-.37),Vector3(side*.08,ring.w-.25,station-.44)],[.03,.022,.003],d.color.darkened(.4),"FeedingMandible"))
  if style=="watcher":
   for side in [-1,1]:finish(SpaceModelFactory.ball(root,Vector3(side*.18,ring.w+ring.y*.85,station+.06),Vector3(.055,.05,.035),iris_color,"SecondaryOcellus"),true)
 else:
  # Bell ocelli and wisp folds are not mammal mouths.
  for side in [-1,1]:finish(ArtGeometry.sweep(root,[Vector3(side*.22,ring.w+.02,station-.1),Vector3(side*.28,ring.w-.12,station+.02)],[.01,.004],d.color.darkened(.20),"SensoryFold"))

static func iris_fibres(width: float,height: float,depth: float) -> ArrayMesh:
 var key:=str(Vector3(width,height,depth))
 if fibre_cache.has(key):return fibre_cache[key]
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(16):
  var angle:=TAU*i/16
  for corner in [Vector2(0,-1),Vector2(1,-1),Vector2(0,1),Vector2(0,1),Vector2(1,-1),Vector2(1,1)]:
   var radius:=lerpf(.38,.63,corner.x)
   var a: float=angle+corner.y*.018
   surface.set_normal(Vector3.FORWARD);surface.set_color(Color.WHITE.darkened(.12 if i%2==0 else 0))
   surface.add_vertex(Vector3(cos(a)*width*radius,sin(a)*height*radius,-depth-.003))
 var mesh:=surface.commit();fibre_cache[key]=mesh;return mesh

static func eyes(root: Node3D) -> Array[Node3D]:
 var result: Array[Node3D]=[]
 for eye in root.find_children("EyeAnchor*","Node3D",true,false):
  if eye.has_meta("eye_open_y"):result.append(eye)
 return result
static func blink(anchors: Array[Node3D],time: float) -> void:
 var phase:=fposmod(time,4.4)
 var closure:=smoothstep(4.12,4.24,phase)*(1.0-smoothstep(4.28,4.4,phase))
 for eye in anchors:
  if is_instance_valid(eye) and bool(eye.get_meta("blinkable",true)):eye.scale.y=float(eye.get_meta("eye_open_y"))*lerpf(1.0,.08,closure)
