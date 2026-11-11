class_name DebugCapture
extends Node
## Developer helper for automated screenshots. Arguments after "--":
##   --shot=/path.png --wait=5 --play --class=0 --pos=x,y,z --yaw=r --pitch=r
##   --ads --fire=2.0 --board --nohud --nobots --see_enemy --view=x,y,z,tx,ty,tz
##   --streak=heli|dogs|uav|ready --streak_team=0|1 (call a streak at 1 s)
##   --weapon=id (hold that gun) --reload=t (press reload at t seconds) --empty (start with an empty mag)
##   --armory=0..10  a lit showcase of every gun, the knife, the frag and
##                   both soldiers (0 wide, 1 Cardstock, 2 rifles, 3 second
##                   row, 4 Militia, 5-10 close-ups: M4, AK, sniper, SMG,
##                   shotgun, pistol + knife + frag)

var args: PackedStringArray
var main: Node
var _opts := {}
var _t := 0.0
var _done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in args:
		var s := String(a)
		if s.begins_with("--"):
			var kv := s.substr(2).split("=", true, 1)
			_opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _opts.has("class"):
		Game.settings["class"] = int(_opts["class"])
	if _opts.has("play"):
		main.start_match()
		var p: Player = main.match_node.player
		if _opts.has("nobots"):
			for s in main.match_node.soldiers:
				if s != p:
					s.global_position = Vector3(200, -50, 200)
					s.set_physics_process(false)
		if _opts.has("weapon"):
			var wid := String(_opts["weapon"])
			var watt := String(_opts.get("att", ""))
			p.weapons[p.current] = Weapon.new(wid, watt)
			p.vm.set_weapon(wid, p.team_color(), watt)
			p.model.set_weapon(wid, watt)
		if _opts.has("pos"):
			var v := String(_opts["pos"]).split(",")
			p.global_position = Vector3(float(v[0]), float(v[1]), float(v[2]))
		if _opts.has("yaw"):
			p.yaw = float(_opts["yaw"])
		if _opts.has("pitch"):
			p.aim_pitch = float(_opts["pitch"])
		if _opts.has("pickup"):
			var pk := WeaponPickup.new()
			main.match_node.add_child(pk)
			var fwd0 := Vector3(-sin(p.yaw), 0, -cos(p.yaw))
			pk.setup(String(_opts["pickup"]), 20, 60, p.global_position + fwd0 * 1.2, 1)
		if _opts.has("see_enemy"):
			# Put an enemy bot in plain view, 9 m ahead.
			for s in main.match_node.soldiers:
				if s.team == 1:
					var fwd := Vector3(-sin(p.yaw), 0, -cos(p.yaw))
					s.global_position = p.global_position + fwd * 9.0 + Vector3(1.2, 0, 0)
					(s as Bot).debug_hold = true
					s.set_physics_process(true)
					(s as Bot).yaw = p.yaw + PI
					s.rotation.y = p.yaw + PI
					break
	if _opts.has("cac") and main.menu:
		main.menu._open_cac()
	if _opts.has("armory"):
		_build_armory(int(_opts["armory"]))
	if _opts.has("view") or _opts.has("tour"):
		if main.menu:
			main.menu.visible = false
	if _opts.has("tour"):
		# A list of camera views (x,y,z,tx,ty,tz per line), one PNG each.
		var f := FileAccess.open(String(_opts["tour"]), FileAccess.READ)
		var views := []
		while f and not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line != "" and not line.begins_with("#"):
				views.append(line)
		var cam := Camera3D.new()
		cam.fov = 70.0
		get_tree().current_scene.add_child(cam)
		set_meta("cam", cam)
		set_meta("tour", views)
		set_meta("tour_i", 0)
		set_meta("tour_t", 0.0)
	if _opts.has("view"):
		var v := String(_opts["view"]).split(",")
		var cam := Camera3D.new()
		cam.fov = 60.0
		get_tree().current_scene.add_child(cam)
		var from := Vector3(float(v[0]), float(v[1]), float(v[2]))
		var to := Vector3(float(v[3]), float(v[4]), float(v[5]))
		cam.global_transform = Transform3D(Basis.looking_at(to - from), from)
		cam.make_current()
		set_meta("cam", cam)


