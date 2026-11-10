class_name Scenery
extends RefCounted
## Builds and scatters everything that grows or stands in the meadow:
## hedges, blossom trees, pine forest, groves, rocks, wildflowers, the pond,
## and the distant mountains. Everything is a chunked MultiMesh so thousands
## of objects stay cheap to draw.

const CHUNK := 64.0
const FLOWER_CHUNK := 24.0

const FOLIAGE_SHADER := preload("res://shaders/foliage.gdshader")
const BUSH_SHADER := preload("res://shaders/bush.gdshader")
const FLOWER_SHADER := preload("res://shaders/flower.gdshader")
const WATER_SHADER := preload("res://shaders/water.gdshader")

const BLOSSOM_PINK := Color(1.0, 0.66, 0.8, 0.85)
const BLOSSOM_DEEP := Color(0.95, 0.48, 0.7, 0.85)
const BLOSSOM_LILAC := Color(0.78, 0.62, 0.95, 0.75)
const BLOSSOM_WHITE := Color(0.98, 0.93, 0.95, 0.7)

const FLOWER_COLORS := [
	Color(0.96, 0.56, 0.8), Color(0.96, 0.56, 0.8), Color(0.88, 0.36, 0.68),
	Color(0.98, 0.97, 0.93), Color(1.0, 0.84, 0.3), Color(0.72, 0.6, 0.96),
	Color(1.0, 0.52, 0.22),
]

static var _foliage_mat: ShaderMaterial
static var _bush_mat: ShaderMaterial
static var _leaf_mat: ShaderMaterial
static var _flower_mat: ShaderMaterial


static func build(world: World) -> void:
	_foliage_mat = ShaderMaterial.new()
	_foliage_mat.shader = FOLIAGE_SHADER
	_bush_mat = ShaderMaterial.new()
	_bush_mat.shader = BUSH_SHADER
	_leaf_mat = ShaderMaterial.new()
	_leaf_mat.shader = BUSH_SHADER
	_leaf_mat.set_shader_parameter("floret_scale", 4.5)
	_leaf_mat.set_shader_parameter("lumpiness", 0.8)
	_leaf_mat.set_shader_parameter("sway", 0.015)
	_flower_mat = ShaderMaterial.new()
	_flower_mat.shader = FLOWER_SHADER

	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var root := Node3D.new()
	root.name = "Scenery"
	world.add_child(root)

	_place_trees(world, root, rng)
	_place_hedges_and_bushes(world, root, rng)
	_place_rocks(world, root, rng)
	_place_flowers(world, root, rng)
	_build_pond(world, root, rng)
	_build_horizon(world, root, rng)


# ------------------------------------------------------------ placement

