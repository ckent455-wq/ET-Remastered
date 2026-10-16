shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.3,0.29,0.20,1.0);
uniform float variation = 0.0;
uniform float opacity = 0.75;
uniform bool ceiling_ring = false;
uniform bool runoff = false;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 uv=floor(UV*128.0)/128.0;
 vec2 q=(uv-0.5)*2.0;
 float n=noise(uv*8.0+variation);
 float fine=noise(uv*36.0+variation);
 float edge=1.0-smoothstep(0.50,1.0,length(q)+n*0.27);
 float streak=noise(vec2(uv.x*29.0,uv.y*2.5)+variation);
 float body=mix(n,streak,0.55);
 float ring=ceiling_ring ? (0.42+0.58*smoothstep(0.25,0.68,length(q)+n*0.12)) : 1.0;
 ALBEDO=tint.rgb*mix(0.65,1.22,fine);
 ROUGHNESS=0.96;
 float drips=runoff ? smoothstep(0.62,0.78,noise(vec2(uv.x*31.0+variation,1.0)))*smoothstep(0.12,0.32,uv.y)*(1.0-smoothstep(0.68,0.98,uv.y))*(1.0-smoothstep(0.4,0.8,abs(q.x))) : 0.0;
 ALPHA=max(edge*mix(0.30,1.0,body)*ring,drips*0.65)*opacity;
 ALPHA_SCISSOR_THRESHOLD=0.14;
}
