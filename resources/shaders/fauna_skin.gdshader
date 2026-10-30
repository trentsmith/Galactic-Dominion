shader_type spatial;
render_mode cull_disabled;
uniform vec4 coat : source_color = vec4(.5,.4,.3,1.);
uniform vec4 marking : source_color = vec4(.9,.8,.6,1.);
uniform float pattern = 0.;
uniform float face_region = 0.;
uniform int skin_kind = 0;
varying vec3 local_pos;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){
 vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){local_pos=VERTEX;}
void fragment(){
 vec3 p=local_pos;
 float organic=noise(p*3.);
 float stripes=pow(.5+.5*sin(p.z*11.+organic*2.4),10.);
 float spots=smoothstep(.68,.87,noise(p*5.));
 float blend=pattern<.5?spots:stripes;
 float belly=1.-smoothstep(.55,1.15,p.y);
 float grain=noise(p*vec3(65.,110.,65.));
 float muzzle=(1.-smoothstep(-1.45,-.9,p.z))*(1.-smoothstep(1.35,1.62,p.y))*face_region;
 ALBEDO=mix(coat.rgb,marking.rgb,clamp(blend*.18+belly*.30+muzzle*.28,0.,.55))*(.96+grain*.07);
 ROUGHNESS=skin_kind==0?.82:skin_kind==1?.48:skin_kind==2?.64:.35;
 METALLIC=0.;SPECULAR=skin_kind==0?.25:.4;
 if(skin_kind==3){EMISSION=coat.rgb*.025;RIM=.13;RIM_TINT=.2;}
}
