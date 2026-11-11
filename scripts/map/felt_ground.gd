class_name FeltGround
extends RefCounted
## The ground, built the way a skilled crafter would build a diorama base:
##
##   * the tarmac is a patchwork of hand-cut grey felt slabs laid over a
##     dark underlay that shows in the seams, with stitched repair patches;
##   * the sidewalk is light grey felt paving with stitched joints;
##   * lawns are two or three layers of green felt with pinking-shear edges,
##     covered in fringe-cut felt grass tufts and little felt flowers;
##   * mud is layered brown felt with a wet, glossy centre, tyre ruts and a
##     cellophane puddle;
##   * gravel beds are felt pebbles and pom-poms;
##   * imperfections: oil stains, stray threads, grass in the cracks;
##   * road markings are stitched felt strips.
##
## Everything is merged into a few meshes (one per material) so thousands of
## cut pieces stay cheap to draw. All of it is decoration: the collision
## floor is the slab underneath.

const TARMAC := Color(0.3, 0.31, 0.33)
const SIDEWALK := Color(0.64, 0.63, 0.6)
const GRASS_DARK := Color(0.18, 0.28, 0.14)
const GRASS_MID := Color(0.27, 0.37, 0.19)
const GRASS_LIGHT := Color(0.38, 0.44, 0.24)
const MUD := Color(0.35, 0.25, 0.17)
const MUD_DARK := Color(0.23, 0.155, 0.1)
const TOP := 0.03  # height of the felt layer

## Rectangles (x0, z0, x1, z1) that become lawn instead of tarmac.
const LAWNS := [
	Rect2(-14.0, 23.0, 74.0, 3.0),     # south verge along the fence
	Rect2(58.0, -38.0, 2.0, 61.0),     # east verge
	Rect2(32.0, -38.0, 26.0, 1.8),     # north verge
	Rect2(-13.6, 17.5, 4.6, 5.5),      # island by the terminal corner
	Rect2(44.0, -34.5, 8.0, 4.0),      # island north-east
]

static var rng := RandomNumberGenerator.new()


class Layer:
	## Collects cut pieces that share one material into a single mesh.
	var st := SurfaceTool.new()
	var mat: Material
	var count := 0

	func _init(m: Material) -> void:
		mat = m
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	func _v(p: Vector3, n: Vector3, c: Color) -> void:
		st.set_color(c)
		st.set_normal(n)
		st.set_uv(Vector2(p.x, p.z))
		st.add_vertex(p)

	func _tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color) -> void:
		if (b - a).cross(c - a).dot(n) > 0.0:
			var t := b
			b = c
			c = t
		_v(a, n, col)
		_v(b, n, col)
		_v(c, n, col)

	## A flat cut piece: polygon in XZ (as Vector2(x, z)), from y0 up by thick.
	func piece(poly: PackedVector2Array, y0: float, thick: float, tint := Color.WHITE) -> void:
		var pts := poly.duplicate()
		if Geometry2D.is_polygon_clockwise(pts):
			pts.reverse()
		var tris := Geometry2D.triangulate_polygon(pts)
		if tris.is_empty():
			return
		var y1 := y0 + thick
		for t in range(0, tris.size(), 3):
			var a: Vector2 = pts[tris[t]]
			var b: Vector2 = pts[tris[t + 1]]
			var c: Vector2 = pts[tris[t + 2]]
			_tri(Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(c.x, y1, c.y), Vector3.UP, tint)
		var n := pts.size()
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			var e := (b - a).normalized()
			# Counter-clockwise in (x, z) means the outward side is (e.y, -e.x)
			# measured in (x, z) — careful: z grows "down" in this plane.
			var out := Vector3(-e.y, 0, e.x)
			var mid := (a + b) * 0.5
			var centre := _centroid(pts)
			if Vector2(out.x, out.z).dot(mid - centre) < 0.0:
				out = -out
			var p0 := Vector3(a.x, y0, a.y)
			var p1 := Vector3(b.x, y0, b.y)
			var p2 := Vector3(b.x, y1, b.y)
			var p3 := Vector3(a.x, y1, a.y)
			var shade := tint.darkened(0.08)
			_tri(p0, p1, p2, out, shade)
			_tri(p0, p2, p3, out, shade)
		count += 1

	func commit(parent: Node3D, shadows := false) -> MeshInstance3D:
		if count == 0:
			return null
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		return mi

	static func _centroid(pts: PackedVector2Array) -> Vector2:
		var c := Vector2.ZERO
		for p in pts:
			c += p
		return c / maxf(pts.size(), 1)


