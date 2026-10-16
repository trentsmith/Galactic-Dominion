shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 tint : source_color = vec4(.15,.5,.65,1.);
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local=VERTEX;}
void fragment(){float fog=noise3(local*4.+vec3(TIME*.008,0,0))*.7+noise3(local*11.)*.3;float edge=pow(max(dot(NORMAL,VIEW),0.),2.);ALBEDO=tint.rgb*.45;ALPHA=smoothstep(.3,.75,fog)*edge*.18;}
