class_name NexusShipArt
extends RefCounted
## Original faction hulls; no creature faces. Five class silhouettes share fittings.
static func build(parent: Node3D,stats: ShipStats,team: int=0) -> void:
 var eldritch:=stats.variant_style in ["nexus_eldritch","voidglass","celestial"]
 var accent:=Color(.32,.95,.8) if eldritch else Color(1,.12,.08)
 var armor:=Color(.12,.065,.19) if eldritch else Color(.38,.045,.055)
 if not stats.variant_style in ["standard","nexus_crimson","nexus_eldritch"]:armor=stats.color.darkened(.15)
 var heavy:=stats.ability in ["aegis","barrage"]
 var span:=1.35 if heavy else .85 if stats.ability=="speed" else 1.0
 var hull:=Node3D.new();hull.name="NexusLivingHull" if eldritch else "NexusBloodforgedHull";parent.add_child(hull)
 if eldritch:
  SpaceModelFactory.ball(hull,Vector3(0,0,.25),Vector3(.65,.42,2.5),armor,"ChitinSpine")
  SpaceModelFactory.ball(hull,Vector3(0,.05,-.6),Vector3(.45,.32,.7),Color(.25,.85,.66),"CosmicHeart",true)
  for side in [-1,1]:
   for i in range(6):
    var t:=float(i)/5
    var at:=Vector3(side*(.8+sin(t*PI)*1.3)*span,.15+sin(t*PI)*.25,-2.6+t*5.0)
    var plate:=SpaceModelFactory.mesh(hull,SpaceModelFactory.petal_mesh(),at,armor.lightened(t*.12),"CrescentChitin")
    plate.scale=Vector3(.8,.9,.55);plate.rotation=Vector3(PI/2,0,side*-.65)
    SpaceModelFactory.ball(hull,at+Vector3(0,.15,0),Vector3(.055,.08,.28),accent,"BioluminescentVein",true)
  for i in range(3):
   var loop:=SpaceModelFactory.ring(hull,Vector3(0,.25,.3+i*.55),.6+i*.12,.035,accent,"DimensionalRib",true)
   loop.rotation.y=.4
 else:
  ShipArtDetails.armor(hull,[Vector4(.18,.28,-3.3,0),Vector4(.72,.5,-1.6,0),Vector4(.82,.48,.7,0),Vector4(.5,.3,2.5,0)],armor,"ForgedKeel")
  for side in [-1,1]:
   for i in range(3):
    var blade:=PrismMesh.new();blade.size=Vector3(1.3,.3,2.5)
    var plate:=SpaceModelFactory.mesh(hull,blade,Vector3(side*(1.0+i*.4)*span,.1,-.6+i*.8),armor.lightened(i*.06),"JaggedArmor")
    plate.rotation=Vector3(0,side*.7,side*-.12)
   ShipArtDetails.block(hull,Vector3(side*.48,.43,.5),Vector3(.08,.08,2.8),accent,"ReactorSeam")
   ShipArtDetails.block(hull,Vector3(side*1.9*span,-.2,-.6),Vector3(.3,.3,3.7),Color(.12,.12,.14),"SiegePylon")
   ShipArtDetails.block(hull,Vector3(side*1.9*span,-.2,-2.45),Vector3(.16,.16,.15),accent,"PlasmaEmitter")
  SpaceModelFactory.ball(hull,Vector3(0,.44,.1),Vector3(.2,.12,.9),accent,"BloodforgedReactor",true)
 for side in [-1,1]:
  ShipArtDetails.nacelle(hull,Vector3(side*(1.4 if heavy else 1.05),-.15,1.6),.75 if heavy else .6,accent)
 if stats.ability=="aegis":
  for side in [-1,1]:ShipArtDetails.block(hull,Vector3(side*2.5,.05,.4),Vector3(.55,.6,2.2),armor.lightened(.1),"GuardianRampart")
 elif stats.ability=="barrage":
  for side in [-1,1]:
   for i in range(3):ShipArtDetails.block(hull,Vector3(side*(.8+i*.3),-.45,.1),Vector3(.22,.24,1.8),armor.lightened(.12),"BomberLaunchRack")
 elif stats.ability=="repair":
  SpaceModelFactory.ring(hull,Vector3(0,.8,.7),.9,.045,accent,"SupportRelay",true)
 elif stats.ability=="overcharge":
  ShipArtDetails.block(hull,Vector3(0,.65,.8),Vector3(.3,.25,1.2),armor.lightened(.1),"SkirmisherDorsal")
 for part in hull.find_children("*","MeshInstance3D",true,false):
  var paint:=part.material_override as StandardMaterial3D
  if paint!=null:paint.next_pass=null;paint.cull_mode=BaseMaterial3D.CULL_DISABLED
 ShipArtDetails.exhaust(parent,accent)
 var muzzle:=SphereMesh.new();muzzle.radius=.35;muzzle.height=.7
 SpaceModelFactory.mesh(parent,muzzle,Vector3(0,0,-3.25),accent,"MuzzleFlash",true).visible=false
 var shell:=SphereMesh.new();shell.radius=4.5;shell.height=9
 var shield:=SpaceModelFactory.mesh(parent,shell,Vector3.ZERO,Color(accent,.12),"ShieldShell",true)
 var material:=shield.material_override as StandardMaterial3D;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED
 shield.visible=false
