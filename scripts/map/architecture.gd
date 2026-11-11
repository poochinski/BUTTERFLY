class_name Architecture
extends RefCounted
## Architectural detail that turns boxes into buildings: window mullions,
## ceiling beams, column bases and capitals, parapets, rooftop plant,
## three-dimensional cardboard lettering and chain-link fencing.

static var _chain_mat: StandardMaterial3D


static func _m(kind: int, col: Color, pattern := 0, col2 := Color.WHITE) -> Material:
	return Craft.mat(kind, col, pattern, col2)


## Window frame in an opening. `a` and `b` are opposite corners lying in
## the wall plane (the wall runs along X if a.z == b.z, otherwise along Z).
static func window_frame(parent: Node3D, a: Vector3, b: Vector3, spacing: float, col: Color, transom := true) -> void:
	var m := _m(Craft.Kind.CARDBOARD, col)
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var lo := a.min(b)
	var hi := a.max(b)
	var width := (hi.x - lo.x) if along_x else (hi.z - lo.z)
	var height := hi.y - lo.y
	var depth := 0.16
	var t := 0.09
	var center := (lo + hi) * 0.5
	var size_h := Vector3(width, t, depth) if along_x else Vector3(depth, t, width)
	Craft.box(parent, Vector3(center.x, lo.y + t * 0.5, center.z), size_h * Vector3(1.0, 1.6, 1.4), m)
	Craft.box(parent, Vector3(center.x, hi.y - t * 0.5, center.z), size_h, m)
	if transom and height > 1.4:
		Craft.box(parent, Vector3(center.x, lo.y + height * 0.62, center.z), size_h * Vector3(1.0, 0.7, 1.0), m)
	var n := maxi(int(round(width / spacing)), 1)
	for i in n + 1:
		var f := float(i) / n
		var p := lo.lerp(Vector3(hi.x, lo.y, hi.z), f)
		var size_v := Vector3(t, height, depth)
		Craft.box(parent, Vector3(p.x, center.y, p.z), size_v if along_x else Vector3(depth, height, t), m)


## A beam between two points (cardboard I-beam look via a lighter flange).
static func beam(parent: Node3D, from: Vector3, to: Vector3, w: float, h: float, col: Color) -> void:
	var mid := (from + to) * 0.5
	var len := from.distance_to(to)
	var web := Craft.box(parent, mid, Vector3.ONE, _m(Craft.Kind.CARDBOARD, col), Vector3.ZERO)
	web.look_at_from_position(mid, to, Vector3.UP if absf((to - from).normalized().y) < 0.95 else Vector3.RIGHT)
	web.scale = Vector3(w * 0.5, h, len)
	var flange := Craft.box(parent, mid - Vector3(0, h * 0.5, 0), Vector3.ONE, _m(Craft.Kind.CARDBOARD, col.lightened(0.15)), Vector3.ZERO)
	flange.look_at_from_position(mid - Vector3(0, h * 0.5, 0), to - Vector3(0, h * 0.5, 0), Vector3.UP)
	flange.scale = Vector3(w, h * 0.18, len)


## Base and capital collars for a square column.
static func column_trim(parent: Node3D, pos: Vector3, height: float, width: float, col: Color) -> void:
	var m := _m(Craft.Kind.CARDBOARD, col)
	Craft.box(parent, pos + Vector3(0, 0.2, 0), Vector3(width + 0.22, 0.4, width + 0.22), m)
	Craft.box(parent, pos + Vector3(0, 0.45, 0), Vector3(width + 0.12, 0.1, width + 0.12), m)
	Craft.box(parent, pos + Vector3(0, height - 0.3, 0), Vector3(width + 0.26, 0.24, width + 0.26), m)
	Craft.box(parent, pos + Vector3(0, height - 0.5, 0), Vector3(width + 0.14, 0.16, width + 0.14), m)


## A parapet with a cap all around a rectangular roof.
static func parapet(parent: Node3D, lo: Vector3, hi: Vector3, h: float, col: Color, cap: Color) -> void:
	var m := _m(Craft.Kind.CARDBOARD, col)
	var mc := _m(Craft.Kind.CARDBOARD, cap)
	var y := lo.y + h * 0.5
	var sx := hi.x - lo.x
	var sz := hi.z - lo.z
	for e in [[Vector3((lo.x + hi.x) * 0.5, y, lo.z), Vector3(sx + 0.4, h, 0.4)], [Vector3((lo.x + hi.x) * 0.5, y, hi.z), Vector3(sx + 0.4, h, 0.4)],
			[Vector3(lo.x, y, (lo.z + hi.z) * 0.5), Vector3(0.4, h, sz)], [Vector3(hi.x, y, (lo.z + hi.z) * 0.5), Vector3(0.4, h, sz)]]:
		var p: Vector3 = e[0]
		var s: Vector3 = e[1]
		Craft.box(parent, p, s, m)
		Craft.box(parent, p + Vector3(0, h * 0.5 + 0.06, 0), s + Vector3(0.12, 0.12 - s.y, 0.12), mc)


