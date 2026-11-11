class_name PauseMenu
extends CanvasLayer
## In-match pause: resume, settings, leave.

signal leave_pressed
signal class_chosen(index: int)

var _root: Control
var _main: VBoxContainer
var _settings: MainMenu.SettingsPanel
var _resume: Button
var _classes: VBoxContainer
var is_open := false


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UIKit.theme()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.08, 0.1, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_main = VBoxContainer.new()
	_main.position = Vector2(120, 260)
	_main.custom_minimum_size = Vector2(520, 0)
	_main.add_theme_constant_override("separation", 14)
	_root.add_child(_main)
	_main.add_child(UIKit.label("PAUSED", 80, UIKit.ACCENT, true, 14))
	_resume = UIKit.button("RESUME", close)
	_main.add_child(_resume)
	_main.add_child(UIKit.button("CHANGE CLASS", _open_classes))
	_main.add_child(UIKit.button("SETTINGS", func():
		_main.visible = false
		_settings.open()))
	_main.add_child(UIKit.button("LEAVE MATCH", func():
		close()
		leave_pressed.emit()))
	_settings = MainMenu.SettingsPanel.new()
	_settings.visible = false
	_settings.position = Vector2(120, 260)
	_settings.closed.connect(func():
		_main.visible = true
		_resume.grab_focus())
	_root.add_child(_settings)
	_classes = VBoxContainer.new()
	_classes.position = Vector2(120, 150)
	_classes.custom_minimum_size = Vector2(760, 0)
	_classes.add_theme_constant_override("separation", 8)
	_classes.visible = false
	_root.add_child(_classes)


## Every class: the defaults and the custom slots, with what each carries.
func _open_classes() -> void:
	_main.visible = false
	for c in _classes.get_children():
		c.queue_free()
	_classes.add_child(UIKit.label("CHANGE CLASS", 56, UIKit.ACCENT, true, 12))
	var current := int(Game.settings["class"]) % Game.class_count()
	var first: Button = null
	for i in Game.class_count():
		var c := Game.loadout(i)
		var b := UIKit.button(("> " if i == current else "") + String(c["name"]).to_upper() + "    ·    " + Game.describe(c), func():
			Game.settings["class"] = i
			Game.save_profile()
			class_chosen.emit(i)
			close())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 20)
		_classes.add_child(b)
		if i == current or first == null:
			first = b
	_classes.add_child(UIKit.button("BACK", func():
		_classes.visible = false
		_main.visible = true
		_resume.grab_focus()))
	_classes.visible = true
	first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	is_open = true
	_root.visible = true
	_main.visible = true
	_settings.visible = false
	_classes.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume.grab_focus()


func close() -> void:
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Game.save_profile()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
