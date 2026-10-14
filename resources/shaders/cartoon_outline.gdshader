shader_type spatial;
render_mode unshaded, cull_front;
uniform float thickness = 0.035;
uniform vec4 ink : source_color = vec4(0.065, 0.075, 0.16, 1.0);
void vertex() { VERTEX += NORMAL * thickness; }
void fragment() { ALBEDO = ink.rgb; }
