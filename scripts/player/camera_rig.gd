class_name CameraRig
extends Node3D
## Over-the-shoulder third-person camera. Mouse, right stick or touch drag to
## look; wheel / d-pad to zoom. Keeps itself above the terrain.

const SHOULDER := 0.8
const MIN_DIST := 2.4
const MAX_DIST := 8.0

var target: Player
var yaw := 0.0
var pitch := -0.16
var distance := 4.0
var camera: Camera3D

var _focus := Vector3.ZERO
var _dist_cur := 4.0
var _initialized := false


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 62.0
	camera.near = 0.08
	camera.far = 6000.0
	add_child(camera)
	camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event.device != InputEvent.DEVICE_ID_EMULATION:
		var s := 0.0024 * float(Game.settings["mouse_sensitivity"])
		var inv := -1.0 if bool(Game.settings["invert_y"]) else 1.0
		yaw -= event.relative.x * s
		pitch -= event.relative.y * s * inv
	if event.is_action_pressed("zoom_in"):
		distance = clampf(distance - 0.5, MIN_DIST, MAX_DIST)
	elif event.is_action_pressed("zoom_out"):
		distance = clampf(distance + 0.5, MIN_DIST, MAX_DIST)


func _process(delta: float) -> void:
	if target == null:
		return
	var look := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	var inv := -1.0 if bool(Game.settings["invert_y"]) else 1.0
	yaw -= look.x * 2.6 * delta
	pitch -= look.y * 1.8 * delta * inv
	if Game.touch_look != Vector2.ZERO:
		yaw -= Game.touch_look.x * 0.006
		pitch -= Game.touch_look.y * 0.005
		Game.touch_look = Vector2.ZERO
	pitch = clampf(pitch, -1.15, 0.5)

	var crouch := target.model.crouch if target.model else 0.0
	var focus_target := target.global_position + Vector3(0, 1.5 - crouch * 0.45, 0)
	if not _initialized:
		_focus = focus_target
		_initialized = true
	_focus = _focus.lerp(focus_target, 1.0 - exp(-12.0 * delta))
	_dist_cur = lerpf(_dist_cur, distance - crouch * 0.6, 1.0 - exp(-6.0 * delta))

	var basis := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	var cam_pos := _focus + basis * Vector3(SHOULDER, 0.0, _dist_cur)
	var world: World = Game.world
	var g := world.height_at(cam_pos.x, cam_pos.z) + 0.4
	if cam_pos.y < g:
		cam_pos.y = g
	camera.global_transform = Transform3D(basis, cam_pos)


func forward() -> Vector3:
	return -camera.global_transform.basis.z
