shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform vec4 ground_color : source_color = vec4(0.1,0.15,0.15,1.0);
uniform int biome = 0;
varying vec3 local_position;
float hash2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash2(i),hash2(i+vec2(1,0)),f.x),mix(hash2(i+vec2(0,1)),hash2(i+vec2(1,1)),f.x),f.y);}
void vertex(){local_position=VERTEX;}
void fragment(){
 float broad=noise2(local_position.xz*.13);
 float detail=noise2(local_position.xz*1.8);
 vec3 patch=biome==0?vec3(.045,.14,.12):(biome==1?vec3(.22,.38,.30):vec3(.30,.24,.17));
 ALBEDO=mix(ground_color.rgb,patch,smoothstep(.40,.78,broad)*.65)*(0.84+detail*.30);
 ROUGHNESS=1.0;
 EMISSION=vec3(.01,.025,.025)*smoothstep(.82,.96,detail)*broad;
}
