class_name Player
extends Node3D
## Third-person naturalist: walking, running, sneaking, jumping and the
## net swing. Movement is relative to the camera; ground comes from the
## World heightfield, so no physics engine is needed.

signal swung
signal caught(butterfly: Node3D)

const WALK_SPEED := 3.4
const RUN_SPEED := 6.2
const SNEAK_SPEED := 1.5
const JUMP_VELOCITY := 4.8
const GRAVITY := 13.0
const RADIUS := 0.35
const SWING_TIME := 0.62
const STRIKE_WINDOW := Vector2(0.3, 0.6)
const CATCH_RADIUS := 0.5

var camera_rig: Node3D
var model: PlayerModel
var velocity := Vector3.ZERO
var on_ground := true
var sneaking := false
var running := false
var swing_t := -1.0

var _prev_hoop := Vector3.ZERO
var _swing_queued := false
var _noise_boost := 0.0
var _swing_catches: Array = []


func _ready() -> void:
	model = PlayerModel.new()
	model.name = "Model"
	add_child(model)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_swing_queued = true
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var world: World = Game.world
	if Input.is_action_just_pressed("sneak"):
		sneaking = not sneaking
	if Input.is_action_just_pressed("swing") or _swing_queued:
		_swing_queued = false
		start_swing()

	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Game.touch_move.length() > 0.05:
		iv = Game.touch_move.limit_length(1.0)
	running = Input.is_action_pressed("run") and iv.length() > 0.2
	if running and sneaking:
		sneaking = false

	var yaw: float = camera_rig.yaw if camera_rig else 0.0
	var dir := Vector3(iv.x, 0.0, iv.y).rotated(Vector3.UP, yaw)
	var max_speed := SNEAK_SPEED if sneaking else (RUN_SPEED if running else WALK_SPEED)
	if swing_t >= 0.0:
		max_speed *= 0.35
	var target_v := dir * max_speed
	var accel := 16.0 if on_ground else 5.0
	var hv := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_v, accel * delta * maxf(max_speed, 2.0))
	velocity.x = hv.x
	velocity.z = hv.z

	if on_ground and Input.is_action_just_pressed("jump") and swing_t < 0.0:
		velocity.y = JUMP_VELOCITY
		on_ground = false
		sneaking = false
	velocity.y -= GRAVITY * delta

	var old := global_position
	var pos := old + velocity * delta
	pos = world.resolve(pos, RADIUS)
	# Don't wade into the deep middle of the pond.
	if world.is_water(pos.x, pos.z) and world.height_at(pos.x, pos.z) < world.water_level - 0.5:
		pos.x = old.x
		pos.z = old.z
	var g := world.height_at(pos.x, pos.z)
	var was_on_ground := on_ground
	if pos.y <= g:
		pos.y = g
		velocity.y = 0.0
		on_ground = true
	elif was_on_ground and velocity.y <= 0.0 and pos.y - g < 0.35:
		pos.y = g
		velocity.y = 0.0
		on_ground = true
	else:
		on_ground = false
	global_position = pos

	if swing_t >= 0.0:
		model.rotation.y = lerp_angle(model.rotation.y, yaw, 1.0 - exp(-22.0 * delta))
	elif hv.length() > 0.2:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-hv.x, -hv.z), 1.0 - exp(-12.0 * delta))

	var swing_n := -1.0
	if swing_t >= 0.0:
		_update_swing(delta)
		if swing_t >= 0.0:
			swing_n = swing_t / SWING_TIME
	model.animate(delta, hv.length(), sneaking, on_ground, swing_n)
	_noise_boost = maxf(0.0, _noise_boost - delta * 0.8)
	RenderingServer.global_shader_parameter_set("player_pos", global_position)


func start_swing() -> void:
	if swing_t >= 0.0:
		return
	swing_t = 0.0
	_swing_catches.clear()
	_prev_hoop = model.hoop_position()
	swung.emit()


func _update_swing(delta: float) -> void:
	swing_t += delta
	var n := swing_t / SWING_TIME
	var hoop := model.hoop_position()
	if n >= STRIKE_WINDOW.x and n <= STRIKE_WINDOW.y:
		if n < STRIKE_WINDOW.x + 0.1:
			# A little lunge into the swing.
			var fwd := -model.global_transform.basis.z
			velocity += fwd * 9.0 * delta
		for b in get_tree().get_nodes_in_group("insects"):
			if not b.is_catchable():
				continue
			var d := _seg_dist(b.global_position, _prev_hoop, hoop)
			if d < CATCH_RADIUS * b.catch_scale():
				b.get_caught(model.hoop)
				_swing_catches.append(b)
				caught.emit(b)
		if _swing_catches.is_empty():
			_noise_boost = maxf(_noise_boost, 0.35)
	_prev_hoop = hoop
	if swing_t >= SWING_TIME:
		swing_t = -1.0


## How noticeable the player is. Butterflies multiply their alert distance
## by this: sneaking ≈ 0.25, standing ≈ 0.55, walking ≈ 1.0, running ≈ 1.6.
func noise_level() -> float:
	var spd := Vector2(velocity.x, velocity.z).length()
	var lvl: float
	if sneaking:
		lvl = 0.24 + spd / SNEAK_SPEED * 0.1
	elif spd > WALK_SPEED + 0.6:
		lvl = 1.6
	else:
		lvl = 0.55 + clampf(spd / WALK_SPEED, 0.0, 1.0) * 0.45
	if not on_ground:
		lvl = maxf(lvl, 1.2)
	return lvl + _noise_boost


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.000001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)
