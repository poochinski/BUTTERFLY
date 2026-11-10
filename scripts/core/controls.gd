class_name Controls
extends RefCounted
## Registers every input action in code so keyboard/mouse, gamepad and touch
## all work without hand-editing the Input Map.

static func register() -> void:
	_add("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add("move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add("move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add("cam_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_add("cam_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_add("cam_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_add("cam_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	# Mouse-left swing is handled in Player so touch-emulated clicks never swing.
	_add("swing", [_key(KEY_E), _joy(JOY_BUTTON_X), _joy(JOY_BUTTON_RIGHT_SHOULDER), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add("sneak", [_key(KEY_C), _key(KEY_CTRL), _joy(JOY_BUTTON_B), _joy(JOY_BUTTON_LEFT_STICK)])
	_add("run", [_key(KEY_SHIFT), _joy(JOY_BUTTON_LEFT_SHOULDER), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add("jump", [_key(KEY_SPACE), _joy(JOY_BUTTON_A)])
	_add("journal", [_key(KEY_TAB), _key(KEY_J), _joy(JOY_BUTTON_Y), _joy(JOY_BUTTON_BACK)])
	_add("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy(JOY_BUTTON_START)])
	_add("zoom_in", [_mouse(MOUSE_BUTTON_WHEEL_UP), _joy(JOY_BUTTON_DPAD_UP)])
	_add("zoom_out", [_mouse(MOUSE_BUTTON_WHEEL_DOWN), _joy(JOY_BUTTON_DPAD_DOWN)])


static func _add(action: String, events: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.25)
	for e in events:
		InputMap.action_add_event(action, e)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.device = -1
	return e


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.device = -1
	return e


static func _joy(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.device = -1
	return e


static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	e.device = -1
	return e
