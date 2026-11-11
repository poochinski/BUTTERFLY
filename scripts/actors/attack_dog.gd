class_name AttackDog
extends Soldier
## A killstreak attack dog: a felt shepherd in a team-coloured collar. It
## runs the navmesh toward the nearest enemy and lunges for a takedown. It
## is a full combat target (bullets, frags, knives and bots all treat it as
## an enemy) with a little less health than a soldier.

const SPEED := 7.6
const LUNGE_RANGE := 1.8
const DOG_HEALTH := 70.0

var handler: Soldier
var match_ref: MatchManager
var _body: Node3D
var _legs: Array = []
var _tail: Node3D
var _head: Node3D
var _path := PackedVector3Array()
var _path_i := 0
var _repath := 0.0
var _bite_cd := 0.0
var _run := 0.0
var _dead_t := -1.0
var _bark_t := 0.0
var _hunt: Soldier


func _ready() -> void:
	add_to_group("soldiers")
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.5
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.3
	_capsule.height = 0.8
	_shape = CollisionShape3D.new()
	_shape.shape = _capsule
	_shape.position = Vector3(0, 0.42, 0)
	add_child(_shape)
	health = DOG_HEALTH
	weapons = [Weapon.new("pistol")]
	display_name = "Attack Dog"
	_build_model()
	_bark_t = randf_range(0.5, 2.0)


func _build_model() -> void:
	var tan := Craft.mat(Craft.Kind.FELT, Color(0.6, 0.44, 0.28), Craft.Pattern.STITCH, Color(0.42, 0.3, 0.2))
	var dark := Craft.mat(Craft.Kind.FELT, Color(0.14, 0.12, 0.11))
	var nose := Craft.mat(Craft.Kind.PLASTIC, Color(0.05, 0.05, 0.05))
	var collar := Craft.mat(Craft.Kind.FELT, team_color())
	_body = Craft.pivot(self, Vector3(0, 0.55, 0))
	# Body with the black saddle of a shepherd.
	Craft.part(_body, Craft.capsule(0.19, 0.95), tan, Vector3.ZERO, Vector3(PI * 0.5, 0, 0), Vector3(1.0, 1.0, 0.95))
	Craft.part(_body, Craft.capsule(0.17, 0.62), dark, Vector3(0, 0.07, 0.06), Vector3(PI * 0.5, 0, 0), Vector3(1.08, 1.0, 0.8))
	_head = Craft.pivot(_body, Vector3(0, 0.16, -0.5))
	Craft.part(_head, Craft.sphere(0.15, 12), tan, Vector3.ZERO, Vector3.ZERO, Vector3(0.95, 0.95, 1.1))
	Craft.part(_head, Craft.capsule(0.07, 0.22), dark, Vector3(0, -0.04, -0.15), Vector3(PI * 0.5, 0, 0))
	Craft.part(_head, Craft.sphere(0.035, 8), nose, Vector3(0, -0.02, -0.26))
	for sx: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([Vector2(-0.05, 0), Vector2(0.05, 0), Vector2(0.0, 0.15)])
		Craft.part(_head, Craft.cutout(ear, 0.02), dark, Vector3(sx * 0.08, 0.1, 0.02), Vector3(0, 0, -sx * 0.25))
		Craft.part(_head, Craft.sphere(0.018, 6), nose, Vector3(sx * 0.06, 0.05, -0.13))
	Craft.part(_body, Craft.cylinder(0.15, 0.15, 0.06, 14), collar, Vector3(0, 0.08, -0.38), Vector3(PI * 0.5 - 0.5, 0, 0))
	for p: Vector3 in [Vector3(-0.11, -0.05, -0.32), Vector3(0.11, -0.05, -0.32), Vector3(-0.11, -0.05, 0.32), Vector3(0.11, -0.05, 0.32)]:
		var hip := Craft.pivot(_body, p)
		Craft.part(hip, Craft.capsule(0.055, 0.5), tan, Vector3(0, -0.22, 0))
		Craft.part(hip, Craft.sphere(0.06, 8), dark, Vector3(0, -0.46, -0.03), Vector3.ZERO, Vector3(1.0, 0.6, 1.3))
		_legs.append(hip)
	_tail = Craft.pivot(_body, Vector3(0, 0.08, 0.5))
	Craft.part(_tail, Craft.capsule(0.05, 0.42), dark, Vector3(0, -0.12, 0.12), Vector3(-0.7, 0, 0))
	Craft.make_moving(self)