static func _place_trees(world: World, root: Node3D, rng: RandomNumberGenerator) -> void:
	var pines := [_pine_mesh(1), _pine_mesh(2), _pine_mesh(3)]
	var broad := [_leafy_tree_mesh(11, false), _leafy_tree_mesh(12, false)]
	var blossom := [_leafy_tree_mesh(21, true), _leafy_tree_mesh(22, true)]
	var buckets := {}

	# Pine forest ring and groves.
	var step := 7.0
	var x := -430.0
	while x < 430.0:
		var z := -430.0
		while z < 430.0:
			var px := x + rng.randf_range(-3.0, 3.0)
			var pz := z + rng.randf_range(-3.0, 3.0)
			z += step
			var r := Vector2(px, pz).length()
			if r > 440.0:
				continue
			var f := world.forest_at(px, pz)
			var chance := pow(f, 1.3) * 0.85
			if world.flowers_at(px, pz) < 0.1 and f < 0.05:
				chance = 0.004
			if rng.randf() > chance or World.path_dist(px, pz) < 6.0 or world.is_water(px, pz):
				continue
			if world.dist_to_pond(px, pz) < World.POND_RADIUS * 1.8:
				continue
			var s := rng.randf_range(0.75, 1.35) * (1.0 + smoothstep(250.0, 420.0, r) * 0.4)
			_add(buckets, "pine%d" % rng.randi_range(0, 2), _xform(world, px, pz, s, rng), Color(0, 0, 0, 0))
			if r < World.PLAY_RADIUS + 40.0:
				world.add_blocker(px, pz, 0.45 * s)
		x += step

	# Broadleaf groves at forest edges and the odd tree in the meadow.
	x = -260.0
	while x < 260.0:
		var z := -260.0
		while z < 260.0:
			var px := x + rng.randf_range(-4.0, 4.0)
			var pz := z + rng.randf_range(-4.0, 4.0)
			z += 10.0
			var f := world.forest_at(px, pz)
			var edge := f * (1.0 - f) * 4.0
			var chance := edge * 0.35 + 0.012
			if rng.randf() > chance or World.path_dist(px, pz) < 7.0 or world.is_water(px, pz):
				continue
			if world.dist_to_pond(px, pz) < World.POND_RADIUS * 1.5:
				continue
			var s := rng.randf_range(0.8, 1.25)
			_add(buckets, "broad%d" % rng.randi_range(0, 1), _xform(world, px, pz, s, rng), Color(0.3, 0.5, 0.2, 0.0))
			world.add_blocker(px, pz, 0.4 * s)
		x += 10.0

	# Blossom trees: two rows framing the path toward the sunset, plus a few
	# scattered through the flower fields.
	var zz := 52.0
	while zz > -120.0:
		for side in [-1.0, 1.0]:
			var off: float = side * rng.randf_range(12.5, 15.5)
			var pz := zz + rng.randf_range(-2.0, 2.0)
			var px := World.path_x(pz) + off
			if world.is_water(px, pz) or world.forest_at(px, pz) > 0.5:
				continue
			var s := rng.randf_range(0.85, 1.15)
			var col: Color = BLOSSOM_PINK if rng.randf() < 0.75 else BLOSSOM_WHITE
			_add(buckets, "blossom%d" % rng.randi_range(0, 1), _xform(world, px, pz, s, rng), col)
			world.add_blocker(px, pz, 0.35 * s)
		zz -= rng.randf_range(10.0, 13.0)
	for i in 70:
		var px := rng.randf_range(-170.0, 170.0)
		var pz := rng.randf_range(-170.0, 170.0)
		if world.flowers_at(px, pz) < 0.3 or World.path_dist(px, pz) < 8.0 or world.is_water(px, pz):
			continue
		var s := rng.randf_range(0.8, 1.2)
		var col: Color = [BLOSSOM_PINK, BLOSSOM_DEEP, BLOSSOM_WHITE][rng.randi_range(0, 2)]
		_add(buckets, "blossom%d" % rng.randi_range(0, 1), _xform(world, px, pz, s, rng), col)
		world.add_blocker(px, pz, 0.35 * s)
		_add_canopy_perches(world, px, pz, s, rng)

	for key in buckets:
		var mesh: Mesh
		var name: String = key.split(":")[0]
		if name.begins_with("pine"):
			mesh = pines[int(name.substr(4))]
		elif name.begins_with("broad"):
			mesh = broad[int(name.substr(5))]
		else:
			mesh = blossom[int(name.substr(7))]
		var b: Dictionary = buckets[key]
		_make_mmi(root, mesh, b["x"], b["c"], 420.0, true)


static func _add_canopy_perches(world: World, px: float, pz: float, s: float, rng: RandomNumberGenerator) -> void:
	var g := world.height_at(px, pz)
	for i in 3:
		var a := rng.randf() * TAU
		world.add_perch(Vector3(px + cos(a) * 1.6 * s, g + 3.4 * s, pz + sin(a) * 1.6 * s))


