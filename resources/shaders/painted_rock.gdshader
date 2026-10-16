shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local=VERTEX;}
void fragment(){
 float strata=noise3(local*3.5)*.6+noise3(local*9.)*.4;
 float grain=noise3(local*43.);
 float fissure=smoothstep(.46,.53,abs(noise3(local*14.)-.5));
 vec3 stone=mix(vec3(.10,.12,.15),vec3(.34,.29,.25),strata);
 stone*=.78+grain*.35;
 stone=mix(stone,vec3(.17,.12,.09),fissure*.35);
 ALBEDO=stone;ROUGHNESS=.94;SPECULAR=.12;
 NORMAL=normalize(NORMAL+vec3(dFdx(grain),dFdy(grain),0.)*.24);
}
