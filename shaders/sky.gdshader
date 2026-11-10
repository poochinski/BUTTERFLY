shader_type sky;
render_mode use_debanding;

// Painterly sky with a day → golden hour → night palette, a soft sun, drifting
// domain-warped clouds lit from the sun side, and stars at night.

uniform vec3 sun_dir = vec3(0.0, 0.2, -1.0);
uniform float cloud_time = 0.0;
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.42;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

vec3 to_linear(vec3 c) {
	return pow(max(c, vec3(0.0)), vec3(2.2));
}

void sky() {
	vec3 d = EYEDIR;
	vec3 sd = normalize(sun_dir);
	float e = sd.y;
	float day = smoothstep(0.06, 0.62, e);
	float night = smoothstep(0.02, -0.22, e);
	float dusk = (1.0 - day) * (1.0 - night);

	vec3 zen_day = vec3(0.25, 0.46, 0.84);
	vec3 hor_day = vec3(0.7, 0.82, 0.94);
	vec3 zen_dusk = vec3(0.3, 0.42, 0.76);
	vec3 hor_dusk_sun = vec3(1.0, 0.66, 0.38);
	vec3 hor_dusk_away = vec3(0.88, 0.68, 0.8);
	vec3 zen_night = vec3(0.012, 0.02, 0.06);
	vec3 hor_night = vec3(0.05, 0.07, 0.15);

	vec2 dxz = d.xz;
	vec2 sxz = sd.xz;
	float toward = 0.5;
	if (length(dxz) > 0.001 && length(sxz) > 0.001) {
		toward = dot(normalize(dxz), normalize(sxz)) * 0.5 + 0.5;
	}
	float up = clamp(d.y, 0.0, 1.0);
	float hgrad = pow(1.0 - up, 2.6);

	vec3 zen = mix(mix(zen_dusk, zen_day, day), zen_night, night);
	vec3 hor_dusk = mix(hor_dusk_away, hor_dusk_sun, pow(toward, 2.2));
	vec3 hor = mix(mix(hor_dusk, hor_day, day), hor_night, night);
	vec3 col = mix(zen, hor, hgrad);

	// Sun disc and glow.
	float cosang = max(dot(d, sd), 0.0);
	vec3 suncol = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.95, 0.86), day);
	float glow = pow(cosang, 48.0) * 0.9 + pow(cosang, 5.0) * 0.32 * (dusk * 1.6 + 0.2);
	col += suncol * glow * (1.0 - night);
	float disk = smoothstep(0.9990, 0.9995, cosang);
	col = mix(col, suncol * 6.0, disk * (1.0 - night));

	// Below the horizon: hazy ground colour that the fog blends into.
	if (d.y < 0.0) {
		col = mix(hor, hor * vec3(0.7, 0.68, 0.72), smoothstep(0.0, -0.4, d.y));
	}

	// Clouds (skipped while baking the ambient-light cubemap).
	if (!AT_CUBEMAP_PASS && d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.1) * 0.55 + cloud_time * vec2(0.006, 0.0025);
		vec2 q = vec2(fbm(uv * 0.8), fbm(uv * 0.8 + vec2(5.2, 1.3))) - 0.5;
		vec2 toward_sun = length(sxz) > 0.001 ? normalize(sxz) : vec2(0.0, 1.0);
		float c = clamp((fbm(uv * 1.6 + q * 1.3) - 0.5) * 2.4 + 0.5, 0.0, 1.0);
		float c2 = clamp((fbm(uv * 1.6 + q * 1.3 + toward_sun * 0.09) - 0.5) * 2.4 + 0.5, 0.0, 1.0);
		float edge = 1.0 - cloud_cover;
		float cov = smoothstep(edge - 0.06, edge + 0.2, c) * smoothstep(0.0, 0.22, d.y);
		float thick = smoothstep(edge, 1.0, c);
		float lit = clamp(0.62 + (c - c2) * 2.6, 0.0, 1.0);
		vec3 cl_lit = mix(vec3(1.3, 0.86, 0.68), vec3(1.12, 1.1, 1.06), day);
		vec3 cl_dark = mix(vec3(0.7, 0.58, 0.8), vec3(0.74, 0.79, 0.9), day);
		cl_lit = mix(cl_lit, vec3(0.1, 0.11, 0.16), night);
		cl_dark = mix(cl_dark, vec3(0.04, 0.05, 0.09), night);
		vec3 ccol = mix(cl_dark, cl_lit, lit * (1.0 - thick * 0.45));
		ccol += suncol * pow(cosang, 4.0) * (1.0 - thick) * 1.1 * (1.0 - night);
		col = mix(col, ccol, cov * 0.95);
	}

	// Stars.
	if (night > 0.0 && d.y > 0.0) {
		vec3 sp = d * 220.0;
		vec2 cell = floor(sp.xz / (sp.y * 0.004 + 1.0));
		float h = hash(cell);
		float star = step(0.9965, h) * (0.5 + 0.5 * sin(TIME * 2.0 + h * 50.0));
		col += vec3(0.9, 0.92, 1.0) * star * night * night * smoothstep(0.05, 0.3, d.y);
	}

	// Palette above is authored in sRGB; the sun disc stays HDR-bright.
	COLOR = to_linear(min(col, vec3(1.0))) + max(col - vec3(1.0), vec3(0.0)) * 2.0;
}
