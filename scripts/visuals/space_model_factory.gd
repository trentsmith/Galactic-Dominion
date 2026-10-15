class_name SpaceModelFactory
extends RefCounted

const PEARL := Color(0.91, 0.94, 1.0)
const GOLD := Color(1.0, 0.64, 0.12)
const NAVY := Color(0.009, 0.028, 0.09)
const BLUE := Color(0.015, 0.22, 0.48)
const CYAN := Color(0.05, 0.87, 1.0)

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color, name_text: String = "", glow: bool = false) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.name = name_text if not name_text.is_empty() else "ArmorPart"
 node.mesh = shape
 node.position = at
 node.material_override = CartoonStyle.material(color, glow)
 parent.add_child(node,true)
 return node

static func ball(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, name_text: String = "", glow: bool = false) -> MeshInstance3D:
 var sphere := SphereMesh.new()
 sphere.radius = 1
 sphere.height = 2
 sphere.radial_segments = 32
 sphere.rings = 16
 var node := mesh(parent, sphere, at, color, name_text, glow)
 node.scale = dimensions
 return node

static func ring(parent: Node3D, at: Vector3, radius: float, width: float, color: Color, name_text: String = "", glow: bool = false) -> MeshInstance3D:
 var torus := TorusMesh.new()
 torus.inner_radius = radius - width
 torus.outer_radius = radius + width
 torus.rings = 40
 torus.ring_segments = 10
 var node := mesh(parent, torus, at, color, name_text, glow)
 node.rotation.x = PI / 2
 return node

static func petal_mesh() -> ArrayMesh:
 # A closed, curved fin with actual thickness, not a flat sprite.
 var points := PackedVector2Array([Vector2(0,0),Vector2(-0.32,0.22),Vector2(-0.52,0.72),Vector2(-0.48,1.25),Vector2(-0.31,1.83),Vector2(0,2.55),Vector2(0.26,2.08),Vector2(0.48,1.52),Vector2(0.55,0.95),Vector2(0.42,0.36)])
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in range(points.size()):
  var next := (index + 1) % points.size()
  var a := Vector3(points[index].x,points[index].y,0)
  var b := Vector3(points[next].x,points[next].y,0)
  for v in [Vector3(0,1.05,-0.16),a,b,Vector3(0,1.05,0.16),b,a]: surface.add_vertex(v)
 surface.generate_normals()
 return surface.commit()

static func fin(parent: Node3D, at: Vector3, size: Vector3, lean: float, accent: Color = CYAN) -> Node3D:
 var root := Node3D.new()
 root.name = "SweptFin"
 root.position = at
 root.rotation.z = lean
 root.scale = size
 parent.add_child(root,true)
 var shape := petal_mesh()
 mesh(root,shape,Vector3.ZERO,GOLD,"GoldFinEdge")
 mesh(root,shape,Vector3(0,0.10,-0.07),PEARL,"PearlFinShell").scale = Vector3(0.84,0.88,0.9)
 mesh(root,shape,Vector3(0,0.24,-0.15),BLUE,"RecessedBlueFin").scale = Vector3(0.60,0.74,0.8)
 mesh(root,shape,Vector3(0,0.38,-0.31),accent,"FinEnergyInset",true).scale = Vector3(0.28,0.50,0.3)
 for panel in root.get_children():
  var material := panel.material_override as StandardMaterial3D
  material.cull_mode = BaseMaterial3D.CULL_DISABLED
  material.next_pass = null
 return root

static func pod(parent: Node3D, at: Vector3, size: float = 1.0, accent: Color = CYAN) -> Node3D:
 var root := Node3D.new()
 root.name = "ThrusterPod"
 root.position = at
 root.scale = Vector3.ONE * size
 parent.add_child(root,true)
 ball(root,Vector3.ZERO,Vector3(0.55,0.49,0.65),PEARL,"PearlPodHousing")
 ring(root,Vector3(0,0,-0.40),0.37,0.07,GOLD,"GoldEngineCollar")
 ball(root,Vector3(0,0,-0.43),Vector3(0.31,0.31,0.13),NAVY,"EngineRecess")
 ring(root,Vector3(0,0,-0.55),0.235,0.035,BLUE,"BlueEngineRing")
 ball(root,Vector3(0,0,-0.565),Vector3(0.18,0.18,0.025),accent,"ThrusterCore",true)
 ball(root,Vector3(-0.04,0.05,-0.595),Vector3(0.07,0.07,0.012),Color(0.75,1,1),"HotCore",true)
 for index in range(6):
  var angle := TAU * index / 6
  var block := BoxMesh.new()
  block.size = Vector3(0.05,0.09,0.03)
  mesh(root,block,Vector3(cos(angle)*0.27,sin(angle)*0.27,-0.55),GOLD,"TurbineBlade").rotation.z = angle
 return root

