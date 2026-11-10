class_name TouchControls
extends CanvasLayer
## On-screen controls for phones and tablets: a floating joystick on the
## left, drag-to-look on the right, and big round action buttons.

const JOY_RADIUS := 110.0

var _root: TouchSurface


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = TouchSurface.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	Game.input_mode_changed.connect(func(_m): _root.visible = Game.input_mode == Game.InputMode.TOUCH)
	_root.visible = Game.input_mode == Game.InputMode.TOUCH


class TouchSurface:
	extends Control

	var move_finger := -1
	var move_origin := Vector2.ZERO
	var move_pos := Vector2.ZERO
	var look_finger := -1
	var look_last := Vector2.ZERO
	## action, label, anchor (0..1 of screen), offset from anchor, radius
	var buttons := [
		{"action": "swing", "label": "NET", "anchor": Vector2(1, 1), "offset": Vector2(-150, -170), "r": 84.0},
		{"action": "sneak", "label": "SNEAK", "anchor": Vector2(1, 1), "offset": Vector2(-320, -100), "r": 56.0},
		{"action": "jump", "label": "JUMP", "anchor": Vector2(1, 1), "offset": Vector2(-150, -350), "r": 54.0},
		{"action": "journal", "label": "BOOK", "anchor": Vector2(1, 0), "offset": Vector2(-90, 170), "r": 50.0},
		{"action": "pause", "label": "II", "anchor": Vector2(1, 0), "offset": Vector2(-90, 290), "r": 40.0},
	]
	var pressed := {}

	func _button_center(b: Dictionary) -> Vector2:
		var a: Vector2 = b["anchor"]
		return Vector2(size.x * a.x, size.y * a.y) + b["offset"]

	func _input(event: InputEvent) -> void:
		if not visible:
			return
		if event is InputEventScreenTouch:
			var pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if event.pressed:
				for b in buttons:
					if pos.distance_to(_button_center(b)) <= float(b["r"]) * 1.15:
						pressed[event.index] = b["action"]
						_send(b["action"], true)
						queue_redraw()
						return
				if pos.x < size.x * 0.45 and move_finger == -1:
					move_finger = event.index
					move_origin = pos
					move_pos = pos
				elif look_finger == -1:
					look_finger = event.index
					look_last = pos
			else:
				if pressed.has(event.index):
					_send(pressed[event.index], false)
					pressed.erase(event.index)
				if event.index == move_finger:
					move_finger = -1
					Game.touch_move = Vector2.ZERO
				if event.index == look_finger:
					look_finger = -1
			queue_redraw()
		elif event is InputEventScreenDrag:
			var pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if event.index == move_finger:
				move_pos = pos
				Game.touch_move = ((move_pos - move_origin) / JOY_RADIUS).limit_length(1.0)
				queue_redraw()
			elif event.index == look_finger:
				Game.touch_look += pos - look_last
				look_last = pos

	func _send(action: String, down: bool) -> void:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = down
		Input.parse_input_event(ev)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if move_finger != -1:
			draw_circle(move_origin, JOY_RADIUS, Color(1, 0.97, 0.9, 0.18))
			draw_arc(move_origin, JOY_RADIUS, 0, TAU, 48, Color(1, 0.97, 0.9, 0.5), 3.0, true)
			var knob := move_origin + (move_pos - move_origin).limit_length(JOY_RADIUS)
			draw_circle(knob, 44, Color(1, 0.97, 0.9, 0.55))
		else:
			var hint_c := Vector2(200, size.y - 200)
			draw_arc(hint_c, JOY_RADIUS, 0, TAU, 48, Color(1, 0.97, 0.9, 0.25), 3.0, true)
			draw_string(font, hint_c + Vector2(-40, 8), "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.97, 0.9, 0.5))
		for b in buttons:
			var c := _button_center(b)
			var r: float = b["r"]
			var on: bool = pressed.values().has(b["action"])
			draw_circle(c, r, Color(0.99, 0.95, 0.86, 0.7 if on else 0.42))
			draw_arc(c, r, 0, TAU, 48, Color(0.45, 0.32, 0.22, 0.7), 3.0, true)
			var label: String = b["label"]
			var fs := 26 if r > 60 else 20
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.INK)
