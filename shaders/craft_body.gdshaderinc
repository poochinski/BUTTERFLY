// The PAPERCUT material: one shader for every craft supply in the game.
// kind: 0 cardboard · 1 paper · 2 felt · 3 knit yarn · 4 masking tape
//       5 plastic (buttons, caps) · 6 foil · 7 glowing paper
// pattern: 0 none · 1 hazard stripes · 2 dots · 3 checker tiles
//          4 window grid · 5 stitched border · 6 horizontal bands
//          7 cardboard floor panels · 8 wall panels with painted wainscot
//
// Boxes are unit BoxMeshes scaled by their node; the shader recovers each
// box's real size, then fakes the things that make real craft objects read
// as real: rounded (bevelled) edges that catch the light, an inked crease
// on every fold, worn kraft showing through paint, corrugation ridges under
// the liner, flutes on cut edges, fibres, fuzz and contact grime.

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
varying float v_seed;
varying vec3 v_world;

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

float c_fbm(vec2 p) {
	return c_noise(p) * 0.55 + c_noise(p * 2.1 + 3.7) * 0.3 + c_noise(p * 4.3 + 9.1) * 0.15;
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
	vec3 o = MODEL_MATRIX[3].xyz;
	v_seed = c_hash(o.xz * 0.731 + o.y * 1.37);
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
	vec3 ax_u;
	vec3 ax_v;
	if (an.x > an.y && an.x > an.z) {
		uv = p.zy;
		half_ext = v_scale.zy * 0.5;
		ax_u = vec3(0.0, 0.0, 1.0);
		ax_v = vec3(0.0, 1.0, 0.0);
	} else if (an.y > an.z) {
		uv = p.xz;
		half_ext = v_scale.xz * 0.5;
		ax_u = vec3(1.0, 0.0, 0.0);
		ax_v = vec3(0.0, 0.0, 1.0);
	} else {
		uv = p.xy;
		half_ext = v_scale.xy * 0.5;
		ax_u = vec3(1.0, 0.0, 0.0);
		ax_v = vec3(0.0, 1.0, 0.0);
	}
	float edge = 1000.0;
	float thin = 1000.0;
	vec3 edge_dir = vec3(0.0);
	if (box_edges) {
		float eu = half_ext.x - abs(uv.x);
		float ev = half_ext.y - abs(uv.y);
		edge = min(eu, ev);
		thin = min(half_ext.x, half_ext.y) * 2.0;
		edge_dir = eu < ev ? ax_u * sign(uv.x) : ax_v * sign(uv.y);
	}
	vec2 suv = uv + v_seed * 17.0;

	// Hand-made variation: no two pieces of card are quite the same colour.
	vec3 base = color.rgb * (0.94 + 0.12 * v_seed);
	base *= 0.95 + 0.1 * c_fbm(suv * 0.35);

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
		base *= 0.93 + 0.1 * c_hash(gi + v_seed);
		vec2 gf = abs(fract(g) - 0.5);
		base *= mix(0.72, 1.0, smoothstep(0.485, 0.465, max(gf.x, gf.y)));
	} else if (pattern == 4) {
		vec2 g = fract(uv * pattern_scale);
		vec2 gid = floor(uv * pattern_scale);
		float w = step(0.22, g.x) * step(g.x, 0.78) * step(0.28, g.y) * step(g.y, 0.82);
		vec3 lit = color2.rgb * (0.75 + 0.3 * c_hash(gid));
		base = mix(base, lit, w);
		base *= mix(1.0, 0.8, w * (1.0 - smoothstep(0.28, 0.36, g.y)));
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
	float bevel = 0.0;
	float ink = 0.0;
	vec3 emit = vec3(0.0);

	if (pattern == 8 && an.y < 0.5) {
		// Upright cardboard panels, with a hand-painted lower band.
		float along = an.x > an.z ? v_world.z : v_world.x;
		float pw = 1.6 * pattern_scale;
		float pid = floor(along / pw);
		float pf = abs(fract(along / pw) - 0.5) * pw;
		base *= 0.93 + 0.1 * c_hash(vec2(pid, v_seed));
		float seam = 1.0 - smoothstep(pw * 0.5 - 0.025, pw * 0.5 - 0.01, pf);
		base *= mix(0.6, 1.0, seam);
		h -= (1.0 - seam) * 0.004;
		float paint_line = 1.15 + (c_noise(vec2(along * 3.0, v_seed * 9.0)) - 0.5) * 0.06;
		float band = 1.0 - smoothstep(paint_line - 0.01, paint_line + 0.01, v_world.y);
		base = mix(base, color2.rgb * (0.94 + 0.1 * c_noise(vec2(along, v_world.y) * 6.0)), band);
		float trim = 1.0 - smoothstep(0.0, 0.03, abs(v_world.y - paint_line - 0.06));
		base = mix(base, base * 0.55, trim * 0.5);
	}

	if (pattern == 7) {
		// Floor made of big painted cardboard panels laid side by side.
		vec2 g = uv / (2.4 * pattern_scale);
		vec2 id = floor(g);
		vec2 f = fract(g);
		float seam = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 2.4 * pattern_scale;
		base *= 0.9 + 0.14 * c_hash(id);
		base = mix(base, color2.rgb, smoothstep(0.62, 0.8, c_fbm(uv * 0.18 + id)) * 0.35);
		base *= mix(0.55, 1.0, smoothstep(0.0, 0.03, seam));
		h -= (1.0 - smoothstep(0.0, 0.03, seam)) * 0.006;
	}

	if (kind == 0) {
		float fib = c_noise(suv * vec2(40.0, 4.0)) * 0.5 + c_noise(suv * 90.0) * 0.5;
		base *= 0.92 + 0.16 * fib;
		vec3 kraft = c_lin(vec3(0.8, 0.62, 0.42)) * (0.88 + 0.18 * fib);
		// Paint thins out in spots and wears away at the edges.
		float thin_ink = smoothstep(0.7, 0.9, c_fbm(suv * 2.5)) * 0.25 * wear;
		base = mix(base, kraft, thin_ink);
		float worn = wear * (1.0 - smoothstep(0.0, 0.025 + 0.05 * c_noise(suv * 6.0), edge));
		base = mix(base, kraft, worn);
		// Corrugation ridges showing through the liner, plus dimples.
		float ridge = sin((ax_u.x > 0.5 ? uv.x : uv.y) * 160.0) * 0.5 + 0.5;
		h += ridge * 0.0006 * bumps + (c_fbm(suv * 6.0) - 0.5) * 0.004 * bumps;
		if (thin < 0.07) {
			bool along_x = half_ext.x > half_ext.y;
			float along = along_x ? uv.x : uv.y;
			float across = along_x ? uv.y / max(half_ext.y, 0.001) : uv.x / max(half_ext.x, 0.001);
			float liner = step(0.74, abs(across));
			float wv = 1.0 - smoothstep(0.08, 0.24, abs(across - sin(along * 180.0) * 0.55));
			base = mix(kraft * 0.25, kraft * 1.05, max(liner, wv));
			h += wv * 0.002;
		}
		bevel = 0.022;
		ink = 0.45;
		rough = 0.86 - fib * 0.08;
		spec = 0.32;
	} else if (kind == 1) {
		float fib = c_noise(suv * 140.0) * 0.6 + c_noise(suv * 18.0) * 0.4;
		base *= 0.93 + 0.12 * fib;
		// Tiny coloured fibres speckled through the paper.
		float fleck = step(0.985, c_hash(floor(suv * 260.0)));
		base = mix(base, base * vec3(0.8, 0.85, 1.05), fleck * 0.6);
		h = (c_fbm(suv * 4.0) - 0.5) * 0.004 * bumps + (fib - 0.5) * 0.0006;
		bevel = 0.008;
		ink = 0.35;
		rough = 0.93;
		spec = 0.22;
	} else if (kind == 2) {
		float f1 = c_noise(suv * 170.0);
		float f2 = c_noise(suv * 38.0);
		float pill = step(0.97, c_hash(floor(suv * 55.0)));
		base *= 0.8 + 0.3 * (f1 * 0.6 + f2 * 0.4);
		base *= 1.0 - pill * 0.15;
		h = (f1 - 0.5) * 0.002 * bumps + (f2 - 0.5) * 0.002;
		bevel = 0.03;
		ink = 0.15;
		rough = 1.0;
		spec = 0.1;
		rim = 0.7;
	} else if (kind == 3) {
		vec2 k = uv * vec2(10.0, 12.0) * pattern_scale;
		vec2 cell = fract(k);
		vec2 q1 = c_rot(cell - vec2(0.28, 0.5), 0.55);
		vec2 q2 = c_rot(cell - vec2(0.72, 0.5), -0.55);
		float e = max(1.0 - length(q1 * vec2(3.4, 1.35)), 1.0 - length(q2 * vec2(3.4, 1.35)));
		e = clamp(e, 0.0, 1.0);
		base *= 0.4 + 0.72 * smoothstep(0.0, 0.55, e);
		base *= 0.9 + 0.16 * c_noise(suv * 220.0);
		base *= 0.92 + 0.12 * c_hash(floor(k.yy));
		h = e * 0.012 * bumps;
		bevel = 0.04;
		rough = 1.0;
		spec = 0.1;
		rim = 0.5;
	} else if (kind == 4) {
		base *= 0.94 + 0.12 * c_noise(suv * vec2(8.0, 70.0));
		h = (c_noise(suv * vec2(6.0, 30.0)) - 0.5) * 0.003;
		rough = 0.4;
		spec = 0.45;
	} else if (kind == 5) {
		rough = 0.2;
		spec = 0.7;
		bevel = 0.01;
	} else if (kind == 6) {
		h = (c_fbm(suv * 22.0) - 0.5) * 0.008;
		metal = 0.85;
		rough = 0.28 + 0.15 * c_noise(suv * 30.0);
	} else if (kind == 7) {
		emit = base * 2.4;
	}

	// Rounded edges: bend the normal toward the nearest edge, so every fold
	// catches a highlight on one side and falls into shade on the other.
	vec3 n_obj = n;
	if (box_edges && bevel > 0.0) {
		float bw = min(bevel, thin * 0.35);
		float k = 1.0 - smoothstep(0.0, bw, edge);
		n_obj = normalize(n * (1.0 - k * 0.75) + edge_dir * k * 0.85);
		NORMAL = normalize(mat3(VIEW_MATRIX) * (MODEL_NORMAL_MATRIX * n_obj));
		// An inked crease right on the fold.
		base *= 1.0 - ink * (1.0 - smoothstep(0.0015, 0.006, edge)) * 0.5;
	}

	// Contact grime where things meet the floor.
	if (box_edges && v_scale.y > 0.3 && an.y < 0.5) {
		float from_floor = (v_local.y + 0.5) * v_scale.y;
		base *= mix(0.72, 1.0, smoothstep(0.0, 0.25, from_floor));
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
		RIM_TINT = 0.75;
	}
	if (kind == 1 || kind == 2) {
		// Thin paper and felt let a little light through.
		BACKLIGHT = base * (kind == 1 ? 0.25 : 0.12);
	}
}
