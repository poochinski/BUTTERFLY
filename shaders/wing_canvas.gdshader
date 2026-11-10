shader_type canvas_item;

// Journal / pop-up illustration of a whole butterfly seen from above.

#include "res://shaders/wing.gdshaderinc"

uniform float silhouette = 0.0;
uniform vec4 silhouette_col : source_color = vec4(0.36, 0.3, 0.24, 0.55);
uniform vec4 body_col : source_color = vec4(0.12, 0.09, 0.07, 1.0);

void fragment() {
	vec2 uv = UV;
	float x = (uv.x - 0.5) * 2.0;
	vec2 p = vec2(abs(x) * 1.06 - 0.025, (0.5 - uv.y) * 2.0 + 0.04);
	float im;
	vec4 c = wing_sample(p, im);
	c.rgb += irid_col.rgb * im * 0.45;
	// Body, head and antennae.
	float body = length(vec2(x * 16.0, (uv.y - 0.55) * 2.8));
	float head = length(vec2(x, uv.y - 0.37) * vec2(26.0, 26.0));
	float ant = 1.0;
	for (int s = -1; s <= 1; s += 2) {
		vec2 a0 = vec2(0.5 + float(s) * 0.01, 0.35);
		vec2 a1 = vec2(0.5 + float(s) * 0.09, 0.17);
		ant = min(ant, sd_seg(uv, a0, a1) * 120.0);
		ant = min(ant, length(uv - a1) * 90.0);
	}
	float b = max(max(1.0 - smoothstep(0.85, 1.0, body), 1.0 - smoothstep(0.85, 1.0, head)), 1.0 - smoothstep(0.6, 1.0, ant));
	c.rgb = mix(c.rgb, body_col.rgb, b);
	c.a = max(c.a, b);
	if (silhouette > 0.5) {
		c.rgb = silhouette_col.rgb;
		c.a *= silhouette_col.a;
	}
	COLOR = c;
}
