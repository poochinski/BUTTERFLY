// Procedural butterfly wing painter, shared by the 3D wings and the journal
// illustrations. Wing space: p.x = 0 at the body to 1 at the tip,
// p.y = +1 toward the head, -1 toward the tail. One quad holds the forewing
// (drawn on top) and the hindwing.

uniform vec2 fore_apex = vec2(0.94, 0.64);
uniform vec2 fore_tornus = vec2(0.6, 0.02);
uniform vec2 hind_outer = vec2(0.64, -0.3);
uniform vec2 hind_bottom = vec2(0.28, -0.7);
uniform float wing_round = 0.045;
uniform float scallop = 0.0;
uniform float tail_len = 0.0;
uniform float tail_width = 0.03;
uniform vec2 tail_dir = vec2(0.15, -1.0);

uniform vec4 fore_in : source_color = vec4(0.9, 0.5, 0.1, 1.0);
uniform vec4 fore_out : source_color = vec4(1.0, 0.6, 0.15, 1.0);
uniform vec4 hind_in : source_color = vec4(0.9, 0.5, 0.1, 1.0);
uniform vec4 hind_out : source_color = vec4(1.0, 0.6, 0.15, 1.0);
uniform float grad_start = 0.1;
uniform float grad_end = 0.9;

uniform vec4 border_col : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform float border_fore = 0.0;
uniform float border_hind = 0.0;
uniform vec4 spot_col : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform float spot_count = 0.0;
uniform float spot_size = 0.013;
uniform float spot_rows = 1.0;

uniform vec4 sub_col : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float sub_size = 0.0;
uniform float sub_offset = 0.03;
uniform float sub_count = 8.0;
uniform float sub_fore = 0.0;

uniform vec4 vein_col : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform float vein_width = 0.0;
uniform float vein_count = 9.0;

uniform vec4 stripe_col : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform float stripe_width = 0.0;
uniform float stripe_freq = 4.0;
uniform float stripe_angle = 0.0;
uniform float stripe_offset = 0.0;
uniform float stripe_mode = 0.0;
uniform float stripe_hind = 1.0;
uniform float stripe_fore = 1.0;

uniform vec4 apex_col : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform float apex_size = 0.0;
uniform vec4 apex_dot_col : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform float apex_dots = 0.0;

uniform vec4 band_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 band_line = vec4(0.3, 0.5, 0.7, 0.2);
uniform float band_width = 0.0;
uniform vec4 band2_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 band2_line = vec4(0.1, -0.2, 0.5, -0.4);
uniform float band2_width = 0.0;

uniform vec4 cell_col : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform float cell_size = 0.0;

uniform vec4 eye_ring : source_color = vec4(0.95, 0.85, 0.4, 1.0);
uniform vec4 eye_mid : source_color = vec4(0.12, 0.08, 0.2, 1.0);
uniform vec4 eye_pupil : source_color = vec4(0.4, 0.35, 0.9, 1.0);
uniform vec4 eye_fore = vec4(0.0);
uniform vec4 eye_hind = vec4(0.0);
uniform vec4 eye_hind2 = vec4(0.0);

uniform vec4 dot_col : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform float dot_density = 0.0;
uniform float dot_size = 0.02;

uniform vec4 fringe_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fringe = 0.0;

uniform vec4 irid_col : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float irid = 0.0;
uniform float irid_start = 0.3;
uniform float root_dark = 0.3;

float w_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float sd_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float sd_poly5(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3, vec2 v4) {
	vec2 v[5] = vec2[5](v0, v1, v2, v3, v4);
	float d = dot(p - v[0], p - v[0]);
	float s = 1.0;
	int j = 4;
	for (int i = 0; i < 5; i++) {
		vec2 e = v[j] - v[i];
		vec2 w = p - v[i];
		vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
		d = min(d, dot(b, b));
		bool c1 = p.y >= v[i].y;
		bool c2 = p.y < v[j].y;
		bool c3 = e.x * w.y > e.y * w.x;
		if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) {
			s = -s;
		}
		j = i;
	}
	return s * sqrt(d);
}

