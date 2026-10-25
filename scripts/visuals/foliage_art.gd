class_name FoliageArt
extends RefCounted
static func leaves(parent: Node3D, at: Vector3, color: Color, seed_value: int, size: float = 1.0) -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=seed_value
 var cluster:=MultiMeshInstance3D.new()
 var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
 mm.mesh=ArtGeometry.loft([Vector4(.01,.01,-.7,0),Vector4(.28,.07,-.25,.07),Vector4(.32,.1,.15,.10),Vector4(.12,.04,.6,.04),Vector4(.005,.005,.9,0)],12)
 mm.instance_count=24
 for i in range(24):
  var a:=rng.randf()*TAU
  var offset:=Vector3(cos(a)*rng.randf_range(.1,1.3),rng.randf_range(-.12,.28),sin(a)*rng.randf_range(.1,1.3))*size
  var basis:=Basis.from_euler(Vector3(rng.randf_range(-.35,.35),a,rng.randf_range(-.25,.25))).scaled(Vector3(1.0,.9,1.1)*rng.randf_range(.7,1.3)*size)
  mm.set_instance_transform(i,Transform3D(basis,offset))
  mm.set_instance_color(i,Color.WHITE.darkened(rng.randf_range(0,.18)))
 cluster.multimesh=mm;cluster.position=at
 var mat:=CartoonStyle.material(color);mat.vertex_color_use_as_albedo=true;mat.next_pass=null;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 cluster.material_override=mat;parent.add_child(cluster)

static func build(parent: Node3D, biome: String, at: Vector3, color: Color, glow: Color, style: int) -> Node3D:
 var root:=Node3D.new();root.position=at;root.rotation.y=style*.73;parent.add_child(root)
 if biome=="eldritch":
  for i in range(3):
   var a: float=TAU*i/3+style*.31
   var tip:=Vector3(cos(a)*.7,1.7+(style%4)*.35,sin(a)*.7)
   var stalk:=ArtGeometry.sweep(root,[Vector3.ZERO,Vector3(cos(a)*.4,.8,sin(a)*.4),tip,tip+Vector3(.3,.35,-.1)],[.16,.13,.07,.005],Color(.16,.24,.23),"WhisperStalk")
   EldritchArt.stone(stalk)
   if i==0:
    SpaceModelFactory.ball(root,tip,Vector3(.13,.2,.09),Color(.43,.65,.49),"WhisperBud",true)
 elif biome=="vampire" and style%3==0:
  ArtGeometry.sweep(root,[Vector3.ZERO,Vector3(.35,1.3,0),Vector3(-.3,3,0),Vector3(.4,4.8,.2),Vector3(.2,6.6,0)],[.45,.34,.25,.15,.015],Color(.10,.055,.105),"TwistedTrunk")
  for side in [-1,1]:
   ArtGeometry.sweep(root,[Vector3(0,2.5,0),Vector3(side*.8,4,.1),Vector3(side*2,5.2,.1),Vector3(side*2.6,5.3,.4)],[.24,.17,.08,.01],Color(.14,.07,.13),"Branch")
   leaves(root,Vector3(side*2.1,5.4,.1),color.lightened(.08),style+side,1.5)
   for i in range(4):
    var x:float=side*(1.1+i*.45)
    ArtGeometry.sweep(root,[Vector3(x,5.3,.4),Vector3(x+.15,4.5,.4),Vector3(x-.08,3.5-i*.15,.5)],[.055,.045,.008],color,"TrailingBlossom")
    leaves(root,Vector3(x,4.1-i*.15,.45),color.lightened(.12),style+i,.18)
  leaves(root,Vector3(.2,6.4,0),color,style,1.6)
 elif biome=="alien" and style%3==0:
  for i in range(6):
   var a:=TAU*i/6
   var tip:=Vector3(cos(a)*.9,1.6+i%3*.5,sin(a)*.9)
   ArtGeometry.sweep(root,[Vector3.ZERO,Vector3(cos(a)*.4,.7,sin(a)*.4),tip,tip+Vector3(.15,.35,0)],[.18,.13,.09,.01],Color(.83,.42,.38),"BranchingCoral")
   for side in [-1,1]:
    ArtGeometry.sweep(root,[tip*.65,tip+Vector3(side*.45,.15,.1),tip+Vector3(side*.55,.45,.1)],[.085,.055,.007],glow.lerp(Color(.85,.65,.5),.5),"CoralFinger")
 elif style%3==1:
  ArtGeometry.sweep(root,[Vector3.ZERO,Vector3(.12,.6,0),Vector3(0,1.25,0)],[.05,.04,.015],color.darkened(.2),"FlowerStem")
  for i in range(7):
   var a:=TAU*i/7
   var petal:=ArtGeometry.part(root,[Vector4(.01,.01,-.15,0),Vector4(.22,.09,.25,.08),Vector4(.3,.12,.65,.12),Vector4(.03,.02,1.1,.05)],color.lightened(.35),"LuminousFlowerPetal")
   petal.position=Vector3(0,1.15,0);petal.rotation=Vector3(-.22,a,0)
  SpaceModelFactory.ball(root,Vector3(0,1.23,0),Vector3(.18,.12,.18),glow,"FlowerHeart",true)
 else:
  for i in range(8):
   var a:=TAU*i/8
   var frond:=ArtGeometry.part(root,[Vector4(.015,.01,0,0),Vector4(.20,.04,.4,.15),Vector4(.32,.06,.9,.35),Vector4(.20,.05,1.4,.65),Vector4(.005,.005,1.9,.8)],color.lightened(.08),"SweptFernFrond")
   frond.rotation.y=a
  if biome=="eldritch":
   ArtGeometry.sweep(root,[Vector3.ZERO,Vector3(0,1.2,0),Vector3(.15,2.1,.1),Vector3(0,2.8,0)],[.24,.3,.14,.005],glow.darkened(.3),"LivingSpire")
   SpaceModelFactory.ball(root,Vector3(0,1.9,-.27),Vector3(.12,.18,.04),glow,"SpireEye",true)
 return root
