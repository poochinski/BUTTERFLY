class_name MainMenu
extends CanvasLayer
## Front end: PAPERCUT title over a slow fly-around of the map, play,
## loadout, bot difficulty, settings, rank card.

signal play_pressed
signal quit_pressed
signal map_changed

var _root: Control
var _main: VBoxContainer
var _settings: SettingsPanel
var _class_btn: Button
var _diff_btn: Button
var _map_btn: Button
var _cac: ClassEditor
var _map_l: Label
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
	_map_btn = UIKit.button("", _cycle_map)
	_main.add_child(_map_btn)
	_diff_btn = UIKit.button("", _cycle_difficulty)
	_main.add_child(_diff_btn)
	_main.add_child(UIKit.button("CREATE-A-CLASS", _open_cac))
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
	_map_l = UIKit.label("", 20, UIKit.PAPER)
	cv.add_child(_map_l)

	var hint := UIKit.label("Mouse & keyboard or gamepad", 18, Color(1, 1, 1, 0.75))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(90, -60)
	_root.add_child(hint)

	_cac = ClassEditor.new()
	_cac.visible = false
	_cac.position = Vector2(90, 300)
	_cac.closed.connect(_close_settings)
	_root.add_child(_cac)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.position = Vector2(90, 330)
	_settings.closed.connect(_close_settings)
	_root.add_child(_settings)
	refresh()


func refresh() -> void:
	var ci := int(Game.settings["class"]) % Game.class_count()
	var c := Game.loadout(ci)
	_class_btn.text = "LOADOUT: " + String(c["name"]).to_upper()
	_class_desc.text = Game.describe(c)
	var md := _map_def()
	_map_btn.text = "MAP: " + String(md["name"]).to_upper()
	_map_l.text = "MAP: %s — %s" % [String(md["name"]).to_upper(), md["desc"]]
	_diff_btn.text = "BOTS: " + String(Game.DIFFICULTIES[int(Game.settings["bot_difficulty"])]).to_upper()
	var r := Game.rank_for(int(Game.profile["xp"]))
	_rank_l.text = "LEVEL %d   ·   %s" % [int(r["level"]), r["name"]]
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
	Game.settings["class"] = (int(Game.settings["class"]) + 1) % Game.class_count()
	Game.save_profile()
	refresh()


func _map_def() -> Dictionary:
	for m in Game.MAPS:
		if m["id"] == Game.settings.get("map", "gateway"):
			return m
	return Game.MAPS[0]


func _cycle_map() -> void:
	var i := Game.MAPS.find(_map_def())
	Game.settings["map"] = Game.MAPS[(i + 1) % Game.MAPS.size()]["id"]
	Game.save_profile()
	refresh()
	map_changed.emit()


func _cycle_difficulty() -> void:
	Game.settings["bot_difficulty"] = (int(Game.settings["bot_difficulty"]) + 1) % Game.DIFFICULTIES.size()
	Game.save_profile()
	refresh()


func _open_settings() -> void:
	_main.visible = false
	_settings.open()


func _open_cac() -> void:
	_main.visible = false
	_cac.open()


func _close_settings() -> void:
	_main.visible = true
	refresh()
	_play.grab_focus()


