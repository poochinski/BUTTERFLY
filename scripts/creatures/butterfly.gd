class_name Butterfly
extends Node3D
## A single butterfly: procedural painted wings, fluttering flight, landing
## on flowers, noticing (and fleeing) the player, getting caught, and being
## released again.

enum State { FLY, PERCH, FLEE, CAUGHT, RELEASE }

const WING_SHADER := preload("res://shaders/wing_spatial.gdshader")
## Butterflies are drawn a little larger than life so they read well in play.
const HALF_SPAN := 0.27

var species_id := ""
var sp: Dictionary
var state: int = State.FLY
var vel := Vector3.ZERO
var target := Vector3.ZERO
var home := Vector3.ZERO
var landing := false
var size := 1.0

var _t := 0.0
var _state_t := 0.0
var _perch_time := 0.0
var _flap := 0.0
var _seed := 0.0
var _wing_angle := 0.4
var _wing_r: Node3D
var _wing_l: Node3D
var _mat: ShaderMaterial
var _net: Node3D
var _net_offset := Vector3.ZERO
var _retarget := 0.0


func setup(id: String, pos: Vector3, perched_at: Variant = null) -> void:
	species_id = id
	sp = Species.get_data(id)
	size = float(sp["size"]) * randf_range(0.9, 1.1)
	_seed = randf() * 100.0
	_t = randf() * 10.0
	position = pos
	home = pos
	add_to_group("insects")
	_build()
	if perched_at != null:
		position = perched_at
		_enter_perch()
	else:
		_pick_wander_target()


func is_catchable() -> bool:
	return state == State.FLY or state == State.PERCH or state == State.FLEE


func catch_scale() -> float:
	return clampf(size, 0.8, 1.25)


func is_released() -> bool:
	return state == State.RELEASE


# ------------------------------------------------------------- building

func _build() -> void:
	var span := HALF_SPAN * size
	_mat = ShaderMaterial.new()
	_mat.shader = WING_SHADER
	Species.apply_wing(_mat, sp)
	var quad := _wing_quad(span)
	_wing_r = Node3D.new()
	add_child(_wing_r)
	var mr := MeshInstance3D.new()
	mr.mesh = quad
	mr.material_override = _mat
	_wing_r.add_child(mr)
	_wing_l = Node3D.new()
	add_child(_wing_l)
	var ml := MeshInstance3D.new()
	ml.mesh = quad
	ml.material_override = _mat
	ml.scale = Vector3(-1, 1, 1)
	_wing_l.add_child(ml)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.1, 0.08, 0.07)
	body_mat.roughness = 0.7
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.013 * size
	cap.height = 0.12 * size
	cap.radial_segments = 8
	cap.rings = 2
	body.mesh = cap
	body.material_override = body_mat
	body.rotation.x = PI * 0.5
	body.position = Vector3(0, 0, 0.015 * size)
	add_child(body)
	for side in [-1.0, 1.0]:
		var ant := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.0035 * size
		cyl.bottom_radius = 0.002 * size
		cyl.height = 0.07 * size
		cyl.radial_segments = 4
		cyl.rings = 1
		ant.mesh = cyl
		ant.material_override = body_mat
		ant.position = Vector3(side * 0.012, 0.012, -0.075) * size
		ant.rotation = Vector3(-1.1, side * 0.35, 0)
		add_child(ant)


func _wing_quad(span: float) -> ArrayMesh:
	var verts := PackedVector3Array([
		Vector3(0, 0, -span), Vector3(span, 0, -span), Vector3(span, 0, span), Vector3(0, 0, span)])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var normals := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var idx := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


# ------------------------------------------------------------- behaviour

func _process(delta: float) -> void:
	_t += delta
	_state_t += delta
	var player: Player = Game.player
	match state:
		State.FLY:
			if player and _threatened(player):
				_flee(player)
			else:
				_fly(delta, 1.0)
		State.FLEE:
			_fly(delta, 2.6)
			if _state_t > 2.5:
				state = State.FLY
				_state_t = 0.0
				home = global_position
				_pick_wander_target()
		State.PERCH:
			if player and _threatened(player):
				_flee(player)
			elif _state_t > _perch_time:
				state = State.FLY
				_state_t = 0.0
				target = global_position + Vector3(randf_range(-3, 3), randf_range(1.0, 2.0), randf_range(-3, 3))
		State.CAUGHT:
			if is_instance_valid(_net):
				global_position = _net.global_position + _net.global_transform.basis * _net_offset
			if _state_t > 1.1:
				_release()
		State.RELEASE:
			_fly(delta, 1.4)
			var fade := clampf(1.0 - (_state_t - 4.0) / 1.5, 0.0, 1.0)
			scale = Vector3.ONE * maxf(fade, 0.001)
			if _state_t > 5.5:
				queue_free()
	_animate_wings(delta)


func _threatened(player: Player) -> bool:
	var d := global_position.distance_to(player.global_position + Vector3(0, 0.9, 0))
	var radius := float(sp["alert"]) * player.noise_level()
	if state == State.PERCH:
		radius *= 0.85
	return d < radius


