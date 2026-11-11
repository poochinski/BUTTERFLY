class_name MatchManager
extends Node3D
## Team Deathmatch, 6 v 6: the player and five bots for Task Force Cardstock
## against six Corrugated Militia bots. First to the score limit, or the
## higher score when time runs out, wins.
##
## Also owns spawning (away from enemies, near friends), scoring and XP,
## killstreaks (UAV at 3 kills), the kill feed and the end of the match.

signal kill_event(killer: Soldier, victim: Soldier, weapon_id: String, headshot: bool)
signal xp_event(amount: int, reason: String)
signal message(text: String, color: Color)
signal score_changed
signal match_ended(winner: int)
signal uav_changed
## Big ribbon banner (killstreaks) and small medal splashes (double kill...).
signal banner(title: String, subtitle: String, color: Color)
signal medal(text: String, xp: int)

const SCORE_LIMIT := 75
const TIME_LIMIT := 600.0
const RESPAWN_BOT := 3.0
const RESPAWN_PLAYER := 4.0
const UAV_KILLS := 3
const HELI_KILLS := 5
const DOG_KILLS := 7
const DOG_TOTAL := 10
const DOG_AT_ONCE := 3
const DOG_TIME := 40.0
## Kill streaks in order: id, kills needed, name.
const STREAKS := [["uav", 3, "UAV"], ["heli", 5, "ATTACK HELI"], ["dogs", 7, "DOGS"]]
const UAV_TIME := 30.0
const TEAM_SIZE := 6

var map: GameMap
var player: Player
var soldiers: Array[Soldier] = []
var team_score := [0, 0]
var time_left := TIME_LIMIT
var ended := false
var winner := -1
var uav_time := [0.0, 0.0]
var uav_ready := false
## The player's earned, unused streaks: id -> true.
var streaks_ready := {}
var _packs: Array = []
var last_fired := {}  # Soldier -> time
var killed_by: Soldier
var respawn_left := 0.0
var clock := 0.0
var first_blood := false
var killed_by_last: Soldier
var _multi := 0
var _last_kill_t := -100.0
var _deaths_since_kill := 0

var _respawns := {}  # Soldier -> seconds remaining
var _uav_plane: Node3D
var _uav_angle := 0.0
var _rank_before := 0


func start(m: GameMap) -> void:
	map = m
	Fx.root = self
	_rank_before = int(Game.rank_for(int(Game.profile["xp"]))["index"])
	var names := Game.BOT_NAMES.duplicate()
	names.shuffle()
	var name_i := 0
	for t in 2:
		for i in TEAM_SIZE:
			var s: Soldier
			if t == 0 and i == 0:
				player = Player.new()
				player.name = "Player"
				player.setup(0, String(Game.settings["player_name"]), int(Game.settings["class"]))
				s = player
			else:
				var b := Bot.new()
				b.name = "Bot_%d_%d" % [t, i]
				b.setup(t, names[name_i % names.size()], randi() % (WeaponDB.CLASSES.size() + WeaponDB.BOT_CLASSES.size()))
				name_i += 1
				s = b
			add_child(s)
			soldiers.append(s)
			s.died.connect(_on_died)
			s.fired.connect(_on_fired)
	var used := {}
	for s in soldiers:
		var list: Array = map.spawns[s.team]
		var idx := 0
		for k in list.size():
			if not used.has(str(s.team) + ":" + str(k)):
				idx = k
				break
		used[str(s.team) + ":" + str(idx)] = true
		var t: Transform3D = list[idx]
		s.respawn(Transform3D(t.basis, t.origin + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))))
	Sfx.play_ui("match_start")
	message.emit("TEAM DEATHMATCH — first to %d" % SCORE_LIMIT, Color(1, 0.92, 0.6))


