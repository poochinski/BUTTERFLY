class_name Props
extends RefCounted
## Reusable papercraft props. Every function takes a MapBuilder and places a
## prop with collision where it should block movement and bullets.

static func luggage(b: MapBuilder, pos: Vector3, rng: RandomNumberGenerator, solid := true) -> void:
	var cols := [Color(0.18, 0.19, 0.21), Color(0.24, 0.25, 0.28), Craft.BLUE, Color(0.36, 0.2, 0.2), Color(0.3, 0.36, 0.32), Color(0.45, 0.4, 0.34), Craft.SLATE, Color(0.3, 0.3, 0.32)]
	var col: Color = cols[rng.randi() % cols.size()]
	var size := Vector3(rng.randf_range(0.45, 0.8), rng.randf_range(0.35, 0.7), rng.randf_range(0.25, 0.4))
	var yaw := rng.randf() * TAU
	var kind := Craft.Kind.FELT if rng.randf() < 0.5 else Craft.Kind.CARDBOARD
	var m := Craft.mat(kind, col, Craft.Pattern.STITCH if kind == Craft.Kind.FELT else 0, Craft.CREAM)
	var p := pos + Vector3(0, size.y * 0.5, 0)
	var node: Node3D
	if solid:
		node = b.solid(p, size, m, yaw)
	else:
		node = Craft.pivot(b.deco_root, p, Vector3(0, yaw, 0))
		Craft.box(node, Vector3.ZERO, size, m)
	var handle := Craft.mat(Craft.Kind.PLASTIC, Color(0.15, 0.15, 0.15), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.part(node, Craft.cylinder(0.02, 0.02, size.x * 0.5, 6), handle, Vector3(0, size.y * 0.5 + 0.04, 0), Vector3(0, 0, PI * 0.5))


static func bench(b: MapBuilder, pos: Vector3, yaw: float, seats := 4) -> void:
	var w := seats * 0.6
	var frame := Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.72, 0.75))
	var cushion := Craft.mat(Craft.Kind.FELT, Color(0.26, 0.28, 0.32), Craft.Pattern.STITCH, Color(0.42, 0.44, 0.48))
	var dir := Vector3(cos(yaw), 0, -sin(yaw))
	var body := b.solid(pos + Vector3(0, 0.25, 0), Vector3(w, 0.5, 0.6), cushion, yaw)
	Craft.box(body, Vector3(0, 0.45, 0.27), Vector3(w, 0.5, 0.08), cushion)
	Craft.box(body, Vector3(0, -0.2, 0), Vector3(w + 0.05, 0.08, 0.5), frame)
	for i in seats - 1:
		var x := -w * 0.5 + 0.6 * (i + 1)
		Craft.box(body, Vector3(x, 0.32, 0), Vector3(0.05, 0.18, 0.55), frame)


static func counter(b: MapBuilder, pos: Vector3, length: float, yaw: float, top_col: Color, body_col: Color) -> void:
	var body := b.solid(pos + Vector3(0, 0.55, 0), Vector3(length, 1.1, 0.9), Craft.mat(Craft.Kind.CARDBOARD, body_col, Craft.Pattern.BANDS, body_col.lightened(0.2), 2.0), yaw)
	Craft.box(body, Vector3(0, 0.58, 0), Vector3(length + 0.1, 0.06, 1.0), Craft.mat(Craft.Kind.PAPER, top_col))
	# Little paper monitors on top.
	var screen := Craft.mat(Craft.Kind.GLOW, Color(0.42, 0.52, 0.6))
	var dark := Craft.mat(Craft.Kind.PAPER, Color(0.2, 0.2, 0.22))
	var n := int(length / 1.6)
	for i in n:
		var x := -length * 0.5 + 0.8 + i * 1.6
		Craft.box(body, Vector3(x, 0.8, 0.15), Vector3(0.45, 0.32, 0.05), dark)
		Craft.box(body, Vector3(x, 0.8, 0.12), Vector3(0.38, 0.26, 0.02), screen)


