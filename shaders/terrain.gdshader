shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

#include "res://shaders/world_common.gdshaderinc"

varying vec3 v_world;
varying vec3 v_normal;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = NORMAL;
}

void fragment() {
	vec2 xz = v_world.xz;
	vec4 m = texture(mask_tex, map_uv(xz));
	vec3 col = meadow_color(xz, m) * 0.62;
	float n3 = texture(noise_tex, xz * 0.21).r;
	float n4 = texture(noise_tex, xz * 0.9 + 0.5).r;

	// Pink flower carpets, so fields read as pink even far beyond the flower meshes.
	float fl = m.g * smoothstep(0.35, 0.65, n3);
	col = mix(col, vec3(0.86, 0.52, 0.74), fl * 0.6);

	// Dirt footpath.
	float pd = path_dist(xz);
	float path = 1.0 - smoothstep(1.2, 2.3 + n3 * 0.9, pd);
	vec3 dirt = mix(vec3(0.46, 0.37, 0.28), vec3(0.6, 0.5, 0.38), n4);
	col = mix(col, dirt, path);

	// Steep slopes show stone.
	float slope = 1.0 - v_normal.y;
	col = mix(col, vec3(0.52, 0.48, 0.46) * (0.8 + 0.4 * n4), smoothstep(0.3, 0.48, slope));

	// Damp, darker soil around and under the pond.
	float wet = (1.0 - smoothstep(water_level - 0.2, water_level + 0.5, v_world.y)) * pond_area(xz);
	col = mix(col, vec3(0.2, 0.22, 0.14), wet * 0.8);

	ALBEDO = to_linear(col * (0.9 + 0.2 * n4));
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
