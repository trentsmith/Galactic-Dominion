shader_type spatial;
render_mode cull_disabled;
uniform vec4 coat : source_color = vec4(.5,.4,.3,1.);
uniform vec4 marking : source_color = vec4(.9,.8,.6,1.);
uniform float pattern = 0.;
varying vec3 local_pos;
void vertex(){local_pos=VERTEX;}
void fragment(){
 vec3 p=local_pos;
 float stripes=pow(.5+.5*sin(p.z*18.+sin(p.y*9.)*1.8),12.);
 vec3 cell=fract(p*8.)-.5;
 float spots=1.-smoothstep(.10,.24,length(cell));
 float blend=pattern<.5?spots:stripes;
 float belly=1.-smoothstep(.35,.95,p.y);
 ALBEDO=mix(coat.rgb,marking.rgb,clamp(blend*.42+belly*.45,0.,.75));
 ROUGHNESS=.72;METALLIC=0.;
}
