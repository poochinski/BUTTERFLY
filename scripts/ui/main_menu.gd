class_name MainMenu
extends CanvasLayer
## Front end: PAPERCUT title over a slow fly-around of the map, play,
## loadout, bot difficulty, settings, rank card.

signal play_pressed
signal quit_pressed

var _root: Control
var _main: VBoxContainer
var _settings: SettingsPanel
var _class_btn: Button
var _diff_btn: Button
var _class_desc: Label
var _rank_l: Label
var _xp_bar: ProgressBar
var _stats_l: Label
var _play: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UIKit.theme()
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.size = Vector2(760, 1080)
	shade.color = Color(0.05, 0.12, 0.14, 0.35)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)

	var title := UIKit.label("PAPERCUT", 150, Color(1.0, 0.86, 0.35), true, 22)
	title.position = Vector2(80, 60)
	title.rotation = -0.04
	_root.add_child(title)
	var sub := UIKit.label("CORRUGATED WARFARE", 34, UIKit.PAPER, true, 10)
	sub.position = Vector2(92, 230)
	_root.add_child(sub)

	_main = VBoxContainer.new()
	_main.position = Vector2(90, 330)
	_main.custom_minimum_size = Vector2(560, 0)
	_main.add_theme_constant_override("separation", 14)
	_root.add_child(_main)
	_play = UIKit.button("PLAY — TEAM DEATHMATCH", func(): play_pressed.emit())
	_main.add_child(_play)
	_class_btn = UIKit.button("", _cycle_class)
	_main.add_child(_class_btn)
	_class_desc = UIKit.label("", 20, UIKit.PAPER)
	_class_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_desc.custom_minimum_size = Vector2(540, 0)
	_main.add_child(_class_desc)
	_diff_btn = UIKit.button("", _cycle_difficulty)
	_main.add_child(_diff_btn)
	_main.add_child(UIKit.button("SETTINGS", _open_settings))
	_main.add_child(UIKit.button("QUIT", func(): quit_pressed.emit()))

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	card.position = Vector2(-520, 60)
	card.custom_minimum_size = Vector2(460, 0)
	_root.add_child(card)
	var cv := VBoxContainer.new()
	card.add_child(cv)
	cv.add_child(UIKit.label("SERVICE RECORD", 26, UIKit.ACCENT, true))
	_rank_l = UIKit.label("", 30, UIKit.PAPER, true)
	cv.add_child(_rank_l)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(400, 22)
	_xp_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.35)
	bg.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIKit.ACCENT
	fill.set_corner_radius_all(8)
	_xp_bar.add_theme_stylebox_override("background", bg)
	_xp_bar.add_theme_stylebox_override("fill", fill)
	cv.add_child(_xp_bar)
	_stats_l = UIKit.label("", 20)
	cv.add_child(_stats_l)
	cv.add_child(UIKit.label("MAP: GATEWAY — papercraft airport", 20, UIKit.PAPER))

	var hint := UIKit.label("Mouse & keyboard or gamepad", 18, Color(1, 1, 1, 0.75))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(90, -60)
	_root.add_child(hint)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.position = Vector2(90, 330)
	_settings.closed.connect(_close_settings)
	_root.add_child(_settings)
	refresh()


func refresh() -> void:
	var c: Dictionary = WeaponDB.CLASSES[int(Game.settings["class"])]
	_class_btn.text = "LOADOUT: " + String(c["name"]).to_upper()
	_class_desc.text = c["desc"]
	_diff_btn.text = "BOTS: " + String(Game.DIFFICULTIES[int(Game.settings["bot_difficulty"])]).to_upper()
	var r := Game.rank_for(int(Game.profile["xp"]))
	_rank_l.text = "%s   (rank %d)" % [r["name"], int(r["index"]) + 1]
	_xp_bar.value = float(r["progress"]) * 100.0
	var k := int(Game.profile["kills"])
	var d := maxi(int(Game.profile["deaths"]), 1)
	_stats_l.text = "XP %d   ·   K/D %.2f   ·   Wins %d / %d" % [int(Game.profile["xp"]), float(k) / d, int(Game.profile["wins"]), int(Game.profile["matches"])]


func show_menu() -> void:
	visible = true
	refresh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_play.grab_focus()


func _cycle_class() -> void:
	Game.settings["class"] = (int(Game.settings["class"]) + 1) % WeaponDB.CLASSES.size()
	Game.save_profile()
	refresh()


func _cycle_difficulty() -> void:
	Game.settings["bot_difficulty"] = (int(Game.settings["bot_difficulty"]) + 1) % Game.DIFFICULTIES.size()
	Game.save_profile()
	refresh()


func _open_settings() -> void:
	_main.visible = false
	_settings.open()


func _close_settings() -> void:
	_main.visible = true
	_play.grab_focus()


class SettingsPanel:
	extends VBoxContainer
	signal closed

	var _first: Control

	func _ready() -> void:
		custom_minimum_size = Vector2(560, 0)
		add_theme_constant_override("separation", 12)
		add_child(UIKit.label("SETTINGS", 40, UIKit.ACCENT, true))
		_first = _slider("Look sensitivity", "sensitivity", 0.2, 3.0, 0.05)
		_slider("Field of view", "fov", 55.0, 95.0, 1.0)
		_slider("Volume", "volume", 0.0, 1.0, 0.05)
		_toggle("Invert look", "invert_y")
		_toggle("Fullscreen", "fullscreen")
		var gq := CheckButton.new()
		gq.text = "High quality graphics (bounce light, depth of field)"
		gq.button_pressed = String(Game.settings.get("graphics", "high")) == "high"
		gq.toggled.connect(func(on):
			Game.settings["graphics"] = "high" if on else "low"
			Game.apply_settings())
		add_child(gq)
		add_child(UIKit.button("BACK", func():
			Game.save_profile()
			visible = false
			closed.emit()))

	func open() -> void:
		visible = true
		_first.grab_focus()

	func _slider(text: String, key: String, lo: float, hi: float, step: float) -> HSlider:
		var row := HBoxContainer.new()
		var l := UIKit.label(text, 22)
		l.custom_minimum_size = Vector2(230, 0)
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = lo
		s.max_value = hi
		s.step = step
		s.value = float(Game.settings[key])
		s.custom_minimum_size = Vector2(240, 30)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UIKit.label("%.2f" % s.value if step < 1.0 else "%d" % int(s.value), 22, UIKit.ACCENT)
		v.custom_minimum_size = Vector2(70, 0)
		s.value_changed.connect(func(val):
			Game.settings[key] = val
			v.text = "%.2f" % val if step < 1.0 else "%d" % int(val)
			Game.apply_settings())
		row.add_child(s)
		row.add_child(v)
		add_child(row)
		return s

	func _toggle(text: String, key: String) -> void:
		var c := CheckButton.new()
		c.text = text
		c.button_pressed = bool(Game.settings[key])
		c.toggled.connect(func(on):
			Game.settings[key] = on
			Game.apply_settings())
		add_child(c)