func _physics_process(delta: float) -> void:
	if ended:
		return
	clock += delta
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_match(0 if team_score[0] > team_score[1] else (1 if team_score[1] > team_score[0] else -1))
		return
	for s in _respawns.keys():
		_respawns[s] -= delta
		if s == player:
			respawn_left = _respawns[s]
			var skip: bool = _respawns[s] < RESPAWN_PLAYER - 1.5 and (Input.is_action_just_pressed("fire") or Input.is_action_just_pressed("jump"))
			if _respawns[s] <= 0.0 or skip:
				_respawns.erase(s)
				s.respawn(pick_spawn(s.team))
				killed_by = null
		elif _respawns[s] <= 0.0:
			_respawns.erase(s)
			s.respawn(pick_spawn(s.team))
	for t in 2:
		if uav_time[t] > 0.0:
			uav_time[t] -= delta
			if uav_time[t] <= 0.0:
				uav_changed.emit()
	_update_uav_plane(delta)
	if player and not player.alive and killed_by and is_instance_valid(killed_by):
		_death_cam(delta)
	_update_dogs(delta)
	if player and player.alive and not player.input_locked:
		if streaks_ready.has("uav") and Input.is_action_just_pressed("killstreak"):
			streaks_ready.erase("uav")
			uav_ready = false
			_call_uav(0, player)
		if streaks_ready.has("heli") and Input.is_action_just_pressed("killstreak2"):
			streaks_ready.erase("heli")
			_call_heli(0, player)
		if streaks_ready.has("dogs") and Input.is_action_just_pressed("killstreak3"):
			streaks_ready.erase("dogs")
			_call_dogs(0, player)


## Chooses where to respawn: far from living enemies, close to friends,
## never in an enemy's line of sight if it can be helped.
func pick_spawn(team: int) -> Transform3D:
	var candidates: Array = map.spawns[team] + map.spawns[-1] + map.spawns[1 - team]
	var best: Transform3D = candidates[0]
	var best_score := -INF
	var space := get_world_3d().direct_space_state
	for c in candidates:
		var t: Transform3D = c
		var p := t.origin
		var nearest_enemy := 999.0
		var near_friend := 999.0
		var seen := false
		for s in soldiers:
			if not s.alive:
				continue
			var d := p.distance_to(s.global_position)
			if s.team != team:
				nearest_enemy = minf(nearest_enemy, d)
				if d < 45.0 and not seen:
					var q := PhysicsRayQueryParameters3D.create(s.eye_position(), p + Vector3(0, 1.4, 0), 1)
					if space.intersect_ray(q).is_empty():
						seen = true
			else:
				near_friend = minf(near_friend, d)
		var score := minf(nearest_enemy, 40.0) * 1.0 - minf(near_friend, 40.0) * 0.35 + randf() * 6.0
		if seen:
			score -= 60.0
		if nearest_enemy < 10.0:
			score -= 100.0
		if score > best_score:
			best_score = score
			best = t
	# Face toward the middle of the map.
	var look := Vector3(8, 0, -4) - best.origin
	var yaw := atan2(-look.x, -look.z)
	return Transform3D(Basis(Vector3.UP, yaw), best.origin)


func _on_fired(s: Soldier) -> void:
	# Suppressed shots don't show on the enemy radar and only carry a short way.
	var quiet := bool(s.weapon().data.get("suppressed", false))
	if not quiet:
		last_fired[s] = clock
	for o in soldiers:
		if o is Bot and o.team != s.team and (not quiet or o.global_position.distance_to(s.global_position) < 15.0):
			(o as Bot).hear(s.global_position, s)


func _on_died(victim: Soldier, killer: Soldier, weapon_id: String, headshot: bool) -> void:
	if ended:
		return
	kill_event.emit(killer, victim, weapon_id, headshot)
	var valid_kill := killer != null and killer != victim and killer.team != victim.team
	if valid_kill:
		killer.kills += 1
		killer.streak += 1
		killer.score += 100 + (50 if headshot else 0)
		team_score[killer.team] += 1
		score_changed.emit()
		if killer == player:
			xp_event.emit(100, "Enemy down")
			Game.profile["kills"] = int(Game.profile["kills"]) + 1
			_count_weapon_kill(weapon_id)
			_award(100)
			_player_medals(victim, weapon_id, headshot)
			_streak_banner(killer.streak)
		elif killer is Bot:
			if killer.streak == UAV_KILLS:
				_call_uav(killer.team, killer)
			elif killer.streak == HELI_KILLS:
				_call_heli(killer.team, killer)
			elif killer.streak == DOG_KILLS:
				_call_dogs(killer.team, killer)
	for a in victim.attackers.keys():
		var att: Soldier = a
		if att != killer and is_instance_valid(att) and att.team != victim.team:
			att.assists += 1
			att.score += 20
			if att == player:
				xp_event.emit(20, "Assist")
				_award(20)
	if valid_kill and not first_blood:
		first_blood = true
	_drop_weapon(victim)
	if victim == player:
		_deaths_since_kill += 1
		player.vm.visible = false
		killed_by = killer if killer != player else null
		killed_by_last = killed_by
		Game.profile["deaths"] = int(Game.profile["deaths"]) + 1
		_respawns[victim] = RESPAWN_PLAYER
		respawn_left = RESPAWN_PLAYER
	else:
		_respawns[victim] = RESPAWN_BOT
	if team_score[0] >= SCORE_LIMIT or team_score[1] >= SCORE_LIMIT:
		_end_match(0 if team_score[0] >= SCORE_LIMIT else 1)


