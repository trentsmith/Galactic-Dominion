shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_disabled;
uniform vec4 ring_tint : source_color = vec4(.68,.61,.51,1);
void fragment(){
 float t=UV.y;
 float bands=.45+.17*sin(t*95.)+.06*sin(t*310.)*exp(-fwidth(t)*400.);
 float gap=1.-smoothstep(.007,.016,abs(t-.61));
 float edge=smoothstep(0.,.06,t)*(1.-smoothstep(.94,1.,t));
 ALBEDO=ring_tint.rgb*(.7+bands*.5);ROUGHNESS=.95;
 ALPHA=edge*(.22+bands*.45)*(1.-gap*.94);
}
