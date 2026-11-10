class_name Viewmodel
extends Node3D
## First-person arms and gun. Lives under the camera, draws with its own
## field of view and never clips into walls (see craft_vm.gdshader).
## All motion is procedural: sway, bob, breathing, recoil, aim-down-sights,
## sprint, reloads, swaps, knife and grenade throws.

const HIP := Vector3(0.16, -0.19, -0.44)
const SPRINT_POS := Vector3(0.2, -0.27, -0.34)
const SPRINT_ROT := Vector3(-0.4, 0.95, 0.4)

var team_color := Color(0.24, 0.45, 0.85)
var weapon_id := ""
var gun: Node3D
var knife: Node3D
var frag: Node3D
var _holder: Node3D
var _mag: Node3D
var _mag_rest := Vector3.ZERO
var _pump: Node3D
var _sight := Vector3(0, 0.1, 0)

var _sway := Vector2.ZERO
var _sway_vel := Vector2.ZERO
var _bob := 0.0
var _kick := 0.0
var _kick_rot := Vector2.ZERO
var _reload_t := -1.0
var _reload_total := 1.0
var _swap := 0.0
var _swap_target := 0.0
var _knife_t := -1.0
var _throw_t := -1.0
var _pump_t := -1.0
var _land := 0.0
var _time := 0.0


func _ready() -> void:
	_holder = Node3D.new()
	add_child(_holder)
	knife = GunBuilder.knife(true)
	knife.visible = false
	add_child(knife)
	frag = GunBuilder.frag(true)
	frag.visible = false
	add_child(frag)


func set_weapon(id: String, color: Color) -> void:
	weapon_id = id
	team_color = color
	for c in _holder.get_children():
		c.queue_free()
	gun = GunBuilder.build(id, true, color)
	_holder.add_child(gun)
	_mag = gun.get_meta("mag")
	_mag_rest = _mag.position
	_pump = gun.get_meta("pump") if gun.has_meta("pump") else null
	_sight = gun.get_meta("sight")
	_build_arms()
	_reload_t = -1.0


func muzzle() -> Node3D:
	return gun.get_meta("muzzle") if gun else null


func _build_arms() -> void:
	var sleeve := Craft.outlined(Craft.mat(Craft.Kind.FELT, team_color.darkened(0.15), Craft.Pattern.STITCH, Craft.CREAM, 1.0, 0.0, false, true), 0.003, true)
	var glove := Craft.outlined(Craft.mat(Craft.Kind.FELT, Color(0.24, 0.2, 0.18), 0, Color.WHITE, 1.0, 0.0, false, true), 0.003, true)
	var cuff := Craft.mat(Craft.Kind.KNIT, Craft.CREAM, 0, Color.WHITE, 2.0, 0.0, false, true)
	var right_hand := Vector3(0, -0.035, 0.02)
	var left_hand: Vector3 = gun.get_meta("left")
	_limb(right_hand + Vector3(0.0, -0.02, 0.08), Vector3(0.13, -0.2, 0.32), 0.042, sleeve)
	_limb(Vector3(0.13, -0.2, 0.32), Vector3(0.24, -0.45, 0.6), 0.055, sleeve)
	_limb(left_hand + Vector3(-0.02, -0.04, 0.06), Vector3(-0.16, -0.2, 0.0), 0.04, sleeve)
	_limb(Vector3(-0.16, -0.2, 0.0), Vector3(-0.3, -0.45, 0.4), 0.052, sleeve)
	Craft.part(gun, Craft.sphere(0.05, 10), glove, right_hand, Vector3.ZERO, Vector3(0.8, 1.0, 1.3), false)
	Craft.part(gun, Craft.sphere(0.048, 10), glove, left_hand + Vector3(0, -0.02, 0), Vector3.ZERO, Vector3(0.9, 0.9, 1.3), false)
	Craft.part(gun, Craft.cylinder(0.047, 0.047, 0.03, 10), cuff, right_hand + Vector3(0.0, -0.015, 0.075), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)


