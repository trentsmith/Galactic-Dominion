shader_type spatial;
render_mode cull_disabled;
uniform vec4 stone : source_color = vec4(.12,.17,.18,1.);
varying vec3 p;
float hash(vec3 v){return fract(sin(dot(v,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 v){
 vec3 i=floor(v);vec3 f=fract(v);f=f*f*(3.-2.*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){p=VERTEX;}
void fragment(){
 float grain=noise(p*2.)*.6+noise(p*9.)*.25+noise(p*35.)*.15;
 float veins=pow(1.-abs(noise(p*.7)*2.-1.),18.);
 ALBEDO=stone.rgb*(.55+grain*.8)+vec3(.03,.05,.045)*veins;
 ROUGHNESS=.86+grain*.1;
 EMISSION=vec3(.008,.025,.018)*veins;
}
