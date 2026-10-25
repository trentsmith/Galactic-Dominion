class_name EldritchArt
extends RefCounted
static func build(world: SurfaceWorld) -> void:
 var root:=Node3D.new();root.name="AbyssOssuary";world.add_child(root)
 # Ribbed mineral anatomy and a remote, asymmetric eye replace the toy-like head.
 for side in [-1,1]:
  for i in range(6):
   var x: float=side*(18+i*9)
   var z: float=-46-i*9
   var arch:=ArtGeometry.sweep(root,[Vector3(x,0,z),Vector3(x*1.06,14+i*2,z-3),Vector3(x*.8,29+i,z-8),Vector3(x*.45,34+i,z-5)],[3.2,2.3,1.3,.12],Color(.14,.19,.18),"OssuaryRib")
   stone(arch)
   for rib in range(4):
    var at:=Vector3(x*1.04,5+rib*4,z-1)
    var spur:=ArtGeometry.sweep(root,[at,at+Vector3(side*3,1,-1),at+Vector3(side*5,3,-2)],[.9,.5,.025],Color(.18,.21,.19),"VertebralSpur")
    stone(spur)
 for i in range(9):
  var rock:=SpaceModelFactory.mesh(root,SpaceEnvironmentArt.asteroid_mesh(800+i),Vector3(-32+i*8,20+sin(i)*6,-112),Color(.13,.17,.19),"FracturedCrown")
  rock.scale=Vector3(6,12+i%3*3,5);stone(rock)
 var eye:=Node3D.new();eye.name="AncientWatchingEye";eye.position=Vector3(9,42,-93);root.add_child(eye)
 SpaceModelFactory.ball(eye,Vector3.ZERO,Vector3(4,1.8,.9),Color(.04,.065,.06),"ObsidianSocket")
 SpaceModelFactory.ball(eye,Vector3(0,0,1),Vector3(1.1,1.15,.18),Color(.52,.65,.37),"PaleIris",true)
 SpaceModelFactory.ball(eye,Vector3(0,0,1.2),Vector3(.13,.95,.05),Color(.005,.01,.01),"VerticalPupil")
 for i in range(8):
  var x: float=-48+i*13
  var tendril:=ArtGeometry.sweep(root,[Vector3(x,0,-67),Vector3(x+4,6,-65),Vector3(x-2,10,-61),Vector3(x-5,13,-64)],[1.1,.65,.3,.015],Color(.11,.16,.16),"RootTendril")
  stone(tendril)
 # Warm, readable refuge contrasts with the cooler abyss. No jumpscares/flashing.
 for side in [-1,1]:
  var lamp:=OmniLight3D.new();lamp.position=Vector3(side*6,4,1);lamp.light_color=Color(.85,.75,.48);lamp.light_energy=2;lamp.omni_range=18;world.add_child(lamp)
static func stone(mesh: MeshInstance3D) -> void:
 var mat:=ShaderMaterial.new();mat.shader=preload("res://resources/shaders/eldritch_stone.gdshader");mesh.material_override=mat
