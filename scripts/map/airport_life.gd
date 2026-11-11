class_name AirportLife
extends RefCounted
## The small things that make Gateway read as a working airport rather than
## a set: where the rain drains, how the lights get power, how pilots find
## their stand, how the jet is fuelled and loaded, how passengers get
## through security and find their gate, and the mess they leave behind.
## Every piece is still a craft supply: card, paper, felt, yarn, tape, foil.

static var rng := RandomNumberGenerator.new()
const FONT := preload("res://assets/fonts/LuckiestGuy-Regular.ttf")
const BODY_FONT := preload("res://assets/fonts/Fredoka.ttf")


static func build(map: GatewayMap) -> void:
	rng.seed = 8642
	var root := Node3D.new()
	root.name = "AirportLife"
	map.deco.add_child(root)
	var b := map.b
	_curbs_and_drains(root)
	_utilities(root, b)
	_airside_signs(root, b)
	_servicing(root, b)
	_terminal_systems(root, b)
	_baggage_hall(root, b)
	_clutter(root)


static func _m(kind: int, col: Color, pattern := 0, col2 := Color.WHITE, scale := 1.0) -> Material:
	return Craft.mat(kind, col, pattern, col2, scale)


static func _text(parent: Node3D, text: String, pos: Vector3, yaw: float, size: int, col: Color, px := 0.004, outline := 0, font: Font = FONT) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = outline
	l.outline_modulate = Craft.INK
	l.position = pos
	l.rotation.y = yaw
	parent.add_child(l)
	return l


# ------------------------------------------------- A. curbs, drains, covers

static func _curb(parent: Node3D, a: Vector2, b: Vector2, painted: bool) -> void:
	var len := a.distance_to(b)
	var dir := (b - a) / len
	var yaw := atan2(-dir.x, -dir.y) + PI * 0.5
	var seg := 1.0
	var n := maxi(int(len / seg), 1)
	for i in n:
		var p := a + dir * (i + 0.5) * (len / n)
		var col := Color(0.78, 0.77, 0.74)
		if painted:
			col = Craft.YELLOW if i % 2 == 0 else Color(0.2, 0.2, 0.22)
		Craft.box(parent, Vector3(p.x, 0.065, p.y), Vector3(len / n - 0.012, 0.13, 0.16), _m(Craft.Kind.CARDBOARD, col), Vector3(0, yaw, rng.randf_range(-0.01, 0.01)), false)


static func _curbs_and_drains(root: Node3D) -> void:
	# Painted kerb where the sidewalk meets the airside, plain kerbs round lawns.
	_curb(root, Vector2(-14.0, 22.3), Vector2(-14.0, 26.0), true)
	for r: Rect2 in [Rect2(-13.6, 17.5, 4.6, 5.5), Rect2(44.0, -34.5, 8.0, 4.0)]:
		var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for i in 4:
			_curb(root, c[i], c[(i + 1) % 4], false)
	_curb(root, Vector2(-9.0, 23.0), Vector2(60.0, 23.0), false)
	_curb(root, Vector2(58.0, -36.2), Vector2(58.0, 23.0), false)
	_curb(root, Vector2(32.0, -36.2), Vector2(58.0, -36.2), false)
	# Storm-drain grates along the terminal face: foil bars in a dark slot.
	var slot := _m(Craft.Kind.FELT, Color(0.08, 0.08, 0.09))
	var bar := Craft.mat(Craft.Kind.FOIL, Color(0.62, 0.63, 0.66), 0, Color.WHITE, 1.0, 0.0)
	var z := -23.0
	while z < 21.0:
		var g := Craft.pivot(root, Vector3(-12.9, 0.035, z))
		Craft.box(g, Vector3.ZERO, Vector3(0.5, 0.01, 1.2), slot, Vector3.ZERO, false)
		for k in 7:
			Craft.box(g, Vector3(0, 0.008, -0.51 + k * 0.17), Vector3(0.52, 0.012, 0.045), bar, Vector3.ZERO, false)
		z += 7.0
	# Manholes and fuel-hydrant pits: big bottle-cap lids with knurled rims.
	var lid := Craft.mat(Craft.Kind.FOIL, Color(0.5, 0.51, 0.54), 0, Color.WHITE, 1.0, 0.0, false)
	for p: Vector2 in [Vector2(0, 10), Vector2(24, -6), Vector2(36, -22), Vector2(-2, 18), Vector2(52, 2), Vector2(21, -14), Vector2(21, 9)]:
		var hydrant := p == Vector2(21, -14) or p == Vector2(21, 9)
		var cap := Craft.part(root, Craft.cylinder(0.5 if not hydrant else 0.38, 0.52 if not hydrant else 0.4, 0.04, 24), lid if not hydrant else Craft.mat(Craft.Kind.PLASTIC, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), Vector3(p.x, 0.045, p.y))
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for k in 3:
			Craft.box(root, Vector3(p.x, 0.07, p.y - 0.2 + k * 0.2), Vector3(0.62 if not hydrant else 0.42, 0.008, 0.03), _m(Craft.Kind.PAPER, Color(0.3, 0.3, 0.32)), Vector3.ZERO, false)


# ------------------------------------------------------- B. utilities

