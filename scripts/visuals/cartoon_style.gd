class_name CartoonStyle
extends RefCounted
const OUTLINE = preload("res://resources/shaders/cartoon_outline.gdshader")

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
 var result := StandardMaterial3D.new()
 result.albedo_color = color
 result.roughness = 0.9
 result.metallic = 0
 result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
 result.specular_mode = BaseMaterial3D.SPECULAR_TOON
 if glow:
  result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 elif color.a >= 0.99:
  var outline := ShaderMaterial.new()
  outline.shader = OUTLINE
  result.next_pass = outline
 return result

static func ball(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
 var mesh := SphereMesh.new()
 mesh.radius = 1
 mesh.height = 2
 mesh.radial_segments = 20
 mesh.rings = 12
 var node := MeshInstance3D.new()
 node.mesh = mesh
 node.position = at
 node.scale = dimensions
 node.material_override = material(color, glow)
 parent.add_child(node)
 return node

static func ui_theme() -> Theme:
 var theme := Theme.new()
 theme.default_font_size = 16
 for state in ["normal", "hover", "pressed", "focus", "disabled"]:
  var panel := StyleBoxFlat.new()
  panel.bg_color = Color(0.11, 0.16, 0.3) if state == "normal" else Color(0.19, 0.29, 0.46) if state == "hover" else Color(0.12, 0.32, 0.4) if state == "pressed" else Color(0.07, 0.1, 0.19)
  panel.border_color = Color(0.58, 0.85, 0.98) if state in ["hover", "focus"] else Color(0.27, 0.39, 0.59)
  panel.set_border_width_all(2)
  panel.set_corner_radius_all(12)
  panel.content_margin_left = 16
  panel.content_margin_right = 16
  panel.content_margin_top = 8
  panel.content_margin_bottom = 8
  theme.set_stylebox(state,"Button",panel)
  theme.set_stylebox(state,"OptionButton",panel)
 theme.set_color("font_color","Button",Color(0.94, 0.97, 1))
 theme.set_color("font_hover_color","Button",Color(1, 0.91, 0.62))
 return theme
