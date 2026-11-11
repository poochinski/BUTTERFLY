class_name GameMap
extends Node3D
## Shared plumbing for every map: spawn lists, the navigation region, the
## decoration root, a MapBuilder, and the daylight rig (sun, sky fill,
## painted sky, tonemapping, grading, haze, depth of field) that keeps every
## map in the same realistic-diorama look.

var spawns := {0: [], 1: [], -1: []}
var nav_region: NavigationRegion3D
var deco: Node3D
var b: MapBuilder
var rng := RandomNumberGenerator.new()
var sun: DirectionalLight3D
var env: Environment
var cam_attr: CameraAttributesPractical
## Playable area (x, z) for the minimap and bounds.
var bounds := Rect2(-60, -40, 120, 80)
var title := "Map"
## Menu camera orbit: centre x, centre z, radius x, radius z.
var orbit := Vector4(0, 0, 58, 46)
var orbit_height := 22.0
## Cruising height of the attack helicopter above y = 0.
var heli_height := 24.0


func build() -> void:
	pass


func _setup_roots() -> void:
	nav_region = NavigationRegion3D.new()
	nav_region.name = "Nav"
	add_child(nav_region)
	deco = Node3D.new()
	deco.name = "Deco"
	add_child(deco)
	b = MapBuilder.new(nav_region, deco)


func _bake_nav(aabb: AABB, cell := 0.25) -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = MapBuilder.WORLD_LAYER
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.3
	nm.agent_max_slope = 40.0
	nm.cell_size = cell
	nm.cell_height = 0.25
	nm.filter_baking_aabb = aabb
	nav_region.navigation_mesh = nm
	nav_region.bake_navigation_mesh(false)


# --------------------------------------------------------------- lighting

func _environment() -> void:
	# Neutral mid-afternoon daylight: a real sun, not a stage gel.
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.light_energy = 1.85
	sun.light_angular_distance = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 110.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 1.6
	sun.shadow_bias = 0.04
	sun.rotation = Vector3(deg_to_rad(-41.0), deg_to_rad(-38.0), 0.0)
	add_child(sun)
	# A soft sky fill so shadows read as overcast daylight, not black.
	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.light_color = Color(0.78, 0.84, 0.92)
	fill.light_energy = 0.24
	fill.shadow_enabled = false
	fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	fill.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(150.0), 0.0)
	add_child(fill)

	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.08
	env.tonemap_white = 6.0
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.6
	env.ssao_power = 1.6
	env.ssao_detail = 0.8
	env.ssao_light_affect = 0.15
	env.ssil_radius = 4.0
	env.ssil_intensity = 1.3
	env.ssil_sharpness = 0.9
	env.glow_intensity = 0.25
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.83, 0.86)
	env.fog_density = 0.0022
	env.fog_aerial_perspective = 0.5
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.08
	env.adjustment_color_correction = _grade()
	var we := WorldEnvironment.new()
	we.environment = env
	cam_attr = CameraAttributesPractical.new()
	cam_attr.dof_blur_far_distance = 60.0
	cam_attr.dof_blur_far_transition = 55.0
	cam_attr.dof_blur_amount = 0.07
	we.camera_attributes = cam_attr
	add_child(we)
	apply_graphics()
	Game.settings_changed.connect(apply_graphics)


## A gentle photographic grade: barely-cool shadows and neutral, slightly
## warm highlights, like a well-lit photo of a museum diorama.
func _grade() -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(0.03, 0.035, 0.05), Color(0.24, 0.25, 0.27), Color(0.61, 0.6, 0.58), Color(1.0, 0.98, 0.95)])
	var t := GradientTexture1D.new()
	t.gradient = g
	t.width = 256
	return t


func apply_graphics() -> void:
	var high := String(Game.settings.get("graphics", "high")) == "high"
	env.ssao_enabled = true
	env.ssil_enabled = high
	env.glow_enabled = true
	cam_attr.dof_blur_far_enabled = high
	sun.shadow_blur = 1.6 if high else 1.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if high else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS


func _label(pos: Vector3, text: String, size: int, color: Color, billboard := false, yaw := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://assets/fonts/LuckiestGuy-Regular.ttf")
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_modulate = Color(0.17, 0.1, 0.07)
	l.outline_size = maxi(size / 6, 4)
	l.position = pos
	l.rotation.y = yaw
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	l.double_sided = false
	deco.add_child(l)
	return l