static func _utilities(root: Node3D, b: MapBuilder) -> void:
	var box_m := _m(Craft.Kind.CARDBOARD, Color(0.55, 0.6, 0.55))
	var warn := _m(Craft.Kind.PAPER, Craft.YELLOW)
	var cable_cols := [Color(0.15, 0.15, 0.17), Color(0.9, 0.55, 0.15)]
	# Junction boxes beside each floodlight mast, wired in with yarn.
	for pair in [[Vector3(1.4, 0, -25.2), Vector3(0, 0, -24)], [Vector3(54.6, 0, -35.0), Vector3(56, 0, -34)],
			[Vector3(54.6, 0, 22.0), Vector3(56, 0, 23)], [Vector3(12.6, 0, 22.0), Vector3(14, 0, 23)], [Vector3(-9.6, 0, -10.6), Vector3(-8, 0, -9)]]:
		var at: Vector3 = pair[0]
		var to: Vector3 = pair[1]
		var jb := b.solid(at + Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.4), box_m, atan2(to.x - at.x, to.z - at.z))
		Craft.box(jb, Vector3(0, 0.15, 0.205), Vector3(0.22, 0.2, 0.01), warn)
		var bolt := Craft.cutout(PackedVector2Array([Vector2(0.02, 0.08), Vector2(-0.04, -0.01), Vector2(0.0, -0.01), Vector2(-0.02, -0.08), Vector2(0.04, 0.01), Vector2(0.0, 0.01)]), 0.004)
		Craft.part(jb, bolt, _m(Craft.Kind.PAPER, Craft.INK), Vector3(0, 0.15, 0.212))
		var pts := []
		for i in 9:
			var t := i / 8.0
			var p := at.lerp(to, t) + Vector3(sin(t * PI) * 0.25, 0.05, 0)
			if i == 0:
				p.y = 0.2
			if i == 8:
				p.y = 0.6
			pts.append(p)
		Handmade.cable(root, pts, cable_cols[rng.randi() % 2], 0.03)
	# A felt fire hydrant on the corner by the terminal.
	var h := b.column(Vector3(-12.4, 0, 22.4), 0.16, 0.7, _m(Craft.Kind.FELT, Craft.RED))
	Craft.part(h, Craft.sphere(0.17, 12), _m(Craft.Kind.FELT, Craft.RED), Vector3(0, 0.35, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	for side: float in [-1.0, 1.0]:
		Craft.part(h, Craft.cylinder(0.06, 0.06, 0.14, 10), Craft.mat(Craft.Kind.PLASTIC, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), Vector3(side * 0.18, 0.12, 0), Vector3(0, 0, PI * 0.5))
	Craft.part(h, Craft.cylinder(0.06, 0.08, 0.08, 10), Craft.mat(Craft.Kind.PLASTIC, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), Vector3(0, 0.46, 0))
	# Bollards outside the terminal doors: card tubes wrapped in felt bands.
	var post := Craft.mat(Craft.Kind.CARDBOARD, Color(0.2, 0.2, 0.22), 0, Color.WHITE, 1.0, 1.0, false)
	var band := Craft.mat(Craft.Kind.FELT, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false)
	for i in 6:
		var p := Vector3(-41.0 + i * 1.2, 0, 23.5)
		var bo := b.column(p, 0.11, 0.95, post)
		for y: float in [0.25, 0.7]:
			Craft.part(bo, Craft.cylinder(0.115, 0.115, 0.08, 14), band, Vector3(0, y - 0.475, 0))
	# Fire-extinguisher cabinets on the terminal walls.
	for spot in [[Vector3(-13.7, 1.3, -8.0), PI * 0.5], [Vector3(-13.7, 1.3, 16.0), PI * 0.5], [Vector3(-14.3, 1.3, 6.0), -PI * 0.5], [Vector3(-57.7, 1.3, 8.0), PI * 0.5]]:
		var pos: Vector3 = spot[0]
		var yaw: float = spot[1]
		var cab := Craft.pivot(root, pos, Vector3(0, yaw, 0))
		Craft.box(cab, Vector3.ZERO, Vector3(0.5, 0.8, 0.14), _m(Craft.Kind.CARDBOARD, Craft.RED))
		Craft.box(cab, Vector3(0, 0, 0.075), Vector3(0.38, 0.62, 0.01), Craft.cellophane(Color(0.8, 0.9, 1.0, 0.35)))
		Craft.part(cab, Craft.capsule(0.08, 0.42), _m(Craft.Kind.FELT, Color(0.75, 0.12, 0.1)), Vector3(0, -0.04, 0.0))
		_text(cab, "FIRE", Vector3(0, 0.5, 0.075), 0.0, 32, Craft.WHITE, 0.004)
	# Wall lamps above the terminal's tarmac doors, and over the entrance.
	var glow := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.88, 0.62), 0, Color.WHITE, 1.0, 0.0, false)
	for spot in [[Vector3(-13.55, 3.45, -4.0), PI * 0.5], [Vector3(-13.55, 3.45, 12.0), PI * 0.5], [Vector3(-36.0, 3.0, 22.45), 0.0], [Vector3(-40.0, 3.0, 22.45), 0.0]]:
		var pos: Vector3 = spot[0]
		var lamp := Craft.pivot(root, pos, Vector3(0, spot[1], 0))
		Craft.box(lamp, Vector3(0, 0, 0.08), Vector3(0.5, 0.12, 0.2), _m(Craft.Kind.CARDBOARD, Color(0.25, 0.26, 0.3)))
		Craft.box(lamp, Vector3(0, -0.07, 0.1), Vector3(0.42, 0.02, 0.14), glow)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.6)
		l.light_energy = 0.8
		l.omni_range = 4.0
		l.position = Vector3(0, -0.4, 0.5)
		lamp.add_child(l)


