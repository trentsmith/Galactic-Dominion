class_name ShipArtDetails
extends RefCounted
## Chamfered hard-surface spacecraft. No lathed hulls or petal wings.
const STEEL:=Color(.11,.18,.24)
const ARMOR:=Color(.68,.74,.8)
const DARK:=Color(.025,.035,.045)
const COPPER:=Color(.84,.47,.17)
const ION:=Color(.22,.85,1)
static var shapes: Dictionary={}
static var halo_texture: ImageTexture
static var panel_texture: ImageTexture
static func metal_texture() -> ImageTexture:
 if panel_texture!=null:return panel_texture
 var image:=Image.create(128,128,false,Image.FORMAT_RGB8)
 var random:=RandomNumberGenerator.new();random.seed=2424
 for y in range(128):
  for x in range(128):
   var value:=random.randf_range(.94,1.0)
   if x%32==0 or y%64==0:value*=.8
   if y%37==0 and x%64<19:value*=.87
   image.set_pixel(x,y,Color(value,value,value))
 panel_texture=ImageTexture.create_from_image(image);return panel_texture
static func enamel(node: MeshInstance3D,roughness: float=.46) -> void:
 var mat:=node.material_override as StandardMaterial3D
 mat.roughness=roughness;mat.metallic=.65;mat.metallic_specular=.4;mat.next_pass=null
 mat.clearcoat_enabled=true;mat.clearcoat=.16;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mat.albedo_texture=metal_texture()
static func armor(parent: Node3D,profile: Array[Vector4],color: Color,title: String) -> MeshInstance3D:
 var key:=str(profile)
 if not shapes.has(key):
  var cross: Array[Vector2]=[Vector2(-.72,-1),Vector2(.72,-1),Vector2(1,-.55),Vector2(1,.55),Vector2(.72,1),Vector2(-.72,1),Vector2(-1,.55),Vector2(-1,-.55)]
  var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for ring in range(profile.size()-1):
   for edge in range(8):
    for corner in [Vector2i(ring,edge),Vector2i(ring, (edge+1)%8),Vector2i(ring+1,edge),Vector2i(ring,(edge+1)%8),Vector2i(ring+1,(edge+1)%8),Vector2i(ring+1,edge)]:
     var p:=profile[corner.x];var uv:=cross[corner.y]
     st.set_smooth_group(-1);st.set_uv(Vector2(p.z*.35,uv.x*.5+.5));st.add_vertex(Vector3(uv.x*p.x,uv.y*p.y+p.w,p.z))
  for end in [0,profile.size()-1]:
   var p:=profile[end]
   for edge in range(8):
    for uv in [Vector2.ZERO,cross[edge],cross[(edge+1)%8]]:st.set_smooth_group(-1);st.set_uv(Vector2(p.z*.35,uv.x*.5+.5));st.add_vertex(Vector3(uv.x*p.x,uv.y*p.y+p.w,p.z))
  st.generate_normals();shapes[key]=st.commit()
 var node:=SpaceModelFactory.mesh(parent,shapes[key],Vector3.ZERO,color,title);enamel(node);return node
static func block(parent: Node3D,at: Vector3,size: Vector3,color: Color,title: String,glow: bool=false) -> MeshInstance3D:
 var node:=SpaceModelFactory.mesh(parent,BoxMesh.new(),at,color,title,glow);node.scale=size
 if not glow:enamel(node)
 return node
