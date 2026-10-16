shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 ocean : source_color = vec4(.008,.035,.09,1);
uniform vec4 land : source_color = vec4(.12,.4,.4,1);
uniform vec4 cloud_color : source_color = vec4(.75,.85,.92,1);
uniform float terrain_seed = 4.0;
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*f*(f*(f*6.-15.)+10.);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
float terrain(vec3 p){float n=0.;float a=.5;for(int i=0;i<5;i++){n+=noise3(p)*a;p=p*2.03+2.7;a*=.5;}return n;}
void vertex(){local=normalize(VERTEX);}
void fragment(){
 vec3 p=local*3.3+terrain_seed;
 float n=terrain(p+vec3(terrain(p+10.)*.8));
 float coast=smoothstep(.44,.48,n);
 float shallows=smoothstep(.36,.46,n);
 vec3 sea=mix(ocean.rgb,land.rgb*vec3(.5,.85,1.1),shallows*.6);
 vec3 soil=mix(land.rgb*.5,land.rgb*1.15,smoothstep(.45,.66,n));
 float alpine=smoothstep(.65,.73,n);
 soil=mix(soil,vec3(.71,.76,.68),alpine*.5);
 vec3 base=mix(sea,soil,coast);
 float ice=smoothstep(.83,.98,abs(local.y)+noise3(local*9.)*.08);
 base=mix(base,cloud_color.rgb*.85,ice*.75);
 float swirls=terrain(local*5.5+vec3(11.0,terrain_seed*.1,7.0));
 float clouds=smoothstep(.56,.7,swirls+noise3(local*19.)*.08);
 base=mix(base,cloud_color.rgb,clouds*.8);
 float fresnel=pow(1.-max(dot(NORMAL,VIEW),0.),4.);
 ALBEDO=base;ROUGHNESS=mix(.24,.87,max(coast,clouds));METALLIC=.02;
 EMISSION=cloud_color.rgb*fresnel*.17;
}
