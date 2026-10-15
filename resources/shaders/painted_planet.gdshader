shader_type spatial;
render_mode diffuse_toon, specular_disabled;
uniform vec4 ocean : source_color = vec4(0.015,0.10,0.33,1.0);
uniform vec4 land : source_color = vec4(0.09,0.36,0.7,1.0);
uniform vec4 cloud_color : source_color = vec4(0.37,0.77,1.0,1.0);
uniform float terrain_seed = 4.0;
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
float terrain(vec3 p){float n=0.0;float a=0.5;for(int i=0;i<5;i++){n+=noise3(p)*a;p=p*2.1+2.7;a*=0.5;}return n;}
void vertex(){local=normalize(VERTEX);}
void fragment(){
 float n=terrain(local*6.0+terrain_seed);
 float coast=smoothstep(0.43,0.51,n);
 vec3 base=mix(ocean.rgb,land.rgb,coast);
 float ridge=smoothstep(0.55,0.72,n);
 base=mix(base,land.rgb*0.55,ridge);
 float clouds=smoothstep(0.62,0.78,terrain(local*10.0+vec3(21,4,7)));
 base=mix(base,cloud_color.rgb,clouds*0.75);
 float fresnel=pow(1.0-max(dot(NORMAL,VIEW),0.0),3.0);
 ALBEDO=base;
 ROUGHNESS=0.9;
 EMISSION=cloud_color.rgb*(fresnel*0.65+clouds*0.035);
}
