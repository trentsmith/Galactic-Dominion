shader_type canvas_item;
void fragment(){float left=1.-smoothstep(.28,.82,UV.x);float edge=smoothstep(.18,.7,abs(UV.y-.5));COLOR=vec4(.012,.021,.035,clamp(left*.97+edge*.18,.08,.98));}
