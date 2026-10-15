class_name SanctuaryArt
extends RefCounted
const PALETTES=[Color(.24,.64,.45),Color(.40,.38,.75),Color(.77,.41,.38)]
static func habitat(parent: Node3D,kind: String,level: int) -> Node3D:
 var root:=Node3D.new();parent.add_child(root)
 var color:=Color(.40,.85,.5) if kind=="meadow" else Color(.20,.7,.92) if kind=="reef" else Color(.66,.39,.96) if kind=="rift" else Color(.90,.69,.3)
 var plate:=CylinderMesh.new();plate.top_radius=3.65;plate.bottom_radius=3.9;plate.height=.3;plate.radial_segments=24
 SpaceModelFactory.mesh(root,plate,Vector3(0,.15,0),color.darkened(.35),"HabitatFloor")
 SpaceModelFactory.ring(root,Vector3(0,.35,0),3.6,.13,color,"HabitatBorder",true).rotation=Vector3.ZERO
 if kind=="meadow":
  SurfaceArt.post(root,Vector3(-2,1.2,1),.20,2.4,Color(.3,.17,.12))
  SurfaceArt.ball(root,Vector3(-2,2.5,1),Vector3(1.5,.7,1.3),Color(.36,.8,.45))
  for i in range(5):SurfaceArt.ball(root,Vector3(cos(i*1.4)*2,.4,sin(i*1.4)*2),Vector3(.35,.35,.35),Color(1,.65,.83))
 elif kind=="reef":
  var water:=CylinderMesh.new();water.top_radius=3.3;water.bottom_radius=3.3;water.height=.08;water.radial_segments=32
  SpaceModelFactory.mesh(root,water,Vector3(0,.38,0),Color(.12,.50,.75),"LagoonWater")
  for i in range(5):
   var a:=i*1.3
   SurfaceArt.post(root,Vector3(cos(a)*2,.9,sin(a)*2),.10,1.4,Color(.85,.44,.47))
   SurfaceArt.ball(root,Vector3(cos(a)*2,1.6,sin(a)*2),Vector3.ONE*.18,Color(.4,1,1),true)
 elif kind=="rift":
  for i in range(4):
   var a:=i*PI/2
   SurfaceArt.ball(root,Vector3(cos(a)*2,1.0,sin(a)*2),Vector3(.4,1.5,.4),Color(.35,.25,.5))
  SpaceModelFactory.ring(root,Vector3(0,2,0),1.4,.06,color,"RiftHalo",true)
 else:
  for x in [-1,1]:
   var box:=BoxMesh.new();box.size=Vector3(1.6,.5,4)
   SpaceModelFactory.mesh(root,box,Vector3(x*1.1,.55,0),Color(.42,.25,.16),"PlanterBed")
 for i in range(level):SurfaceArt.ball(root,Vector3(-.5+i*.5,.6,3.2),Vector3.ONE*.14,Color(1,.95,.5),true)
 return root
static func island(parent: Node3D,palette: int) -> void:
 var core:=SphereMesh.new();core.radius=28;core.height=56;core.radial_segments=40;core.rings=16
 var base:=SpaceModelFactory.mesh(parent,core,Vector3(0,-15,0),Color(.21,.19,.30),"FloatingPlanetCore");base.scale=Vector3(1,.50,1)
 var top:=CylinderMesh.new();top.top_radius=27.5;top.bottom_radius=27;top.height=1.2;top.radial_segments=48
 SpaceModelFactory.mesh(parent,top,Vector3(0,-.6,0),PALETTES[palette],"GardenSurface")
 for i in range(15):
  var a:=TAU*i/15
  SurfaceArt.ball(parent,Vector3(cos(a)*25,1,sin(a)*25),Vector3(.8,1.0,.8),Color(.8,.85,1))
  SurfaceArt.ball(parent,Vector3(cos(a)*25,2,sin(a)*25),Vector3(.2,.3,.2),Color(.35,.9,1),true)