# ------------------------------------------------------- C. signage

static func _taxi_sign(root: Node3D, b: MapBuilder, pos: Vector3, yaw: float, panels: Array) -> void:
	var sign := Craft.pivot(root, pos, Vector3(0, yaw, 0))
	var w := 0.0
	for p in panels:
		w += 0.55 + String(p[0]).length() * 0.22
	var x := -w * 0.5
	for p in panels:
		var pw := 0.55 + String(p[0]).length() * 0.22
		var yellow: bool = p[1]
		var bg := Craft.YELLOW if yellow else Color(0.12, 0.12, 0.14)
		var fg := Craft.INK if yellow else Craft.YELLOW
		Craft.box(sign, Vector3(x + pw * 0.5, 0.6, 0), Vector3(pw, 0.6, 0.3), _m(Craft.Kind.CARDBOARD, bg))
		for side: float in [1.0, -1.0]:
			_text(sign, p[0], Vector3(x + pw * 0.5, 0.6, 0.155 * side), 0.0 if side > 0.0 else PI, 72, fg, 0.0055)
		x += pw
	for lx: float in [-w * 0.35, w * 0.35]:
		Craft.box(sign, Vector3(lx, 0.15, 0), Vector3(0.08, 0.3, 0.08), _m(Craft.Kind.CARDBOARD, Color(0.3, 0.3, 0.32)))
	var _u := b


static func _airside_signs(root: Node3D, b: MapBuilder) -> void:
	# Taxiway signs standing on the lawns.
	_taxi_sign(root, b, Vector3(8.0, 0.04, 24.3), 0.0, [["A", false], ["A2 >", true]])
	_taxi_sign(root, b, Vector3(30.0, 0.04, 24.3), 0.0, [["< B", true], ["A", false]])
	_taxi_sign(root, b, Vector3(59.0, 0.04, -8.0), -PI * 0.5, [["07", false], ["< 08 09", true]])
	_taxi_sign(root, b, Vector3(46.0, 0.04, -31.0), PI, [["B", false]])
	# Stand guidance display on the terminal, facing the airliner's cockpit.
	var vdgs := Craft.pivot(root, Vector3(-13.6, 6.4, -2.0), Vector3(0, PI * 0.5, 0))
	Craft.box(vdgs, Vector3.ZERO, Vector3(1.6, 1.1, 0.25), _m(Craft.Kind.CARDBOARD, Color(0.18, 0.18, 0.2)))
	Craft.box(vdgs, Vector3(0, 0.0, 0.13), Vector3(1.4, 0.9, 0.01), Craft.mat(Craft.Kind.GLOW, Color(0.05, 0.08, 0.06), 0, Color.WHITE, 1.0, 0.0))
	_text(vdgs, "PC 101", Vector3(0, 0.26, 0.14), 0.0, 48, Color(1.0, 0.75, 0.2), 0.004, 0, BODY_FONT)
	_text(vdgs, "STOP", Vector3(0, -0.12, 0.14), 0.0, 96, Color(1.0, 0.25, 0.2), 0.0045)
	_text(root, "STAND 07", Vector3(-13.6, 7.3, -2.0), PI * 0.5, 64, Craft.CREAM, 0.0055, 10)
	# Windsock on its mast on the north-east lawn.
	var mast := Craft.mat(Craft.Kind.CARDBOARD, Color(0.9, 0.9, 0.92), Craft.Pattern.BANDS, Craft.RED, 1.2, 1.0, false)
	b.column(Vector3(48.0, 0, -32.5), 0.08, 6.0, mast)
	var sock := Craft.pivot(root, Vector3(48.0, 5.8, -32.5), Vector3(0, -0.6, 0))
	Craft.part(sock, Craft.torus_ring(0.35), Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.7, 0.72), 0, Color.WHITE, 1.0, 0.0, false), Vector3.ZERO, Vector3(0, 0, PI * 0.5))
	for i in 5:
		var r0 := 0.35 - i * 0.05
		var r1 := r0 - 0.05
		var seg := Craft.part(sock, Craft.cylinder(r1, r0, 0.42, 16), Craft.mat(Craft.Kind.FELT, Craft.ORANGE if i % 2 == 0 else Craft.WHITE, 0, Color.WHITE, 1.0, 0.0, false), Vector3(0.21 + i * 0.42, -i * 0.06, 0), Vector3(0, 0, PI * 0.5 + 0.12))
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# FOD bin: litter must never reach a jet engine.
	var fod := b.solid(Vector3(-11.5, 0.5, -14.0), Vector3(0.8, 1.0, 0.6), _m(Craft.Kind.CARDBOARD, Craft.ORANGE))
	Craft.box(fod, Vector3(0, 0.52, 0), Vector3(0.84, 0.06, 0.64), _m(Craft.Kind.CARDBOARD, Color(0.2, 0.2, 0.22)))
	_text(fod, "F.O.D.", Vector3(0, 0.15, 0.305), 0.0, 48, Craft.INK, 0.004)
	# Safety signs on posts.
	for spot in [[Vector3(-12.6, 0.04, -17.0), 0.0, "NO SMOKING"], [Vector3(31.0, 0.04, -24.5), PI, "HEARING PROTECTION"], [Vector3(-12.6, 0.04, 16.0), 0.0, "AIRSIDE ONLY"]]:
		var sp := Craft.pivot(root, spot[0], Vector3(0, spot[1], 0))
		Craft.box(sp, Vector3(0, 0.75, 0), Vector3(0.06, 1.5, 0.06), _m(Craft.Kind.CARDBOARD, Color(0.4, 0.4, 0.42)))
		Craft.box(sp, Vector3(0, 1.5, 0.04), Vector3(0.9, 0.5, 0.02), _m(Craft.Kind.PAPER, Craft.WHITE, Craft.Pattern.STITCH, Craft.RED, 0.6))
		_text(sp, spot[2], Vector3(0, 1.5, 0.055), 0.0, 40, Craft.RED, 0.0028)


