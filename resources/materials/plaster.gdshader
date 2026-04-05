shader_type spatial;

// Procedural plaster/stucco wall shader with subtle cracks and weathering.

uniform vec3 plaster_color : source_color = vec3(0.85, 0.80, 0.70);
uniform vec3 stain_color : source_color = vec3(0.55, 0.50, 0.42);
uniform float noise_scale = 15.0;
uniform float crack_threshold : hint_range(0.0, 1.0) = 0.72;
uniform float weathering_amount : hint_range(0.0, 1.0) = 0.3;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.88;

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
	for (int i = 0; i < 5; i++) {
		v += a * value_noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

// Voronoi for crack pattern
float voronoi_cracks(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float min_dist = 1.0;
	float second_dist = 1.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = vec2(hash(i + neighbor), hash((i + neighbor) * 1.7));
			vec2 diff = neighbor + point - f;
			float d = length(diff);
			if (d < min_dist) {
				second_dist = min_dist;
				min_dist = d;
			} else if (d < second_dist) {
				second_dist = d;
			}
		}
	}
	return second_dist - min_dist;
}

void fragment() {
	vec2 uv = UV;

	// Base plaster texture - subtle bumpy surface
	float surface = fbm(uv * noise_scale);
	vec3 color = plaster_color + (surface - 0.5) * 0.06;

	// Weathering stains (concentrated at bottom and edges)
	float weather_noise = fbm(uv * 4.0 + vec2(7.0, 3.0));
	float bottom_weight = smoothstep(0.8, 1.0, uv.y); // More staining at bottom
	float weather = weather_noise * weathering_amount * (0.5 + bottom_weight);
	color = mix(color, stain_color, weather);

	// Cracks
	float cracks = voronoi_cracks(uv * 8.0);
	float crack_mask = 1.0 - smoothstep(0.0, 0.04, cracks);
	crack_mask *= step(crack_threshold, fbm(uv * 3.0)); // Only some areas have cracks
	color = mix(color, stain_color * 0.6, crack_mask * 0.7);

	ALBEDO = color;
	ROUGHNESS = roughness_base + surface * 0.06;
}