static func _place_hedges_and_bushes(world: World, root: Node3D, rng: RandomNumberGenerator) -> void:
	var bush := _bush_mesh()
	var buckets := {}
	var gap_noise := FastNoiseLite.new()
	gap_noise.seed = 77
	gap_noise.frequency = 0.05
	# Flowering hedges lining the path, like rows in an orchard at dusk.
	var z := 70.0
	while z > -75.0:
		for side in [-1.0, 1.0]:
			var n := gap_noise.get_noise_2d(z, side * 10.0)
			if n < -0.38:
				continue
			var off: float = side * (3.5 + n * 0.5)
			var px := World.path_x(z) + off
			var pz := z + rng.randf_range(-0.2, 0.2)
			if world.is_water(px, pz):
				continue
			var sx := rng.randf_range(1.0, 1.4)
			var sy := rng.randf_range(0.75, 1.05)
			var t := _xform_scaled(world, px, pz, Vector3(sx, sy, sx * 1.15), rng, -0.15)
			var col: Color = BLOSSOM_PINK if rng.randf() < 0.8 else BLOSSOM_DEEP
			_add(buckets, "bush", t, col)
			world.add_blocker(px, pz, 0.55)
			world.add_perch(Vector3(px, t.origin.y + 1.25 * sy, pz))
		z -= rng.randf_range(0.95, 1.15)
	# Loose flowering shrubs in the flower meadows.
	for i in 900:
		var px := rng.randf_range(-185.0, 185.0)
		var pz := rng.randf_range(-185.0, 185.0)
		var f := world.flowers_at(px, pz)
		if f < 0.25 or rng.randf() > f or World.path_dist(px, pz) < 5.0 or world.is_water(px, pz):
			continue
		var s := rng.randf_range(0.6, 1.1)
		var t := _xform_scaled(world, px, pz, Vector3(s, s * rng.randf_range(0.7, 0.95), s), rng, -0.1)
		var col: Color = [BLOSSOM_PINK, BLOSSOM_LILAC, BLOSSOM_WHITE, BLOSSOM_DEEP][rng.randi_range(0, 3)]
		_add(buckets, "bush", t, col)
		world.add_perch(Vector3(px, t.origin.y + 1.2 * s, pz))
		if s > 0.85:
			world.add_blocker(px, pz, 0.4 * s)
	for key in buckets:
		var b: Dictionary = buckets[key]
		_make_mmi(root, bush, b["x"], b["c"], 260.0, true)


static func _place_rocks(world: World, root: Node3D, rng: RandomNumberGenerator) -> void:
	var rocks := [_rock_mesh(5), _rock_mesh(6)]
	var buckets := {}
	for i in 700:
		var px := rng.randf_range(-400.0, 400.0)
		var pz := rng.randf_range(-400.0, 400.0)
		var r := Vector2(px, pz).length()
		if World.path_dist(px, pz) < 4.0 or world.is_water(px, pz) or r > 420.0:
			continue
		var slope := 1.0 - world.normal_at(px, pz).y
		if rng.randf() > 0.25 + slope * 3.0 + smoothstep(160.0, 300.0, r) * 0.4:
			continue
		var s := rng.randf_range(0.4, 1.6) * (1.0 + slope * 2.0)
		var t := _xform_scaled(world, px, pz, Vector3(s, s * rng.randf_range(0.6, 1.0), s * rng.randf_range(0.8, 1.2)), rng, -0.25 * s)
		_add(buckets, "rock%d" % rng.randi_range(0, 1), t, Color(0, 0, 0, 0))
		if r < World.PLAY_RADIUS + 30.0 and s > 0.7:
			world.add_blocker(px, pz, 0.7 * s)
	for key in buckets:
		var b: Dictionary = buckets[key]
		var name: String = key.split(":")[0]
		_make_mmi(root, rocks[int(name.substr(4))], b["x"], b["c"], 380.0, true)


static func _place_flowers(world: World, root: Node3D, rng: RandomNumberGenerator) -> void:
	var mesh := _flower_mesh()
	var palette_noise := FastNoiseLite.new()
	palette_noise.seed = 19
	palette_noise.frequency = 0.03
	var buckets := {}
	var lim := 210.0
	var tx := -lim
	while tx < lim:
		var tz := -lim
		while tz < lim:
			var candidates := int(FLOWER_CHUNK * FLOWER_CHUNK * 0.75)
			for i in candidates:
				var px := tx + rng.randf() * FLOWER_CHUNK
				var pz := tz + rng.randf() * FLOWER_CHUNK
				var f := world.flowers_at(px, pz)
				var chance := pow(f, 1.4) * 0.9 + 0.012
				if rng.randf() > chance:
					continue
				if World.path_dist(px, pz) < 1.8 or world.is_water(px, pz) or world.forest_at(px, pz) > 0.6:
					continue
				var pn := palette_noise.get_noise_2d(px, pz) * 0.5 + 0.5
				var idx := 0
				var roll := rng.randf()
				if roll < 0.55:
					idx = 0 if pn > 0.45 else 3
				elif roll < 0.75:
					idx = 1 if pn > 0.5 else 5
				elif roll < 0.9:
					idx = [2, 4][int(pn * 2.0) % 2]
				else:
					idx = rng.randi_range(0, FLOWER_COLORS.size() - 1)
				var col: Color = FLOWER_COLORS[idx]
				col.a = rng.randf_range(0.5, 0.8)
				var s := rng.randf_range(0.75, 1.3)
				var t := _xform_scaled(world, px, pz, Vector3(s, s * rng.randf_range(0.85, 1.25), s), rng, -0.02)
				_add(buckets, "f", t, col, FLOWER_CHUNK)
				if rng.randf() < 0.08:
					world.add_perch(Vector3(px, t.origin.y + 0.42 * s, pz))
			tz += FLOWER_CHUNK
		tx += FLOWER_CHUNK
	for key in buckets:
		var b: Dictionary = buckets[key]
		_make_mmi(root, mesh, b["x"], b["c"], 75.0, false)