# ------------------------------------------------------ D. servicing

static func _servicing(root: Node3D, b: MapBuilder) -> void:
	# Jet bridge: pleated-paper bellows sealing round the door, a rotunda
	# where it meets the terminal, and drive wheels on the far leg.
	var pleat := _m(Craft.Kind.PAPER, Color(0.3, 0.32, 0.36))
	for i in 22:
		var x := -2.55 + i * 0.15
		Craft.box(root, Vector3(x, 4.35, -5.13 + (i % 2) * 0.05), Vector3(0.14, 2.9, 0.04), pleat)
	Craft.part(root, Craft.cylinder(2.0, 2.0, 2.9, 24), _m(Craft.Kind.CARDBOARD, Color(0.55, 0.58, 0.64), Craft.Pattern.BANDS, Color(0.6, 0.63, 0.7), 2.0), Vector3(-12.6, 4.4, -9.0))
	var tyre := Craft.mat(Craft.Kind.PLASTIC, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.box(root, Vector3(-1.0, 0.35, -8.8), Vector3(1.8, 0.3, 0.5), _m(Craft.Kind.CARDBOARD, Craft.YELLOW, Craft.Pattern.HAZARD, Craft.INK, 2.0))
	for side: float in [-0.75, 0.75]:
		Craft.part(root, Craft.cylinder(0.32, 0.32, 0.28, 16), tyre, Vector3(-1.0 + side, 0.32, -8.8), Vector3(PI * 0.5, 0, 0))
	# Forward cargo hold open on the airliner, bags riding up the belt.
	var hold := Craft.pivot(root, Vector3(3.2, 2.45, 0.62), Vector3(-0.64, 0, 0))
	Craft.box(hold, Vector3.ZERO, Vector3(1.6, 1.1, 0.04), _m(Craft.Kind.FELT, Color(0.08, 0.08, 0.1)))
	Craft.box(hold, Vector3(0, 0.62, 0.02), Vector3(1.7, 0.08, 0.06), _m(Craft.Kind.PAPER, Color(0.6, 0.65, 0.72)))
	for i in 4:
		var t := 0.2 + i * 0.2
		var p := Vector3(3.2, lerpf(0.9, 2.5, t), lerpf(5.6, 1.6, t))
		Craft.box(root, p, Vector3(0.45, 0.3, 0.3), _m(Craft.Kind.FELT, [Craft.RED, Craft.TEAL, Craft.PURPLE, Craft.ORANGE][i], Craft.Pattern.STITCH, Craft.CREAM), Vector3(-0.38, rng.randf_range(-0.3, 0.3), 0))
	# Hydrant fuel cart under the north wing with its hose plugged in.
	var cart := b.solid(Vector3(20.0, 0.7, -12.4), Vector3(1.6, 0.9, 3.0), _m(Craft.Kind.CARDBOARD, Color(0.85, 0.85, 0.88)), 0.2)
	Craft.box(cart, Vector3(0, 0.5, 0), Vector3(1.4, 0.12, 2.6), _m(Craft.Kind.CARDBOARD, Craft.RED))
	_text(cart, "JET A-1", Vector3(0.81, 0.0, 0.0), PI * 0.5, 48, Craft.RED, 0.0045)
	for side: float in [-0.8, 0.8]:
		for z: float in [-1.0, 1.0]:
			Craft.part(cart, Craft.cylinder(0.26, 0.26, 0.18, 14), tyre, Vector3(side, -0.42, z), Vector3(0, 0, PI * 0.5))
	var hose := []
	for i in 12:
		var t := i / 11.0
		hose.append(Vector3(lerpf(20.4, 21.0, t), 0.06 + sin(t * PI) * 0.1, lerpf(-11.5, -14.0, t)))
	Handmade.cable(root, hose, Color(0.12, 0.12, 0.14), 0.05)
	var up := []
	for i in 10:
		var t := i / 9.0
		up.append(Vector3(19.6, lerpf(1.2, 2.6, t), lerpf(-12.6, -11.0, t) + sin(t * PI) * 0.3))
	Handmade.cable(root, up, Color(0.12, 0.12, 0.14), 0.05)
	# Tow bar waiting at the nose, and cones off each wingtip.
	var bar := Craft.pivot(root, Vector3(-7.0, 0.25, -2.0), Vector3(0, 0, 0))
	Craft.box(bar, Vector3.ZERO, Vector3(3.2, 0.12, 0.12), _m(Craft.Kind.CARDBOARD, Craft.YELLOW, Craft.Pattern.HAZARD, Craft.INK, 3.0))
	for side: float in [-0.8, 0.8]:
		Craft.part(bar, Craft.cylinder(0.2, 0.2, 0.12, 12), tyre, Vector3(side, -0.05, 0.12), Vector3(PI * 0.5, 0, 0))
	for p: Vector3 in [Vector3(24.8, 0, -21.6), Vector3(24.8, 0, 17.6), Vector3(-10.8, 0, -2.0), Vector3(42.0, 0, -2.0)]:
		Props.cone(b, p)


# ------------------------------------------------- E. terminal systems

static func _terminal_systems(root: Node3D, b: MapBuilder) -> void:
	# Security checkpoint: x-ray tunnel with rollers and trays, detector arch.
	var xray := b.solid(Vector3(-25.0, 0.6, 8.0), Vector3(2.4, 1.2, 1.1), _m(Craft.Kind.CARDBOARD, Color(0.82, 0.84, 0.88)))
	Craft.box(xray, Vector3(0, -0.1, 0), Vector3(2.42, 0.55, 0.8), _m(Craft.Kind.FELT, Color(0.08, 0.08, 0.1)))
	Craft.box(xray, Vector3(-1.1, -0.35, 0), Vector3(0.1, 0.5, 0.9), _m(Craft.Kind.FELT, Color(0.15, 0.15, 0.17)))
	for side: float in [-1.0, 1.0]:
		var bed := Craft.pivot(root, Vector3(-25.0 + side * 2.4, 0.45, 8.0))
		Craft.box(bed, Vector3.ZERO, Vector3(2.4, 0.08, 0.8), _m(Craft.Kind.CARDBOARD, Color(0.3, 0.31, 0.34)))
		for k in 12:
			Craft.part(bed, Craft.cylinder(0.03, 0.03, 0.78, 8), Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.71, 0.74), 0, Color.WHITE, 1.0, 0.0, false), Vector3(-1.1 + k * 0.2, 0.05, 0), Vector3(PI * 0.5, 0, 0))
		for leg: float in [-1.0, 1.0]:
			Craft.box(bed, Vector3(leg * 1.0, -0.22, 0), Vector3(0.06, 0.44, 0.7), _m(Craft.Kind.CARDBOARD, Color(0.3, 0.31, 0.34)))
		for k in 2:
			Craft.box(bed, Vector3(-0.6 + k * 0.9, 0.12, 0), Vector3(0.55, 0.08, 0.4), _m(Craft.Kind.PLASTIC, Color(0.25, 0.27, 0.3)))
	Craft.box(root, Vector3(-25.0, 1.25, 8.56), Vector3(0.6, 0.4, 0.04), Craft.mat(Craft.Kind.GLOW, Color(0.4, 0.75, 1.0), 0, Color.WHITE, 1.0, 0.0))
	var arch := Craft.pivot(root, Vector3(-20.5, 0, 8.0))
	var grey := _m(Craft.Kind.CARDBOARD, Color(0.78, 0.8, 0.84))
	for side: float in [-0.5, 0.5]:
		b.solid(Vector3(-20.5, 1.1, 8.0 + side * 1.0), Vector3(0.5, 2.2, 0.18), grey)
	Craft.box(arch, Vector3(0, 2.3, 0), Vector3(0.5, 0.25, 2.2), grey)
	Craft.part(arch, Craft.sphere(0.07, 8), Craft.mat(Craft.Kind.GLOW, Color(0.3, 1.0, 0.4), 0, Color.WHITE, 1.0, 0.0, false), Vector3(0.26, 2.3, 0.6))
	_text(root, "SECURITY", Vector3(-22.8, 2.9, 8.0), -PI * 0.5, 64, Craft.CREAM, 0.005, 10)
	# Clocks on the pillars.
	for p: Vector3 in [Vector3(-44, 4.2, -8), Vector3(-32, 4.2, -8), Vector3(-44, 4.2, 12), Vector3(-32, 4.2, 12)]:
		for side: float in [-1.0, 1.0]:
			var c := Craft.pivot(root, p + Vector3(0, 0, side * 0.48), Vector3(0, 0.0 if side > 0.0 else PI, 0))
			Craft.part(c, Craft.cylinder(0.38, 0.38, 0.04, 28), _m(Craft.Kind.PAPER, Craft.CREAM), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
			Craft.part(c, Craft.torus_ring(0.39), Craft.mat(Craft.Kind.PLASTIC, Craft.ORANGE, 0, Color.WHITE, 1.0, 0.0, false), Vector3(0, 0, 0.01), Vector3(PI * 0.5, 0, 0))
			for k in 12:
				var a := TAU * k / 12.0
				Craft.box(c, Vector3(sin(a) * 0.3, cos(a) * 0.3, 0.025), Vector3(0.025, 0.06 if k % 3 == 0 else 0.03, 0.005), _m(Craft.Kind.PAPER, Craft.INK))
			Craft.box(c, Vector3(0.06, 0.09, 0.03), Vector3(0.025, 0.2, 0.006), _m(Craft.Kind.PAPER, Craft.INK), Vector3(0, 0, -0.6))
			Craft.box(c, Vector3(-0.05, 0.12, 0.034), Vector3(0.018, 0.27, 0.006), _m(Craft.Kind.PAPER, Craft.INK), Vector3(0, 0, 0.35))
	# Exit signs over the doors (green glowing paper boxes).
	for spot in [[Vector3(-14.3, 3.3, -4.0), -PI * 0.5], [Vector3(-14.3, 3.3, 12.0), -PI * 0.5], [Vector3(-38.0, 3.35, 21.7), PI]]:
		var s := Craft.pivot(root, spot[0], Vector3(0, spot[1], 0))
		Craft.box(s, Vector3.ZERO, Vector3(0.9, 0.32, 0.1), Craft.mat(Craft.Kind.GLOW, Color(0.2, 0.85, 0.35), 0, Color.WHITE, 1.0, 0.0))
		_text(s, "EXIT", Vector3(0, 0, 0.055), 0.0, 48, Color.WHITE, 0.0045)
	# Ceiling vents and sprinkler heads (a multimesh each).
	var vents := []
	var sprinklers := []
	var x := -56.0
	while x < -15.0:
		var in_skylight := (x > -50.5 and x < -46.5) or (x > -38.5 and x < -34.5) or (x > -26.5 and x < -22.5)
		var z := -17.0
		while z < 21.0:
			if not in_skylight:
				vents.append(Transform3D(Basis.from_scale(Vector3(0.7, 0.03, 0.7)), Vector3(x, 7.97, z)))
				sprinklers.append(Transform3D(Basis(), Vector3(x + 1.5, 7.92, z + 1.5)))
			z += 6.0
		x += 6.0
	FeltGround._multimesh(root, Craft.unit_box(), Craft.mat(Craft.Kind.FOIL, Color(0.78, 0.79, 0.82), Craft.Pattern.BANDS, Color(0.5, 0.5, 0.52), 14.0), vents, false)
	FeltGround._multimesh(root, Craft.sphere(0.05, 8), Craft.mat(Craft.Kind.PLASTIC, Craft.RED, 0, Color.WHITE, 1.0, 0.0, false), sprinklers, false)
	# Security cameras in the corners.
	for spot in [[Vector3(-57.4, 6.8, -29.4), PI * 0.75], [Vector3(-14.7, 6.8, 21.4), -PI * 0.25], [Vector3(-57.4, 6.8, 21.4), PI * 0.25], [Vector3(-14.7, 2.5, -29.4), -PI * 0.75]]:
		var cam := Craft.pivot(root, spot[0], Vector3(0, spot[1], 0))
		Craft.box(cam, Vector3(0, 0.15, 0), Vector3(0.06, 0.3, 0.06), _m(Craft.Kind.CARDBOARD, Color(0.85, 0.86, 0.88)))
		Craft.box(cam, Vector3(0, 0, -0.18), Vector3(0.16, 0.14, 0.36), _m(Craft.Kind.CARDBOARD, Color(0.9, 0.9, 0.92)), Vector3(0.35, 0, 0))
		Craft.part(cam, Craft.sphere(0.03, 6), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.2, 0.15), 0, Color.WHITE, 1.0, 0.0, false), Vector3(0.05, 0.05, -0.05))
	# Wayfinding: hanging yellow signs, and arrows on the floor.
	for spot in [[Vector3(-30.0, 5.2, -12.0), 0.0, "GATES 1-7  >"], [Vector3(-48.0, 5.2, 0.0), PI * 0.5, "<  BAGGAGE"], [Vector3(-18.0, 5.0, 4.0), -PI * 0.5, "SECURITY  >"]]:
		var sg := Craft.pivot(root, spot[0], Vector3(0, spot[1], 0))
		Craft.box(sg, Vector3.ZERO, Vector3(3.4, 0.55, 0.08), _m(Craft.Kind.FELT, Craft.YELLOW, Craft.Pattern.STITCH, Craft.INK))
		for side: float in [1.0, -1.0]:
			_text(sg, spot[2], Vector3(0, 0, 0.045 * side), 0.0 if side > 0.0 else PI, 72, Craft.INK, 0.0042)
		for sx: float in [-1.3, 1.3]:
			Craft.box(sg, Vector3(sx, 1.4, 0), Vector3(0.012, 2.3, 0.012), _m(Craft.Kind.PAPER, Color(0.85, 0.85, 0.85)))
	var arrow := Craft.cutout(PackedVector2Array([Vector2(-0.18, -0.4), Vector2(0.18, -0.4), Vector2(0.18, 0.1), Vector2(0.4, 0.1), Vector2(0, 0.5), Vector2(-0.4, 0.1), Vector2(-0.18, 0.1)]), 0.01)
	for p: Vector3 in [Vector3(-40, 0.03, -10.5), Vector3(-34, 0.03, -10.5), Vector3(-28, 0.03, -10.5), Vector3(-22, 0.03, -10.5)]:
		Craft.part(root, arrow, Craft.mat(Craft.Kind.FELT, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), p, Vector3(-PI * 0.5, -PI * 0.5, 0))
	# Restrooms sign and a wet-floor A-frame.
	var rr := Craft.pivot(root, Vector3(-57.7, 2.3, 18.0), Vector3(0, PI * 0.5, 0))
	Craft.box(rr, Vector3.ZERO, Vector3(1.6, 0.5, 0.05), _m(Craft.Kind.FELT, Craft.BLUE, Craft.Pattern.STITCH, Craft.CREAM))
	_text(rr, "RESTROOMS", Vector3(0, 0, 0.03), 0.0, 56, Craft.CREAM, 0.0042)
	var wf := Craft.pivot(root, Vector3(-55.5, 0, 15.5), Vector3(0, 0.6, 0))
	for side: float in [-1.0, 1.0]:
		var panel := Craft.box(wf, Vector3(0, 0.38, side * 0.12), Vector3(0.4, 0.75, 0.01), _m(Craft.Kind.CARDBOARD, Craft.YELLOW), Vector3(side * 0.3, 0, 0))
		panel.rotation.x = side * 0.3
	_text(wf, "CAUTION", Vector3(0, 0.5, 0.14), 0.0, 36, Craft.INK, 0.003)


