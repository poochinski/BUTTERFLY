shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, shadows_disabled;

// First-person weapon/arms variant: own field of view, never clips into walls.
#define VIEWMODEL
#include "res://shaders/craft_body.gdshaderinc"
