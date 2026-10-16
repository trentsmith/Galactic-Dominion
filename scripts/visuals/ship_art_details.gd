class_name ShipArtDetails
extends RefCounted
# Shared sculpted surfaces keep every livery on the selected hull.
static func enamel(node: MeshInstance3D, roughness: float = 0.32) -> void:
 var mat := node.material_override as StandardMaterial3D
 mat.roughness=roughness
 mat.metallic=0.12
 mat.clearcoat_enabled=true
 mat.clearcoat=0.35
 mat.clearcoat_roughness=0.25

static func hull(parent: Node3D, stats: ShipStats, pearl: Color, panel: Color, accent: Color) -> void:
 var heavy := stats.ability in ["aegis","barrage"]
 var w := 1.38 if heavy else 1.02
 var body := ArtGeometry.part(parent,[Vector4(.06,.06,-3.05,-.05),Vector4(.4,.24,-2.8,-.05),Vector4(w*.8,.46,-2.0,-.06),Vector4(w,.53,-1.0,-.08),Vector4(w*.96,.5,.2,-.08),Vector4(w*.77,.43,1.35,-.04),Vector4(w*.55,.32,2.15,0),Vector4(.25,.18,2.6,0),Vector4(.04,.03,2.72,0)],pearl,"PearlFuselage")
 enamel(body)
 # Separate nacelle fairings and a recessed, tapered dorsal deck replace the rear sphere.
 var deck := ArtGeometry.part(parent,[Vector4(.03,.03,-1.7,.35),Vector4(.34,.18,-1.1,.43),Vector4(.50,.22,-.15,.47),Vector4(.43,.18,.9,.42),Vector4(.27,.12,1.8,.25),Vector4(.02,.02,2.4,.10)],panel,"BlueRearArmor")
 enamel(deck,0.38)
 for side in [-1,1]:
  var shoulder := ArtGeometry.part(parent,[Vector4(.03,.03,-1.9,0),Vector4(.31,.15,-1.25,0),Vector4(.34,.18,-.25,0),Vector4(.29,.14,.8,0),Vector4(.1,.07,1.9,0),Vector4(.02,.02,2.15,0)],pearl,"LayeredShoulderArmor")
  shoulder.position=Vector3(side*w*.73,.39,0)
  enamel(shoulder)
  ArtGeometry.sweep(parent,[Vector3(side*w*.7,.49,-1.6),Vector3(side*w*.98,.47,-.2),Vector3(side*w*.8,.36,1.2)],[.027,.035,.017],SpaceModelFactory.GOLD,"InlaidGoldSeam")
  ArtGeometry.sweep(parent,[Vector3(side*w*.78,.16,-2.15),Vector3(side*w*1.02,.20,-.6),Vector3(side*w*.96,.12,1.3)],[.025,.034,.016],accent,"NavigationLightRail")
  for index in range(4):
   var vent := ArtGeometry.part(parent,[Vector4(.01,.01,-.13,0),Vector4(.13,.025,-.07,0),Vector4(.13,.025,.07,0),Vector4(.01,.01,.13,0)],SpaceModelFactory.NAVY,"RecessedCoolingVent")
   vent.position=Vector3(side*.40,.66,.45+index*.23)
   vent.rotation.y=side*.2
 # A low glass flight deck, inset front face, and narrow seal rather than a gold ball.
 var glass := ArtGeometry.part(parent,[Vector4(.02,.02,-2.65,.41),Vector4(.40,.23,-2.1,.53),Vector4(.51,.25,-1.45,.61),Vector4(.32,.16,-.75,.61),Vector4(.02,.02,-.48,.55)],SpaceModelFactory.NAVY,"FlightDeckGlass")
 enamel(glass,0.16)
 var front := SpaceModelFactory.ball(parent,Vector3(0,.25,-2.68),Vector3(.66,.47,.30),SpaceModelFactory.NAVY,"PilotCanopy")
 enamel(front,0.19)
 var seal := SpaceModelFactory.ring(parent,Vector3(0,.25,-2.72),.67,.035,SpaceModelFactory.GOLD,"GoldCanopySeal")
 seal.scale.y=.72
 for side in [-1,1]:
  SpaceModelFactory.ball(parent,Vector3(side*.24,.28,-2.96),Vector3(.09,.14,.025),accent,"CanopyEye",true)
  SpaceModelFactory.ball(parent,Vector3(side*.39,.07,-2.90),Vector3(.07,.025,.015),accent,"CanopyCheek",true)
 ArtGeometry.sweep(parent,[Vector3(-.10,.08,-2.98),Vector3(0,.02,-3.0),Vector3(.10,.08,-2.98)],[.012,.014,.012],accent,"CanopySmile")
 var reflection := ArtGeometry.sweep(parent,[Vector3(-.32,.68,-2.0),Vector3(-.27,.82,-1.55),Vector3(-.17,.77,-1.0)],[.018,.028,.01],Color(.46,.70,.83),"GlassReflection")
 (reflection.material_override as StandardMaterial3D).next_pass=null
 ArtGeometry.part(parent,[Vector4(.01,.01,-3.12,-.12),Vector4(.21,.075,-2.83,-.14),Vector4(.12,.05,-2.45,-.15),Vector4(.01,.01,-2.2,-.14)],SpaceModelFactory.GOLD,"GoldNoseGuard")
 if stats.ability=="speed":
  var spine:=ArtGeometry.part(parent,[Vector4(.02,.02,-.3,0),Vector4(.07,.22,.4,0),Vector4(.055,.32,1.25,0),Vector4(.01,.01,2.1,0)],pearl,"InterceptorDorsalFin")
  spine.position.y=.55
 elif stats.ability=="overcharge":
  for side in [-1,1]:
   SpaceModelFactory.ring(parent,Vector3(side*.88,.30,-1.5),.14,.025,SpaceModelFactory.GOLD,"OverchargeSocket")
 elif stats.ability=="aegis":
  for side in [-1,1]:
   var armor:=ArtGeometry.part(parent,[Vector4(.03,.02,-1.6,0),Vector4(.30,.17,-.7,0),Vector4(.34,.21,.6,0),Vector4(.04,.03,1.8,0)],pearl,"GuardianShoulderPlate")
   armor.position=Vector3(side*1.30,.05,0)
 elif stats.ability=="barrage":
  for side in [-1,1]:
   for index in range(3):
    SpaceModelFactory.ring(parent,Vector3(side*(.9+index*.18),-.25,-1.5),.07,.018,SpaceModelFactory.GOLD,"MissileBayPort")

