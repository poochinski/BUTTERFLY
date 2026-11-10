class_name UITheme
extends RefCounted
## Shared look for every menu and panel: warm parchment cards with soft ink.

const INK := Color(0.29, 0.21, 0.15)
const INK_SOFT := Color(0.45, 0.36, 0.28)
const PAPER := Color(0.99, 0.96, 0.88, 0.93)
const PAPER_SOLID := Color(0.98, 0.94, 0.85)
const ACCENT := Color(0.86, 0.45, 0.42)
const GOLD := Color(0.93, 0.68, 0.25)

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 22
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT.darkened(0.2))
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("panel", "Panel", panel_style())
	var normal := card_style(Color(1, 1, 1, 0.35))
	var hover := card_style(Color(1, 0.97, 0.9, 0.85))
	var focus := card_style(Color(1, 0.97, 0.9, 0.85), ACCENT)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", normal)
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 10)
	_theme = t
	return t


static func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PAPER
	s.set_corner_radius_all(18)
	s.set_border_width_all(2)
	s.border_color = Color(0.62, 0.48, 0.34, 0.55)
	s.shadow_color = Color(0.1, 0.05, 0.02, 0.25)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 4)
	s.set_content_margin_all(18)
	return s


static func card_style(bg: Color, border := Color(0.62, 0.48, 0.34, 0.35)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(14)
	s.set_border_width_all(2)
	s.border_color = border
	s.set_content_margin_all(10)
	return s


static func label(text: String, size := 22, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## A square painting of a species' wings (journal shader), kept square
## whatever size its container is.
static func butterfly_art(species_id: String, silhouette := false) -> Control:
	var box := AspectRatioContainer.new()
	box.ratio = 1.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/wing_canvas.gdshader")
	Species.apply_wing(m, Species.get_data(species_id))
	m.set_shader_parameter("silhouette", 1.0 if silhouette else 0.0)
	r.material = m
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(r)
	return box
