shader_type spatial;

// Terrain shader: blends grass and rock based on slope and height.
// Uses layered noise for natural-looking ground detail.

uniform vec3 grass_color_1 : source_color = vec3(0.22, 0.42, 0.12);
uniform vec3 grass_color_2 : source_color = vec3(0.28, 0.50, 0.15);
uniform vec3 rock_color_1 : source_color = vec3(0.40, 0.38, 0.34);
uniform vec3 rock_color_2 : source_color = vec3(0.50, 0.47, 0.42);
uniform vec3 dirt_color : source_color = vec3(0.45, 0.35, 0.22);
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float slope_blend : hint_range(0.01, 0.5) = 0.15;
uniform float height_snow_start = 10.0;
uniform float noise_scale = 8.0;
uniform float detail_scale = 32.0;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.85;

// Simple hash-based noise (no texture lookups needed)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * value_noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 world_uv = UV * noise_scale;

	// Noise layers
	float large_noise = fbm(world_uv, 4);
	float detail_noise = fbm(UV * detail_scale, 3);
	float combined_noise = large_noise * 0.7 + detail_noise * 0.3;

	// Slope from normal (Y component = how flat the surface is)
	float slope = 1.0 - NORMAL.y;
	float slope_factor = smoothstep(slope_threshold - slope_blend, slope_threshold + slope_blend, slope);

	// Grass with color variation
	vec3 grass = mix(grass_color_1, grass_color_2, combined_noise);
	// Add subtle dirt patches
	float dirt_mask = smoothstep(0.55, 0.65, fbm(world_uv * 0.5, 3));
	grass = mix(grass, dirt_color, dirt_mask * 0.4);

	// Rock with color variation
	vec3 rock = mix(rock_color_1, rock_color_2, detail_noise);

	// Blend grass and rock by slope
	vec3 color = mix(grass, rock, slope_factor);

	// Height-based snow tint at peaks
	float height_factor = smoothstep(height_snow_start, height_snow_start + 4.0, VERTEX.y);
	vec3 snow_color = vec3(0.92, 0.93, 0.95);
	color = mix(color, snow_color, height_factor * 0.7);

	ALBEDO = color;
	ROUGHNESS = roughness_base - detail_noise * 0.1;
	NORMAL_MAP_DEPTH = 0.3;
}
