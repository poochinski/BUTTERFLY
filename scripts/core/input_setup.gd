class_name InputSetup
extends RefCounted
## Every control, registered in code. Keyboard and mouse follow the classic
## PC shooter layout; gamepad follows the classic console layout.

static func register() -> void:
	_add("move_left", [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add("move_right", [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add("move_forward", [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add("move_back", [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add("look_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)], 0.12)
	_add("look_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)], 0.12)
	_add("look_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)], 0.12)
	_add("look_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)], 0.12)
	_add("fire", [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add("ads", [_mouse(MOUSE_BUTTON_RIGHT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add("reload", [_key(KEY_R), _joy(JOY_BUTTON_X)])
	_add("jump", [_key(KEY_SPACE), _joy(JOY_BUTTON_A)])
	_add("crouch", [_key(KEY_C), _joy(JOY_BUTTON_B)])
	_add("prone", [_key(KEY_CTRL), _key(KEY_Z)])
	_add("sprint", [_key(KEY_SHIFT), _joy(JOY_BUTTON_LEFT_STICK)])
	_add("melee", [_key(KEY_V), _key(KEY_E), _joy(JOY_BUTTON_RIGHT_STICK)])
	_add("frag", [_key(KEY_G), _joy(JOY_BUTTON_RIGHT_SHOULDER)])
	_add("switch_weapon", [_mouse(MOUSE_BUTTON_WHEEL_UP), _mouse(MOUSE_BUTTON_WHEEL_DOWN), _joy(JOY_BUTTON_Y)])
	_add("weapon_1", [_key(KEY_1)])
	_add("weapon_2", [_key(KEY_2)])
	_add("killstreak", [_key(KEY_5), _key(KEY_4), _joy(JOY_BUTTON_DPAD_UP)])
	_add("scoreboard", [_key(KEY_TAB), _joy(JOY_BUTTON_BACK)])
	_add("pause", [_key(KEY_ESCAPE), _joy(JOY_BUTTON_START)])
	_add("ui_accept", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_SPACE), _joy(JOY_BUTTON_A)])


static func _add(action: String, events: Array, deadzone := 0.25) -> void:
	if InputMap.has_action(action):
		if action == "ui_accept":
			for e in events:
				InputMap.action_add_event(action, e)
			return
		InputMap.erase_action(action)
	InputMap.add_action(action, deadzone)
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
