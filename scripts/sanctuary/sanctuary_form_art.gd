class_name SanctuaryFormArt
extends RefCounted
const ROSE:=Color(1,.55,.77)
const PEARL:=Color(.96,.95,.83)
const MINT:=Color(.42,1,.79)
static func leaf(parent: Node3D,at: Vector3,dimensions: Vector3,lean: float,color: Color) -> MeshInstance3D:
 var node:=SpaceModelFactory.mesh(parent,SpaceModelFactory.petal_mesh(),at,color,"KindredPetal")
 node.scale=dimensions;node.rotation.z=lean
 var material:=node.material_override as StandardMaterial3D
 material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.next_pass=null;material.roughness=.75;material.metallic=0
 return node
static func pearl(parent: Node3D,at: Vector3,size: float,color: Color=MINT) -> void:
 SurfaceArt.ball(parent,at,Vector3.ONE*size,color,true).name="AffectionPearl"
static func creature(parent: Node3D,definition: FaunaDefinition,stage: int) -> Node3D:
 var root:=SurfaceArt.creature(parent,definition)
 stage=clampi(stage,0,2);root.set_meta("form_stage",stage)
 if stage==0:return root
 var details:=Node3D.new();details.name="KindredDetails";root.add_child(details)
 var accent:=ROSE if stage==1 else MINT
 var style:=definition.body_style
 if style=="stag":
  for side in [-1,1]:
   var path:=Curve3D.new();path.bake_interval=.15
   for point in [Vector3(side*.3,1.7,-.8),Vector3(side*.55,2.4,-.7),Vector3(side*.85,2.9,-.6),Vector3(side*1.0,3.25,-.4)]:path.add_point(point)
   SpaceModelFactory.tube(details,path,Vector3.ZERO,.075,PEARL,false)
   for i in range(2+stage):
    leaf(details,Vector3(side*(.5+i*.15),2.2+i*.25,-.75),Vector3(.25,.23,.4),side*-.8,accent)
   pearl(details,Vector3(side*1.0,3.25,-.4),.12,accent)
  if stage==2:
   SpaceModelFactory.ring(details,Vector3(0,2.7,-.6),1.15,.04,PEARL,"AuroraCrown",true).rotation=Vector3.ZERO
   for i in range(5):leaf(details,Vector3(0,.85,-.2+i*.36),Vector3(.45,.38,.5),PI/2,MINT)
 elif style in ["bat","manta"]:
  for node in root.get_children():
   if str(node.name).begins_with("FaunaWing"):node.scale*=1.16 if stage==1 else 1.35
  for side in [-1,1]:
   for i in range(2+stage):
    leaf(details,Vector3(side*(.55+i*.32),.9,.3+i*.18),Vector3(.38,.38,.45),side*-2.1,accent)
  if stage==2:
   for side in [-1,1]:leaf(details,Vector3(side*.28,1.5,-.7),Vector3(.30,.40,.4),side*-.45,PEARL)
 elif style=="wolf":
  for i in range(5+stage*2):
   var a:=TAU*i/(5+stage*2)
   leaf(details,Vector3(cos(a)*.48,1.12+sin(a)*.35,-.68),Vector3(.28,.35,.45),a-PI/2,accent)
  var tail:=Curve3D.new();tail.bake_interval=.15
  tail.add_point(Vector3(0,1,.8));tail.add_point(Vector3(.5,1.3,1.6));tail.add_point(Vector3(.65,1.9,1.8))
  SpaceModelFactory.tube(details,tail,Vector3.ZERO,.14,definition.color.lightened(.25),false)
  leaf(details,Vector3(.65,1.8,1.8),Vector3(.35,.30,.5),-.8,accent)
  if stage==2:
   for side in [-1,1]:leaf(details,Vector3(side*.3,1.6,-.9),Vector3(.25,.36,.3),side*-.3,PEARL)
 elif style=="jelly":
  SurfaceArt.ball(details,Vector3(0,1.4,0),Vector3(.8,.22,.8),accent)
  for i in range(4+stage*2):
   var a:=TAU*i/(4+stage*2)
   var path:=Curve3D.new();path.bake_interval=.15
   path.add_point(Vector3(cos(a)*.7,.8,sin(a)*.7));path.add_point(Vector3(cos(a)*.9,-.3,sin(a)*.9));path.add_point(Vector3(cos(a)*.65,-1.3,sin(a)*.65))
   SpaceModelFactory.tube(details,path,Vector3.ZERO,.03,accent,true)
   pearl(details,Vector3(cos(a)*.65,-1.3,sin(a)*.65),.10,PEARL)
  if stage==2:
   for i in range(5):leaf(details,Vector3(0,1.4,0),Vector3(.32,.35,.4),TAU*i/5,PEARL)
 elif style in ["fish","shark"]:
  for side in [-1,1]:
   leaf(details,Vector3(side*.35,1.0,-.2),Vector3(.45,.65 if style=="shark" else .45,.5),side*-1.5,accent)
   for i in range(stage+1):SurfaceArt.ball(details,Vector3(side*.45,1.15,.2+i*.4),Vector3(.15,.32,.27),PEARL)
  for i in range(2+stage):leaf(details,Vector3(0,1.25,-.5+i*.5),Vector3(.32,.38,.4),0,accent)
  if stage==2:SpaceModelFactory.ring(details,Vector3(0,1.1,-1.0),.7,.035,MINT,"TidalCrest",true)
 elif style=="wisp":
  for i in range(3+stage):
   var a:=TAU*i/(3+stage)
   leaf(details,Vector3(cos(a)*.4,1,sin(a)*.4),Vector3(.35,.5,.5),-a,accent)
  if stage==2:
   var ring:=SpaceModelFactory.ring(details,Vector3(0,1,0),1.05,.04,PEARL,"DreamweaveRing",true);ring.rotation=Vector3(.5,.5,0)
 elif style=="watcher":
  for i in range(4+stage*2):
   var a:=TAU*i/(4+stage*2)
   leaf(details,Vector3(cos(a)*.5,1.2+sin(a)*.4,-.4),Vector3(.33,.45,.5),a-PI/2,accent)
  if stage==2:
   for i in range(5):pearl(details,Vector3(cos(TAU*i/5),1.8+sin(TAU*i/5)*.4,-.1),.09,PEARL)
 elif style=="crawler":
  for side in [-1,1]:
   for i in range(2+stage):
    leaf(details,Vector3(side*(.45+i*.3),.9,-.2+i*.35),Vector3(.35,.45,.45),side*-1.1,accent)
   pearl(details,Vector3(side*1.3,.6,-1.8),.18,accent)
 if stage==2:
  var emblem:=SurfaceArt.ball(details,Vector3(0,1.25,-1.39),Vector3(.07,.09,.02),PEARL,true);emblem.name="RadiantEmblem"
 return root