static func baggage_cart(b: MapBuilder, pos: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var frame := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.4, 0.46))
	var bed := b.solid(pos + Vector3(0, 0.45, 0), Vector3(2.6, 0.12, 1.5), frame, yaw)
	var wheel := Craft.mat(Craft.Kind.PLASTIC, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			Craft.part(bed, Craft.cylinder(0.22, 0.22, 0.12, 14), wheel, Vector3(sx * 0.95, -0.25, sz * 0.7), Vector3(PI * 0.5, 0, 0))
	# Rails and a canopy, like the reference airport carts.
	var rail := Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW)
	Craft.box(bed, Vector3(-1.25, 0.5, 0), Vector3(0.08, 1.0, 1.5), rail)
	Craft.box(bed, Vector3(1.25, 0.5, 0), Vector3(0.08, 1.0, 1.5), rail)
	Craft.box(bed, Vector3(0, 1.05, 0), Vector3(2.7, 0.06, 1.6), Craft.mat(Craft.Kind.FELT, Color(0.3, 0.31, 0.33), Craft.Pattern.STITCH, Color(0.45, 0.46, 0.48)))
	for i in rng.randi_range(2, 4):
		var p := Vector3(rng.randf_range(-0.8, 0.8), 0.06, rng.randf_range(-0.45, 0.45))
		var w := (bed.global_transform * p) if bed.is_inside_tree() else pos + Vector3(0, 0.51, 0) + p.rotated(Vector3.UP, yaw)
		luggage(b, Vector3(w.x, pos.y + 0.51, w.z), rng, false)


static func container(b: MapBuilder, pos: Vector3, yaw: float, col: Color, label_col := Craft.CREAM) -> void:
	# Airline cargo "can": a box with a slanted top corner.
	var m := Craft.mat(Craft.Kind.CARDBOARD, col, Craft.Pattern.BANDS, col.darkened(0.12), 1.2)
	var body := b.solid(pos + Vector3(0, 0.8, 0), Vector3(2.0, 1.6, 1.55), m, yaw)
	var slant := Craft.box(body, Vector3(0, 0.58, 0.62), Vector3(1.98, 0.62, 0.62), m)
	slant.rotation.x = -0.6
	Craft.box(body, Vector3(0, 0.05, -0.79), Vector3(1.2, 0.5, 0.02), Craft.mat(Craft.Kind.PAPER, label_col))
	Craft.box(body, Vector3(0, 0.05, -0.8), Vector3(0.8, 0.12, 0.02), Craft.mat(Craft.Kind.PAPER, Craft.INK))


static func crate(b: MapBuilder, pos: Vector3, size: float, yaw: float, col := Craft.KRAFT) -> StaticBody3D:
	var m := Craft.mat(Craft.Kind.CARDBOARD, col)
	var body := b.solid(pos + Vector3(0, size * 0.5, 0), Vector3(size, size, size), m, yaw)
	# Hand-placed: never quite square.
	body.rotation.x = randf_range(-0.025, 0.025)
	body.rotation.z = randf_range(-0.025, 0.025)
	var tape := Craft.mat(Craft.Kind.TAPE, Color(0.86, 0.8, 0.64))
	# Top flaps: usually taped shut, sometimes popped open.
	var open := randf() < 0.3
	for side: float in [-1.0, 1.0]:
		var hinge := Craft.pivot(body, Vector3(side * size * 0.5, size * 0.5, 0))
		hinge.rotation.z = side * (1.9 if open else 0.0)
		Craft.box(hinge, Vector3(-side * size * 0.25, 0.006, 0), Vector3(size * 0.5, 0.012, size * 0.98), m)
	if not open:
		Craft.box(body, Vector3(0, size * 0.5 + 0.014, 0), Vector3(size * 0.18, 0.004, size + 0.004), tape)
	Craft.box(body, Vector3(0, 0, size * 0.5 + 0.002), Vector3(size * 0.18, size + 0.004, 0.004), tape)
	# A printed "this way up" arrow.
	var arrow := Craft.cutout(PackedVector2Array([Vector2(-0.06, -0.12), Vector2(0.06, -0.12), Vector2(0.06, 0.02), Vector2(0.12, 0.02), Vector2(0, 0.14), Vector2(-0.12, 0.02), Vector2(-0.06, 0.02)]), 0.004)
	Craft.part(body, arrow, Craft.mat(Craft.Kind.PAPER, Craft.INK, 0, Color.WHITE, 1.0, 0.0, false), Vector3(size * 0.25, 0, size * 0.5 + 0.004), Vector3.ZERO, Vector3.ONE * size, false)
	return body


