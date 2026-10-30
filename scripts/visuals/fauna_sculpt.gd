class_name FaunaSculpt
extends RefCounted
static func build(parent: Node3D, definition: FaunaDefinition) -> Node3D:
 var root:=Node3D.new();parent.add_child(root)
 var c:=definition.color.lightened(.10);var light:=c.lightened(.20);var glow:=definition.glow;var style:=definition.body_style
 var soft:=Color(.92,.84,.70).lerp(c.lightened(.4),.3)
 var aquatic:=style in ["jelly","fish","shark"]
 var body_profile: Array[Vector4]=[Vector4(.12,.15,-.85,1),Vector4(.5,.52,-.55,1.12),Vector4(.78,.66,.05,1.1),Vector4(.64,.56,.65,1),Vector4(.12,.16,1.05,1)]
 if style in ["fish","shark"]:
  body_profile=[Vector4(.04,.05,-1.55,1.05),Vector4(.46,.42,-1.25,1.1),Vector4(.68,.67,-.35,1.2),Vector4(.5,.5,.55,1.1),Vector4(.12,.18,1.45,1.02),Vector4(.025,.05,1.7,1)]
 if style=="wisp":
  body_profile=[Vector4(.04,.05,-.8,1.1),Vector4(.6,.65,-.4,1.15),Vector4(.65,.75,.1,1.25),Vector4(.3,.38,.8,1.05),Vector4(.03,.04,1.5,.5)]
 if style=="jelly":
  body_profile=[Vector4(.05,.05,-.75,1.3),Vector4(.65,.55,-.4,1.5),Vector4(.9,.6,.1,1.5),Vector4(.65,.45,.55,1.4),Vector4(.05,.05,.8,1.3)]
 # Species anatomy carries identity before any facial details are added.
 if style=="stag":
  body_profile=[Vector4(.07,.10,-.85,1.25),Vector4(.40,.46,-.55,1.4),Vector4(.56,.50,.05,1.35),Vector4(.48,.42,.70,1.25),Vector4(.08,.12,1.0,1.22)]
 elif style=="wolf":
  body_profile=[Vector4(.12,.20,-.85,1.18),Vector4(.48,.60,-.4,1.18),Vector4(.60,.53,.15,1.06),Vector4(.40,.42,.8,1.0),Vector4(.08,.12,1.1,1.02)]
 elif style=="bat":
  body_profile=[Vector4(.08,.1,-.7,1.1),Vector4(.36,.45,-.35,1.15),Vector4(.42,.48,.18,1.1),Vector4(.28,.30,.6,1),Vector4(.02,.03,.82,.95)]
 elif style=="crawler":
  body_profile=[Vector4(.06,.07,-.95,.65),Vector4(.52,.35,-.55,.68),Vector4(.85,.45,.25,.72),Vector4(.62,.38,.85,.7),Vector4(.05,.07,1.25,.65)]
 var face_profile: Array[Vector4]=body_profile
 var body:=ArtGeometry.part(root,body_profile,c,"FaunaBody")
 # A pale inset breast provides a deliberate character palette and readable silhouette.
 if not aquatic and style!="wisp":
  var breast:=ArtGeometry.part(root,[Vector4(.03,.03,-.87,.92),Vector4(.36,.32,-.62,.98),Vector4(.43,.3,.15,.85),Vector4(.03,.03,.6,.8)],c.lightened(.48),"BreastMarking")
  breast.position.y=-.18
  if style=="stag":breast.visible=false
 if style in ["bat","manta"]:
  for side in [-1,1]:ArtGeometry.wing(root,side,c.lightened(.18) if style=="bat" else glow.darkened(.15))
 elif style=="jelly":
  for i in range(10):
   var a:=TAU*i/10
   ArtGeometry.sweep(root,[Vector3(cos(a)*.6,1.3,sin(a)*.55),Vector3(cos(a)*.75,.5,sin(a)*.65),Vector3(cos(a)*.55,-.15,sin(a)*.6),Vector3(cos(a)*.8,-.8,sin(a)*.8)],[.055,.045,.03,.008],glow.lightened(.2),"PearlTendril")
  SpaceModelFactory.ring(root,Vector3(0,1.12,0),.78,.035,glow,"BellRim",true).rotation=Vector3.ZERO
 elif style in ["fish","shark"]:
  for side in [-1,1]:
   var fin:=ArtGeometry.wing(root,side,c.lightened(.25));fin.scale*=.55;fin.position.z=.3
  var dorsal:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(0,1.6,0),glow.darkened(.2),"SculptedDorsal")
  dorsal.scale=Vector3(.5,.55,.4);dorsal.rotation.y=PI/2
  for side in [-1,1]:
   var tail:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(0,1,1.5),light,"ForkedTail")
   tail.scale=Vector3(.35,.5,.4);tail.rotation=Vector3(side*.75,PI/2,0)
  for row in range(4):
   for side in [-1,1]:
    SpaceModelFactory.ball(root,Vector3(side*(.5-row*.08),1.3,-.25+row*.35),Vector3(.08,.13,.24),light,"PearlescentScale")
 elif style!="wisp":
  var count:=1 if style=="bat" else 3 if style in ["grazer","crawler"] else 2
  for side in [-1,1]:
   for i in range(count):
    var z:float=.45 if style=="bat" else (i-(count-1)*.5)*.8
    ArtGeometry.sweep(root,[Vector3(side*.48,.95,z),Vector3(side*.62,.62,z+.12),Vector3(side*.60,.22,z-.06),Vector3(side*.64,.12,z-.15)],[.19,.16,.095,.07],c.darkened(.06),"SculptedLeg")
    if style=="stag":
     for toe in [-1,1]:SpaceModelFactory.ball(root,Vector3(side*.64+toe*.07,.15,z-.2),Vector3(.06,.14,.20),c.darkened(.45),"HoofHalf")
    else:
     SpaceModelFactory.ball(root,Vector3(side*.64,.15,z-.2),Vector3(.18,.13,.25),c.darkened(.25),"RoundedPaw")
     for toe in [-1,1]:SpaceModelFactory.ball(root,Vector3(side*.64+toe*.055,.21,z-.35),Vector3(.035,.025,.025),light,"PawDimple")
 # Organic heads use tapered cheeks and a muzzle instead of a second sphere.
 if not aquatic and style!="wisp":
  var head_profile: Array[Vector4]=[Vector4(.08,.10,-1.72,1.32),Vector4(.33,.31,-1.5,1.45),Vector4(.52,.49,-1.05,1.48),Vector4(.45,.45,-.65,1.47),Vector4(.08,.1,-.35,1.35)]
  if style=="stag":
   head_profile=[Vector4(.16,.12,-1.94,1.52),Vector4(.24,.22,-1.72,1.55),Vector4(.40,.43,-1.12,1.85),Vector4(.36,.4,-.72,1.85),Vector4(.05,.08,-.45,1.65)]
  elif style=="wolf":
   head_profile=[Vector4(.16,.12,-1.95,1.34),Vector4(.28,.22,-1.65,1.4),Vector4(.5,.46,-1.0,1.55),Vector4(.4,.4,-.55,1.5),Vector4(.06,.08,-.3,1.4)]
  elif style=="bat":
   head_profile=[Vector4(.14,.12,-1.55,1.43),Vector4(.39,.34,-1.28,1.5),Vector4(.57,.49,-.85,1.55),Vector4(.38,.37,-.5,1.5),Vector4(.05,.05,-.3,1.4)]
  elif style=="crawler":
   head_profile=[Vector4(.04,.05,-1.55,.85),Vector4(.38,.25,-1.3,.9),Vector4(.47,.33,-.9,.98),Vector4(.3,.26,-.55,.95),Vector4(.04,.05,-.3,.85)]
  face_profile=head_profile
  ArtGeometry.part(root,head_profile,light,"SculptedHead")
  if style in ["stag","wolf","bat","grazer","hopper"]:
   for side in [-1,1]:
    var ear_y:=2.08 if style=="stag" else 1.82
    var ear:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(side*.34,ear_y,-.7),c,"LeafEar")
    ear.scale=Vector3(.28 if style=="stag" else .32,.31 if style!="bat" else .43,.64);ear.rotation.z=side*-.5
    var inner:=SpaceModelFactory.mesh(ear,SpaceModelFactory.petal_mesh(),Vector3(0,.12,-.08),c.lerp(Color(.6,.39,.35),.45),"EarLining")
    inner.scale=Vector3(.57,.70,.65)
 if style=="stag":
  for side in [-1,1]:
   ArtGeometry.sweep(root,[Vector3(side*.26,1.75,-.68),Vector3(side*.42,2.15,-.55),Vector3(side*.65,2.45,-.48),Vector3(side*.8,2.7,-.3)],[.1,.075,.045,.007],glow.lightened(.35),"BranchingAntler")
   ArtGeometry.sweep(root,[Vector3(side*.42,2.15,-.55),Vector3(side*.85,2.32,-.65),Vector3(side*1.0,2.5,-.6)],[.065,.04,.007],glow.lightened(.35),"AntlerTine")
 elif style=="wolf":
  for i in range(7):
   var a:=TAU*i/7
   var tuft:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(cos(a)*.42,1.25+sin(a)*.36,-.45),light,"ManeTuft")
   tuft.scale=Vector3(.3,.28,.5);tuft.rotation.z=a-PI/2
  ArtGeometry.sweep(root,[Vector3(0,1,.8),Vector3(.3,1.4,1.3),Vector3(.55,1.6,1.65),Vector3(.65,1.5,1.9)],[.23,.22,.13,.015],light,"PlumedTail")
 elif style in ["crawler","watcher"]:
  for i in range(7):
   var a:=PI*float(i)/6
   var plate:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(cos(a)*.55,1.4+sin(a)*.35,.25),light,"PetalCarapace")
   plate.scale=Vector3(.4,.38,.5);plate.rotation=Vector3(.7,0,a-PI/2)
  if style=="crawler":
   for side in [-1,1]:ArtGeometry.sweep(root,[Vector3(side*.4,1,-.5),Vector3(side*.9,.55,-1.1),Vector3(side*1.1,.65,-1.7),Vector3(side*.95,.9,-1.85)],[.16,.12,.08,.012],glow.darkened(.15),"CurledFeelers")
 elif style=="wisp":
  for side in [-1,1]:ArtGeometry.sweep(root,[Vector3(side*.3,.8,.3),Vector3(side*.7,.5,.8),Vector3(side*.5,.3,1.4),Vector3(side*.2,.65,1.8)],[.18,.14,.07,.006],glow,"DreamRibbon")
  SpaceModelFactory.ring(root,Vector3(0,1.45,.1),.8,.018,glow,"WispHalo",true).rotation=Vector3(.5,0,.2)
 FaunaFace.build(root,definition,face_profile)
 # Restrained, habitat-colored markings rather than accessories on every species.
 if style=="stag":
  for side in [-1,1]:
   for i in range(5):
    SpaceModelFactory.ball(root,Vector3(side*.54,1.47+(i%2)*.08,-.2+i*.19),Vector3(.012,.035,.045),soft,"FawnSpot")
 if style in ["fish","shark"]:
  for side in [-1,1]:
   for i in range(3):
    ArtGeometry.sweep(root,[Vector3(side*.53,1.5,-.45+i*.25),Vector3(side*.64,1.22,-.40+i*.25),Vector3(side*.5,.94,-.35+i*.25)],[.035,.045,.015],c.darkened(.20),"ReefStripe")
 FaunaIdentity.add(root,definition)
 soften_materials(root)
 return root

static func soften_materials(node: Node) -> void:
 for child in node.get_children():
  if child is MeshInstance3D and child.material_override is StandardMaterial3D:
   var mat:=child.material_override as StandardMaterial3D
   if not child.has_meta("natural_face") and not str(child.name).begins_with("Eye") and not str(child.name).begins_with("Iris"):
    mat.roughness=.86;mat.metallic=0;mat.metallic_specular=.16;mat.next_pass=null
   mat.cull_mode=BaseMaterial3D.CULL_DISABLED
  soften_materials(child)
