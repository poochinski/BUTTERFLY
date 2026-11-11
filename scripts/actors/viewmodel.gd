class_name Viewmodel
extends Node3D
## First-person arms and gun. Lives under the camera, draws with its own
## field of view and never clips into walls (see craft_vm.gdshader).
## All motion is procedural: sway, bob, breathing, jump and landing, recoil,
## aim-down-sights, sprint, swaps, knife and grenade throws, and full
## reloads where the support hand really fetches each magazine (or shell),
## the old mag drops to the floor, and empty guns are charged again.
## Pistol slides recoil and lock back, sniper bolts are cycled by hand and
## brass flies out of the ejection port.

const HIP := Vector3(0.15, -0.175, -0.52)
const HIP_ROT := Vector3(0.0, 0.05, 0.0)
const SPRINT_POS := Vector3(0.2, -0.27, -0.34)
const SPRINT_ROT := Vector3(-0.4, 0.95, 0.4)
const OFFSCREEN := Vector3(-0.05, -0.42, 0.12)

var team_color := Color(0.2, 0.28, 0.44)
var weapon_id := ""
var gun: Node3D
var knife: Node3D
var frag: Node3D
var _model := ""
var _holder: Node3D
var _left: Node3D
var _shell: Node3D
var _mag: Node3D
var _mag_rest := Vector3.ZERO
var _mag_grip := Vector3.ZERO
var _hand := Vector3.ZERO
var _pump: Node3D
var _slide: Node3D
var _bolt: Node3D
var _charge: Node3D
var _eject: Node3D
var _sight := Vector3(0, 0.1, 0)
var _ads_z := -0.28

var _sway := Vector2.ZERO
var _sway_vel := Vector2.ZERO
var _bob := 0.0
var _kick := 0.0
var _kick_rot := Vector2.ZERO
var _kick_roll := 0.0
var _reload_t := -1.0
var _reload_total := 1.0
var _empty_reload := false
var _keys: Array = []
var _dropped := false
var _slapped := false
var _bolted := false
var _swap := 0.0
var _swap_target := 0.0
var _knife_t := -1.0
var _throw_t := -1.0
var _pump_t := -1.0
var _slide_t := -1.0
var _slide_locked := false
var _bolt_t := -1.0
var _land := 0.0
var _jump := 0.0
var _was_floor := true
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


func set_weapon(id: String, color: Color, att := "") -> void:
	weapon_id = id
	team_color = color
	_model = String(WeaponDB.get_data(id)["model"])
	for c in _holder.get_children():
		c.queue_free()
	gun = GunBuilder.build(id, true, color, att)
	_holder.add_child(gun)
	_mag = gun.get_meta("mag")
	_mag_rest = _mag.position
	_pump = gun.get_meta("pump") if gun.has_meta("pump") else null
	_slide = gun.get_meta("slide") if gun.has_meta("slide") else null
	_bolt = gun.get_meta("bolt") if gun.has_meta("bolt") else null
	_charge = gun.get_meta("charge") if gun.has_meta("charge") else null
	_eject = gun.get_meta("eject") if gun.has_meta("eject") else null
	_sight = gun.get_meta("sight")
	_ads_z = float(gun.get_meta("ads_z")) if gun.has_meta("ads_z") else -0.28
	_hand = gun.get_meta("left")
	_mag_grip = _grip_point(_mag)
	_build_arms()
	_reload_t = -1.0
	_slide_locked = false
	_slide_t = -1.0
	_bolt_t = -1.0


func muzzle() -> Node3D:
	return gun.get_meta("muzzle") if gun else null