## Air-conditioning units, vents and an antenna on a roof.
static func rooftop(parent: Node3D, center: Vector3, rng: RandomNumberGenerator, count := 4, spread := Vector2(14, 10)) -> void:
	var unit_m := _m(Craft.Kind.CARDBOARD, Color(0.78, 0.8, 0.84))
	var grille := _m(Craft.Kind.PAPER, Color(0.3, 0.32, 0.36))
	var fan := Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.77, 0.8), 0, Color.WHITE, 1.0, 0.0, false)
	for i in count:
		var p := center + Vector3(rng.randf_range(-spread.x, spread.x), 0, rng.randf_range(-spread.y, spread.y))
		var s := Vector3(rng.randf_range(1.6, 2.8), rng.randf_range(0.9, 1.4), rng.randf_range(1.2, 2.0))
		var u := Craft.pivot(parent, p, Vector3(0, rng.randf() * 0.2, 0))
		Craft.box(u, Vector3(0, s.y * 0.5, 0), s, unit_m)
		Craft.box(u, Vector3(0, s.y * 0.5, s.z * 0.5 + 0.01), Vector3(s.x * 0.8, s.y * 0.6, 0.02), grille)
		Craft.part(u, Craft.cylinder(s.x * 0.22, s.x * 0.22, 0.08, 16), fan, Vector3(0, s.y + 0.04, 0))
		Craft.part(u, Craft.cutout(Craft.star_points(s.x * 0.2, s.x * 0.06, 4), 0.02), grille, Vector3(0, s.y + 0.09, 0), Vector3(-PI * 0.5, rng.randf(), 0))
	var mast := Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.72, 0.76), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.part(parent, Craft.cylinder(0.05, 0.07, 5.0, 8), mast, center + Vector3(spread.x * 0.6, 2.5, -spread.y * 0.4))
	Craft.part(parent, Craft.sphere(0.12, 8), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.2, 0.15), 0, Color.WHITE, 1.0, 0.0, false), center + Vector3(spread.x * 0.6, 5.05, -spread.y * 0.4))


## Big chunky cardboard letters (extruded text) — rooftop signs, logos.
static func letters(parent: Node3D, text: String, pos: Vector3, yaw: float, size: float, col: Color, depth := 0.35) -> Node3D:
	var root := Craft.pivot(parent, pos, Vector3(0, yaw, 0))
	var tm := TextMesh.new()
	tm.text = text
	tm.font = preload("res://assets/fonts/LuckiestGuy-Regular.ttf")
	tm.font_size = 64
	tm.pixel_size = size / 64.0
	tm.depth = depth
	tm.curve_step = 1.0
	var face := Craft.outlined(Craft.mat(Craft.Kind.CARDBOARD, col, 0, Color.WHITE, 1.0, 0.0, false), 0.03)
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = face
	root.add_child(mi)
	# A kraft backing board behind the letters, as if glued on.
	var back := TextMesh.new()
	back.text = text
	back.font = tm.font
	back.font_size = 64
	back.pixel_size = tm.pixel_size
	back.depth = depth * 0.6
	back.curve_step = 1.0
	var bmi := MeshInstance3D.new()
	bmi.mesh = back
	bmi.material_override = Craft.mat(Craft.Kind.CARDBOARD, Craft.KRAFT, 0, Color.WHITE, 1.0, 0.0, false)
	bmi.position = Vector3(size * 0.04, -size * 0.04, -depth * 0.6)
	root.add_child(bmi)
	return root


## Chain-link fence material: a diamond wire grid cut out with alpha.
static func chain_link() -> StandardMaterial3D:
	if _chain_mat:
		return _chain_mat
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var u := float(x) / 64.0
			var v := float(y) / 64.0
			var d1 := absf(fract_d(u + v) - 0.5)
			var d2 := absf(fract_d(u - v) - 0.5)
			var wire := minf(d1, d2) > 0.43
			img.set_pixel(x, y, Color(0.82, 0.84, 0.87, 1.0) if wire else Color(0, 0, 0, 0))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.6
	m.roughness = 0.4
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(4.0, 4.0, 4.0)
	_chain_mat = m
	return m


static func fract_d(x: float) -> float:
	return x - floorf(x)
