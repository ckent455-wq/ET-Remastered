shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D ground_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec3 crest_color = vec3(0.22, 0.265, 0.25);
varying vec3 world_position;
varying float slope;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	slope = NORMAL.y;
}
void fragment() {
	// Painted aerial perspective keeps only subtle silhouettes beyond dense mist.
	float silhouette = smoothstep(1.0, 23.0, world_position.y);
	vec3 haze = vec3(0.30, 0.34, 0.32);
	float grain = texture(ground_texture, world_position.xz * 0.025).r - 0.45;
	ALBEDO = mix(haze, crest_color, silhouette) + (grain * 0.014 + slope * 0.008) * silhouette;
}