static func barrier(b: MapBuilder, pos: Vector3, yaw: float, length := 2.0) -> void:
	var m := Craft.mat(Craft.Kind.CARDBOARD, Craft.ORANGE, Craft.Pattern.HAZARD, Craft.WHITE, 1.4)
	var body := b.solid(pos + Vector3(0, 0.45, 0), Vector3(length, 0.9, 0.45), m, yaw)
	Craft.box(body, Vector3(0, -0.4, 0), Vector3(length, 0.12, 0.7), Craft.mat(Craft.Kind.CARDBOARD, Craft.WHITE))


static func cone(b: MapBuilder, pos: Vector3) -> void:
	var m := Craft.mat(Craft.Kind.FELT, Craft.ORANGE, 0, Color.WHITE, 1.0, 0.0, false)
	var stripe := Craft.mat(Craft.Kind.FELT, Craft.WHITE, 0, Color.WHITE, 1.0, 0.0, false)
	Craft.part(b.deco_root, Craft.cylinder(0.04, 0.2, 0.6, 12), m, pos + Vector3(0, 0.32, 0))
	Craft.part(b.deco_root, Craft.cylinder(0.105, 0.135, 0.1, 12), stripe, pos + Vector3(0, 0.36, 0))
	Craft.box(b.deco_root, pos + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5), Craft.mat(Craft.Kind.CARDBOARD, Craft.ORANGE))


static func pillar(b: MapBuilder, pos: Vector3, height: float, col: Color) -> void:
	var m := Craft.mat(Craft.Kind.CARDBOARD, col, Craft.Pattern.BANDS, col.lightened(0.15), 0.8)
	b.solid(pos + Vector3(0, height * 0.5, 0), Vector3(0.9, height, 0.9), m)


static func planter(b: MapBuilder, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var pot := b.solid(pos + Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 1.2), Craft.mat(Craft.Kind.CARDBOARD, Craft.CONCRETE_DARK))
	var leaf := Craft.mat(Craft.Kind.FELT, Craft.GRASS, 0, Color.WHITE, 1.0, 0.0, false)
	for i in 5:
		var pts := Craft.blob_points(0.35, 0.25, 12, rng.randi())
		var l := Craft.part(pot, Craft.cutout(pts, 0.02), leaf, Vector3(rng.randf_range(-0.2, 0.2), 0.75 + rng.randf() * 0.4, rng.randf_range(-0.2, 0.2)), Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, 0))
		l.scale = Vector3(1, 1.4, 1)


static func truck(b: MapBuilder, pos: Vector3, yaw: float, body_col: Color, tank := false) -> void:
	var paint := Craft.mat(Craft.Kind.CARDBOARD, body_col)
	var dark := Craft.mat(Craft.Kind.PAPER, Color(0.2, 0.2, 0.24))
	var glass := Craft.mat(Craft.Kind.PAPER, Color(0.32, 0.4, 0.46))
	var root := b.solid(pos + Vector3(0, 1.2, 0), Vector3(2.4, 1.6, 6.5), paint, yaw)
	Craft.box(root, Vector3(0, -0.85, 0), Vector3(2.2, 0.3, 6.4), dark)
	Craft.box(root, Vector3(0, 0.55, -2.6), Vector3(2.3, 0.7, 1.1), paint)
	Craft.box(root, Vector3(0, 0.55, -3.16), Vector3(1.9, 0.5, 0.02), glass)
	if tank:
		var tank_m := Craft.mat(Craft.Kind.FOIL, Color(0.85, 0.86, 0.88), 0, Color.WHITE, 1.0, 1.0, false)
		Craft.part(root, Craft.cylinder(1.05, 1.05, 4.6, 20), tank_m, Vector3(0, 0.75, 0.75), Vector3(PI * 0.5, 0, 0))
		Craft.box(root, Vector3(0, 0.75, 0.75), Vector3(2.2, 0.25, 4.0), Craft.mat(Craft.Kind.TAPE, Color(0.6, 0.62, 0.64)))
	var wheel := Craft.mat(Craft.Kind.PLASTIC, Color(0.1, 0.1, 0.11), 0, Color.WHITE, 1.0, 0.0, false)
	var hub := Craft.mat(Craft.Kind.PLASTIC, Color(0.55, 0.56, 0.58), 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		for z: float in [-2.2, 1.8]:
			Craft.part(root, Craft.cylinder(0.5, 0.5, 0.35, 18), wheel, Vector3(sx * 1.1, -0.85, z), Vector3(0, 0, PI * 0.5))
			Craft.part(root, Craft.cylinder(0.22, 0.22, 0.37, 12), hub, Vector3(sx * 1.1, -0.85, z), Vector3(0, 0, PI * 0.5))


static func paper_tree(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator) -> void:
	# Paper Mario style: layered cut-out canopy discs on a cardboard trunk.
	var trunk := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.29, 0.22), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.part(parent, Craft.cylinder(0.25 * scale, 0.35 * scale, 3.0 * scale, 10), trunk, pos + Vector3(0, 1.5 * scale, 0))
	var greens := [Color(0.24, 0.34, 0.2), Color(0.3, 0.4, 0.22), Color(0.22, 0.3, 0.19)]
	for i in 3:
		var pts := Craft.blob_points(1.6 * scale * (1.0 - i * 0.15), 0.18, 20, rng.randi())
		var m := Craft.mat(Craft.Kind.PAPER, greens[i], Craft.Pattern.DOTS, Color(0.36, 0.44, 0.25), 0.6, 1.0, false)
		var y := (3.2 + i * 0.7) * scale
		for k in 2:
			Craft.part(parent, Craft.cutout(pts, 0.04), m, pos + Vector3(0, y, 0), Vector3(0, k * PI * 0.5 + i * 0.4, 0))


