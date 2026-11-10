shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// Crinkly coloured cellophane for windows.
uniform vec4 color : source_color = vec4(0.55, 0.85, 1.0, 0.32);

varying vec3 v_world;

float g_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = floor((v_world.xy + v_world.zy) * 3.0);
	float facet = g_hash(c);
	ALBEDO = color.rgb;
	ALPHA = color.a + facet * 0.08;
	ROUGHNESS = 0.08 + facet * 0.1;
	SPECULAR = 0.8;
	NORMAL = normalize(NORMAL + (vec3(g_hash(c + 1.3), g_hash(c + 2.7), g_hash(c + 5.1)) - 0.5) * 0.25);
}
