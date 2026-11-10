shader_type spatial;
render_mode diffuse_burley;

// Lumpy flowering shrubs and leafy tree canopies, covered in tiny procedural
// florets/leaf clusters (3D voronoi cells in object space).

#include "res://shaders/world_common.gdshaderinc"

uniform vec3 leaf : source_color = vec3(0.2, 0.38, 0.14);
uniform vec3 leaf_light : source_color = vec3(0.42, 0.56, 0.2);
uniform float floret_scale = 9.0;
uniform float lumpiness = 0.35;
uniform float sway = 0.03;

varying vec3 v_local;
varying vec3 v_origin;
varying float v_up;
varying vec4 v_bloom;

void vertex() {
	v_origin = MODEL_MATRIX[3].xyz;
	// INSTANCE_CUSTOM: rgb = blossom colour, a = how much of the shrub is in bloom.
	v_bloom = INSTANCE_CUSTOM;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = texture(noise_tex, wp.xz * 0.35 + wp.y * 0.21).r;
	VERTEX += NORMAL * (n - 0.5) * lumpiness;
	float h = max(VERTEX.y, 0.0);
	VERTEX.x += sin(TIME * 1.2 + v_origin.x * 0.7) * sway * h * wind_params.z * 2.0;
	VERTEX.z += cos(TIME * 1.0 + v_origin.z * 0.7) * sway * h * wind_params.z * 2.0;
	v_local = VERTEX;
	v_up = NORMAL.y;
}

void fragment() {
	vec3 p = v_local * floret_scale + v_origin * 0.37;
	vec3 ip = floor(p);
	vec3 fp = fract(p);
	float md = 8.0;
	vec3 mh = vec3(0.0);
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 o = vec3(float(x), float(y), float(z));
				vec3 h = hash33(ip + o);
				vec3 diff = o + h - fp;
				float d = dot(diff, diff);
				if (d < md) {
					md = d;
					mh = h;
				}
			}
		}
	}
	float cellv = 1.0 - smoothstep(0.08, 0.32, md);
	float top = smoothstep(-0.7, 0.5, v_up);
	float amount = v_bloom.a;
	vec3 ba = v_bloom.rgb;
	vec3 bb = ba * vec3(0.92, 0.72, 0.8);
	float bloom = step(1.0 - amount * mix(0.55, 1.0, top), mh.x);
	vec3 fcol = mix(ba, bb, mh.y) * mix(0.85, 1.12, mh.z);
	fcol = mix(fcol, vec3(1.0, 0.95, 0.97), step(0.9, mh.z) * 0.6);
	vec3 lcol = mix(leaf, leaf_light, mh.y * top);
	vec3 col = mix(lcol * mix(0.65, 1.0, cellv), fcol * mix(0.75, 1.0, cellv), bloom);
	col *= mix(0.5, 1.0, top);
	ALBEDO = to_linear(col);
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	BACKLIGHT = to_linear(col) * 0.3;
}
