class_name AttackHeli
extends Node3D
## The 5-kill streak: a papercraft attack helicopter that circles the map
## for 40 seconds, banking through its orbit, and hoses any enemy it has a
## clear line of sight to with its chin gun. Kills are credited to whoever
## called it in.

const LIFETIME := 40.0
const DAMAGE := 16.0
const RANGE := 95.0
const BURST := 1.4
const REST := 0.8
const ROF := 0.09

var owner_soldier: Soldier
var team := 0
var match_ref: MatchManager
var _t := 0.0
var _angle := 0.0
var _center := Vector3.ZERO
var _radius := Vector2(40, 30)
var _alt := 24.0
var _rotor: Node3D
var _tail_rotor: Node3D
var _gun: Node3D
var _target: Soldier
var _burst := 0.0
var _rest := 0.0
var _shot_cd := 0.0
var _scan := 0.0
var _audio: AudioStreamPlayer3D
var _leaving := false


func setup(m: MatchManager, by: Soldier, t: int) -> void:
	match_ref = m
	owner_soldier = by
	team = t
	var b := m.map.bounds
	_center = Vector3(b.get_center().x, 0, b.get_center().y)
	_radius = Vector2(b.size.x * 0.3, b.size.y * 0.3)
	_alt = m.map.heli_height
	_angle = randf() * TAU
	_build()
	global_position = _orbit_point(_angle) + Vector3(0, 30, 0)
	_audio = AudioStreamPlayer3D.new()
	_audio.stream = Sfx._bank["rotor"]
	_audio.volume_db = 2.0
	_audio.unit_size = 18.0
	_audio.max_distance = 260.0
	add_child(_audio)
	_audio.play()


func _orbit_point(a: float) -> Vector3:
	return _center + Vector3(cos(a) * _radius.x, _alt, sin(a) * _radius.y)


func _build() -> void:
	var paint := GunBuilder.painted(Craft.Kind.PAPER, Color(0.27, 0.3, 0.24), 0.6, false)
	var dark := Craft.mat(Craft.Kind.PAPER, Color(0.12, 0.12, 0.13))
	var glass := Craft.cellophane(Color(0.35, 0.45, 0.5, 0.5))
	var stripe := Craft.mat(Craft.Kind.PAPER, Game.TEAM_COLORS[team])
	var o := 0.02
	var body := Craft.pivot(self)
	# Narrow tandem-seat fuselage, canopy, stub wings with rocket pods,
	# tail boom and fin, skids, and a chin turret.
	Craft.part(body, Craft.capsule(0.75, 5.0), Craft.outlined(paint, o), Vector3(0, 0, 0), Vector3(PI * 0.5, 0, 0), Vector3(0.8, 1.0, 1.0))
	Craft.part(body, Craft.capsule(0.55, 2.4), glass, Vector3(0, 0.45, -1.0), Vector3(PI * 0.5 - 0.08, 0, 0), Vector3(0.75, 1.0, 1.0), false)
	Craft.box(body, Vector3(0, 0.0, 3.6), Vector3(0.35, 0.4, 4.0), Craft.outlined(paint, o))
	Craft.box(body, Vector3(0, 0.75, 5.4), Vector3(0.12, 1.5, 0.9), Craft.outlined(paint, o), Vector3(-0.3, 0, 0))
	Craft.box(body, Vector3(0, 0.0, 5.3), Vector3(1.6, 0.08, 0.5), Craft.outlined(paint, o))
	Craft.box(body, Vector3(0, 0.0, 1.2), Vector3(1.16, 0.25, 0.5), stripe)
	for sx: float in [-1.0, 1.0]:
		Craft.box(body, Vector3(sx * 0.95, -0.15, 0.2), Vector3(1.2, 0.1, 0.8), Craft.outlined(paint, o))
		Craft.part(body, Craft.cylinder(0.2, 0.2, 1.3, 10), dark, Vector3(sx * 1.4, -0.38, 0.1), Vector3(PI * 0.5, 0, 0))
		Craft.box(body, Vector3(sx * 0.6, -1.15, 0.0), Vector3(0.08, 0.08, 3.4), dark)
		for z: float in [-0.9, 0.9]:
			Craft.box(body, Vector3(sx * 0.5, -0.9, z), Vector3(0.06, 0.5, 0.06), dark, Vector3(0, 0, sx * 0.3))
	_gun = Craft.pivot(body, Vector3(0, -0.65, -1.9))
	Craft.part(_gun, Craft.sphere(0.25, 10), dark)
	Craft.part(_gun, Craft.cylinder(0.05, 0.05, 0.9, 8), dark, Vector3(0, 0, -0.45), Vector3(PI * 0.5, 0, 0))
	# Main rotor mast and blades (paper strips), tail rotor.
	Craft.part(body, Craft.cylinder(0.14, 0.18, 0.6, 10), dark, Vector3(0, 1.0, -0.2))
	_rotor = Craft.pivot(body, Vector3(0, 1.32, -0.2))
	for i in 4:
		Craft.box(_rotor, Vector3.ZERO, Vector3(0.32, 0.04, 6.4), dark, Vector3(0, i * PI * 0.25, 0))
	_tail_rotor = Craft.pivot(body, Vector3(0.22, 0.9, 5.6))
	for i in 2:
		Craft.box(_tail_rotor, Vector3.ZERO, Vector3(0.04, 1.3, 0.14), dark, Vector3(i * PI * 0.5, 0, 0))
	Craft.make_moving(self)


