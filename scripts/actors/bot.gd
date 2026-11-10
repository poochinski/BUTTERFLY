class_name Bot
extends Soldier
## A computer-controlled soldier. It sees (field of view + line of sight),
## hears gunfire, remembers where it last saw you, paths over the navmesh,
## strafes and crouches in fights, aims with human-like reaction time and
## error that settles as it tracks, fires in bursts, reloads, knifes up
## close and throws frags at your last known position.

const SPEED := 4.6
const VIEW_DIST := 85.0
const VIEW_COS := 0.34  # about 70 degrees either side
## [reaction s, turn rad/s, aim error degrees, head-aim chance]
const SKILL := [
	[0.75, 2.6, 7.0, 0.05],
	[0.45, 4.2, 4.0, 0.15],
	[0.3, 6.0, 2.4, 0.25],
	[0.18, 9.0, 1.3, 0.4],
]

var yaw := 0.0
var target: Soldier
var target_visible := false
var last_seen_pos := Vector3.ZERO
var last_seen_t := -100.0
var _skill: Array
var _path := PackedVector3Array()
var _path_i := 0
var _goal := Vector3.ZERO
var _has_goal := false
var _repath := 0.0
var _think := 0.0
var _reaction := 0.0
var _aim_err := Vector2.ZERO
var _strafe := 1.0
var _strafe_t := 0.0
var _burst := 0.0
var _pause := 0.0
var _stuck_t := 0.0
var _stuck_pos := Vector3.ZERO
var _grenade_cd := 8.0
var _knife_cd := 0.0
var _crouch_t := 0.0
var _time := 0.0
var _sprinting := false
## Debug: stand still and hold an aiming pose at the nearest enemy.
var debug_hold := false


func _ready() -> void:
	super._ready()
	_skill = SKILL[clampi(int(Game.settings["bot_difficulty"]), 0, 3)]
	_think = randf() * 0.2
	_grenade_cd = randf_range(6.0, 14.0)


func respawn(at: Transform3D) -> void:
	super.respawn(at)
	yaw = at.basis.get_euler().y
	target = null
	target_visible = false
	last_seen_t = -100.0
	_has_goal = false
	_path = PackedVector3Array()


