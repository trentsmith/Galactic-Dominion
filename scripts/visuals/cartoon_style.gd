class_name CartoonStyle
extends RefCounted
const OUTLINE = preload("res://resources/shaders/cartoon_outline.gdshader")

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
 var result := StandardMaterial3D.new()
 result.albedo_color = color
 result.roughness = 0.30
 result.metallic = 0.65 if color.r > 0.75 and color.g > 0.3 and color.b < 0.35 else 0.06
 result.metallic_specular = 0.45
 result.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
 result.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
 if glow:
  result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  result.emission_enabled = true
  result.emission = color
  result.emission_energy_multiplier = 1.3
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
  panel.bg_color = Color(.055,.085,.11) if state == "normal" else Color(.10,.17,.20) if state == "hover" else Color(.08,.23,.24) if state == "pressed" else Color(.035,.055,.075)
  panel.border_color = Color(.64,.87,.80) if state in ["hover", "focus"] else Color(.19,.30,.35)
  panel.set_border_width_all(1)
  panel.set_corner_radius_all(8)
  panel.content_margin_left = 16
  panel.content_margin_right = 16
  panel.content_margin_top = 8
  panel.content_margin_bottom = 8
  theme.set_stylebox(state,"Button",panel)
  theme.set_stylebox(state,"OptionButton",panel)
 theme.set_color("font_color","Button",Color(0.94, 0.97, 1))
 theme.set_color("font_hover_color","Button",Color(1, 0.91, 0.62))
 return theme
