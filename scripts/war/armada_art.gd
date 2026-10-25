class_name ArmadaArt
extends RefCounted
## Bounded reinforcement geometry. Player takeover promotes the ship to its full hull.
static var hull: ArrayMesh
static func build(ship: CombatShip) -> void:
 if hull==null:
  hull=ArtGeometry.loft([Vector4(.12,.16,-3,0),Vector4(.65,.5,-1,0),Vector4(1,.55,1.6,0),Vector4(.6,.35,2.4,0)],8)
 var color:=Color(.3,.48,.58) if ship.team==0 else Color(.5,.21,.19)
 SpaceModelFactory.mesh(ship,hull,Vector3.ZERO,color,"ArmadaHull")
 for side in [-1,1]:
  var wing:=BoxMesh.new();wing.size=Vector3(1.8,.25,2.3)
  SpaceModelFactory.mesh(ship,wing,Vector3(side*1.4,0,.6),color.lightened(.15),"ArmadaWing")
 var engine:=BoxMesh.new();engine.size=Vector3(.9,.35,.3)
 SpaceModelFactory.mesh(ship,engine,Vector3(0,0,2.5),Color(.2,.85,1) if ship.team==0 else Color(1,.35,.15),"MainEngine",true)
 var flash:=SphereMesh.new();flash.radius=.4;flash.height=.8
 SpaceModelFactory.mesh(ship,flash,Vector3(0,0,-3.3),Color(1,.8,.2),"MuzzleFlash",true).visible=false
 var shield:=SphereMesh.new();shield.radius=3;shield.height=6;shield.radial_segments=8;shield.rings=4
 var shell:=SpaceModelFactory.mesh(ship,shield,Vector3.ZERO,Color(.2,.7,1,.15),"ShieldShell",true)
 shell.visible=false
