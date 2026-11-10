class_name AmbientFX
extends Node3D
## Drifting pollen and seed fluff in daylight, glowing fireflies at dusk and
## night. Both emitters follow the player.

var pollen: GPUParticles3D
var fireflies: GPUParticles3D


func _ready() -> void:
	pollen = _make_emitter(260, 9.0, Vector3(22, 5, 22), Color(1.0, 0.92, 0.7), 0.035, 1.6)
	fireflies = _make_emitter(140, 7.0, Vector3(26, 2.2, 26), Color(0.85, 1.0, 0.35), 0.05, 6.0)
	var fm := fireflies.process_material as ParticleProcessMaterial
	fm.turbulence_noise_strength = 2.2
	fm.turbulence_noise_scale = 3.0
	fm.emission_shape_offset = Vector3(0, 1.5, 0)


func _make_emitter(amount: int, lifetime: float, box: Vector3, color: Color, size: float, glow: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(-box * 1.5, box * 3.0)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = box
	m.emission_shape_offset = Vector3(0, box.y, 0)
	m.gravity = Vector3(0.15, 0.02, 0.05)
	m.initial_velocity_min = 0.02
	m.initial_velocity_max = 0.15
	m.direction = Vector3(1, 0.2, 0.3)
	m.spread = 180.0
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.6
	m.turbulence_noise_scale = 6.0
	m.turbulence_noise_speed_random = 0.4
	m.scale_min = 0.5
	m.scale_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.85, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	m.scale_curve = ct
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow
	mat.albedo_texture = _dot_texture()
	quad.material = mat
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


func _dot_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


func _process(_delta: float) -> void:
	var player: Node3D = Game.player
	if player:
		pollen.global_position = player.global_position
		fireflies.global_position = player.global_position
	var light := Game.daylight()
	pollen.amount_ratio = clampf(light * 1.2, 0.05, 1.0)
	var dusk := 1.0 - smoothstep(0.1, 0.55, light)
	fireflies.amount_ratio = dusk
	fireflies.emitting = dusk > 0.02
