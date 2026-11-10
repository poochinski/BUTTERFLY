shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Infinite grass field: the multimesh follows the player in steps of
// `spacing`, and every blade derives its jitter from its world cell, so blades
// never visibly move as the grid recentres.

#include "res://shaders/world_common.gdshaderinc"

uniform float spacing = 0.25;
uniform float field_radius = 34.0;

varying float v_t;
varying vec3 v_col;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec2 cell = floor(origin.xz / spacing + 0.5);
	float r1 = hash12(cell);
	float r2 = hash12(cell + 17.31);
	float r3 = hash12(cell + 41.77);
	vec2 base = origin.xz + (vec2(r1, r2) - 0.5) * spacing * 0.95;

	vec4 m = texture(mask_tex, map_uv(base));
	float pd = path_dist(base);
	float ground = ground_height(base);
	float tall = smoothstep(0.2, 0.7, m.a);
	float h = mix(0.45, 1.1, tall) * mix(0.6, 1.3, r3);
	h *= smoothstep(0.9, 2.2, pd);
	h *= 1.0 - m.b * 0.45;
	h *= 1.0 - smoothstep(field_radius * 0.7, field_radius, length(base - player_pos.xz));
	h *= mix(1.0, smoothstep(water_level - 0.1, water_level + 0.15, ground), pond_area(base));

	float ang = r1 * 6.2831;
	float c = cos(ang);
	float s = sin(ang);
	vec3 lv = VERTEX;
	lv.xz = vec2(c * lv.x - s * lv.z, s * lv.x + c * lv.z);
	float t = lv.y;
	lv.y *= h;
	lv.xz *= mix(0.8, 1.25, r2);

	vec2 wd = normalize(wind_params.xy);
	float gust = sin(TIME * 1.3 + dot(base, wd) * 0.18) * 0.5 + 0.5;
	float flutter = sin(TIME * 4.1 + base.x * 1.7 + base.y * 1.3);
	vec2 bend = wd * (gust * wind_params.z + flutter * 0.08);
	vec2 away = base - player_pos.xz;
	float pdist = length(away);
	bend += away / max(pdist, 0.001) * smoothstep(1.3, 0.2, pdist) * 1.1;
	float bt = t * t;
	lv.xz += bend * bt * h * 0.8;
	lv.y -= dot(bend, bend) * bt * h * 0.18;

	vec3 world = vec3(base.x, ground - 0.04, base.y) + lv;
	VERTEX = world - origin;
	NORMAL = normalize(vec3(bend.x * 0.4, 1.0, bend.y * 0.4));

	v_t = t;
	v_col = meadow_color(base, m) * mix(0.85, 1.15, r3);
	v_col = mix(v_col, vec3(0.78, 0.7, 0.38), smoothstep(0.82, 1.0, r2) * 0.55);
}

void fragment() {
	vec3 tip = v_col * vec3(1.15, 1.2, 0.85) + vec3(0.05, 0.05, 0.0);
	vec3 col = mix(v_col * 0.4, tip, v_t * v_t);
	ALBEDO = to_linear(col);
	ROUGHNESS = 0.7;
	SPECULAR = 0.35;
	BACKLIGHT = to_linear(vec3(0.75, 0.85, 0.3)) * v_t * 0.9;
	AO = mix(0.5, 1.0, v_t);
	AO_LIGHT_AFFECT = 0.5;
}
