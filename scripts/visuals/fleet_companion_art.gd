class_name FleetCompanionArt
extends RefCounted
# Original, editable geometry. Animation pivots remain separate in the GLB exports.
const PINK := Color(1,0.32,0.88)

static func pivot(parent: Node3D, title: String, tilt: Vector3, speed: float) -> Node3D:
 var node := Node3D.new()
 node.name = title
 node.rotation = tilt
 node.set_meta("orbit_speed",speed)
 parent.add_child(node,true)
 return node

static func orbitot(parent: Node3D) -> Array[Node3D]:
 var pearl := SpaceModelFactory.PEARL
 var gold := SpaceModelFactory.GOLD
 var cyan := SpaceModelFactory.CYAN
 SpaceModelFactory.ball(parent,Vector3.ZERO,Vector3(1.18,1.12,1.0),pearl,"OrbitotPearlShell")
 var eyes := SpaceModelFactory.face(parent,Vector3(0,0.06,-0.57),0.94,cyan)
 for side in [-1,1]:
  SpaceModelFactory.fin(parent,Vector3(side*0.64,0.73,0.24),Vector3(0.56,0.60,0.65),side*-0.48,cyan)
  SpaceModelFactory.pod(parent,Vector3(side*0.88,-0.92,-0.02),0.74,cyan).rotation.z = side*0.25
 SpaceModelFactory.pod(parent,Vector3(0,-0.05,0.89),0.65,cyan).rotation.x = -0.5
 SpaceModelFactory.ring(parent,Vector3(0,-0.73,-0.85),0.20,0.05,gold,"GravityCoreSeal")
 SpaceModelFactory.ball(parent,Vector3(0,-0.73,-0.89),Vector3(0.15,0.15,0.05),cyan,"GravityCore",true)
 # Tilted gimbals frame the face; satellites rotate around local Y.
 for index in range(2):
  var orbit := pivot(parent,"SatelliteOrbit",Vector3(0.35 if index==0 else -0.4,0,0.38 if index==0 else -0.38),0.48 if index==0 else -0.34)
  orbit.position.y = -0.25-index*0.12
  SpaceModelFactory.ring(orbit,Vector3.ZERO,1.85+index*0.22,0.018,cyan,"IonOrbitTrail",true).rotation = Vector3.ZERO
  SpaceModelFactory.ring(orbit,Vector3.ZERO,1.92+index*0.22,0.025,gold,"GoldOrbitRail").rotation = Vector3.ZERO
  for bead in range(3):
   var angle := TAU*bead/3.0+index*0.7
   var at := Vector3(cos(angle)*(1.85+index*0.22),0,sin(angle)*(1.85+index*0.22))
   SpaceModelFactory.ball(orbit,at,Vector3.ONE*0.18,gold,"SatelliteCasing")
   SpaceModelFactory.ball(orbit,at+Vector3(0,0,-0.09),Vector3(0.14,0.14,0.12),SpaceModelFactory.BLUE,"SatelliteGem")
   SpaceModelFactory.ball(orbit,at+Vector3(-0.04,0.05,-0.19),Vector3.ONE*0.035,cyan,"SatelliteSpark",true)
 var crown := pivot(parent,"PlanetCrown",Vector3(0.6,0,0.28),0.22)
 crown.position.y = 2.25
 SpaceModelFactory.ball(crown,Vector3.ZERO,Vector3.ONE*0.28,SpaceModelFactory.BLUE,"CrownPlanet")
 SpaceModelFactory.ring(crown,Vector3.ZERO,0.62,0.028,gold,"CrownPlanetRing").rotation = Vector3.ZERO
 SpaceModelFactory.ring(crown,Vector3.ZERO,0.54,0.014,cyan,"CrownIonRing",true).rotation = Vector3.ZERO
 return eyes