func _player_medals(victim: Soldier, weapon_id: String, headshot: bool) -> void:
	var give := func(text: String, xp: int):
		medal.emit(text, xp)
		_award(xp)
	if not first_blood:
		give.call("FIRST BLOOD", 100)
	if headshot:
		give.call("HEADSHOT", 50)
	if weapon_id == "knife":
		give.call("PAPER CUT!", 50)
	elif weapon_id == "frag":
		give.call("CONFETTI BOMB", 50)
	if victim == killed_by_last:
		give.call("PAYBACK", 50)
		killed_by_last = null
	if _deaths_since_kill >= 4:
		give.call("COMEBACK", 75)
	_deaths_since_kill = 0
	var dist := player.global_position.distance_to(victim.global_position)
	if dist > 38.0 and weapon_id != "knife":
		give.call("LONGSHOT", 50)
	if clock - _last_kill_t < 3.5:
		_multi += 1
	else:
		_multi = 1
	_last_kill_t = clock
	match _multi:
		2:
			give.call("DOUBLE KILL", 50)
		3:
			give.call("TRIPLE KILL", 75)
		4:
			give.call("FURY KILL", 100)
		5, 6, 7, 8:
			give.call("PAPER SHREDDER", 150)


func _streak_banner(n: int) -> void:
	var titles := {
		3: ["3 KILL STREAK", "UAV READY  —  press 5 / D-pad Up"],
		5: ["5 KILL STREAK", "ATTACK HELICOPTER READY  —  press 6 / D-pad Right"],
		7: ["7 KILL STREAK", "ATTACK DOGS READY  —  press 7 / D-pad Left"],
		10: ["10 KILL STREAK", "UNSTOPPABLE"],
		15: ["15 KILL STREAK", "ORIGAMI LEGEND"],
		20: ["20 KILL STREAK", "THE WHOLE CRAFT BOX"],
	}
	if n == UAV_KILLS:
		uav_ready = true
		streaks_ready["uav"] = true
	elif n == HELI_KILLS:
		streaks_ready["heli"] = true
	elif n == DOG_KILLS:
		streaks_ready["dogs"] = true
	if titles.has(n):
		var t: Array = titles[n]
		banner.emit(t[0], t[1], Color(1.0, 0.82, 0.25) if n < 10 else Color(1.0, 0.45, 0.35))
		Sfx.play_ui("streak_ready")
		_award(n * 25)
		xp_event.emit(n * 25, "Kill streak")
	elif n > 20 and n % 5 == 0:
		banner.emit("%d KILL STREAK" % n, "Somebody stop them", Color(1.0, 0.45, 0.35))
		Sfx.play_ui("streak_ready")


func _drop_weapon(victim: Soldier) -> void:
	var w := victim.weapon()
	if w.mag + w.reserve <= 0:
		return
	var p := WeaponPickup.new()
	add_child(p)
	p.setup(w.id, w.mag, w.reserve, victim.global_position, victim.team, w.att)
	var all := get_tree().get_nodes_in_group("pickups")
	if all.size() > 14:
		all[0].queue_free()


