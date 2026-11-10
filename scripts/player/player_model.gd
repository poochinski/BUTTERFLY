class_name PlayerModel
extends Node3D
## The young naturalist: a procedurally built, procedurally animated
## character in a straw sun hat, field jacket and boots, carrying a net.
## Faces -Z. Every joint is a Node3D pivot so animation is just rotations.

const SKIN := Color(0.93, 0.74, 0.6)
const SHIRT := Color(0.96, 0.92, 0.82)
const JACKET := Color(0.36, 0.5, 0.42)
const SHORTS := Color(0.6, 0.5, 0.35)
const BOOT := Color(0.34, 0.22, 0.15)
const SOCK := Color(0.95, 0.94, 0.9)
const HAT := Color(0.93, 0.8, 0.5)
const RIBBON := Color(0.85, 0.38, 0.4)
const HAIR := Color(0.28, 0.17, 0.1)
const SCARF := Color(0.95, 0.55, 0.25)
const SATCHEL := Color(0.62, 0.42, 0.26)
const WOOD := Color(0.6, 0.43, 0.27)

## Net held upright, tilted a little forward and out to the right so it
## never blocks the camera's view of the character.
const IDLE_GRIP := PI - 0.5
const IDLE_TILT := 0.35

var hips: Node3D
var torso: Node3D
var head: Node3D
var shoulder_l: Node3D
var shoulder_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var hip_l: Node3D
var hip_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var grip: Node3D
var hoop: Node3D
var net_bag: MeshInstance3D

var crouch := 0.0
var _phase := 0.0
var _air := 0.0
var _time := 0.0
var _mats := {}


func _ready() -> void:
	_build()


func hoop_position() -> Vector3:
	return hoop.global_position


# ------------------------------------------------------------- building

func _mat(c: Color, rough := 0.85) -> StandardMaterial3D:
	if _mats.has(c):
		return _mats[c]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.6
	_mats[c] = m
	return m