# --------------------------------------------------- F. baggage hall

static func _baggage_hall(root: Node3D, b: MapBuilder) -> void:
	var roller := Craft.mat(Craft.Kind.FOIL, Color(0.72, 0.73, 0.76), 0, Color.WHITE, 1.0, 0.0, false)
	# Dowel rollers at each belt end, where bags drop on and off.
	for seg in [[-10.0, 3.0], [8.0, 21.0]]:
		for end: float in [seg[0], seg[1]]:
			var dir := -1.0 if end == seg[0] else 1.0
			for k in 6:
				Craft.part(root, Craft.cylinder(0.05, 0.05, 1.5, 10), roller, Vector3(end + dir * (0.15 + k * 0.14), 0.78, -32.5), Vector3(PI * 0.5, 0, 0))
	# Sort signs over the belts.
	for spot in [[Vector3(-3.5, 3.6, -32.5), "PC 101  ORIGAMI CITY"], [Vector3(14.5, 3.6, -32.5), "PC 207  FELT FALLS"]]:
		var s := Craft.pivot(root, spot[0])
		Craft.box(s, Vector3.ZERO, Vector3(4.2, 0.6, 0.08), Craft.mat(Craft.Kind.GLOW, Color(0.08, 0.12, 0.25), 0, Color.WHITE, 1.0, 0.0))
		for side: float in [1.0, -1.0]:
			_text(s, spot[1], Vector3(0, 0, 0.045 * side), 0.0 if side > 0.0 else PI, 56, Color(1.0, 0.82, 0.3), 0.004, 0, BODY_FONT)
		for sx: float in [-1.6, 1.6]:
			Craft.box(s, Vector3(sx, 0.75, 0), Vector3(0.015, 0.9, 0.015), _m(Craft.Kind.PAPER, Color(0.2, 0.2, 0.22)))
	# Yellow felt safety lines along the walls.
	var line_m := Craft.felt_piece(Craft.YELLOW, Craft.Kind.FELT, 2, false)
	for z: float in [-27.0, -37.4]:
		Craft.box(root, Vector3(9.0, 0.045, z), Vector3(44.0, 0.012, 0.16), line_m, Vector3.ZERO, false)
	# Pallets stacked with taped boxes.
	for p: Vector3 in [Vector3(30.0, 0, -36.6), Vector3(-12.0, 0, -36.4)]:
		var pal := b.solid(p + Vector3(0, 0.07, 0), Vector3(1.2, 0.14, 1.0), _m(Craft.Kind.CARDBOARD, Craft.KRAFT))
		for k in 3:
			Craft.box(pal, Vector3(-0.4 + k * 0.4, -0.04, 0), Vector3(0.1, 0.08, 1.0), _m(Craft.Kind.CARDBOARD, Craft.KRAFT_DARK))
		for k in 4:
			Props.crate(b, p + Vector3(-0.3 + (k % 2) * 0.6, 0.14 + (k / 2) * 0.55, -0.2 + (k % 2) * 0.3), 0.5, rng.randf() * 0.3)


