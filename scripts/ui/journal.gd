class_name Journal
extends CanvasLayer
## The Field Journal: a page of every species. Caught ones are painted in
## full colour with notes; undiscovered ones are faint silhouettes.

var _root: Control
var _grid: GridContainer
var _detail_art: Control
var _detail_name: Label
var _detail_sci: Label
var _detail_meta: Label
var _detail_fact: Label
var _progress: Label
var _cards := {}
var is_open := false


func _ready() -> void:
	layer = 8
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

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 90
	panel.offset_right = -90
	panel.offset_top = 60
	panel.offset_bottom = -60
	var style := UITheme.panel_style()
	style.bg_color = UITheme.PAPER_SOLID
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	panel.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.7
	cols.add_child(left)
	var head := HBoxContainer.new()
	left.add_child(head)
	head.add_child(UITheme.label("Field Journal", 42))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	_progress = UITheme.label("", 22, UITheme.INK_SOFT)
	head.add_child(_progress)
	var rule := ColorRect.new()
	rule.color = Color(0.62, 0.48, 0.34, 0.4)
	rule.custom_minimum_size = Vector2(0, 2)
	left.add_child(rule)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	cols.add_child(right)
	_detail_art = Control.new()
	_detail_art.custom_minimum_size = Vector2(300, 300)
	right.add_child(_detail_art)
	_detail_name = UITheme.label("", 34)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_detail_name)
	_detail_sci = UITheme.label("", 20, UITheme.INK_SOFT)
	right.add_child(_detail_sci)
	_detail_meta = UITheme.label("", 20, UITheme.ACCENT)
	right.add_child(_detail_meta)
	_detail_fact = UITheme.label("", 20)
	_detail_fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_fact.custom_minimum_size = Vector2(300, 0)
	right.add_child(_detail_fact)
	var close_hint := UITheme.label("Tab / Y / Esc to close", 16, UITheme.INK_SOFT)
	close_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	close_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	right.add_child(close_hint)

	for id in Species.ORDER:
		var card := Button.new()
		card.custom_minimum_size = Vector2(150, 170)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_ALL
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 2)
		card.add_child(v)
		var art_holder := Control.new()
		art_holder.custom_minimum_size = Vector2(0, 124)
		art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(art_holder)
		var name_l := UITheme.label("", 15)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(name_l)
		card.focus_entered.connect(_show_detail.bind(id))
		card.mouse_entered.connect(_show_detail.bind(id))
		card.pressed.connect(_show_detail.bind(id))
		_grid.add_child(card)
		_cards[id] = {"button": card, "art": art_holder, "name": name_l}

	Game.journal_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	is_open = not is_open
	_root.visible = is_open
	get_tree().paused = is_open
	if is_open:
		_refresh()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var first: Button = _cards[Species.ORDER[0]]["button"]
		first.grab_focus()
		_show_detail(Species.ORDER[0])
	elif Game.input_mode == Game.InputMode.KEYBOARD:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh() -> void:
	_progress.text = "%d of %d discovered   ·   %d catches" % [Game.journal.size(), Species.ORDER.size(), Game.total_catches]
	for id in Species.ORDER:
		var card: Dictionary = _cards[id]
		var holder: Control = card["art"]
		for c in holder.get_children():
			c.queue_free()
		var known := Game.journal.has(id)
		var art := UITheme.butterfly_art(id, not known)
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.add_child(art)
		var sp := Species.get_data(id)
		var lbl: Label = card["name"]
		lbl.text = sp["name"] if known else "? ? ?"


func _show_detail(id: String) -> void:
	var sp := Species.get_data(id)
	var known := Game.journal.has(id)
	for c in _detail_art.get_children():
		c.queue_free()
	var art := UITheme.butterfly_art(id, not known)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_art.add_child(art)
	var rarity: String = Species.RARITY_NAMES[int(sp["rarity"])]
	if known:
		_detail_name.text = sp["name"]
		_detail_sci.text = sp["sci"]
		_detail_meta.text = "%s   ·   caught %d   ·   first seen day %d" % [rarity, Game.caught_count(id), int(Game.journal[id]["first_day"])]
		_detail_fact.text = sp["fact"]
	else:
		_detail_name.text = "Undiscovered"
		_detail_sci.text = rarity
		var h: Array = sp["hours"]
		_detail_meta.text = "Active around %s – %s" % [_fmt_hour(float(h[0])), _fmt_hour(float(h[1]))]
		_detail_fact.text = _habitat_hint(sp)


func _fmt_hour(h: float) -> String:
	var hh := int(h)
	var suffix := "am" if hh < 12 else "pm"
	var h12 := hh % 12
	if h12 == 0:
		h12 = 12
	return "%d%s" % [h12, suffix]


func _habitat_hint(sp: Dictionary) -> String:
	var hab: Dictionary = sp["habitat"]
	var best := ""
	var best_v := -1.0
	for k in hab:
		if float(hab[k]) > best_v:
			best_v = float(hab[k])
			best = k
	match best:
		"flowers":
			return "Look for it sipping nectar in the flower fields."
		"forest_edge":
			return "Look for it along the edges of the woods."
		"pond":
			return "Look for it near the pond."
		_:
			return "Look for it out in the open meadow grass."