# ------------------------------------------------------------------ build

static func build(map: GatewayMap) -> void:
	rng.seed = 2468
	var root := Node3D.new()
	root.name = "FeltGround"
	map.deco.add_child(root)

	var tarmac := Layer.new(Craft.felt_piece(TARMAC, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 3.0))
	var patches := Layer.new(Craft.felt_piece(Color(0.42, 0.42, 0.44), Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.5))
	var sidewalk := Layer.new(Craft.felt_piece(SIDEWALK, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.5))
	var stitches := Layer.new(Craft.felt_piece(Color(0.95, 0.92, 0.84), Craft.Kind.PAPER))
	var lawn1 := Layer.new(Craft.felt_piece(GRASS_DARK, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.0))
	var lawn2 := Layer.new(Craft.felt_piece(GRASS_MID, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.0))
	var lawn3 := Layer.new(Craft.felt_piece(GRASS_LIGHT, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.0))
	var mud1 := Layer.new(Craft.felt_piece(MUD, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.0))
	var mud2 := Layer.new(Craft.felt_piece(MUD_DARK, Craft.Kind.FELT, 2, true, 0, Color.WHITE, 2.0))
	var wet := Layer.new(Craft.felt_piece(Color(0.2, 0.13, 0.08), Craft.Kind.PLASTIC))
	var oil := Layer.new(Craft.felt_piece(Color(0.1, 0.1, 0.12), Craft.Kind.PLASTIC))
	var yellow := Layer.new(Craft.felt_piece(Color(0.84, 0.66, 0.18)))
	var white := Layer.new(Craft.felt_piece(Color(0.84, 0.83, 0.8)))
	var red := Layer.new(Craft.felt_piece(Color(0.6, 0.18, 0.15)))
	var puddles := Layer.new(Craft.cellophane(Color(0.5, 0.6, 0.66, 0.55)))
	var muddy_water := Layer.new(Craft.cellophane(Color(0.45, 0.36, 0.25, 0.6)))

	var crack_spots := _tarmac(tarmac, patches, stitches)
	_sidewalk(sidewalk, stitches)
	var grass_spots := _lawns(lawn1, lawn2, lawn3)
	grass_spots.append_array(crack_spots)
	var gravel_spots := _gravel_beds()
	_mud(mud1, mud2, wet, muddy_water, root)
	_markings(yellow, white, red, stitches)
	_stains(oil, puddles)
	_outside(lawn1, lawn2, lawn3, mud1, mud2, wet, muddy_water, grass_spots, gravel_spots)

	for l in [tarmac, patches, sidewalk, lawn1, lawn2, lawn3, mud1, mud2, wet, oil, yellow, white, red, stitches]:
		(l as Layer).commit(root)
	for l in [puddles, muddy_water]:
		var mi := (l as Layer).commit(root)
		if mi:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grass_tufts(root, grass_spots)
	_flowers(root, grass_spots)
	_gravel(root, gravel_spots)
	_threads(root)


# ------------------------------------------------------------ polygons

## A hand-cut quad: each edge split in three with a little wobble.
static func _cut_quad(c: Array, wobble: float, shrink: float) -> PackedVector2Array:
	var centre := Vector2.ZERO
	for p in c:
		centre += p
	centre /= 4.0
	var pts := PackedVector2Array()
	for i in 4:
		var a: Vector2 = c[i]
		var b: Vector2 = c[(i + 1) % 4]
		var e := b - a
		var nrm := Vector2(-e.y, e.x).normalized()
		for k in 3:
			var t := k / 3.0
			var p := a + e * t
			if k > 0:
				p += nrm * rng.randf_range(-wobble, wobble)
			pts.append(p)
	for i in pts.size():
		pts[i] = centre + (pts[i] - centre) * shrink
	return pts


