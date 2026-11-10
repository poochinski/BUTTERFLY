class_name Props
extends RefCounted
## Reusable papercraft props. Every function takes a MapBuilder and places a
## prop with collision where it should block movement and bullets.

static func luggage(b: MapBuilder, pos: Vector3, rng: RandomNumberGenerator, solid := true) -> void:
	var cols := [Craft.RED, Craft.TEAL, Craft.PURPLE, Craft.ORANGE, Craft.YELLOW, Craft.PINK, Craft.BLUE, Color(0.3, 0.3, 0.32)]
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
	var cushion := Craft.mat(Craft.Kind.FELT, Craft.TEAL, Craft.Pattern.STITCH, Craft.CREAM)
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
	var screen := Craft.mat(Craft.Kind.GLOW, Color(0.55, 0.85, 0.95))
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
	Craft.box(bed, Vector3(0, 1.05, 0), Vector3(2.7, 0.06, 1.6), Craft.mat(Craft.Kind.FELT, Craft.ORANGE, Craft.Pattern.STITCH, Craft.CREAM))
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
	var tape := Craft.mat(Craft.Kind.TAPE, Color(0.93, 0.86, 0.66))
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
	var pot := b.solid(pos + Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 1.2), Craft.mat(Craft.Kind.KNIT, Craft.TEAL))
	var leaf := Craft.mat(Craft.Kind.FELT, Craft.GRASS, 0, Color.WHITE, 1.0, 0.0, false)
	for i in 5:
		var pts := Craft.blob_points(0.35, 0.25, 12, rng.randi())
		var l := Craft.part(pot, Craft.cutout(pts, 0.02), leaf, Vector3(rng.randf_range(-0.2, 0.2), 0.75 + rng.randf() * 0.4, rng.randf_range(-0.2, 0.2)), Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, 0))
		l.scale = Vector3(1, 1.4, 1)


static func truck(b: MapBuilder, pos: Vector3, yaw: float, body_col: Color, tank := false) -> void:
	var paint := Craft.mat(Craft.Kind.CARDBOARD, body_col)
	var dark := Craft.mat(Craft.Kind.PAPER, Color(0.2, 0.2, 0.24))
	var glass := Craft.mat(Craft.Kind.PAPER, Color(0.55, 0.8, 0.9))
	var root := b.solid(pos + Vector3(0, 1.2, 0), Vector3(2.4, 1.6, 6.5), paint, yaw)
	Craft.box(root, Vector3(0, -0.85, 0), Vector3(2.2, 0.3, 6.4), dark)
	Craft.box(root, Vector3(0, 0.55, -2.6), Vector3(2.3, 0.7, 1.1), paint)
	Craft.box(root, Vector3(0, 0.55, -3.16), Vector3(1.9, 0.5, 0.02), glass)
	if tank:
		var tank_m := Craft.mat(Craft.Kind.FOIL, Color(0.85, 0.86, 0.88), 0, Color.WHITE, 1.0, 1.0, false)
		Craft.part(root, Craft.cylinder(1.05, 1.05, 4.6, 20), tank_m, Vector3(0, 0.75, 0.75), Vector3(PI * 0.5, 0, 0))
		Craft.box(root, Vector3(0, 0.75, 0.75), Vector3(2.2, 0.25, 4.0), Craft.mat(Craft.Kind.TAPE, Craft.RED))
	var wheel := Craft.mat(Craft.Kind.PLASTIC, Color(0.1, 0.1, 0.11), 0, Color.WHITE, 1.0, 0.0, false)
	var hub := Craft.mat(Craft.Kind.PLASTIC, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		for z: float in [-2.2, 1.8]:
			Craft.part(root, Craft.cylinder(0.5, 0.5, 0.35, 18), wheel, Vector3(sx * 1.1, -0.85, z), Vector3(0, 0, PI * 0.5))
			Craft.part(root, Craft.cylinder(0.22, 0.22, 0.37, 12), hub, Vector3(sx * 1.1, -0.85, z), Vector3(0, 0, PI * 0.5))


static func paper_tree(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator) -> void:
	# Paper Mario style: layered cut-out canopy discs on a cardboard trunk.
	var trunk := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.38, 0.24), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.part(parent, Craft.cylinder(0.25 * scale, 0.35 * scale, 3.0 * scale, 10), trunk, pos + Vector3(0, 1.5 * scale, 0))
	var greens := [Color(0.3, 0.62, 0.32), Color(0.38, 0.7, 0.36), Color(0.26, 0.55, 0.3)]
	for i in 3:
		var pts := Craft.blob_points(1.6 * scale * (1.0 - i * 0.15), 0.18, 20, rng.randi())
		var m := Craft.mat(Craft.Kind.PAPER, greens[i], Craft.Pattern.DOTS, Color(0.55, 0.82, 0.4), 0.6, 1.0, false)
		var y := (3.2 + i * 0.7) * scale
		for k in 2:
			Craft.part(parent, Craft.cutout(pts, 0.04), m, pos + Vector3(0, y, 0), Vector3(0, k * PI * 0.5 + i * 0.4, 0))
