class_name FrontierHomeArt
extends RefCounted
static func build(parent: Node3D,profile: PlayerProfile) -> Node3D:
 var root:=Node3D.new();root.name="FrontierHomeFacilities";parent.add_child(root)
 var index:=0
 for id in FrontierState.FACILITIES:
  var level:=int(profile.frontier.facilities[id])
  if level<=0:continue
  var at:=Vector3(-20+index*20,0,-23);index+=1
  var block:=BoxMesh.new();block.size=Vector3(8,1,6)
  SpaceModelFactory.mesh(root,block,at,Color(.12,.23,.28),id+"Module")
  var label:=Label3D.new();label.text=FrontierState.FACILITIES[id].name+" / Lv%d"%level;label.position=at+Vector3(0,6,0);label.pixel_size=.02;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;root.add_child(label)
  if id=="observatory":
   SpaceModelFactory.ring(root,at+Vector3(0,3,0),3,.2,Color(.4,.85,1),"ObservatoryDish",true)
   for i in range(3):
    var ship:=Node3D.new();ship.position=at+Vector3((i-1)*3,1.5,0);ship.scale=Vector3.ONE*.25;root.add_child(ship);SpaceModelFactory.ship(ship,profile.configured_stats(i))
   if profile.ship_story.ending=="preserve":SpaceModelFactory.ball(root,at+Vector3(0,4,0),Vector3.ONE*.55,Color(.4,1,.8),"PreservedMemoryCore",true)
  elif id=="repair":
   for side in [-1,1]:SpaceModelFactory.ring(root,at+Vector3(side*2,2,0),1.4,.12,Color(.4,1,.7),"DockClamp",true)
  else:
   for i in range(level):
    var crate:=BoxMesh.new();crate.size=Vector3(1.5,1.5,1.5);SpaceModelFactory.mesh(root,crate,at+Vector3((i-1)*2,1.2,0),Color(.8,.48,.18),"Fabricator")
 return root