## An organic blob; zigzag gives pinking-shear edges.
static func _blob(centre: Vector2, r: Vector2, irregular: float, steps: int, zigzag := 0.0, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var phase := rng.randf() * TAU
	for i in steps:
		var a := TAU * i / steps
		var k := 1.0 + irregular * (sin(a * 3.0 + phase) * 0.5 + sin(a * 5.0 + phase * 1.7) * 0.3) + rng.randf_range(-irregular, irregular) * 0.3
		if zigzag > 0.0:
			k += zigzag if i % 2 == 0 else -zigzag
		var p := Vector2(cos(a) * r.x, sin(a) * r.y) * k
		pts.append(centre + p.rotated(rot))
	return pts


## A wobbly-edged rectangle (for lawn regions), optionally pinked.
static func _cut_rect(r: Rect2, wobble: float, step: float, zigzag := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var idx := 0
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var e := b - a
		var n := maxi(int(e.length() / step), 1)
		var nrm := Vector2(-e.y, e.x).normalized()
		for k in n:
			var p := a + e * (float(k) / n)
			if k > 0:
				p += nrm * rng.randf_range(-wobble, wobble)
			if zigzag > 0.0 and k > 0:
				p += nrm * (zigzag if idx % 2 == 0 else -zigzag)
			idx += 1
			pts.append(p)
	return pts


## A strip polygon following a path (tyre ruts, painted lines).
static func _strip(path: Array, width: float, wobble := 0.0) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in path.size():
		var p: Vector2 = path[i]
		var d: Vector2 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var n := Vector2(-d.y, d.x)
		var w := width * 0.5 + rng.randf_range(-wobble, wobble)
		left.append(p + n * w)
		right.append(p - n * w)
	right.reverse()
	left.append_array(right)
	return left


static func _in_lawn(p: Vector2) -> bool:
	for r in LAWNS:
		var rr: Rect2 = r
		if rr.grow(0.3).has_point(p):
			return true
	return false


## A dashed thread running round a polygon, inset slightly: stitching.
static func _stitch(layer: Layer, poly: PackedVector2Array, y: float, inset := 0.06, dash := 0.08, gap := 0.06) -> void:
	var centre := Layer._centroid(poly)
	var n := poly.size()
	for i in n:
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		a = a + (centre - a).normalized() * inset
		b = b + (centre - b).normalized() * inset
		var len := a.distance_to(b)
		if len < 0.02:
			continue
		var dir := (b - a) / len
		var side := Vector2(-dir.y, dir.x) * 0.008
		var t := 0.0
		while t < len:
			var s := a + dir * t
			var e := a + dir * minf(t + dash, len)
			layer.piece(PackedVector2Array([s + side, e + side, e - side, s - side]), y, 0.006)
			t += dash + gap


# -------------------------------------------------------------- tarmac

static func _tarmac(layer: Layer, patches: Layer, stitches: Layer) -> Array:
	var cracks := []
	var x0 := -14.0
	var z0 := -38.0
	var cell := 3.0
	var nx := int((60.0 - x0) / cell) + 1
	var nz := int((26.0 - z0) / cell) + 1
	var corners := []
	for i in nx + 1:
		var col := []
		for j in nz + 1:
			var p := Vector2(x0 + i * cell, z0 + j * cell)
			if i > 0 and i < nx and j > 0 and j < nz:
				p += Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))
			col.append(p)
		corners.append(col)
	for i in nx:
		for j in nz:
			var q := [corners[i][j], corners[i + 1][j], corners[i + 1][j + 1], corners[i][j + 1]]
			var centre: Vector2 = (q[0] + q[2]) * 0.5
			if centre.x > 60.0 or centre.y > 26.0 or _in_lawn(centre):
				continue
			var crack := rng.randf() < 0.06
			var poly := _cut_quad(q, 0.07, 0.94 if crack else 0.985)
			var shade := rng.randf_range(0.84, 1.1)
			var tint := Color(shade, shade * rng.randf_range(0.98, 1.02), shade * rng.randf_range(0.97, 1.03))
			layer.piece(poly, rng.randf_range(0.0, 0.004), TOP, tint)
			if crack:
				# Grass pushing up through the gap around this slab.
				for k in rng.randi_range(4, 9):
					var e := rng.randi() % 4
					var a: Vector2 = q[e]
					var b: Vector2 = q[(e + 1) % 4]
					var sp: Vector2 = a.lerp(b, rng.randf())
					cracks.append(Vector3(sp.x, 0.005, sp.y))
			if rng.randf() < 0.08:
				# A stitched-on repair patch.
				var pc: Vector2 = centre + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
				var patch := _blob(pc, Vector2(rng.randf_range(0.5, 0.9), rng.randf_range(0.4, 0.8)), 0.12, 12, 0.0, rng.randf() * TAU)
				var pt := rng.randf_range(0.85, 1.1)
				patches.piece(patch, TOP + 0.004, 0.008, Color(pt, pt, pt))
				_stitch(stitches, patch, TOP + 0.012, 0.05)
	return cracks


