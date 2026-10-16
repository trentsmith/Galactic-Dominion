shader_type spatial;
render_mode unshaded, cull_front;
uniform float thickness = 0.012;
uniform vec4 ink : source_color = vec4(0.025, 0.035, 0.065, 1.0);
void vertex() { VERTEX += NORMAL * thickness; }
void fragment() { ALBEDO = ink.rgb; }