static func wing(parent: Node3D, side: int, heavy: bool, panel: Color, accent: Color) -> void:
 var root := Node3D.new();root.name="SweptFin";parent.add_child(root,true)
 var span := 1.1 if heavy else 1.0
 root.position=Vector3(side*.75,-.05,.35)
 root.rotation.y=side*PI/2
 root.scale=Vector3(1,1,span)
 var gold := ArtGeometry.part(root,[Vector4(.54,.09,0,0),Vector4(.72,.095,.65,.03),Vector4(.57,.075,1.5,.13),Vector4(.20,.045,2.3,.22),Vector4(.01,.01,2.65,.23)],SpaceModelFactory.GOLD,"WingLeadingEdge")
 var shell := ArtGeometry.part(root,[Vector4(.49,.10,.08,.01),Vector4(.63,.11,.68,.04),Vector4(.49,.09,1.5,.14),Vector4(.15,.055,2.3,.23),Vector4(.01,.01,2.53,.24)],SpaceModelFactory.PEARL,"PearlWingPanel")
 enamel(shell)
 var inset := ArtGeometry.part(root,[Vector4(.03,.02,.35,.15),Vector4(.37,.025,.8,.16),Vector4(.30,.025,1.4,.23),Vector4(.06,.018,2.1,.30),Vector4(.01,.01,2.25,.31)],panel,"InsetWingEnamel")
 enamel(inset,0.38)
 SpaceModelFactory.ball(root,Vector3(0,.27,2.4),Vector3(.065,.025,.10),accent,"WingtipLight",true)
 enamel(gold,0.28)

static func exhaust(parent: Node3D, accent: Color) -> MeshInstance3D:
 SpaceModelFactory.ring(parent,Vector3(0,0,2.57),.46,.06,SpaceModelFactory.GOLD,"AftEngineCollar")
 SpaceModelFactory.ball(parent,Vector3(0,0,2.62),Vector3(.37,.34,.09),SpaceModelFactory.NAVY,"RecessedEngineChamber")
 SpaceModelFactory.ring(parent,Vector3(0,0,2.71),.28,.028,accent,"AftIonAperture",true)
 var flame:=ArtGeometry.part(parent,[Vector4(.20,.17,0,0),Vector4(.24,.20,.25,0),Vector4(.16,.13,.62,0),Vector4(.07,.06,1.15,0),Vector4(.005,.005,1.55,0)],accent,"MainEngine")
 flame.position=Vector3(0,0,2.72)
 var material:=flame.material_override as StandardMaterial3D
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.emission_enabled=true;material.emission=accent;material.emission_energy_multiplier=.65;material.next_pass=null
 return flame