static func _sidewalk(layer: Layer, stitches: Layer) -> void:
	var size := 1.25
	var x := -58.0
	while x < -14.0:
		var z := 22.3
		while z < 26.0:
			var q := [Vector2(x, z), Vector2(x + size, z), Vector2(x + size, minf(z + size, 26.0)), Vector2(x, minf(z + size, 26.0))]
			var poly := _cut_quad(q, 0.025, 0.965)
			var s := rng.randf_range(0.9, 1.06)
			layer.piece(poly, 0.0, 0.036, Color(s, s, s * 0.98))
			if rng.randf() < 0.18:
				_stitch(stitches, poly, 0.036, 0.07, 0.07, 0.07)
			z += size
		x += size


# --------------------------------------------------------------- lawns

## Lays every lawn and returns spots (Vector3 + density) for grass tufts.
static func _lawns(l1: Layer, l2: Layer, l3: Layer) -> Array:
	var spots := []
	for r in LAWNS:
		_lawn_rect(r, l1, l2, l3, spots, 3.2)
	return spots


static func _lawn_rect(r: Rect2, l1: Layer, l2: Layer, l3: Layer, spots: Array, density: float) -> void:
	l1.piece(_cut_rect(r, 0.06, 0.35, 0.05), 0.0, TOP + 0.006)
	# Layers of lighter felt cut into organic shapes on top.
	var area := r.size.x * r.size.y
	var n2 := int(area / 6.0) + 1
	for i in n2:
		var c := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		var rad := Vector2(rng.randf_range(0.5, 1.6), rng.randf_range(0.4, 1.2)).min(r.size * 0.45)
		var poly := _clip_to(_blob(c, rad, 0.25, 22, 0.035, rng.randf() * TAU), r)
		if poly.size() >= 3:
			l2.piece(poly, TOP + 0.006, 0.01)
		if rng.randf() < 0.45:
			var poly3 := _clip_to(_blob(c + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)), rad * 0.5, 0.3, 18, 0.03, rng.randf() * TAU), r)
			if poly3.size() >= 3:
				l3.piece(poly3, TOP + 0.016, 0.008)
	var tufts := int(area * density)
	for i in tufts:
		var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		spots.append(Vector3(p.x, TOP + 0.015, p.y))


static func _clip_to(poly: PackedVector2Array, r: Rect2) -> PackedVector2Array:
	var rect := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var res := Geometry2D.intersect_polygons(poly, rect)
	return res[0] if res.size() > 0 else PackedVector2Array()


# --------------------------------------------------------------- gravel

## Returns gravel bed regions as [centre(Vector2), radius(Vector2), count].
static func _gravel_beds() -> Array:
	var beds := []
	# Strips just inside the fences.
	beds.append([Rect2(-14.0, 25.0, 74.0, 1.0), 26.0])
	beds.append([Rect2(59.0, -38.0, 1.0, 64.0), 26.0])
	beds.append([Rect2(32.0, -38.0, 27.0, 0.9), 26.0])
	beds.append([Rect2(-58.0, 26.4, 118.0, 1.4), 16.0])
	# Round beds around the floodlight masts and jet bridge legs.
	for p: Vector2 in [Vector2(0, -24), Vector2(56, -34), Vector2(56, 23), Vector2(14, 23), Vector2(-8, -9), Vector2(-1, -8.8)]:
		beds.append([Rect2(p - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), 22.0])
	return beds


