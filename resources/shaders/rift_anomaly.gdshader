shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_opaque;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void fragment(){
 vec2 p=(UV-.5)*2.;float r=length(p);float a=atan(p.y,p.x);
 float turbulence=noise2(vec2(a*5.,TIME*.16))*0.07+noise2(p*17.+TIME*.07)*.035;
 float edge=.62+turbulence;
 float rim=exp(-abs(r-edge)*75.);
 float fire=exp(-abs(r-edge-.04)*17.)*noise2(p*23.+vec2(TIME*.13,0));
 float halo=exp(-abs(r-edge)*7.)*.22;
 float inside=1.-smoothstep(edge-.015,edge,r);
 float strands=pow(noise2(vec2(p.x*30.,p.y*1.8-TIME*.2)),6.)*inside;
 vec3 glow=vec3(1.,.28,.035)*(rim+fire*.7+halo)+vec3(.26,.045,.65)*strands;
 ALBEDO=vec3(.003,.001,.008)*inside+glow;EMISSION=glow*1.4;
 ALPHA=clamp(inside+rim+fire+halo*.7,0.,1.)*smoothstep(1.,.88,r);
}