# ------------------------------------------------------------ revamp props

## Airport gate seating: a row of linked seats with armrests on a beam.
static func gate_seats(b: MapBuilder, pos: Vector3, yaw: float, seats: int, col: Color) -> void:
	var w := seats * 0.62
	var frame := Craft.mat(Craft.Kind.FOIL, Color(0.72, 0.74, 0.78), 0, Color.WHITE, 1.0, 0.0, true)
	var cushion := Craft.mat(Craft.Kind.FELT, col, Craft.Pattern.STITCH, Craft.CREAM)
	var body := b.solid(pos + Vector3(0, 0.25, 0), Vector3(w, 0.5, 0.62), null, yaw)
	Craft.box(body, Vector3(0, -0.02, 0), Vector3(w + 0.1, 0.06, 0.12), frame)
	for leg: float in [-w * 0.4, w * 0.4]:
		Craft.box(body, Vector3(leg, -0.15, 0), Vector3(0.08, 0.2, 0.5), frame)
	for i in seats:
		var x := -w * 0.5 + 0.31 + i * 0.62
		Craft.box(body, Vector3(x, 0.08, 0.0), Vector3(0.52, 0.12, 0.5), cushion)
		Craft.box(body, Vector3(x, 0.42, 0.24), Vector3(0.52, 0.56, 0.1), cushion, Vector3(-0.12, 0, 0))
		Craft.box(body, Vector3(x - 0.31, 0.22, 0.02), Vector3(0.05, 0.05, 0.44), frame)
		Craft.box(body, Vector3(x - 0.31, 0.11, 0.18), Vector3(0.05, 0.22, 0.05), frame)
	Craft.box(body, Vector3(w * 0.5, 0.22, 0.02), Vector3(0.05, 0.05, 0.44), frame)


static func vending(b: MapBuilder, pos: Vector3, yaw: float, col: Color, rng: RandomNumberGenerator) -> void:
	var body := b.solid(pos + Vector3(0, 1.0, 0), Vector3(1.1, 2.0, 0.8), Craft.mat(Craft.Kind.CARDBOARD, col), yaw)
	Craft.box(body, Vector3(-0.12, 0.15, -0.41), Vector3(0.72, 1.4, 0.02), Craft.mat(Craft.Kind.GLOW, Color(0.62, 0.68, 0.72), 0, Color.WHITE, 1.0, 0.0, true))
	var caps := [Craft.RED, Craft.YELLOW, Craft.GRASS, Craft.ORANGE, Craft.PINK, Craft.BLUE]
	for row in 4:
		for colm in 4:
			Craft.part(body, Craft.cylinder(0.05, 0.05, 0.16, 8), Craft.mat(Craft.Kind.PLASTIC, caps[(row * 4 + colm + rng.randi()) % caps.size()], 0, Color.WHITE, 1.0, 0.0, false), Vector3(-0.4 + colm * 0.18, 0.65 - row * 0.32, -0.43))
	Craft.box(body, Vector3(0.38, 0.3, -0.41), Vector3(0.22, 0.5, 0.03), Craft.mat(Craft.Kind.PAPER, Color(0.25, 0.25, 0.28)))
	Craft.box(body, Vector3(0, -0.75, -0.41), Vector3(0.8, 0.22, 0.03), Craft.mat(Craft.Kind.PAPER, Color(0.15, 0.15, 0.17)))
	Craft.box(body, Vector3(0, 0.95, -0.41), Vector3(1.0, 0.2, 0.03), Craft.mat(Craft.Kind.PAPER, Craft.CREAM, Craft.Pattern.DOTS, col, 2.0))