func _process(delta: float) -> void:
	_t += delta
	var mn = main.match_node
	if mn and mn.player:
		var p: Player = mn.player
		if _opts.has("ads"):
			Input.action_press("ads")
		if _opts.has("fire") and _t > float(_opts["fire"]) and _t < float(_opts["fire"]) + 0.6:
			Input.action_press("fire")
		elif _opts.has("fire"):
			Input.action_release("fire")
		if _opts.has("board"):
			Input.action_press("scoreboard")
		if _opts.has("nohud") and main.hud:
			main.hud.visible = false
		if _opts.has("empty") and not has_meta("emptied"):
			set_meta("emptied", true)
			p.weapon().mag = 0
			p.weapon().reloading = 0.0
		if _opts.has("reload") and _t > float(_opts["reload"]) and not has_meta("reloaded"):
			set_meta("reloaded", true)
			var w := p.weapon()
			if w.mag <= 0:
				w.mag = 0
			else:
				w.mag = 5
			w.start_reload()
			p.vm.start_reload(w.reload_total, w.mag <= 0)
		if _opts.has("streak") and _t > 1.0 and not has_meta("streaked"):
			set_meta("streaked", true)
			var st_team := int(_opts.get("streak_team", "0"))
			match String(_opts["streak"]):
				"heli":
					mn._call_heli(st_team, p)
				"dogs":
					mn._call_dogs(st_team, p)
				"uav":
					mn._call_uav(st_team, p)
				"ready":
					p.streak = 7
					mn.streaks_ready = {"uav": true, "heli": true, "dogs": true}
		if _opts.has("classes") and _t > 1.0 and not has_meta("classes_open"):
			set_meta("classes_open", true)
			main.pause.open()
			main.pause._open_classes()
		if _opts.has("hold_pitch"):
			p.aim_pitch = float(_opts["pitch"])
	if _opts.has("banner") and _t > 0.5 and not has_meta("banner_done") and mn:
		set_meta("banner_done", true)
		mn.banner.emit("5 KILL STREAK", "You're on a roll", Color(1.0, 0.82, 0.25))
		mn.medal.emit("DOUBLE KILL", 50)
		mn.player.streak = 5
	if has_meta("cam"):
		(get_meta("cam") as Camera3D).make_current()
	if has_meta("tour"):
		var views: Array = get_meta("tour")
		var i: int = get_meta("tour_i")
		var tt: float = float(get_meta("tour_t")) + delta
		set_meta("tour_t", tt)
		var cam: Camera3D = get_meta("cam")
		if i < views.size():
			var v := String(views[i]).split(",")
			var from := Vector3(float(v[0]), float(v[1]), float(v[2]))
			var to := Vector3(float(v[3]), float(v[4]), float(v[5]))
			cam.global_transform = Transform3D(Basis.looking_at(to - from), from)
			if tt > 1.2:
				var img := get_viewport().get_texture().get_image()
				img.save_png("%s_%02d.png" % [String(_opts.get("shot", "/tmp/tour")).trim_suffix(".png"), i])
				set_meta("tour_i", i + 1)
				set_meta("tour_t", 0.0)
		else:
			print("Tour done: ", views.size())
			get_tree().quit()
		return
	if not _done and _t >= float(_opts.get("wait", "4")):
		_done = true
		var img := get_viewport().get_texture().get_image()
		var out := String(_opts.get("shot", "/tmp/shot.png"))
		img.save_png(out)
		var info := ""
		if mn:
			info = " score=%s alive=%d" % [str(mn.team_score), mn.soldiers.filter(func(s): return s.alive).size()]
			for s in mn.soldiers:
				if s is Bot and s.team == 1:
					info += " bot1@%s" % str(s.global_position.snapped(Vector3(0.1, 0.1, 0.1)))
					break
		for d in get_tree().get_nodes_in_group("soldiers"):
			if d is AttackDog:
				info += " dog@%s%s" % [str(d.global_position.snapped(Vector3(0.1, 0.1, 0.1))), "" if d.alive else "(dead)"]
		print("Saved ", out, " fps=", Engine.get_frames_per_second(), info)
		get_tree().quit()