static func hull(parent: Node3D,stats: ShipStats,_pearl: Color,panel: Color,accent: Color) -> void:
 var heavy:=stats.ability in ["aegis","barrage"]
 var width:=1.15 if heavy else .88
 var paint:=ARMOR if stats.variant_style=="standard" else ARMOR.lerp(panel.lightened(.3),.25)
 armor(parent,[Vector4(.18,.10,-2.9,0),Vector4(.57,.24,-2.3,0),Vector4(width,.35,-1.4,0),Vector4(width,.30,.3,0),Vector4(.62,.22,1.2,0)],STEEL,"PearlFuselage")
 var deck:=armor(parent,[Vector4(.45,.08,-1.0,.36),Vector4(.65,.12,-.3,.38),Vector4(.50,.09,.7,.35)],DARK,"BlueRearArmor")
 deck.position.y=.02
 var glass:=armor(parent,[Vector4(.1,.025,-2.8,.18),Vector4(.43,.16,-2.1,.40),Vector4(.50,.20,-1.4,.48),Vector4(.40,.10,-.7,.45)],Color(.018,.055,.08),"FlightDeckGlass");enamel(glass,.14)
 var canopy:=armor(parent,[Vector4(.06,.02,-2.82,.22),Vector4(.42,.09,-2.18,.38),Vector4(.45,.1,-1.75,.51)],Color(.018,.07,.095),"PilotCanopy");enamel(canopy,.14)
 for side in [-1,1]:
  var plate:=armor(parent,[Vector4(.12,.1,-2.4,0),Vector4(.30,.12,-1.5,0),Vector4(.36,.1,.25,0),Vector4(.2,.06,1.15,0)],paint,"LayeredShoulderArmor");plate.position=Vector3(side*.67,.34,0)
  block(parent,Vector3(side*.74,.48,-.6),Vector3(.045,.025,1.4),COPPER,"HullAccentInlay")
  for index in range(4):
   block(parent,Vector3(side*.34,.53,-.25+index*.19),Vector3(.23,.055,.075),STEEL,"RecessedCoolingVent")
  # Open mechanical rear: conduits and thrust frame remain visible between armour.
  block(parent,Vector3(side*.42,.12,1.4),Vector3(.16,.18,1.05),COPPER,"ExposedPowerConduit")
  for i in range(3):block(parent,Vector3(side*.48,.27,.9+i*.35),Vector3(.58,.14,.12),STEEL,"ReactorCrossBrace")
  block(parent,Vector3(side*.43,.53,-1.63),Vector3(.025,.025,.45),ION,"CockpitEdgeLight",true)
 if stats.ability=="aegis":
  for side in [-1,1]:block(parent,Vector3(side*1.1,.25,-.5),Vector3(.45,.55,1.8),paint,"GuardianShoulderPlate")
 elif stats.ability=="barrage":
  for side in [-1,1]:
   for i in range(3):block(parent,Vector3(side*.65,-.35,-1+i*.4),Vector3(.24,.18,.28),DARK,"MissileBayPort")
 elif stats.ability=="repair":
  block(parent,Vector3(0,.55,.4),Vector3(.7,.2,.6),Color(.2,.8,.6),"RepairBeacon",true)
 elif stats.ability=="speed":
  var fin:=block(parent,Vector3(0,.65,.55),Vector3(.10,.65,.8),STEEL,"InterceptorDorsalFin");fin.rotation.x=-.25
static func wing(parent: Node3D,side: int,heavy: bool,_panel: Color,_accent: Color) -> void:
 var root:=Node3D.new();root.name="SweptFin";parent.add_child(root,true)
 var span:=2.8 if heavy else 2.45
 var strut:=block(root,Vector3(side*span*.65,-.04,.4),Vector3(span,.20,.55),STEEL,"ExposedWingSpar");strut.rotation.y=side*-.18
 var panel:=armor(root,[Vector4(.4,.07,-1.6,0),Vector4(.66,.10,-.6,0),Vector4(.58,.08,.7,0),Vector4(.24,.04,1.2,0)],ARMOR,"PearlWingPanel");panel.position=Vector3(side*1.65,.03,.12);panel.rotation.y=side*-.32
 block(root,Vector3(side*1.72,.16,.8),Vector3(.45,.035,.65),COPPER,"WingWarningPanel")
 # The gun is mounted to an exposed rail rather than a decorative fin tip.
 block(root,Vector3(side*2.0,-.25,-.95),Vector3(.16,.16,1.8),DARK,"RailMountedCannon")
