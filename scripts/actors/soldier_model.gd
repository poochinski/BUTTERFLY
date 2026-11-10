class_name SoldierModel
extends Node3D
## A papercraft soldier doll: folded-cardboard body, felt uniform in team
## colours, button eyes, a felt helmet (Cardstock) or knitted beanie
## (Militia), and a cardboard gun. Procedurally animated: walking, aiming,
## crouching, prone, recoil, and folding flat when defeated.

var team := 0
var hips: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var forearm_l: Node3D
var forearm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var gun_mount: Node3D
var gun: Node3D

var _phase := 0.0
var _kick := 0.0
var _dead := 0.0
var _crouch := 0.0
var _prone := 0.0
var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _m(kind: int, col: Color, pattern := 0, col2 := Color.WHITE, edges := true) -> Material:
	return Craft.outlined(Craft.mat(kind, col, pattern, col2, 1.0, 0.6, edges), 0.012)


func _build() -> void:
	_built = true
	var tc: Color = Game.TEAM_COLORS[team]
	var uniform_c := tc.darkened(0.15)
	var skin := Color(0.98, 0.86, 0.72)
	var felt := _m(Craft.Kind.FELT, uniform_c, Craft.Pattern.STITCH, Craft.CREAM)
	var felt_dark := _m(Craft.Kind.FELT, uniform_c.darkened(0.3))
	var vest := _m(Craft.Kind.CARDBOARD, Craft.KRAFT if team == 1 else Color(0.5, 0.56, 0.42))
	var paper_skin := _m(Craft.Kind.PAPER, skin, 0, Color.WHITE, false)
	var boot := _m(Craft.Kind.PLASTIC, Color(0.2, 0.15, 0.12), 0, Color.WHITE, false)

	# Plush proportions: a soft felt body, chunky limbs and a quilted vest.
	hips = Craft.pivot(self, Vector3(0, 0.84, 0))
	Craft.part(hips, Craft.capsule(0.2, 0.42), felt_dark, Vector3(0, 0.0, 0), Vector3(0, 0, PI * 0.5), Vector3(1.0, 1.0, 0.72))
	torso = Craft.pivot(hips, Vector3(0, 0.1, 0))
	Craft.part(torso, Craft.capsule(0.22, 0.62), felt, Vector3(0, 0.27, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.72))
	var vest_root := Craft.pivot(torso, Vector3(0, 0.27, 0))
	Craft.box(vest_root, Vector3(0, 0.02, -0.12), Vector3(0.4, 0.4, 0.07), vest, Vector3(0.06, 0, 0))
	Craft.box(vest_root, Vector3(0, 0.02, 0.13), Vector3(0.4, 0.42, 0.07), vest, Vector3(-0.05, 0, 0))
	var pouch := _m(Craft.Kind.FELT, uniform_c.lightened(0.18), Craft.Pattern.STITCH, Craft.CREAM)
	for x: float in [-0.12, 0.0, 0.12]:
		Craft.box(vest_root, Vector3(x, -0.08, -0.175), Vector3(0.1, 0.13, 0.06), pouch)
		Craft.part(vest_root, Craft.cylinder(0.012, 0.012, 0.01, 8), Craft.mat(Craft.Kind.PLASTIC, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), Vector3(x, -0.03, -0.207), Vector3(PI * 0.5, 0, 0))
	var strap := _m(Craft.Kind.TAPE, Craft.KRAFT_DARK)
	for x: float in [-0.13, 0.13]:
		Craft.box(vest_root, Vector3(x, 0.24, 0.0), Vector3(0.06, 0.05, 0.34), strap)
	Craft.box(torso, Vector3(0, 0.3, 0.24), Vector3(0.3, 0.34, 0.14), _m(Craft.Kind.CARDBOARD, Craft.KRAFT_DARK))
	Craft.part(torso, Craft.capsule(0.06, 0.32), _m(Craft.Kind.KNIT, Game.TEAM_COLORS[team].lightened(0.2)), Vector3(0, 0.5, 0.25), Vector3(0, 0, PI * 0.5))

	head = Craft.pivot(torso, Vector3(0, 0.56, 0))
	Craft.part(head, Craft.sphere(0.17, 16), paper_skin, Vector3(0, 0.15, 0), Vector3.ZERO, Vector3(1.0, 0.95, 0.95))
	var eye := Craft.mat(Craft.Kind.PLASTIC, Color(0.08, 0.06, 0.06), 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		Craft.part(head, Craft.cylinder(0.03, 0.03, 0.02, 10), eye, Vector3(sx * 0.06, 0.16, -0.155), Vector3(PI * 0.5, 0, 0))
		Craft.part(head, Craft.sphere(0.008, 6), Craft.mat(Craft.Kind.PLASTIC, Color.WHITE, 0, Color.WHITE, 1.0, 0.0, false), Vector3(sx * 0.055, 0.17, -0.168))
		Craft.part(head, Craft.cylinder(0.026, 0.026, 0.01, 10), Craft.mat(Craft.Kind.FELT, Color(0.98, 0.55, 0.55), 0, Color.WHITE, 1.0, 0.0, false), Vector3(sx * 0.1, 0.09, -0.13), Vector3(PI * 0.5 + 0.4, 0, 0))
	# Determined brows.
	var brow := Craft.mat(Craft.Kind.FELT, Color(0.2, 0.13, 0.1), 0, Color.WHITE, 1.0, 0.0, true)
	Craft.box(head, Vector3(-0.06, 0.215, -0.15), Vector3(0.07, 0.015, 0.02), brow, Vector3(0, 0, -0.25))
	Craft.box(head, Vector3(0.06, 0.215, -0.15), Vector3(0.07, 0.015, 0.02), brow, Vector3(0, 0, 0.25))
	if team == 0:
		var helm := _m(Craft.Kind.FELT, Color(0.42, 0.5, 0.36), Craft.Pattern.STITCH, Craft.CREAM, false)
		Craft.part(head, Craft.sphere(0.2, 16), helm, Vector3(0, 0.22, 0.01), Vector3.ZERO, Vector3(1.05, 0.7, 1.1))
		Craft.part(head, Craft.cylinder(0.215, 0.215, 0.04, 18), _m(Craft.Kind.KNIT, tc, 0, Color.WHITE, false), Vector3(0, 0.2, 0.01))
	else:
		var beanie := _m(Craft.Kind.KNIT, Color(0.86, 0.3, 0.22), 0, Color.WHITE, false)
		Craft.part(head, Craft.sphere(0.185, 16), beanie, Vector3(0, 0.23, 0.01), Vector3.ZERO, Vector3(1.0, 0.85, 1.0))
		Craft.part(head, Craft.cylinder(0.19, 0.19, 0.07, 18), _m(Craft.Kind.KNIT, Color(0.95, 0.85, 0.6), 0, Color.WHITE, false), Vector3(0, 0.17, 0.01))
		Craft.part(head, Craft.sphere(0.06, 10), _m(Craft.Kind.KNIT, Color(0.95, 0.85, 0.6), 0, Color.WHITE, false), Vector3(0, 0.39, 0.02))
		Craft.box(head, Vector3(0, 0.03, -0.12), Vector3(0.26, 0.09, 0.08), _m(Craft.Kind.KNIT, Color(0.86, 0.3, 0.22)))

	for side: float in [-1.0, 1.0]:
		var sh := Craft.pivot(torso, Vector3(side * 0.27, 0.45, 0))
		Craft.part(sh, Craft.capsule(0.07, 0.32), felt, Vector3(0, -0.13, 0))
		var el := Craft.pivot(sh, Vector3(0, -0.27, 0))
		Craft.part(el, Craft.capsule(0.06, 0.28), felt, Vector3(0, -0.12, 0))
		Craft.part(el, Craft.sphere(0.065, 10), _m(Craft.Kind.FELT, Color(0.25, 0.22, 0.2), 0, Color.WHITE, false), Vector3(0, -0.27, 0))
		if side < 0.0:
			arm_l = sh
			forearm_l = el
		else:
			arm_r = sh
			forearm_r = el
	for side: float in [-1.0, 1.0]:
		var hp := Craft.pivot(hips, Vector3(side * 0.11, -0.04, 0))
		Craft.part(hp, Craft.capsule(0.095, 0.42), felt_dark, Vector3(0, -0.17, 0))
		var kn := Craft.pivot(hp, Vector3(0, -0.38, 0))
		Craft.part(kn, Craft.capsule(0.085, 0.38), felt_dark, Vector3(0, -0.15, 0))
		Craft.part(kn, Craft.cylinder(0.092, 0.092, 0.05, 12), _m(Craft.Kind.KNIT, Craft.CREAM, 0, Color.WHITE, false), Vector3(0, -0.27, 0))
		Craft.part(kn, Craft.capsule(0.08, 0.28), boot, Vector3(0, -0.36, -0.05), Vector3(PI * 0.5, 0, 0), Vector3(1.15, 1.0, 0.8))
		if side < 0.0:
			leg_l = hp
			knee_l = kn
		else:
			leg_r = hp
			knee_r = kn
	gun_mount = Craft.pivot(torso, Vector3(0.12, 0.33, -0.25))


func set_weapon(id: String) -> void:
	if not _built:
		_build()
	if gun:
		gun.queue_free()
	gun = GunBuilder.build(id, false, Game.TEAM_COLORS[team])
	gun_mount.add_child(gun)


func muzzle() -> Node3D:
	if gun and gun.has_meta("muzzle"):
		return gun.get_meta("muzzle")
	return null


func kick() -> void:
	_kick = 1.0


func play_death(_headshot: bool) -> void:
	_dead = 0.001


func reset() -> void:
	_dead = 0.0
	scale = Vector3.ONE
	rotation = Vector3.ZERO
	position = Vector3.ZERO
	visible = true


func set_shadow_only(on: bool) -> void:
	_set_cast(self, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if on else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


func _set_cast(n: Node, mode: int) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			(c as GeometryInstance3D).cast_shadow = mode
		_set_cast(c, mode)


## speed: horizontal m/s, stance: Soldier.Stance, pitch: aim pitch radians.
func animate(delta: float, speed: float, stance: int, pitch: float, sprinting: bool) -> void:
	if not _built:
		return
	if _dead > 0.0:
		_animate_death(delta)
		return
	_crouch = move_toward(_crouch, 1.0 if stance == Soldier.Stance.CROUCH else 0.0, delta * 6.0)
	_prone = move_toward(_prone, 1.0 if stance == Soldier.Stance.PRONE else 0.0, delta * 4.0)
	_kick = move_toward(_kick, 0.0, delta * 9.0)
	var amt := clampf(speed / 4.8, 0.0, 1.4)
	_phase += delta * speed * (2.2 if not sprinting else 1.8)
	var s := sin(_phase)

	# Whole-body prone: tip forward and lie down.
	rotation.x = -_prone * PI * 0.47
	position.y = _prone * 0.18
	position.z = _prone * 0.45

	var swing := 0.6 * amt * (1.0 - _crouch * 0.5)
	leg_l.rotation.x = s * swing + _crouch * 1.2
	leg_r.rotation.x = -s * swing + _crouch * 0.3
	knee_l.rotation.x = -maxf(0.0, sin(_phase + 1.3)) * 1.0 * amt - _crouch * 1.6
	knee_r.rotation.x = -maxf(0.0, sin(_phase + 1.3 + PI)) * 1.0 * amt - _crouch * 0.9
	hips.position.y = 0.84 - _crouch * 0.38 + absf(cos(_phase)) * 0.04 * amt
	hips.rotation.y = s * 0.1 * amt
	torso.rotation.x = -_crouch * 0.15 - (0.25 if sprinting else 0.0)
	torso.rotation.y = -s * 0.08 * amt

	var aim := clampf(pitch, -1.2, 1.2) * (1.0 - _prone * 0.6)
	head.rotation.x = aim * 0.5
	# Positive X rotation swings a limb forward (the doll faces -Z).
	if sprinting:
		arm_r.rotation = Vector3(0.5 + s * 0.3, 0, 0.1)
		arm_l.rotation = Vector3(0.7 - s * 0.3, 0, -0.3)
		forearm_r.rotation.x = 1.2
		forearm_l.rotation.x = 1.3
		gun_mount.rotation = Vector3(-0.9, 0.9, 0.3)
	else:
		arm_r.rotation = Vector3(1.25 + aim + _kick * 0.12, 0.25, 0.0)
		forearm_r.rotation.x = 0.35
		arm_l.rotation = Vector3(1.45 + aim, -0.55, 0.0)
		forearm_l.rotation.x = 0.1
		gun_mount.rotation = Vector3(aim + _kick * 0.15, 0, 0)
	gun_mount.position = Vector3(0.12, 0.33, -0.25 + _kick * 0.05)


func _animate_death(delta: float) -> void:
	# Fold flat like a sheet of paper, flutter down, then shrink away.
	_dead += delta
	var t := _dead
	rotation.x = lerpf(rotation.x, -PI * 0.5, minf(delta * 6.0, 1.0))
	rotation.z = sin(t * 9.0) * 0.15 * maxf(0.0, 1.0 - t)
	scale = Vector3(1.0, 1.0, lerpf(scale.z, 0.08, minf(delta * 8.0, 1.0)))
	position.y = lerpf(position.y, 0.1, minf(delta * 4.0, 1.0))
	if t > 2.4:
		var k := clampf(1.0 - (t - 2.4) / 0.6, 0.001, 1.0)
		scale = Vector3(k, k, 0.08 * k)
	if t > 3.0:
		visible = false