static func _build_pond(world: World, root: Node3D, rng: RandomNumberGenerator) -> void:
	var plane := PlaneMesh.new()
	var w := World.POND_RADIUS * 3.4
	plane.size = Vector2(w, w)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	plane.material = mat
	var water := MeshInstance3D.new()
	water.name = "Pond"
	water.mesh = plane
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position = Vector3(World.POND_CENTER.x, world.water_level, World.POND_CENTER.y)
	root.add_child(water)

	# Lily pads, some with a flower.
	var pad := _lily_mesh()
	var xs := []
	for i in 22:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.3, 0.95) * World.POND_RADIUS
		var px := World.POND_CENTER.x + cos(a) * d
		var pz := World.POND_CENTER.y + sin(a) * d
		if not world.is_water(px, pz):
			continue
		var s := rng.randf_range(0.6, 1.2)
		var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, 1.0, s)), Vector3(px, world.water_level + 0.02, pz))
		xs.append(t)
		if rng.randf() < 0.4:
			world.add_perch(Vector3(px, world.water_level + 0.08, pz))
	_make_mmi(root, pad, xs, [], 200.0, false)


static func _build_horizon(world: World, root: Node3D, rng: RandomNumberGenerator) -> void:
	# A wide ground ring beyond the terrain so the land runs to the horizon.
	var ring := _ring_mesh(470.0, 6000.0, 48, Color(0.2, 0.3, 0.2))
	var ring_mi := MeshInstance3D.new()
	ring_mi.mesh = ring
	ring_mi.position.y = 12.0
	ring_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring_mi)
	# Distant purple mountains.
	for i in 20:
		var a := TAU * i / 20.0 + rng.randf_range(-0.12, 0.12)
		var d := rng.randf_range(850.0, 1700.0)
		var h := rng.randf_range(110.0, 280.0) * (d / 1200.0)
		# Keep every mountain's foot well outside the playable valley.
		var rad := minf(h * rng.randf_range(2.0, 3.2), d - 560.0)
		var m := _mountain_mesh(rng.randi(), rad, h)
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.position = Vector3(cos(a) * d, 0.0, sin(a) * d)
		mi.rotation.y = rng.randf() * TAU
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)


# --------------------------------------------------------------- helpers

static func _xform(world: World, x: float, z: float, s: float, rng: RandomNumberGenerator) -> Transform3D:
	return _xform_scaled(world, x, z, Vector3(s, s, s), rng, -0.2)


static func _xform_scaled(world: World, x: float, z: float, s: Vector3, rng: RandomNumberGenerator, sink: float) -> Transform3D:
	var b := Basis(Vector3.UP, rng.randf() * TAU)
	b = b * Basis.from_scale(s)
	return Transform3D(b, Vector3(x, world.height_at(x, z) + sink, z))


static func _add(buckets: Dictionary, kind: String, t: Transform3D, custom: Color, chunk := CHUNK) -> void:
	var key := "%s:%d:%d" % [kind, floori(t.origin.x / chunk), floori(t.origin.z / chunk)]
	if not buckets.has(key):
		buckets[key] = {"x": [], "c": []}
	buckets[key]["x"].append(t)
	buckets[key]["c"].append(custom)