static func face(parent: Node3D, at: Vector3, size: float = 1.0, accent: Color = CYAN) -> Array[Node3D]:
 var root := Node3D.new()
 root.name = "FaceScreen"
 root.position = at
 root.scale = Vector3.ONE * size
 parent.add_child(root,true)
 ball(root,Vector3.ZERO,Vector3(1.02,0.95,0.62),NAVY,"GlossyVisor")
 ring(root,Vector3(0,0,0.02),1.0,0.065,GOLD,"VisorSeal").scale = Vector3(1.04,0.97,1)
 var eyes: Array[Node3D] = []
 for side in [-1,1]:
  var eye := ball(root,Vector3(side*0.37,0.12,-0.57),Vector3(0.13,0.25,0.045),accent,"LuminousEye",true)
  eye.rotation.z = side * -0.1
  eyes.append(eye)
  ball(root,Vector3(side*0.55,-0.23,-0.48),Vector3(0.12,0.055,0.025),accent,"CheekLight",true)
 # Small illuminated open smile, shaped with a smooth curved tube.
 var curve := Curve3D.new()
 for index in range(13):
  var t := float(index)/12
  curve.add_point(Vector3(lerpf(-0.15,0.15,t),-0.23-sin(t*PI)*0.13,-0.61))
 tube(parent,curve,at,0.028*size,accent,true,Vector3.ONE*size)
 ball(root,Vector3(-0.35,0.54,-0.42),Vector3(0.23,0.085,0.025),Color(0.82,0.97,1),"VisorGlint",true).rotation.z = -0.45
 ball(root,Vector3(-0.58,0.34,-0.37),Vector3(0.07,0.035,0.018),Color(0.4,0.85,1),"SecondaryGlint",true)
 return eyes

static func tube(parent: Node3D, path: Curve3D, at: Vector3, radius: float, color: Color, glow: bool, size: Vector3 = Vector3.ONE) -> void:
 var points := path.get_baked_points()
 for index in range(points.size()-1):
  var a := points[index]*size + at
  var b := points[index+1]*size + at
  if a.distance_to(b) < 0.001: continue
  var cylinder := CylinderMesh.new()
  cylinder.top_radius = radius
  cylinder.bottom_radius = radius
  cylinder.height = a.distance_to(b)
  cylinder.radial_segments = 8
  var node := mesh(parent,cylinder,(a+b)/2,color,"SmileLight",glow)
  var direction := (b-a).normalized()
  node.quaternion = Quaternion(Vector3.UP,direction)

static func companion(parent: Node3D, definition: CollectibleDefinition) -> Array[Node3D]:
 if definition.visual_style == "lunaflutter": return moon_moth(parent)
 var accent := CYAN
 if definition.rarity in ["legendary","mythic"]: accent = definition.rarity_color()
 ball(parent,Vector3.ZERO,Vector3(1.20,1.15,1.02),PEARL,"PearlHelmet")
 ball(parent,Vector3(0,-0.05,0.44),Vector3(1.04,0.91,0.75),BLUE,"RearBlueShell")
 var eyes := face(parent,Vector3(0,0.08,-0.55),0.96,accent)
 # Broad pearl-and-gold articulated pods echo the reference silhouette.
 pod(parent,Vector3(-1.21,-0.16,0.02),0.78,accent).rotation.z = -0.25
 pod(parent,Vector3(1.17,-0.28,0.02),0.78,accent).rotation.z = 0.25
 pod(parent,Vector3(0,-1.09,0.06),0.68,accent)
 ring(parent,Vector3(0,-0.73,-0.82),0.20,0.055,GOLD,"ChestCoreSeal")
 ball(parent,Vector3(0,-0.73,-0.84),Vector3(0.14,0.14,0.04),accent,"ChestCore",true)
 var tall := definition.species in ["Pebble","Vesperi"]
 for side in [-1,1]:
  fin(parent,Vector3(side*0.65,0.76,0.12),Vector3(0.72,0.78 if tall else 0.48,0.8),side*-0.42,accent)
  ball(parent,Vector3(side*0.98,0.15,0.2),Vector3(0.14,0.32,0.14),GOLD,"SideArmorHinge")
 if definition.species == "Auralith":
  ring(parent,Vector3(0,0.55,0),1.28,0.025,accent,"AuralithHalo",true).rotation = Vector3(0,0,0)
 if definition.species == "Drakari":
  for side in [-1,1]: fin(parent,Vector3(side*0.9,-0.15,0.5),Vector3(0.6,0.6,0.6),side*-1.3,Color(1,0.44,0.18))
 if definition.rarity in ["legendary","mythic"]:
  ring(parent,Vector3.ZERO,1.65,0.025,accent,"RareOrbit",true).rotation = Vector3(0.25,0,0.2)
 return eyes