func _limb(a: Vector3, b: Vector3, r: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Craft.capsule(r, a.distance_to(b) + r)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gun.add_child(mi)
	var dir := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := dir.cross(ref).normalized()
	var z := x.cross(dir).normalized()
	mi.transform = Transform3D(Basis(x, dir, z), (a + b) * 0.5)


# ---------------------------------------------------------------- events

func kick(strength: float) -> void:
	_kick = minf(_kick + 0.6 * strength, 1.4)
	_kick_rot += Vector2(randf_range(-0.4, 0.4), 1.0) * 0.5 * strength
	if _pump and weapon_id == "shotgun":
		_pump_t = 0.0


func start_reload(total: float) -> void:
	_reload_t = 0.0
	_reload_total = maxf(total, 0.1)


func cancel_reload() -> void:
	_reload_t = -1.0
	if _mag:
		_mag.position = _mag_rest
		_mag.visible = true


func lower() -> void:
	_swap_target = 1.0


func raise() -> void:
	_swap_target = 0.0


func is_lowered() -> bool:
	return _swap > 0.95


func start_knife() -> void:
	_knife_t = 0.0


func start_throw() -> void:
	_throw_t = 0.0


func land(strength: float) -> void:
	_land = clampf(strength, 0.0, 1.0)


## Called every frame by the player.
func animate(delta: float, look_delta: Vector2, speed: float, on_floor: bool, ads: float, sprint: float, crouch: float) -> void:
	_time += delta
	# Sway lags behind the look direction, like a springy paper arm.
	var target_sway := (-look_delta * 0.0018).limit_length(0.08) * (1.0 - ads * 0.75)
	_sway_vel += (target_sway - _sway) * 160.0 * delta
	_sway_vel *= exp(-14.0 * delta)
	_sway += _sway_vel * delta

	var move := clampf(speed / 4.8, 0.0, 1.6) if on_floor else 0.0
	_bob += delta * (speed * 1.9 + 0.001)
	var bob_amt := move * (1.0 - ads * 0.88)
	var bob := Vector3(sin(_bob) * 0.012, -absf(cos(_bob)) * 0.012, 0.0) * bob_amt
	var breathe := Vector3(sin(_time * 1.3) * 0.002, sin(_time * 2.1) * 0.0025, 0.0) * (1.0 - ads * 0.6)

	_kick = move_toward(_kick, 0.0, delta * 9.0)
	_kick_rot = _kick_rot.move_toward(Vector2.ZERO, delta * 7.0)
	_swap = move_toward(_swap, _swap_target, delta * 5.0)
	_land = move_toward(_land, 0.0, delta * 4.0)

	var ads_pos := Vector3(-_sight.x, -_sight.y, -0.28)
	var pos := HIP.lerp(ads_pos, ads)
	var rot := Vector3.ZERO
	pos = pos.lerp(SPRINT_POS, sprint)
	rot = rot.lerp(SPRINT_ROT, sprint)
	pos += bob + breathe
	pos.x += _sway.x * 0.25
	pos.y += _sway.y * 0.25 - _land * 0.04 - crouch * 0.01
	rot.y += _sway.x * 1.2
	rot.x += _sway.y * 1.2 + bob.y * 1.5
	rot.z += _sway.x * 0.6 - sin(_bob) * 0.01 * bob_amt
	pos.z += _kick * 0.035
	pos.y += _kick * 0.004
	rot.x += _kick * 0.06 * (1.0 - ads * 0.5) + _kick_rot.y * 0.02
	rot.y += _kick_rot.x * 0.02

	# Reload: tip the gun, drop the mag out and slap a new one in.
	if _reload_t >= 0.0:
		_reload_t += delta / _reload_total
		var r := _reload_t
		var tilt := smoothstep(0.0, 0.15, r) * (1.0 - smoothstep(0.85, 1.0, r))
		rot += Vector3(0.25, 0.25, 0.55) * tilt
		pos += Vector3(-0.03, -0.05, 0.02) * tilt
		if _mag:
			var out := smoothstep(0.15, 0.3, r) * (1.0 - smoothstep(0.55, 0.75, r))
			_mag.position = _mag_rest + Vector3(0, -0.28, 0.05) * out
			_mag.visible = out < 0.95
			if r > 0.7 and r < 0.78:
				rot.x += 0.05
		if r >= 1.0:
			_reload_t = -1.0
			if _mag:
				_mag.position = _mag_rest
				_mag.visible = true

	# Weapon swap: drop below the screen.
	pos.y -= _swap * 0.35
	rot.x -= _swap * 0.7

	# Knife: gun ducks left, paper knife slashes in from the right.
	if _knife_t >= 0.0:
		_knife_t += delta / 0.5
		var k := _knife_t
		var away := sin(clampf(k, 0.0, 1.0) * PI)
		pos += Vector3(-0.12, -0.12, 0.05) * away
		rot += Vector3(-0.3, 0.4, 0.3) * away
		knife.visible = k < 1.0
		var stab := sin(clampf((k - 0.15) / 0.5, 0.0, 1.0) * PI)
		knife.position = Vector3(0.18, -0.16, -0.3).lerp(Vector3(-0.02, -0.08, -0.62), stab)
		knife.rotation = Vector3(-0.2, 0.5 - stab * 0.6, -0.8 + stab * 0.5)
		if k >= 1.0:
			_knife_t = -1.0
			knife.visible = false

	# Grenade throw: gun dips, knitted frag arcs out from the left hand.
	if _throw_t >= 0.0:
		_throw_t += delta / 0.6
		var t := _throw_t
		var dip := sin(clampf(t, 0.0, 1.0) * PI)
		pos += Vector3(0.06, -0.15, 0.04) * dip
		rot.x -= 0.4 * dip
		frag.visible = t < 0.55
		frag.position = Vector3(-0.2, -0.15, -0.3).lerp(Vector3(-0.05, 0.05, -0.7), smoothstep(0.25, 0.55, t))
		if t >= 1.0:
			_throw_t = -1.0
			frag.visible = false

	if _pump and _pump_t >= 0.0:
		_pump_t += delta / 0.55
		var pt := sin(clampf((_pump_t - 0.3) / 0.7, 0.0, 1.0) * PI)
		_pump.position = Vector3(0, 0, 0.12 * pt)
		if _pump_t >= 1.0:
			_pump_t = -1.0
			_pump.position = Vector3.ZERO

	transform = Transform3D(Basis.from_euler(rot), pos)
