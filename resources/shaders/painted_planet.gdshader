shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 ocean : source_color = vec4(.008,.035,.09,1);
uniform vec4 land : source_color = vec4(.12,.4,.4,1);
uniform vec4 cloud_color : source_color = vec4(.75,.85,.92,1);
uniform float terrain_seed = 4.0;
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*f*(f*(f*6.-15.)+10.);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
float terrain(vec3 p){float n=0.,a=.5;for(int i=0;i<6;i++){n+=noise3(p)*a;p=p*2.03+2.7;a*=.5;}return n;}
void vertex(){local=normalize(VERTEX);}
void fragment(){
 vec3 p=local*3.8+terrain_seed;
 float n=terrain(p+vec3(terrain(p+10.)*.9));
 float coast=smoothstep(.485,.50,n);
 float shelf=smoothstep(.44,.49,n)*(1.-smoothstep(.49,.51,n));
 vec3 sea=ocean.rgb+vec3(.012,.12,.14)*shelf;
 float ridge=1.-abs(noise3(p*12.)*2.-1.);
 vec3 soil=mix(land.rgb*.64,land.rgb*1.28,smoothstep(.48,.66,n));
 soil*=.82+ridge*.22;
 float alpine=smoothstep(.65,.74,n)*smoothstep(.6,.9,ridge);
 soil=mix(soil,vec3(.65,.68,.62),alpine*.6);
 vec3 base=mix(sea,soil,coast);
 float ice=smoothstep(.90,.99,abs(local.y)+noise3(local*17.)*.025);
 base=mix(base,cloud_color.rgb*.75,ice*.75);
 // Small warm settlement clusters emerge on the dark hemisphere.
 float night=1.-smoothstep(-.2,.1,dot(local,normalize(vec3(-.6,.5,-.8))));
 float clusters=smoothstep(.76,.87,noise3(local*180.))*smoothstep(.56,.69,noise3(local*24.+terrain_seed))*coast;
 ALBEDO=base;ROUGHNESS=mix(.43,.9,coast);METALLIC=.01;SPECULAR=.18;
 EMISSION=vec3(1.,.55,.22)*clusters*night*.10;
}
