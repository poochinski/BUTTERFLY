class_name PauseMenu
extends CanvasLayer
## Pause screen with a few comfort settings.

var _root: Control
var _painterly: CheckButton
var _invert: CheckButton
var _fog: CheckButton
var _sens: HSlider
var _resume: Button
var is_open := false


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.get_theme()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.1, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var title := UITheme.label("Resting in the meadow", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	_resume = Button.new()
	_resume.text = "Keep exploring"
	_resume.pressed.connect(close)
	v.add_child(_resume)

	_painterly = CheckButton.new()
	_painterly.text = "Watercolour filter"
	_painterly.toggled.connect(func(on): Game.settings["painterly"] = on)
	v.add_child(_painterly)
	_fog = CheckButton.new()
	_fog.text = "Light rays (volumetric fog)"
	_fog.toggled.connect(_on_fog)
	v.add_child(_fog)
	_invert = CheckButton.new()
	_invert.text = "Invert camera up/down"
	_invert.toggled.connect(func(on): Game.settings["invert_y"] = on)
	v.add_child(_invert)
	var sens_row := HBoxContainer.new()
	sens_row.add_child(UITheme.label("Look sensitivity", 20))
	_sens = HSlider.new()
	_sens.min_value = 0.3
	_sens.max_value = 2.5
	_sens.step = 0.05
	_sens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sens.value_changed.connect(func(val): Game.settings["mouse_sensitivity"] = val)
	sens_row.add_child(_sens)
	v.add_child(sens_row)

	var quit := Button.new()
	quit.text = "Save and quit"
	quit.pressed.connect(func():
		Game.save_game()
		get_tree().quit())
	v.add_child(quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_open:
			close()
		elif not get_tree().paused:
			open()
		else:
			return
		get_viewport().set_input_as_handled()


func open() -> void:
	is_open = true
	_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_painterly.set_pressed_no_signal(bool(Game.settings["painterly"]))
	_invert.set_pressed_no_signal(bool(Game.settings["invert_y"]))
	_fog.set_pressed_no_signal(bool(Game.settings["volumetric_fog"]))
	_sens.set_value_no_signal(float(Game.settings["mouse_sensitivity"]))
	_resume.grab_focus()


func close() -> void:
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Game.save_game()
	if Game.input_mode == Game.InputMode.KEYBOARD:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_fog(on: bool) -> void:
	Game.settings["volumetric_fog"] = on
	var cycle := get_tree().get_first_node_in_group("day_cycle") as DayCycle
	if cycle:
		cycle.env.volumetric_fog_enabled = on
