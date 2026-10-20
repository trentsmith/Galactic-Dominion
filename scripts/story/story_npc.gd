class_name StoryNPC
extends Node3D
## Original placeholder field hologram; also used as a comms portrait.
var npc_id := "milo"
const NAMES={"astra":"Commander Astra","milo":"Engineer Milo","sera":"Warden Sera"}
const COLORS={"astra":Color(.25,.65,.9),"milo":Color(1,.55,.2),"sera":Color(.6,.45,.85)}
func _ready() -> void:
 var color: Color=COLORS.get(npc_id,COLORS.milo)
 var torso:=CapsuleMesh.new();torso.radius=.48;torso.height=1.3
 part(torso,Vector3(0,1.25,0),color)
 var head:=SphereMesh.new();head.radius=.42;head.height=.84
 part(head,Vector3(0,2.25,0),Color(.88,.9,.86))
 var visor:=BoxMesh.new();visor.size=Vector3(.55,.2,.1)
 part(visor,Vector3(0,2.27,-.39),Color(.06,.16,.24),true)
 for side in [-1.0,1.0]:
  var limb:=CapsuleMesh.new();limb.radius=.15;limb.height=.85
  part(limb,Vector3(side*.64,1.25,0),color.lightened(.1)).rotation.z=side*.12
  part(limb,Vector3(side*.24,.42,0),Color(.15,.2,.25))
 var badge:=BoxMesh.new();badge.size=Vector3(.18,.18,.08)
 part(badge,Vector3(.22,1.5,-.46),Color(.4,1,1),true)
 var ring:=TorusMesh.new();ring.inner_radius=.75;ring.outer_radius=.8
 part(ring,Vector3(0,.04,0),color,true)
 var label:=Label3D.new();label.text=NAMES.get(npc_id,"Comms")+"\nO: COMMS & WORKSHOP";label.position.y=3.0;label.font_size=26;label.pixel_size=.009;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 add_child(label)
func part(mesh: Mesh,at: Vector3,color: Color,glow: bool=false) -> MeshInstance3D:
 var node:=MeshInstance3D.new();node.mesh=mesh;node.position=at;node.material_override=CartoonStyle.material(color,glow);add_child(node);return node
