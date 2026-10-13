class_name SpaceEffects
extends RefCounted

static func burst(parent: Node, position: Vector3, color: Color, size: float = 4.0) -> void:
 var mesh := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 1.0
 sphere.height = 2.0
 mesh.mesh = sphere
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.albedo_color = color
 mesh.material_override = material
 parent.add_child(mesh)
 mesh.global_position = position
 mesh.scale = Vector3.ONE * 0.15
 var tween := mesh.create_tween().set_parallel(true)
 tween.tween_property(mesh, "scale", Vector3.ONE * size, 0.45)
 tween.tween_property(material, "albedo_color:a", 0.0, 0.45)
 tween.chain().tween_callback(mesh.queue_free)