static func _make_mmi(parent: Node3D, mesh: Mesh, xforms: Array, customs: Array, vis_end: float, shadows: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = customs.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	var stride := 16 if mm.use_custom_data else 12
	var buf := PackedFloat32Array()
	buf.resize(stride * xforms.size())
	for i in xforms.size():
		var t: Transform3D = xforms[i]
		var o := i * stride
		buf[o] = t.basis.x.x
		buf[o + 1] = t.basis.y.x
		buf[o + 2] = t.basis.z.x
		buf[o + 3] = t.origin.x
		buf[o + 4] = t.basis.x.y
		buf[o + 5] = t.basis.y.y
		buf[o + 6] = t.basis.z.y
		buf[o + 7] = t.origin.y
		buf[o + 8] = t.basis.x.z
		buf[o + 9] = t.basis.y.z
		buf[o + 10] = t.basis.z.z
		buf[o + 11] = t.origin.z
		if mm.use_custom_data:
			var c: Color = customs[i]
			buf[o + 12] = c.r
			buf[o + 13] = c.g
			buf[o + 14] = c.b
			buf[o + 15] = c.a
	if xforms.size() > 0:
		mm.buffer = buf
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if vis_end > 0.0:
		mmi.visibility_range_end = vis_end
		mmi.visibility_range_end_margin = vis_end * 0.1
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


static func _vert(st: SurfaceTool, v: Vector3, n: Vector3, col: Color, sway: float) -> void:
	st.set_color(col)
	st.set_normal(n)
	st.set_uv(Vector2(0.0, sway))
	st.add_vertex(v)


static func _tube(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, segs: int, col: Color, sway_a: float, sway_b: float) -> void:
	var axis := (b - a).normalized()
	var side := axis.cross(Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var side2 := axis.cross(side).normalized()
	for s in segs:
		var a0 := TAU * s / segs
		var a1 := TAU * (s + 1) / segs
		var n0 := side * cos(a0) + side2 * sin(a0)
		var n1 := side * cos(a1) + side2 * sin(a1)
		var dark := col.darkened(0.15)
		_vert(st, a + n0 * ra, n0, dark, sway_a)
		_vert(st, b + n0 * rb, n0, col, sway_b)
		_vert(st, b + n1 * rb, n1, col, sway_b)
		_vert(st, a + n0 * ra, n0, dark, sway_a)
		_vert(st, b + n1 * rb, n1, col, sway_b)
		_vert(st, a + n1 * ra, n1, dark, sway_a)


static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, rng: RandomNumberGenerator, col: Color, sway: float, rings := 7, segs := 10) -> void:
	var pts := []
	for i in rings + 1:
		var row := []
		var phi := PI * i / rings
		for j in segs + 1:
			var th := TAU * j / segs
			var n := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var jitter := 1.0 + (rng.randf() - 0.5) * 0.18 if (i > 0 and i < rings and j < segs) else 1.0
			row.append([c + n * r * jitter, n])
		row[segs] = [row[0][0], row[0][1]]
		pts.append(row)
	for i in rings:
		for j in segs:
			var p00: Array = pts[i][j]
			var p01: Array = pts[i][j + 1]
			var p10: Array = pts[i + 1][j]
			var p11: Array = pts[i + 1][j + 1]
			for q in [p00, p10, p11, p00, p11, p01]:
				var v: Vector3 = q[0]
				var shade := col.darkened(clampf(-q[1].y * 0.3, 0.0, 0.3))
				_vert(st, v, q[1], shade, sway)


static func _ring_mesh(inner: float, outer: float, segs: int, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in segs:
		var a0 := TAU * s / segs
		var a1 := TAU * (s + 1) / segs
		var i0 := Vector3(cos(a0) * inner, 0, sin(a0) * inner)
		var i1 := Vector3(cos(a1) * inner, 0, sin(a1) * inner)
		var o0 := Vector3(cos(a0) * outer, -60.0, sin(a0) * outer)
		var o1 := Vector3(cos(a1) * outer, -60.0, sin(a1) * outer)
		for v in [i0, o1, o0, i0, i1, o1]:
			_vert(st, v, Vector3.UP, col, 0.0)
	var m := st.commit()
	m.surface_set_material(0, _foliage_mat)
	return m


# ----------------------------------------------------------- mesh makers

static func _pine_mesh(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := rng.randf_range(10.0, 13.0)
	_tube(st, Vector3.ZERO, Vector3(0, 3.5, 0), 0.32, 0.16, 7, Color(0.32, 0.22, 0.17), 0.0, 0.2)
	var tiers := 7
	for t in tiers:
		var f := float(t) / tiers
		var y0 := 1.7 + f * (height - 3.4)
		var rad := lerpf(2.9, 0.75, f) * rng.randf_range(0.9, 1.1)
		var top := y0 + lerpf(2.5, 1.7, f)
		var segs := 11
		var col_low := Color(0.1, 0.2, 0.19).lerp(Color(0.15, 0.29, 0.24), f)
		var col_high := Color(0.2, 0.36, 0.28).lerp(Color(0.3, 0.46, 0.32), f)
		var ring := []
		for s in segs:
			var a := TAU * s / segs + rng.randf() * 0.25
			var r := rad * rng.randf_range(0.72, 1.15)
			ring.append(Vector3(cos(a) * r, y0 - rng.randf_range(0.25, 0.7), sin(a) * r))
		var apex := Vector3(rng.randf_range(-0.12, 0.12), top, rng.randf_range(-0.12, 0.12))
		var inner := Vector3(0, y0 + 0.4, 0)
		var sway_apex := top / height
		for s in segs:
			var p0: Vector3 = ring[s]
			var p1: Vector3 = ring[(s + 1) % segs]
			var n0 := Vector3(p0.x, rad * 0.9, p0.z).normalized()
			var n1 := Vector3(p1.x, rad * 0.9, p1.z).normalized()
			_vert(st, apex, Vector3.UP, col_high, sway_apex)
			_vert(st, p1, n1, col_low, p1.y / height)
			_vert(st, p0, n0, col_low, p0.y / height)
			var under := col_low.darkened(0.45)
			_vert(st, p0, Vector3(n0.x, -0.6, n0.z).normalized(), under, p0.y / height)
			_vert(st, p1, Vector3(n1.x, -0.6, n1.z).normalized(), under, p1.y / height)
			_vert(st, inner, Vector3.DOWN, under, inner.y / height)
	var m := st.commit()
	m.surface_set_material(0, _foliage_mat)
	return m


static func _leafy_tree_mesh(seed_value: int, blossom: bool) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var trunk_h := rng.randf_range(2.4, 3.0) * (0.85 if blossom else 1.15)
	var bark := Color(0.36, 0.26, 0.2) if blossom else Color(0.34, 0.27, 0.2)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(rng.randf_range(-0.2, 0.2), trunk_h, rng.randf_range(-0.2, 0.2))
	_tube(st, Vector3.ZERO, top, 0.24, 0.15, 7, bark, 0.0, 0.3)
	var centers := []
	var n_blobs := rng.randi_range(6, 8)
	for i in n_blobs:
		var a := TAU * i / n_blobs + rng.randf_range(-0.3, 0.3)
		var out := rng.randf_range(0.9, 1.8)
		var c := top + Vector3(cos(a) * out, rng.randf_range(0.6, 1.9), sin(a) * out)
		centers.append(c)
		_tube(st, top, top.lerp(c, 0.75), 0.11, 0.05, 5, bark, 0.3, 0.6)
	centers.append(top + Vector3(0, 2.3, 0))
	var trunk_mat := _foliage_mat
	st.set_material(trunk_mat)
	var m := st.commit()

	var cst := SurfaceTool.new()
	cst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaf := Color(0.3, 0.45, 0.2)
	for c in centers:
		var r := rng.randf_range(1.1, 1.6)
		_blob(cst, c, Vector3(r, r * 0.8, r), rng, leaf, 0.7)
	cst.commit(m)
	m.surface_set_material(0, trunk_mat)
	m.surface_set_material(1, _bush_mat if blossom else _leaf_mat)
	return m


static func _bush_mesh() -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(0.3, 0.45, 0.2)
	_blob(st, Vector3(0, 0.62, 0), Vector3(0.75, 0.62, 0.75), rng, col, 0.6, 8, 12)
	_blob(st, Vector3(0.35, 0.5, 0.2), Vector3(0.5, 0.45, 0.5), rng, col, 0.5, 6, 9)
	_blob(st, Vector3(-0.3, 0.45, -0.25), Vector3(0.5, 0.42, 0.5), rng, col, 0.5, 6, 9)
	var m := st.commit()
	m.surface_set_material(0, _bush_mat)
	return m


static func _rock_mesh(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 7
	var segs := 10
	var pts := []
	for i in rings + 1:
		var row := []
		var phi := PI * i / rings
		for j in segs:
			var th := TAU * j / segs
			var n := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var d := 1.0 + noise.get_noise_3dv(n) * 0.35
			var v := n * d
			v.y = maxf(v.y * 0.75, -0.3)
			row.append(v)
		pts.append(row)
	for i in rings:
		for j in segs:
			var j1 := (j + 1) % segs
			var quad := [pts[i][j], pts[i + 1][j], pts[i + 1][j1], pts[i][j], pts[i + 1][j1], pts[i][j1]]
			var fn: Vector3 = (quad[1] - quad[0]).cross(quad[2] - quad[0]).normalized()
			if fn.dot(quad[0]) < 0.0:
				fn = -fn
			for v in quad:
				var moss := smoothstep(0.35, 0.8, fn.y)
				var col := Color(0.5, 0.48, 0.46).lerp(Color(0.33, 0.43, 0.2), moss)
				_vert(st, v, fn, col, 0.0)
	var m := st.commit()
	m.surface_set_material(0, _foliage_mat)
	return m


static func _flower_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heads := [Vector3(0.0, 0.4, 0.0), Vector3(0.09, 0.32, 0.05), Vector3(-0.07, 0.27, -0.06)]
	var sizes := [0.07, 0.06, 0.055]
	for i in heads.size():
		var h: Vector3 = heads[i]
		var w := 0.008
		var base := Vector3(h.x * 0.4, 0.0, h.z * 0.4)
		var side := Vector3(w, 0, 0)
		var quad := [[base - side, 0.0], [h - side, 1.0], [h + side, 1.0], [base - side, 0.0], [h + side, 1.0], [base + side, 0.0]]
		for q in quad:
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2(0, q[1]))
			st.set_uv2(Vector2(0, 0))
			st.add_vertex(q[0])
		var s: float = sizes[i]
		var tilt := Vector3(h.x, 0.0, h.z) * 1.5
		var corners := [Vector3(-s, 0, -s), Vector3(s, 0, -s), Vector3(s, 0, s), Vector3(-s, 0, s)]
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for k in [0, 1, 2, 0, 2, 3]:
			var c: Vector3 = corners[k]
			c.y += c.dot(tilt)
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[k])
			st.set_uv2(Vector2(1, 0))
			st.add_vertex(h + c)
	var m := st.commit()
	m.surface_set_material(0, _flower_mat)
	return m


static func _lily_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 14
	var r := 0.45
	var col := Color(0.25, 0.45, 0.2)
	for s in segs - 1:
		var a0 := 0.35 + (TAU - 0.7) * s / (segs - 1)
		var a1 := 0.35 + (TAU - 0.7) * (s + 1) / (segs - 1)
		_vert(st, Vector3.ZERO, Vector3.UP, col.lightened(0.1), 0.0)
		_vert(st, Vector3(cos(a1) * r, 0, sin(a1) * r), Vector3.UP, col, 0.0)
		_vert(st, Vector3(cos(a0) * r, 0, sin(a0) * r), Vector3.UP, col, 0.0)
	var m := st.commit()
	m.surface_set_material(0, _foliage_mat)
	return m


static func _mountain_mesh(seed_value: int, radius: float, height: float) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.frequency = 2.2
	noise.fractal_octaves = 4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 10
	var segs := 40
	var grid := []
	for i in rings + 1:
		var row := []
		var t := float(i) / rings
		for j in segs:
			var a := TAU * j / segs
			var dir := Vector2(cos(a), sin(a))
			var rr := radius * t
			var n := noise.get_noise_2d(dir.x * t * 1.5, dir.y * t * 1.5)
			var h := height * pow(1.0 - t, 1.5) * (0.75 + n * 0.45)
			if i == 0:
				h = height
			row.append(Vector3(dir.x * rr, h, dir.y * rr))
		grid.append(row)
	for i in rings:
		for j in segs:
			var j1 := (j + 1) % segs
			var quad := [grid[i][j], grid[i + 1][j], grid[i + 1][j1], grid[i][j], grid[i + 1][j1], grid[i][j1]]
			var fn: Vector3 = (quad[2] - quad[0]).cross(quad[1] - quad[0]).normalized()
			if fn.y < 0.0:
				fn = -fn
			for v in quad:
				var hf: float = v.y / height
				var col := Color(0.18, 0.26, 0.24).lerp(Color(0.44, 0.38, 0.5), smoothstep(0.1, 0.55, hf))
				col = col.lerp(Color(0.66, 0.6, 0.7), smoothstep(0.7, 0.95, hf))
				_vert(st, v, fn, col, 0.0)
	var m := st.commit()
	m.surface_set_material(0, _foliage_mat)
	return m
