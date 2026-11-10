// The PAPERCUT material: one shader for every craft supply in the game.
// kind: 0 cardboard · 1 paper · 2 felt · 3 knit yarn · 4 masking tape
//       5 plastic (buttons, caps) · 6 foil · 7 glowing paper
// pattern: 0 none · 1 hazard stripes · 2 dots · 3 checker tiles
//          4 window grid · 5 stitched border · 6 horizontal bands
// Boxes are unit BoxMeshes scaled by their node, so the shader recovers each
// box's real size to wear its edges and draw corrugated cut edges.

uniform int kind = 0;
uniform vec4 color : source_color = vec4(0.78, 0.6, 0.42, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int pattern = 0;
uniform float pattern_scale = 1.0;
uniform float wear = 1.0;
uniform float bumps = 1.0;
uniform bool box_edges = true;

varying vec3 v_local;
varying vec3 v_lnormal;
varying vec3 v_scale;

#ifdef VIEWMODEL
global uniform float vm_fov_scale;
#endif

float c_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float c_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(c_hash(i), c_hash(i + vec2(1.0, 0.0)), u.x),
		mix(c_hash(i + vec2(0.0, 1.0)), c_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec3 c_lin(vec3 c) {
	return pow(max(c, vec3(0.0)), vec3(2.2));
}

vec2 c_rot(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

void vertex() {
	v_local = VERTEX;
	v_lnormal = NORMAL;
	v_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
#ifdef VIEWMODEL
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION.xy *= vm_fov_scale;
	POSITION.z = POSITION.w - (POSITION.w - POSITION.z) * 0.02;
#endif
}

void fragment() {
	vec3 n = normalize(v_lnormal);
	vec3 an = abs(n);
	vec3 p = v_local * v_scale;
	vec2 uv;
	vec2 half_ext;
	if (an.x > an.y && an.x > an.z) {
		uv = p.zy;
		half_ext = v_scale.zy * 0.5;
	} else if (an.y > an.z) {
		uv = p.xz;
		half_ext = v_scale.xz * 0.5;
	} else {
		uv = p.xy;
		half_ext = v_scale.xy * 0.5;
	}
	float edge = 1000.0;
	float thin = 1000.0;
	if (box_edges) {
		edge = min(half_ext.x - abs(uv.x), half_ext.y - abs(uv.y));
		thin = min(half_ext.x, half_ext.y) * 2.0;
	}

	vec3 base = color.rgb;

	// Printed / painted patterns.
	if (pattern == 1) {
		float s = step(0.5, fract((uv.x + uv.y) * 1.6 * pattern_scale));
		base = mix(base, color2.rgb, s);
	} else if (pattern == 2) {
		vec2 g = fract(uv * 4.0 * pattern_scale) - 0.5;
		base = mix(base, color2.rgb, 1.0 - smoothstep(0.17, 0.21, length(g)));
	} else if (pattern == 3) {
		vec2 g = uv * pattern_scale;
		vec2 gi = floor(g);
		base = mix(base, color2.rgb, mod(gi.x + gi.y, 2.0));
		vec2 gf = abs(fract(g) - 0.5);
		base *= mix(0.75, 1.0, smoothstep(0.47, 0.44, max(gf.x, gf.y)));
	} else if (pattern == 4) {
		vec2 g = fract(uv * pattern_scale);
		float w = step(0.22, g.x) * step(g.x, 0.78) * step(0.28, g.y) * step(g.y, 0.82);
		base = mix(base, color2.rgb, w);
	} else if (pattern == 5) {
		float sd = abs(edge - 0.045 * pattern_scale);
		float dash = step(0.45, fract((abs(uv.x) + abs(uv.y)) * 9.0 / pattern_scale));
		base = mix(base, color2.rgb, (1.0 - smoothstep(0.006, 0.011, sd)) * dash);
	} else if (pattern == 6) {
		base = mix(base, color2.rgb, step(0.5, fract(p.y * pattern_scale)));
	}

	float h = 0.0;
	float rough = 0.85;
	float spec = 0.3;
	float metal = 0.0;
	float rim = 0.0;
	vec3 emit = vec3(0.0);

	if (kind == 0) {
		float fib = c_noise(uv * vec2(40.0, 4.0)) * 0.5 + c_noise(uv * 90.0) * 0.5;
		base *= 0.9 + 0.2 * fib;
		h = (c_noise(uv * 7.0) - 0.5) * 0.004 * bumps;
		vec3 kraft = c_lin(vec3(0.8, 0.62, 0.42)) * (0.88 + 0.18 * fib);
		float worn = wear * (1.0 - smoothstep(0.0, 0.03 + 0.04 * c_noise(uv * 6.0), edge));
		base = mix(base, kraft, worn);
		if (thin < 0.07) {
			bool along_x = half_ext.x > half_ext.y;
			float along = along_x ? uv.x : uv.y;
			float across = along_x ? uv.y / max(half_ext.y, 0.001) : uv.x / max(half_ext.x, 0.001);
			float liner = step(0.74, abs(across));
			float wv = 1.0 - smoothstep(0.08, 0.24, abs(across - sin(along * 180.0) * 0.55));
			base = mix(kraft * 0.3, kraft * 1.05, max(liner, wv));
		}
		rough = 0.88;
	} else if (kind == 1) {
		float fib = c_noise(uv * 120.0) * 0.6 + c_noise(uv * 15.0) * 0.4;
		base *= 0.93 + 0.12 * fib;
		h = (c_noise(uv * 10.0) - 0.5) * 0.002 * bumps;
		base *= mix(0.8, 1.0, smoothstep(0.0, 0.02, edge));
		rough = 0.92;
		spec = 0.25;
	} else if (kind == 2) {
		float f1 = c_noise(uv * 160.0);
		float f2 = c_noise(uv * 35.0);
		base *= 0.82 + 0.28 * (f1 * 0.6 + f2 * 0.4);
		h = (f1 - 0.5) * 0.0015 * bumps;
		rough = 1.0;
		spec = 0.12;
		rim = 0.55;
	} else if (kind == 3) {
		vec2 k = uv * vec2(10.0, 12.0) * pattern_scale;
		vec2 cell = fract(k);
		vec2 q1 = c_rot(cell - vec2(0.28, 0.5), 0.55);
		vec2 q2 = c_rot(cell - vec2(0.72, 0.5), -0.55);
		float e = max(1.0 - length(q1 * vec2(3.4, 1.35)), 1.0 - length(q2 * vec2(3.4, 1.35)));
		e = clamp(e, 0.0, 1.0);
		base *= 0.42 + 0.7 * smoothstep(0.0, 0.55, e);
		base *= 0.9 + 0.16 * c_noise(uv * 220.0);
		base *= 0.92 + 0.12 * c_hash(floor(k.yy));
		h = e * 0.01 * bumps;
		rough = 1.0;
		spec = 0.1;
		rim = 0.4;
	} else if (kind == 4) {
		base *= 0.94 + 0.12 * c_noise(uv * vec2(8.0, 70.0));
		h = (c_noise(uv * vec2(6.0, 30.0)) - 0.5) * 0.002;
		rough = 0.42;
		spec = 0.45;
	} else if (kind == 5) {
		rough = 0.22;
		spec = 0.65;
	} else if (kind == 6) {
		h = (c_noise(uv * 26.0) - 0.5) * 0.006;
		metal = 0.85;
		rough = 0.3;
	} else if (kind == 7) {
		emit = base * 2.2;
	}

	if (h != 0.0) {
		vec3 sigma_s = dFdx(VERTEX);
		vec3 sigma_t = dFdy(VERTEX);
		vec3 r1 = cross(sigma_t, NORMAL);
		vec3 r2 = cross(NORMAL, sigma_s);
		float det = dot(sigma_s, r1);
		vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
		NORMAL = normalize(abs(det) * NORMAL - grad);
	}

	ALBEDO = base;
	ROUGHNESS = rough;
	SPECULAR = spec;
	METALLIC = metal;
	EMISSION = emit;
	if (rim > 0.0) {
		RIM = rim;
		RIM_TINT = 0.7;
	}
}
