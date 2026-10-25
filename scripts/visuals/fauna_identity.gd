class_name FaunaIdentity
extends RefCounted
## Habitat anatomy and patterned coats, shared by wild and sanctuary residents.
static func add(root: Node3D,d: FaunaDefinition) -> void:
 var pale:=Color(.95,.85,.65)
 var c:=d.color
 match d.id:
  "bloodstag":
   for side in [-1,1]:
    for i in range(3):
     var leaf:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(side*(.5+i*.13),2.1+i*.22,-.55),Color(.94,.35,.3),"AntlerBlossom")
     leaf.scale=Vector3(.16,.23,.25);leaf.rotation.z=side*1.1
   ArtGeometry.sweep(root,[Vector3(0,1.35,.8),Vector3(0,1.55,1.1),Vector3(0,1.4,1.35)],[.14,.2,.02],pale,"FawnTail")
  "duskbat":
   for side in [-1,1]:
    for rib in range(3):
     ArtGeometry.sweep(root,[Vector3(side*.3,1.2,0),Vector3(side*(1.2+rib*.3),1.8-rib*.25,.2),Vector3(side*(1.8+rib*.25),1.4-rib*.25,.8)],[.035,.025,.008],pale,"WingVein")
   SpaceModelFactory.ball(root,Vector3(0,1.63,-1.31),Vector3(.12,.15,.025),pale,"MoonBrow")
  "nightfang":
   for side in [-1,1]:
    for row in range(3):
     var tuft:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(side*.55,1.2+row*.12,.2+row*.2),c.darkened(.2),"EmberRuff")
     tuft.scale=Vector3(.2,.35,.3);tuft.rotation.z=side*.75
   SpaceModelFactory.ball(root,Vector3(0,1.73,-1.49),Vector3(.09,.13,.025),d.glow,"EmberBrow",true)
  "sporehopper":
   for i in range(7):
    var a:=TAU*i/7
    SpaceModelFactory.ball(root,Vector3(cos(a)*.56,1.88,sin(a)*.42),Vector3(.09,.055,.09),pale,"BellFreckle")
   for side in [-1,1]:ArtGeometry.sweep(root,[Vector3(side*.2,1.8,0),Vector3(side*.55,2.2,.1),Vector3(side*.4,2.4,0)],[.08,.06,.01],d.glow,"CrownFrond")
  "prismgrazer":
   for side in [-1,1]:
    ArtGeometry.sweep(root,[Vector3(side*.24,1,-1.2),Vector3(side*.55,.72,-1.5),Vector3(side*.78,.8,-1.35)],[.04,.035,.006],pale,"ReefWhisker")
   for i in range(4):
    var fin:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(0,1.7,.1+i*.22),d.glow.lightened(.3),"CoralSail")
    fin.scale=Vector3(.12,.4+i*.06,.3);fin.rotation.y=PI/2
  "thornmanta":
   for side in [-1,1]:
    for i in range(3):ArtGeometry.sweep(root,[Vector3(side*.45,1.35,-.85+i*.2),Vector3(side*.58,1.12,-.8+i*.2)],[.035,.01],pale,"GillSlit")
   ArtGeometry.sweep(root,[Vector3(0,1.6,-.7),Vector3(0,2.3,-.3),Vector3(0,1.8,.25)],[.13,.1,.01],c.darkened(.4),"HunterSail")
  "manyeye":
   for i in range(5):
    var a: float=PI*(.15+i*.17)
    var at:=Vector3(cos(a)*.7,1.7+sin(a)*.55,-.75)
    ArtGeometry.sweep(root,[Vector3(cos(a)*.35,1.4,-.35),at,at+Vector3(0,.2,-.15)],[.09,.055,.025],c.darkened(.3),"WatcherEyeStalk")
    SpaceModelFactory.ball(root,at+Vector3(0,.2,-.15),Vector3(.12,.1,.1),Color(.65,.72,.42),"SentinelEye")
    SpaceModelFactory.ball(root,at+Vector3(0,.2,-.24),Vector3(.025,.075,.025),Color(.01,.02,.015),"SentinelSlit")
  "veilcrawler":
   for side in [-1,1]:
    for i in range(3):
     ArtGeometry.sweep(root,[Vector3(side*.6,.9,-.4+i*.55),Vector3(side*1.2,1.1,-.6+i*.55),Vector3(side*1.8,.18,-.8+i*.6)],[.13,.09,.012],c.darkened(.35),"VeilStilt")
  "riftwisp":
   for i in range(6):
    var x: float=(i-2.5)*.16
    ArtGeometry.sweep(root,[Vector3(x,.95,.4),Vector3(x*1.5,.6,1.3),Vector3(x*2,.9,2.1)],[.065,.04,.003],Color(.35,.63,.65),"VeilStreamer")
 for child in root.get_children():
  if child is MeshInstance3D and str(child.name) in ["FaunaBody","SculptedHead"]:
   var mat:=ShaderMaterial.new();mat.shader=preload("res://resources/shaders/fauna_skin.gdshader")
   mat.set_shader_parameter("coat",c.lightened(.1));mat.set_shader_parameter("marking",pale.lerp(d.glow,.2));mat.set_shader_parameter("pattern",float(d.id.hash()%2))
   child.material_override=mat