static func ship(parent: Node3D, stats: ShipStats, team: int = 0) -> void:
 var accent := CYAN if team == 0 else Color(1,0.34,0.24)
 if stats.variant_style != "standard": accent = stats.color.lightened(0.25)
 var lunar := stats.variant_style == "moon_moth"
 if lunar: accent = Color(0.92,0.30,1)
 var heavy := stats.ability in ["aegis","barrage"]
 var body := CapsuleMesh.new()
 body.radius = 1.45 if heavy else 1.12
 body.height = 4.6 if stats.ability == "aegis" else 5.8
 mesh(parent,body,Vector3.ZERO,PEARL,"PearlFuselage").rotation.x = PI/2
 ball(parent,Vector3(0,0.12,1.05),Vector3(1.12,0.95,1.6),BLUE,"BlueRearArmor")
 ball(parent,Vector3(0,0.65,-2.20),Vector3(1.05,0.95,0.94),GOLD,"GoldCanopySeal")
 var visor := ball(parent,Vector3(0,0.73,-2.37),Vector3(0.96,0.85,0.91),Color(0.07,0.006,0.16) if lunar else NAVY,"PilotCanopy")
 var cockpit_material := visor.material_override as StandardMaterial3D
 cockpit_material.roughness = 0.08
 for side in [-1,1]:
  ball(parent,Vector3(side*0.36,0.80,-3.23),Vector3(0.13,0.22,0.055),accent,"CanopyEye",true)
  var span := 1.15 if heavy else 0.95
  if not lunar:
   fin(parent,Vector3(side*0.82,0.3,0.60),Vector3(span,1.25 if stats.ability=="speed" else 1.0,1),side*-0.90,accent)
  pod(parent,Vector3(side*(2.0 if heavy else 1.65),-0.24,0.78),0.92 if heavy else 0.74,accent)
  ring(parent,Vector3(side*0.82,-0.25,-2.75),0.16,0.04,GOLD,"NoseSensorSeal")
  ball(parent,Vector3(side*0.82,-0.25,-2.80),Vector3.ONE*0.10,accent,"NoseSensor",true)
 ball(parent,Vector3(-0.30,1.32,-2.84),Vector3(0.21,0.07,0.10),Color(0.8,0.98,1),"CanopyGlint",true).rotation.z = -0.4
 var nose := CapsuleMesh.new()
 nose.radius = 0.32
 nose.height = 1.0
 mesh(parent,nose,Vector3(0,-0.28,-2.55),GOLD,"GoldNoseGuard").rotation.x = PI/2
 if stats.ability == "aegis":
  ring(parent,Vector3(0,0,0.9),2.05,0.10,GOLD,"GuardianArmorRing")
 elif stats.ability == "barrage":
  for side in [-1,1]:
   for y in [-0.35,0.25]: pod(parent,Vector3(side*1.1,y,1.6),0.53,Color(1,0.6,0.16))
 elif stats.ability == "repair":
  ring(parent,Vector3(0,1.05,0.8),0.55,0.08,GOLD,"RepairBeaconRing").rotation = Vector3.ZERO
  ball(parent,Vector3(0,1.16,0.8),Vector3(0.32,0.18,0.32),Color(0.45,1,0.78),"RepairBeacon",true)
 if lunar:
  moon_wings(parent,1.45,Vector3(0,0.35,0.6))
  moon_antennae(parent,1.10,Vector3(0,0.75,-1.6))
 ring(parent,Vector3(0,0,2.52),0.65,0.10,GOLD,"AftEngineCollar")
 var engine := SphereMesh.new()
 engine.radius = 0.47
 engine.height = 0.94
 mesh(parent,engine,Vector3(0,0,2.85),accent,"MainEngine",true)
 var muzzle := SphereMesh.new()
 muzzle.radius = 0.35
 muzzle.height = 0.7
 mesh(parent,muzzle,Vector3(0,0,-3.25),accent,"MuzzleFlash",true).visible = false
 var shield := SphereMesh.new()
 shield.radius = 4.5
 shield.height = 9
 var barrier := mesh(parent,shield,Vector3.ZERO,Color(accent,0.12),"ShieldShell",true)
 var material := barrier.material_override as StandardMaterial3D
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 barrier.visible = false

