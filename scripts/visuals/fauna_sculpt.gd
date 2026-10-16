class_name FaunaSculpt
extends RefCounted
static func build(parent: Node3D, definition: FaunaDefinition) -> Node3D:
 var root:=Node3D.new();parent.add_child(root)
 var c:=definition.color;var light:=c.lightened(.23);var glow:=definition.glow;var style:=definition.body_style
 var aquatic:=style in ["jelly","fish","shark"]
 var body_profile: Array[Vector4]=[Vector4(.12,.15,-.85,1),Vector4(.5,.52,-.55,1.12),Vector4(.7,.62,.05,1.1),Vector4(.6,.52,.65,1),Vector4(.12,.16,1.05,1)]
 if style in ["fish","shark"]:
  body_profile=[Vector4(.04,.05,-1.55,1.05),Vector4(.4,.42,-1.25,1.1),Vector4(.68,.67,-.35,1.2),Vector4(.5,.5,.55,1.1),Vector4(.12,.18,1.45,1.02),Vector4(.025,.05,1.7,1)]
 if style=="wisp":
  body_profile=[Vector4(.04,.05,-.8,1.1),Vector4(.6,.65,-.4,1.15),Vector4(.65,.75,.1,1.25),Vector4(.3,.38,.8,1.05),Vector4(.03,.04,1.5,.5)]
 if style=="jelly":
  body_profile=[Vector4(.05,.05,-.75,1.3),Vector4(.65,.55,-.4,1.5),Vector4(.9,.6,.1,1.5),Vector4(.65,.45,.55,1.4),Vector4(.05,.05,.8,1.3)]
 var body:=ArtGeometry.part(root,body_profile,c,"FaunaBody")
 # A pale inset breast provides a deliberate character palette and readable silhouette.
 if not aquatic and style!="wisp":
  var breast:=ArtGeometry.part(root,[Vector4(.03,.03,-.87,.92),Vector4(.36,.32,-.62,.98),Vector4(.43,.3,.15,.85),Vector4(.03,.03,.6,.8)],c.lightened(.48),"BreastMarking")
  breast.position.y=-.18
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
  var count:=3 if style in ["grazer","crawler"] else 2
  for side in [-1,1]:
   for i in range(count):
    var z:float=(i-(count-1)*.5)*.8
    ArtGeometry.sweep(root,[Vector3(side*.48,.95,z),Vector3(side*.62,.62,z+.12),Vector3(side*.60,.22,z-.06),Vector3(side*.64,.12,z-.15)],[.19,.16,.095,.07],c.darkened(.06),"SculptedLeg")
    SpaceModelFactory.ball(root,Vector3(side*.64,.15,z-.2),Vector3(.18,.13,.25),c.darkened(.25),"RoundedPaw")
 # Organic heads use tapered cheeks and a muzzle instead of a second sphere.
 if not aquatic and style!="wisp":
  ArtGeometry.part(root,[Vector4(.06,.07,-1.65,1.10),Vector4(.32,.26,-1.42,1.19),Vector4(.53,.48,-1.05,1.40),Vector4(.46,.46,-.65,1.43),Vector4(.1,.1,-.35,1.32)],light,"SculptedHead")
  for side in [-1,1]:
   var ear:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(side*.36,1.62,-.75),c,"LeafEar")
   ear.scale=Vector3(.36,.30 if style!="bat" else .43,.8);ear.rotation.z=side*-.5
   var inner:=SpaceModelFactory.mesh(ear,SpaceModelFactory.petal_mesh(),Vector3(0,.15,-.1),glow.lightened(.3),"EarLining")
   inner.scale=Vector3(.55,.65,.6)
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
 var face_z:float=-1.48 if not aquatic and style!="wisp" else -.68 if style in ["jelly","wisp"] else -1.33
 var face_y:float=1.38 if not aquatic else 1.55 if style=="jelly" else 1.24
 for side in [-1,1]:
  var at:=Vector3(side*.23,face_y,face_z)
  SpaceModelFactory.ball(root,at,Vector3(.16,.2,.08),Color(.015,.025,.06),"EyeSocket")
  SpaceModelFactory.ball(root,at+Vector3(0,.005,-.065),Vector3(.09,.13,.025),glow,"Iris",true)
  SpaceModelFactory.ball(root,at+Vector3(-.035,.06,-.09),Vector3(.035,.04,.012),Color(.95,1,1),"EyeCatchlight",true)
  SpaceModelFactory.ball(root,Vector3(side*.34,face_y-.19,face_z+.01),Vector3(.10,.045,.025),Color(1,.53,.63),"RosyCheek")
  if style=="watcher":SpaceModelFactory.ball(root,Vector3(side*.2,face_y+.27,face_z+.02),Vector3(.10,.12,.06),glow,"UpperEye",true)
 ArtGeometry.sweep(root,[Vector3(-.12,face_y-.2,face_z-.02),Vector3(0,face_y-.27,face_z-.03),Vector3(.12,face_y-.2,face_z-.02)],[.018,.022,.018],Color(.04,.02,.07),"LittleSmile")
 return root
