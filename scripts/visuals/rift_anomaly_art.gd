class_name RiftAnomalyArt
extends RefCounted
static func build(parent: Node3D,at: Vector3) -> Node3D:
 var root:=Node3D.new();root.name="DreamingRiftAnomaly";root.position=at;parent.add_child(root)
 var quad:=QuadMesh.new();quad.size=Vector2(1000,1000)
 var visual:=MeshInstance3D.new();visual.name="EmberRift";visual.mesh=quad
 var material:=ShaderMaterial.new();material.shader=preload("res://resources/shaders/rift_anomaly.gdshader");visual.material_override=material;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 visual.visibility_range_end=7500;root.add_child(visual)
 var light:=OmniLight3D.new();light.omni_range=1200;light.light_color=Color(1,.28,.07);light.light_energy=2;root.add_child(light)
 for side in [-1,1]:
  var points: Array[Vector3]=[]
  for i in range(8):points.append(Vector3(side*(390+sin(i*3.4)*23),350-i*90,40+sin(i*1.7)*20))
  var filament:=ArtGeometry.sweep(root,points,[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0],Color(.65,.25,1),"VioletEnergyFilament")
  var glow:=filament.material_override as StandardMaterial3D;glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.next_pass=null;glow.emission_enabled=true;glow.emission=Color(.65,.25,1)
 return root
