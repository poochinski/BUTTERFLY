class_name DayCycle
extends Node3D
## Sun, moon, sky and atmosphere, all driven by Game.hour. The sun rises
## behind the starting point and sets at the far end of the path.

const SKY_SHADER := preload("res://shaders/sky.gdshader")

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment
var sky_mat: ShaderMaterial
var _cloud_t := 0.0


func _ready() -> void:
	add_to_group("day_cycle")
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL

	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_density = 0.0007
	env.fog_aerial_perspective = 0.75
	env.fog_sky_affect = 0.0
	env.fog_sun_scatter = 0.2
	env.volumetric_fog_enabled = bool(Game.settings.get("volumetric_fog", true))
	env.volumetric_fog_density = 0.0018
	env.volumetric_fog_anisotropy = 0.7
	env.volumetric_fog_length = 90.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_ambient_inject = 0.0
	env.volumetric_fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 110.0
	sun.shadow_blur = 1.5
	sun.light_angular_distance = 0.6
	sun.light_volumetric_fog_energy = 1.4
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	add_child(sun)

	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.shadow_enabled = false
	moon.light_color = Color(0.62, 0.72, 1.0)
	moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	moon.light_volumetric_fog_energy = 0.3
	add_child(moon)
	_update(0.0)


func _process(delta: float) -> void:
	_cloud_t += delta
	_update(delta)


func sun_direction() -> Vector3:
	var a := (Game.hour - 6.0) / 12.0 * PI
	return Vector3(-0.32, sin(a), cos(a)).normalized()


func _update(_delta: float) -> void:
	var dir := sun_direction()
	var e := dir.y
	var day := smoothstep(0.06, 0.62, e)
	var night := smoothstep(0.02, -0.22, e)
	var dusk := (1.0 - day) * (1.0 - night)

	_aim(sun, dir)
	var sun_col := Color(1.0, 0.6, 0.34).lerp(Color(1.0, 0.95, 0.88), day)
	sun.light_color = sun_col
	sun.light_energy = smoothstep(-0.04, 0.08, e) * lerpf(1.25, 1.5, day)
	sun.visible = sun.light_energy > 0.001

	var mdir := Vector3(0.3, -dir.y, -dir.z * 0.6).normalized()
	if mdir.y < 0.15:
		mdir.y = 0.15
		mdir = mdir.normalized()
	_aim(moon, mdir)
	moon.light_energy = night * 0.32
	moon.visible = moon.light_energy > 0.001

	sky_mat.set_shader_parameter("sun_dir", dir)
	sky_mat.set_shader_parameter("cloud_time", _cloud_t)

	var fog_day := Color(0.72, 0.8, 0.92)
	var fog_dusk := Color(0.8, 0.62, 0.72)
	var fog_night := Color(0.07, 0.09, 0.17)
	var fog := fog_dusk.lerp(fog_day, day).lerp(fog_night, night)
	env.fog_light_color = fog
	env.fog_light_energy = lerpf(1.0, 0.6, night)
	env.volumetric_fog_albedo = Color(1, 1, 1).lerp(Color(1.0, 0.85, 0.8), dusk)
	env.volumetric_fog_emission = fog_night * 0.05 * night
	env.ambient_light_energy = lerpf(1.0, 0.55, night)
	env.background_energy_multiplier = 1.0

	var wind := 0.45 + 0.2 * sin(_cloud_t * 0.07)
	RenderingServer.global_shader_parameter_set("wind_params", Vector4(1.0, 0.4, wind, 0.0))


func _aim(light: DirectionalLight3D, to_light: Vector3) -> void:
	var up := Vector3.UP if absf(to_light.y) < 0.98 else Vector3.FORWARD
	light.global_transform = Transform3D(Basis.looking_at(-to_light, up), Vector3.ZERO)