static func trash_bin(b: MapBuilder, pos: Vector3, col: Color) -> void:
	var body := b.column(pos, 0.32, 0.95, Craft.mat(Craft.Kind.CARDBOARD, col, Craft.Pattern.BANDS, col.darkened(0.2), 6.0, 1.0, false))
	Craft.part(body, Craft.cylinder(0.36, 0.36, 0.08, 18), Craft.mat(Craft.Kind.PLASTIC, Color(0.25, 0.25, 0.28), 0, Color.WHITE, 1.0, 0.0, false), Vector3(0, 0.5, 0))


## Queue stanchions joined by felt ropes.
static func stanchions(parent: Node3D, pts: Array) -> void:
	var post := Craft.mat(Craft.Kind.FOIL, Color(0.72, 0.73, 0.75), 0, Color.WHITE, 1.0, 0.0, false)
	var rope := Craft.mat(Craft.Kind.FELT, Color(0.2, 0.22, 0.26), 0, Color.WHITE, 1.0, 0.0, false)
	for i in pts.size():
		var p: Vector3 = pts[i]
		Craft.part(parent, Craft.cylinder(0.03, 0.03, 0.95, 8), post, p + Vector3(0, 0.48, 0))
		Craft.part(parent, Craft.cylinder(0.16, 0.18, 0.04, 14), post, p + Vector3(0, 0.02, 0))
		Craft.part(parent, Craft.sphere(0.05, 8), post, p + Vector3(0, 0.97, 0))
		if i > 0:
			var q: Vector3 = pts[i - 1]
			for k in 6:
				var t0 := float(k) / 6.0
				var t1 := float(k + 1) / 6.0
				var sag := func(t: float) -> Vector3: return q.lerp(p, t) + Vector3(0, 0.9 - 0.18 * 4.0 * t * (1.0 - t), 0)
				var a: Vector3 = sag.call(t0)
				var c: Vector3 = sag.call(t1)
				var seg := Craft.box(parent, (a + c) * 0.5, Vector3.ONE, rope, Vector3.ZERO, false)
				seg.look_at_from_position((a + c) * 0.5, c, Vector3.UP)
				seg.scale = Vector3(0.04, 0.04, a.distance_to(c) + 0.01)


