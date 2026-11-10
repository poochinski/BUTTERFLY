shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// Little meadow flowers. INSTANCE_CUSTOM.rgb = petal colour, .a = petals / 10.

#include "res://shaders/world_common.gdshaderinc"

varying vec4 v_custom;
varying float v_head;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_head = UV2.x;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float k = max(VERTEX.y, 0.0);
	vec2 wd = normalize(wind_params.xy);
	float sway = sin(TIME * 1.8 + origin.x * 0.4 + origin.z * 0.3) * wind_params.z * 0.25
		+ sin(TIME * 3.7 + origin.x * 2.0) * 0.04;
	vec2 away = origin.xz - player_pos.xz;
	float d = length(away);
	vec2 push = away / max(d, 0.001) * smoothstep(1.0, 0.2, d) * 0.9;
	vec3 offset_world = vec3(wd.x * sway + push.x, 0.0, wd.y * sway + push.y) * k;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * offset_world;
}

void fragment() {
	if (v_head > 0.5) {
		vec2 q = UV * 2.0 - 1.0;
		float a = atan(q.y, q.x);
		float r = length(q);
		float petals = max(v_custom.a * 10.0, 4.0);
		float edge = 0.5 + 0.5 * pow(abs(cos(a * petals * 0.5)), 0.7);
		if (r > edge) {
			discard;
		}
		vec3 pc = v_custom.rgb;
		vec3 col = mix(pc * 0.7, pc, smoothstep(0.1, 0.85, r));
		col = mix(vec3(0.98, 0.76, 0.2), col, smoothstep(0.14, 0.24, r));
		ALBEDO = to_linear(col);
		BACKLIGHT = to_linear(col) * 0.5;
	} else {
		ALBEDO = to_linear(vec3(0.24, 0.42, 0.15));
	}
	ROUGHNESS = 0.8;
}
