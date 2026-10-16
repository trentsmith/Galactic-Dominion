class_name SceneryArt
extends RefCounted
static func wreck(parent: Node3D, size: Vector3) -> void:
 var root:=Node3D.new();root.scale=size/Vector3(2.0,1.0,4.0);parent.add_child(root)
 ArtGeometry.part(root,[Vector4(.1,.08,-2,0),Vector4(.9,.4,-1.2,0),Vector4(1,.5,.1,0),Vector4(.7,.4,1.5,0),Vector4(.1,.08,2,0)],Color(.16,.22,.28),"AbandonedHull")
 for side in [-1,1]:
  var rib:=ArtGeometry.part(root,[Vector4(.02,.02,-1.7,0),Vector4(.12,.14,-1.1,0),Vector4(.15,.15,1.2,0),Vector4(.02,.02,1.6,0)],Color(.47,.53,.59),"ExposedRib")
  rib.position=Vector3(side*.75,.3,0)
  var plate:=SpaceModelFactory.mesh(root,SpaceModelFactory.petal_mesh(),Vector3(side*.75,.2,.25),Color(.35,.43,.49),"BrokenArmorPanel")
  plate.scale=Vector3(.6,.8,.4);plate.rotation=Vector3(.7,side*.2,side*-.8)
 # Severed conduits, exposed bulkhead and a dark engine bell read at flight distance.
 for side in [-1,1]:
  ArtGeometry.sweep(root,[Vector3(side*.65,-.1,-1.4),Vector3(side*.84,.15,-.2),Vector3(side*.55,.05,1.4)],[.035,.045,.025],Color(.24,.18,.13),"SeveredConduit")
  var seam:=ArtGeometry.part(root,[Vector4(.01,.01,-1.4,0),Vector4(.055,.025,-1,0),Vector4(.06,.03,1,0),Vector4(.01,.01,1.5,0)],Color(.11,.15,.18),"CharredPanelSeam")
  seam.position=Vector3(side*.42,.5,0)
 SpaceModelFactory.ring(root,Vector3(0,0,1.72),.43,.075,Color(.31,.29,.25),"WreckEngineCollar")
 SpaceModelFactory.ball(root,Vector3(0,0,1.78),Vector3(.34,.34,.10),Color(.018,.027,.033),"EmptyEngineBell")
 for i in range(3):
  SpaceModelFactory.ball(root,Vector3(.78,.12,-.8+i*.55),Vector3(.015,.04,.12),Color(.9,.44,.16),"DormantWarningLight",true)
static func tower(parent: Node3D, at: Vector3, color: Color, glow: Color) -> void:
 var tower:=ArtGeometry.part(parent,[Vector4(.1,.1,0,0),Vector4(2.4,2.4,.4,0),Vector4(2.1,2.1,3.5,0),Vector4(1.3,1.3,5,0),Vector4(.2,.2,7,0)],color,"SculptedCitadel")
 tower.position=at;tower.rotation.x=-PI/2
 for side in [-1,1]:
  var window:=ArtGeometry.part(parent,[Vector4(.02,.02,0,0),Vector4(.12,.08,.2,0),Vector4(.12,.08,2,0),Vector4(.02,.02,2.2,0)],glow,"CitadelLight")
  window.position=at+Vector3(side*.8,1.6,-2.0);window.rotation.x=-PI/2
