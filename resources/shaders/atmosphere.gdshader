shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec4 glow_color : source_color = vec4(0.05,0.45,1.0,1.0);
void fragment(){float rim=pow(1.0-max(dot(NORMAL,VIEW),0.0),3.2);ALBEDO=glow_color.rgb;ALPHA=rim*0.45;}
