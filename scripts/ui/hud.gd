class_name HUD
extends CanvasLayer
## Journal progress, clock, the sneaking meter, catch pop-ups and control
## hints that match whatever device the player is using.

var _root: Control
var _count_label: Label
var _clock_label: Label
var _hint: Label
var _stealth: StealthMeter
var _toast: PanelContainer
var _toast_art_holder: Control
var _toast_title: Label
var _toast_name: Label
var _toast_sci: Label
var _toast_tween: Tween
var _welcome: PanelContainer


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.get_theme()
	add_child(_root)

	# Journal progress (top-left).
	var top_left := PanelContainer.new()
	top_left.position = Vector2(28, 24)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top_left)
	var tl := HBoxContainer.new()
	top_left.add_child(tl)
	var icon := UITheme.butterfly_art("monarch")
	icon.custom_minimum_size = Vector2(44, 44)
	tl.add_child(icon)
	var tlv := VBoxContainer.new()
	tlv.add_theme_constant_override("separation", 0)
	tl.add_child(tlv)
	tlv.add_child(UITheme.label("Field Journal", 16, UITheme.INK_SOFT))
	_count_label = UITheme.label("", 26)
	tlv.add_child(_count_label)

	# Clock (top-right).
	var top_right := PanelContainer.new()
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top_right.position = Vector2(-28, 24)
	_root.add_child(top_right)
	var trv := VBoxContainer.new()
	trv.add_theme_constant_override("separation", 0)
	top_right.add_child(trv)
	_clock_label = UITheme.label("", 26)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	trv.add_child(_clock_label)
	var day_label := UITheme.label("", 16, UITheme.INK_SOFT)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	day_label.name = "Day"
	trv.add_child(day_label)

	# Sneak meter (bottom-left).
	_stealth = StealthMeter.new()
	_stealth.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stealth.position = Vector2(30, -150)
	_stealth.custom_minimum_size = Vector2(240, 120)
	_stealth.size = Vector2(240, 120)
	_stealth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stealth)

	# Control hints (bottom-right).
	_hint = UITheme.label("", 17, Color(1, 0.98, 0.92, 0.92))
	_hint.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.02, 0.6))
	_hint.add_theme_constant_override("shadow_offset_x", 1)
	_hint.add_theme_constant_override("shadow_offset_y", 2)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.position = Vector2(-30, -40)
	_root.add_child(_hint)

	_build_toast()
	_build_welcome()
	get_tree().create_timer(12.0).timeout.connect(_welcome_fade)

	Game.species_caught.connect(_on_caught)
	Game.input_mode_changed.connect(func(_m): _update_hint())
	_update_hint()


func _process(_delta: float) -> void:
	_count_label.text = "%d / %d species" % [Game.journal.size(), Species.ORDER.size()]
	_clock_label.text = Game.clock_text()
	var day_label: Label = _root.find_child("Day", true, false)
	if day_label:
		day_label.text = "Day %d" % Game.day
	_hint.visible = Game.input_mode != Game.InputMode.TOUCH
	if _welcome.visible and (Game.player and Vector2(Game.player.velocity.x, Game.player.velocity.z).length() > 0.5):
		_welcome_fade()


func _update_hint() -> void:
	match Game.input_mode:
		Game.InputMode.GAMEPAD:
			_hint.text = "Left stick  move    Right stick  look    RT / X  swing net\nB  sneak    LB  run    A  jump    Y  journal    Start  pause"
		Game.InputMode.TOUCH:
			_hint.text = ""
		_:
			_hint.text = "WASD  move    Mouse  look    Click / E  swing net\nC  sneak    Shift  run    Space  jump    Tab  journal    Esc  pause"


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.position = Vector2(0, -150)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	_toast.add_child(h)
	_toast_art_holder = Control.new()
	_toast_art_holder.custom_minimum_size = Vector2(120, 120)
	h.add_child(_toast_art_holder)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	_toast_title = UITheme.label("", 18, UITheme.ACCENT)
	v.add_child(_toast_title)
	_toast_name = UITheme.label("", 32)
	v.add_child(_toast_name)
	_toast_sci = UITheme.label("", 18, UITheme.INK_SOFT)
	v.add_child(_toast_sci)


func _on_caught(id: String, is_new: bool) -> void:
	var sp := Species.get_data(id)
	for c in _toast_art_holder.get_children():
		c.queue_free()
	var art := UITheme.butterfly_art(id)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_art_holder.add_child(art)
	var stars := Species.rarity_stars(int(sp["rarity"]))
	var rarity: String = Species.RARITY_NAMES[int(sp["rarity"])]
	if is_new:
		_toast_title.text = "New species!   %s  %s" % [rarity, stars]
	else:
		_toast_title.text = "Caught again  (x%d)   %s" % [Game.caught_count(id), stars]
	_toast_name.text = sp["name"]
	_toast_sci.text = sp["sci"]
	_toast.pivot_offset = _toast.size * 0.5
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast.scale = Vector2(0.85, 0.85)
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	_toast_tween.parallel().tween_property(_toast, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(3.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _build_welcome() -> void:
	_welcome = PanelContainer.new()
	_welcome.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_welcome.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_welcome.position = Vector2(0, 110)
	_welcome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_welcome)
	var v := VBoxContainer.new()
	_welcome.add_child(v)
	var t := UITheme.label("Meadowlight", 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := UITheme.label("Sneak up on butterflies and catch them in your net.\nRare ones are shy — crouch down and creep closer.", 20, UITheme.INK_SOFT)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)


func _welcome_fade() -> void:
	if _welcome.has_meta("fading"):
		return
	_welcome.set_meta("fading", true)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(_welcome, "modulate:a", 0.0, 1.5)
	tw.tween_callback(_welcome.hide)


class StealthMeter:
	extends Control
	## Ripples show how much noise you're making; fewer ripples = sneakier.

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var p: Player = Game.player
		if p == null:
			return
		var lvl := p.noise_level()
		var c := Vector2(54, size.y - 54)
		draw_circle(c, 44, Color(0.99, 0.96, 0.88, 0.85))
		draw_arc(c, 44, 0, TAU, 48, Color(0.62, 0.48, 0.34, 0.55), 2.0, true)
		var rings := clampi(int(round(lvl * 3.0)), 1, 5)
		for i in rings:
			var r := 10.0 + i * 6.5
			var a := 1.0 - i * 0.15
			var col := Color(0.35, 0.55, 0.4, a) if lvl < 0.45 else (Color(0.85, 0.6, 0.25, a) if lvl < 1.2 else Color(0.85, 0.35, 0.3, a))
			draw_arc(c, r, -PI * 0.75, -PI * 0.25, 16, col, 3.0, true)
			draw_arc(c, r, PI * 0.25, PI * 0.75, 16, col, 3.0, true)
		draw_circle(c, 5, UITheme.INK)
		var font := ThemeDB.fallback_font
		var text := "Sneaking" if p.sneaking else ("Running" if p.running else "Walking")
		if lvl < 0.45 and not p.sneaking:
			text = "Still"
		var shadow := Color(0.1, 0.05, 0.02, 0.6)
		var light := Color(1, 0.98, 0.92, 0.95)
		draw_string(font, c + Vector2(57, 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, shadow)
		draw_string(font, c + Vector2(56, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, light)
