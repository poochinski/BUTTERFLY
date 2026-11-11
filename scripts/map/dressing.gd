class_name Dressing
extends RefCounted
## Set dressing: the little hand-made touches that make a craft world feel
## lived in. Bunting, string lights, taped-up posters, Paper Mario style
## cut-out grass and flowers, hanging felt signs. Visual only, no collision.


static func _paper(col: Color) -> Material:
	return Craft.mat(Craft.Kind.PAPER, col, 0, Color.WHITE, 1.0, 0.0, false)


## A sagging string of triangle flags between two points.
static func bunting(parent: Node3D, a: Vector3, b: Vector3, sag: float, rng: RandomNumberGenerator, colors: Array = []) -> void:
	if colors.is_empty():
		colors = [Craft.PINK, Craft.YELLOW, Craft.TEAL, Craft.ORANGE, Craft.PURPLE, Craft.GRASS]
	var string_m := _paper(Color(0.95, 0.93, 0.88))
	var len := a.distance_to(b)
	var segs := maxi(int(len / 0.7), 4)
	var pts: Array[Vector3] = []
	for i in segs + 1:
		var t := float(i) / segs
		pts.append(a.lerp(b, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0))
	var flag := Craft.cutout(PackedVector2Array([Vector2(-0.22, 0), Vector2(0.22, 0), Vector2(0, -0.42)]), 0.006)
	var dir := (b - a).normalized()
	var yaw := atan2(-dir.x, -dir.z) + PI * 0.5
	for i in segs:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var seg := Craft.box(parent, (p0 + p1) * 0.5, Vector3(0.015, 0.015, p0.distance_to(p1)), string_m, Vector3.ZERO, false)
		seg.look_at_from_position((p0 + p1) * 0.5, p1, Vector3.UP)
		seg.scale = Vector3(0.015, 0.015, p0.distance_to(p1))
		var col: Color = colors[i % colors.size()]
		var f := Craft.part(parent, flag, _paper(col), (p0 + p1) * 0.5, Vector3(rng.randf_range(-0.12, 0.12), yaw, rng.randf_range(-0.08, 0.08)), Vector3.ONE, false)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Glowing paper-bead lights on a sagging wire.
static func string_lights(parent: Node3D, a: Vector3, b: Vector3, sag: float, warm := true) -> void:
	var wire := _paper(Color(0.2, 0.18, 0.16))
	var len := a.distance_to(b)
	var n := maxi(int(len / 0.9), 3)
	var cols := [Color(1.0, 0.85, 0.5), Color(1.0, 0.6, 0.55), Color(0.7, 0.9, 1.0), Color(0.8, 1.0, 0.6)]
	var prev := a
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0)
		if i > 0:
			var seg := Craft.box(parent, (prev + p) * 0.5, Vector3.ONE, wire, Vector3.ZERO, false)
			seg.look_at_from_position((prev + p) * 0.5, p, Vector3.UP)
			seg.scale = Vector3(0.012, 0.012, prev.distance_to(p))
		var c: Color = Color(1.0, 0.86, 0.55) if warm else cols[i % cols.size()]
		Craft.part(parent, Craft.sphere(0.06, 8), Craft.mat(Craft.Kind.GLOW, c, 0, Color.WHITE, 1.0, 0.0, false), p + Vector3(0, -0.07, 0), Vector3.ZERO, Vector3(1, 1.3, 1), false)
		prev = p