## Weapon kills unlock attachments for that gun.
func _count_weapon_kill(weapon_id: String) -> void:
	if not WeaponDB.DATA.has(weapon_id):
		return
	var wk: Dictionary = Game.profile["weapon_kills"]
	var n := int(wk.get(weapon_id, 0)) + 1
	wk[weapon_id] = n
	for a: Array in WeaponDB.ATTACHMENTS.get(weapon_id, []):
		if int(a[1]) == n:
			medal.emit("UNLOCKED: %s" % String(WeaponDB.ATTACH[a[0]]).to_upper(), 0)
			message.emit("%s unlocked for the %s" % [WeaponDB.ATTACH[a[0]], WeaponDB.DATA[weapon_id]["name"]], Color(0.7, 0.92, 1.0))


func _award(xp: int) -> void:
	if Game.add_xp(xp):
		var r := Game.rank_for(int(Game.profile["xp"]))
		Sfx.play_ui("rank_up")
		var lvl := int(r["level"])
		var unlocked := []
		for id in WeaponDB.UNLOCK_LEVEL:
			if int(WeaponDB.UNLOCK_LEVEL[id]) == lvl:
				unlocked.append(String(WeaponDB.DATA[id]["name"]))
		var sub := "Level %d  —  %s" % [lvl, r["name"]]
		if not unlocked.is_empty():
			sub += "   ·   New: " + ", ".join(unlocked)
		banner.emit("LEVEL UP!", sub, Color(0.55, 0.85, 1.0))


func _death_cam(delta: float) -> void:
	# Killcam-lite: look at whoever got you, from where you fell.
	var cam := player.camera
	var target := killed_by.eye_position()
	var from := player.global_position + Vector3(0, 1.4, 0)
	var dir := (target - from).normalized()
	var want := Transform3D(Basis.looking_at(dir), from - dir * 0.5)
	cam.global_transform = cam.global_transform.interpolate_with(want, minf(delta * 4.0, 1.0))
	cam.fov = lerpf(cam.fov, 40.0, minf(delta * 2.0, 1.0))


func _call_uav(team: int, by: Soldier) -> void:
	uav_time[team] = UAV_TIME
	if by == player:
		uav_ready = false
		Sfx.play_ui("streak_use")
		message.emit("UAV ONLINE", Color(0.6, 0.85, 1.0))
	elif team == 0:
		message.emit("Friendly UAV online", Color(0.6, 0.85, 1.0))
	else:
		message.emit("ENEMY UAV ONLINE", Color(1.0, 0.45, 0.4))
	Sfx.play_3d("plane", Vector3(10, 30, 0), 4.0)
	uav_changed.emit()


## 5 kills: an attack helicopter circles for 40 seconds.
func _call_heli(team: int, by: Soldier) -> void:
	var h := AttackHeli.new()
	add_child(h)
	h.setup(self, by, team)
	if by == player:
		Sfx.play_ui("streak_use")
		message.emit("ATTACK HELICOPTER INBOUND", Color(0.6, 0.85, 1.0))
	elif team == 0:
		message.emit("Friendly attack helicopter inbound", Color(0.6, 0.85, 1.0))
	else:
		message.emit("ENEMY ATTACK HELICOPTER INBOUND", Color(1.0, 0.45, 0.4))


## 7 kills: a pack of ten attack dogs, three on the ground at a time, each
## fallen dog replaced until all ten are spent or 40 seconds pass.
func _call_dogs(team: int, by: Soldier) -> void:
	_packs.append({"team": team, "by": by, "released": 0, "alive": [], "t": 0.0})
	if by == player:
		Sfx.play_ui("streak_use")
		message.emit("ATTACK DOGS RELEASED", Color(0.6, 0.85, 1.0))
	elif team == 0:
		message.emit("Friendly dogs released", Color(0.6, 0.85, 1.0))
	else:
		message.emit("ENEMY DOGS INCOMING", Color(1.0, 0.45, 0.4))


