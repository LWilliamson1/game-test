shader_type spatial;

// Procedural roof tile / thatch shader.

uniform vec3 tile_color_1 : source_color = vec3(0.40, 0.18, 0.10);
uniform vec3 tile_color_2 : source_color = vec3(0.32, 0.14, 0.08);
uniform float tile_rows = 12.0;
uniform float tile_cols = 6.0;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.82;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 tile_uv = uv * vec2(tile_cols, tile_rows);

	// Offset every other row (like shingles)
	float row = floor(tile_uv.y);
	if (mod(row, 2.0) > 0.5) {
		tile_uv.x += 0.5;
	}

	vec2 tile_id = floor(tile_uv);
	vec2 tile_frac = fract(tile_uv);

	// Per-tile color variation
	float tile_hash = hash(tile_id);
	vec3 color = mix(tile_color_1, tile_color_2, tile_hash);

	// Shingle overlap shadow at top edge
	float overlap = smoothstep(0.0, 0.15, tile_frac.y);
	color *= 0.7 + overlap * 0.3;

	// Subtle weathering
	float weather = value_noise(uv * 20.0);
	color += (weather - 0.5) * 0.05;

	// Moss on some tiles
	float moss_chance = step(0.85, hash(tile_id + vec2(5.0)));
	float moss = value_noise(uv * 30.0) * moss_chance;
	color = mix(color, vec3(0.2, 0.3, 0.12), moss * 0.4);

	ALBEDO = color;
	ROUGHNESS = roughness_base;
}