## Where the support hand grabs a magazine: low on its body.
func _grip_point(m: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for c in m.get_children():
		var mis: Array = [c] if c is MeshInstance3D else c.get_children()
		for mi in mis:
			if not mi is MeshInstance3D:
				continue
			var xf: Transform3D = (c.transform * mi.transform) if mi != c else (mi as Node3D).transform
			var bb: AABB = xf * (mi as MeshInstance3D).get_aabb()
			box = bb if first else box.merge(bb)
			first = false
	if first:
		return _mag_rest + Vector3(0, -0.08, -0.1)
	return m.position + box.get_center() + Vector3(0, -box.size.y * 0.25, 0)


# ------------------------------------------------------------------ arms

func _build_arms() -> void:
	var tc := team_color
	var camo2 := tc.lerp(Color(0.24, 0.26, 0.27), 0.5)
	var sleeve := Craft.outlined(Craft.mat(Craft.Kind.FELT, tc.darkened(0.24), Craft.Pattern.CAMO, camo2, 7.0, 0.0, false, true), 0.003, true)
	var glove := Craft.outlined(Craft.mat(Craft.Kind.FELT, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false, true), 0.0025, true)
	var knuckle := Craft.mat(Craft.Kind.PAPER, Color(0.06, 0.06, 0.065), 0, Color.WHITE, 1.0, 0.0, false, true)
	var cuff := Craft.mat(Craft.Kind.FELT, tc.darkened(0.35), Craft.Pattern.STITCH, tc.darkened(0.55), 0.3, 0.0, false, true)
	var patch := Craft.mat(Craft.Kind.FELT, tc, Craft.Pattern.BANDS, tc.lightened(0.45), 60.0, 0.0, false, true)
	var band := Craft.mat(Craft.Kind.FELT, Color(0.1, 0.1, 0.1), 0, Color.WHITE, 1.0, 0.0, false, true)
	var bezel := Craft.mat(Craft.Kind.FOIL, Color(0.5, 0.51, 0.53), 0, Color.WHITE, 1.0, 0.0, false, true)
	var dial := Craft.mat(Craft.Kind.PAPER, Color(0.07, 0.08, 0.08), 0, Color.WHITE, 1.0, 0.0, false, true)
	var lume := Craft.mat(Craft.Kind.GLOW, Color(0.35, 0.6, 0.4), 0, Color.WHITE, 1.0, 0.0, false, true)
	var right_hand := Vector3(0, -0.045, 0.012)
	# Right arm: forearm up to the grip, upper arm off-screen.
	var ra := right_hand + Vector3(0.0, -0.03, 0.09)
	var rb := Vector3(0.13, -0.2, 0.32)
	_limb(gun, ra, rb, 0.044, sleeve)
	_limb(gun, rb, Vector3(0.24, -0.45, 0.6), 0.056, sleeve)
	_ring(gun, ra, rb, -0.005, 0.047, 0.03, cuff)
	C_hand(gun, right_hand, glove, knuckle, false)
	# A velcro flag patch on the right sleeve.
	var pp := ra.lerp(rb, 0.75) + Vector3(0.03, 0.035, 0.0)
	Craft.part(gun, Craft.unit_box(), patch, pp, Vector3(-0.6, 0.0, -0.6), Vector3(0.05, 0.004, 0.035), false)
	# Left arm lives on its own node so it can leave the gun during reloads.
	_left = Node3D.new()
	_left.name = "LeftArm"
	gun.add_child(_left)
	var lh := _hand
	var la := lh + Vector3(-0.025, -0.05, 0.07)
	var lb := Vector3(-0.16, -0.2, 0.0)
	_limb(_left, la, lb, 0.042, sleeve)
	_limb(_left, lb, Vector3(-0.3, -0.45, 0.4), 0.054, sleeve)
	_ring(_left, la, lb, -0.005, 0.045, 0.028, cuff)
	C_hand(_left, lh + Vector3(0, -0.012, 0), glove, knuckle, true)
	# A field watch on the left wrist, face turned up.
	_ring(_left, la, lb, 0.05, 0.046, 0.022, band)
	var dir := (lb - la).normalized()
	var up := (Vector3(-0.4, 1.0, 0.0) - dir * Vector3(-0.4, 1.0, 0.0).dot(dir)).normalized()
	var wc := la + dir * 0.05 + up * 0.046
	var wx := dir.cross(up).normalized()
	var face_basis := Basis(wx, up, wx.cross(up).normalized())
	var face := MeshInstance3D.new()
	face.mesh = Craft.cylinder(0.019, 0.019, 0.012, 16)
	face.material_override = bezel
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	face.transform = Transform3D(face_basis, wc)
	_left.add_child(face)
	var dial_mi := MeshInstance3D.new()
	dial_mi.mesh = Craft.cylinder(0.016, 0.016, 0.002, 16)
	dial_mi.material_override = dial
	dial_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dial_mi.transform = Transform3D(face_basis, wc + up * 0.0065)
	_left.add_child(dial_mi)
	for i in 4:
		var a := TAU * i / 4.0
		var p := wc + up * 0.0078 + (wx * cos(a) + face_basis.z * sin(a)) * 0.012
		Craft.part(_left, Craft.sphere(0.0018, 6), lume, p, Vector3.ZERO, Vector3.ONE, false)
	# A shotgun shell carried in the left hand while loading.
	_shell = Node3D.new()
	_left.add_child(_shell)
	_shell.visible = false
	var hull := Craft.mat(Craft.Kind.PLASTIC, Color(0.55, 0.12, 0.1), 0, Color.WHITE, 1.0, 0.0, false, true)
	var brass := Craft.mat(Craft.Kind.FOIL, Color(0.74, 0.57, 0.27), 0, Color.WHITE, 1.0, 0.0, false, true)
	Craft.part(_shell, Craft.cylinder(0.0095, 0.0095, 0.05, 10), hull, lh + Vector3(0.0, 0.01, 0.0), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
	Craft.part(_shell, Craft.cylinder(0.0102, 0.0102, 0.012, 10), brass, lh + Vector3(0.0, 0.01, 0.03), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)


## A felt glove: palm, curled fingers with hard knuckle armour, and a thumb
## wrapped round a part.
func C_hand(parent: Node3D, at: Vector3, glove: Material, knuckle: Material, support: bool) -> void:
	Craft.part(parent, Craft.sphere(0.034, 10), glove, at + Vector3(0.018 if not support else -0.02, 0, 0.005), Vector3.ZERO, Vector3(0.7, 1.15, 1.3), false)
	var fx := -0.006 if not support else 0.012
	for i in 4:
		var y := at.y + 0.022 - i * 0.017
		Craft.part(parent, Craft.capsule(0.0095, 0.05), glove, Vector3(fx, y, at.z - 0.01), Vector3(0, 0, PI * 0.5), Vector3.ONE, false)
		Craft.part(parent, Craft.sphere(0.0072, 6), knuckle, Vector3(fx + (0.025 if not support else -0.025), y, at.z - 0.01), Vector3.ZERO, Vector3(0.8, 1.0, 1.0), false)
	# Moulded knuckle plate across the back of the hand.
	Craft.part(parent, Craft.unit_box(), knuckle, at + Vector3(0.036 if not support else -0.038, -0.004, 0.004), Vector3.ZERO, Vector3(0.008, 0.05, 0.032), false)
	Craft.part(parent, Craft.capsule(0.01, 0.05), glove, at + Vector3(0.022 if not support else -0.024, 0.03, -0.02), Vector3(0.9, 0, 0.3), Vector3.ONE, false)


func _limb(parent: Node3D, a: Vector3, b: Vector3, r: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Craft.capsule(r, a.distance_to(b) + r)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.transform = Transform3D(_along(b - a), (a + b) * 0.5)


## A short cylinder (cuff, watch strap) around a limb, `d` metres from a.
func _ring(parent: Node3D, a: Vector3, b: Vector3, d: float, r: float, h: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Craft.cylinder(r, r, h, 14)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.transform = Transform3D(_along(b - a), a + (b - a).normalized() * d)


func _along(v: Vector3) -> Basis:
	var dir := v.normalized()
	var ref := Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := dir.cross(ref).normalized()
	var z := x.cross(dir).normalized()
	return Basis(x, dir, z)


# ---------------------------------------------------------------- events

func kick(strength: float) -> void:
	_kick = minf(_kick + 0.6 * strength, 1.4)
	_kick_rot += Vector2(randf_range(-0.4, 0.4), 1.0) * 0.5 * strength
	_kick_roll += randf_range(-1.0, 1.0) * 0.04 * strength
	if _pump and weapon_id == "shotgun":
		_pump_t = 0.0


## A round went off: cycle the action and throw the brass.
func fired(now_empty: bool) -> void:
	match _model:
		"pistol":
			_slide_t = 0.0
			_slide_locked = now_empty
			_eject_brass(0.15)
		"sniper":
			if not now_empty:
				_bolt_t = 0.0
		"shotgun", "revolver":
			pass
		_:
			_eject_brass(0.0)


func _eject_brass(delay: float) -> void:
	if _eject == null:
		return
	var kind := 0
	match _model:
		"pistol", "smg":
			kind = 1
		"shotgun":
			kind = 2
		"sniper":
			kind = 3
	if delay <= 0.0:
		Fx.casing(_eject.global_position, _eject.global_transform.basis, kind)
	else:
		get_tree().create_timer(delay, false).timeout.connect(func():
			if is_instance_valid(_eject) and _eject.is_inside_tree():
				Fx.casing(_eject.global_position, _eject.global_transform.basis, kind))


func start_reload(total: float, empty := false) -> void:
	_reload_t = 0.0
	_reload_total = maxf(total, 0.1)
	_empty_reload = empty
	_dropped = false
	_slapped = false
	_bolted = false
	_keys = _reload_keys()


func cancel_reload() -> void:
	_reload_t = -1.0
	_reset_parts()


func _reset_parts() -> void:
	if _mag:
		_mag.position = _mag_rest
		_mag.visible = true
	if _left:
		_left.position = Vector3.ZERO
		_left.rotation = Vector3.ZERO
	if _shell:
		_shell.visible = false
	if _charge:
		_charge.position = Vector3.ZERO


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


# -------------------------------------------------------------- reloads

## Keyframes for the support hand and the magazine through a reload:
## [time 0..1, hand offset from its grip, mag offset from rest (or null
## while the mag is out of sight), event]. Events: "drop" throws the old mag
## to the floor, "slap" seats the new one, "charge" works the action.
func _reload_keys() -> Array:
	var k := []
	var grab := _mag_grip - _hand
	var below := Vector3(0, -0.28, 0.06)
	if _model == "shotgun":
		# Shell by shell into the loading port under the receiver.
		var port := Vector3(0, -0.02, -0.13) - _hand
		k.append([0.0, Vector3.ZERO, Vector3.ZERO, ""])
		var n := 4
		for i in n:
			var t0 := 0.08 + i * 0.19
			k.append([t0 + 0.05, OFFSCREEN, Vector3.ZERO, "shell"])
			k.append([t0 + 0.12, port + Vector3(0, -0.04, 0), Vector3.ZERO, ""])
			k.append([t0 + 0.16, port, Vector3.ZERO, "push"])
		k.append([0.92, Vector3.ZERO, Vector3.ZERO, ""])
		k.append([1.0, Vector3.ZERO, Vector3.ZERO, ""])
		return k
	if _model == "revolver":
		# Swing the cylinder out, dump the empties, speed-load, snap shut.
		var out := Vector3(-0.04, 0.0, 0.0)
		k.append([0.0, Vector3.ZERO, Vector3.ZERO, ""])
		k.append([0.14, Vector3(0.0, 0.05, -0.03), out, ""])
		k.append([0.24, Vector3(0.0, 0.05, -0.03), out, "dump"])
		k.append([0.44, OFFSCREEN, out, ""])
		k.append([0.66, Vector3(-0.03, 0.03, -0.06), out, "slap"])
		k.append([0.8, Vector3(0.0, 0.05, -0.03), Vector3.ZERO, ""])
		k.append([1.0, Vector3.ZERO, Vector3.ZERO, ""])
		return k
	var pistol := _model == "pistol"
	k.append([0.0, Vector3.ZERO, Vector3.ZERO, ""])
	if pistol:
		# The empty mag falls free; the support hand fetches a fresh one.
		k.append([0.1, Vector3(-0.02, -0.06, 0.02), Vector3.ZERO, ""])
		k.append([0.2, Vector3(-0.02, -0.06, 0.02), below, "drop"])
		k.append([0.38, OFFSCREEN, null, ""])
		k.append([0.55, grab + Vector3(0, -0.07, 0), Vector3(0, -0.07, 0), ""])
		k.append([0.64, grab, Vector3.ZERO, "slap"])
		if _empty_reload:
			k.append([0.76, Vector3(-0.01, 0.1, 0.03), Vector3.ZERO, "charge"])
		k.append([0.88, Vector3.ZERO, Vector3.ZERO, ""])
		k.append([1.0, Vector3.ZERO, Vector3.ZERO, ""])
		return k
	# Rifles: hand to the mag, strip it out and let it fall, fetch a new
	# one from the vest, seat it with a slap, then charge an empty gun.
	k.append([0.12, grab, Vector3.ZERO, ""])
	k.append([0.26, grab + Vector3(0, -0.12, 0.04), Vector3(0, -0.12, 0.04), ""])
	k.append([0.3, grab + Vector3(0, -0.14, 0.05), Vector3(0, -0.14, 0.05), "drop"])
	k.append([0.42, OFFSCREEN, null, ""])
	k.append([0.56, grab + Vector3(0, -0.09, 0.02), Vector3(0, -0.09, 0.02), ""])
	k.append([0.64, grab, Vector3.ZERO, "slap"])
	if _empty_reload and _charge:
		var ch := Vector3(0.0, 0.09, 0.07) - _hand
		match _model:
			"ak":
				ch = Vector3(0.05, 0.07, -0.14) - _hand
			"smg":
				ch = Vector3(-0.045, 0.068, -0.28) - _hand
		k.append([0.74, ch, Vector3.ZERO, ""])
		k.append([0.8, ch + Vector3(0, 0, 0.06), Vector3.ZERO, "charge"])
	elif _empty_reload and _bolt:
		k.append([0.72, Vector3(0.0, -0.02, 0.05), Vector3.ZERO, "bolt"])
	k.append([0.9, Vector3.ZERO, Vector3.ZERO, ""])
	k.append([1.0, Vector3.ZERO, Vector3.ZERO, ""])
	return k


func _animate_reload(delta: float) -> Vector3:
	## Returns extra (rot) wobble for the whole gun.
	_reload_t += delta / _reload_total
	var r := _reload_t
	var extra := Vector3.ZERO
	# Find the surrounding keys.
	var i := 0
	while i < _keys.size() - 2 and float(_keys[i + 1][0]) <= r:
		i += 1
	var a: Array = _keys[i]
	var b: Array = _keys[mini(i + 1, _keys.size() - 1)]
	var span := maxf(float(b[0]) - float(a[0]), 0.0001)
	var t := clampf((r - float(a[0])) / span, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	_left.position = (a[1] as Vector3).lerp(b[1] as Vector3, t)
	if a[2] == null and b[2] == null:
		_mag.visible = false
	elif a[2] == null:
		_mag.visible = t > 0.5
		_mag.position = _mag_rest + (b[2] as Vector3) + (_left.position - (b[1] as Vector3))
	elif b[2] == null:
		_mag.visible = not _dropped
		_mag.position = _mag_rest + (a[2] as Vector3)
	else:
		_mag.visible = true
		_mag.position = _mag_rest + (a[2] as Vector3).lerp(b[2] as Vector3, t)
	# Events fire as the playhead passes their key.
	for key: Array in _keys:
		var kt := float(key[0])
		var ev := String(key[3])
		if ev == "" or r < kt:
			continue
		match ev:
			"drop":
				if not _dropped:
					_dropped = true
					_mag.visible = false
					Fx.dropped_mag(_mag)
			"dump":
				if not _dropped:
					_dropped = true
					var down := Basis(Vector3.RIGHT, -PI * 0.5) * _mag.global_transform.basis.orthonormalized()
					for _n in 6:
						Fx.casing(_mag.global_position + Vector3(0, 0.06, 0), down, 1)
			"slap":
				if not _slapped:
					_slapped = true
					_kick = maxf(_kick, 0.35)
	# Charging: pull the handle (or release the slide) shortly after its key.
	for key: Array in _keys:
		var ev2 := String(key[3])
		var dt := r - float(key[0])
		if ev2 == "charge" and dt > -0.06 and dt < 0.08:
			var pull := sin(clampf((dt + 0.06) / 0.14, 0.0, 1.0) * PI)
			if _charge:
				_charge.position = Vector3(0, 0, 0.06 * pull)
			if _slide and dt > 0.0:
				_slide_locked = false
			extra += Vector3(0.0, 0.0, -0.12) * pull
		if ev2 == "bolt" and dt > 0.0 and not _bolted:
			_bolted = true
			_bolt_t = 0.0
		if ev2 == "shell":
			_shell.visible = r > float(key[0]) - 0.05 and r < float(key[0]) + 0.11
		if ev2 == "push" and dt > -0.02 and dt < 0.04:
			extra += Vector3(0.03, 0.0, 0.0)
	# Whole gun tilts toward the support hand while it works.
	var tilt := smoothstep(0.0, 0.12, r) * (1.0 - smoothstep(0.86, 1.0, r))
	if _model == "shotgun":
		extra += Vector3(0.15, -0.2, -0.45) * tilt
	elif _model == "pistol" or _model == "revolver":
		extra += Vector3(0.2, 0.15, 0.25) * tilt
	else:
		extra += Vector3(0.18, 0.22, 0.5) * tilt
	if r >= 1.0:
		_reload_t = -1.0
		_reset_parts()
	return extra


# ------------------------------------------------------------- animate

## Called every frame by the player.
func animate(delta: float, look_delta: Vector2, speed: float, on_floor: bool, ads: float, sprint: float, crouch: float) -> void:
	_time += delta
	# Sway lags behind the look direction, like a springy paper arm.
	var target_sway := (-look_delta * 0.0018).limit_length(0.08) * (1.0 - ads * 0.75)
	_sway_vel += (target_sway - _sway) * 160.0 * delta
	_sway_vel *= exp(-14.0 * delta)
	_sway += _sway_vel * delta

	if _was_floor and not on_floor:
		_jump = 1.0
	_was_floor = on_floor
	var move := clampf(speed / 4.8, 0.0, 1.6) if on_floor else 0.0
	_bob += delta * (speed * 1.9 + 0.001)
	var bob_amt := move * (1.0 - ads * 0.88)
	var bob := Vector3(sin(_bob) * 0.012, -absf(cos(_bob)) * 0.012, 0.0) * bob_amt
	var breathe := Vector3(sin(_time * 1.3) * 0.002, sin(_time * 2.1) * 0.0025, 0.0) * (1.0 - ads * 0.6)

	_kick = move_toward(_kick, 0.0, delta * 9.0)
	_kick_rot = _kick_rot.move_toward(Vector2.ZERO, delta * 7.0)
	_kick_roll = move_toward(_kick_roll, 0.0, delta * 0.6)
	_swap = move_toward(_swap, _swap_target, delta * 5.0)
	_land = move_toward(_land, 0.0, delta * 4.0)
	_jump = move_toward(_jump, 0.0, delta * 2.5)

	var ads_pos := Vector3(-_sight.x, -_sight.y, _ads_z)
	var pos := HIP.lerp(ads_pos, ads)
	var rot := HIP_ROT.lerp(Vector3.ZERO, ads)
	pos = pos.lerp(SPRINT_POS, sprint)
	rot = rot.lerp(SPRINT_ROT, sprint)
	pos += bob + breathe
	# Sprinting swings the gun in a loose figure of eight.
	pos += Vector3(sin(_bob) * 0.03, -absf(cos(_bob)) * 0.022, 0.0) * sprint * move
	rot.z += sin(_bob) * 0.07 * sprint * move
	pos.x += _sway.x * 0.25
	pos.y += _sway.y * 0.25 - _land * 0.04 - crouch * 0.01 + _jump * 0.014 * (1.0 - ads)
	rot.x += _jump * 0.05 * (1.0 - ads) - _land * 0.06
	rot.y += _sway.x * 1.2
	rot.x += _sway.y * 1.2 + bob.y * 1.5
	rot.z += _sway.x * 0.6 - sin(_bob) * 0.01 * bob_amt
	pos.z += _kick * 0.035
	pos.y += _kick * 0.004
	rot.x += _kick * 0.06 * (1.0 - ads * 0.5) + _kick_rot.y * 0.02
	rot.y += _kick_rot.x * 0.02
	rot.z += _kick_roll * (1.0 - ads * 0.6)

	if _reload_t >= 0.0 and _mag:
		rot += _animate_reload(delta)

	# Pistol slide: snaps back on each shot and stays back on empty.
	if _slide:
		var back := 0.0
		if _slide_t >= 0.0:
			_slide_t += delta / 0.09
			back = sin(clampf(_slide_t, 0.0, 1.0) * PI)
			if _slide_t >= 1.0:
				_slide_t = -1.0
		if _slide_locked and (_slide_t < 0.0 or _slide_t > 0.5):
			back = 1.0
		_slide.position = Vector3(0, 0, 0.028 * back)

	# Sniper bolt: lift, draw back (brass out), drive home, lock down.
	if _bolt and _bolt_t >= 0.0:
		_bolt_t += delta / 0.8
		var bt := _bolt_t
		var lift := smoothstep(0.1, 0.25, bt) * (1.0 - smoothstep(0.75, 0.9, bt))
		var draw := smoothstep(0.25, 0.42, bt) * (1.0 - smoothstep(0.55, 0.72, bt))
		_bolt.rotation.z = lift * 1.2
		_bolt.position = Vector3(0, 0.072, 0.075 * draw)
		rot += Vector3(0.05, 0.08, 0.12) * lift
		if bt > 0.42 and bt - delta / 0.8 <= 0.42:
			_eject_brass(0.0)
		if bt >= 1.0:
			_bolt_t = -1.0
			_bolt.rotation.z = 0.0
			_bolt.position = Vector3(0, 0.072, 0)

	# Weapon swap: drop below the screen with a roll.
	pos.y -= _swap * 0.35
	rot.x -= _swap * 0.7
	rot.z += _swap * 0.4

	# Knife: gun ducks left, the knife slashes in from the right.
	if _knife_t >= 0.0:
		_knife_t += delta / 0.5
		var k := _knife_t
		var away := sin(clampf(k, 0.0, 1.0) * PI)
		pos += Vector3(-0.12, -0.12, 0.05) * away
		rot += Vector3(-0.3, 0.4, 0.3) * away
		knife.visible = k < 1.0
		var stab := sin(clampf((k - 0.15) / 0.5, 0.0, 1.0) * PI)
		var sweep := smoothstep(0.1, 0.6, k)
		knife.position = Vector3(0.22, -0.12, -0.3).lerp(Vector3(-0.05, -0.12, -0.6), stab) + Vector3(-0.08 * sweep, -0.04 * sweep, 0)
		knife.rotation = Vector3(-0.2, 0.5 - stab * 0.6, -0.9 + sweep * 0.9)
		if k >= 1.0:
			_knife_t = -1.0
			knife.visible = false

	# Grenade throw: gun dips, the frag arcs out from the left hand.
	if _throw_t >= 0.0:
		_throw_t += delta / 0.6
		var t := _throw_t
		var dip := sin(clampf(t, 0.0, 1.0) * PI)
		pos += Vector3(0.06, -0.15, 0.04) * dip
		rot.x -= 0.4 * dip
		frag.visible = t < 0.55
		frag.position = Vector3(-0.2, -0.22, -0.3).lerp(Vector3(-0.22, -0.1, -0.35), smoothstep(0.0, 0.25, t)).lerp(Vector3(-0.05, 0.05, -0.75), smoothstep(0.25, 0.55, t))
		frag.rotation = Vector3(-t * 6.0, 0.3, 0.0)
		if t >= 1.0:
			_throw_t = -1.0
			frag.visible = false

	if _pump and _pump_t >= 0.0:
		_pump_t += delta / 0.55
		var pt := sin(clampf((_pump_t - 0.3) / 0.7, 0.0, 1.0) * PI)
		_pump.position = Vector3(0, 0, 0.12 * pt)
		if _left and _reload_t < 0.0:
			_left.position = Vector3(0, 0, 0.12 * pt)
		if _pump_t > 0.62 and _pump_t - delta / 0.55 <= 0.62:
			_eject_brass(0.0)
		if _pump_t >= 1.0:
			_pump_t = -1.0
			_pump.position = Vector3.ZERO
			if _left and _reload_t < 0.0:
				_left.position = Vector3.ZERO

	transform = Transform3D(Basis.from_euler(rot), pos)
