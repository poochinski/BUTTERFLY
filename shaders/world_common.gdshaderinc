// Shared helpers for every world shader: terrain lookups, the meadow path,
// hashing, and the meadow colour palette (so grass blades and the ground
// beneath them always agree).

global uniform sampler2D height_tex : filter_linear, repeat_disable;
global uniform sampler2D mask_tex : filter_linear, repeat_disable;
global uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
global uniform vec3 player_pos;
global uniform vec4 wind_params; // xy = direction, z = strength
global uniform float water_level;

const float WORLD_SIZE = 1024.0;
const vec2 POND_CENTER = vec2(58.0, -14.0);
const float POND_RADIUS = 15.0;
const float WORLD_RES = 257.0;

vec2 map_uv(vec2 xz) {
	float cell = WORLD_SIZE / (WORLD_RES - 1.0);
	return ((xz + WORLD_SIZE * 0.5) / cell + 0.5) / WORLD_RES;
}

float ground_height(vec2 xz) {
	return texture(height_tex, map_uv(xz)).r;
}

// 1 near the pond (where water_level matters), 0 elsewhere.
float pond_area(vec2 xz) {
	return 1.0 - step(POND_RADIUS * 2.6, length(xz - POND_CENTER));
}

float path_x(float z) {
	return 12.0 * sin(z / 37.0) + 5.0 * sin(z / 15.0 + 1.3);
}

float path_dist(vec2 xz) {
	float dx = 12.0 / 37.0 * cos(xz.y / 37.0) + 5.0 / 15.0 * cos(xz.y / 15.0 + 1.3);
	float d = abs(xz.x - path_x(xz.y)) / sqrt(1.0 + dx * dx);
	float ends = max(0.0, max(-190.0 - xz.y, xz.y - 110.0));
	return d + ends * 4.0;
}

// Colours in these shaders are written as everyday (sRGB) values;
// lighting needs them in linear space.
vec3 to_linear(vec3 c) {
	return pow(max(c, vec3(0.0)), vec3(2.2));
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

vec3 meadow_color(vec2 xz, vec4 m) {
	float n1 = texture(noise_tex, xz * 0.013).r;
	float n2 = texture(noise_tex, xz * 0.061 + 0.37).r;
	vec3 lush = vec3(0.23, 0.42, 0.12);
	vec3 fresh = vec3(0.47, 0.62, 0.2);
	vec3 dry = vec3(0.68, 0.62, 0.32);
	vec3 col = mix(lush, fresh, smoothstep(0.3, 0.7, n1));
	col = mix(col, dry, smoothstep(0.55, 0.8, n2) * 0.5);
	col = mix(col, vec3(0.17, 0.29, 0.12), m.b * 0.7);
	return col;
}
