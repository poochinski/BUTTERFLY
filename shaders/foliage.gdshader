shader_type spatial;
render_mode diffuse_burley, cull_disabled;

// Vertex-coloured scenery (pines, trunks, rocks, mountains) with gentle wind
// sway weighted by UV.y (0 at the base, 1 at the top).

#include "res://shaders/world_common.gdshaderinc"

uniform float sway_amount = 0.12;
uniform float noise_scale = 0.4;
uniform float backlight = 0.2;

varying vec3 v_world;
varying vec3 v_origin;

void vertex() {
	v_origin = MODEL_MATRIX[3].xyz;
	float sw = UV.y * UV.y;
	float t = TIME * 0.9 + v_origin.x * 0.13 + v_origin.z * 0.11;
	VERTEX.x += sin(t) * sway_amount * sw * wind_params.z * 2.0;
	VERTEX.z += cos(t * 0.8) * sway_amount * 0.7 * sw * wind_params.z * 2.0;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = texture(noise_tex, v_world.xz * noise_scale * 0.25 + v_world.y * noise_scale * 0.2).r;
	float tint = hash12(floor(v_origin.xz));
	vec3 col = COLOR.rgb * mix(0.78, 1.18, n) * mix(0.88, 1.1, tint);
	ALBEDO = to_linear(col);
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
	BACKLIGHT = to_linear(col) * backlight;
}