func _physics_process(delta: float) -> void:
	_t += delta
	_rotor.rotation.y += delta * 26.0
	_tail_rotor.rotation.x += delta * 40.0
	if _t > LIFETIME and not _leaving:
		_leaving = true
		if match_ref:
			match_ref.message.emit("Attack helicopter leaving", Color(0.85, 0.9, 1.0))
	# Fly the orbit (climbing in at the start, out at the end) and bank.
	var speed := 0.2
	_angle += delta * speed
	var p := _orbit_point(_angle)
	if _t < 3.0:
		p.y += (3.0 - _t) * 10.0
	if _leaving:
		p += Vector3(cos(_angle), 0, sin(_angle)) * (_t - LIFETIME) * 25.0 + Vector3(0, (_t - LIFETIME) * 6.0, 0)
		if _t > LIFETIME + 6.0:
			queue_free()
			return
	var ahead := _orbit_point(_angle + 0.06)
	var fwd := (ahead - global_position)
	fwd.y = 0.0
	global_position = global_position.lerp(p, minf(delta * 2.0, 1.0))
	if fwd.length() > 0.01:
		var basis := Basis.looking_at(fwd.normalized(), Vector3.UP)
		basis = basis.rotated(basis.z.normalized(), -0.32).rotated(basis.x.normalized(), -0.08)
		global_transform.basis = global_transform.basis.slerp(basis.orthonormalized(), minf(delta * 3.0, 1.0))
	if _leaving or _t < 2.0:
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.35
		_target = _pick_target()
	if _target == null or not _target.alive:
		_burst = 0.0
		return
	var aim := _target.center_position()
	_gun.global_transform = Transform3D(Basis.looking_at(aim - _gun.global_position, Vector3.UP), _gun.global_position)
	if _rest > 0.0:
		_rest -= delta
		return
	_burst += delta
	if _burst > BURST:
		_burst = 0.0
		_rest = REST
		return
	_shot_cd -= delta
	if _shot_cd <= 0.0:
		_shot_cd = ROF
		_fire_at(aim)


func _pick_target() -> Soldier:
	var best: Soldier = null
	var best_d := RANGE * RANGE
	var space := get_world_3d().direct_space_state
	for n in get_tree().get_nodes_in_group("soldiers"):
		var s: Soldier = n
		if s.team == team or not s.alive:
			continue
		var d := _gun.global_position.distance_squared_to(s.center_position())
		if d > best_d:
			continue
		var q := PhysicsRayQueryParameters3D.create(_gun.global_position, s.center_position(), 1)
		if not space.intersect_ray(q).is_empty():
			continue
		best_d = d
		best = s
	return best


func _fire_at(aim: Vector3) -> void:
	var from := _gun.global_position
	var dir := (aim - from).normalized()
	# A heavy gun from a moving platform: a fairly wide cone.
	var spread := deg_to_rad(1.6)
	var ref := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	var x := dir.cross(ref).normalized()
	var y := x.cross(dir).normalized()
	var a := randf() * TAU
	var r := sqrt(randf()) * tan(spread)
	dir = (dir + (x * cos(a) + y * sin(a)) * r).normalized()
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * RANGE * 1.2, Combat.MASK_SHOTS)
	var hit := space.intersect_ray(q)
	var end := from + dir * RANGE * 1.2
	if not hit.is_empty():
		end = hit["position"]
		var col = hit["collider"]
		if col is Soldier:
			var victim: Soldier = col
			if victim.alive and victim.team != team:
				var credit: Soldier = owner_soldier if is_instance_valid(owner_soldier) else null
				victim.take_damage(DAMAGE, credit, "heli", false, dir)
		else:
			Fx.impact(end, hit["normal"], Color(0.55, 0.5, 0.42), false)
	Fx.tracer(from + dir * 0.9, end, Color(1.0, 0.7, 0.4))
	Sfx.play_3d("heli_gun", from, -2.0)
