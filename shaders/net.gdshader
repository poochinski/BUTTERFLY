shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// Fine mesh netting: a diamond grid cut out with alpha scissor.

uniform vec3 net_color : source_color = vec3(0.96, 0.95, 0.9);
uniform float cells = 18.0;

void fragment() {
	vec2 g = vec2(UV.x * cells * 2.0, UV.y * cells * 0.8);
	vec2 d = vec2(g.x + g.y, g.x - g.y);
	vec2 f = abs(fract(d) - 0.5);
	float line = 1.0 - smoothstep(0.06, 0.12, min(f.x, f.y));
	ALBEDO = net_color;
	ALPHA = max(line, 0.12);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
	BACKLIGHT = net_color * 0.4;
}
