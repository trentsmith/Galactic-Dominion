shader_type spatial;
render_mode diffuse_toon, specular_disabled;
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local=VERTEX;}
void fragment(){
 float patches=noise3(local*3.0)*0.7+noise3(local*8.0)*0.3;
 vec3 rock=mix(vec3(0.14,0.11,0.19),vec3(0.54,0.36,0.25),smoothstep(0.2,0.8,patches));
 ALBEDO=rock;
 ROUGHNESS=0.95;
}