static func nacelle(parent: Node3D,at: Vector3,size: float,_accent: Color) -> void:
 var root:=Node3D.new();root.name="SplitEnginePod";root.position=Vector3(signf(at.x)*3.05,-.12,.4);root.scale=Vector3.ONE*size;parent.add_child(root,true)
 for side in [-1,1]:
  # Four distinct rectangular thruster cassettes with a structural gap between them.
  var at_y: float=side*.38
  var shell:=armor(root,[Vector4(.40,.12,-1.8,0),Vector4(.73,.22,-1.2,0),Vector4(.80,.22,1.0,0),Vector4(.65,.18,1.85,0)],ARMOR,"NacelleArmor");shell.position.y=at_y
  var inlay:=armor(root,[Vector4(.22,.012,-1.45,0),Vector4(.48,.018,-.8,0),Vector4(.5,.018,1.35,0)],STEEL,"NacelleTopPanel");inlay.position.y=at_y+.23
  block(root,Vector3(0,at_y,1.87),Vector3(1.20,.32,.11),DARK,"RecessedEngineChannel")
  block(root,Vector3(0,at_y,1.94),Vector3(.99,.18,.035),ION,"CyanEngineStrip",true)
  block(root,Vector3(0,at_y,1.97),Vector3(.74,.055,.02),Color(.82,1,1),"WhiteHotEngineCore",true)
  var halo:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.75,.75);halo.mesh=quad;halo.position=Vector3(0,at_y,2.0)
  if halo_texture==null:
   var image:=Image.create(32,32,false,Image.FORMAT_RGBA8)
   for y in range(32):
    for x in range(32):
     var point:=(Vector2(x,y)/31.0-Vector2.ONE*.5)*2
     var glow:=exp(-point.length_squared()*4)
     image.set_pixel(x,y,Color(.1,.65,1,glow*.4))
   halo_texture=ImageTexture.create_from_image(image)
  var halo_material:=StandardMaterial3D.new();halo_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;halo_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;halo_material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;halo_material.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED;halo_material.cull_mode=BaseMaterial3D.CULL_DISABLED;halo_material.albedo_texture=halo_texture
  halo.material_override=halo_material;halo.name="EngineBloom";root.add_child(halo)
  for i in range(3):
   var tile:=armor(root,[Vector4(.48,.025,-.32,0),Vector4(.55,.035,-.2,0),Vector4(.55,.03,.25,0),Vector4(.48,.02,.32,0)],ARMOR.lightened(i*.035),"OverlappingEnginePlate")
   tile.position=Vector3(0,at_y+.27,-.8+i*.72)
   for bolt_side in [-1,1]:block(root,Vector3(bolt_side*.44,at_y+.31,-.8+i*.72),Vector3(.045,.02,.045),DARK,"EngineFastener")
  for i in range(3):block(root,Vector3(.76,at_y,-.65+i*.43),Vector3(.05,.25,.20),DARK,"NacelleVent")
  block(root,Vector3(-.68,at_y+.21,.55),Vector3(.10,.04,.45),COPPER,"EngineHazardStripe")
 block(root,Vector3(0,0,.3),Vector3(.42,1.05,.6),DARK,"EnginePylon")
static func exhaust(parent: Node3D,_accent: Color) -> MeshInstance3D:
 armor(parent,[Vector4(.60,.26,.8,.08),Vector4(.64,.28,1.55,.08),Vector4(.52,.23,1.85,.08)],STEEL,"AftEngineCollar")
 block(parent,Vector3(0,.08,1.88),Vector3(.91,.36,.05),COPPER,"AftIonAperture")
 var engine:=armor(parent,[Vector4(.42,.14,0,0),Vector4(.44,.13,.18,0),Vector4(.30,.06,.65,0)],Color(1,.43,.06),"MainEngine")
 engine.position=Vector3(0,.08,1.9)
 var mat:=engine.material_override as StandardMaterial3D;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.emission_enabled=true;mat.emission=Color(1,.4,.04)
 return engine