static func crystal_petal(parent: Node3D, at: Vector3, lean: float, size: float) -> void:
 var root := Node3D.new()
 root.name = "PrismPetal"
 root.position = at
 root.rotation.z = lean
 root.scale = Vector3.ONE*size
 root.set_meta("wing_side",-1 if lean>0 else 1)
 root.set_meta("rest_rotation",root.rotation)
 parent.add_child(root,true)
 # Closed tapered leaf with a raised ridge and independently colored triangular facets.
 var rim := [Vector3(0,0,0),Vector3(-0.38,0.48,0),Vector3(-0.48,1.05,0),Vector3(-0.29,1.64,0),Vector3(0,2.15,0),Vector3(0.31,1.66,0),Vector3(0.50,1.02,0),Vector3(0.38,0.44,0)]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var palette := [Color(1,0.70,0.92),Color(0.64,0.55,1),Color(0.88,0.82,1),Color(0.48,0.82,1)]
 for side in [-1,1]:
  for index in range(rim.size()):
   var middle: Vector3 = (rim[index]+rim[(index+1)%rim.size()])*0.5+Vector3(0,0,side*0.06)
   for tri in [[Vector3(0,1.03,side*0.24),rim[index],middle],[Vector3(0,1.03,side*0.24),middle,rim[(index+1)%rim.size()]]]:
    surface.set_color(palette[(index+(1 if side>0 else 0))%palette.size()])
    for vertex in (tri if side<0 else [tri[0],tri[2],tri[1]]):surface.add_vertex(vertex)
 surface.generate_normals()
 var gem := SpaceModelFactory.mesh(root,surface.commit(),Vector3.ZERO,Color.WHITE,"IridescentPetalFacets")
 var material := gem.material_override as StandardMaterial3D
 material.vertex_color_use_as_albedo = true
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 material.next_pass = null
 material.roughness = 0.23
 var curve := Curve3D.new()
 curve.bake_interval = 0.18
 for point in rim:curve.add_point(point)
 curve.add_point(rim[0])
 SpaceModelFactory.tube(root,curve,Vector3.ZERO,0.025,SpaceModelFactory.PEARL,false)
 for node in root.get_children():
  if node is MeshInstance3D:node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func glimbloom(parent: Node3D) -> Array[Node3D]:
 for side in [-1,1]:
  crystal_petal(parent,Vector3(side*0.55,0.48,0.62),side*-0.62,0.94)
  crystal_petal(parent,Vector3(side*0.87,0.04,0.64),side*-1.34,0.86)
  crystal_petal(parent,Vector3(side*0.68,-0.43,0.57),side*-2.10,0.67)
 SpaceModelFactory.ball(parent,Vector3.ZERO,Vector3(1.17,1.10,1.03),Color(1,0.85,0.96),"GlimbloomPearlShell")
 var eyes := SpaceModelFactory.face(parent,Vector3(0,0.06,-0.57),0.94,PINK)
 var visor := parent.find_child("GlossyVisor",true,false) as MeshInstance3D
 (visor.material_override as StandardMaterial3D).albedo_color = Color(0.045,0.003,0.09)
 for side in [-1,1]:SpaceModelFactory.pod(parent,Vector3(side*0.91,-0.78,-0.09),0.74,PINK).rotation.z = side*0.30
 SpaceModelFactory.pod(parent,Vector3(0,-1.03,0.45),0.48,PINK)
 var crown := SpaceModelFactory.moon_crystal(parent,Vector3(0,1.02,-0.65),0.86)
 crown.name = "ForeheadPrism"
 SpaceModelFactory.ring(parent,Vector3(0,0.99,-0.54),0.29,0.045,SpaceModelFactory.GOLD,"CrownGoldSetting").scale = Vector3(0.78,1.2,1)
 var orbit := pivot(parent,"CrystalOrbit",Vector3(-0.22,0,0.28),-0.28)
 for index in range(5):
  var angle := TAU*index/5
  var gem := SpaceModelFactory.moon_crystal(orbit,Vector3(cos(angle)*2.20,0,sin(angle)*2.20),0.62)
  gem.name = "OrbitingPrism"
  gem.rotation.z = angle
 return eyes

static func attack(parent: Node3D, style: String) -> void:
 if style == "gravity_loop":
  SpaceModelFactory.ring(parent,Vector3.ZERO,0.55,0.045,SpaceModelFactory.CYAN,"GravityLoop",true)
  SpaceModelFactory.ring(parent,Vector3.ZERO,0.42,0.025,SpaceModelFactory.GOLD,"GravityLoopInner",true).rotation.y = 0.65
 elif style == "prism_pulse":
  var crystal := SpaceModelFactory.moon_crystal(parent,Vector3.ZERO,0.9)
  crystal.rotation.z = PI/4
