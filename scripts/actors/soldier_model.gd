class_name SoldierModel
extends Node3D
## A soldier figure built like a hobbyist's felt action figure: a soft felt
## body in cut-felt camouflage, real kit sewn and glued from craft supplies
## (plate carrier or chest rig, pouches with mags, radio, helmet with NVG
## mount and headset, or beanie and shemagh), varied faces and skin tones,
## and a replica gun. Procedurally animated: walking, aiming,
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
var _modelled := false
var _time := 0.0
var _reload := 0.0


func _ready() -> void:
	if not _built:
		_build()


func _m(kind: int, col: Color, pattern := 0, col2 := Color.WHITE, pscale := 1.0) -> Material:
	return Craft.outlined(Craft.mat(kind, col, pattern, col2, pscale, 0.0, false), 0.012)


const SKIN_TONES := [Color(0.94, 0.8, 0.67), Color(0.86, 0.68, 0.52), Color(0.72, 0.52, 0.38), Color(0.55, 0.38, 0.26), Color(0.4, 0.27, 0.19), Color(0.9, 0.74, 0.6)]

## Varies the face, skin tone and small kit choices per soldier.
var look_seed := randi()


const MODEL := "soldier.glb"
const HAIR := [Color(0.12, 0.09, 0.07), Color(0.24, 0.16, 0.1), Color(0.45, 0.32, 0.18), Color(0.1, 0.1, 0.1), Color(0.55, 0.42, 0.28)]