static func _gravel(root: Node3D, beds: Array) -> void:
	var pebble := Craft.sphere(0.07, 7)
	var cols := [Color(0.62, 0.6, 0.57), Color(0.5, 0.49, 0.47), Color(0.72, 0.66, 0.56), Color(0.4, 0.4, 0.42)]
	var buckets := [[], [], [], []]
	var poms := []
	for bed in beds:
		var r: Rect2 = bed[0]
		var dens: float = bed[1]
		var round_bed := absf(r.size.x - r.size.y) < 0.01 and r.size.x < 4.0
		var n := int(r.size.x * r.size.y * dens)
		for i in n:
			var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
			if round_bed and p.distance_to(r.get_center()) > r.size.x * 0.5:
				continue
			var s := rng.randf_range(0.45, 1.15)
			var b := Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
			b = b * Basis.from_scale(Vector3(s * rng.randf_range(0.8, 1.3), s * 0.55, s))
			buckets[rng.randi() % 4].append(Transform3D(b, Vector3(p.x, TOP + 0.01, p.y)))
			if rng.randf() < 0.035:
				poms.append(Vector3(p.x, TOP + 0.05, p.y))
	for i in 4:
		_multimesh(root, pebble, Craft.felt_piece(cols[i], Craft.Kind.FELT, 0, false), buckets[i], true)
	var pom_xf := []
	for p in poms:
		pom_xf.append(Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.7, 1.2)), p))
	_multimesh(root, Craft.sphere(0.06, 10), Craft.felt_piece(Color(0.86, 0.82, 0.74), Craft.Kind.KNIT, 0, false), pom_xf, true)


# ------------------------------------------------------------------ mud

static func _mud(m1: Layer, m2: Layer, wet: Layer, water: Layer, root: Node3D) -> void:
	# A muddy corner behind the east spawn crates, churned by the tug.
	_mud_patch(Vector2(55.5, -28.0), Vector2(2.6, 2.0), m1, m2, wet, water)
	_mud_patch(Vector2(-11.0, 24.5), Vector2(1.6, 0.9), m1, m2, wet, water)
	_mud_patch(Vector2(35.0, 24.6), Vector2(2.2, 1.0), m1, m2, wet, water)
	# Muddy tread prints leaving the patch, fading out over a few metres.
	_tread(m2, Vector2(53.6, -26.8), Vector2(-0.7, 0.75).normalized(), 6.0)
	_tread(m2, Vector2(36.5, 24.2), Vector2(-1.0, -0.35).normalized(), 4.5)
	var _r := root


static func _tread(layer: Layer, start: Vector2, dir: Vector2, length: float) -> void:
	var side := Vector2(-dir.y, dir.x)
	var t := 0.0
	var i := 0
	while t < length:
		var fade := 1.0 - t / length
		for off: float in [-0.7, 0.7]:
			if rng.randf() > fade + 0.15:
				continue
			var c := start + dir * t + side * (off + (0.06 if i % 2 == 0 else -0.06))
			var blk := PackedVector2Array([c + side * 0.13 - dir * 0.05, c + side * 0.13 + dir * 0.05, c - side * 0.13 + dir * 0.05, c - side * 0.13 - dir * 0.05])
			layer.piece(blk, TOP + 0.003, 0.004)
		t += 0.22
		i += 1


