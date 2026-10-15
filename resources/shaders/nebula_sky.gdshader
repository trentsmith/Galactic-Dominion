shader_type sky;
uniform float nebula_seed = 8.1;
uniform float moon_palette : hint_range(0.0,1.0) = 0.0;
float hash(vec3 p) { p=fract(p*0.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z); }
float noise3(vec3 p) {
 vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p) { float value=0.0;float amp=0.5;for(int i=0;i<5;i++){value+=amp*noise3(p);p=p*2.03+vec3(7.1,3.2,1.7);amp*=0.5;}return value; }
void sky() {
 vec3 d=normalize(EYEDIR);
 float ribbon=exp(-pow(d.y*1.8+d.x*0.65+sin(d.z*3.0)*0.36,2.0)*3.8);
 float cloud=fbm(d*4.2+nebula_seed);
 float detail=fbm(d*13.0+vec3(cloud*3.0));
 float density=smoothstep(0.35,0.80,cloud+detail*0.23)*ribbon;
 vec3 color=vec3(0.0015,0.004,0.022);
 color+=mix(vec3(0.025,0.018,0.16),vec3(0.008,0.25,0.80),detail)*density*1.45;
 color+=vec3(0.005,0.20,0.42)*pow(density,2.8);
 vec2 grid=SKY_COORDS*vec2(1100.0,550.0);
 vec2 cell=floor(grid);vec2 offset=fract(grid)-vec2(0.5);
 float choice=hash(vec3(cell,19.0));
 float pin=1.0-smoothstep(0.015,0.095,length(offset));
 if(choice>0.991)color+=vec3(0.48,0.72,1.0)*pin*(0.4+choice);
 vec2 big=SKY_COORDS*vec2(150.0,75.0);vec2 b=fract(big)-0.5;
 float bright=hash(vec3(floor(big),41.0));
 if(bright>0.974){
  float core=0.0017/(dot(b,b)+0.0009);
  float rays=0.00035/(abs(b.x*b.y)+0.00035)*exp(-length(b)*12.0);
  color+=vec3(0.38,0.77,1.0)*(core+rays*0.65);
 }
 color=mix(color,vec3(color.b*0.78,color.g*0.55,color.b),moon_palette);
 COLOR=color;
}
