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
 var root := Node3D.new();root.position=at;parent.add_child(root)
 if biome == "alien":
  if style%3==0:
   for i in range(7):
    var angle:=TAU*i/7
    var height:=1.0+(i%3)*.7
    var coral:=post(root,Vector3(cos(angle)*.6,height*.5,sin(angle)*.6),.12,height,Color(.65,.27,.14))
    coral.rotation.z=sin(angle)*.3
    ball(root,Vector3(cos(angle)*.7,height,sin(angle)*.7),Vector3(.18,.22,.18),Color(.3,.95,.85),true)
  elif style%3==1:
   post(root,Vector3(0,2,0),.12,4,color.darkened(.3))
   for i in range(6):
    var leaf:=ball(root,Vector3(sin(i*2.1)*.6,1+i*.5,cos(i*2.1)*.5),Vector3(.45,1.1,.12),color)
    leaf.rotation.z=sin(i*2.1)*.5;leaf.rotation.y=i*1.5
   ball(root,Vector3(0,4.2,0),Vector3(.15,.3,.15),glow,true)
  else:
   ball(root,Vector3(0,.25,0),Vector3(1,.3,1),Color(.2,.2,.5))
   for i in range(9):
    var a:=TAU*i/9
    var tendril:=post(root,Vector3(cos(a)*.7,.8,sin(a)*.7),.08,1.3,Color(.35,.18,.6))
    tendril.rotation.z=sin(a)*.3
    ball(root,Vector3(cos(a)*.7,1.5,sin(a)*.7),Vector3(.10,.14,.10),glow,true)
 elif biome == "vampire":
  if style%3==0:
   var trunk:=Curve3D.new();trunk.bake_interval=.6
   for point in [Vector3.ZERO,Vector3(.2,1.5,0),Vector3(-.35,3,0),Vector3(.6,4.5,.1),Vector3(.3,6.6,0)]:trunk.add_point(point)
   SpaceModelFactory.tube(root,trunk,Vector3.ZERO,.30,Color(.09,.045,.09),false)
   for side in [-1,1]:
    var branch:=Curve3D.new();branch.bake_interval=.5
    branch.add_point(Vector3(.3,4,0));branch.add_point(Vector3(side*1.3,5.6,.2));branch.add_point(Vector3(side*2.2,6,.5))
    SpaceModelFactory.tube(root,branch,Vector3.ZERO,.13,Color(.09,.045,.09),false)
    ball(root,Vector3(side*1.9,6.15,.3),Vector3(2,.4,1.5),color)
    for i in range(3):
     var vine:=post(root,Vector3(side*(1.2+i*.6),5.0-i*.13,.6),.045,1.8+i*.3,color)
     ball(root,Vector3(side*(1.2+i*.6),4.2-i*.3,.6),Vector3(.10,.22,.10),glow,true)
   ball(root,Vector3(.3,6.8,0),Vector3(1.8,.5,1.5),color)
  elif style%3==1:
   post(root,Vector3(0,.65,0),.06,1.3,color.darkened(.5))
   for i in range(6):
    var a:=TAU*i/6
    var petal:=ball(root,Vector3(cos(a)*.4,1.25,sin(a)*.4),Vector3(.22,.12,.65),Color(1,.18,.08),true)
    petal.rotation.y=-a+PI/2
   ball(root,Vector3(0,1.28,0),Vector3(.16,.13,.16),Color(1,.82,.2),true)
  else:
   for i in range(7):
    var a:=TAU*i/7
    var leaf:=ball(root,Vector3(cos(a)*.65,.4,sin(a)*.65),Vector3(.35,.15,1.1),Color(.12,.24,.21))
    leaf.rotation.y=-a
   ball(root,Vector3(0,.6,0),Vector3(.4,.6,.4),Color(.35,.10,.40))

 else:
  post(root,Vector3.ZERO+Vector3(0,1.2,0),.20,2.4,color)
  for i in range(5):
   var a:=TAU*i/5
   ball(root,Vector3(cos(a)*.6,1.8+sin(a)*.5,sin(a)*.6),Vector3(.18,.7,.18),color.lightened(.1))
  ball(root,Vector3(0,2.2,0),Vector3(.4,.5,.3),glow,true)
  ball(root,Vector3(0,2.2,-.28),Vector3(.17,.26,.06),Color(.015,.005,.03))
 for part in root.find_children("","MeshInstance3D",true,false):
  var mat:=part.material_override as StandardMaterial3D
  if mat!=null and mat.shading_mode!=BaseMaterial3D.SHADING_MODE_UNSHADED:
   mat.roughness=.95;mat.metallic=0;mat.metallic_specular=.12
 root.rotation.y=style*.73
 return root