static func _mud_patch(c: Vector2, r: Vector2, m1: Layer, m2: Layer, wet: Layer, water: Layer) -> void:
	var rot := rng.randf() * TAU
	m1.piece(_blob(c, r, 0.22, 26, 0.0, rot), TOP - 0.004, 0.012)
	m2.piece(_blob(c + Vector2(0.2, -0.1), r * 0.7, 0.25, 22, 0.0, rot), TOP + 0.008, 0.008)
	wet.piece(_blob(c + Vector2(0.1, 0.0), r * 0.42, 0.3, 18, 0.0, rot), TOP + 0.016, 0.004)
	water.piece(_blob(c + Vector2(-0.2, 0.15), r * 0.3, 0.25, 18, 0.0, rot), TOP + 0.021, 0.003)
	# Splashes and clods around the edge.
	for i in 10:
		var a := rng.randf() * TAU
		var p := c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot) * rng.randf_range(1.0, 1.35)
		m1.piece(_blob(p, Vector2.ONE * rng.randf_range(0.08, 0.2), 0.3, 9), TOP, 0.01)


# ------------------------------------------------------------- markings

static func _markings(yellow: Layer, white: Layer, red: Layer, stitches: Layer) -> void:
	var y := TOP + 0.004
	var lines := [
		[[Vector2(-12, -2), Vector2(58, -2)], yellow, 0.3],
		[[Vector2(10, -5), Vector2(10, 13)], yellow, 0.28],
		[[Vector2(46, -24), Vector2(46, 0)], yellow, 0.28],
	]
	for l in lines:
		var pts: Array = l[0]
		var path := []
		var a: Vector2 = pts[0]
		var b: Vector2 = pts[1]
		var n := int(a.distance_to(b) / 1.5)
		for i in n + 1:
			path.append(a.lerp(b, float(i) / n))
		var poly := _strip(path, l[2], 0.015)
		(l[1] as Layer).piece(poly, y, 0.01)
		_stitch(stitches, poly, y + 0.01, 0.045, 0.1, 0.08)
	# A curved lead-in line toward the jet bridge stand.
	var curve := []
	for i in 16:
		var t := i / 15.0
		curve.append(Vector2(lerpf(-12.0, -4.0, t), lerpf(-2.0, 6.0, t * t)))
	var cpoly := _strip(curve, 0.26, 0.012)
	yellow.piece(cpoly, y, 0.01)
	_stitch(stitches, cpoly, y + 0.01, 0.045, 0.1, 0.08)
	# White dashes along the apron and the terminal service lane.
	for i in 14:
		var d := _cut_quad([Vector2(-10 + i * 5.0 - 1.3, 19.82), Vector2(-10 + i * 5.0 + 1.3, 19.82), Vector2(-10 + i * 5.0 + 1.3, 20.18), Vector2(-10 + i * 5.0 - 1.3, 20.18)], 0.01, 1.0)
		white.piece(d, y, 0.01)
		_stitch(stitches, d, y + 0.01, 0.04, 0.08, 0.07)
	for i in 10:
		var z := -22.0 + i * 4.5
		var d := _cut_quad([Vector2(-11.18, z - 1.0), Vector2(-10.82, z - 1.0), Vector2(-10.82, z + 1.0), Vector2(-11.18, z + 1.0)], 0.01, 1.0)
		white.piece(d, y, 0.01)
	# Red-and-white stop bar at the nose of the airliner.
	for i in 8:
		var z0 := -5.0 + i * 0.75
		var q := _cut_quad([Vector2(-10.45, z0), Vector2(-9.95, z0), Vector2(-9.95, z0 + 0.75), Vector2(-10.45, z0 + 0.75)], 0.01, 0.97)
		(red if i % 2 == 0 else white).piece(q, y, 0.012)


# ------------------------------------------------------- imperfections

static func _stains(oil: Layer, puddles: Layer) -> void:
	for p: Vector2 in [Vector2(44.5, -4.0), Vector2(44.0, -1.5), Vector2(-6.0, 13.0), Vector2(-6.8, 1.8), Vector2(9.0, 7.5),
			Vector2(16.5, -10.5), Vector2(16.5, 6.5), Vector2(3.2, 4.6), Vector2(25.0, -14.0), Vector2(-3.0, -2.0)]:
		var r := Vector2(rng.randf_range(0.5, 1.1), rng.randf_range(0.4, 0.9))
		oil.piece(_blob(p, r, 0.35, 20, 0.0, rng.randf() * TAU), TOP + 0.004, 0.003)
		for k in 3:
			var q := p + Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
			oil.piece(_blob(q, Vector2.ONE * rng.randf_range(0.08, 0.22), 0.3, 10), TOP + 0.004, 0.003)
	for p: Vector2 in [Vector2(20.0, -20.0), Vector2(36.0, 11.0), Vector2(-4.0, -15.0), Vector2(49.0, -11.0), Vector2(28.0, 16.0), Vector2(6.0, -24.0)]:
		puddles.piece(_blob(p, Vector2(rng.randf_range(0.7, 1.4), rng.randf_range(0.5, 1.0)), 0.3, 22, 0.0, rng.randf() * TAU), TOP + 0.005, 0.003)


