shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec4 glow_color : source_color = vec4(.12,.46,.8,1);
void fragment(){
 float rim=pow(1.-max(dot(NORMAL,VIEW),0.),4.2);
 ALBEDO=glow_color.rgb;ALPHA=rim*.28;
}
