class_name HUD
extends CanvasLayer
## In-match interface laid out like a classic shooter:
## minimap top-left with score underneath, kill feed on the left, ammo and
## grenades bottom-right, crosshair and hitmarkers in the centre, XP
## pop-ups below, plus damage indicators, the sniper scope, the death
## screen and the scoreboard. Dressed in paper, felt and stitches.

var mm: MatchManager
var root: Control
var _minimap: Minimap
var _score_l: Label
var _time_l: Label
var _feed: VBoxContainer
var _weapon_l: Label
var _ammo_l: Label
var _reserve_l: Label
var _frag_l: Label
var _streak_l: Label
var _xp_box: VBoxContainer
var _msg_l: Label
var _msg_t := 0.0
var _center: CenterOverlay
var _death: Control
var _death_l: Label
var _death_sub: Label
var _board: Control
var _board_cols: Array = []
var _end: Control


func setup(m: MatchManager) -> void:
	mm = m
	layer = 5
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIKit.theme()
	add_child(root)

	_center = CenterOverlay.new()
	_center.hud = self
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_center)

	_minimap = Minimap.new()
	_minimap.hud = self
	_minimap.position = Vector2(26, 22)
	_minimap.size = Vector2(250, 250)
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_minimap)

	var score_box := VBoxContainer.new()
	score_box.position = Vector2(30, 286)
	score_box.add_theme_constant_override("separation", 0)
	root.add_child(score_box)
	_score_l = UIKit.label("", 26, UIKit.PAPER, true)
	score_box.add_child(_score_l)
	_time_l = UIKit.label("", 20)
	score_box.add_child(_time_l)

	_feed = VBoxContainer.new()
	_feed.position = Vector2(30, 380)
	_feed.add_theme_constant_override("separation", 2)
	root.add_child(_feed)

	var ammo_box := VBoxContainer.new()
	ammo_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ammo_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ammo_box.position = Vector2(-40, -40)
	ammo_box.alignment = BoxContainer.ALIGNMENT_END
	ammo_box.add_theme_constant_override("separation", 0)
	root.add_child(ammo_box)
	_streak_l = UIKit.label("", 22, UIKit.ACCENT, true)
	_streak_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_box.add_child(_streak_l)
	_weapon_l = UIKit.label("", 22)
	_weapon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_box.add_child(_weapon_l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	ammo_box.add_child(row)
	_frag_l = UIKit.label("", 22, Color(0.75, 0.9, 0.6))
	row.add_child(_frag_l)
	_ammo_l = UIKit.label("", 64, UIKit.PAPER, true, 10)
	row.add_child(_ammo_l)
	_reserve_l = UIKit.label("", 28)
	row.add_child(_reserve_l)

	_xp_box = VBoxContainer.new()
	_xp_box.set_anchors_preset(Control.PRESET_CENTER)
	_xp_box.position = Vector2(-150, 70)
	_xp_box.custom_minimum_size = Vector2(300, 0)
	_xp_box.add_theme_constant_override("separation", 0)
	root.add_child(_xp_box)

	_msg_l = UIKit.label("", 30, UIKit.ACCENT, true, 8)
	_msg_l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_l.position = Vector2(-500, 150)
	_msg_l.size = Vector2(1000, 50)
	root.add_child(_msg_l)

	_build_death()
	_build_board()
	_build_end()

	mm.kill_event.connect(_on_kill)
	mm.xp_event.connect(_on_xp)
	mm.message.connect(_on_message)
	mm.match_ended.connect(_on_end)
	mm.player.hit_confirmed.connect(func(h, k): _center.hitmarker(h, k))
	mm.player.damaged.connect(func(a, d): _center.damage(a, d))


func _process(delta: float) -> void:
	if mm == null or mm.player == null:
		return
	var p := mm.player
	var w := p.weapon()
	_score_l.text = "%s  %d   ·   %d  %s" % [Game.TEAM_SHORT[0], mm.team_score[0], mm.team_score[1], Game.TEAM_SHORT[1]]
	_score_l.add_theme_color_override("font_color", Game.TEAM_COLORS[0].lightened(0.45) if mm.team_score[0] >= mm.team_score[1] else Game.TEAM_COLORS[1].lightened(0.45))
	var t := int(ceil(mm.time_left))
	_time_l.text = "Team Deathmatch   %d:%02d" % [t / 60, t % 60]
	_weapon_l.text = String(w.data["name"]) + ("   RELOADING" if w.reloading > 0.0 else "")
	_ammo_l.text = str(w.mag)
	_ammo_l.add_theme_color_override("font_color", Color(1, 0.4, 0.35) if w.mag <= int(w.data["mag"]) / 4 else UIKit.PAPER)
	_reserve_l.text = "/ %d" % w.reserve
	_frag_l.text = "FRAG x%d   " % p.frags
	if mm.uav_ready:
		_streak_l.text = "UAV READY  [5]" if Game.input_mode == Game.InputMode.KEYBOARD else "UAV READY  [D-PAD UP]"
	else:
		var need := MatchManager.UAV_KILLS - p.streak
		_streak_l.text = "UAV in %d" % need if need > 0 and need < MatchManager.UAV_KILLS else ""
	if mm.uav_active(0):
		_streak_l.text += "\nUAV ONLINE"
	_msg_t -= delta
	_msg_l.modulate.a = clampf(_msg_t, 0.0, 1.0)

	_death.visible = not p.alive and not mm.ended
	if _death.visible:
		_death_l.text = "Folded by %s" % mm.killed_by.display_name if mm.killed_by else "You folded"
		var r := maxf(0.0, mm.respawn_left)
		_death_sub.text = "Respawning in %.0f   ·   press Fire to redeploy" % ceil(r) if r < MatchManager.RESPAWN_PLAYER - 1.5 else "Respawning in %.0f" % ceil(r)
	_board.visible = (Input.is_action_pressed("scoreboard") and not mm.ended) or mm.ended
	if _board.visible:
		_fill_board()
	_center.queue_redraw()
	_minimap.queue_redraw()


func _on_kill(killer: Soldier, victim: Soldier, weapon_id: String, headshot: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if killer and killer != victim:
		row.add_child(UIKit.label(killer.display_name, 20, Game.TEAM_COLORS[killer.team].lightened(0.4)))
	var wname := "Knife" if weapon_id == "knife" else ("Frag" if weapon_id == "frag" else ("Fall" if weapon_id == "fall" else String(WeaponDB.DATA[weapon_id]["name"]) if WeaponDB.DATA.has(weapon_id) else weapon_id))
	row.add_child(UIKit.label("[" + wname + ("  HS" if headshot else "") + "]", 18, UIKit.ACCENT))
	row.add_child(UIKit.label(victim.display_name, 20, Game.TEAM_COLORS[victim.team].lightened(0.4)))
	_feed.add_child(row)
	if _feed.get_child_count() > 5:
		_feed.get_child(0).queue_free()
	var tw := row.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(row, "modulate:a", 0.0, 0.8)
	tw.tween_callback(row.queue_free)


func _on_xp(amount: int, reason: String) -> void:
	var l := UIKit.label("+%d  %s" % [amount, reason], 28, UIKit.ACCENT, true, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_box.add_child(l)
	l.pivot_offset = Vector2(150, 20)
	l.scale = Vector2(1.4, 1.4)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


func _on_message(text: String, color: Color) -> void:
	_msg_l.text = text
	_msg_l.add_theme_color_override("font_color", color)
	_msg_t = 3.5


func _build_death() -> void:
	_death = VBoxContainer.new()
	_death.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_death.position = Vector2(-450, -260)
	_death.size = Vector2(900, 120)
	_death.visible = false
	root.add_child(_death)
	_death_l = UIKit.label("", 42, Color(1, 0.55, 0.45), true, 10)
	_death_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death.add_child(_death_l)
	_death_sub = UIKit.label("", 22)
	_death_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death.add_child(_death_sub)


func _build_board() -> void:
	_board = PanelContainer.new()
	_board.set_anchors_preset(Control.PRESET_CENTER)
	_board.custom_minimum_size = Vector2(1100, 0)
	_board.position = Vector2(-550, -260)
	_board.visible = false
	root.add_child(_board)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 40)
	_board.add_child(h)
	for t in 2:
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 4)
		h.add_child(v)
		_board_cols.append(v)


func _fill_board() -> void:
	for t in 2:
		var v: VBoxContainer = _board_cols[t]
		for c in v.get_children():
			c.queue_free()
		var head := UIKit.label("%s   %d" % [Game.TEAM_NAMES[t], mm.team_score[t]], 26, Game.TEAM_COLORS[t].lightened(0.45), true)
		v.add_child(head)
		v.add_child(UIKit.label("Name                         Score   K   D   A", 16, Color(1, 1, 1, 0.7)))
		for s in mm.teams_sorted(t):
			var so: Soldier = s
			var line := "%-24s %6d %4d %4d %4d" % [so.display_name + ("  (you)" if so == mm.player else ""), so.score, so.kills, so.deaths, so.assists]
			var l := UIKit.label(line, 20, UIKit.ACCENT if so == mm.player else UIKit.PAPER)
			l.add_theme_font_override("font", UIKit.BODY_FONT)
			v.add_child(l)


func _build_end() -> void:
	_end = VBoxContainer.new()
	_end.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_end.position = Vector2(-500, 60)
	_end.size = Vector2(1000, 140)
	_end.visible = false
	root.add_child(_end)


func _on_end(winner: int) -> void:
	_end.visible = true
	var txt := "VICTORY" if winner == 0 else ("DEFEAT" if winner == 1 else "DRAW")
	var col := Color(1, 0.85, 0.3) if winner == 0 else (Color(1, 0.45, 0.4) if winner == 1 else UIKit.PAPER)
	var big := UIKit.label(txt, 110, col, true, 14)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end.add_child(big)
	var r := Game.rank_for(int(Game.profile["xp"]))
	var sub := UIKit.label("%s   ·   %d XP   ·   returning to base…" % [r["name"], int(Game.profile["xp"])], 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end.add_child(sub)
	_board.position.y = -120


# ===================================================================== widgets

class CenterOverlay:
	extends Control
	## Crosshair, hitmarker, damage vignette and arrows, scope, grenade cook.

	var hud: HUD
	var _hit := 0.0
	var _hit_kill := false
	var _hit_head := false
	var _dmg := 0.0
	var _arrows: Array = []

	func hitmarker(head: bool, kill: bool) -> void:
		_hit = 1.0
		_hit_kill = kill
		_hit_head = head

	func damage(amount: float, from_dir: Vector3) -> void:
		_dmg = minf(_dmg + amount / 60.0, 1.0)
		_arrows.append({"dir": -from_dir, "t": 1.4})

	func _process(delta: float) -> void:
		_hit = maxf(0.0, _hit - delta * 4.0)
		_dmg = maxf(0.0, _dmg - delta * 0.5)
		for a in _arrows:
			a["t"] -= delta
		_arrows = _arrows.filter(func(a): return a["t"] > 0.0)

	func _draw() -> void:
		var p := hud.mm.player
		if p == null:
			return
		var c := size * 0.5
		var ink := Color(0.1, 0.06, 0.04, 0.9)
		if p.alive and not hud.mm.ended:
			if p.is_scoped():
				_draw_scope(c)
			elif p.ads < 0.5 and not p.sprinting:
				var spread := p.current_spread(p.ads, clampf(Vector2(p.velocity.x, p.velocity.z).length() / Player.WALK, 0.0, 1.0), not p.is_on_floor())
				var px := tan(deg_to_rad(spread)) / tan(deg_to_rad(p.camera.fov) * 0.5) * size.y * 0.5 + 6.0
				var a := 1.0 - p.ads * 2.0
				for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					var s: Vector2 = c + d * px
					var e: Vector2 = c + d * (px + 12.0)
					draw_line(s, e, Color(ink.r, ink.g, ink.b, a), 5.0, true)
					draw_line(s, e, Color(1, 0.97, 0.9, a), 2.5, true)
			if _hit > 0.0:
				var col := Color(1, 0.3, 0.25, _hit) if _hit_kill else Color(1, 1, 1, _hit)
				var r := 10.0 + (1.0 - _hit) * 4.0
				for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
					draw_line(c + d * r * 0.6, c + d * r * 1.6, Color(0, 0, 0, _hit * 0.7), 5.0, true)
					draw_line(c + d * r * 0.6, c + d * r * 1.6, col, 2.5, true)
			if p.cooking() >= 0.0:
				var frac := p.cooking() / WeaponDB.FRAG_FUSE
				draw_arc(c + Vector2(0, 70), 22, -PI * 0.5, -PI * 0.5 + TAU * frac, 32, Color(1, 0.4, 0.3), 6.0, true)
		# Red paper vignette when hurt.
		var hurt := clampf(1.0 - p.health / Soldier.MAX_HEALTH, 0.0, 1.0) * 0.8 + _dmg * 0.3
		if hurt > 0.02 and p.alive:
			var steps := 18
			for i in steps:
				var t := float(i) / steps
				var a2 := hurt * (1.0 - t) * 0.12
				var inset := t * size.y * 0.22
				draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(0.7, 0.05, 0.05, a2), false, size.y * 0.012)
		# Damage direction arrows (torn paper wedges around the centre).
		for a3 in _arrows:
			var d3: Vector3 = a3["dir"]
			var local := p.global_transform.basis.inverse() * d3
			var ang := atan2(local.x, -local.z)
			var dir2 := Vector2(sin(ang), -cos(ang))
			var base := c + dir2 * 150.0
			var side := Vector2(-dir2.y, dir2.x)
			var alpha := clampf(float(a3["t"]), 0.0, 1.0)
			draw_colored_polygon(PackedVector2Array([base + dir2 * 30.0, base + side * 34.0, base - side * 34.0]), Color(0.85, 0.1, 0.08, alpha * 0.85))

	func _draw_scope(c: Vector2) -> void:
		var r := size.y * 0.46
		var dark := Color(0.06, 0.05, 0.04)
		draw_rect(Rect2(Vector2.ZERO, Vector2(c.x - r, size.y)), dark)
		draw_rect(Rect2(Vector2(c.x + r, 0), Vector2(size.x - c.x - r, size.y)), dark)
		var steps := 64
		for i in steps:
			var a0 := TAU * i / steps
			var a1 := TAU * (i + 1) / steps
			var p0 := c + Vector2(cos(a0), sin(a0)) * r
			var p1 := c + Vector2(cos(a1), sin(a1)) * r
			var q0 := c + Vector2(cos(a0), sin(a0)) * r * 2.0
			var q1 := c + Vector2(cos(a1), sin(a1)) * r * 2.0
			draw_colored_polygon(PackedVector2Array([p0, q0, q1, p1]), dark)
		# Kraft paper tube rim and a hand-drawn reticle.
		draw_arc(c, r, 0, TAU, 96, Color(0.8, 0.62, 0.42), 14.0, true)
		draw_arc(c, r - 8, 0, TAU, 96, Color(0.1, 0.06, 0.04), 3.0, true)
		var ink := Color(0.08, 0.05, 0.03)
		draw_line(c - Vector2(r, 0), c - Vector2(14, 0), ink, 3.0, true)
		draw_line(c + Vector2(14, 0), c + Vector2(r, 0), ink, 3.0, true)
		draw_line(c - Vector2(0, r), c - Vector2(0, 14), ink, 3.0, true)
		draw_line(c + Vector2(0, 14), c + Vector2(0, r), ink, 3.0, true)
		draw_circle(c, 3.0, Color(0.9, 0.15, 0.1))


class Minimap:
	extends Control
	## Rotating radar: the real map photographed from above, teammates as
	## arrows, enemies as red dots when they fire or a UAV is up.

	var hud: HUD
	var texture: Texture2D
	const SCALE := 3.0

	func _ready() -> void:
		clip_contents = true

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.16, 0.42, 0.48, 0.92))
		var mm := hud.mm
		var p := mm.player
		if p == null:
			return
		var c := size * 0.5
		var me := p.global_position
		var yaw := p.yaw if p is Player else p.rotation.y
		draw_set_transform(c, yaw, Vector2.ONE)
		if texture:
			var b := GatewayMap.BOUNDS
			draw_texture_rect(texture, Rect2((Vector2(b.position.x, b.position.y) - Vector2(me.x, me.z)) * SCALE, b.size * SCALE), false, Color(1, 1, 1, 0.92))
		for s in mm.soldiers:
			if s == p or not s.alive:
				continue
			if not mm.is_visible_on_radar(s, p.team):
				continue
			var pos := (Vector2(s.global_position.x, s.global_position.z) - Vector2(me.x, me.z)) * SCALE
			if s.team == p.team:
				var f := Vector2(-sin(s.rotation.y), -cos(s.rotation.y))
				var side := Vector2(-f.y, f.x)
				draw_colored_polygon(PackedVector2Array([pos + f * 8, pos + side * 5 - f * 5, pos - side * 5 - f * 5]), Game.TEAM_COLORS[s.team].lightened(0.3))
			else:
				draw_circle(pos, 6.5, Color(0.1, 0.05, 0.04))
				draw_circle(pos, 5.0, Color(1.0, 0.25, 0.2))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11), c + Vector2(8, 8), c + Vector2(0, 4), c + Vector2(-8, 8)]), UIKit.ACCENT)
		draw_polyline(PackedVector2Array([c + Vector2(0, -11), c + Vector2(8, 8), c + Vector2(0, 4), c + Vector2(-8, 8), c + Vector2(0, -11)]), UIKit.INK, 2.0, true)
		draw_rect(r, UIKit.INK, false, 4.0)
		UIKit.draw_stitches(self, r, Color(1, 0.95, 0.85, 0.8), 7.0, 9.0, 6.0, 2.0)
		# Compass letter for north.
		var n := Vector2(sin(-yaw), -cos(-yaw)) * (size.x * 0.42) + c
		draw_string(UIKit.TITLE_FONT, n + Vector2(-7, 8), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.ACCENT)
		if mm.uav_active(p.team):
			draw_string(UIKit.TITLE_FONT, Vector2(10, size.y - 10), "UAV", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.85, 1.0))