## A felt-covered workbench floating above the apron, in open daylight,
## with every gun, the knife, the frag and one soldier from each team.
func _build_armory(shot: int) -> void:
	if main.menu:
		main.menu.visible = false
	var base := Vector3(30, 30, 10)
	var stand := Node3D.new()
	stand.name = "Armory"
	get_tree().current_scene.add_child(stand)
	stand.global_position = base
	var felt := Craft.mat(Craft.Kind.FELT, Color(0.3, 0.33, 0.3), 0, Color.WHITE, 1.0, 0.0)
	Craft.box(stand, Vector3(0, -0.05, 0), Vector3(3.6, 0.1, 1.8), felt)
	var ids := [["m4", "acog"], ["ak", "reddot"], ["sniper", "suppressor"], ["smg", ""], ["shotgun", "grip"], ["pistol", "suppressor"],
		["lmg", ""], ["dmr", "acog"], ["revolver", ""]]
	if _opts.has("att"):
		for e: Array in ids:
			e[1] = String(_opts["att"])
	for i in ids.size():
		var g := GunBuilder.build(ids[i][0], false, Game.TEAM_COLORS[0], ids[i][1])
		stand.add_child(g)
		var row := i / 3
		var col := i % 3
		# Lie each gun on its side, barrel to the right.
		g.position = Vector3(-1.15 + col * 1.15, 0.22, -0.55 + row * 0.5)
		g.rotation = Vector3(0, -PI * 0.5, 0)
	var kn := GunBuilder.knife(false)
	stand.add_child(kn)
	kn.position = Vector3(-2.4, 0.03, 0.75)
	kn.rotation = Vector3(0, -PI * 0.5, PI * 0.5)
	var fr := GunBuilder.frag(false)
	stand.add_child(fr)
	fr.position = Vector3(-2.0, 0.05, 0.75)
	for t in 2:
		var m := SoldierModel.new()
		m.team = t
		stand.add_child(m)
		var x := -2.4 if t == 0 else 2.4
		Craft.box(stand, Vector3(x, -0.05, 0.2), Vector3(1.0, 0.1, 1.0), felt)
		m.position = Vector3(x, 0.0, 0.2)
		m.rotation.y = PI + (0.35 if t == 0 else -0.35)
		m.set_weapon("m4" if t == 0 else "ak")
		m.animate(0.016, 0.0, 0, 0.0, false)
	var cam := Camera3D.new()
	cam.fov = 40.0
	get_tree().current_scene.add_child(cam)
	var views := [
		[Vector3(0, 2.2, 5.4), Vector3(0, 0.5, 0)],
		[Vector3(-1.9, 1.5, 2.6), Vector3(-2.4, 1.05, 0.2)],
		[Vector3(0.35, 1.9, 1.6), Vector3(0.35, 0.2, -0.4)],
		[Vector3(0.2, 1.9, 2.2), Vector3(0.2, 0.2, 0.2)],
		[Vector3(1.9, 1.5, 2.6), Vector3(2.4, 1.05, 0.2)],
		[Vector3(-0.95, 0.7, 0.45), Vector3(-0.95, 0.2, -0.4)],
		[Vector3(0.2, 0.7, 0.45), Vector3(0.2, 0.2, -0.4)],
		[Vector3(1.5, 0.75, 0.55), Vector3(1.5, 0.2, -0.4)],
		[Vector3(-1.05, 0.65, 0.95), Vector3(-1.05, 0.2, 0.2)],
		[Vector3(0.2, 0.7, 1.05), Vector3(0.2, 0.2, 0.2)],
		[Vector3(1.25, 0.55, 0.95), Vector3(1.25, 0.1, 0.35)],
		[Vector3(0.3, 2.6, 1.6), Vector3(0.3, 0.1, -0.05)],
	]
	var v: Array = views[clampi(shot, 0, views.size() - 1)]
	var from: Vector3 = base + v[0]
	var to: Vector3 = base + v[1]
	cam.global_transform = Transform3D(Basis.looking_at(to - from), from)
	cam.make_current()
	set_meta("cam", cam)