## Stray threads lying on the ground, the way they end up on a work table.
static func _threads(root: Node3D) -> void:
	var cols := [Color(0.2, 0.2, 0.22), Color(0.55, 0.5, 0.38), Color(0.5, 0.52, 0.56), Color(0.85, 0.84, 0.8)]
	var layer := Layer.new(Craft.felt_piece(Color.WHITE, Craft.Kind.KNIT, 2, true))
	for i in 26:
		var start := Vector2(rng.randf_range(-12.0, 58.0), rng.randf_range(-36.0, 25.0))
		var dir := rng.randf() * TAU
		var path := []
		var p := start
		for k in 18:
			path.append(p)
			dir += rng.randf_range(-0.5, 0.5)
			p += Vector2(cos(dir), sin(dir)) * 0.12
		layer.piece(_strip(path, 0.022), TOP + 0.004, 0.012, cols[i % cols.size()])
	layer.commit(root)


# ------------------------------------------------------------ outside

static func _outside(l1: Layer, l2: Layer, l3: Layer, m1: Layer, m2: Layer, wet: Layer, water: Layer, grass_spots: Array, _gravel: Array) -> void:
	# Fields just beyond the fences: what you see through the chain link.
	var fields := [Rect2(-70.0, 27.8, 150.0, 10.0), Rect2(60.4, -50.0, 16.0, 78.0), Rect2(30.0, -52.0, 30.4, 13.6), Rect2(-70.0, -52.0, 55.8, 21.6)]
	for f in fields:
		var r: Rect2 = f
		l1.piece(_cut_rect(r, 0.2, 1.2, 0.08), 0.0, TOP)
		var n := int(r.size.x * r.size.y / 14.0)
		for i in n:
			var c := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
			var poly := _clip_to(_blob(c, Vector2(rng.randf_range(0.8, 2.6), rng.randf_range(0.6, 1.8)), 0.3, 22, 0.05, rng.randf() * TAU), r)
			if poly.size() >= 3:
				(l2 if rng.randf() < 0.7 else l3).piece(poly, TOP, 0.012)
		var tufts := int(r.size.x * r.size.y * 0.7)
		for i in tufts:
			var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
			grass_spots.append(Vector3(p.x, TOP + 0.01, p.y))
	# A churned muddy track outside the south fence.
	_mud_patch(Vector2(5.0, 31.5), Vector2(3.0, 1.6), m1, m2, wet, water)
	_mud_patch(Vector2(-30.0, 33.0), Vector2(2.2, 1.3), m1, m2, wet, water)
	var path := []
	for i in 30:
		var t := i / 29.0
		path.append(Vector2(lerpf(-40.0, 40.0, t), 32.0 + sin(t * 6.0) * 1.6))
	for off: float in [-0.8, 0.8]:
		var shifted := []
		for p in path:
			shifted.append(p + Vector2(0, off))
		m2.piece(_strip(shifted, 0.32, 0.04), TOP + 0.002, 0.008)


# --------------------------------------------------------------- grass

