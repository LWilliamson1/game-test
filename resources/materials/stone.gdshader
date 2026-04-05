shader_type spatial;

// Procedural stone/brick shader with mortar lines and surface variation.

uniform vec3 stone_color_1 : source_color = vec3(0.50, 0.48, 0.44);
uniform vec3 stone_color_2 : source_color = vec3(0.58, 0.55, 0.50);
uniform vec3 mortar_color : source_color = vec3(0.65, 0.62, 0.55);
uniform float brick_scale_x = 4.0;
uniform float brick_scale_y = 8.0;
uniform float mortar_width : hint_range(0.01, 0.15) = 0.05;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.9;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.6;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * value_noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

// Returns 1.0 for mortar, 0.0 for stone face
float brick_pattern(vec2 uv, out vec2 brick_id) {
	vec2 scaled = uv * vec2(brick_scale_x, brick_scale_y);

	// Offset every other row
	float row = floor(scaled.y);
	if (mod(row, 2.0) > 0.5) {
		scaled.x += 0.5;
	}

	vec2 brick_uv = fract(scaled);
	brick_id = floor(scaled);

	// Mortar lines
	float mx = step(brick_uv.x, mortar_width) + step(1.0 - mortar_width, brick_uv.x);
	float my = step(brick_uv.y, mortar_width) + step(1.0 - mortar_width, brick_uv.y);

	return clamp(mx + my, 0.0, 1.0);
}

void fragment() {
	vec2 brick_id;
	float mortar = brick_pattern(UV, brick_id);

	// Per-brick color variation
	float brick_hash = hash(brick_id);
	vec3 stone = mix(stone_color_1, stone_color_2, brick_hash);

	// Surface noise for weathering
	float surface_noise = fbm(UV * 20.0);
	stone += (surface_noise - 0.5) * 0.08;

	// Dark crevice stains
	float stain = fbm(UV * 6.0 + vec2(42.0, 17.0));
	stone *= 1.0 - smoothstep(0.5, 0.7, stain) * 0.15;

	vec3 color = mix(stone, mortar_color, mortar);

	ALBEDO = color;
	ROUGHNESS = roughness_base + mortar * 0.05 - surface_noise * 0.05;

	// Fake normal from brick edges for depth
	vec2 scaled = UV * vec2(brick_scale_x, brick_scale_y);
	float row = floor(scaled.y);
	if (mod(row, 2.0) > 0.5) {
		scaled.x += 0.5;
	}
	vec2 brick_uv = fract(scaled);
	vec2 edge_normal = vec2(0.0);
	edge_normal.x = smoothstep(0.0, mortar_width * 2.0, brick_uv.x) - smoothstep(1.0 - mortar_width * 2.0, 1.0, brick_uv.x);
	edge_normal.y = smoothstep(0.0, mortar_width * 2.0, brick_uv.y) - smoothstep(1.0 - mortar_width * 2.0, 1.0, brick_uv.y);
	NORMAL = normalize(NORMAL + vec3(edge_normal * normal_strength, 0.0));
}