func hear(pos: Vector3, shooter: Soldier) -> void:
	if not alive or shooter.team == team:
		return
	if pos.distance_to(global_position) < 45.0 and not target_visible:
		last_seen_pos = pos
		last_seen_t = _time
		target = shooter


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_time += delta
	if not alive:
		if model:
			model.animate(delta, 0.0, stance, 0.0, false)
		return
	if debug_hold:
		var tgt := get_tree().get_first_node_in_group("soldiers") as Soldier
		if tgt and tgt != self:
			var to := tgt.eye_position() - eye_position()
			yaw = atan2(-to.x, -to.z)
			aim_pitch = atan2(to.y, Vector2(to.x, to.z).length())
		rotation.y = yaw
		if model:
			model.animate(delta, 0.0, stance, aim_pitch, false)
		return
	_think -= delta
	if _think <= 0.0:
		_think = randf_range(0.1, 0.18)
		_perceive()
	_knife_cd = maxf(0.0, _knife_cd - delta)
	_grenade_cd = maxf(0.0, _grenade_cd - delta)

	var move_dir := Vector3.ZERO
	var want_speed := SPEED * float(weapon().data["move"])
	_sprinting = false
	if target and target_visible and target.alive:
		move_dir = _combat(delta)
		want_speed *= 0.75 if stance == Stance.STAND else (0.5 if stance == Stance.CROUCH else 0.2)
	else:
		if stance != Stance.STAND:
			set_stance(Stance.STAND)
		if target and _time - last_seen_t < 6.0:
			_set_goal(last_seen_pos)
			_maybe_grenade()
		elif not _has_goal or _path_i >= _path.size():
			_pick_roam_goal()
		move_dir = _follow_path(delta)
		_face(move_dir, delta, 5.0)
		aim_pitch = lerpf(aim_pitch, 0.0, minf(delta * 4.0, 1.0))
		if weapon().mag < int(weapon().data["mag"]) * 0.4 and weapon().can_reload():
			weapon().start_reload()
		if _path.size() - _path_i > 3 and _time - last_seen_t > 6.0:
			_sprinting = true
			want_speed *= 1.4

	var hv := Vector3(velocity.x, 0, velocity.z).move_toward(move_dir * want_speed, 30.0 * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()
	rotation.y = yaw
	_check_stuck(delta, move_dir)
	if model:
		model.animate(delta, hv.length(), stance, aim_pitch, _sprinting)


# ------------------------------------------------------------ perception

func _perceive() -> void:
	var eye := eye_position()
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var best: Soldier = null
	var best_d := VIEW_DIST
	var space := get_world_3d().direct_space_state
	for s in get_tree().get_nodes_in_group("soldiers"):
		var o: Soldier = s
		if o.team == team or not o.alive:
			continue
		var to := o.center_position() - eye
		var d := to.length()
		if d > best_d:
			continue
		var flat := Vector3(to.x, 0, to.z).normalized()
		var seen_cone := flat.dot(fwd) > VIEW_COS or d < 6.0 or (o == target and target_visible)
		if not seen_cone:
			continue
		var visible_pt := false
		for p in [o.center_position(), o.head_position()]:
			var q := PhysicsRayQueryParameters3D.create(eye, p, 1)
			if space.intersect_ray(q).is_empty():
				visible_pt = true
				break
		if visible_pt:
			best = o
			best_d = d
	if best:
		if best != target or not target_visible:
			_reaction = float(_skill[0]) * randf_range(0.8, 1.4) + best_d * 0.006
			var e := deg_to_rad(float(_skill[2])) * (1.0 + best_d / 30.0)
			_aim_err = Vector2(randf_range(-e, e) * 2.0, randf_range(-e, e))
		target = best
		target_visible = true
		last_seen_pos = best.global_position
		last_seen_t = _time
	else:
		target_visible = false


# ---------------------------------------------------------------- combat

func _combat(delta: float) -> Vector3:
	var eye := eye_position()
	var aim_at := target.center_position()
	if randf() < float(_skill[3]) * 0.1:
		aim_at = target.head_position()
	var to := aim_at - eye
	var want_yaw := atan2(-to.x, -to.z) + _aim_err.x
	var want_pitch := atan2(to.y, Vector2(to.x, to.z).length()) + _aim_err.y
	var turn := float(_skill[1]) * delta
	yaw = _approach_angle(yaw, want_yaw, turn)
	aim_pitch = move_toward(aim_pitch, want_pitch, turn * 0.8)
	_aim_err = _aim_err.lerp(Vector2.ZERO, minf(delta * 1.6, 1.0))
	_reaction -= delta
	var dist := to.length()

	# Knife if they're right on top of us.
	if dist < 2.0 and _knife_cd <= 0.0:
		_knife_cd = 1.2
		Sfx.play_3d("knife", global_position, -2.0)
		Combat.melee(self, target)
		return Vector3.ZERO

	var w := weapon()
	if w.mag <= 0:
		if w.can_reload():
			w.start_reload()
			Sfx.play_3d("reload", global_position, -8.0)
		elif current == 0:
			switch_weapon(1)
	var aim_dir := Basis.from_euler(Vector3(aim_pitch, yaw, 0)) * Vector3.FORWARD
	var facing_err := aim_dir.angle_to(to.normalized())
	if _reaction <= 0.0 and facing_err < deg_to_rad(6.0) + 0.5 / maxf(dist, 1.0):
		if _pause > 0.0:
			_pause -= delta
		else:
			_burst += delta
			var spread := current_spread(0.65, 0.3, false)
			if w.can_fire():
				var res := fire_weapon(eye, aim_dir, spread, model.muzzle() if model else null)
				if not res.is_empty():
					Fx.muzzle_flash(model.muzzle() if model else null, false)
					var rec: Array = w.data["recoil"]
					aim_pitch += deg_to_rad(float(rec[0])) * 0.5
			var burst_len := 0.5 if w.is_auto() else 0.05
			if _burst > burst_len * randf_range(0.6, 1.4):
				_burst = 0.0
				_pause = randf_range(0.15, 0.45) if w.is_auto() else randf_range(0.25, 0.6)

	# Strafe, sometimes crouch, close distance with shotguns/SMGs.
	_strafe_t -= delta
	if _strafe_t <= 0.0:
		_strafe_t = randf_range(0.5, 1.4)
		_strafe = [-1.0, 1.0, -1.0, 1.0, 0.0][randi() % 5]
		_crouch_t -= 1.0
		if randf() < 0.18 and dist > 8.0:
			set_stance(Stance.CROUCH)
		elif stance == Stance.CROUCH and randf() < 0.5:
			set_stance(Stance.STAND)
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var desired := right * _strafe
	var range_pref := 9.0 if int(w.data["pellets"]) > 1 or String(w.data["class"]) == "Submachine Gun" else 22.0
	if String(w.data["class"]) == "Sniper Rifle":
		range_pref = 40.0
	if dist > range_pref + 6.0:
		desired += fwd * 0.8
	elif dist < range_pref * 0.4:
		desired -= fwd * 0.5
	return desired.normalized() if desired.length() > 0.01 else Vector3.ZERO


func _maybe_grenade() -> void:
	if _grenade_cd > 0.0 or frags <= 0:
		return
	var d := global_position.distance_to(last_seen_pos)
	if d < 9.0 or d > 26.0:
		return
	_grenade_cd = randf_range(14.0, 26.0)
	var eye := eye_position()
	var to := last_seen_pos - eye
	var flat := Vector3(to.x, 0, to.z)
	var dir := (flat.normalized() + Vector3(0, 0.35, 0)).normalized()
	var speed_scale := clampf(flat.length() / 22.0, 0.45, 1.0)
	throw_frag(eye, dir * speed_scale, WeaponDB.FRAG_FUSE - 0.6)


# ------------------------------------------------------------ navigation

func _pick_roam_goal() -> void:
	var map := get_world_3d().navigation_map
	var best := Vector3.ZERO
	var best_score := -INF
	for i in 4:
		var p := NavigationServer3D.map_get_random_point(map, 1, true)
		var s := randf() * 10.0
		# Drift toward the enemy side of the map, like a real player.
		for o in get_tree().get_nodes_in_group("soldiers"):
			var so: Soldier = o
			if so.team != team and so.alive:
				s -= p.distance_to(so.global_position) * 0.05
		if p.y > 3.6:
			s -= 8.0
		if s > best_score:
			best_score = s
			best = p
	_set_goal(best)


func _set_goal(p: Vector3) -> void:
	if _has_goal and p.distance_to(_goal) < 2.0 and _repath > 0.0:
		return
	_goal = p
	_has_goal = true
	_repath = 1.5
	var map := get_world_3d().navigation_map
	_path = NavigationServer3D.map_get_path(map, global_position, p, true)
	_path_i = 0
	if _path.size() > 0 and _path[_path.size() - 1].distance_to(p) > 2.5:
		# Unreachable (roof or island): drop it and roam elsewhere next frame.
		_path = PackedVector3Array()
		_has_goal = false


func _follow_path(delta: float) -> Vector3:
	_repath -= delta
	if _path.is_empty():
		return Vector3.ZERO
	while _path_i < _path.size():
		var p := _path[_path_i]
		var d := Vector2(p.x - global_position.x, p.z - global_position.z)
		if d.length() < 0.6 and absf(p.y - global_position.y) < 1.4:
			_path_i += 1
			continue
		return Vector3(d.x, 0, d.y).normalized()
	_has_goal = false
	return Vector3.ZERO


func _face(dir: Vector3, delta: float, speed: float) -> void:
	if dir.length() < 0.01:
		return
	yaw = _approach_angle(yaw, atan2(-dir.x, -dir.z), speed * delta)


func _check_stuck(delta: float, move_dir: Vector3) -> void:
	if move_dir.length() < 0.1:
		_stuck_t = 0.0
		_stuck_pos = global_position
		return
	_stuck_t += delta
	if _stuck_t > 1.2:
		if global_position.distance_to(_stuck_pos) < 0.4:
			if is_on_floor():
				velocity.y = 6.0
			_has_goal = false
			_path = PackedVector3Array()
		_stuck_t = 0.0
		_stuck_pos = global_position


static func _approach_angle(from: float, to: float, step: float) -> float:
	var diff := wrapf(to - from, -PI, PI)
	if absf(diff) <= step:
		return to
	return from + signf(diff) * step
