shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/wing.gdshaderinc"

uniform float glow = 0.0;

void fragment() {
	vec2 p = vec2(UV.x, (0.5 - UV.y) * 2.0);
	float im;
	vec4 c = wing_sample(p, im);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
	BACKLIGHT = c.rgb * 0.55;
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	EMISSION = irid_col.rgb * im * (0.35 + fres * 0.9) + c.rgb * glow;
}