func team_color() -> Color:
	return Game.TEAM_COLORS[team]


func eye_height() -> float:
	return 0.7


func eye_position() -> Vector3:
	return global_position + Vector3(0, 0.7, 0)


func head_position() -> Vector3:
	return global_position + Vector3(0, 0.7, 0)


func center_position() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)


func hit_zone(_point: Vector3) -> String:
	return "body"


func die(killer: Soldier, weapon_id: String, headshot: bool) -> void:
	super.die(killer, weapon_id, headshot)
	_dead_t = 0.0
	if killer is Player:
		killer.score += 50
		if match_ref:
			match_ref.xp_event.emit(50, "Dog killed")
			match_ref._award(50)


func _nearest_enemy() -> Soldier:
	var best: Soldier = null
	var best_d := INF
	if match_ref == null:
		return null
	for s in match_ref.soldiers:
		if s.team == team or not s.alive:
			continue
		var d := global_position.distance_squared_to(s.global_position)
		if d < best_d:
			best_d = d
			best = s
	return best


func _physics_process(delta: float) -> void:
	if _dead_t >= 0.0:
		# Roll over and fade away.
		_dead_t += delta
		_body.rotation.z = lerpf(_body.rotation.z, PI * 0.5, minf(delta * 8.0, 1.0))
		_body.position.y = lerpf(_body.position.y, 0.22, minf(delta * 6.0, 1.0))
		if _dead_t > 2.5:
			scale = Vector3.ONE * maxf(0.01, 1.0 - (_dead_t - 2.5) * 2.0)
		if _dead_t > 3.0:
			queue_free()
		return
	_bite_cd = maxf(0.0, _bite_cd - delta)
	_repath -= delta
	if _repath <= 0.0 or _hunt == null or not _hunt.alive:
		_repath = 0.6
		_hunt = _nearest_enemy()
		if _hunt:
			var nav := get_world_3d().navigation_map
			_path = NavigationServer3D.map_get_path(nav, global_position, _hunt.global_position, true)
			_path_i = 0
	var want := Vector3.ZERO
	if _hunt:
		var to_target := _hunt.global_position - global_position
		to_target.y = 0.0
		if to_target.length() < LUNGE_RANGE:
			want = to_target.normalized() * 2.0
			if _bite_cd <= 0.0:
				_bite_cd = 0.9
				_hunt.take_damage(120.0, handler if is_instance_valid(handler) else self, "dogs", false, to_target.normalized())
				Sfx.play_3d("bark", global_position, 2.0)
		else:
			while _path_i < _path.size() and Vector2(_path[_path_i].x - global_position.x, _path[_path_i].z - global_position.z).length() < 0.7:
				_path_i += 1
			var next := _hunt.global_position if _path_i >= _path.size() else _path[_path_i]
			var d := next - global_position
			d.y = 0.0
			want = d.normalized() * SPEED if d.length() > 0.05 else Vector3.ZERO
	velocity.x = move_toward(velocity.x, want.x, 40.0 * delta)
	velocity.z = move_toward(velocity.z, want.z, 40.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = maxf(velocity.y, -1.0)
	move_and_slide()
	var flat := Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.5:
		rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), minf(delta * 12.0, 1.0))
	# Gallop: legs in pairs, a bounding body and a wagging tail.
	_run += delta * flat.length() * 2.2
	var g := clampf(flat.length() / SPEED, 0.0, 1.0)
	for i in _legs.size():
		var phase := _run + (0.0 if i < 2 else PI * 0.6) + (0.25 if i % 2 == 1 else 0.0)
		(_legs[i] as Node3D).rotation.x = sin(phase) * 0.8 * g
	_body.position.y = 0.55 + absf(sin(_run)) * 0.06 * g
	_body.rotation.x = sin(_run) * 0.08 * g
	_tail.rotation.y = sin(Time.get_ticks_msec() * 0.02) * 0.4
	_bark_t -= delta
	if _bark_t <= 0.0:
		_bark_t = randf_range(1.2, 3.0)
		Sfx.play_3d("bark", global_position, -3.0)
