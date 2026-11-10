shader_type canvas_item;

// Full-screen painterly pass: Kuwahara brush strokes, gentle edge wobble,
// pigment pooling at edges, paper grain and a warm vignette.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D paper_tex : repeat_enable, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform int radius = 3;
uniform float wobble = 1.6;
uniform float edge_darkening = 0.35;
uniform float grain = 0.12;
uniform float vignette = 0.25;

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float aspect = px.y / px.x;
	vec2 puv = SCREEN_UV * vec2(aspect, 1.0);
	vec2 uv = SCREEN_UV;
	vec3 original = texture(screen_tex, uv).rgb;

	vec2 wob = vec2(texture(paper_tex, puv * 1.3).r, texture(paper_tex, puv * 1.3 + vec2(0.37, 0.71)).r) - 0.5;
	uv += wob * px * wobble * 4.0;

	// Kuwahara: pick the calmest of four quadrants.
	vec3 mean[4];
	vec3 sq[4];
	for (int k = 0; k < 4; k++) {
		mean[k] = vec3(0.0);
		sq[k] = vec3(0.0);
	}
	for (int j = 0; j <= radius; j++) {
		for (int i = 0; i <= radius; i++) {
			vec2 o = vec2(float(i), float(j)) * px;
			vec3 c0 = texture(screen_tex, uv + vec2(-o.x, -o.y)).rgb;
			vec3 c1 = texture(screen_tex, uv + vec2(o.x, -o.y)).rgb;
			vec3 c2 = texture(screen_tex, uv + vec2(-o.x, o.y)).rgb;
			vec3 c3 = texture(screen_tex, uv + vec2(o.x, o.y)).rgb;
			mean[0] += c0; sq[0] += c0 * c0;
			mean[1] += c1; sq[1] += c1 * c1;
			mean[2] += c2; sq[2] += c2 * c2;
			mean[3] += c3; sq[3] += c3 * c3;
		}
	}
	float n = float((radius + 1) * (radius + 1));
	float best = 1e9;
	vec3 col = original;
	for (int k = 0; k < 4; k++) {
		vec3 m = mean[k] / n;
		vec3 v = abs(sq[k] / n - m * m);
		float s = v.r + v.g + v.b;
		if (s < best) {
			best = s;
			col = m;
		}
	}

	// Pigment pooling along edges.
	float lx = lum(texture(screen_tex, uv + vec2(px.x * 2.0, 0.0)).rgb) - lum(texture(screen_tex, uv - vec2(px.x * 2.0, 0.0)).rgb);
	float ly = lum(texture(screen_tex, uv + vec2(0.0, px.y * 2.0)).rgb) - lum(texture(screen_tex, uv - vec2(0.0, px.y * 2.0)).rgb);
	float edge = clamp(length(vec2(lx, ly)) * 2.5, 0.0, 1.0);
	col *= 1.0 - edge * edge_darkening * 0.6;

	// Paper grain and a slightly warm, soft-lifted palette.
	float p = texture(paper_tex, puv * 3.5).r;
	float p2 = texture(paper_tex, puv * 11.0).r;
	col *= 1.0 - grain * ((p - 0.5) * 0.8 + (p2 - 0.5) * 0.6);
	col = mix(col, col * vec3(1.03, 1.0, 0.95) + vec3(0.015, 0.01, 0.0), 0.6);
	float l = lum(col);
	col = mix(vec3(l), col, 1.08);

	vec2 vc = SCREEN_UV - 0.5;
	col *= 1.0 - dot(vc, vc) * vignette;

	COLOR = vec4(mix(original, col, strength), 1.0);
}