func _update_dogs(delta: float) -> void:
	for pack: Dictionary in _packs.duplicate():
		pack["t"] = float(pack["t"]) + delta
		var alive: Array = (pack["alive"] as Array).filter(func(d): return is_instance_valid(d) and d.alive)
		pack["alive"] = alive
		if float(pack["t"]) >= DOG_TIME:
			for d in alive:
				d.queue_free()
			_packs.erase(pack)
			if int(pack["team"]) == 0:
				message.emit("Dogs called off", Color(0.85, 0.9, 1.0))
			continue
		while alive.size() < DOG_AT_ONCE and int(pack["released"]) < DOG_TOTAL:
			alive.append(_release_dog(pack))
			pack["released"] = int(pack["released"]) + 1
		if alive.is_empty() and int(pack["released"]) >= DOG_TOTAL:
			_packs.erase(pack)


func _release_dog(pack: Dictionary) -> AttackDog:
	var team := int(pack["team"])
	var d := AttackDog.new()
	d.team = team
	d.handler = pack["by"]
	d.match_ref = self
	var list: Array = map.spawns[team]
	var t: Transform3D = list[randi() % list.size()]
	add_child(d)
	d.global_position = t.origin + Vector3(randf_range(-1.5, 1.5), 0.3, randf_range(-1.5, 1.5))
	Sfx.play_3d("bark", d.global_position, 4.0)
	return d


## How many dogs a team has on the ground (for the HUD).
func dogs_out(team: int) -> int:
	var n := 0
	for pack: Dictionary in _packs:
		if int(pack["team"]) == team:
			n += (pack["alive"] as Array).size()
	return n


func uav_active(team: int) -> bool:
	return uav_time[team] > 0.0


func is_visible_on_radar(s: Soldier, viewer_team: int) -> bool:
	if s.team == viewer_team:
		return true
	if not s.alive:
		return false
	if uav_active(viewer_team):
		return true
	return clock - float(last_fired.get(s, -100.0)) < 1.6


func _update_uav_plane(delta: float) -> void:
	var active := uav_active(0) or uav_active(1)
	if active and _uav_plane == null:
		_uav_plane = _paper_airplane()
		add_child(_uav_plane)
	elif not active and _uav_plane:
		_uav_plane.queue_free()
		_uav_plane = null
	if _uav_plane:
		_uav_angle += delta * 0.18
		var c := Vector3(5, 38, -4)
		var p := c + Vector3(cos(_uav_angle) * 55.0, sin(_uav_angle * 2.0) * 2.0, sin(_uav_angle) * 40.0)
		var nxt := c + Vector3(cos(_uav_angle + 0.05) * 55.0, 0, sin(_uav_angle + 0.05) * 40.0)
		_uav_plane.global_transform = Transform3D(Basis.looking_at(nxt - p).rotated(Basis.looking_at(nxt - p).z, 0.35), p)


func _paper_airplane() -> Node3D:
	var root := Node3D.new()
	var m := Craft.mat(Craft.Kind.PAPER, Craft.WHITE, Craft.Pattern.BANDS, Color(0.7, 0.85, 1.0), 3.0, 0.0, false)
	for side: float in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(0, -3.0), Vector2(side * 2.4, 2.0), Vector2(0, 1.4)])
		if side < 0.0:
			pts.reverse()
		Craft.part(root, Craft.cutout(pts, 0.03), m, Vector3.ZERO, Vector3(PI * 0.5, 0, side * 0.25))
	Craft.part(root, Craft.cutout(PackedVector2Array([Vector2(0, 0), Vector2(-3.0, 0.0), Vector2(1.6, -0.9)]), 0.03), m, Vector3(0, -0.1, 0), Vector3(0, PI * 0.5, 0))
	return root


func _end_match(w: int) -> void:
	if ended:
		return
	ended = true
	winner = w
	Game.profile["matches"] = int(Game.profile["matches"]) + 1
	if w == 0:
		Game.profile["wins"] = int(Game.profile["wins"]) + 1
		_award(500)
		xp_event.emit(500, "Match won")
		Sfx.play_ui("victory")
	else:
		_award(150)
		xp_event.emit(150, "Match complete")
		Sfx.play_ui("defeat")
	Game.save_profile()
	if player:
		player.input_locked = true
	match_ended.emit(w)


func teams_sorted(team: int) -> Array:
	var list := []
	for s in soldiers:
		if s.team == team:
			list.append(s)
	list.sort_custom(func(a, b): return a.score > b.score)
	return list
