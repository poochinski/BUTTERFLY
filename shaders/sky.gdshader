shader_type sky;
render_mode use_debanding;

// A painted backdrop sky, like a hand-coloured theatre curtain: soft teal
// to pale cream, with gentle brush swirls. Paper clouds are real objects.

uniform vec3 zenith : source_color = vec3(0.16, 0.56, 0.7);
uniform vec3 horizon : source_color = vec3(0.72, 0.9, 0.9);
uniform vec3 ground : source_color = vec3(0.55, 0.62, 0.5);
uniform vec3 sun_tint : source_color = vec3(1.0, 0.93, 0.75);

float s_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float s_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(s_hash(i), s_hash(i + vec2(1.0, 0.0)), u.x),
		mix(s_hash(i + vec2(0.0, 1.0)), s_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void sky() {
	vec3 d = EYEDIR;
	float up = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon, zenith, pow(up, 0.6));
	// Brush strokes: stretched noise following the dome.
	float ang = atan(d.x, d.z);
	float strokes = s_noise(vec2(ang * 6.0, d.y * 22.0)) * 0.6 + s_noise(vec2(ang * 18.0, d.y * 60.0)) * 0.4;
	col *= 0.94 + strokes * 0.1;
	float sun = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += sun_tint * pow(sun, 24.0) * 0.35;
	if (d.y < 0.0) {
		col = mix(horizon, ground, smoothstep(0.0, -0.2, d.y));
	}
	COLOR = col;
}