static func creature(parent: Node3D, definition: FaunaDefinition) -> Node3D:
 var root:=Node3D.new();parent.add_child(root)
 var color:=definition.color;var glow:=definition.glow
 var style:=definition.body_style
 var floating:=style in ["bat","manta","wisp","jelly","fish","shark"]
 var body:=ball(root,Vector3(0,1.0,0),Vector3(.85,.55,1.0),color)
 body.name="FaunaBody"
 if style in ["bat","manta"]:
  for side in [-1,1]:
   var wing:=SpaceModelFactory.fin(root,Vector3(side*.45,1.0,0),Vector3(1.3,.8,.4),side*-1.45,glow)
   wing.name="FaunaWing"+str(side)
 elif style == "wisp":
  body.scale=Vector3(.55,.65,.55)
  SpaceModelFactory.ring(root,Vector3(0,1,0),.85,.035,glow,"WispHalo",true)
 elif style == "jelly":
  body.scale=Vector3(.85,.60,.85)
  body.material_override=CartoonStyle.material(glow,true)
  for i in range(6):
   var a:=TAU*i/6
   var curve:=Curve3D.new();curve.bake_interval=.2
   curve.add_point(Vector3(cos(a)*.5,.8,sin(a)*.5));curve.add_point(Vector3(cos(a)*.6,-.2,sin(a)*.6));curve.add_point(Vector3(cos(a)*.4,-.9,sin(a)*.4))
   SpaceModelFactory.tube(root,curve,Vector3.ZERO,.035,glow,true)
 elif style in ["fish","shark"]:
  body.scale=Vector3(.6,.6,1.6)
  SpaceModelFactory.fin(root,Vector3(0,1.2,.1),Vector3(.4,.4,.3),0,glow)
  for side in [-1,1]:SpaceModelFactory.fin(root,Vector3(side*.4,.95,.3),Vector3(.6,.45,.3),side*-1.4,glow)
  SpaceModelFactory.fin(root,Vector3(0,.8,1.4),Vector3(.6,.6,.4),PI/2,glow)
 else:
  var count:=3 if style in ["grazer","crawler"] else 2
  for side in [-1,1]:
   for index in range(count):
    var leg:=post(root,Vector3(side*.65,.40,(index-(count-1)*.5)*.75),.13,.8,color.darkened(.15))
    leg.rotation.z=side*.30
 if style == "stag":
  for side in [-1,1]:
   post(root,Vector3(side*.35,2.0,-.8),.08,1.1,glow).rotation.z=side*.45
   post(root,Vector3(side*.58,2.15,-.8),.06,.65,glow).rotation.z=side*1.0
 elif style == "hopper":
  ball(root,Vector3(0,1.6,0),Vector3(.95,.4,.95),color.lightened(.3))
 elif style == "crawler":
  for side in [-1,1]:
   var curve:=Curve3D.new();curve.bake_interval=.2
   curve.add_point(Vector3(side*.4,.9,-.5));curve.add_point(Vector3(side*1.1,.4,-1.2));curve.add_point(Vector3(side*1.3,.6,-1.8))
   SpaceModelFactory.tube(root,curve,Vector3.ZERO,.13,color,false)
 var head:=ball(root,Vector3(0,1.15,-.9),Vector3(.55,.50,.5),color.lightened(.12))
 if style == "wolf":
  ball(root,Vector3(0,1.03,-1.35),Vector3(.35,.25,.42),color)
  for side in [-1,1]:SpaceModelFactory.fin(root,Vector3(side*.3,1.45,-.9),Vector3(.25,.22,.3),side*-.2,glow)
 var eye_count:=4 if style == "watcher" else 2
 for i in range(eye_count):
  var x:float=(i%2*2-1)*.22
  var y:float=1.21+floorf(float(i)/2)*.26
  ball(root,Vector3(x,y,-1.32),Vector3(.13,.15,.06),glow,true)
 return root