## A printed paper poster taped to a wall. yaw: direction the poster faces.
static func poster(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, rng: RandomNumberGenerator, title := "") -> void:
	var root := Craft.pivot(parent, pos, Vector3(0, yaw, rng.randf_range(-0.05, 0.05)))
	var bgs := [Craft.CREAM, Craft.WHITE, Craft.BLUE, Color(0.24, 0.26, 0.3), Color(0.62, 0.66, 0.68)]
	var bg: Color = bgs[rng.randi() % bgs.size()]
	Craft.box(root, Vector3.ZERO, Vector3(size.x, size.y, 0.006), Craft.mat(Craft.Kind.PAPER, bg), Vector3.ZERO, false)
	var ink: Color = Craft.INK if bg.get_luminance() > 0.5 else Craft.CREAM
	var accent: Color = [Craft.RED, Craft.YELLOW, Craft.BLUE, Craft.TEAL][rng.randi() % 4]
	# Simple printed artwork: a big shape and a couple of text bars.
	var shape := rng.randi() % 3
	var art_m := _paper(accent)
	if shape == 0:
		Craft.part(root, Craft.cutout(Craft.star_points(size.x * 0.28, size.x * 0.12), 0.004), art_m, Vector3(0, size.y * 0.12, 0.006), Vector3.ZERO, Vector3.ONE, false)
	elif shape == 1:
		Craft.part(root, Craft.cutout(Craft.blob_points(size.x * 0.25, 0.0, 24, 1), 0.004), art_m, Vector3(0, size.y * 0.12, 0.006), Vector3.ZERO, Vector3.ONE, false)
	else:
		var plane := PackedVector2Array([Vector2(-0.35, 0), Vector2(0.35, 0.05), Vector2(0.4, 0.0), Vector2(0.35, -0.05)])
		for k in plane.size():
			plane[k] *= size.x
		Craft.part(root, Craft.cutout(plane, 0.004), art_m, Vector3(0, size.y * 0.12, 0.006), Vector3(0, 0, 0.3), Vector3.ONE, false)
	for k in 2:
		Craft.box(root, Vector3(0, -size.y * (0.22 + k * 0.12), 0.005), Vector3(size.x * (0.7 - k * 0.2), size.y * 0.05, 0.003), _paper(ink), Vector3.ZERO, false)
	if title != "":
		var l := Label3D.new()
		l.text = title
		l.font = preload("res://assets/fonts/LuckiestGuy-Regular.ttf")
		l.font_size = 48
		l.pixel_size = size.x / 900.0
		l.modulate = ink
		l.outline_size = 0
		l.position = Vector3(0, -size.y * 0.3, 0.009)
		root.add_child(l)
	var tape := Craft.mat(Craft.Kind.TAPE, Color(0.86, 0.8, 0.64), 0, Color.WHITE, 1.0, 0.0, false)
	for c in [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		Craft.box(root, Vector3(c.x * size.x * 0.47, c.y * size.y * 0.47, 0.008), Vector3(size.x * 0.22, size.y * 0.07, 0.003), tape, Vector3(0, 0, c.x * c.y * 0.7), false)


## Cut-out paper grass, Paper Mario style: crossed jagged cards.
static func grass(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator, tall := false) -> void:
	var cols := [Color(0.3, 0.42, 0.2), Color(0.38, 0.47, 0.24), Color(0.26, 0.36, 0.19)]
	if tall:
		cols = [Color(0.66, 0.6, 0.38), Color(0.58, 0.52, 0.34)]
	var pts := PackedVector2Array()
	var blades := 5
	var w := 0.5 * scale
	pts.append(Vector2(-w, 0))
	for i in blades:
		var x0 := -w + (2.0 * w) * (i + 0.5) / blades
		var hh := rng.randf_range(0.35, 0.6) * scale * (1.6 if tall else 1.0)
		pts.append(Vector2(x0 - w / blades * 0.6, hh * 0.35))
		pts.append(Vector2(x0 + rng.randf_range(-0.05, 0.05) * scale, hh))
		pts.append(Vector2(x0 + w / blades * 0.6, hh * 0.35))
	pts.append(Vector2(w, 0))
	var mesh := Craft.cutout(pts, 0.008)
	var m := Craft.mat(Craft.Kind.PAPER, cols[rng.randi() % cols.size()], 0, Color.WHITE, 1.0, 0.0, false)
	var y0 := rng.randf() * PI
	for k in 2:
		Craft.part(parent, mesh, m, pos, Vector3(0, y0 + k * PI * 0.5, 0), Vector3.ONE, k == 0)


static func flower(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var cols := [Color(0.86, 0.85, 0.8), Color(0.84, 0.74, 0.36), Color(0.62, 0.56, 0.7), Color(0.86, 0.85, 0.8), Color(0.84, 0.74, 0.36)]
	var stem := _paper(Craft.GRASS)
	Craft.box(parent, pos + Vector3(0, 0.2, 0), Vector3(0.02, 0.4, 0.004), stem, Vector3(0, rng.randf() * PI, 0), false)
	var petals := Craft.cutout(Craft.star_points(0.13, 0.07, 5), 0.01)
	var y := rng.randf() * PI
	Craft.part(parent, petals, _paper(cols[rng.randi() % cols.size()]), pos + Vector3(0, 0.42, 0), Vector3(-0.4, y, 0), Vector3.ONE, false)
	Craft.part(parent, Craft.cylinder(0.035, 0.035, 0.02, 10), Craft.mat(Craft.Kind.PLASTIC, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), pos + Vector3(0, 0.425, 0), Vector3(PI * 0.5 - 0.4, y, 0), Vector3.ONE, false)


## A felt sign hanging from two strings.
static func hanging_sign(parent: Node3D, pos: Vector3, yaw: float, text: String, col: Color, width := 3.0) -> void:
	var root := Craft.pivot(parent, pos, Vector3(0, yaw, 0))
	Craft.box(root, Vector3.ZERO, Vector3(width, 0.7, 0.06), Craft.mat(Craft.Kind.FELT, col, Craft.Pattern.STITCH, Craft.CREAM), Vector3.ZERO, false)
	var s := _paper(Color(0.9, 0.9, 0.88))
	for x in [-width * 0.4, width * 0.4]:
		Craft.box(root, Vector3(x, 0.9, 0), Vector3(0.012, 1.1, 0.012), s, Vector3.ZERO, false)
	for side in [1.0, -1.0]:
		var l := Label3D.new()
		l.text = text
		l.font = preload("res://assets/fonts/LuckiestGuy-Regular.ttf")
		l.font_size = 96
		l.pixel_size = 0.0045
		l.modulate = Craft.CREAM
		l.outline_modulate = Craft.INK
		l.outline_size = 14
		l.position = Vector3(0, -0.02, 0.035 * side)
		l.rotation.y = 0.0 if side > 0.0 else PI
		root.add_child(l)