float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float fore_sd(vec2 p) {
	vec2 a = fore_apex;
	vec2 c = vec2(a.x * 0.45, a.y * 0.35);
	vec2 a2 = mix(a, c, 0.06);
	vec2 t2 = mix(fore_tornus, c, 0.06);
	float d = sd_poly5(p, vec2(0.02, 0.06), mix(vec2(a.x * 0.5, a.y * 0.78 + 0.03), c, 0.05), a2, t2, vec2(0.06, -0.04));
	float ang = atan(p.y, p.x);
	d += scallop * (0.5 + 0.5 * sin(ang * 46.0));
	return d - wing_round;
}

float hind_sd(vec2 p) {
	vec2 o = hind_outer;
	vec2 b = hind_bottom;
	vec2 c = vec2(o.x * 0.45, (o.y + b.y) * 0.4);
	float d = sd_poly5(p, vec2(0.03, 0.02), vec2(o.x * 0.8, o.y * 0.2 + 0.03), mix(o, c, 0.06), mix(b, c, 0.06), vec2(0.04, -0.28));
	float ang = atan(p.y, p.x);
	d += scallop * (0.5 + 0.5 * sin(ang * 40.0));
	d -= wing_round;
	if (tail_len > 0.0) {
		vec2 t0 = mix(o, b, 0.5);
		vec2 t1 = t0 + normalize(tail_dir) * tail_len;
		float td = sd_seg(p, t0, t1) - tail_width;
		d = smin(d, td, 0.03);
	}
	return d;
}

vec3 eyespot(vec3 col, vec2 p, vec4 e) {
	if (e.z <= 0.0) {
		return col;
	}
	float d = length(p - e.xy) / e.z;
	col = mix(col, eye_ring.rgb, 1.0 - smoothstep(0.9, 1.0, d));
	col = mix(col, eye_mid.rgb, 1.0 - smoothstep(0.6, 0.7, d));
	col = mix(col, eye_pupil.rgb, 1.0 - smoothstep(0.3, 0.4, d));
	float hl = length(p - e.xy - vec2(-0.22, 0.22) * e.z) / e.z;
	col = mix(col, vec3(1.0), 1.0 - smoothstep(0.08, 0.14, hl));
	return col;
}

float spot_row(vec2 p, float d, float ang, float r, float depth, float count, float size) {
	float delta = 1.0 / max(count, 0.01);
	float a2 = abs(fract(ang / delta + 0.5) - 0.5) * delta * r;
	float dd = length(vec2(a2, d - depth));
	return 1.0 - smoothstep(size * 0.7, size, dd);
}

