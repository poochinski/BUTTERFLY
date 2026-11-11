class_name GunBuilder
extends RefCounted
## Builds the guns as prop-maker replicas: the kind of painted cardboard
## props a skilled hobbyist would build for a film. Each major part is cut
## from a true side profile and laminated (painted card skins over a kraft
## core that shows at the cut edges). Finishes are real-world (matte black,
## flat dark earth, OD green, wood-grained card), weathered with rubbed paint
## and dry-brushed edges. Detail parts come from the craft drawer: foil
## barrels, brads for pins, webbing slings, cellophane lenses, cloth tape.
## The barrel points along -Z; the origin is the firing hand.
##
## Metadata on the root:
##   "sight"  : Vector3 the eye lines up with when aiming down sights
##   "muzzle" : Node3D at the barrel tip
##   "eject"  : Node3D at the ejection port (brass flies out to +X)
##   "mag"    : Node3D magazine (animated during reloads)
##   "pump"   : Node3D fore-end (shotgun), only when present
##   "slide"  : Node3D pistol slide, only when present
##   "bolt"   : Node3D sniper bolt (pivots on the barrel axis), when present
##   "charge" : Node3D charging handle pulled on empty reloads, when present
##   "left"   : Vector3 where the support hand holds

const CORE := Color(0.8, 0.62, 0.42)
static var _paints := {}


## A painted material with the replica weathering switched on. Cached, so
## every M4 in the match shares one material.
static func painted(kind: int, col: Color, dry: float, vm: bool, pattern := 0, col2 := Color.WHITE, pscale := 1.0) -> ShaderMaterial:
	var key := "%d|%s|%.2f|%s|%d|%s|%.2f" % [kind, col.to_html(), dry, vm, pattern, col2.to_html(), pscale]
	if _paints.has(key):
		return _paints[key]
	var m := Craft.mat(kind, col, pattern, col2, pscale, 0.35, vm, vm).duplicate() as ShaderMaterial
	m.set_shader_parameter("dry_brush", dry)
	_paints[key] = m
	return m