func _flee(player: Player) -> void:
	state = State.FLEE
	_state_t = 0.0
	landing = false
	var away := global_position - player.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(1, 0, 0)
	away = away.normalized().rotated(Vector3.UP, randf_range(-0.7, 0.7))
	target = global_position + away * randf_range(7.0, 12.0) + Vector3(0, randf_range(1.5, 3.0), 0)
	vel += away * 1.5 + Vector3(0, 1.5, 0)


func _fly(delta: float, speed_mul: float) -> void:
	var style: String = sp["style"]
	var speed := float(sp["speed"]) * speed_mul
	var to_t := target - global_position
	var dist := to_t.length()
	if landing:
		speed *= clampf(dist / 1.2, 0.25, 1.0)
		if dist < 0.08:
			global_position = target
			_enter_perch()
			return
	elif dist < 0.6:
		_on_target_reached()
		to_t = target - global_position
	_retarget -= delta
	if style == "erratic" and state == State.FLY and not landing and _retarget <= 0.0:
		_retarget = randf_range(0.4, 0.9)
		target += Vector3(randf_range(-1.5, 1.5), randf_range(-0.4, 0.4), randf_range(-1.5, 1.5))

	var desired := to_t.normalized() * speed
	if not landing:
		var bob_f := 2.2 if style != "glide" else 1.4
		desired.y += sin(_t * bob_f * TAU + _seed) * 0.9
		desired += Vector3(sin(_t * 1.3 + _seed), 0.0, cos(_t * 1.1 + _seed * 2.0)) * 0.45
	var steer := 3.0 if style == "erratic" else 2.2
	vel = vel.lerp(desired, clampf(delta * steer, 0.0, 1.0))
	global_position += vel * delta

	var world: World = Game.world
	var g := world.height_at(global_position.x, global_position.z)
	if global_position.y < g + 0.2 and not landing:
		global_position.y = g + 0.2
		vel.y = absf(vel.y)
	if global_position.y > g + 6.0 and state != State.RELEASE:
		vel.y -= delta * 3.0

	var hv := Vector2(vel.x, vel.z)
	if hv.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-vel.x, -vel.z), 1.0 - exp(-6.0 * delta))
	rotation.x = lerpf(rotation.x, clampf(vel.y * 0.25, -0.5, 0.5), 1.0 - exp(-5.0 * delta))
	rotation.z = lerpf(rotation.z, clampf(-hv.length() * 0.05 * sin(_t * 0.7 + _seed), -0.3, 0.3), delta * 3.0)


func _on_target_reached() -> void:
	if state != State.FLY:
		_pick_wander_target()
		return
	if randf() < 0.55:
		var world: World = Game.world
		var p = world.random_perch_near(global_position, 10.0)
		if p != null:
			target = p + Vector3(0, 0.02, 0)
			landing = true
			return
	_pick_wander_target()


func _pick_wander_target() -> void:
	landing = false
	var world: World = Game.world
	var a := randf() * TAU
	var r := randf_range(2.0, 8.0)
	var x := home.x + cos(a) * r
	var z := home.z + sin(a) * r
	var g := world.height_at(x, z)
	target = Vector3(x, g + randf_range(0.6, 2.4), z)
	home = home.lerp(Vector3(x, home.y, z), 0.3)


func _enter_perch() -> void:
	state = State.PERCH
	_state_t = 0.0
	landing = false
	vel = Vector3.ZERO
	_perch_time = randf_range(4.0, 12.0)
	rotation.x = 0.0
	rotation.z = 0.0
	rotation.y = randf() * TAU


func get_caught(net: Node3D) -> void:
	state = State.CAUGHT
	_state_t = 0.0
	_net = net
	_net_offset = Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), -0.22)
	remove_from_group("insects")
	Game.record_catch(species_id)


func _release() -> void:
	state = State.RELEASE
	_state_t = 0.0
	landing = false
	_net = null
	var a := randf() * TAU
	target = global_position + Vector3(cos(a) * 6.0, 7.0, sin(a) * 6.0)
	vel = Vector3(0, 2.0, 0)
	_mat.set_shader_parameter("glow", 0.25)


func _animate_wings(delta: float) -> void:
	var style: String = sp["style"]
	var angle: float
	match state:
		State.PERCH:
			# Basking with wings open, now and then slowly folding them.
			angle = 0.45 + 0.42 * sin(_state_t * 1.1 + _seed)
		State.CAUGHT:
			_flap += delta * 16.0 * TAU
			angle = 0.6 + sin(_flap) * 0.7
		_:
			var hz := 8.0 if state != State.FLEE else 11.0
			var gliding := style == "glide" and state == State.FLY and sin(_t * 1.6 + _seed) > 0.35
			if gliding:
				angle = lerpf(_wing_angle, 0.2, 1.0 - exp(-8.0 * delta))
			else:
				_flap += delta * hz * TAU
				angle = 0.35 + sin(_flap) * 0.95
	_wing_angle = angle
	_wing_r.rotation.z = angle
	_wing_l.rotation.z = -angle