## The jointed figure modelled in Blender (tools/blender/build_soldier.py):
## each part hangs on the pivot the animation drives, and every material
## slot is swapped for a craft material in the soldier's team colours.
func _build() -> void:
	if not ModelLib.has(MODEL, "torso"):
		_build_procedural()
		return
	_built = true
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var cardstock := team == 0
	var tc: Color = Game.TEAM_COLORS[team]
	var shirt_c := tc.darkened(0.24) if cardstock else tc.darkened(0.22)
	var camo2 := tc.lerp(Color(0.24, 0.26, 0.27), 0.5) if cardstock else tc.lerp(Color(0.36, 0.3, 0.22), 0.55)
	var gear_c := Color(0.44, 0.37, 0.26) if cardstock else Color(0.32, 0.33, 0.23)
	var skin_c: Color = SKIN_TONES[rng.randi() % SKIN_TONES.size()]
	var hair_c: Color = HAIR[rng.randi() % HAIR.size()]
	var flat := func(kind: int, col: Color, pattern := 0, col2 := Color.WHITE, pscale := 1.0) -> Material:
		return Craft.mat(kind, col, pattern, col2, pscale, 0.0, false)
	var mats := {
		"uniform": _m(Craft.Kind.FELT, shirt_c, Craft.Pattern.CAMO, camo2, 7.0),
		"uniform_dark": flat.call(Craft.Kind.FELT, shirt_c.darkened(0.35)),
		"pants": _m(Craft.Kind.FELT, tc.darkened(0.22), Craft.Pattern.CAMO, camo2.darkened(0.2), 7.0) if cardstock else _m(Craft.Kind.FELT, Color(0.44, 0.4, 0.3), Craft.Pattern.STITCH, Color(0.3, 0.27, 0.2)),
		"gear": _m(Craft.Kind.FELT, gear_c, Craft.Pattern.STITCH, gear_c.darkened(0.35)),
		"webbing": flat.call(Craft.Kind.FELT, gear_c.darkened(0.3)),
		"black": _m(Craft.Kind.PAPER, Color(0.1, 0.1, 0.11)),
		"mag": flat.call(Craft.Kind.PAPER, Color(0.13, 0.13, 0.14)),
		"metal": flat.call(Craft.Kind.FOIL, Color(0.55, 0.56, 0.58)),
		"skin": Craft.outlined(Craft.mat(Craft.Kind.PAPER, skin_c, 0, Color.WHITE, 1.0, 0.0, false), 0.005),
		"skin_dark": flat.call(Craft.Kind.PAPER, skin_c.darkened(0.35)),
		"eye": flat.call(Craft.Kind.PAPER, Color(0.9, 0.89, 0.86)),
		"iris": flat.call(Craft.Kind.PLASTIC, Color(0.08, 0.06, 0.05)),
		"hair": flat.call(Craft.Kind.FELT, hair_c),
		"glove": _m(Craft.Kind.FELT, Color(0.13, 0.13, 0.14) if cardstock else Color(0.3, 0.24, 0.17)),
		"boot": _m(Craft.Kind.FELT, Color(0.42, 0.34, 0.24) if cardstock else Color(0.24, 0.17, 0.12), Craft.Pattern.STITCH, Color(0.2, 0.16, 0.12)),
		"sole": flat.call(Craft.Kind.PAPER, Color(0.08, 0.08, 0.08)),
		"lace": flat.call(Craft.Kind.FELT, Color(0.16, 0.14, 0.12)),
		"patch": flat.call(Craft.Kind.FELT, tc, Craft.Pattern.BANDS, tc.lightened(0.45), 60.0),
		"knit": _m(Craft.Kind.KNIT, [Color(0.18, 0.18, 0.19), Color(0.26, 0.27, 0.21), Color(0.3, 0.22, 0.16)][rng.randi() % 3]),
		"shemagh": _m(Craft.Kind.FELT, Color(0.78, 0.74, 0.64), Craft.Pattern.CHECKER, Color(0.5, 0.22, 0.18), 45.0),
	}
	for k in mats:
		mats[k] = Craft.moving(mats[k])
	var put := func(parent: Node3D, part_name: String) -> void:
		ModelLib.part(parent, MODEL, part_name, mats)

	hips = Craft.pivot(self, Vector3(0, 0.95, 0))
	put.call(hips, "pelvis")
	if cardstock or rng.randf() < 0.5:
		put.call(hips, "belt_gear")
	torso = Craft.pivot(hips, Vector3(0, 0.08, 0))
	put.call(torso, "torso")
	put.call(torso, "carrier" if cardstock else "rig")
	head = Craft.pivot(torso, Vector3(0, 0.47, 0))
	put.call(head, "head_a" if rng.randf() < 0.5 else "head_b")
	if cardstock:
		put.call(head, "helmet")
		put.call(head, "headset")
	else:
		put.call(head, "beanie")
		var masked := rng.randf() < 0.65
		if masked:
			put.call(head, "shemagh")
		elif rng.randf() < 0.6:
			put.call(head, "beard")
	for side: float in [-1.0, 1.0]:
		var sh := Craft.pivot(torso, Vector3(side * 0.19, 0.42, 0))
		put.call(sh, "upper_arm_patch" if side < 0.0 and cardstock else "upper_arm")
		var el := Craft.pivot(sh, Vector3(0, -0.29, 0))
		put.call(el, "forearm")
		if side < 0.0:
			arm_l = sh
			forearm_l = el
		else:
			arm_r = sh
			forearm_r = el
	for side: float in [-1.0, 1.0]:
		var hp := Craft.pivot(hips, Vector3(side * 0.095, -0.06, 0))
		put.call(hp, "thigh_L" if side < 0.0 else "thigh_R")
		var kn := Craft.pivot(hp, Vector3(0, -0.43, 0))
		put.call(kn, "shin")
		if cardstock:
			put.call(kn, "kneepad")
		if side < 0.0:
			leg_l = hp
			knee_l = kn
		else:
			leg_r = hp
			knee_r = kn
	gun_mount = Craft.pivot(torso, Vector3(0.1, 0.36, -0.3))
	_modelled = true


