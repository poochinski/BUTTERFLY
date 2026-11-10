shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/world_common.gdshaderinc"

uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;
uniform vec3 deep : source_color = vec3(0.08, 0.2, 0.24);
uniform vec3 shallow : source_color = vec3(0.32, 0.52, 0.46);

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float depth_raw = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
	view.xyz /= view.w;
	float water_depth = max(0.0, VERTEX.z - view.z);
	float dt = clamp(water_depth / 1.6, 0.0, 1.0);

	vec2 uv1 = v_world.xz * 0.15 + TIME * vec2(0.02, 0.01);
	vec2 uv2 = v_world.xz * 0.23 - TIME * vec2(0.015, 0.02);
	float n1 = texture(noise_tex, uv1).r;
	float n2 = texture(noise_tex, uv2).r;
	vec3 nrm = normalize(vec3((n1 - 0.5) * 0.25, 1.0, (n2 - 0.5) * 0.25));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);

	vec3 col = mix(shallow, deep, dt);
	float foam = 1.0 - smoothstep(0.0, 0.22, water_depth);
	col = mix(col, vec3(0.92, 0.9, 0.85), foam * 0.45 * (0.6 + 0.4 * n1));
	ALBEDO = col;
	ALPHA = mix(0.5, 0.93, dt);
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;
}
