class_name GunBuilder
extends RefCounted
## Builds the guns as model-quality craft pieces. Each major part is cut
## from a true side-profile silhouette and extruded like laminated
## cardboard (outer skins of painted card over a kraft core you can see at
## the edges), then dressed with rails, rivets, tape wraps, foil barrels and
## optics. The barrel points along -Z; the origin is the firing hand.
##
## Metadata on the root:
##   "sight"  : Vector3 the eye lines up with when aiming down sights
##   "muzzle" : Node3D at the barrel tip
##   "mag"    : Node3D magazine (animated during reloads)
##   "pump"   : Node3D fore-end (shotgun), only when present
##   "left"   : Vector3 where the support hand holds

const CORE := Color(0.8, 0.62, 0.42)


class Kit:
	## Materials and helpers for one gun, so parts can be terse.
	var vm: bool
	var ow: float
	var shadows: bool
	var body: Material
	var body_core: Material
	var trim: Material
	var trim_core: Material
	var dark: Material
	var foil: Material
	var tape: Material
	var brass: Material
	var team: Material
	var glow_red: Material
	var glass: Material

	func _init(viewmodel: bool, body_c: Color, trim_c: Color, team_c: Color) -> void:
		vm = viewmodel
		ow = 0.003 if viewmodel else 0.01
		shadows = not viewmodel
		body = _o(Craft.mat(Craft.Kind.PAPER, body_c, 0, Color.WHITE, 1.0, 0.0, false, vm))
		body_core = Craft.mat(Craft.Kind.CARDBOARD, body_c.lerp(CORE, 0.55), 0, Color.WHITE, 1.0, 0.0, false, vm)
		trim = _o(Craft.mat(Craft.Kind.CARDBOARD, trim_c, 0, Color.WHITE, 1.0, 0.0, false, vm))
		trim_core = Craft.mat(Craft.Kind.CARDBOARD, trim_c.lerp(CORE, 0.6).darkened(0.1), 0, Color.WHITE, 1.0, 0.0, false, vm)
		dark = _o(Craft.mat(Craft.Kind.PAPER, Color(0.24, 0.25, 0.28), 0, Color.WHITE, 1.0, 0.0, false, vm))
		foil = _o(Craft.mat(Craft.Kind.FOIL, Color(0.8, 0.82, 0.86), 0, Color.WHITE, 1.0, 0.0, false, vm))
		tape = Craft.mat(Craft.Kind.TAPE, Color(0.93, 0.86, 0.66), 0, Color.WHITE, 1.0, 0.0, false, vm)
		brass = Craft.mat(Craft.Kind.PLASTIC, Color(0.88, 0.68, 0.26), 0, Color.WHITE, 1.0, 0.0, false, vm)
		team = Craft.mat(Craft.Kind.PAPER, team_c, 0, Color.WHITE, 1.0, 0.0, false, vm)
		glow_red = Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.12, 0.08), 0, Color.WHITE, 1.0, 0.0, false, vm)
		glass = Craft.cellophane(Color(0.6, 0.85, 1.0, 0.18))

	func _o(m: ShaderMaterial) -> Material:
		return Craft.outlined(m, ow, vm)

	## A part cut from a side profile. pts are (forward, up) in metres.
	## Laminated: a kraft core with thinner painted skins either side.
	func prof(parent: Node3D, pts: Array, thick: float, skin: Material, core: Material = null, x := 0.0) -> Node3D:
		var poly := PackedVector2Array()
		for p in pts:
			poly.append(p)
		if Geometry2D.is_polygon_clockwise(poly):
			poly.reverse()
		var holder := Node3D.new()
		holder.position = Vector3(x, 0, 0)
		holder.rotation.y = PI * 0.5
		parent.add_child(holder)
		if core:
			var inner := Craft.part(holder, Craft.cutout(poly, thick), core, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, shadows)
			inner.scale = Vector3(0.995, 0.995, 1.0)
			Craft.part(holder, Craft.cutout(poly, thick * 0.22), skin, Vector3(0, 0, thick * 0.45), Vector3.ZERO, Vector3.ONE, shadows)
			Craft.part(holder, Craft.cutout(poly, thick * 0.22), skin, Vector3(0, 0, -thick * 0.45), Vector3.ZERO, Vector3.ONE, shadows)
		else:
			Craft.part(holder, Craft.cutout(poly, thick), skin, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, shadows)
		return holder

	func box(parent: Node3D, f: float, y: float, size: Vector3, m: Material, x := 0.0, rot := Vector3.ZERO) -> MeshInstance3D:
		return Craft.box(parent, Vector3(x, y, -f), size, m, rot, shadows)

	## A cylinder along the barrel axis from f0 to f1.
	func tube(parent: Node3D, f0: float, f1: float, y: float, r: float, m: Material, x := 0.0, segs := 14) -> MeshInstance3D:
		return Craft.part(parent, Craft.cylinder(r, r, f1 - f0, segs), m, Vector3(x, y, -(f0 + f1) * 0.5), Vector3(PI * 0.5, 0, 0), Vector3.ONE, shadows)

	## A little disc (button, rivet, sight bead) facing sideways (+X).
	func rivet(parent: Node3D, f: float, y: float, x: float, r: float, m: Material) -> void:
		Craft.part(parent, Craft.cylinder(r, r, r * 0.7, 10), m, Vector3(x, y, -f), Vector3(0, 0, PI * 0.5), Vector3.ONE, shadows)

	## Picatinny rail: a strip with notched teeth.
	func rail(parent: Node3D, f0: float, f1: float, y: float, width: float, x := 0.0, up := true) -> void:
		var len := f1 - f0
		if up:
			box(parent, (f0 + f1) * 0.5, y, Vector3(width, 0.008, len), dark, x)
		else:
			box(parent, (f0 + f1) * 0.5, y, Vector3(0.008, width, len), dark, x)
		var n := int(len / 0.012)
		for i in n:
			var f := f0 + (i + 0.5) * len / n
			if up:
				box(parent, f, y + 0.007, Vector3(width * 1.05, 0.006, 0.006), dark, x)
			else:
				box(parent, f, y, Vector3(0.006, width * 1.05, 0.006), dark, x + signf(x) * 0.007)

	## Masking tape wrapped around a part.
	func wrap(parent: Node3D, f: float, y: float, size: Vector2) -> void:
		box(parent, f, y, Vector3(size.x + 0.004, size.y + 0.004, 0.018), tape)

	## Tube-style red dot sight. Returns the sight centre height.
	func red_dot(parent: Node3D, f: float, base_y: float) -> float:
		var cy := base_y + 0.032
		box(parent, f, base_y + 0.008, Vector3(0.03, 0.016, 0.05), dark)
		box(parent, f, base_y + 0.018, Vector3(0.012, 0.012, 0.03), dark)
		var shell := Craft.tube(0.021, 0.085, 18, false)
		var hold := Node3D.new()
		hold.position = Vector3(0, cy, -f)
		hold.rotation.y = PI * 0.5
		parent.add_child(hold)
		Craft.part(hold, shell, body, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, shadows)
		Craft.part(hold, Craft.tube(0.0195, 0.085, 18, true), dark, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
		for side: float in [-1.0, 1.0]:
			Craft.part(hold, Craft.tube(0.024, 0.012, 18, false), body, Vector3(side * 0.043, 0, 0), Vector3.ZERO, Vector3.ONE, shadows)
			Craft.part(hold, Craft.tube(0.0195, 0.012, 18, true), dark, Vector3(side * 0.043, 0, 0), Vector3.ZERO, Vector3.ONE, false)
		box(parent, f, cy + 0.026, Vector3(0.012, 0.012, 0.014), brass)
		rivet(parent, f, cy, 0.025, 0.007, brass)
		var lens := Craft.part(parent, Craft.cylinder(0.0195, 0.0195, 0.002, 18), Craft.cellophane(Color(1.0, 0.55, 0.45, 0.16)), Vector3(0, cy, -(f + 0.04)), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Craft.part(parent, Craft.sphere(0.0022, 8), glow_red, Vector3(0, cy, -(f + 0.035)), Vector3.ZERO, Vector3.ONE, false)
		return cy

	## Box-style holographic sight with a ring-and-dot reticle.
	func holo(parent: Node3D, f: float, base_y: float) -> float:
		var cy := base_y + 0.03
		box(parent, f, base_y + 0.006, Vector3(0.036, 0.012, 0.075), body)
		box(parent, f + 0.02, base_y + 0.014, Vector3(0.03, 0.01, 0.03), dark)
		for side: float in [-1.0, 1.0]:
			box(parent, f, cy, Vector3(0.005, 0.044, 0.07), body, side * 0.02)
		box(parent, f, cy + 0.024, Vector3(0.045, 0.006, 0.07), body)
		var gl := box(parent, f + 0.03, cy, Vector3(0.036, 0.04, 0.002), glass)
		gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Ring-and-dot reticle made of tiny glowing beads.
		for i in 20:
			var a := TAU * i / 20.0
			Craft.part(parent, Craft.sphere(0.0011, 6), glow_red, Vector3(cos(a) * 0.0085, cy + sin(a) * 0.0085, -(f + 0.028)), Vector3.ZERO, Vector3.ONE, false)
		Craft.part(parent, Craft.sphere(0.0016, 8), glow_red, Vector3(0, cy, -(f + 0.028)), Vector3.ZERO, Vector3.ONE, false)
		return cy


static func build(id: String, viewmodel: bool, team_color := Color(0.24, 0.45, 0.85)) -> Node3D:
	var w := WeaponDB.get_data(id)
	var root := Node3D.new()
	root.name = "Gun_" + id
	var k := Kit.new(viewmodel, w["body"], w["trim"], team_color)
	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	root.add_child(muzzle)
	var mag := Node3D.new()
	mag.name = "Mag"
	root.add_child(mag)
	var sight_y := 0.1
	var left := Vector3(0, 0.0, -0.33)
	match String(w["model"]):
		"rifle":
			sight_y = _m4(root, mag, k, team_color)
			muzzle.position = Vector3(0, 0.072, -0.73)
			left = Vector3(0, 0.035, -0.34)
		"ak":
			sight_y = _ak(root, mag, k)
			muzzle.position = Vector3(0, 0.072, -0.74)
			left = Vector3(0, 0.03, -0.34)
		"smg":
			sight_y = _smg(root, mag, k)
			muzzle.position = Vector3(0, 0.06, -0.46)
			left = Vector3(0, -0.035, -0.27)
		"sniper":
			sight_y = _sniper(root, mag, k)
			muzzle.position = Vector3(0, 0.07, -1.02)
			left = Vector3(0, 0.03, -0.4)
		"shotgun":
			var pump := Node3D.new()
			pump.name = "Pump"
			root.add_child(pump)
			sight_y = _shotgun(root, pump, k)
			root.set_meta("pump", pump)
			muzzle.position = Vector3(0, 0.07, -0.78)
			left = Vector3(0, 0.02, -0.42)
		"pistol":
			sight_y = _pistol(root, mag, k)
			muzzle.position = Vector3(0, 0.07, -0.19)
			left = Vector3(-0.025, -0.045, 0.0)
	root.set_meta("muzzle", muzzle)
	root.set_meta("mag", mag)
	root.set_meta("sight", Vector3(0, sight_y, 0))
	root.set_meta("left", left)
	# How close the sights sit to the eye when aiming: optics come in close.
	var ads_z := -0.28
	match String(w["model"]):
		"rifle", "smg":
			ads_z = -0.235
		"pistol":
			ads_z = -0.32
		"shotgun", "ak":
			ads_z = -0.26
	root.set_meta("ads_z", ads_z)
	return root


# ------------------------------------------------------------------- M4A1

static func _m4(r: Node3D, mag: Node3D, k: Kit, team_c: Color) -> float:
	# Lower receiver with magwell, upper receiver, collapsible stock.
	k.prof(r, [Vector2(-0.07, 0.0), Vector2(0.2, 0.0), Vector2(0.2, 0.052), Vector2(-0.07, 0.052)], 0.05, k.body, k.body_core)
	k.prof(r, [Vector2(0.065, 0.004), Vector2(0.158, 0.004), Vector2(0.152, -0.04), Vector2(0.07, -0.04)], 0.048, k.body, k.body_core)
	k.prof(r, [Vector2(-0.075, 0.052), Vector2(0.215, 0.052), Vector2(0.215, 0.098), Vector2(-0.06, 0.098), Vector2(-0.075, 0.085)], 0.046, k.body, k.body_core)
	k.tube(r, -0.33, -0.07, 0.07, 0.016, k.dark)
	k.prof(r, [Vector2(-0.12, 0.096), Vector2(-0.12, 0.03), Vector2(-0.2, 0.01), Vector2(-0.31, 0.0), Vector2(-0.325, 0.05), Vector2(-0.315, 0.098), Vector2(-0.2, 0.098)], 0.042, k.trim, k.trim_core)
	k.box(r, -0.32, 0.048, Vector3(0.046, 0.11, 0.012), k.trim)
	# Pistol grip, trigger guard and trigger.
	k.prof(r, [Vector2(-0.005, 0.004), Vector2(0.045, 0.004), Vector2(0.02, -0.105), Vector2(-0.032, -0.098)], 0.036, k.trim, k.trim_core)
	k.box(r, 0.075, -0.035, Vector3(0.012, 0.006, 0.08), k.dark)
	k.box(r, 0.065, -0.018, Vector3(0.005, 0.03, 0.006), k.foil, 0.0, Vector3(-0.3, 0, 0))
	# Handguard with rails and tape wraps, barrel, gas block, flash hider.
	k.prof(r, [Vector2(0.215, 0.035), Vector2(0.48, 0.035), Vector2(0.48, 0.105), Vector2(0.215, 0.105)], 0.056, k.trim, k.trim_core)
	k.rail(r, -0.05, 0.21, 0.102, 0.024)
	k.rail(r, 0.22, 0.47, 0.109, 0.024)
	for side: float in [-1.0, 1.0]:
		k.rail(r, 0.3, 0.46, 0.07, 0.022, side * 0.03, false)
	k.wrap(r, 0.26, 0.07, Vector2(0.056, 0.07))
	k.wrap(r, 0.43, 0.07, Vector2(0.056, 0.07))
	k.tube(r, 0.48, 0.67, 0.072, 0.011, k.foil)
	k.box(r, 0.5, 0.075, Vector3(0.03, 0.03, 0.025), k.dark)
	k.tube(r, 0.66, 0.73, 0.072, 0.014, k.dark)
	for f: float in [0.68, 0.7, 0.72]:
		k.box(r, f, 0.072, Vector3(0.03, 0.004, 0.004), k.foil)
	# Charging handle, forward assist, ejection port, brass rivets, sticker.
	k.box(r, -0.065, 0.093, Vector3(0.05, 0.01, 0.018), k.dark)
	k.rivet(r, 0.0, 0.085, 0.029, 0.009, k.dark)
	k.box(r, 0.08, 0.075, Vector3(0.004, 0.022, 0.07), k.dark, 0.025)
	for f: float in [-0.04, 0.03, 0.12, 0.18]:
		k.rivet(r, f, 0.03, 0.027, 0.0055, k.brass)
		k.rivet(r, f, 0.03, -0.027, 0.0055, k.brass)
	Craft.part(r, Craft.cutout(Craft.star_points(0.02, 0.009), 0.002), k.team, Vector3(0.023, 0.06, 0.24), Vector3(0, PI * 0.5, 0.2), Vector3.ONE, k.shadows)
	# Curved magazine.
	k.prof(mag, [Vector2(0.075, -0.038), Vector2(0.15, -0.038), Vector2(0.165, -0.12), Vector2(0.18, -0.18), Vector2(0.105, -0.19), Vector2(0.092, -0.12)], 0.034, k.dark)
	k.box(mag, 0.142, -0.188, Vector3(0.04, 0.012, 0.085), k.trim, 0.0, Vector3(-0.2, 0, 0))
	k.wrap(mag, 0.13, -0.1, Vector2(0.034, 0.075))
	# Optic: tube red dot on the flat-top rail.
	return k.red_dot(r, 0.07, 0.106)


# ------------------------------------------------------------------ AK-47

static func _ak(r: Node3D, mag: Node3D, k: Kit) -> float:
	k.prof(r, [Vector2(-0.06, 0.0), Vector2(0.25, 0.0), Vector2(0.25, 0.066), Vector2(-0.02, 0.066), Vector2(-0.06, 0.052)], 0.05, k.body, k.body_core)
	k.prof(r, [Vector2(-0.06, 0.066), Vector2(0.18, 0.066), Vector2(0.17, 0.082), Vector2(-0.04, 0.082)], 0.044, k.body)
	k.prof(r, [Vector2(-0.06, 0.056), Vector2(-0.06, 0.008), Vector2(-0.2, -0.03), Vector2(-0.34, -0.058), Vector2(-0.35, 0.02), Vector2(-0.2, 0.046)], 0.044, k.trim, k.trim_core)
	k.box(r, -0.345, -0.018, Vector3(0.046, 0.08, 0.014), k.dark, 0.0, Vector3(0.2, 0, 0))
	k.prof(r, [Vector2(-0.0, 0.004), Vector2(0.045, 0.004), Vector2(0.022, -0.1), Vector2(-0.028, -0.094)], 0.036, k.trim, k.trim_core)
	k.box(r, 0.07, -0.03, Vector3(0.012, 0.006, 0.075), k.dark)
	k.prof(r, [Vector2(0.25, 0.008), Vector2(0.45, 0.012), Vector2(0.45, 0.064), Vector2(0.25, 0.066)], 0.056, k.trim, k.trim_core)
	k.prof(r, [Vector2(0.27, 0.07), Vector2(0.43, 0.07), Vector2(0.42, 0.095), Vector2(0.28, 0.095)], 0.046, k.trim, k.trim_core)
	k.tube(r, 0.24, 0.5, 0.083, 0.011, k.body)
	k.tube(r, 0.45, 0.7, 0.05, 0.011, k.foil)
	k.prof(r, [Vector2(0.64, 0.04), Vector2(0.67, 0.04), Vector2(0.665, 0.105), Vector2(0.645, 0.105)], 0.026, k.dark)
	k.box(r, 0.655, 0.115, Vector3(0.004, 0.02, 0.004), k.dark)
	k.tube(r, 0.69, 0.74, 0.05, 0.016, k.dark)
	k.box(r, 0.2, 0.09, Vector3(0.03, 0.014, 0.04), k.dark)
	for side: float in [-1.0, 1.0]:
		k.box(r, 0.2, 0.108, Vector3(0.006, 0.022, 0.012), k.dark, side * 0.006)
	k.box(r, 0.04, 0.04, Vector3(0.006, 0.01, 0.06), k.foil, 0.027)
	for f: float in [0.0, 0.1, 0.2]:
		k.rivet(r, f, 0.03, 0.027, 0.0055, k.brass)
		k.rivet(r, f, 0.03, -0.027, 0.0055, k.brass)
	k.wrap(r, 0.4, 0.04, Vector2(0.056, 0.058))
	k.prof(mag, [Vector2(0.1, 0.0), Vector2(0.175, 0.0), Vector2(0.2, -0.1), Vector2(0.235, -0.19), Vector2(0.16, -0.215), Vector2(0.13, -0.12), Vector2(0.108, -0.045)], 0.034, k.trim, k.trim_core)
	k.wrap(mag, 0.16, -0.09, Vector2(0.034, 0.06))
	return 0.112


# -------------------------------------------------------------------- SMG

static func _smg(r: Node3D, mag: Node3D, k: Kit) -> float:
	k.prof(r, [Vector2(-0.06, 0.0), Vector2(0.27, 0.0), Vector2(0.3, 0.03), Vector2(0.3, 0.085), Vector2(-0.06, 0.085)], 0.052, k.body, k.body_core)
	k.rail(r, -0.04, 0.24, 0.087, 0.026)
	k.tube(r, 0.3, 0.46, 0.06, 0.013, k.foil)
	k.tube(r, 0.4, 0.46, 0.06, 0.018, k.dark)
	# Folding wire stock made of pipe cleaners.
	for side: float in [-1.0, 1.0]:
		k.box(r, -0.17, 0.05, Vector3(0.008, 0.008, 0.22), k.dark, side * 0.02)
	k.box(r, -0.28, 0.035, Vector3(0.05, 0.07, 0.014), k.dark)
	k.prof(r, [Vector2(-0.0, 0.004), Vector2(0.045, 0.004), Vector2(0.022, -0.1), Vector2(-0.028, -0.094)], 0.036, k.trim, k.trim_core)
	k.box(r, 0.07, -0.03, Vector3(0.012, 0.006, 0.07), k.dark)
	# Felt vertical foregrip.
	var fg := Craft.outlined(Craft.mat(Craft.Kind.FELT, Color(0.22, 0.24, 0.28), Craft.Pattern.STITCH, Craft.CREAM, 0.4, 0.0, false, k.vm), k.ow, k.vm)
	Craft.part(r, Craft.capsule(0.018, 0.09), fg, Vector3(0, -0.035, -0.27), Vector3(0.15, 0, 0), Vector3.ONE, k.shadows)
	k.rail(r, 0.22, 0.3, -0.002, 0.022)
	for f: float in [0.02, 0.12, 0.22]:
		k.rivet(r, f, 0.045, 0.028, 0.0055, k.brass)
		k.rivet(r, f, 0.045, -0.028, 0.0055, k.brass)
	Craft.part(r, Craft.cutout(Craft.star_points(0.018, 0.008), 0.002), k.team, Vector3(0.0275, 0.05, -0.18), Vector3(0, PI * 0.5, 0.2), Vector3.ONE, k.shadows)
	k.prof(mag, [Vector2(0.1, 0.0), Vector2(0.15, 0.0), Vector2(0.155, -0.17), Vector2(0.105, -0.17)], 0.03, k.dark)
	k.wrap(mag, 0.128, -0.08, Vector2(0.03, 0.05))
	return k.holo(r, 0.07, 0.093)


# ----------------------------------------------------------------- sniper

static func _sniper(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Thumbhole stock cut from one big profile.
	k.prof(r, [Vector2(-0.38, -0.05), Vector2(-0.12, -0.02), Vector2(-0.04, -0.1), Vector2(0.03, -0.1), Vector2(0.05, 0.0), Vector2(0.5, 0.0), Vector2(0.5, 0.05), Vector2(-0.1, 0.06), Vector2(-0.38, 0.07)], 0.05, k.trim, k.trim_core)
	k.box(r, -0.385, 0.01, Vector3(0.052, 0.12, 0.016), k.dark)
	k.prof(r, [Vector2(-0.06, 0.05), Vector2(0.22, 0.05), Vector2(0.22, 0.09), Vector2(-0.06, 0.09)], 0.04, k.body, k.body_core)
	k.tube(r, 0.22, 1.0, 0.07, 0.013, k.foil)
	k.tube(r, 0.93, 1.02, 0.07, 0.019, k.dark)
	# Bolt with a bottle-cap knob.
	k.box(r, 0.04, 0.075, Vector3(0.06, 0.008, 0.008), k.foil, 0.04)
	Craft.part(r, Craft.sphere(0.012, 10), k.brass, Vector3(0.072, 0.075, -0.04), Vector3.ZERO, Vector3.ONE, k.shadows)
	# Big paper-tube scope with lens caps and turrets.
	k.box(r, 0.0, 0.1, Vector3(0.02, 0.02, 0.025), k.dark)
	k.box(r, 0.17, 0.1, Vector3(0.02, 0.02, 0.025), k.dark)
	k.tube(r, -0.06, 0.26, 0.13, 0.022, k.body)
	k.tube(r, 0.2, 0.3, 0.13, 0.03, k.body)
	k.tube(r, -0.1, -0.04, 0.13, 0.027, k.body)
	k.rivet(r, 0.09, 0.13, 0.028, 0.012, k.brass)
	Craft.part(r, Craft.cylinder(0.012, 0.012, 0.016, 10), k.brass, Vector3(0, 0.158, -0.09), Vector3.ZERO, Vector3.ONE, k.shadows)
	Craft.part(r, Craft.cylinder(0.028, 0.028, 0.004, 18), Craft.cellophane(Color(0.4, 0.7, 1.0, 0.5)), Vector3(0, 0.13, -0.301), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
	# Folded bipod.
	for side: float in [-1.0, 1.0]:
		k.box(r, 0.6, -0.01, Vector3(0.008, 0.008, 0.2), k.dark, side * 0.012, Vector3(0.08, 0, 0))
	k.wrap(r, 0.35, 0.025, Vector2(0.05, 0.05))
	for f: float in [0.0, 0.12]:
		k.rivet(r, f, 0.07, 0.022, 0.0055, k.brass)
	k.prof(mag, [Vector2(0.06, 0.0), Vector2(0.14, 0.0), Vector2(0.14, -0.05), Vector2(0.06, -0.05)], 0.034, k.dark)
	return 0.13


# ---------------------------------------------------------------- shotgun

static func _shotgun(r: Node3D, pump: Node3D, k: Kit) -> float:
	k.prof(r, [Vector2(-0.05, 0.0), Vector2(0.22, 0.0), Vector2(0.22, 0.075), Vector2(-0.05, 0.075)], 0.052, k.body, k.body_core)
	k.prof(r, [Vector2(-0.05, 0.07), Vector2(-0.05, 0.005), Vector2(-0.18, -0.03), Vector2(-0.36, -0.06), Vector2(-0.37, 0.04), Vector2(-0.18, 0.06)], 0.046, k.trim, k.trim_core)
	k.box(r, -0.37, -0.01, Vector3(0.048, 0.1, 0.016), k.dark, 0.0, Vector3(0.2, 0, 0))
	k.prof(r, [Vector2(-0.0, 0.004), Vector2(0.045, 0.004), Vector2(0.022, -0.1), Vector2(-0.028, -0.094)], 0.036, k.trim, k.trim_core)
	k.box(r, 0.07, -0.03, Vector3(0.012, 0.006, 0.075), k.dark)
	k.tube(r, 0.22, 0.79, 0.068, 0.016, k.foil)
	k.tube(r, 0.22, 0.7, 0.03, 0.014, k.dark)
	k.box(r, 0.74, 0.05, Vector3(0.012, 0.05, 0.02), k.dark)
	Craft.part(r, Craft.sphere(0.005, 8), k.brass, Vector3(0, 0.088, -0.77), Vector3.ZERO, Vector3.ONE, k.shadows)
	for i in 4:
		Craft.part(r, Craft.cylinder(0.008, 0.008, 0.03, 8), Craft.mat(Craft.Kind.PLASTIC, Craft.RED, 0, Color.WHITE, 1.0, 0.0, false, k.vm), Vector3(0.03, 0.03, -(0.04 + i * 0.03)), Vector3(PI * 0.5, 0, 0), Vector3.ONE, k.shadows)
	var felt := Craft.outlined(Craft.mat(Craft.Kind.FELT, Color(0.55, 0.32, 0.2), Craft.Pattern.STITCH, Craft.CREAM, 0.3, 0.0, false, k.vm), k.ow, k.vm)
	k.prof(pump, [Vector2(0.32, 0.005), Vector2(0.5, 0.005), Vector2(0.5, 0.06), Vector2(0.32, 0.06)], 0.05, felt)
	for f: float in [0.35, 0.38, 0.41, 0.44, 0.47]:
		k.box(pump, f, 0.032, Vector3(0.054, 0.05, 0.006), Craft.mat(Craft.Kind.FELT, Color(0.4, 0.22, 0.14), 0, Color.WHITE, 1.0, 0.0, false, k.vm))
	return 0.088


# ----------------------------------------------------------------- pistol

static func _pistol(r: Node3D, mag: Node3D, k: Kit) -> float:
	k.prof(r, [Vector2(-0.04, 0.045), Vector2(0.19, 0.045), Vector2(0.19, 0.082), Vector2(-0.03, 0.082), Vector2(-0.04, 0.072)], 0.032, k.foil)
	for i in 5:
		k.box(r, -0.025 + i * 0.008, 0.064, Vector3(0.034, 0.03, 0.003), k.dark)
	k.prof(r, [Vector2(-0.03, 0.0), Vector2(0.17, 0.0), Vector2(0.17, 0.045), Vector2(-0.03, 0.045)], 0.03, k.body, k.body_core)
	k.prof(r, [Vector2(-0.03, 0.004), Vector2(0.03, 0.004), Vector2(0.008, -0.1), Vector2(-0.045, -0.094)], 0.034, k.body, k.body_core)
	for side: float in [-1.0, 1.0]:
		k.prof(r, [Vector2(-0.024, -0.01), Vector2(0.022, -0.01), Vector2(0.005, -0.085), Vector2(-0.038, -0.08)], 0.004, k.trim, null, side * 0.018)
	k.box(r, 0.05, -0.018, Vector3(0.01, 0.006, 0.06), k.body)
	k.box(r, 0.04, -0.008, Vector3(0.005, 0.022, 0.006), k.dark, 0.0, Vector3(-0.3, 0, 0))
	k.box(r, -0.035, 0.07, Vector3(0.012, 0.022, 0.014), k.dark, 0.0, Vector3(0.4, 0, 0))
	k.box(r, 0.17, 0.088, Vector3(0.006, 0.012, 0.008), k.dark)
	Craft.part(r, Craft.sphere(0.0035, 8), k.brass, Vector3(0, 0.095, -0.17), Vector3.ZERO, Vector3.ONE, k.shadows)
	for side: float in [-1.0, 1.0]:
		k.box(r, -0.02, 0.09, Vector3(0.006, 0.014, 0.008), k.dark, side * 0.008)
	k.box(mag, -0.018, -0.1, Vector3(0.03, 0.012, 0.05), k.dark, 0.0, Vector3(-0.22, 0, 0))
	return 0.093


# --------------------------------------------------------------- extras

static func knife(viewmodel: bool) -> Node3D:
	var root := Node3D.new()
	var ow := 0.0035 if viewmodel else 0.012
	var blade := Craft.outlined(Craft.mat(Craft.Kind.FOIL, Color(0.86, 0.88, 0.92), 0, Color.WHITE, 1.0, 0.0, true, viewmodel), ow, viewmodel)
	var grip := Craft.outlined(Craft.mat(Craft.Kind.TAPE, Color(0.2, 0.2, 0.22), 0, Color.WHITE, 1.0, 0.0, true, viewmodel), ow, viewmodel)
	Craft.box(root, Vector3(0, 0, 0.04), Vector3(0.03, 0.03, 0.11), grip, Vector3.ZERO, not viewmodel)
	var pts := PackedVector2Array([Vector2(-0.016, 0), Vector2(0.016, 0), Vector2(0.012, 0.15), Vector2(-0.016, 0.19)])
	Craft.part(root, Craft.cutout(pts, 0.006), blade, Vector3(0, 0, -0.01), Vector3(-PI * 0.5, 0, 0), Vector3.ONE, not viewmodel)
	return root


static func frag(viewmodel: bool) -> Node3D:
	var root := Node3D.new()
	var ow := 0.0035 if viewmodel else 0.01
	var body := Craft.outlined(Craft.mat(Craft.Kind.KNIT, Color(0.36, 0.5, 0.3), 0, Color.WHITE, 3.0, 0.0, false, viewmodel), ow, viewmodel)
	Craft.part(root, Craft.sphere(0.045, 12), body, Vector3.ZERO, Vector3.ZERO, Vector3(1, 1.15, 1), not viewmodel)
	Craft.part(root, Craft.cylinder(0.016, 0.02, 0.03, 8), Craft.mat(Craft.Kind.FOIL, Color(0.8, 0.8, 0.82), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), Vector3(0, 0.06, 0))
	Craft.part(root, Craft.cylinder(0.012, 0.012, 0.004, 10), Craft.mat(Craft.Kind.PLASTIC, Craft.RED, 0, Color.WHITE, 1.0, 0.0, false, viewmodel), Vector3(0.022, 0.07, 0), Vector3(0, 0, PI * 0.5))
	return root