static func station(parent: Node3D, accent: Color = CYAN) -> void:
 # Build at model scale; the world scales this reusable assembly up.
 ring(parent,Vector3.ZERO,2.5,0.36,PEARL,"PearlDockingRing")
 ring(parent,Vector3(0,0,-0.15),2.17,0.10,GOLD,"GoldDockingLip")
 ring(parent,Vector3(0,0,-0.26),2.05,0.035,accent,"DockingGuidance",true)
 for index in range(6):
  var angle := TAU*index/6
  var at := Vector3(cos(angle)*2.54,sin(angle)*2.54,0)
  ball(parent,at,Vector3(0.4,0.4,0.6),BLUE,"RingArmorJoint")
  pod(parent,at+Vector3(0,0,-0.20),0.47,accent)
 for side in [-1,1]:
  fin(parent,Vector3(side*2.35,1.5,0.2),Vector3(0.8,1.2,1),side*-0.55,accent)
  ball(parent,Vector3(side*2.85,-0.55,0.4),Vector3(0.45,1.0,0.6),PEARL,"StationModule")

# Lunaflutter is built from layered, closed 3D wings and faceted crystal meshes.
static func moon_wing(parent: Node3D, at: Vector3, dimensions: Vector3, lean: float, side: int) -> Node3D:
 var root := Node3D.new()
 root.name = "MoonWing"
 root.position = at
 root.scale = dimensions
 root.rotation.z = lean
 root.set_meta("rest_rotation",root.rotation)
 root.set_meta("wing_side",side)
 parent.add_child(root,true)
 var shape := petal_mesh()
 mesh(root,shape,Vector3.ZERO,GOLD,"GoldWingRim")
 mesh(root,shape,Vector3(0,0.035,-0.065),PEARL,"PearlWingRim").scale = Vector3(0.96,0.96,0.92)
 mesh(root,shape,Vector3(0,0.09,-0.14),Color(0.67,0.23,0.92),"VioletWingMembrane").scale = Vector3(0.87,0.90,0.84)
 mesh(root,shape,Vector3(0,0.24,-0.25),Color(1,0.70,0.89),"RoseWingPanel").scale = Vector3(0.66,0.68,0.65)
 mesh(root,shape,Vector3(0,0.40,-0.34),Color(1,0.94,0.73),"MoonWingInlay").scale = Vector3(0.37,0.48,0.45)
 for part in root.get_children():
  var material := part.material_override as StandardMaterial3D
  material.cull_mode = BaseMaterial3D.CULL_DISABLED
  material.next_pass = null
 for direction in [-1,1]:
  var vein := Curve3D.new()
  vein.bake_interval = 0.18
  vein.add_point(Vector3(0,0.18,-0.43))
  vein.add_point(Vector3(direction*0.21,0.95,-0.42))
  vein.add_point(Vector3(direction*0.16,1.85,-0.33))
  tube(root,vein,Vector3.ZERO,0.012,Color(0.90,0.74,1),true)
 for index in range(7):
  var y := 0.48+index*0.22
  var x := sin(index*2.4)*0.29
  ball(root,Vector3(x,y,-0.42),Vector3.ONE*0.026,Color(1,0.86,1),"WingStarlight",true)
 return root

static func moon_wings(parent: Node3D, size: float = 1.0, offset: Vector3 = Vector3.ZERO) -> void:
 for side in [-1,1]:
  moon_wing(parent,offset+Vector3(side*0.73,0.36,0.58)*size,Vector3(1.78,1.08,0.8)*size,side*-1.05,side)
  moon_wing(parent,offset+Vector3(side*0.75,-0.33,0.70)*size,Vector3(1.45,0.72,0.8)*size,side*-2.12,side)
  ball(parent,offset+Vector3(side*1.08,0.15,0.18)*size,Vector3(0.24,0.35,0.21)*size,GOLD,"MoonWingHinge")