static func potted_tree(b: MapBuilder, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var pot := b.column(pos, 0.6, 0.9, Craft.mat(Craft.Kind.CARDBOARD, Color(0.3, 0.31, 0.33), 0, Color.WHITE, 1.0, 0.0, false))
	Craft.part(pot, Craft.cylinder(0.56, 0.56, 0.06, 18), Craft.mat(Craft.Kind.FELT, Color(0.35, 0.25, 0.18), 0, Color.WHITE, 1.0, 0.0, false), Vector3(0, 0.43, 0))
	Props.paper_tree(b.deco_root, pos + Vector3(0, 0.45, 0), 0.75, rng)


static func info_screen(parent: Node3D, pos: Vector3, yaw: float, lines: Array) -> void:
	var root := Craft.pivot(parent, pos, Vector3(0, yaw, 0))
	var frame := Craft.mat(Craft.Kind.CARDBOARD, Color(0.25, 0.26, 0.3))
	Craft.box(root, Vector3(0, 0.9, 0), Vector3(0.12, 1.8, 0.12), frame)
	Craft.box(root, Vector3(0, 0.03, 0), Vector3(0.7, 0.06, 0.5), frame)
	Craft.box(root, Vector3(0, 2.1, 0), Vector3(1.5, 0.95, 0.12), frame)
	Craft.box(root, Vector3(0, 2.1, 0.065), Vector3(1.38, 0.83, 0.01), Craft.mat(Craft.Kind.GLOW, Color(0.12, 0.2, 0.42), 0, Color.WHITE, 1.0, 0.0, true))
	for i in lines.size():
		var l := Label3D.new()
		l.text = lines[i]
		l.font = preload("res://assets/fonts/Fredoka.ttf")
		l.font_size = 40
		l.pixel_size = 0.0045
		l.modulate = Color(0.95, 0.78, 0.3) if i == 0 else Color(0.86, 0.88, 0.9)
		l.outline_size = 0
		l.position = Vector3(0, 2.4 - i * 0.2, 0.075)
		root.add_child(l)


## A striped felt awning over a shop front, facing +Z after yaw.
static func awning(parent: Node3D, pos: Vector3, yaw: float, width: float, col: Color) -> void:
	var root := Craft.pivot(parent, pos, Vector3(0, yaw, 0))
	var m := Craft.mat(Craft.Kind.FELT, col, Craft.Pattern.BANDS, Craft.CREAM, 3.0)
	var sheet := Craft.box(root, Vector3(0, 0, 0.45), Vector3(width, 0.04, 1.0), Craft.mat(Craft.Kind.FELT, col, 0, Color.WHITE, 1.0, 0.0), Vector3(0.45, 0, 0))
	sheet.scale = Vector3(width, 0.04, 1.0)
	var n := int(width / 0.5)
	for i in n:
		if i % 2 == 0:
			Craft.box(root, Vector3(-width * 0.5 + (i + 0.5) * width / n, 0.005, 0.45), Vector3(width / n, 0.045, 1.0), Craft.mat(Craft.Kind.FELT, Craft.CREAM, 0, Color.WHITE, 1.0, 0.0), Vector3(0.45, 0, 0))
	for i in n:
		var x := -width * 0.5 + (i + 0.5) * width / n
		var pts := PackedVector2Array([Vector2(-width / n * 0.5, 0), Vector2(width / n * 0.5, 0), Vector2(0, -0.16)])
		Craft.part(root, Craft.cutout(pts, 0.01), Craft.mat(Craft.Kind.FELT, col if i % 2 == 0 else Craft.CREAM, 0, Color.WHITE, 1.0, 0.0, false), Vector3(x, -0.4, 0.88))
	var _u := m


static func rug(parent: Node3D, center: Vector3, size: Vector2, col: Color, yaw := 0.0) -> void:
	Craft.box(parent, center + Vector3(0, 0.025, 0), Vector3(size.x, 0.02, size.y), Craft.mat(Craft.Kind.FELT, col, Craft.Pattern.STITCH, Craft.CREAM, 2.0), Vector3(0, yaw, 0), false)


## Ground power unit on wheels.
static func gpu_cart(b: MapBuilder, pos: Vector3, yaw: float) -> void:
	var body := b.solid(pos + Vector3(0, 0.75, 0), Vector3(1.4, 1.1, 2.2), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW), yaw)
	Craft.box(body, Vector3(0, 0.0, -1.11), Vector3(1.1, 0.7, 0.02), Craft.mat(Craft.Kind.PAPER, Color(0.25, 0.26, 0.3)))
	Craft.box(body, Vector3(0, 0.56, 0), Vector3(1.5, 0.06, 2.3), Craft.mat(Craft.Kind.CARDBOARD, Craft.INK, Craft.Pattern.HAZARD, Craft.YELLOW, 2.0))
	var wheel := Craft.mat(Craft.Kind.PLASTIC, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		for z: float in [-0.7, 0.7]:
			Craft.part(body, Craft.cylinder(0.24, 0.24, 0.16, 14), wheel, Vector3(sx * 0.72, -0.52, z), Vector3(0, 0, PI * 0.5))
	var cable := Craft.mat(Craft.Kind.KNIT, Color(0.15, 0.15, 0.17), 0, Color.WHITE, 3.0, 0.0, false)
	Craft.part(body, Craft.capsule(0.05, 1.6), cable, Vector3(0.5, 0.4, -1.6), Vector3(1.1, 0, 0.3))


## Belt loader: an inclined conveyor on a little truck.
static func belt_loader(b: MapBuilder, pos: Vector3, yaw: float, rise: float) -> void:
	var truck := b.solid(pos + Vector3(0, 0.55, 0), Vector3(1.6, 0.7, 4.0), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW), yaw)
	var belt := Craft.mat(Craft.Kind.CARDBOARD, Color(0.22, 0.23, 0.26), Craft.Pattern.BANDS, Color(0.32, 0.33, 0.36), 8.0)
	var length := 5.5
	var pitch := asin(clampf(rise / length, 0.0, 0.9))
	var beltn := Craft.box(truck, Vector3(0, 0.5 + rise * 0.5, -0.4), Vector3(0.9, 0.12, length), belt, Vector3(pitch, 0, 0))
	beltn.rotation.x = pitch
	for side: float in [-1.0, 1.0]:
		Craft.box(truck, Vector3(side * 0.5, 0.62 + rise * 0.5, -0.4), Vector3(0.06, 0.18, length), Craft.mat(Craft.Kind.FOIL, Color(0.8, 0.8, 0.82)), Vector3(pitch, 0, 0))
	var wheel := Craft.mat(Craft.Kind.PLASTIC, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		for z: float in [-1.4, 1.4]:
			Craft.part(truck, Craft.cylinder(0.3, 0.3, 0.2, 14), wheel, Vector3(sx * 0.82, -0.25, z), Vector3(0, 0, PI * 0.5))


static func chocks(parent: Node3D, pos: Vector3) -> void:
	var m := Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW, Craft.Pattern.HAZARD, Craft.INK, 3.0)
	for z: float in [-0.75, 0.75]:
		Craft.box(parent, pos + Vector3(0, 0.12, z), Vector3(0.5, 0.24, 0.22), m)


