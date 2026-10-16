shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_disabled;
uniform float cloud_seed = 4.0;
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local=normalize(VERTEX);}
void fragment(){
 vec3 p=local*6.+vec3(cloud_seed,TIME*.001,0.);
 p.x+=sin(p.y*1.7)*.8;
 float n=noise3(p)*.58+noise3(p*2.1)*.28+noise3(p*5.3)*.14;
 float clouds=smoothstep(.57,.76,n);
 ALBEDO=vec3(.83,.88,.94);ALPHA=clouds*.36;ROUGHNESS=1.;
}
