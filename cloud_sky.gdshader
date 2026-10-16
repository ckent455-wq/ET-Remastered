shader_type sky;
uniform sampler2D panorama : source_color, filter_linear, repeat_enable;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;

void sky() {
	// Project onto a cloud ceiling: avoids stretched longitude bands at the poles.
	vec2 cloud_uv = EYEDIR.xz / max(EYEDIR.y + 0.28, 0.12) * 0.22 + vec2(0.5);
	float broad = texture(cloud_noise, cloud_uv).r;
	float detail = texture(cloud_noise, cloud_uv * 2.4 + vec2(0.14, 0.31)).r;
	float cloud = smoothstep(0.24, 0.78, broad * 0.78 + detail * 0.22);
	vec3 overcast = mix(vec3(0.15, 0.175, 0.165), vec3(0.29, 0.32, 0.30), cloud);
	// The reduced local panorama supplies broad illumination beneath the cloud deck.
	vec3 photographic = texture(panorama, SKY_COORDS).rgb;
	overcast = mix(overcast, photographic, 0.12);
	float altitude = smoothstep(-0.02, 0.42, EYEDIR.y);
	COLOR = mix(vec3(0.30, 0.34, 0.32), overcast, altitude);
}
