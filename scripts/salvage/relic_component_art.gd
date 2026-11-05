class_name RelicComponentArt
extends RefCounted
static func build(parent: Node3D,stats: ShipStats) -> void:
 for slot in ["engine","shield","weapon","utility"]:
  var style: String=stats.get(slot+"_style")
  var definition:=CollectionCatalog.find(style)
  if definition==null or not definition.discovery_only:continue
  var color:=definition.rarity_color()
  if slot=="engine":
   for side in [-1,1]:
    var ring:=SpaceModelFactory.ring(parent,Vector3(side*2.0,0,2),.7,.045,color,"RelicDriveCoil",true);ring.rotation.x=PI/2
  elif slot=="shield":
   for side in [-1,1]:SpaceModelFactory.ball(parent,Vector3(side*.9,.55,.3),Vector3(.12,.25,.12),color,"EclipseCapacitor",true)
  elif slot=="weapon":
   for side in [-1,1]:
    var shape:=BoxMesh.new();shape.size=Vector3(.09,.09,1.6)
    SpaceModelFactory.mesh(parent,shape,Vector3(side*2.5,.25,-1),color,"RelicWeaponRail",true)
  else:
   var ring:=SpaceModelFactory.ring(parent,Vector3(0,1.6,1.8),.4,.035,color,"WayfinderArray",true);ring.rotation.x=0