vec3 wing_pattern(vec2 p, float d, bool hind, out float irid_mask) {
	float r = length(p);
	float ang = atan(p.y, p.x);
	vec2 ref = hind ? hind_outer : fore_apex;
	float rn = r / length(ref);
	vec3 cin = hind ? hind_in.rgb : fore_in.rgb;
	vec3 cout = hind ? hind_out.rgb : fore_out.rgb;
	vec3 col = mix(cin, cout, smoothstep(grad_start, grad_end, rn));

	if (dot_density > 0.0) {
		vec2 g = p / (dot_size * 3.0) + (hind ? vec2(7.3, 1.1) : vec2(0.0));
		vec2 id = floor(g);
		vec2 f = fract(g) - 0.5;
		vec2 off = (vec2(w_hash(id + 1.3), w_hash(id + 2.7)) - 0.5) * 0.4;
		if (w_hash(id) < dot_density) {
			col = mix(col, dot_col.rgb, 1.0 - smoothstep(0.2, 0.3, length(f - off)));
		}
	}

	if (stripe_width > 0.0 && ((hind && stripe_hind > 0.5) || (!hind && stripe_fore > 0.5))) {
		float t;
		if (stripe_mode < 0.5) {
			t = dot(p, vec2(cos(stripe_angle), sin(stripe_angle)));
		} else if (stripe_mode < 1.5) {
			t = ang / 3.14159;
		} else {
			t = r;
		}
		float sv = abs(fract(t * stripe_freq + stripe_offset) - 0.5);
		float sw = stripe_width * 0.5;
		col = mix(col, stripe_col.rgb, 1.0 - smoothstep(sw - 0.03, sw + 0.03, sv));
	}

	if (!hind && band_width > 0.0) {
		float bd = sd_seg(p, band_line.xy, band_line.zw);
		col = mix(col, band_col.rgb, 1.0 - smoothstep(band_width * 0.75, band_width, bd));
	}
	if (hind && band2_width > 0.0) {
		float bd = sd_seg(p, band2_line.xy, band2_line.zw);
		col = mix(col, band2_col.rgb, 1.0 - smoothstep(band2_width * 0.75, band2_width, bd));
	}

	if (!hind && cell_size > 0.0) {
		vec2 c = vec2(fore_apex.x * 0.45, fore_apex.y * 0.42);
		float cd = length((p - c) * vec2(1.7, 0.75));
		col = mix(col, cell_col.rgb, 1.0 - smoothstep(cell_size * 0.75, cell_size, cd));
	}

	if (hind) {
		col = eyespot(col, p, eye_hind);
		col = eyespot(col, p, eye_hind2);
	} else {
		col = eyespot(col, p, eye_fore);
	}

	if (vein_width > 0.0) {
		float delta = 3.14159 / vein_count;
		float vd = r * abs(fract(ang / delta + 0.5) - 0.5) * delta;
		float vein = (1.0 - smoothstep(vein_width * 0.5, vein_width, vd)) * smoothstep(0.1, 0.22, r);
		float arc = (1.0 - smoothstep(vein_width * 0.5, vein_width, abs(rn - 0.48) * length(ref))) * smoothstep(-0.9, -0.2, ang) * (1.0 - smoothstep(0.6, 1.1, ang));
		col = mix(col, vein_col.rgb, max(vein, arc * 0.85));
	}

	if (!hind && apex_size > 0.0) {
		float ad = length(p - fore_apex);
		col = mix(col, apex_col.rgb, 1.0 - smoothstep(apex_size * 0.85, apex_size, ad));
		if (apex_dots > 0.0) {
			vec2 dir = normalize(fore_tornus - fore_apex);
			vec2 inward = vec2(-0.13, -0.03);
			for (int k = 0; k < 4; k++) {
				vec2 c = fore_apex + dir * (0.07 + float(k) * 0.065) + inward * (1.0 - float(k) * 0.25);
				float dd = length(p - c);
				col = mix(col, apex_dot_col.rgb, 1.0 - smoothstep(0.018, 0.026, dd));
			}
		}
	}

	float bw = hind ? border_hind : border_fore;
	float bm = 0.0;
	if (bw > 0.0) {
		bm = 1.0 - smoothstep(bw - 0.01, bw + 0.005, d);
		col = mix(col, border_col.rgb, bm);
		if (spot_count > 0.0) {
			col = mix(col, spot_col.rgb, spot_row(p, d, ang, r, bw * (spot_rows > 1.5 ? 0.3 : 0.5), spot_count, spot_size));
			if (spot_rows > 1.5) {
				col = mix(col, spot_col.rgb, spot_row(p, d, ang + 0.5 / spot_count, r, bw * 0.72, spot_count, spot_size * 0.85));
			}
		}
	}

	if (sub_size > 0.0 && (hind || sub_fore > 0.5)) {
		col = mix(col, sub_col.rgb, spot_row(p, d, ang, r, bw + sub_offset, sub_count, sub_size));
	}

	if (fringe > 0.0) {
		col = mix(col, fringe_col.rgb, 1.0 - smoothstep(fringe * 0.5, fringe, d));
	}

	col *= mix(1.0 - root_dark, 1.0, smoothstep(0.02, 0.26, r));
	col *= 0.94 + 0.08 * w_hash(floor(p * 160.0));
	irid_mask = irid * smoothstep(irid_start, irid_start + 0.25, rn) * (1.0 - bm);
	return col;
}

// Returns the wing colour (rgb) and coverage (a).
vec4 wing_sample(vec2 p, out float irid_mask) {
	irid_mask = 0.0;
	float df = fore_sd(p);
	float dh = hind_sd(p);
	float aa = 0.008;
	vec3 col = vec3(0.0);
	float alpha = 0.0;
	float im_h = 0.0;
	float im_f = 0.0;
	if (dh < aa) {
		col = wing_pattern(p, -dh, true, im_h);
		// Soft shadow where the forewing overlaps.
		col *= mix(0.8, 1.0, smoothstep(0.0, 0.04, df));
		alpha = 1.0 - smoothstep(-aa, aa, dh);
		irid_mask = im_h;
	}
	if (df < aa) {
		float af = 1.0 - smoothstep(-aa, aa, df);
		vec3 fc = wing_pattern(p, -df, false, im_f);
		col = mix(col, fc, af);
		alpha = max(alpha, af);
		irid_mask = mix(irid_mask, im_f, af);
	}
	return vec4(col, alpha);
}
