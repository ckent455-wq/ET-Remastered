shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, skip_vertex_transform, fog_disabled;
uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform vec3 eye_position = vec3(0.0);
uniform float opacity = 1.0;
varying vec3 world_position;

void vertex() {
	// Camera-facing wisps retain their particle scale without rotating the view.
	world_position = MODEL_MATRIX[3].xyz
		+ INV_VIEW_MATRIX[0].xyz * VERTEX.x * length(MODEL_MATRIX[0].xyz)
		+ INV_VIEW_MATRIX[1].xyz * VERTEX.y * length(MODEL_MATRIX[1].xyz);
	VERTEX = (VIEW_MATRIX * vec4(world_position, 1.0)).xyz;
}

void fragment() {
	// Exterior fog must not drift through the six furnished rooms or sealed shops.
	float x = abs(world_position.x);
	float z = world_position.z;
	bool west_room = world_position.x < 0.0 &&
		((z < -40.5 && z > -51.5) || (z < -53.5 && z > -64.5) || (z < -66.0 && z > -78.0));
	bool east_room = world_position.x > 0.0 &&
		((z < -40.0 && z > -52.0) || (z < -53.0 && z > -65.0) || (z < -66.5 && z > -77.5));
	if ((x > 6.42 && x < 16.6 && (west_room || east_room)) ||
		(x > 6.42 && x < 14.6 && z < -80.0 && z > -90.0) ||
		(world_position.x > 23.8 && world_position.x < 34.2 && z > -148.2 && z < -133.8)) {
		discard;
	}
	float edge = 1.0 - smoothstep(0.25, 1.0, length((UV - 0.5) * 2.0));
	float cloud = smoothstep(0.12, 0.88, texture(noise_texture, UV * 1.5).r);
	float near_fade = smoothstep(1.5, 4.0, distance(eye_position, world_position));
	float ground_fade = 1.0 - smoothstep(2.7, 4.2, world_position.y - max(0.0, eye_position.y - 1.25));
	ALBEDO = vec3(0.40, 0.445, 0.425);
	ALPHA = edge * cloud * near_fade * ground_fade * COLOR.a * opacity;
}