## Fringe-cut felt grass: a strip of felt snipped into blades and rolled
## into a tuft. Three sizes, four greens (plus straw), as MultiMeshes.
static func _grass_tufts(root: Node3D, spots: Array) -> void:
	var meshes := [_tuft_mesh(5, 0.16, 1), _tuft_mesh(6, 0.24, 2), _tuft_mesh(7, 0.36, 3)]
	var cols := [Color(0.22, 0.33, 0.17), Color(0.29, 0.39, 0.2), Color(0.38, 0.45, 0.24), Color(0.19, 0.29, 0.15), Color(0.55, 0.52, 0.34)]
	var buckets := {}
	for s in spots:
		var p: Vector3 = s
		var v := 0 if rng.randf() < 0.45 else (1 if rng.randf() < 0.75 else 2)
		var c := rng.randi() % 4 if rng.randf() > 0.08 else 4
		var key := v * 10 + c
		if not buckets.has(key):
			buckets[key] = []
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.12, 0.12), rng.randf() * TAU, rng.randf_range(-0.12, 0.12)))
		b = b.scaled(Vector3.ONE * rng.randf_range(0.75, 1.3))
		buckets[key].append(Transform3D(b, p))
	for key in buckets:
		var mm := _multimesh(root, meshes[int(key) / 10], Craft.felt_piece(cols[int(key) % 10], Craft.Kind.FELT, 0, false), buckets[key], false)
		mm.visibility_range_end = 140.0


static func _tuft_mesh(blades: int, height: float, seed_value: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var st := SurfaceTool.new()
	for i in blades:
		var w := r.randf_range(0.022, 0.036)
		var h := height * r.randf_range(0.7, 1.15)
		var bend := r.randf_range(0.02, 0.06)
		var blade := PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.6 + bend, h * 0.55), Vector2(bend * 1.6, h), Vector2(-w * 0.5 + bend, h * 0.55)])
		var mesh := Craft.cutout(blade, 0.006)
		var a := TAU * i / blades + r.randf_range(-0.3, 0.3)
		var lean := r.randf_range(0.15, 0.45)
		var xf := Transform3D(Basis.from_euler(Vector3(lean, a, 0)), Vector3(cos(a), 0, sin(a)) * 0.03)
		st.append_from(mesh, 0, xf)
	return st.commit()


static func _flowers(root: Node3D, spots: Array) -> void:
	var petal_cols := [Color(0.88, 0.87, 0.83), Color(0.84, 0.74, 0.36), Color(0.88, 0.87, 0.83), Color(0.6, 0.55, 0.66)]
	var meshes := []
	for c in petal_cols:
		var st := SurfaceTool.new()
		var stem := Craft.cutout(PackedVector2Array([Vector2(-0.007, 0), Vector2(0.007, 0), Vector2(0.005, 0.18), Vector2(-0.005, 0.18)]), 0.004)
		st.append_from(stem, 0, Transform3D.IDENTITY)
		var m := st.commit()
		var petals := Craft.cutout(Craft.star_points(0.06, 0.035, 5), 0.008)
		var st2 := SurfaceTool.new()
		st2.append_from(petals, 0, Transform3D(Basis.from_euler(Vector3(-PI * 0.5 + 0.3, 0, 0)), Vector3(0, 0.18, 0)))
		st2.commit(m)
		var centre := Craft.sphere(0.018, 8)
		var st3 := SurfaceTool.new()
		st3.append_from(centre, 0, Transform3D(Basis.from_scale(Vector3(1, 0.6, 1)), Vector3(0, 0.19, 0)))
		st3.commit(m)
		m.surface_set_material(0, Craft.felt_piece(Color(0.28, 0.4, 0.2), Craft.Kind.FELT, 1, false))
		m.surface_set_material(1, Craft.felt_piece(c, Craft.Kind.FELT, 1, false))
		m.surface_set_material(2, Craft.felt_piece(Color(0.8, 0.62, 0.2), Craft.Kind.PLASTIC, 0, false))
		meshes.append(m)
	var buckets := [[], [], [], []]
	for s in spots:
		if rng.randf() > 0.06:
			continue
		var p: Vector3 = s
		var b := Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3.ONE * rng.randf_range(0.8, 1.3))
		buckets[rng.randi() % 4].append(Transform3D(b, p))
	for i in 4:
		var mmi := _multimesh(root, meshes[i], null, buckets[i], false)
		mmi.visibility_range_end = 90.0


static func _multimesh(root: Node3D, mesh: Mesh, mat: Material, xforms: Array, shadows: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if mat:
		mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	return mmi