## Create-a-Class: five custom slots. Pick a primary and a secondary from
## the guns your level has unlocked, and one attachment for each from those
## your weapon kills have unlocked. Locked items show what unlocks them.
class ClassEditor:
	extends VBoxContainer
	signal closed

	var _slot := 0
	var _slot_btn: Button
	var _p_btn: Button
	var _pa_btn: Button
	var _s_btn: Button
	var _sa_btn: Button
	var _info: Label

	func _ready() -> void:
		custom_minimum_size = Vector2(620, 0)
		add_theme_constant_override("separation", 10)
		add_child(UIKit.label("CREATE-A-CLASS", 40, UIKit.ACCENT, true))
		_slot_btn = UIKit.button("", func(): _slot = (_slot + 1) % Game.CUSTOM_SLOTS; _refresh())
		add_child(_slot_btn)
		_p_btn = UIKit.button("", func(): _cycle_gun("primary", "p_att", 0))
		add_child(_p_btn)
		_pa_btn = UIKit.button("", func(): _cycle_att("primary", "p_att"))
		add_child(_pa_btn)
		_s_btn = UIKit.button("", func(): _cycle_gun("secondary", "s_att", 1))
		add_child(_s_btn)
		_sa_btn = UIKit.button("", func(): _cycle_att("secondary", "s_att"))
		add_child(_sa_btn)
		_info = UIKit.label("", 19, UIKit.PAPER)
		_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_info.custom_minimum_size = Vector2(600, 0)
		add_child(_info)
		add_child(UIKit.button("USE THIS CLASS", func():
			Game.settings["class"] = WeaponDB.CLASSES.size() + _slot
			_close()))
		add_child(UIKit.button("BACK", _close))

	func open() -> void:
		visible = true
		_refresh()
		_slot_btn.grab_focus()

	func _close() -> void:
		Game.save_profile()
		visible = false
		closed.emit()

	func _cls() -> Dictionary:
		return Game.custom_classes()[_slot]

	func _cycle_gun(key: String, att_key: String, slot: int) -> void:
		var c := _cls()
		var ids := []
		for id in WeaponDB.DATA:
			if int(WeaponDB.DATA[id]["slot"]) == slot and Game.weapon_unlocked(id):
				ids.append(id)
		var i := ids.find(c[key])
		c[key] = ids[(i + 1) % ids.size()]
		c[att_key] = ""
		Sfx.play_ui("ui_click")
		_refresh()

	func _cycle_att(key: String, att_key: String) -> void:
		var c := _cls()
		var opts := [""]
		for a: Array in WeaponDB.ATTACHMENTS.get(c[key], []):
			if Game.attachment_unlocked(c[key], a[0]):
				opts.append(a[0])
		var i := opts.find(c[att_key])
		c[att_key] = opts[(i + 1) % opts.size()]
		Sfx.play_ui("ui_click")
		_refresh()

	func _att_name(att: String) -> String:
		return "NONE (iron sights)" if att == "" else String(WeaponDB.ATTACH[att]).to_upper()

	func _refresh() -> void:
		var c := _cls()
		_slot_btn.text = "SLOT: CUSTOM %d" % (_slot + 1)
		_p_btn.text = "PRIMARY: " + String(WeaponDB.DATA[c["primary"]]["name"]).to_upper()
		_pa_btn.text = "  ATTACHMENT: " + _att_name(String(c["p_att"]))
		_s_btn.text = "SECONDARY: " + String(WeaponDB.DATA[c["secondary"]]["name"]).to_upper()
		_sa_btn.text = "  ATTACHMENT: " + _att_name(String(c["s_att"]))
		# What's still locked, and how to get it.
		var lines := []
		var lv := Game.level()
		var locked := []
		for id in WeaponDB.UNLOCK_LEVEL:
			if int(WeaponDB.UNLOCK_LEVEL[id]) > lv:
				locked.append("%s (level %d)" % [WeaponDB.DATA[id]["name"], WeaponDB.UNLOCK_LEVEL[id]])
		if not locked.is_empty():
			lines.append("Locked guns: " + ", ".join(locked))
		for key: String in ["primary", "secondary"]:
			var id := String(c[key])
			var next := []
			for a: Array in WeaponDB.ATTACHMENTS.get(id, []):
				if not Game.attachment_unlocked(id, a[0]):
					next.append("%s %d/%d kills" % [WeaponDB.ATTACH[a[0]], Game.weapon_kills(id), int(a[1])])
			if not next.is_empty():
				lines.append("%s: %s" % [WeaponDB.DATA[id]["name"], ", ".join(next)])
		_info.text = "\n".join(lines) if not lines.is_empty() else "Everything unlocked for this class."


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
