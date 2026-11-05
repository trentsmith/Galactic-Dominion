class_name NexusMissionArt
extends RefCounted
static func beacon(parent: Node3D,at: Vector3,title: String,kind: String) -> Node3D:
 var object:=Node3D.new();object.name=kind;object.position=at;parent.add_child(object)
 var color:=Color(.45,1,.78) if kind=="MemoryVessel" else Color(1,.75,.25)
 if kind=="MemoryVessel":
  var stats: ShipStats=CollectionCatalog.SHIP_TYPES.guardian.duplicate(true);stats.variant_style="nexus_eldritch"
  var hull:=Node3D.new();hull.scale=Vector3.ONE*3.5;object.add_child(hull);NexusShipArt.build(hull,stats)
 elif kind=="ArchiveCore":
  SpaceModelFactory.ball(object,Vector3.ZERO,Vector3(7,7,7),Color(.12,.13,.3),"MemoryShell")
  for i in range(3):
   var ring:=SpaceModelFactory.ring(object,Vector3.ZERO,11+i*3,1,color,"ArchiveCradle",true);ring.rotation=Vector3(i*.9,i*.7,.3)
 else:
  var block:=BoxMesh.new();block.size=Vector3(8,16,7)
  SpaceModelFactory.mesh(object,block,Vector3.ZERO,Color(.22,.27,.34),"RelayMast")
  for side in [-1,1]:
   var panel:=BoxMesh.new();panel.size=Vector3(22,.7,8)
   SpaceModelFactory.mesh(object,panel,Vector3(side*16,-2,0),Color(.08,.22,.31),"TransmissionPanel")
 for i in range(2):SpaceModelFactory.ring(object,Vector3(0,2+i*4,0),16+i*4,.4,color,"ObjectiveHalo",true)
 var label:=Label3D.new();label.text=title;label.position.y=29;label.font_size=28;label.pixel_size=.065;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.visibility_range_end=2000;object.add_child(label)
 return object