static func moon_crystal(parent: Node3D, at: Vector3, size: float) -> Node3D:
 var root := Node3D.new()
 root.name = "AntennaGem"
 root.position = at
 root.scale = Vector3.ONE*size
 parent.add_child(root,true)
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var belt := [Vector3(-0.22,0,0),Vector3(0,0,-0.18),Vector3(0.22,0,0),Vector3(0,0,0.18)]
 for index in range(4):
  for upper in [true,false]:
   surface.set_color(Color(1,0.75,1) if index%2==0 else Color(0.55,0.20,0.88))
   var a: Vector3 = belt[index]
   var b: Vector3 = belt[(index+1)%4]
   for v in [Vector3(0,0.46 if upper else -0.34,0),a if upper else b,b if upper else a]: surface.add_vertex(v)
 surface.generate_normals()
 var gem := mesh(root,surface.commit(),Vector3.ZERO,Color.WHITE,"FacetedLunarCrystal")
 var material := gem.material_override as StandardMaterial3D
 material.vertex_color_use_as_albedo = true
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 material.next_pass = null
 ball(root,Vector3(0,0.08,-0.14),Vector3(0.045,0.22,0.025),Color(1,0.75,1),"CrystalGlow",true)
 return root

static func moon_antennae(parent: Node3D, size: float = 1.0, offset: Vector3 = Vector3.ZERO) -> void:
 for side in [-1,1]:
  var antenna := Node3D.new()
  antenna.name = "CrystalAntenna"
  antenna.position = offset
  antenna.scale = Vector3.ONE*size
  parent.add_child(antenna,true)
  var curve := Curve3D.new()
  curve.bake_interval = 0.15
  curve.add_point(Vector3(side*0.58,0.74,0))
  curve.add_point(Vector3(side*0.78,1.40,0.10))
  curve.add_point(Vector3(side*1.18,2.06,0.22))
  tube(antenna,curve,Vector3.ZERO,0.075,PEARL,false)
  var crystal := moon_crystal(antenna,Vector3(side*1.22,2.23,0.22),0.78)
  crystal.rotation.z = side*0.50
  ring(antenna,Vector3(side*0.59,0.78,-0.03),0.12,0.035,GOLD,"AntennaGoldSocket")

static func moon_moth(parent: Node3D) -> Array[Node3D]:
 var violet := Color(0.94,0.34,1)
 moon_wings(parent)
 moon_antennae(parent)
 ball(parent,Vector3.ZERO,Vector3(1.20,1.16,1.04),PEARL,"LunarPearlHelmet")
 var eyes := face(parent,Vector3(0,0.08,-0.55),0.96,violet)
 var visor := parent.find_child("GlossyVisor",true,false) as MeshInstance3D
 (visor.material_override as StandardMaterial3D).albedo_color = Color(0.065,0.004,0.15)
 for eye in eyes:
  eye.get_parent().remove_child(eye)
  eye.free()
 eyes.clear()
 var screen := parent.find_child("FaceScreen",true,false) as Node3D
 for side in [-1,1]:
  var happy := Node3D.new()
  happy.name = "HappyCrescentEye"
  happy.position = Vector3(side*0.37,0.12,-0.60)
  happy.set_meta("open_scale_y",1.0)
  screen.add_child(happy,true)
  var curve := Curve3D.new()
  curve.bake_interval = 0.035
  for index in range(13):
   var t := float(index)/12
   curve.add_point(Vector3(lerpf(-0.17,0.17,t),sin(t*PI)*0.18,0))
  tube(happy,curve,Vector3.ZERO,0.045,violet,true)
  eyes.append(happy)
 pod(parent,Vector3(-1.12,-0.20,0.03),0.78,violet).rotation.z = -0.30
 for side in [-1,1]:pod(parent,Vector3(side*0.74,-1.02,0.10),0.76,violet).rotation.z=side*0.30
 ring(parent,Vector3(0,-0.72,-0.85),0.21,0.05,GOLD,"DreamCoreSeal")
 ball(parent,Vector3(0,-0.72,-0.87),Vector3(0.14,0.14,0.04),violet,"DreamCore",true)
 return eyes
