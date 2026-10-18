shader_type spatial;
render_mode cull_back;
varying vec3 world;
varying vec3 wall_normal;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*0.58+noise(p*2.1)*0.28+noise(p*4.2)*0.14;}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wall_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);}
void fragment(){
 vec2 p=abs(wall_normal.x)>0.5?world.zy:world.xy;
 if(abs(wall_normal.y)>0.5){p=world.xz;}
 float grain=noise(p*80.0);
 vec3 paper=vec3(0.73,0.70,0.60)*(0.96+grain*0.06);
 // Faded narrow stripes and small repeating diamonds beneath the damage.
 float stripe=pow(0.5+0.5*cos(p.x*38.0),18.0);
 vec2 motif=abs(fract(p*vec2(2.5,3.5))-0.5);
 float diamond=1.0-smoothstep(0.10,0.14,motif.x+motif.y);
 paper=mix(paper,vec3(0.54,0.56,0.45),stripe*0.12+diamond*0.12);
 float patches=fbm(p*vec2(1.6,1.1)+vec2(19.3,7.2));
 float seep=fbm(p*vec2(5.0,0.55)+vec2(7.0,3.0));
 float stain=smoothstep(0.58,0.79,patches+seep*0.13);
 float edge=smoothstep(0.56,0.64,patches+seep*0.13)-smoothstep(0.64,0.73,patches+seep*0.13);
 paper=mix(paper,vec3(0.51,0.44,0.32),stain*0.28);
 paper=mix(paper,vec3(0.48,0.36,0.23),edge*0.08);
 float floor_height=world.y>3.4?3.45:0.22;
 float damp=(1.0-smoothstep(0.0,0.38,world.y-floor_height))*smoothstep(0.35,0.7,fbm(p*3.0));
 paper=mix(paper,vec3(0.32,0.34,0.25),damp*0.18);
 float worn=smoothstep(0.72,0.80,fbm(p*5.0+31.0));
 paper=mix(paper,vec3(0.60,0.58,0.51),worn*0.45);
 ALBEDO=paper; ROUGHNESS=0.98; SPECULAR=0.05;
}