func _part(parent: Node3D, mesh: Mesh, color: Color, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _joint(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 14
	m.rings = 6
	return m


func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 18
	m.rings = 10
	return m


func _cyl(top: float, bottom: float, h: float, segs := 16) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return m


func _torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 24
	m.ring_segments = 8
	return m


func _build() -> void:
	hips = _joint(self, Vector3(0, 0.8, 0))
	_part(hips, _capsule(0.16, 0.36), SHORTS, Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.82))

	torso = _joint(hips, Vector3(0, 0.08, 0))
	_part(torso, _capsule(0.165, 0.52), JACKET, Vector3(0, 0.24, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.8))
	_part(torso, _cyl(0.168, 0.17, 0.06), Color(0.42, 0.3, 0.2), Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	_part(torso, _torus(0.07, 0.12), SHIRT, Vector3(0, 0.5, -0.01), Vector3(0.15, 0, 0), Vector3(1.0, 1.0, 0.9))
	_part(torso, _torus(0.05, 0.1), SCARF, Vector3(0, 0.47, -0.02), Vector3(0.25, 0, 0), Vector3(1.0, 1.4, 0.95))
	_part(torso, _sphere(0.05), SCARF, Vector3(0.02, 0.42, -0.12), Vector3.ZERO, Vector3(1.0, 1.2, 0.6))
	# Chest pockets.
	_part(torso, BoxMesh.new(), JACKET.lightened(0.15), Vector3(-0.08, 0.3, -0.125), Vector3(0.1, 0, 0), Vector3(0.08, 0.07, 0.02))
	_part(torso, BoxMesh.new(), JACKET.lightened(0.15), Vector3(0.08, 0.3, -0.125), Vector3(0.1, 0, 0), Vector3(0.08, 0.07, 0.02))
	# Satchel strap and bag.
	_part(torso, BoxMesh.new(), SATCHEL.darkened(0.2), Vector3(0.0, 0.25, -0.0), Vector3(0, 0, 0.72), Vector3(0.05, 0.62, 0.36))
	var bag := _part(torso, BoxMesh.new(), SATCHEL, Vector3(-0.2, -0.05, 0.02), Vector3(0, 0, 0.1), Vector3(0.08, 0.2, 0.24))
	_part(bag, BoxMesh.new(), SATCHEL.lightened(0.15), Vector3(-0.6, 0.25, 0.0), Vector3.ZERO, Vector3(0.3, 0.55, 1.02))

	head = _joint(torso, Vector3(0, 0.53, 0))
	_part(head, _cyl(0.055, 0.06, 0.08), SKIN, Vector3(0, 0.02, 0))
	_part(head, _sphere(0.155), SKIN, Vector3(0, 0.15, 0))
	_part(head, _sphere(0.163), HAIR, Vector3(0, 0.18, 0.03), Vector3.ZERO, Vector3(1.0, 0.92, 1.0))
	_part(head, _sphere(0.09), HAIR, Vector3(0, 0.07, 0.11), Vector3.ZERO, Vector3(1.2, 1.0, 0.8))
	for side in [-1.0, 1.0]:
		_part(head, _sphere(0.022), Color(0.12, 0.08, 0.06), Vector3(side * 0.055, 0.15, -0.143))
		_part(head, _sphere(0.007), Color(1, 1, 1), Vector3(side * 0.05, 0.158, -0.162))
		_part(head, _sphere(0.03), Color(0.97, 0.6, 0.56), Vector3(side * 0.095, 0.1, -0.12), Vector3.ZERO, Vector3(1.0, 0.7, 0.4))
		_part(head, _sphere(0.035), SKIN, Vector3(side * 0.155, 0.14, 0.0), Vector3.ZERO, Vector3(0.5, 1.0, 0.8))
	_part(head, _sphere(0.02), SKIN.darkened(0.06), Vector3(0, 0.12, -0.155))
	var hat := _joint(head, Vector3(0, 0.27, 0.01))
	hat.rotation.x = 0.14
	_part(hat, _cyl(0.32, 0.33, 0.018, 28), HAT)
	_part(hat, _cyl(0.125, 0.15, 0.15, 20), HAT, Vector3(0, 0.08, 0))
	_part(hat, _cyl(0.152, 0.152, 0.04, 20), RIBBON, Vector3(0, 0.03, 0))
	_part(hat, _cyl(0.126, 0.126, 0.01, 20), HAT.darkened(0.08), Vector3(0, 0.16, 0))

	for side in [-1.0, 1.0]:
		var sh := _joint(torso, Vector3(side * 0.205, 0.45, 0))
		_part(sh, _sphere(0.068), JACKET, Vector3(0, 0, 0))
		_part(sh, _capsule(0.06, 0.3), JACKET, Vector3(0, -0.12, 0))
		var el := _joint(sh, Vector3(0, -0.26, 0))
		_part(el, _torus(0.04, 0.068), SHIRT, Vector3(0, -0.01, 0))
		_part(el, _capsule(0.047, 0.26), SKIN, Vector3(0, -0.11, 0))
		var hand := _joint(el, Vector3(0, -0.25, 0))
		_part(hand, _sphere(0.055), SKIN, Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 1.0, 1.0))
		if side < 0.0:
			shoulder_l = sh
			elbow_l = el
		else:
			shoulder_r = sh
			elbow_r = el
			_build_net(hand)

	for side in [-1.0, 1.0]:
		var hp := _joint(hips, Vector3(side * 0.09, -0.04, 0))
		_part(hp, _capsule(0.078, 0.34), SHORTS, Vector3(0, -0.13, 0))
		var kn := _joint(hp, Vector3(0, -0.37, 0))
		_part(kn, _capsule(0.056, 0.3), SKIN, Vector3(0, -0.12, 0))
		_part(kn, _cyl(0.06, 0.058, 0.09), SOCK, Vector3(0, -0.27, 0))
		_part(kn, _capsule(0.065, 0.24), BOOT, Vector3(0, -0.35, -0.045), Vector3(PI * 0.5, 0, 0), Vector3(1.05, 1.0, 0.75))
		_part(kn, BoxMesh.new(), BOOT.darkened(0.25), Vector3(0, -0.4, -0.04), Vector3.ZERO, Vector3(0.13, 0.025, 0.25))
		if side < 0.0:
			hip_l = hp
			knee_l = kn
		else:
			hip_r = hp
			knee_r = kn


func _build_net(hand: Node3D) -> void:
	grip = _joint(hand, Vector3.ZERO)
	grip.rotation.x = IDLE_GRIP
	var pole_len := 1.4
	_part(grip, _cyl(0.017, 0.019, pole_len, 10), WOOD, Vector3(0, -pole_len * 0.5 + 0.15, 0))
	_part(grip, _cyl(0.024, 0.024, 0.18, 10), Color(0.45, 0.25, 0.2), Vector3(0, 0.02, 0))
	var ring_r := 0.27
	hoop = _joint(grip, Vector3(0, -pole_len + 0.15 - ring_r, 0))
	_part(hoop, _torus(ring_r - 0.012, ring_r + 0.012), Color(0.75, 0.7, 0.6), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	var bag := CylinderMesh.new()
	bag.top_radius = ring_r
	bag.bottom_radius = 0.04
	bag.height = 0.5
	bag.radial_segments = 20
	bag.rings = 4
	bag.cap_top = false
	bag.cap_bottom = false
	var net_mat := ShaderMaterial.new()
	net_mat.shader = preload("res://shaders/net.gdshader")
	net_bag = MeshInstance3D.new()
	net_bag.mesh = bag
	net_bag.material_override = net_mat
	# The bag trails behind the hoop's direction of travel during a swing.
	net_bag.position = Vector3(0, 0, -0.25)
	net_bag.rotation = Vector3(PI * 0.5, 0, 0)
	net_bag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hoop.add_child(net_bag)


# ------------------------------------------------------------ animation

## swing: -1 when not swinging, else normalized 0..1 progress.
func animate(delta: float, speed: float, sneaking: bool, on_ground: bool, swing: float) -> void:
	_time += delta
	crouch = move_toward(crouch, 1.0 if sneaking else 0.0, delta * 4.0)
	_air = move_toward(_air, 0.0 if on_ground else 1.0, delta * 6.0)
	var stride := 2.4 if crouch < 0.5 else 3.4
	_phase += delta * speed * stride
	var amt := clampf(speed / 3.4, 0.0, 1.3)
	if crouch > 0.5:
		amt = clampf(speed / 1.5, 0.0, 1.0) * 0.6
	var s := sin(_phase)
	var breath := sin(_time * 1.8) * 0.01

	var leg_swing := 0.55 * amt * (1.0 - _air)
	hip_l.rotation.x = s * leg_swing + crouch * 1.1 + _air * 0.5
	hip_r.rotation.x = -s * leg_swing + crouch * 1.1 + _air * 0.2
	knee_l.rotation.x = -maxf(0.0, sin(_phase + 1.3)) * 0.95 * amt - crouch * 1.7 - _air * 0.9
	knee_r.rotation.x = -maxf(0.0, sin(_phase + 1.3 + PI)) * 0.95 * amt - crouch * 1.7 - _air * 0.4

	var bob := absf(cos(_phase)) * 0.045 * amt
	hips.position.y = 0.8 - crouch * 0.28 + bob
	hips.rotation.y = s * 0.12 * amt
	torso.rotation.x = -crouch * 0.38 - amt * 0.06 + breath
	torso.rotation.y = -s * 0.1 * amt
	head.rotation.x = crouch * 0.3 + amt * 0.04

	shoulder_l.rotation = Vector3(-s * 0.5 * amt + crouch * 0.5, 0, -0.1 - _air * 0.6)
	elbow_l.rotation.x = 0.25 + amt * 0.3 + crouch * 0.6

	if swing < 0.0:
		shoulder_r.rotation = Vector3(0.25 + s * 0.2 * amt + crouch * 0.5, 0, 0.12 + _air * 0.4)
		elbow_r.rotation.x = 0.5 + crouch * 0.3
		grip.rotation.x = lerp_angle(grip.rotation.x, IDLE_GRIP - crouch * 0.9, minf(delta * 10.0, 1.0))
		grip.rotation.z = lerpf(grip.rotation.z, IDLE_TILT, minf(delta * 10.0, 1.0))
	else:
		_animate_swing(swing)


func _animate_swing(t: float) -> void:
	var arm: float
	var g: float
	var twist: float
	var lean: float
	if t < 0.3:
		var k := _ease_out(t / 0.3)
		arm = lerpf(0.25, 3.35, k)
		g = lerpf(IDLE_GRIP - crouch * 0.9, 0.0, k)
		twist = lerpf(0.0, 0.45, k)
		lean = lerpf(0.0, 0.12, k)
	elif t < 0.55:
		var k := _ease_in((t - 0.3) / 0.25)
		arm = lerpf(3.35, 0.85, k)
		g = 0.0
		twist = lerpf(0.45, -0.35, k)
		lean = lerpf(0.12, -0.32, k)
	else:
		var k := _ease_in_out((t - 0.55) / 0.45)
		arm = lerpf(0.85, 0.25, k)
		g = lerpf(0.0, IDLE_GRIP, k)
		twist = lerpf(-0.35, 0.0, k)
		lean = lerpf(-0.32, 0.0, k)
	shoulder_r.rotation = Vector3(arm, 0, 0.1)
	elbow_r.rotation.x = 0.15
	grip.rotation.x = g
	# The sideways tilt straightens out for the swing and returns afterwards.
	var tilt_in := clampf(1.0 - t / 0.2, 0.0, 1.0)
	var tilt_out := clampf((t - 0.7) / 0.3, 0.0, 1.0)
	grip.rotation.z = IDLE_TILT * maxf(tilt_in, tilt_out)
	torso.rotation.y += twist
	torso.rotation.x += lean
	shoulder_l.rotation.x += -twist * 0.8


func _ease_out(x: float) -> float:
	return 1.0 - (1.0 - x) * (1.0 - x)


func _ease_in(x: float) -> float:
	return x * x


func _ease_in_out(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
