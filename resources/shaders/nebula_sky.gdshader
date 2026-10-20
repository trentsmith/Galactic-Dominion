shader_type sky;
uniform float nebula_seed = 8.1;
uniform float comet_palette : hint_range(0.0,1.0) = 0.0;
uniform float moon_palette : hint_range(0.0,1.0) = 0.0;
float hash(vec3 p){p=fract(p*.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
float fbm(vec3 p){float n=0.,a=.5;for(int i=0;i<5;i++){n+=noise3(p)*a;p=p*2.03+vec3(7.1,3.2,1.7);a*=.5;}return n;}
void sky(){
 vec3 d=normalize(EYEDIR);
 float broad=fbm(d*3.2+nebula_seed);
 float fine=fbm(d*12.+broad*2.);
 float latitude=d.y+d.x*.33+sin(d.z*3.)*.14;
 float band=exp(-latitude*latitude*7.5);
 float wisps=smoothstep(.28,.80,broad+fine*.22)*band;
 float dust=smoothstep(.51,.74,fbm(d*7.+9.1))*band;
 vec3 color=vec3(.002,.005,.015);
 vec3 indigo=vec3(.15,.035,.20);
 vec3 teal=mix(vec3(.03,.08,.16),vec3(.42,.12,.035),smoothstep(.42,.72,broad));
 color+=mix(indigo,teal,smoothstep(.28,.7,fine))*wisps*1.20;
 float core=pow(max(dot(d,normalize(vec3(.6,.12,.7))),0.),20.);
 color+=vec3(.46,.16,.055)*core*band*(.4+broad);
 color*=1.-dust*.62;
 color+=vec3(.045,.075,.11)*pow(wisps,3.);
 vec2 grid=SKY_COORDS*vec2(1400.,700.);
 vec2 cell=floor(grid),o=fract(grid)-.5;
 float star=hash(vec3(cell,19.));
 if(star>.996){
  float pin=exp(-dot(o,o)*145.);
  vec3 hue=mix(vec3(1.,.79,.59),vec3(.59,.78,1.),hash(vec3(cell,7.)));
  color+=hue*pin*(.45+pow((star-.996)/.004,5.)*1.3);
 }
 vec2 big=SKY_COORDS*vec2(160.,80.),b=fract(big)-.5;
 float bright=hash(vec3(floor(big),41.));
 if(bright>.989){
  float glow=exp(-dot(b,b)*100.)*.25+exp(-dot(b,b)*900.)*1.3;
  color+=mix(vec3(1.,.82,.67),vec3(.58,.79,1.),bright)*glow;
 }
 color=mix(color,vec3(color.b*.85,color.g*.7,color.b*1.08),moon_palette);
 color=mix(color,vec3(color.b*1.1,color.b*.28+color.g*.35,color.b*.12),comet_palette);
 COLOR=color;
}