class Kit:
	## Materials and helpers for one gun, so parts can be terse.
	var vm: bool
	var att := ""
	var ow: float
	var shadows: bool
	var paint: Material
	var paint_core: Material
	var furn: Material
	var furn_core: Material
	var groove: Material
	var black: Material
	var rubber: Material
	var steel: Material
	var bright: Material
	var brass: Material
	var pin_m: Material
	var tape: Material
	var team: Material
	var web: Material
	var white: Material
	var glow_red: Material
	var glass: Material
	var lens: Material

	func _init(viewmodel: bool, w: Dictionary, team_c: Color) -> void:
		vm = viewmodel
		ow = 0.003 if viewmodel else 0.008
		shadows = not viewmodel
		var body_c: Color = w["body"]
		var furn_c: Color = w["trim"]
		paint = _o(GunBuilder.painted(Craft.Kind.PAPER, body_c, 0.8, vm))
		paint_core = Craft.mat(Craft.Kind.CARDBOARD, body_c.lerp(CORE, 0.4).darkened(0.2), 0, Color.WHITE, 1.0, 0.0, false, vm)
		if bool(w.get("wood", false)):
			# Wood furniture: kraft card stained and varnished, its fibres
			# reading as grain.
			furn = _o(Craft.mat(Craft.Kind.CARDBOARD, furn_c, 0, Color.WHITE, 1.0, 0.25, vm, vm))
			furn_core = Craft.mat(Craft.Kind.CARDBOARD, furn_c.lerp(CORE, 0.35), 0, Color.WHITE, 1.0, 0.0, false, vm)
		else:
			furn = _o(GunBuilder.painted(Craft.Kind.PAPER, furn_c, 0.6, vm))
			furn_core = Craft.mat(Craft.Kind.CARDBOARD, furn_c.lerp(CORE, 0.4).darkened(0.15), 0, Color.WHITE, 1.0, 0.0, false, vm)
		groove = Craft.mat(Craft.Kind.PAPER, furn_c.darkened(0.55), 0, Color.WHITE, 1.0, 0.0, false, vm)
		black = _o(GunBuilder.painted(Craft.Kind.PAPER, Color(0.12, 0.12, 0.13), 0.7, vm))
		rubber = Craft.mat(Craft.Kind.PAPER, Color(0.07, 0.07, 0.075), 0, Color.WHITE, 1.0, 0.0, false, vm)
		steel = _o(Craft.mat(Craft.Kind.FOIL, Color(0.4, 0.41, 0.43), 0, Color.WHITE, 1.0, 0.0, false, vm))
		bright = Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.71, 0.73), 0, Color.WHITE, 1.0, 0.0, false, vm)
		brass = Craft.mat(Craft.Kind.FOIL, Color(0.74, 0.57, 0.27), 0, Color.WHITE, 1.0, 0.0, false, vm)
		pin_m = Craft.mat(Craft.Kind.FOIL, Color(0.5, 0.51, 0.53), 0, Color.WHITE, 1.0, 0.0, false, vm)
		tape = Craft.mat(Craft.Kind.TAPE, Color(0.14, 0.14, 0.15), 0, Color.WHITE, 1.0, 0.0, false, vm)
		team = Craft.mat(Craft.Kind.TAPE, team_c, 0, Color.WHITE, 1.0, 0.0, false, vm)
		web = Craft.mat(Craft.Kind.FELT, Color(0.25, 0.26, 0.21), Craft.Pattern.STITCH, Color(0.18, 0.19, 0.15), 0.3, 0.0, false, vm)
		white = Craft.mat(Craft.Kind.PAPER, Color(0.86, 0.86, 0.8), 0, Color.WHITE, 1.0, 0.0, false, vm)
		glow_red = Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.12, 0.08), 0, Color.WHITE, 1.0, 0.0, false, vm)
		glass = Craft.cellophane(Color(0.62, 0.78, 0.82, 0.16))
		lens = Craft.cellophane(Color(0.42, 0.6, 0.52, 0.42))

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
			# Outer faces sit exactly at +-thick/2, so side details placed at
			# the part's half width sit on the surface.
			var inner := Craft.part(holder, Craft.cutout(poly, thick * 0.9), core, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, shadows)
			inner.scale = Vector3(0.995, 0.995, 1.0)
			Craft.part(holder, Craft.cutout(poly, thick * 0.2), skin, Vector3(0, 0, thick * 0.4), Vector3.ZERO, Vector3.ONE, shadows)
			Craft.part(holder, Craft.cutout(poly, thick * 0.2), skin, Vector3(0, 0, -thick * 0.4), Vector3.ZERO, Vector3.ONE, shadows)
		else:
			Craft.part(holder, Craft.cutout(poly, thick), skin, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, shadows)
		return holder

	func box(parent: Node3D, f: float, y: float, size: Vector3, m: Material, x := 0.0, rot := Vector3.ZERO) -> MeshInstance3D:
		return Craft.box(parent, Vector3(x, y, -f), size, m, rot, shadows)

	## A cylinder along the barrel axis from f0 to f1.
	func tube(parent: Node3D, f0: float, f1: float, y: float, r: float, m: Material, x := 0.0, segs := 14) -> MeshInstance3D:
		return Craft.part(parent, Craft.cylinder(r, r, f1 - f0, segs), m, Vector3(x, y, -(f0 + f1) * 0.5), Vector3(PI * 0.5, 0, 0), Vector3.ONE, shadows)

	## A tapered cylinder along the barrel: radius r0 at f0, r1 at f1.
	func cone(parent: Node3D, f0: float, f1: float, y: float, r0: float, r1: float, m: Material, x := 0.0, segs := 16) -> MeshInstance3D:
		return Craft.part(parent, Craft.cylinder(r0, r1, f1 - f0, segs), m, Vector3(x, y, -(f0 + f1) * 0.5), Vector3(PI * 0.5, 0, 0), Vector3.ONE, shadows)

	## A little disc (button, brad, sight dot) facing sideways (+X or -X).
	func rivet(parent: Node3D, f: float, y: float, x: float, r: float, m: Material) -> void:
		Craft.part(parent, Craft.cylinder(r, r, r * 0.7, 10), m, Vector3(x, y, -f), Vector3(0, 0, PI * 0.5), Vector3.ONE, shadows)

	## A pin through the receiver: a brad head on each side.
	func pin(parent: Node3D, f: float, y: float, half_w: float, r := 0.0045) -> void:
		rivet(parent, f, y, half_w, r, pin_m)
		rivet(parent, f, y, -half_w, r, pin_m)

	## Picatinny rail: a strip with notched teeth.
	func rail(parent: Node3D, f0: float, f1: float, y: float, width: float, x := 0.0, up := true) -> void:
		var len := f1 - f0
		if up:
			box(parent, (f0 + f1) * 0.5, y, Vector3(width, 0.008, len), black, x)
		else:
			box(parent, (f0 + f1) * 0.5, y, Vector3(0.008, width, len), black, x)
		var n := int(len / 0.012)
		for i in n:
			var f := f0 + (i + 0.5) * len / n
			if up:
				box(parent, f, y + 0.007, Vector3(width * 1.05, 0.006, 0.006), black, x)
			else:
				box(parent, f, y, Vector3(0.006, width * 1.05, 0.006), black, x + signf(x) * 0.007)

	## A row of recessed slots on both sides (vents, M-LOK cut-outs).
	func slots(parent: Node3D, f0: float, f1: float, y: float, n: int, size: Vector2, half_w: float) -> void:
		for i in n:
			var f := f0 + (i + 0.5) * (f1 - f0) / n
			for side: float in [-1.0, 1.0]:
				box(parent, f, y, Vector3(0.002, size.y, size.x), rubber, side * half_w)

	## Cloth tape wrapped around a part.
	func wrap(parent: Node3D, f: float, y: float, size: Vector2, m: Material = null, width := 0.018) -> void:
		box(parent, f, y, Vector3(size.x + 0.004, size.y + 0.004, width), m if m else tape)

	## A webbing sling hanging between two swivels. a and c are
	## (x, y, forward); it sags by `sag` and drifts to the side.
	func sling(parent: Node3D, a: Vector3, c: Vector3, sag: float, drift := -0.02) -> void:
		var pts := []
		var n := 10
		for i in n + 1:
			var t := float(i) / n
			var p := a.lerp(c, t)
			var s := sin(t * PI)
			pts.append(Vector3(p.x + s * drift, p.y - s * sag, -p.z))
		for i in n:
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[i + 1]
			var d := p1 - p0
			var mi := MeshInstance3D.new()
			mi.mesh = Craft.unit_box()
			mi.material_override = web
			if not shadows:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mi)
			var up := Vector3.RIGHT if absf(d.normalized().dot(Vector3.UP)) > 0.9 else Vector3.UP
			mi.transform = Transform3D(Basis.looking_at(d, up) * Basis.from_scale(Vector3(0.004, 0.02, d.length() + 0.003)), (p0 + p1) * 0.5)
		for e: Vector3 in [a, c]:
			Craft.part(parent, Craft.torus_ring(0.011, 0.003), pin_m, Vector3(e.x, e.y + 0.006, -e.z), Vector3(0, 0, PI * 0.5), Vector3.ONE, shadows)

	## Tube-style red dot sight. Returns the sight centre height.
	func red_dot(parent: Node3D, f: float, base_y: float) -> float:
		var cy := base_y + 0.032
		# Cantilever mount with a throw lever.
		box(parent, f, base_y + 0.008, Vector3(0.03, 0.016, 0.05), black)
		box(parent, f, base_y + 0.018, Vector3(0.012, 0.012, 0.03), black)
		box(parent, f + 0.01, base_y + 0.008, Vector3(0.004, 0.01, 0.026), black, 0.019, Vector3(0, 0.25, 0))
		var hold := Node3D.new()
		hold.position = Vector3(0, cy, -f)
		hold.rotation.y = PI * 0.5
		parent.add_child(hold)
		Craft.part(hold, Craft.tube(0.021, 0.085, 18, false), black, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, shadows)
		Craft.part(hold, Craft.tube(0.0195, 0.085, 18, true), rubber, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
		for side: float in [-1.0, 1.0]:
			Craft.part(hold, Craft.tube(0.024, 0.012, 18, false), black, Vector3(side * 0.043, 0, 0), Vector3.ZERO, Vector3.ONE, shadows)
			Craft.part(hold, Craft.tube(0.0195, 0.012, 18, true), rubber, Vector3(side * 0.043, 0, 0), Vector3.ZERO, Vector3.ONE, false)
		# Brightness and windage turrets with their caps.
		Craft.part(parent, Craft.cylinder(0.009, 0.009, 0.012, 12), black, Vector3(0, cy + 0.026, -f), Vector3.ZERO, Vector3.ONE, shadows)
		Craft.part(parent, Craft.cylinder(0.011, 0.011, 0.012, 12), black, Vector3(0.026, cy, -f), Vector3(0, 0, PI * 0.5), Vector3.ONE, shadows)
		var lens_d := Craft.part(parent, Craft.cylinder(0.0195, 0.0195, 0.002, 18), Craft.cellophane(Color(1.0, 0.62, 0.42, 0.16)), Vector3(0, cy, -(f + 0.04)), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
		lens_d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Craft.part(parent, Craft.sphere(0.0022, 8), glow_red, Vector3(0, cy, -(f + 0.035)), Vector3.ZERO, Vector3.ONE, false)
		return cy

	## Flip-up iron sights standing on the rail: a rear aperture and a
	## front post between protective ears. front_floor raises a stalk from
	## the barrel when the front sight sits out past the rail.
	func irons(parent: Node3D, f_rear: float, f_front: float, base_y: float, front_floor := -1.0) -> float:
		var cy := base_y + 0.032
		box(parent, f_rear, base_y + 0.012, Vector3(0.026, 0.024, 0.02), black)
		box(parent, f_rear, cy - 0.013, Vector3(0.02, 0.012, 0.01), black)
		Craft.part(parent, Craft.torus_ring(0.008, 0.003), black, Vector3(0, cy, -f_rear), Vector3(PI * 0.5, 0, 0), Vector3.ONE, shadows)
		if front_floor >= 0.0:
			box(parent, f_front, (front_floor + base_y) * 0.5, Vector3(0.016, base_y - front_floor, 0.02), black)
		box(parent, f_front, base_y + 0.012, Vector3(0.022, 0.024, 0.024), black)
		box(parent, f_front, cy - 0.004, Vector3(0.003, 0.018, 0.003), black)
		for side: float in [-1.0, 1.0]:
			box(parent, f_front, cy, Vector3(0.003, 0.022, 0.014), black, side * 0.01)
		return cy

	## A fixed 4x combat scope: squat body, flared objective bell, rubber
	## eyepiece, a glowing fibre strip on top and a red chevron reticle.
	func acog(parent: Node3D, f: float, base_y: float) -> float:
		var cy := base_y + 0.042
		box(parent, f, base_y + 0.01, Vector3(0.03, 0.02, 0.07), black)
		box(parent, f, cy - 0.024, Vector3(0.026, 0.016, 0.05), black)
		# Hollow tubes (open ends) so the sight picture shows through.
		var hold := Node3D.new()
		hold.position = Vector3(0, cy, -f)
		hold.rotation.y = PI * 0.5
		parent.add_child(hold)
		Craft.part(hold, Craft.tube(0.02, 0.09, 18, false), black, Vector3(0.005, 0, 0), Vector3.ZERO, Vector3.ONE, shadows)
		Craft.part(hold, Craft.tube(0.0185, 0.09, 18, true), rubber, Vector3(0.005, 0, 0), Vector3.ZERO, Vector3.ONE, false)
		Craft.part(hold, Craft.tube(0.026, 0.035, 18, false), black, Vector3(0.065, 0, 0), Vector3.ZERO, Vector3.ONE, shadows)
		Craft.part(hold, Craft.tube(0.0245, 0.035, 18, true), rubber, Vector3(0.065, 0, 0), Vector3.ZERO, Vector3.ONE, false)
		Craft.part(hold, Craft.tube(0.023, 0.02, 18, false), rubber, Vector3(-0.05, 0, 0), Vector3.ZERO, Vector3.ONE, shadows)
		box(parent, f - 0.01, cy + 0.024, Vector3(0.012, 0.006, 0.05), glow_red)
		rivet(parent, f - 0.015, cy, 0.022, 0.008, black)
		Craft.part(parent, Craft.cylinder(0.008, 0.008, 0.01, 10), black, Vector3(0, cy + 0.024, -(f + 0.005)), Vector3.ZERO, Vector3.ONE, shadows)
		var chev := PackedVector2Array([Vector2(-0.0035, -0.0025), Vector2(0, 0.0015), Vector2(0.0035, -0.0025), Vector2(0.0035, -0.0038), Vector2(0, 0.0002), Vector2(-0.0035, -0.0038)])
		Craft.part(parent, Craft.cutout(chev, 0.0005), glow_red, Vector3(0, cy, -(f + 0.02)), Vector3.ZERO, Vector3.ONE, false)
		Craft.part(parent, Craft.unit_box(), black, Vector3(0, cy - 0.011, -(f + 0.02)), Vector3.ZERO, Vector3(0.0012, 0.014, 0.0012), false)
		var l := Craft.part(parent, Craft.cylinder(0.024, 0.024, 0.002, 18), lens, Vector3(0, cy, -(f + 0.08)), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return cy

	## A vertical foregrip clamped under the handguard.
	func vgrip(parent: Node3D, f: float, y: float) -> void:
		box(parent, f, y - 0.005, Vector3(0.03, 0.012, 0.05), black)
		prof(parent, [Vector2(f - 0.02, y - 0.008), Vector2(f + 0.02, y - 0.008), Vector2(f + 0.016, y - 0.095), Vector2(f - 0.017, y - 0.098)], 0.03, black)

	## Box-style holographic sight with a ring-and-dot reticle.
	func holo(parent: Node3D, f: float, base_y: float) -> float:
		var cy := base_y + 0.03
		box(parent, f, base_y + 0.006, Vector3(0.036, 0.012, 0.075), black)
		box(parent, f + 0.02, base_y + 0.014, Vector3(0.03, 0.01, 0.03), black)
		# Battery cap and buttons on the base.
		Craft.part(parent, Craft.cylinder(0.008, 0.008, 0.01, 10), black, Vector3(0.021, base_y + 0.008, -(f - 0.02)), Vector3(0, 0, PI * 0.5), Vector3.ONE, shadows)
		for i in 2:
			box(parent, f - 0.03 + i * 0.012, base_y + 0.014, Vector3(0.008, 0.004, 0.006), rubber)
		# The window hood.
		for side: float in [-1.0, 1.0]:
			box(parent, f, cy, Vector3(0.005, 0.044, 0.07), black, side * 0.02)
		box(parent, f, cy + 0.024, Vector3(0.045, 0.006, 0.07), black)
		var gl := box(parent, f + 0.03, cy, Vector3(0.036, 0.04, 0.002), glass)
		gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Ring-and-dot reticle made of tiny glowing beads.
		for i in 20:
			var a := TAU * i / 20.0
			Craft.part(parent, Craft.sphere(0.0011, 6), glow_red, Vector3(cos(a) * 0.0085, cy + sin(a) * 0.0085, -(f + 0.028)), Vector3.ZERO, Vector3.ONE, false)
		Craft.part(parent, Craft.sphere(0.0016, 8), glow_red, Vector3(0, cy, -(f + 0.028)), Vector3.ZERO, Vector3.ONE, false)
		return cy


static func build(id: String, viewmodel: bool, team_color := Color(0.2, 0.28, 0.44), att := "") -> Node3D:
	var w := WeaponDB.get_data(id)
	var root := Node3D.new()
	root.name = "Gun_" + id
	var k := Kit.new(viewmodel, w, team_color)
	k.att = att
	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	root.add_child(muzzle)
	var eject := Node3D.new()
	eject.name = "Eject"
	root.add_child(eject)
	var mag := Node3D.new()
	mag.name = "Mag"
	root.add_child(mag)
	var sight_y := 0.1
	var left := Vector3(0, 0.0, -0.33)
	match String(w["model"]):
		"rifle":
			sight_y = _m4(root, mag, k)
			muzzle.position = Vector3(0, 0.072, -0.73)
			eject.position = Vector3(0.026, 0.074, -0.06)
			left = Vector3(0, 0.035, -0.34)
		"ak":
			sight_y = _ak(root, mag, k)
			muzzle.position = Vector3(0, 0.05, -0.74)
			eject.position = Vector3(0.026, 0.068, -0.1)
			left = Vector3(0, 0.03, -0.34)
		"smg":
			sight_y = _smg(root, mag, k)
			muzzle.position = Vector3(0, 0.06, -0.46)
			eject.position = Vector3(0.028, 0.06, -0.08)
			left = Vector3(0, -0.035, -0.27)
		"sniper":
			sight_y = _sniper(root, mag, k)
			muzzle.position = Vector3(0, 0.07, -1.03)
			eject.position = Vector3(0.024, 0.08, -0.06)
			left = Vector3(0, 0.03, -0.4)
		"shotgun":
			var pump := Node3D.new()
			pump.name = "Pump"
			root.add_child(pump)
			sight_y = _shotgun(root, pump, k)
			root.set_meta("pump", pump)
			muzzle.position = Vector3(0, 0.068, -0.8)
			eject.position = Vector3(0.028, 0.05, -0.1)
			left = Vector3(0, 0.02, -0.42)
		"pistol":
			sight_y = _pistol(root, mag, k)
			muzzle.position = Vector3(0, 0.068, -0.195)
			eject.position = Vector3(0.012, 0.085, -0.07)
			left = Vector3(-0.025, -0.045, 0.0)
		"lmg":
			sight_y = _lmg(root, mag, k)
			muzzle.position = Vector3(0, 0.06, -0.83)
			eject.position = Vector3(0.03, 0.05, -0.08)
			left = Vector3(0, 0.02, -0.36)
		"dmr":
			sight_y = _dmr(root, mag, k)
			muzzle.position = Vector3(0, 0.055, -0.91)
			eject.position = Vector3(0.027, 0.07, -0.1)
			left = Vector3(0, 0.02, -0.4)
		"revolver":
			sight_y = _revolver(root, mag, k)
			muzzle.position = Vector3(0, 0.068, -0.255)
			eject.position = Vector3(0.0, 0.06, -0.05)
			left = Vector3(-0.025, -0.045, 0.0)
	# Attachments that hang off the gun rather than replacing a sight.
	var model := String(w["model"])
	if att == "suppressor":
		var r := 0.016 if model == "pistol" else (0.026 if model == "sniper" else 0.022)
		var ln := 0.12 if model == "pistol" else 0.18
		var f0 := -muzzle.position.z - 0.01
		k.tube(root, f0, f0 + ln, muzzle.position.y, r, k.black, 0.0, 16)
		for i in 3:
			k.tube(root, f0 + 0.02 + i * ln * 0.3, f0 + 0.03 + i * ln * 0.3, muzzle.position.y, r + 0.001, k.rubber, 0.0, 16)
		muzzle.position.z -= ln
	if att == "grip":
		var gf := {"rifle": [0.34, 0.038], "ak": [0.36, 0.008], "lmg": [0.36, 0.022], "dmr": [0.4, 0.02], "shotgun": [0.41, 0.008]}
		if gf.has(model):
			var g: Array = gf[model]
			var parent: Node3D = root.get_meta("pump") if model == "shotgun" else root
			k.vgrip(parent, float(g[0]), float(g[1]))
			left = Vector3(0, float(g[1]) - 0.05, -float(g[0]))
	if att == "extmag" and model != "shotgun" and model != "revolver":
		mag.scale = Vector3(1.0, 1.35 if model != "sniper" else 1.7, 1.0)
	root.set_meta("muzzle", muzzle)
	root.set_meta("eject", eject)
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
		"shotgun", "ak", "lmg":
			ads_z = -0.26
		"dmr":
			ads_z = -0.25
		"revolver":
			ads_z = -0.32
	root.set_meta("ads_z", ads_z)
	if not viewmodel:
		_bake(root)
		Craft.make_moving(root)
	return root


## Third-person guns never animate their parts, so merge every piece that
## shares a material into one mesh: a dozen soldiers' guns stay cheap.
## direct_only merges just the node's own mesh children (one doll limb).
static func _bake(root: Node3D, direct_only := false) -> void:
	var groups := {}
	var order := []
	var found: Array[MeshInstance3D] = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == root or not direct_only:
			for c in n.get_children():
				stack.append(c)
		if n is MeshInstance3D and n != root:
			var shadow_off := (n as MeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not shadow_off:
				found.append(n)
	var xfs := {}
	for mi in found:
		xfs[mi] = _rel(root, mi)
	for mi in found:
		var mat := mi.material_override
		if mat == null or mi.mesh == null:
			continue
		if not groups.has(mat):
			groups[mat] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
			order.append(mat)
		var g: Array = groups[mat]
		var xf: Transform3D = xfs[mi]
		var nb := xf.basis.inverse().transposed()
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms = arr[Mesh.ARRAY_NORMAL]
			var uvs = arr[Mesh.ARRAY_TEX_UV]
			var idx = arr[Mesh.ARRAY_INDEX]
			var base: int = (g[0] as PackedVector3Array).size()
			var gv: PackedVector3Array = g[0]
			var gn: PackedVector3Array = g[1]
			var gu: PackedVector2Array = g[2]
			var gi: PackedInt32Array = g[3]
			for vi in verts.size():
				gv.append(xf * verts[vi])
				gn.append((nb * (norms[vi] if norms != null and vi < norms.size() else Vector3.UP)).normalized())
				gu.append(uvs[vi] if uvs != null and vi < uvs.size() else Vector2.ZERO)
			if idx != null and (idx as PackedInt32Array).size() > 0:
				for ii in (idx as PackedInt32Array):
					gi.append(base + ii)
			else:
				for vi in verts.size():
					gi.append(base + vi)
			g[0] = gv
			g[1] = gn
			g[2] = gu
			g[3] = gi
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	for mat in order:
		var g: Array = groups[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = g[0]
		arrays[Mesh.ARRAY_NORMAL] = g[1]
		arrays[Mesh.ARRAY_TEX_UV] = g[2]
		arrays[Mesh.ARRAY_INDEX] = g[3]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var out := MeshInstance3D.new()
		out.mesh = am
		out.material_override = mat
		root.add_child(out)


static func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != root and cur is Node3D:
		xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


# ------------------------------------------------------------------- M4A1

static func _m4(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Lower receiver, flared magwell and the upper with its flat top.
	k.prof(r, [Vector2(-0.07, 0.0), Vector2(0.2, 0.0), Vector2(0.205, 0.02), Vector2(0.2, 0.052), Vector2(-0.07, 0.052)], 0.05, k.paint, k.paint_core)
	k.prof(r, [Vector2(0.064, 0.004), Vector2(0.16, 0.004), Vector2(0.156, -0.04), Vector2(0.068, -0.04)], 0.048, k.paint, k.paint_core)
	k.box(r, 0.112, -0.04, Vector3(0.056, 0.008, 0.1), k.paint)
	k.prof(r, [Vector2(-0.075, 0.052), Vector2(0.215, 0.052), Vector2(0.215, 0.096), Vector2(-0.06, 0.096), Vector2(-0.075, 0.084)], 0.046, k.paint, k.paint_core)
	# Ejection port with the dust cover hanging open, brass deflector,
	# forward assist, bolt catch, mag release and the selector.
	k.box(r, 0.06, 0.074, Vector3(0.003, 0.018, 0.058), k.rubber, 0.0235)
	k.box(r, 0.06, 0.06, Vector3(0.002, 0.01, 0.062), k.paint, 0.027, Vector3(0.0, 0.0, -0.5))
	k.box(r, 0.0, 0.086, Vector3(0.008, 0.014, 0.016), k.paint, 0.026)
	k.tube(r, -0.045, -0.005, 0.078, 0.009, k.paint, 0.027)
	k.rivet(r, -0.045, 0.078, 0.027, 0.007, k.black)
	k.box(r, 0.05, 0.042, Vector3(0.003, 0.02, 0.012), k.black, -0.026)
	k.rivet(r, 0.07, 0.03, 0.026, 0.0055, k.black)
	k.box(r, -0.005, 0.034, Vector3(0.003, 0.008, 0.026), k.black, -0.026, Vector3(0.4, 0, 0))
	k.rivet(r, -0.02, 0.026, -0.026, 0.0025, k.white)
	# Takedown and pivot pins.
	k.pin(r, -0.058, 0.044, 0.026)
	k.pin(r, 0.19, 0.044, 0.026)
	k.pin(r, 0.03, 0.03, 0.026, 0.0035)
	# Charging handle (pulled on empty reloads).
	var charge := Craft.pivot(r, Vector3.ZERO)
	charge.name = "Charge"
	k.box(charge, -0.07, 0.09, Vector3(0.05, 0.008, 0.016), k.black)
	k.box(charge, -0.06, 0.09, Vector3(0.012, 0.007, 0.03), k.black)
	r.set_meta("charge", charge)
	# Buffer tube, castle nut, collapsible stock, butt pad, sling loop.
	k.tube(r, -0.33, -0.075, 0.068, 0.015, k.black)
	k.tube(r, -0.095, -0.075, 0.068, 0.019, k.black, 0.0, 10)
	k.prof(r, [Vector2(-0.13, 0.098), Vector2(-0.13, 0.03), Vector2(-0.2, 0.018), Vector2(-0.31, 0.004), Vector2(-0.325, 0.05), Vector2(-0.318, 0.1), Vector2(-0.2, 0.102)], 0.044, k.furn, k.furn_core)
	k.box(r, -0.328, 0.052, Vector3(0.046, 0.1, 0.012), k.rubber)
	k.box(r, -0.165, 0.022, Vector3(0.012, 0.008, 0.04), k.black)
	k.wrap(r, -0.25, 0.058, Vector2(0.044, 0.05), k.team, 0.014)
	# Pistol grip with a finger nub, trigger guard and trigger.
	k.prof(r, [Vector2(-0.005, 0.004), Vector2(0.045, 0.004), Vector2(0.036, -0.03), Vector2(0.03, -0.04), Vector2(0.02, -0.105), Vector2(-0.035, -0.098), Vector2(-0.018, -0.04)], 0.034, k.furn, k.furn_core)
	k.box(r, 0.052, -0.034, Vector3(0.012, 0.005, 0.034), k.paint)
	k.box(r, 0.068, -0.018, Vector3(0.012, 0.034, 0.005), k.paint)
	k.box(r, 0.048, -0.016, Vector3(0.005, 0.026, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	# Free-float handguard with M-LOK slots and a top rail.
	k.prof(r, [Vector2(0.215, 0.038), Vector2(0.47, 0.038), Vector2(0.48, 0.048), Vector2(0.48, 0.098), Vector2(0.47, 0.106), Vector2(0.215, 0.106)], 0.056, k.paint, k.paint_core)
	k.slots(r, 0.24, 0.46, 0.066, 6, Vector2(0.026, 0.009), 0.029)
	k.slots(r, 0.26, 0.44, 0.048, 4, Vector2(0.026, 0.009), 0.029)
	k.rail(r, -0.06, 0.212, 0.1, 0.024)
	k.rail(r, 0.22, 0.47, 0.11, 0.024)
	# Folded back-up sights.
	k.box(r, -0.035, 0.112, Vector3(0.024, 0.008, 0.022), k.black)
	k.prof(r, [Vector2(0.44, 0.116), Vector2(0.47, 0.116), Vector2(0.465, 0.126), Vector2(0.445, 0.126)], 0.022, k.black)
	# Barrel, gas block, birdcage flash hider.
	k.tube(r, 0.48, 0.66, 0.072, 0.0105, k.steel)
	k.box(r, 0.5, 0.074, Vector3(0.026, 0.026, 0.022), k.black)
	k.tube(r, 0.655, 0.73, 0.072, 0.0135, k.black)
	for f: float in [0.675, 0.695, 0.715]:
		k.box(r, f, 0.072, Vector3(0.029, 0.004, 0.007), k.rubber)
	# Webbing sling from the handguard to the stock.
	k.sling(r, Vector3(-0.026, 0.04, 0.44), Vector3(-0.024, 0.01, -0.3), 0.13)
	# Curved STANAG magazine with ribs, a baseplate and a pull tab.
	k.prof(mag, [Vector2(0.075, -0.036), Vector2(0.15, -0.036), Vector2(0.165, -0.12), Vector2(0.18, -0.18), Vector2(0.105, -0.19), Vector2(0.092, -0.12)], 0.032, k.black)
	for t: float in [0.25, 0.5, 0.75]:
		var c := Vector2(0.112, -0.036).lerp(Vector2(0.142, -0.185), t)
		k.box(mag, c.x, c.y, Vector3(0.035, 0.004, 0.05), k.black, 0.0, Vector3(-0.25, 0, 0))
	k.box(mag, 0.142, -0.19, Vector3(0.038, 0.012, 0.085), k.black, 0.0, Vector3(-0.2, 0, 0))
	k.box(mag, 0.11, -0.2, Vector3(0.016, 0.022, 0.006), k.web, 0.0, Vector3(-0.2, 0, 0))
	k.box(mag, 0.113, -0.034, Vector3(0.012, 0.008, 0.05), k.brass)
	# Optic on the flat-top rail, or flip-up irons.
	return _optic(r, k, 0.07, 0.106, -0.035, 0.455)


# ------------------------------------------------------------------ AK-47

static func _ak(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Stamped receiver and ribbed dust cover.
	k.prof(r, [Vector2(-0.06, 0.0), Vector2(0.25, 0.0), Vector2(0.25, 0.062), Vector2(-0.02, 0.062), Vector2(-0.06, 0.05)], 0.05, k.paint, k.paint_core)
	k.prof(r, [Vector2(-0.055, 0.062), Vector2(0.18, 0.062), Vector2(0.175, 0.08), Vector2(-0.035, 0.082), Vector2(-0.055, 0.072)], 0.044, k.paint)
	for f: float in [-0.03, -0.012, 0.006]:
		k.box(r, f, 0.081, Vector3(0.042, 0.004, 0.005), k.paint)
	k.box(r, -0.062, 0.067, Vector3(0.016, 0.01, 0.01), k.bright)
	# Rear sight block and tangent leaf.
	k.prof(r, [Vector2(0.18, 0.062), Vector2(0.25, 0.062), Vector2(0.25, 0.084), Vector2(0.19, 0.09)], 0.04, k.paint)
	k.box(r, 0.2, 0.094, Vector3(0.02, 0.005, 0.055), k.steel, 0.0, Vector3(0.06, 0, 0))
	k.box(r, 0.212, 0.09, Vector3(0.026, 0.008, 0.008), k.steel)
	# Rivets, trunnion pins, the long selector lever and charging handle.
	for f: float in [-0.04, 0.0, 0.2, 0.23]:
		k.pin(r, f, 0.012, 0.026, 0.0035)
	k.pin(r, 0.02, 0.045, 0.026, 0.004)
	k.box(r, 0.06, 0.054, Vector3(0.003, 0.012, 0.13), k.steel, 0.027, Vector3(0.05, 0, 0))
	k.box(r, 0.0, 0.044, Vector3(0.004, 0.018, 0.012), k.steel, 0.028)
	k.box(r, 0.1, 0.06, Vector3(0.002, 0.008, 0.11), k.rubber, 0.0255)
	var charge := Craft.pivot(r, Vector3.ZERO)
	charge.name = "Charge"
	k.box(charge, 0.14, 0.06, Vector3(0.022, 0.009, 0.012), k.bright, 0.035)
	r.set_meta("charge", charge)
	k.box(r, 0.165, -0.006, Vector3(0.012, 0.018, 0.006), k.steel)
	# Wooden stock with a steel buttplate.
	k.prof(r, [Vector2(-0.06, 0.056), Vector2(-0.06, 0.008), Vector2(-0.2, -0.028), Vector2(-0.345, -0.056), Vector2(-0.355, 0.022), Vector2(-0.2, 0.046)], 0.042, k.furn, k.furn_core)
	k.box(r, -0.352, -0.016, Vector3(0.044, 0.084, 0.006), k.steel, 0.0, Vector3(0.2, 0, 0))
	k.wrap(r, -0.27, -0.005, Vector2(0.042, 0.05), k.team, 0.014)
	# Pistol grip, trigger guard and trigger.
	k.prof(r, [Vector2(0.0, 0.004), Vector2(0.045, 0.004), Vector2(0.022, -0.1), Vector2(-0.028, -0.094)], 0.036, k.furn, k.furn_core)
	k.box(r, 0.075, -0.034, Vector3(0.012, 0.005, 0.07), k.steel)
	k.box(r, 0.11, -0.017, Vector3(0.012, 0.034, 0.005), k.steel)
	k.box(r, 0.065, -0.015, Vector3(0.005, 0.024, 0.006), k.steel, 0.0, Vector3(-0.3, 0, 0))
	# Wooden lower handguard with finger grooves and retainer bands.
	k.prof(r, [Vector2(0.25, 0.008), Vector2(0.42, 0.012), Vector2(0.43, 0.025), Vector2(0.43, 0.062), Vector2(0.25, 0.064)], 0.054, k.furn, k.furn_core)
	for y: float in [0.028, 0.044]:
		for side: float in [-1.0, 1.0]:
			k.box(r, 0.335, y, Vector3(0.002, 0.004, 0.12), k.groove, side * 0.0275)
	for f: float in [0.252, 0.43]:
		k.box(r, f, 0.038, Vector3(0.058, 0.064, 0.008), k.steel)
	# Gas tube with the upper handguard, gas block, barrel, cleaning rod.
	k.tube(r, 0.25, 0.52, 0.084, 0.012, k.paint)
	k.prof(r, [Vector2(0.27, 0.068), Vector2(0.42, 0.068), Vector2(0.41, 0.098), Vector2(0.28, 0.098)], 0.046, k.furn, k.furn_core)
	k.box(r, 0.52, 0.068, Vector3(0.026, 0.044, 0.026), k.paint)
	k.tube(r, 0.43, 0.69, 0.05, 0.0105, k.steel)
	k.tube(r, 0.43, 0.665, 0.032, 0.0035, k.bright)
	# Front sight post inside its open hood, and a slant brake.
	k.prof(r, [Vector2(0.635, 0.04), Vector2(0.665, 0.04), Vector2(0.66, 0.098), Vector2(0.64, 0.098)], 0.022, k.paint)
	k.box(r, 0.65, 0.104, Vector3(0.003, 0.016, 0.003), k.paint)
	for side: float in [-1.0, 1.0]:
		k.box(r, 0.65, 0.106, Vector3(0.003, 0.02, 0.012), k.paint, side * 0.009)
	k.tube(r, 0.685, 0.74, 0.05, 0.0135, k.paint)
	k.box(r, 0.735, 0.062, Vector3(0.03, 0.006, 0.02), k.rubber, 0.0, Vector3(0.5, 0, 0))
	# Canvas sling from the front sight base to the stock.
	k.sling(r, Vector3(-0.012, 0.03, 0.62), Vector3(-0.022, -0.03, -0.28), 0.15)
	# Steel magazine with stamped ribs.
	k.prof(mag, [Vector2(0.1, 0.0), Vector2(0.175, 0.0), Vector2(0.2, -0.1), Vector2(0.235, -0.19), Vector2(0.16, -0.215), Vector2(0.13, -0.12), Vector2(0.108, -0.045)], 0.034, k.paint)
	for t: float in [0.3, 0.55, 0.8]:
		var c := Vector2(0.14, -0.01).lerp(Vector2(0.198, -0.2), t)
		k.box(mag, c.x, c.y, Vector3(0.037, 0.004, 0.04), k.paint, 0.0, Vector3(-0.4, 0, 0))
	k.box(mag, 0.198, -0.208, Vector3(0.038, 0.01, 0.07), k.steel, 0.0, Vector3(-0.32, 0, 0))
	k.box(mag, 0.14, 0.002, Vector3(0.012, 0.008, 0.04), k.brass)
	if k.att in ["reddot", "holo", "acog"]:
		# A side-mount rail clamped to the receiver carries the optic.
		k.box(r, 0.07, 0.07, Vector3(0.008, 0.04, 0.09), k.black, -0.03)
		k.box(r, 0.07, 0.092, Vector3(0.05, 0.008, 0.09), k.black, -0.008)
		return _optic(r, k, 0.07, 0.096, 0, 0)
	return 0.112


# -------------------------------------------------------------------- SMG

static func _smg(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Polymer receiver with vents, ejection port and cocking slot.
	k.prof(r, [Vector2(-0.06, 0.0), Vector2(0.27, 0.0), Vector2(0.3, 0.03), Vector2(0.3, 0.085), Vector2(-0.06, 0.085)], 0.052, k.paint, k.paint_core)
	k.rail(r, -0.04, 0.24, 0.087, 0.026)
	k.slots(r, 0.18, 0.28, 0.04, 4, Vector2(0.018, 0.008), 0.027)
	k.box(r, 0.08, 0.062, Vector3(0.003, 0.018, 0.05), k.rubber, 0.0265)
	k.box(r, 0.25, 0.068, Vector3(0.002, 0.008, 0.09), k.rubber, -0.0265)
	var charge := Craft.pivot(r, Vector3.ZERO)
	charge.name = "Charge"
	k.box(charge, 0.28, 0.068, Vector3(0.024, 0.008, 0.012), k.black, -0.036, Vector3(0, 0.3, 0))
	r.set_meta("charge", charge)
	for f: float in [-0.04, 0.24]:
		k.pin(r, f, 0.02, 0.027)
	# Selector with painted safe/fire dots.
	k.box(r, 0.005, 0.03, Vector3(0.003, 0.008, 0.022), k.black, -0.027, Vector3(0.5, 0, 0))
	k.rivet(r, -0.01, 0.042, -0.027, 0.0025, k.white)
	k.rivet(r, 0.02, 0.042, -0.027, 0.0025, k.glow_red)
	# Barrel and a slotted muzzle device.
	k.tube(r, 0.3, 0.42, 0.06, 0.0105, k.steel)
	k.tube(r, 0.4, 0.46, 0.06, 0.017, k.black)
	for f: float in [0.415, 0.43, 0.445]:
		k.box(r, f, 0.06, Vector3(0.036, 0.005, 0.006), k.rubber)
	# Folding wire stock with a rubber butt pad.
	k.box(r, -0.065, 0.05, Vector3(0.05, 0.03, 0.02), k.black)
	for side: float in [-1.0, 1.0]:
		k.box(r, -0.17, 0.05, Vector3(0.008, 0.008, 0.22), k.steel, side * 0.02)
	k.box(r, -0.28, 0.035, Vector3(0.05, 0.07, 0.014), k.black)
	k.box(r, -0.29, 0.035, Vector3(0.05, 0.072, 0.006), k.rubber)
	# Pistol grip, trigger guard, trigger.
	k.prof(r, [Vector2(0.0, 0.004), Vector2(0.045, 0.004), Vector2(0.022, -0.1), Vector2(-0.028, -0.094)], 0.036, k.furn, k.furn_core)
	k.box(r, 0.075, -0.032, Vector3(0.012, 0.005, 0.06), k.black)
	k.box(r, 0.104, -0.016, Vector3(0.012, 0.032, 0.005), k.black)
	k.box(r, 0.065, -0.014, Vector3(0.005, 0.024, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	# Vertical foregrip on a short bottom rail, with team tape.
	k.rail(r, 0.22, 0.3, -0.002, 0.022)
	k.prof(r, [Vector2(0.25, -0.004), Vector2(0.29, -0.004), Vector2(0.285, -0.09), Vector2(0.255, -0.092)], 0.03, k.black)
	k.wrap(r, 0.27, -0.06, Vector2(0.03, 0.032), k.team, 0.014)
	# Sling.
	k.sling(r, Vector3(-0.028, 0.03, 0.2), Vector3(-0.028, 0.02, -0.27), 0.11)
	# Straight polymer magazine with ribs.
	k.prof(mag, [Vector2(0.1, 0.0), Vector2(0.15, 0.0), Vector2(0.158, -0.17), Vector2(0.104, -0.172)], 0.03, k.black)
	for y: float in [-0.06, -0.1, -0.14]:
		k.box(mag, 0.128, y, Vector3(0.033, 0.004, 0.05), k.black)
	k.box(mag, 0.131, -0.176, Vector3(0.036, 0.012, 0.06), k.black)
	k.box(mag, 0.124, 0.002, Vector3(0.011, 0.008, 0.035), k.brass)
	return _optic(r, k, 0.07, 0.093, -0.04, 0.24)


# ----------------------------------------------------------------- sniper

static func _sniper(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Thumbhole stock with a cheek riser and a thick recoil pad.
	k.prof(r, [Vector2(-0.38, -0.05), Vector2(-0.12, -0.02), Vector2(-0.04, -0.1), Vector2(0.03, -0.1), Vector2(0.05, 0.0), Vector2(0.5, 0.0), Vector2(0.5, 0.05), Vector2(-0.1, 0.06), Vector2(-0.38, 0.07)], 0.05, k.furn, k.furn_core)
	k.box(r, -0.08, -0.035, Vector3(0.052, 0.028, 0.045), k.rubber)
	k.prof(r, [Vector2(-0.3, 0.068), Vector2(-0.12, 0.062), Vector2(-0.12, 0.08), Vector2(-0.3, 0.086)], 0.04, k.furn, k.furn_core)
	k.box(r, -0.392, 0.01, Vector3(0.054, 0.124, 0.022), k.rubber)
	k.wrap(r, -0.22, 0.01, Vector2(0.05, 0.08), k.team, 0.014)
	# Round action, scope rail, bolt shroud.
	k.tube(r, -0.07, 0.22, 0.072, 0.022, k.paint)
	k.tube(r, -0.11, -0.07, 0.072, 0.017, k.paint)
	k.rail(r, -0.06, 0.2, 0.096, 0.022)
	k.box(r, 0.06, 0.08, Vector3(0.003, 0.016, 0.07), k.rubber, 0.023)
	# Bolt: body, handle and a tactical knob. Pivots on the barrel axis.
	var bolt := Craft.pivot(r, Vector3(0, 0.072, 0))
	bolt.name = "Bolt"
	k.box(bolt, -0.02, 0.0, Vector3(0.05, 0.007, 0.008), k.steel, 0.042)
	Craft.part(bolt, Craft.sphere(0.012, 10), k.black, Vector3(0.07, 0.0, 0.02), Vector3.ZERO, Vector3.ONE, k.shadows)
	r.set_meta("bolt", bolt)
	# Heavy fluted barrel and a big ported muzzle brake.
	k.tube(r, 0.22, 0.96, 0.07, 0.015, k.steel)
	for side: float in [-1.0, 1.0]:
		k.box(r, 0.6, 0.07, Vector3(0.002, 0.006, 0.6), k.rubber, side * 0.0145)
	k.box(r, 0.6, 0.0845, Vector3(0.006, 0.002, 0.6), k.rubber)
	k.box(r, 0.99, 0.07, Vector3(0.04, 0.034, 0.075), k.paint)
	for f: float in [0.972, 0.99, 1.008]:
		k.box(r, f, 0.07, Vector3(0.042, 0.022, 0.008), k.rubber)
	# Folded bipod on a rail clamp.
	k.box(r, 0.42, -0.008, Vector3(0.03, 0.016, 0.03), k.black)
	for side: float in [-1.0, 1.0]:
		k.box(r, 0.53, -0.012, Vector3(0.008, 0.008, 0.2), k.steel, side * 0.012, Vector3(0.04, 0, 0))
		k.box(r, 0.64, -0.018, Vector3(0.012, 0.012, 0.018), k.rubber, side * 0.012)
	# Scope: rings, main tube, bells, turrets, eyecup, flip caps, lenses.
	for f: float in [0.0, 0.17]:
		k.box(r, f, 0.108, Vector3(0.034, 0.026, 0.018), k.black)
		k.tube(r, f - 0.009, f + 0.009, 0.13, 0.024, k.black)
	k.tube(r, -0.06, 0.24, 0.13, 0.019, k.black)
	k.cone(r, -0.13, -0.06, 0.13, 0.026, 0.019, k.black)
	k.tube(r, -0.15, -0.128, 0.13, 0.028, k.rubber)
	k.cone(r, 0.23, 0.3, 0.13, 0.019, 0.032, k.black)
	k.tube(r, 0.3, 0.345, 0.13, 0.032, k.black)
	Craft.part(r, Craft.cylinder(0.013, 0.013, 0.022, 14), k.black, Vector3(0, 0.158, -0.09), Vector3.ZERO, Vector3.ONE, k.shadows)
	Craft.part(r, Craft.cylinder(0.0135, 0.0135, 0.004, 14), k.bright, Vector3(0, 0.17, -0.09), Vector3.ZERO, Vector3.ONE, k.shadows)
	k.rivet(r, 0.09, 0.13, 0.03, 0.012, k.black)
	k.rivet(r, 0.09, 0.13, -0.03, 0.01, k.black)
	Craft.part(r, Craft.cylinder(0.033, 0.033, 0.004, 16), k.black, Vector3(0, 0.178, -0.352), Vector3(PI * 0.5 - 0.3, 0, 0), Vector3.ONE, k.shadows)
	Craft.part(r, Craft.cylinder(0.03, 0.03, 0.002, 18), k.lens, Vector3(0, 0.13, -0.343), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
	Craft.part(r, Craft.cylinder(0.024, 0.024, 0.002, 18), k.lens, Vector3(0, 0.13, 0.148), Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
	# Sling.
	k.sling(r, Vector3(-0.026, 0.0, 0.62), Vector3(-0.027, -0.04, -0.33), 0.16)
	# Detachable box magazine.
	k.prof(mag, [Vector2(0.06, 0.0), Vector2(0.14, 0.0), Vector2(0.14, -0.055), Vector2(0.06, -0.055)], 0.034, k.black)
	k.box(mag, 0.1, -0.057, Vector3(0.038, 0.008, 0.086), k.black)
	return 0.13


# ---------------------------------------------------------------- shotgun

static func _shotgun(r: Node3D, pump: Node3D, k: Kit) -> float:
	# Receiver with ejection and loading ports.
	k.prof(r, [Vector2(-0.05, 0.0), Vector2(0.22, 0.0), Vector2(0.22, 0.075), Vector2(-0.03, 0.075), Vector2(-0.05, 0.06)], 0.052, k.paint, k.paint_core)
	k.box(r, 0.1, 0.05, Vector3(0.003, 0.026, 0.08), k.rubber, 0.027)
	k.box(r, 0.13, 0.0, Vector3(0.03, 0.004, 0.08), k.rubber)
	k.pin(r, 0.0, 0.012, 0.027)
	k.pin(r, 0.17, 0.012, 0.027)
	k.rivet(r, 0.04, 0.0, 0.027, 0.004, k.black)
	# Wooden stock and grip, rubber recoil pad.
	k.prof(r, [Vector2(-0.05, 0.07), Vector2(-0.05, 0.005), Vector2(-0.18, -0.03), Vector2(-0.36, -0.06), Vector2(-0.37, 0.04), Vector2(-0.18, 0.06)], 0.046, k.furn, k.furn_core)
	k.box(r, -0.375, -0.01, Vector3(0.048, 0.104, 0.018), k.rubber, 0.0, Vector3(0.2, 0, 0))
	k.prof(r, [Vector2(0.0, 0.004), Vector2(0.045, 0.004), Vector2(0.022, -0.1), Vector2(-0.028, -0.094)], 0.036, k.furn, k.furn_core)
	k.wrap(r, -0.25, 0.0, Vector2(0.046, 0.08), k.team, 0.014)
	# Trigger plate, guard, trigger.
	k.box(r, 0.07, -0.006, Vector3(0.03, 0.016, 0.1), k.paint)
	k.box(r, 0.075, -0.032, Vector3(0.012, 0.005, 0.06), k.paint)
	k.box(r, 0.104, -0.018, Vector3(0.012, 0.03, 0.005), k.paint)
	k.box(r, 0.065, -0.016, Vector3(0.005, 0.024, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	# Barrel, magazine tube with its cap, barrel clamp, brass bead.
	k.tube(r, 0.22, 0.8, 0.068, 0.016, k.steel)
	k.tube(r, 0.22, 0.7, 0.03, 0.014, k.paint)
	k.tube(r, 0.69, 0.725, 0.03, 0.0155, k.steel)
	k.box(r, 0.7, 0.05, Vector3(0.012, 0.05, 0.016), k.paint)
	Craft.part(r, Craft.sphere(0.005, 8), k.brass, Vector3(0, 0.088, -0.78), Vector3.ZERO, Vector3.ONE, k.shadows)
	# Side-saddle shell carrier with red shells and brass heads.
	k.box(r, 0.1, 0.04, Vector3(0.008, 0.056, 0.12), k.black, -0.03)
	var hull := Craft.mat(Craft.Kind.PLASTIC, Color(0.55, 0.12, 0.1), 0, Color.WHITE, 1.0, 0.0, false, k.vm)
	for i in 4:
		var f := 0.06 + i * 0.026
		Craft.part(r, Craft.cylinder(0.0095, 0.0095, 0.046, 10), hull, Vector3(-0.042, 0.044, -f), Vector3.ZERO, Vector3.ONE, k.shadows)
		Craft.part(r, Craft.cylinder(0.0102, 0.0102, 0.012, 10), k.brass, Vector3(-0.042, 0.016, -f), Vector3.ZERO, Vector3.ONE, k.shadows)
	# Sling.
	k.sling(r, Vector3(-0.016, 0.02, 0.71), Vector3(-0.024, -0.03, -0.3), 0.14)
	# Wooden pump with grooves, riding on two steel action bars.
	k.prof(pump, [Vector2(0.32, 0.008), Vector2(0.5, 0.008), Vector2(0.5, 0.056), Vector2(0.32, 0.056)], 0.052, k.furn, k.furn_core)
	for y: float in [0.02, 0.032, 0.044]:
		for side: float in [-1.0, 1.0]:
			k.box(pump, 0.41, y, Vector3(0.002, 0.004, 0.16), k.groove, side * 0.0265)
	for side: float in [-1.0, 1.0]:
		k.box(pump, 0.27, 0.03, Vector3(0.003, 0.006, 0.1), k.steel, side * 0.017)
	if k.att == "reddot":
		k.rail(r, 0.0, 0.16, 0.079, 0.022)
		return k.red_dot(r, 0.07, 0.083)
	return 0.088


# ----------------------------------------------------------------- pistol

static func _pistol(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Slide (recoils on every shot, locks back when empty).
	var slide := Craft.pivot(r, Vector3.ZERO)
	slide.name = "Slide"
	k.prof(slide, [Vector2(-0.04, 0.045), Vector2(0.19, 0.045), Vector2(0.19, 0.078), Vector2(0.185, 0.083), Vector2(-0.03, 0.083), Vector2(-0.04, 0.073)], 0.03, k.paint, k.paint_core)
	for i in 6:
		k.box(slide, -0.028 + i * 0.007, 0.064, Vector3(0.032, 0.03, 0.002), k.rubber)
	k.box(slide, 0.13, 0.083, Vector3(0.016, 0.004, 0.08), k.steel)
	k.box(slide, 0.07, 0.08, Vector3(0.012, 0.006, 0.035), k.rubber, 0.006)
	for side: float in [-1.0, 1.0]:
		k.box(slide, -0.02, 0.07, Vector3(0.004, 0.008, 0.016), k.black, side * 0.017)
	# Three-dot sights.
	k.box(slide, 0.175, 0.088, Vector3(0.005, 0.01, 0.008), k.black)
	k.rivet(slide, 0.171, 0.09, 0.0, 0.0018, k.white)
	k.box(slide, -0.025, 0.089, Vector3(0.022, 0.01, 0.008), k.black)
	for side: float in [-1.0, 1.0]:
		Craft.part(slide, Craft.cylinder(0.0018, 0.0018, 0.002, 8), k.white, Vector3(side * 0.006, 0.09, 0.021), Vector3(PI * 0.5, 0, 0), Vector3.ONE, k.shadows)
	r.set_meta("slide", slide)
	# Barrel crown at the front of the slide.
	k.tube(r, 0.17, 0.192, 0.068, 0.006, k.steel)
	# Frame, dust cover, grip panels with screws, slide stop.
	k.prof(r, [Vector2(-0.03, 0.0), Vector2(0.17, 0.0), Vector2(0.17, 0.045), Vector2(-0.03, 0.045)], 0.028, k.black)
	k.prof(r, [Vector2(-0.03, 0.004), Vector2(0.03, 0.004), Vector2(0.008, -0.1), Vector2(-0.045, -0.094)], 0.032, k.black)
	for side: float in [-1.0, 1.0]:
		k.prof(r, [Vector2(-0.024, -0.01), Vector2(0.022, -0.01), Vector2(0.005, -0.085), Vector2(-0.038, -0.08)], 0.004, k.furn, null, side * 0.017)
		k.rivet(r, -0.005, -0.02, side * 0.02, 0.003, k.pin_m)
		k.rivet(r, -0.02, -0.075, side * 0.02, 0.003, k.pin_m)
	k.box(r, 0.06, 0.042, Vector3(0.003, 0.006, 0.04), k.black, -0.0155)
	k.pin(r, 0.12, 0.03, 0.015, 0.003)
	# Trigger guard, trigger, hammer.
	k.box(r, 0.055, -0.026, Vector3(0.01, 0.005, 0.065), k.black)
	k.box(r, 0.087, -0.012, Vector3(0.01, 0.03, 0.006), k.black, 0.0, Vector3(0.25, 0, 0))
	k.box(r, 0.04, -0.008, Vector3(0.005, 0.022, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	k.box(r, -0.046, 0.075, Vector3(0.01, 0.02, 0.012), k.black, 0.0, Vector3(0.4, 0, 0))
	# Magazine: the body hides in the grip until a reload pulls it out.
	k.prof(mag, [Vector2(-0.032, 0.0), Vector2(0.004, 0.0), Vector2(-0.016, -0.096), Vector2(-0.044, -0.092)], 0.022, k.paint)
	k.box(mag, -0.014, -0.002, Vector3(0.009, 0.008, 0.024), k.brass)
	k.box(mag, -0.02, -0.1, Vector3(0.03, 0.012, 0.05), k.black, 0.0, Vector3(-0.22, 0, 0))
	return 0.093


## The optic attachment if one is fitted, otherwise flip-up irons.
static func _optic(r: Node3D, k: Kit, f: float, base_y: float, f_rear: float, f_front: float, front_floor := -1.0) -> float:
	match k.att:
		"reddot":
			return k.red_dot(r, f, base_y)
		"holo":
			return k.holo(r, f, base_y)
		"acog":
			return k.acog(r, f, base_y)
	return k.irons(r, f_rear, f_front, base_y, front_floor)


# ------------------------------------------------------------------- M249

static func _lmg(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Receiver, hinged feed cover with its rail, and the charging handle.
	k.prof(r, [Vector2(-0.08, 0.0), Vector2(0.24, 0.0), Vector2(0.24, 0.1), Vector2(-0.06, 0.1), Vector2(-0.08, 0.085)], 0.056, k.paint, k.paint_core)
	k.prof(r, [Vector2(-0.02, 0.1), Vector2(0.2, 0.1), Vector2(0.19, 0.118), Vector2(-0.01, 0.118)], 0.05, k.paint)
	k.rail(r, 0.0, 0.19, 0.122, 0.024)
	k.box(r, 0.2, 0.108, Vector3(0.056, 0.012, 0.012), k.black)
	var charge := Craft.pivot(r, Vector3.ZERO)
	charge.name = "Charge"
	k.box(charge, 0.12, 0.06, Vector3(0.024, 0.012, 0.014), k.black, 0.038)
	r.set_meta("charge", charge)
	k.box(r, 0.1, 0.06, Vector3(0.002, 0.01, 0.12), k.rubber, 0.0285)
	for f: float in [-0.05, 0.05, 0.2]:
		k.pin(r, f, 0.025, 0.029)
	# Skeleton stock with a rubber pad.
	k.prof(r, [Vector2(-0.08, 0.09), Vector2(-0.08, 0.02), Vector2(-0.38, 0.0), Vector2(-0.4, 0.09), Vector2(-0.38, 0.11)], 0.046, k.furn, k.furn_core)
	k.box(r, -0.405, 0.055, Vector3(0.048, 0.11, 0.014), k.rubber)
	k.wrap(r, -0.25, 0.06, Vector2(0.046, 0.06), k.team, 0.014)
	# Grip and trigger guard.
	k.prof(r, [Vector2(-0.005, 0.004), Vector2(0.045, 0.004), Vector2(0.02, -0.105), Vector2(-0.032, -0.098)], 0.036, k.furn, k.furn_core)
	k.box(r, 0.075, -0.032, Vector3(0.012, 0.005, 0.06), k.black)
	k.box(r, 0.103, -0.016, Vector3(0.012, 0.032, 0.005), k.black)
	k.box(r, 0.065, -0.014, Vector3(0.005, 0.024, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	# Handguard, barrel with carry handle, gas tube, flash hider, bipod.
	k.prof(r, [Vector2(0.24, 0.022), Vector2(0.42, 0.026), Vector2(0.42, 0.085), Vector2(0.24, 0.09)], 0.06, k.furn, k.furn_core)
	k.slots(r, 0.26, 0.4, 0.055, 4, Vector2(0.024, 0.01), 0.031)
	k.tube(r, 0.42, 0.79, 0.06, 0.012, k.steel)
	k.tube(r, 0.42, 0.66, 0.036, 0.009, k.paint)
	k.tube(r, 0.77, 0.83, 0.06, 0.016, k.black)
	k.box(r, 0.55, 0.1, Vector3(0.014, 0.014, 0.13), k.black)
	for f: float in [0.5, 0.6]:
		k.box(r, f, 0.083, Vector3(0.012, 0.035, 0.012), k.black)
	for side: float in [-1.0, 1.0]:
		k.box(r, 0.6, 0.03, Vector3(0.008, 0.008, 0.22), k.steel, side * 0.012, Vector3(-0.04, 0, 0))
	k.sling(r, Vector3(-0.03, 0.03, 0.4), Vector3(-0.026, 0.0, -0.36), 0.15)
	# Soft olive ammo pouch on the left, with a brass belt running in.
	k.prof(mag, [Vector2(0.03, -0.0), Vector2(0.17, -0.0), Vector2(0.175, -0.15), Vector2(0.025, -0.155)], 0.085, k.web, null, -0.02)
	k.box(mag, 0.1, -0.075, Vector3(0.088, 0.03, 0.15), k.web, -0.02)
	for i in 5:
		k.box(mag, 0.07 + i * 0.022, 0.012, Vector3(0.02, 0.01, 0.012), k.brass, -0.03 + i * 0.002)
	# Front post on the barrel; rear aperture on the feed-cover rail.
	return _optic(r, k, 0.08, 0.126, 0.02, 0.755, 0.072)


# ---------------------------------------------------------------- Mk 14

static func _dmr(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Aluminium chassis with a long top rail and slotted handguard.
	k.prof(r, [Vector2(-0.07, 0.0), Vector2(0.3, 0.0), Vector2(0.3, 0.09), Vector2(-0.05, 0.09), Vector2(-0.07, 0.075)], 0.052, k.paint, k.paint_core)
	k.prof(r, [Vector2(0.3, 0.02), Vector2(0.5, 0.02), Vector2(0.5, 0.09), Vector2(0.3, 0.09)], 0.058, k.paint, k.paint_core)
	k.rail(r, -0.05, 0.49, 0.094, 0.024)
	k.slots(r, 0.32, 0.48, 0.055, 5, Vector2(0.022, 0.01), 0.03)
	for side: float in [-1.0, 1.0]:
		k.rail(r, 0.34, 0.47, 0.055, 0.02, side * 0.03, false)
	k.box(r, 0.1, 0.06, Vector3(0.003, 0.018, 0.06), k.rubber, 0.0265)
	var charge := Craft.pivot(r, Vector3.ZERO)
	charge.name = "Charge"
	k.box(charge, 0.22, 0.05, Vector3(0.02, 0.012, 0.014), k.steel, 0.034)
	r.set_meta("charge", charge)
	for f: float in [-0.04, 0.2]:
		k.pin(r, f, 0.025, 0.027)
	# Adjustable stock with a cheek riser.
	k.tube(r, -0.33, -0.07, 0.065, 0.016, k.black)
	k.prof(r, [Vector2(-0.14, 0.1), Vector2(-0.14, 0.03), Vector2(-0.33, 0.004), Vector2(-0.345, 0.055), Vector2(-0.335, 0.11), Vector2(-0.2, 0.12)], 0.044, k.furn, k.furn_core)
	k.box(r, -0.35, 0.056, Vector3(0.046, 0.1, 0.014), k.rubber)
	k.wrap(r, -0.25, 0.06, Vector2(0.044, 0.06), k.team, 0.014)
	k.prof(r, [Vector2(-0.005, 0.004), Vector2(0.045, 0.004), Vector2(0.02, -0.105), Vector2(-0.032, -0.098)], 0.036, k.furn, k.furn_core)
	k.box(r, 0.075, -0.032, Vector3(0.012, 0.005, 0.06), k.black)
	k.box(r, 0.103, -0.016, Vector3(0.012, 0.032, 0.005), k.black)
	k.box(r, 0.065, -0.014, Vector3(0.005, 0.024, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	# Barrel and a ported muzzle brake.
	k.tube(r, 0.5, 0.86, 0.055, 0.011, k.steel)
	k.tube(r, 0.84, 0.91, 0.055, 0.016, k.black)
	for f: float in [0.86, 0.88]:
		k.box(r, f, 0.055, Vector3(0.034, 0.008, 0.006), k.rubber)
	k.sling(r, Vector3(-0.03, 0.03, 0.46), Vector3(-0.024, 0.0, -0.32), 0.14)
	# Straight 20-round magazine.
	k.prof(mag, [Vector2(0.08, 0.0), Vector2(0.15, 0.0), Vector2(0.158, -0.13), Vector2(0.088, -0.135)], 0.03, k.black)
	for y: float in [-0.05, -0.09]:
		k.box(mag, 0.12, y, Vector3(0.033, 0.004, 0.055), k.black)
	k.box(mag, 0.123, -0.137, Vector3(0.036, 0.012, 0.075), k.black)
	return _optic(r, k, 0.08, 0.098, -0.03, 0.47)


# ------------------------------------------------------------------- .44

static func _revolver(r: Node3D, mag: Node3D, k: Kit) -> float:
	# Frame, top strap and rear notch, barrel with full underlug and vent
	# rib, front blade, wood grips, hammer, trigger and guard.
	k.prof(r, [Vector2(-0.03, 0.035), Vector2(0.085, 0.035), Vector2(0.085, 0.088), Vector2(-0.02, 0.09), Vector2(-0.045, 0.07)], 0.03, k.paint, k.paint_core)
	k.prof(r, [Vector2(0.085, 0.042), Vector2(0.255, 0.046), Vector2(0.255, 0.086), Vector2(0.085, 0.088)], 0.022, k.paint, k.paint_core)
	k.box(r, 0.17, 0.09, Vector3(0.01, 0.006, 0.17), k.steel)
	k.box(r, 0.245, 0.097, Vector3(0.004, 0.014, 0.012), k.black)
	k.box(r, -0.015, 0.092, Vector3(0.016, 0.006, 0.01), k.black)
	k.tube(r, 0.25, 0.258, 0.068, 0.007, k.rubber)
	k.prof(r, [Vector2(-0.03, 0.04), Vector2(0.012, 0.04), Vector2(-0.004, -0.065), Vector2(-0.056, -0.062), Vector2(-0.052, 0.0)], 0.032, k.furn, k.furn_core)
	k.rivet(r, -0.02, -0.01, 0.017, 0.003, k.pin_m)
	k.box(r, -0.04, 0.088, Vector3(0.008, 0.018, 0.014), k.black, 0.0, Vector3(0.6, 0, 0))
	k.box(r, 0.04, -0.012, Vector3(0.01, 0.005, 0.05), k.paint)
	k.box(r, 0.064, 0.005, Vector3(0.01, 0.034, 0.006), k.paint, 0.0, Vector3(0.3, 0, 0))
	k.box(r, 0.03, 0.01, Vector3(0.005, 0.026, 0.006), k.bright, 0.0, Vector3(-0.3, 0, 0))
	# The cylinder (it swings out on reloads) with flutes and brass rims.
	var cyl := Craft.part(mag, Craft.cylinder(0.031, 0.031, 0.066, 18), k.paint, Vector3(0, 0.062, -0.048), Vector3(PI * 0.5, 0, 0), Vector3.ONE, k.shadows)
	var _c := cyl
	for i in 6:
		var a := TAU * i / 6.0
		k.box(mag, 0.048, 0.062 + sin(a) * 0.03, Vector3(0.006, 0.006, 0.05), k.rubber, cos(a) * 0.03)
		Craft.part(mag, Craft.cylinder(0.008, 0.008, 0.004, 10), k.brass, Vector3(cos(a + 0.5) * 0.019, 0.062 + sin(a + 0.5) * 0.019, -0.014), Vector3(PI * 0.5, 0, 0), Vector3.ONE, k.shadows)
	return 0.098


# --------------------------------------------------------------- extras

## A combat knife: black-coated clip-point blade with a bare steel edge,
## a steel guard and a stacked leather-washer handle.
static func knife(viewmodel: bool) -> Node3D:
	var root := Node3D.new()
	var ow := 0.003 if viewmodel else 0.01
	var sh := not viewmodel
	var blade := Craft.outlined(painted(Craft.Kind.PAPER, Color(0.16, 0.16, 0.17), 0.6, viewmodel), ow, viewmodel)
	var edge := Craft.mat(Craft.Kind.FOIL, Color(0.78, 0.79, 0.8), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	var steel := Craft.outlined(Craft.mat(Craft.Kind.FOIL, Color(0.45, 0.46, 0.48), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), ow, viewmodel)
	var pts := PackedVector2Array([Vector2(-0.013, 0), Vector2(0.015, 0), Vector2(0.015, 0.12), Vector2(0.006, 0.165), Vector2(-0.004, 0.19), Vector2(-0.008, 0.16), Vector2(-0.013, 0.15)])
	Craft.part(root, Craft.cutout(pts, 0.005), blade, Vector3(0, 0, -0.012), Vector3(-PI * 0.5, 0, 0), Vector3.ONE, sh)
	Craft.box(root, Vector3(0.0145, 0, -0.08), Vector3(0.003, 0.0054, 0.13), edge, Vector3.ZERO, sh)
	Craft.box(root, Vector3(0, 0, -0.008), Vector3(0.052, 0.012, 0.008), steel, Vector3.ZERO, sh)
	var leather := [Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.22, 0.13), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), Craft.mat(Craft.Kind.CARDBOARD, Color(0.29, 0.17, 0.1), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)]
	for i in 10:
		Craft.part(root, Craft.cylinder(0.0155, 0.0155, 0.0095, 12), leather[i % 2], Vector3(0, 0, 0.002 + i * 0.0095), Vector3(PI * 0.5, 0, 0), Vector3(1.0, 1.0, 0.82), sh)
	Craft.part(root, Craft.cylinder(0.017, 0.015, 0.012, 12), steel, Vector3(0, 0, 0.102), Vector3(PI * 0.5, 0, 0), Vector3(1.0, 1.0, 0.82), sh)
	return root


## A fragmentation grenade: olive papier-mache body with its yellow
## marking band, a foil fuse, the spoon and a pull ring.
static func frag(viewmodel: bool) -> Node3D:
	var root := Node3D.new()
	var ow := 0.003 if viewmodel else 0.008
	var sh := not viewmodel
	var body := Craft.outlined(painted(Craft.Kind.PAPER, Color(0.3, 0.33, 0.23), 0.6, viewmodel), ow, viewmodel)
	var steel := Craft.mat(Craft.Kind.FOIL, Color(0.55, 0.56, 0.58), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	var bright := Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.76, 0.78), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	Craft.part(root, Craft.sphere(0.04, 14), body, Vector3.ZERO, Vector3.ZERO, Vector3(1, 1.08, 1), sh)
	Craft.part(root, Craft.cylinder(0.034, 0.034, 0.006, 16), Craft.mat(Craft.Kind.PAPER, Color(0.72, 0.6, 0.2), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), Vector3(0, 0.026, 0), Vector3.ZERO, Vector3.ONE, sh)
	Craft.part(root, Craft.cylinder(0.012, 0.015, 0.026, 10), steel, Vector3(0, 0.05, 0), Vector3.ZERO, Vector3.ONE, sh)
	Craft.box(root, Vector3(0.03, 0.034, 0), Vector3(0.004, 0.05, 0.014), steel, Vector3(0, 0, -0.35), sh)
	Craft.box(root, Vector3(0.012, 0.063, 0), Vector3(0.03, 0.004, 0.014), steel, Vector3(0, 0, -0.1), sh)
	Craft.part(root, Craft.torus_ring(0.012, 0.0025), bright, Vector3(-0.024, 0.058, 0), Vector3(PI * 0.5, 0, 0), Vector3.ONE, sh)
	Craft.box(root, Vector3(-0.012, 0.056, 0), Vector3(0.016, 0.002, 0.002), bright, Vector3.ZERO, sh)
	if not viewmodel:
		Craft.make_moving(root)
	return root