## Floodlight mast with a crossbar of lamp heads.
static func light_mast(b: MapBuilder, pos: Vector3, height: float, yaw := 0.0) -> void:
	var pole := Craft.mat(Craft.Kind.CARDBOARD, Color(0.6, 0.62, 0.68), Craft.Pattern.BANDS, Color(0.5, 0.52, 0.58), 2.0, 1.0, false)
	b.column(pos, 0.22, height, pole)
	var head := Craft.pivot(b.deco_root, pos + Vector3(0, height, 0), Vector3(0, yaw, 0))
	Craft.box(head, Vector3.ZERO, Vector3(2.4, 0.16, 0.16), Craft.mat(Craft.Kind.CARDBOARD, Color(0.45, 0.47, 0.52)))
	for x: float in [-0.9, -0.3, 0.3, 0.9]:
		Craft.box(head, Vector3(x, 0.32, 0), Vector3(0.5, 0.42, 0.22), Craft.mat(Craft.Kind.CARDBOARD, Color(0.45, 0.47, 0.52)))
		Craft.box(head, Vector3(x, 0.32, -0.115), Vector3(0.42, 0.34, 0.01), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.95, 0.82), 0, Color.WHITE, 1.0, 0.0, true))
	Craft.box(b.deco_root, pos + Vector3(0, 1.0, 0.25), Vector3(0.4, 0.6, 0.12), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW, Craft.Pattern.HAZARD, Craft.INK, 3.0))


static func tug(b: MapBuilder, pos: Vector3, yaw: float) -> void:
	var body := b.solid(pos + Vector3(0, 0.6, 0), Vector3(1.6, 0.8, 2.6), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW), yaw)
	Craft.box(body, Vector3(0, 0.7, 0.4), Vector3(1.3, 0.7, 1.1), Craft.mat(Craft.Kind.CARDBOARD, Color(0.3, 0.31, 0.33)))
	Craft.box(body, Vector3(0, 0.75, -0.16), Vector3(1.2, 0.5, 0.02), Craft.mat(Craft.Kind.PAPER, Color(0.32, 0.4, 0.46)))
	var wheel := Craft.mat(Craft.Kind.PLASTIC, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		for z: float in [-0.85, 0.85]:
			Craft.part(body, Craft.cylinder(0.32, 0.32, 0.26, 14), wheel, Vector3(sx * 0.8, -0.3, z), Vector3(0, 0, PI * 0.5))
	Craft.part(body, Craft.sphere(0.1, 8), Craft.mat(Craft.Kind.GLOW, Craft.ORANGE, 0, Color.WHITE, 1.0, 0.0, false), Vector3(0, 1.12, 0.4))