# ---------------------------------------------------------- G. clutter

static func _clutter(root: Node3D) -> void:
	# Crumpled paper balls.
	var ball := _crumple_mesh()
	var balls := []
	for i in 70:
		var p := Vector3(rng.randf_range(-56.0, 58.0), 0.07, rng.randf_range(-36.0, 25.0))
		balls.append(Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3.ONE * rng.randf_range(0.7, 1.3)), p))
	FeltGround._multimesh(root, ball, Craft.mat(Craft.Kind.PAPER, Color(0.95, 0.93, 0.88), 0, Color.WHITE, 1.0, 0.0, false), balls, true)
	# Paper coffee cups with lids, on seats and the floor.
	var cups := []
	var seat_x := [-52.0, -45.0, -38.0, -31.0, -24.0]
	for i in 18:
		var sx: float = seat_x[rng.randi() % seat_x.size()] + rng.randf_range(-1.6, 1.6)
		var on_seat := rng.randf() < 0.6
		var p := Vector3(sx, 0.47 if on_seat else 0.12, 15.1 if rng.randf() < 0.5 else 16.75)
		if not on_seat:
			p.z += rng.randf_range(-1.2, 1.2)
		var tip := not on_seat and rng.randf() < 0.4
		cups.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5 if tip else 0.0, rng.randf() * TAU, 0)), p))
	FeltGround._multimesh(root, Craft.cylinder(0.045, 0.035, 0.13, 12), Craft.mat(Craft.Kind.PAPER, Craft.WHITE, Craft.Pattern.BANDS, Craft.TEAL, 12.0, 0.0, false), cups, true)
	var lids := []
	for t in cups:
		var tt: Transform3D = t
		lids.append(Transform3D(tt.basis, tt.origin + tt.basis.y * 0.07))
	FeltGround._multimesh(root, Craft.cylinder(0.048, 0.048, 0.015, 12), Craft.mat(Craft.Kind.PLASTIC, Color(0.25, 0.2, 0.18), 0, Color.WHITE, 1.0, 0.0, false), lids, false)
	# Folded newspapers left on the gate seats.
	for i in 10:
		var sx: float = seat_x[rng.randi() % seat_x.size()] + rng.randf_range(-1.5, 1.5)
		var np := Craft.pivot(root, Vector3(sx, 0.42, 15.1 if i % 2 == 0 else 16.75), Vector3(0, rng.randf() * TAU, 0))
		Craft.box(np, Vector3.ZERO, Vector3(0.36, 0.02, 0.26), Craft.mat(Craft.Kind.PAPER, Color(0.92, 0.91, 0.86)), Vector3.ZERO, false)
		for k in 4:
			Craft.box(np, Vector3(-0.08 + (k % 2) * 0.16, 0.012, -0.07 + (k / 2) * 0.12), Vector3(0.13, 0.002, 0.08), Craft.mat(Craft.Kind.PAPER, Color(0.45, 0.45, 0.48)), Vector3.ZERO, false)
		Craft.box(np, Vector3(0, 0.012, -0.115), Vector3(0.32, 0.002, 0.025), Craft.mat(Craft.Kind.PAPER, Craft.INK), Vector3.ZERO, false)
	# Paper airplanes that didn't make it.
	for i in 9:
		var p := Vector3(rng.randf_range(-55.0, 55.0), 0.06, rng.randf_range(-35.0, 24.0))
		var pl := Craft.pivot(root, p, Vector3(0, rng.randf() * TAU, rng.randf_range(-0.4, 0.4)))
		var col: Color = [Craft.WHITE, Craft.PINK, Craft.YELLOW, Craft.TEAL][i % 4]
		for side: float in [-1.0, 1.0]:
			var pts := PackedVector2Array([Vector2(0, -0.22), Vector2(side * 0.15, 0.14), Vector2(0, 0.1)])
			Craft.part(pl, Craft.cutout(pts, 0.003), Craft.mat(Craft.Kind.PAPER, col, 0, Color.WHITE, 1.0, 0.0, false), Vector3.ZERO, Vector3(PI * 0.5, 0, side * 0.3))
	# Confetti bits drifted against walls and under seats.
	var bits := []
	var bit_cols := [Craft.PINK, Craft.YELLOW, Craft.TEAL, Craft.ORANGE]
	var bit_sets := [[], [], [], []]
	for i in 360:
		var near_seats := rng.randf() < 0.5
		var p := Vector3(rng.randf_range(-54.0, -22.0), 0.035, rng.randf_range(13.5, 18.5)) if near_seats else Vector3(rng.randf_range(-13.0, 58.0), 0.04, rng.randf_range(-36.0, 24.0))
		bit_sets[i % 4].append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)), p))
	var bit_mesh := Craft.unit_box()
	for i in 4:
		var scaled := []
		for t in bit_sets[i]:
			var tt: Transform3D = t
			scaled.append(Transform3D(tt.basis.scaled(Vector3(0.06, 0.003, 0.04)), tt.origin))
		FeltGround._multimesh(root, bit_mesh, Craft.mat(Craft.Kind.PAPER, bit_cols[i], 0, Color.WHITE, 1.0, 0.0, false), scaled, false)
	var _u := bits
	# Luggage tags on a few cases by the check-in queue.
	for i in 6:
		var p := Vector3(-50.0 + i * 5.5, 0, rng.randf_range(-0.2, 0.6))
		Props.luggage(MapBuilder.new(root, root), p, rng, false)
		Craft.box(root, p + Vector3(0.3, 0.55, 0.0), Vector3(0.08, 0.12, 0.004), Craft.mat(Craft.Kind.PAPER, Craft.CREAM), Vector3(0, rng.randf() * TAU, 0.3), false)


static func _crumple_mesh() -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 5
	var segs := 7
	var pts := []
	for i in rings + 1:
		var row := []
		var phi := PI * i / rings
		for j in segs:
			var th := TAU * j / segs
			var n := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			row.append(n * 0.07 * r.randf_range(0.7, 1.2))
		pts.append(row)
	for i in rings:
		for j in segs:
			var j1 := (j + 1) % segs
			var q := [pts[i][j], pts[i + 1][j], pts[i + 1][j1], pts[i][j], pts[i + 1][j1], pts[i][j1]]
			for t in range(0, 6, 3):
				var a: Vector3 = q[t]
				var b: Vector3 = q[t + 1]
				var c: Vector3 = q[t + 2]
				var n := (b - a).cross(c - a).normalized()
				if n.dot(a + b + c) < 0.0:
					n = -n
				Craft._tri(st, a, b, c, n, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	return st.commit()