## The original all-procedural doll, kept as a fallback if the modelled
## parts are missing.
func _build_procedural() -> void:
	_built = true
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var cardstock := team == 0
	var tc: Color = Game.TEAM_COLORS[team]
	# Uniforms are cut-felt camouflage in the team's colours: Cardstock in a
	# navy-grey urban pattern, the Militia in rust jackets and khaki cargos.
	var shirt_c := tc.darkened(0.24) if cardstock else tc.darkened(0.22)
	var camo2 := tc.lerp(Color(0.24, 0.26, 0.27), 0.5) if cardstock else tc.lerp(Color(0.36, 0.3, 0.22), 0.55)
	var shirt := _m(Craft.Kind.FELT, shirt_c, Craft.Pattern.CAMO, camo2, 7.0)
	var pants := _m(Craft.Kind.FELT, tc.darkened(0.22), Craft.Pattern.CAMO, camo2.darkened(0.2), 7.0) if cardstock else _m(Craft.Kind.FELT, Color(0.44, 0.4, 0.3), Craft.Pattern.STITCH, Color(0.3, 0.27, 0.2))
	var gear_c := Color(0.44, 0.37, 0.26) if cardstock else Color(0.32, 0.33, 0.23)
	var gear := _m(Craft.Kind.FELT, gear_c, Craft.Pattern.STITCH, gear_c.darkened(0.35))
	var webbing := Craft.mat(Craft.Kind.FELT, gear_c.darkened(0.3), 0, Color.WHITE, 1.0, 0.0, false)
	var black := _m(Craft.Kind.PAPER, Color(0.1, 0.1, 0.11))
	var mag_m := Craft.mat(Craft.Kind.PAPER, Color(0.13, 0.13, 0.14), 0, Color.WHITE, 1.0, 0.0, false)
	var skin_c: Color = SKIN_TONES[rng.randi() % SKIN_TONES.size()]
	var skin := _m(Craft.Kind.PAPER, skin_c)
	var glove := _m(Craft.Kind.FELT, Color(0.13, 0.13, 0.14) if cardstock else Color(0.3, 0.24, 0.17))
	var boot := _m(Craft.Kind.FELT, Color(0.42, 0.34, 0.24) if cardstock else Color(0.24, 0.17, 0.12), Craft.Pattern.STITCH, Color(0.2, 0.16, 0.12))
	var sole := Craft.mat(Craft.Kind.PAPER, Color(0.08, 0.08, 0.08), 0, Color.WHITE, 1.0, 0.0, false)
	var patch := Craft.mat(Craft.Kind.FELT, tc, Craft.Pattern.BANDS, tc.lightened(0.45), 60.0, 0.0, false)

	# Hips, belt and buckle.
	hips = Craft.pivot(self, Vector3(0, 0.84, 0))
	Craft.part(hips, Craft.capsule(0.2, 0.42), pants, Vector3(0, 0.0, 0), Vector3(0, 0, PI * 0.5), Vector3(1.0, 1.0, 0.72))
	Craft.part(hips, Craft.cylinder(0.205, 0.205, 0.05, 16), webbing, Vector3(0, 0.07, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.74))
	Craft.box(hips, Vector3(0, 0.07, -0.152), Vector3(0.06, 0.04, 0.01), Craft.mat(Craft.Kind.FOIL, Color(0.5, 0.51, 0.52), 0, Color.WHITE, 1.0, 0.0, false))
	# Dump pouch / holster on the hip.
	Craft.box(hips, Vector3(0.19, -0.02, 0.02), Vector3(0.06, 0.16, 0.1), gear)
	Craft.box(hips, Vector3(0.19, -0.02, 0.02), Vector3(0.065, 0.02, 0.105), webbing)

	torso = Craft.pivot(hips, Vector3(0, 0.1, 0))
	Craft.part(torso, Craft.capsule(0.22, 0.62), shirt, Vector3(0, 0.27, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.72))
	var vest_root := Craft.pivot(torso, Vector3(0, 0.27, 0))
	if cardstock:
		# Plate carrier: front and back plates, cummerbund, shoulder pads,
		# MOLLE webbing, three rifle-mag pouches with mags showing, an
		# admin pouch with a flag patch, a radio with its antenna, and a
		# hydration pack on the back.
		Craft.box(vest_root, Vector3(0, 0.03, -0.13), Vector3(0.36, 0.4, 0.08), gear, Vector3(0.06, 0, 0))
		Craft.box(vest_root, Vector3(0, 0.03, 0.14), Vector3(0.36, 0.42, 0.08), gear, Vector3(-0.05, 0, 0))
		for sx: float in [-1.0, 1.0]:
			Craft.box(vest_root, Vector3(sx * 0.19, -0.06, 0.0), Vector3(0.05, 0.2, 0.26), gear)
			Craft.box(vest_root, Vector3(sx * 0.13, 0.25, 0.0), Vector3(0.08, 0.05, 0.32), gear)
		for row in 4:
			Craft.box(vest_root, Vector3(0, 0.1 + row * 0.035, 0.183), Vector3(0.34, 0.012, 0.006), webbing)
		for x: float in [-0.11, 0.0, 0.11]:
			Craft.box(vest_root, Vector3(x, -0.08, -0.19), Vector3(0.095, 0.13, 0.06), gear)
			Craft.box(vest_root, Vector3(x, 0.0, -0.19), Vector3(0.05, 0.05, 0.03), mag_m, Vector3(0.12, 0, 0))
			Craft.box(vest_root, Vector3(x, -0.03, -0.222), Vector3(0.012, 0.07, 0.004), black)
		Craft.box(vest_root, Vector3(0, 0.12, -0.178), Vector3(0.2, 0.1, 0.03), gear)
		Craft.box(vest_root, Vector3(0, 0.125, -0.196), Vector3(0.09, 0.055, 0.006), patch)
		Craft.box(vest_root, Vector3(-0.16, 0.12, 0.11), Vector3(0.07, 0.14, 0.06), black)
		Craft.part(vest_root, Craft.capsule(0.007, 0.4), black, Vector3(-0.17, 0.38, 0.13), Vector3(0.1, 0, 0.05))
		Craft.box(vest_root, Vector3(0, 0.0, 0.215), Vector3(0.24, 0.32, 0.07), gear)
	else:
		# Chest rig: a strip of four AK mag pouches on X-harness straps,
		# with a cut-down shemagh scarf at the neck.
		Craft.box(vest_root, Vector3(0, -0.08, -0.155), Vector3(0.38, 0.15, 0.07), gear)
		for x: float in [-0.135, -0.045, 0.045, 0.135]:
			Craft.box(vest_root, Vector3(x, -0.08, -0.198), Vector3(0.078, 0.14, 0.03), gear)
			Craft.box(vest_root, Vector3(x, 0.005, -0.18), Vector3(0.05, 0.04, 0.03), mag_m, Vector3(0.2, 0, 0))
		for sx: float in [-1.0, 1.0]:
			Craft.box(vest_root, Vector3(sx * 0.11, 0.12, -0.15), Vector3(0.05, 0.3, 0.02), webbing, Vector3(0.1, 0, sx * 0.2))
			Craft.box(vest_root, Vector3(sx * 0.11, 0.08, 0.15), Vector3(0.05, 0.36, 0.02), webbing, Vector3(-0.1, 0, -sx * 0.5))
	# Shoulder flag patch on the left upper arm is added with the arms.

	head = Craft.pivot(torso, Vector3(0, 0.56, 0))
	Craft.part(head, Craft.sphere(0.17, 18), skin, Vector3(0, 0.15, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.96))
	# A real face, kept simple: small button eyes, brows, a nose, a stitched
	# mouth and ears.
	var eye := Craft.mat(Craft.Kind.PLASTIC, Color(0.06, 0.05, 0.05), 0, Color.WHITE, 1.0, 0.0, false)
	var hair_c: Color = [Color(0.12, 0.09, 0.07), Color(0.24, 0.16, 0.1), Color(0.45, 0.32, 0.18), Color(0.1, 0.1, 0.1)][rng.randi() % 4]
	var brow := Craft.mat(Craft.Kind.FELT, hair_c, 0, Color.WHITE, 1.0, 0.0, false)
	var shades := cardstock and rng.randf() < 0.4
	for sx: float in [-1.0, 1.0]:
		if not shades:
			Craft.part(head, Craft.cylinder(0.021, 0.021, 0.014, 10), eye, Vector3(sx * 0.058, 0.16, -0.158), Vector3(PI * 0.5, 0, 0))
			Craft.part(head, Craft.sphere(0.005, 6), Craft.mat(Craft.Kind.PLASTIC, Color(0.85, 0.85, 0.85), 0, Color.WHITE, 1.0, 0.0, false), Vector3(sx * 0.052, 0.168, -0.167))
		Craft.box(head, Vector3(sx * 0.058, 0.2, -0.153), Vector3(0.06, 0.012, 0.016), brow, Vector3(0, 0, sx * 0.12))
		Craft.part(head, Craft.sphere(0.032, 8), skin, Vector3(sx * 0.165, 0.14, 0.0), Vector3.ZERO, Vector3(0.5, 1.0, 0.8))
	if shades:
		Craft.box(head, Vector3(0, 0.162, -0.158), Vector3(0.2, 0.045, 0.02), black)
	Craft.part(head, Craft.sphere(0.026, 8), _m(Craft.Kind.PAPER, skin_c.darkened(0.06)), Vector3(0, 0.12, -0.165), Vector3.ZERO, Vector3(0.8, 1.0, 0.9))
	Craft.box(head, Vector3(0, 0.075, -0.158), Vector3(0.05, 0.006, 0.01), Craft.mat(Craft.Kind.FELT, skin_c.darkened(0.45), 0, Color.WHITE, 1.0, 0.0, false))
	if cardstock:
		# Helmet in a camo cover, black rails and NVG mount, a strobe, a
		# chin strap and a comms headset.
		Craft.part(head, Craft.sphere(0.2, 18), shirt, Vector3(0, 0.22, 0.01), Vector3.ZERO, Vector3(1.05, 0.72, 1.1))
		Craft.part(head, Craft.cylinder(0.212, 0.212, 0.03, 20), _m(Craft.Kind.FELT, camo2.darkened(0.25)), Vector3(0, 0.2, 0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.04))
		Craft.box(head, Vector3(0, 0.27, -0.2), Vector3(0.07, 0.05, 0.03), black, Vector3(0.3, 0, 0))
		for sx: float in [-1.0, 1.0]:
			Craft.box(head, Vector3(sx * 0.205, 0.24, 0.0), Vector3(0.02, 0.025, 0.16), black, Vector3(0, 0, sx * 0.25))
			Craft.part(head, Craft.cylinder(0.055, 0.055, 0.045, 14), black, Vector3(sx * 0.178, 0.14, 0.0), Vector3(0, 0, PI * 0.5))
			Craft.box(head, Vector3(sx * 0.17, 0.08, -0.05), Vector3(0.012, 0.12, 0.012), black, Vector3(0.5, 0, 0))
		Craft.box(head, Vector3(0, 0.33, 0.13), Vector3(0.04, 0.03, 0.04), black)
		Craft.box(head, Vector3(0, 0.3, 0.18), Vector3(0.08, 0.05, 0.006), patch, Vector3(-0.6, 0, 0))
	else:
		# Dark knit beanie and a red-and-cream checked shemagh over the
		# nose and mouth.
		var knit := _m(Craft.Kind.KNIT, [Color(0.18, 0.18, 0.19), Color(0.26, 0.27, 0.21), Color(0.3, 0.22, 0.16)][rng.randi() % 3])
		Craft.part(head, Craft.sphere(0.183, 16), knit, Vector3(0, 0.255, 0.01), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
		Craft.part(head, Craft.cylinder(0.188, 0.188, 0.05, 18), knit, Vector3(0, 0.225, 0.01))
		var shemagh := _m(Craft.Kind.FELT, Color(0.76, 0.72, 0.62), Craft.Pattern.CHECKER, Color(0.48, 0.22, 0.18), 110.0)
		Craft.box(head, Vector3(0, 0.07, -0.11), Vector3(0.3, 0.12, 0.12), shemagh, Vector3(0.1, 0, 0))
		Craft.part(head, Craft.cylinder(0.2, 0.17, 0.1, 16), shemagh, Vector3(0, -0.01, 0.0))

	for side: float in [-1.0, 1.0]:
		var sh := Craft.pivot(torso, Vector3(side * 0.27, 0.45, 0))
		Craft.part(sh, Craft.capsule(0.07, 0.32), shirt, Vector3(0, -0.13, 0))
		if side < 0.0:
			Craft.box(sh, Vector3(-0.07, -0.08, 0.0), Vector3(0.006, 0.05, 0.07), patch)
		var el := Craft.pivot(sh, Vector3(0, -0.27, 0))
		Craft.part(el, Craft.capsule(0.06, 0.28), shirt, Vector3(0, -0.12, 0))
		Craft.part(el, Craft.cylinder(0.064, 0.064, 0.04, 12), webbing, Vector3(0, -0.21, 0))
		Craft.part(el, Craft.sphere(0.062, 10), glove, Vector3(0, -0.27, 0), Vector3.ZERO, Vector3(0.9, 1.0, 1.1))
		if side < 0.0:
			arm_l = sh
			forearm_l = el
		else:
			arm_r = sh
			forearm_r = el
		GunBuilder._bake(sh, true)
		GunBuilder._bake(el, true)
	for side: float in [-1.0, 1.0]:
		var hp := Craft.pivot(hips, Vector3(side * 0.11, -0.04, 0))
		Craft.part(hp, Craft.capsule(0.095, 0.42), pants, Vector3(0, -0.17, 0))
		# Cargo pocket with its flap.
		Craft.box(hp, Vector3(side * 0.09, -0.2, -0.01), Vector3(0.03, 0.12, 0.12), pants)
		Craft.box(hp, Vector3(side * 0.102, -0.145, -0.01), Vector3(0.012, 0.03, 0.125), webbing)
		var kn := Craft.pivot(hp, Vector3(0, -0.38, 0))
		Craft.part(kn, Craft.capsule(0.085, 0.38), pants, Vector3(0, -0.15, 0))
		if cardstock:
			Craft.part(kn, Craft.sphere(0.07, 10), black, Vector3(0, -0.01, -0.07), Vector3.ZERO, Vector3(1.0, 1.1, 0.55))
		# Laced boots on dark soles.
		Craft.part(kn, Craft.cylinder(0.092, 0.092, 0.1, 12), boot, Vector3(0, -0.26, 0))
		Craft.part(kn, Craft.capsule(0.08, 0.28), boot, Vector3(0, -0.36, -0.05), Vector3(PI * 0.5, 0, 0), Vector3(1.15, 1.0, 0.8))
		Craft.box(kn, Vector3(0, -0.43, -0.05), Vector3(0.18, 0.025, 0.3), sole)
		for i in 3:
			Craft.box(kn, Vector3(0, -0.32 + i * 0.03, -0.125 + i * 0.012), Vector3(0.07, 0.006, 0.01), webbing)
		if side < 0.0:
			leg_l = hp
			knee_l = kn
		else:
			leg_r = hp
			knee_r = kn
		GunBuilder._bake(hp, true)
		GunBuilder._bake(kn, true)
	gun_mount = Craft.pivot(torso, Vector3(0.12, 0.33, -0.25))
	Craft.make_moving(self)
	# Merge each body part's pieces so a squad of dolls stays cheap to draw.
	for n: Node3D in [hips, torso, vest_root, head]:
		GunBuilder._bake(n, true)


var _shadow_only := false


func set_weapon(id: String, att := "") -> void:
	if not _built:
		_build()
	if gun:
		gun.queue_free()
	gun = GunBuilder.build(id, false, Game.TEAM_COLORS[team], att)
	gun_mount.add_child(gun)
	if _shadow_only:
		_set_cast(gun, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)


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
	_shadow_only = on
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
	hips.position.y = (0.95 - _crouch * 0.42 if _modelled else 0.84 - _crouch * 0.38) + absf(cos(_phase)) * 0.04 * amt
	hips.rotation.y = s * 0.1 * amt
	torso.rotation.x = -_crouch * 0.15 - (0.25 if sprinting else 0.0)
	torso.rotation.y = -s * 0.08 * amt

	# Idle breathing and a slight lean into crouch-walking.
	_time += delta
	var breathe := sin(_time * 1.6) * 0.012 * (1.0 - amt * 0.7)
	torso.rotation.x += breathe - _crouch * amt * 0.12

	# Reloading: read the owner's weapon so bots and remote players match.
	var target_reload := 0.0
	var sol := get_parent() as Soldier
	if sol and not sol.weapons.is_empty():
		var w := sol.weapon()
		if w.reloading > 0.0 and w.reload_total > 0.0:
			target_reload = 1.0 - w.reloading / w.reload_total
	_reload = target_reload
	var rl := 0.0
	if _reload > 0.0:
		rl = smoothstep(0.0, 0.12, _reload) * (1.0 - smoothstep(0.85, 1.0, _reload))

	var aim := clampf(pitch, -1.2, 1.2) * (1.0 - _prone * 0.6)
	head.rotation.x = aim * 0.5 + rl * 0.25
	# Positive X rotation swings a limb forward (the doll faces -Z).
	if sprinting:
		# Rifle carried across the chest, the free arm pumping.
		arm_r.rotation = Vector3(0.55 + s * 0.2, 0, 0.12)
		arm_l.rotation = Vector3(0.8 - s * 0.35, 0, -0.32)
		forearm_r.rotation.x = 1.25
		forearm_l.rotation.x = 1.35
		gun_mount.rotation = Vector3(-0.85, 0.95, 0.35 + s * 0.06)
	else:
		# Shouldered and aimed; reloading tips the gun and the support hand
		# drops to the magazine well and back.
		var mag_hand := sin(clampf((_reload - 0.15) / 0.6, 0.0, 1.0) * PI) * rl
		arm_r.rotation = Vector3(1.25 + aim + _kick * 0.12 - rl * 0.35, 0.25, 0.0)
		forearm_r.rotation.x = 0.35 + rl * 0.25
		arm_l.rotation = Vector3(1.45 + aim - rl * 0.5 - mag_hand * 0.45, -0.55 + rl * 0.25, 0.0)
		forearm_l.rotation.x = 0.1 + rl * 0.5
		gun_mount.rotation = Vector3(aim + _kick * 0.15 - rl * 0.45, rl * 0.2, rl * 0.55)
	gun_mount.position = (Vector3(0.1, 0.36, -0.3) if _modelled else Vector3(0.12, 0.33, -0.25)) + Vector3(0, -rl * 0.06, _kick * 0.05)


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
