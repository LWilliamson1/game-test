shader_type spatial;

// Procedural wood grain shader with rings, knots, and plank lines.

uniform vec3 wood_color_light : source_color = vec3(0.52, 0.36, 0.22);
uniform vec3 wood_color_dark : source_color = vec3(0.32, 0.20, 0.10);
uniform float grain_scale = 12.0;
uniform float ring_frequency = 20.0;
uniform float ring_noise = 2.0;
uniform float plank_count = 4.0;
uniform float plank_gap_width : hint_range(0.0, 0.05) = 0.015;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.75;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.4;

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
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;

	// Plank lines (vertical divisions)
	float plank_uv = uv.x * plank_count;
	float plank_id = floor(plank_uv);
	float plank_frac = fract(plank_uv);
	float plank_gap = step(plank_frac, plank_gap_width) + step(1.0 - plank_gap_width, plank_frac);

	// Per-plank offset for grain variation
	float plank_offset = hash(vec2(plank_id, 0.0)) * 10.0;

	// Wood grain: distorted rings running along Y axis
	vec2 grain_uv = vec2(uv.x * grain_scale + plank_offset, uv.y * grain_scale);
	float noise_warp = fbm(grain_uv * 0.3) * ring_noise;
	float ring = sin((grain_uv.y + noise_warp) * ring_frequency) * 0.5 + 0.5;

	// Tighten rings into lines
	ring = smoothstep(0.3, 0.7, ring);

	// Color blend
	vec3 wood = mix(wood_color_light, wood_color_dark, ring);

	// Subtle per-plank color shift
	float plank_tint = hash(vec2(plank_id, 1.0));
	wood = mix(wood, wood * 0.85, plank_tint * 0.3);

	// Surface detail noise
	float detail = fbm(uv * 40.0);
	wood += (detail - 0.5) * 0.04;

	// Knot (occasional dark spot)
	float knot_mask = 1.0 - smoothstep(0.08, 0.12, length(fract(uv * vec2(2.0, 3.0) + vec2(plank_offset)) - 0.5));
	knot_mask *= step(0.75, hash(vec2(plank_id, 3.0))); // Only some planks get knots
	wood = mix(wood, wood_color_dark * 0.6, knot_mask * 0.8);

	// Darken plank gaps
	vec3 gap_color = wood_color_dark * 0.3;
	vec3 color = mix(wood, gap_color, plank_gap);

	ALBEDO = color;
	ROUGHNESS = roughness_base + ring * 0.05 - detail * 0.05;

	// Fake grain normal
	float grain_bump = ring * normal_strength;
	NORMAL = normalize(NORMAL + vec3(0.0, grain_bump * 0.5, 0.0));
}
