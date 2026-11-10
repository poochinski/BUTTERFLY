class_name UIKit
extends RefCounted
## Shared craft look for the interface: paper cards with stitched edges,
## chunky lettering, and helpers to build labels and buttons.

const TITLE_FONT := preload("res://assets/fonts/LuckiestGuy-Regular.ttf")
const BODY_FONT := preload("res://assets/fonts/Fredoka.ttf")
const INK := Color(0.17, 0.11, 0.08)
const PAPER := Color(0.98, 0.94, 0.85)
const KRAFT := Color(0.8, 0.62, 0.42)
const ACCENT := Color(1.0, 0.82, 0.3)

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = BODY_FONT
	t.default_font_size = 22
	t.set_color("font_color", "Label", PAPER)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 6)
	t.set_font("font", "Button", TITLE_FONT)
	t.set_font_size("font_size", "Button", 30)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_stylebox("normal", "Button", card(PAPER, 0.0))
	t.set_stylebox("hover", "Button", card(ACCENT, 0.0))
	t.set_stylebox("focus", "Button", card(ACCENT, 0.0))
	t.set_stylebox("pressed", "Button", card(ACCENT.darkened(0.1), 0.0))
	t.set_stylebox("disabled", "Button", card(Color(0.7, 0.68, 0.64), 0.0))
	t.set_stylebox("panel", "PanelContainer", card(Color(0.16, 0.42, 0.48, 0.92), 0.0))
	t.set_color("font_color", "CheckButton", PAPER)
	t.set_color("font_hover_color", "CheckButton", ACCENT)
	t.set_color("font_focus_color", "CheckButton", ACCENT)
	t.set_color("font_pressed_color", "CheckButton", ACCENT)
	t.set_font_size("font_size", "CheckButton", 24)
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 12)
	var grab := StyleBoxFlat.new()
	grab.bg_color = ACCENT
	grab.set_corner_radius_all(8)
	t.set_stylebox("slider", "HSlider", _slider_bg())
	t.set_icon("grabber", "HSlider", _dot_icon(ACCENT))
	t.set_icon("grabber_highlight", "HSlider", _dot_icon(Color.WHITE))
	_theme = t
	return t


static func card(bg: Color, _tilt: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(10)
	s.set_border_width_all(3)
	s.border_color = INK
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_size = 0
	s.shadow_offset = Vector2(4, 5)
	s.set_content_margin_all(14)
	s.content_margin_left = 22
	s.content_margin_right = 22
	return s


static func _slider_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.1, 0.1, 0.4)
	s.set_corner_radius_all(6)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func _dot_icon(c: Color) -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	for y in 24:
		for x in 24:
			var d := Vector2(x - 11.5, y - 11.5).length()
			var col := Color(0, 0, 0, 0)
			if d < 11.5:
				col = INK
			if d < 8.5:
				col = c
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func label(text: String, size := 22, color := PAPER, title := false, outline := 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	if title:
		l.add_theme_font_override("font", TITLE_FONT)
	return l


static func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func():
		Sfx.play_ui("ui_click")
		cb.call())
	b.focus_entered.connect(func(): Sfx.play_ui("ui_move", -8.0))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


## Dashed "stitches" around a rect, Epic Yarn style.
static func draw_stitches(ci: CanvasItem, r: Rect2, color: Color, inset := 8.0, dash := 10.0, gap := 7.0, width := 3.0) -> void:
	var rr := r.grow(-inset)
	var pts := [rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y), rr.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var len := a.distance_to(b)
		var dir := (b - a) / len
		var t := 0.0
		while t < len:
			ci.draw_line(a + dir * t, a + dir * minf(t + dash, len), color, width, true)
			t += dash + gap
