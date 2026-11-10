// Inverted-hull ink outline drawn around craft objects.
uniform vec4 outline_color : source_color = vec4(0.17, 0.1, 0.07, 1.0);
uniform float width = 0.012;

#ifdef VIEWMODEL
global uniform float vm_fov_scale;
#endif

void vertex() {
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 wv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + wn * width;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wv, 1.0));
#ifdef VIEWMODEL
	POSITION.xy *= vm_fov_scale;
	POSITION.z = POSITION.w - (POSITION.w - POSITION.z) * 0.02;
#endif
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
