class_name Handmade
extends RefCounted
## The things that show a person built this map by hand: masking tape
## holding corners and seams together, yarn wrapped round posts and tied
## over cargo, fat yarn cables, brass paper brads pinning wall panels, and
## blobs of hot glue where posts meet the floor.

static var rng := RandomNumberGenerator.new()
static var _torus: TorusMesh


static func build(map: GatewayMap) -> void:
	rng.seed = 13579
	var root := Node3D.new()
	root.name = "Handmade"
	map.deco.add_child(root)
	_tape(root)
	_yarn(root)
	_brads(root)
	_glue(root)


# ----------------------------------------------------------------- tape

static func _tape_mat(kind := 0) -> Material:
	match kind:
		1:
			return Craft.mat(Craft.Kind.TAPE, Color(0.36, 0.52, 0.72), 0, Color.WHITE, 1.0, 0.0, false)
		2:
			return Craft.mat(Craft.Kind.FOIL, Color(0.72, 0.73, 0.76), 0, Color.WHITE, 1.0, 0.0, false)
	return Craft.mat(Craft.Kind.TAPE, Color(0.86, 0.8, 0.64), 0, Color.WHITE, 1.0, 0.0, false)


## Tape folded round a vertical corner: one strip on each face, each
## running away from the corner. out_a / out_b point out of the two faces.
static func corner_tape(parent: Node3D, corner: Vector3, out_a: Vector3, out_b: Vector3, y0: float, y1: float, m: Material) -> void:
	var h := y1 - y0
	var w := 0.11
	var cy := (y0 + y1) * 0.5
	for f in [[out_a, -out_b], [out_b, -out_a]]:
		var out: Vector3 = f[0]
		var away: Vector3 = f[1]
		var p := corner + out * 0.006 + away * (w * 0.5)
		p.y = cy
		Craft.box(parent, p, Vector3(w if absf(away.x) > 0.5 else 0.004, h, w if absf(away.z) > 0.5 else 0.004), m, Vector3(0, 0, rng.randf_range(-0.006, 0.006)), false)


## A strip of tape stuck flat on a wall (facing `out`), slightly crooked.
static func strip(parent: Node3D, centre: Vector3, out: Vector3, length: float, angle: float, m: Material, width := 0.1) -> void:
	var t := Craft.box(parent, centre + out * 0.006, Vector3.ONE, m, Vector3.ZERO, false)
	t.look_at_from_position(centre + out * 0.006, centre + out, Vector3.UP if absf(out.y) < 0.9 else Vector3.FORWARD)
	t.rotate_object_local(Vector3.FORWARD, angle)
	t.scale = Vector3(width, length, 0.004)


## Tape folded over a roof edge: down the wall face and onto the roof.
static func fold_over(parent: Node3D, top: Vector3, out: Vector3, m: Material) -> void:
	var down := rng.randf_range(0.35, 0.6)
	var over := rng.randf_range(0.25, 0.45)
	var yaw := atan2(out.x, out.z)
	Craft.box(parent, top + out * 0.006 - Vector3(0, down * 0.5, 0), Vector3(0.11, down, 0.004), m, Vector3(0, yaw, rng.randf_range(-0.05, 0.05)), false)
	Craft.box(parent, top - out * (over * 0.5) + Vector3(0, 0.004, 0), Vector3(0.11, 0.004, over), m, Vector3(0, yaw, 0), false)


static func _tape(root: Node3D) -> void:
	var beige := _tape_mat(0)
	var blue := _tape_mat(1)
	var silver := _tape_mat(2)
	# Building corners: terminal and baggage hall.
	var buildings := [[Vector3(-58.25, 0, -30.25), Vector3(-13.75, 8.4, 22.25)], [Vector3(-14.2, 0, -38.2), Vector3(32.2, 5.3, -25.8)]]
	for bld in buildings:
		var lo: Vector3 = bld[0]
		var hi: Vector3 = bld[1]
		var corners := [
			[Vector3(lo.x, 0, lo.z), Vector3.LEFT, Vector3.FORWARD], [Vector3(hi.x, 0, lo.z), Vector3.RIGHT, Vector3.FORWARD],
			[Vector3(hi.x, 0, hi.z), Vector3.RIGHT, Vector3.BACK], [Vector3(lo.x, 0, hi.z), Vector3.LEFT, Vector3.BACK],
		]
		for c in corners:
			corner_tape(root, c[0], c[1], c[2], 0.05, hi.y - 0.05, beige)
		# Pieces of tape folded over the roof edge every few metres.
		for side in [[Vector3.BACK, hi.z, lo.x, hi.x, true], [Vector3.FORWARD, lo.z, lo.x, hi.x, true], [Vector3.RIGHT, hi.x, lo.z, hi.z, false], [Vector3.LEFT, lo.x, lo.z, hi.z, false]]:
			var out: Vector3 = side[0]
			var fixed: float = side[1]
			var a: float = side[2]
			var b: float = side[3]
			var along_x: bool = side[4]
			var t := a + rng.randf_range(1.0, 2.5)
			while t < b - 0.5:
				var top := Vector3(t, hi.y, fixed) if along_x else Vector3(fixed, hi.y, t)
				fold_over(root, top, out, beige if rng.randf() < 0.8 else blue)
				t += rng.randf_range(2.5, 4.5)
	# Seam tape on the terminal's tarmac face (x = -13.73), between windows.
	var face := Vector3.RIGHT
	var z := -28.8
	while z < 21.5:
		var in_door := (z > -29.2 and z < -26.3) or (z > -6.2 and z < -1.8) or (z > 9.8 and z < 14.2)
		if not in_door and rng.randf() < 0.55:
			strip(root, Vector3(-13.73, 0.55, z), face, rng.randf_range(0.7, 0.9), rng.randf_range(-0.04, 0.04), beige)
			if z < -12.0 or z > 21.0 or (z > 9.0 and z < 15.0):
				strip(root, Vector3(-13.73, 3.6, z), face, rng.randf_range(0.8, 1.4), rng.randf_range(-0.05, 0.05), beige)
		z += 1.6
	# South face of the terminal and the baggage hall's tarmac face.
	var x := -57.6
	while x < -14.0:
		if not (x > -40.4 and x < -35.6) and rng.randf() < 0.5:
			strip(root, Vector3(x, 0.55, 22.27), Vector3.BACK, rng.randf_range(0.7, 0.9), rng.randf_range(-0.04, 0.04), beige)
		x += 1.6
	x = -12.8
	while x < 31.5:
		var door := (x > -6.3 and x < -1.7) or (x > 7.7 and x < 12.3) or (x > 21.7 and x < 26.3)
		if not door and rng.randf() < 0.5:
			strip(root, Vector3(x, 0.5, -25.78), Vector3.BACK, rng.randf_range(0.6, 0.9), rng.randf_range(-0.04, 0.04), blue if rng.randf() < 0.3 else beige)
		x += 1.6
	# Crossed-tape repairs on walls, the way a crafter patches a dent.
	for r in [[Vector3(-13.73, 1.8, -27.5), Vector3.RIGHT], [Vector3(-13.73, 3.8, 0.5), Vector3.RIGHT], [Vector3(-50.0, 1.7, 22.27), Vector3.BACK],
			[Vector3(-25.0, 3.9, 22.27), Vector3.BACK], [Vector3(14.0, 3.2, -25.78), Vector3.BACK], [Vector3(29.5, 1.6, -25.78), Vector3.BACK]]:
		var m: Material = silver if rng.randf() < 0.4 else beige
		strip(root, r[0], r[1], 0.6, 0.7, m, 0.11)
		strip(root, r[0] + r[1] * 0.002, r[1], 0.6, -0.7, m, 0.11)


# ----------------------------------------------------------------- yarn

## Yarn wound round a post: stacked loops, merged into one mesh.
static func yarn_wrap(parent: Node3D, centre: Vector3, radius: float, y0: float, y1: float, col: Color) -> void:
	if _torus == null:
		_torus = TorusMesh.new()
		_torus.inner_radius = 0.8
		_torus.outer_radius = 1.0
		_torus.rings = 14
		_torus.ring_segments = 6
	var st := SurfaceTool.new()
	var pitch := 0.026
	var n := int((y1 - y0) / pitch)
	for i in n:
		var tilt := 0.08 if i % 2 == 0 else -0.08
		var s := radius + 0.014
		var b := Basis.from_euler(Vector3(tilt, rng.randf() * TAU, 0)) * Basis.from_scale(Vector3(s, 0.14, s))
		st.append_from(_torus, 0, Transform3D(b, centre + Vector3(0, y0 + i * pitch, 0)))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Craft.mat(Craft.Kind.KNIT, col, 0, Color.WHITE, 3.0, 0.0, false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	# The loose tail and knot.
	Craft.part(parent, Craft.sphere(0.035, 8), mi.material_override, centre + Vector3(radius + 0.02, y1 - 0.02, 0))
	Craft.part(parent, Craft.capsule(0.01, 0.22), mi.material_override, centre + Vector3(radius + 0.04, y1 - 0.12, 0.02), Vector3(0.2, 0, 0.25))


## A fat yarn cable lying along a path (a list of Vector3 points).
static func cable(parent: Node3D, pts: Array, col: Color, r := 0.035) -> void:
	var m := Craft.mat(Craft.Kind.KNIT, col, 0, Color.WHITE, 4.0, 0.0, false)
	var st := SurfaceTool.new()
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var len := a.distance_to(b)
		var cap := Craft.capsule(r, len + r * 2.0)
		var dir := (b - a).normalized()
		var ref := Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
		var x := dir.cross(ref).normalized()
		var z := x.cross(dir).normalized()
		st.append_from(cap, 0, Transform3D(Basis(x, dir, z), (a + b) * 0.5))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	parent.add_child(mi)


static func _yarn(root: Node3D) -> void:
	var cols := [Color(0.18, 0.18, 0.2), Color(0.84, 0.66, 0.18), Color(0.5, 0.52, 0.55), Color(0.4, 0.4, 0.3), Color(0.82, 0.4, 0.14)]
	# Floodlight masts and jet bridge legs.
	for p: Vector3 in [Vector3(0, 0, -24), Vector3(56, 0, -34), Vector3(56, 0, 23), Vector3(14, 0, 23)]:
		yarn_wrap(root, p, 0.22, 0.9, 1.12, cols[rng.randi() % cols.size()])
	for p: Vector3 in [Vector3(-8, 0, -9), Vector3(-1, 0, -8.8)]:
		yarn_wrap(root, p, 0.3, 1.2, 2.0, cols[rng.randi() % cols.size()])
	# Every few fence posts gets a wrap of yarn holding the fence on.
	var lines := [[Vector3(32, 0, -38), Vector3(60, 0, -38)], [Vector3(60, 0, -38), Vector3(60, 0, 26)], [Vector3(60, 0, 26), Vector3(-58, 0, 26)]]
	for l in lines:
		var a: Vector3 = l[0]
		var c: Vector3 = l[1]
		var n := int(a.distance_to(c) / 3.0)
		for i in n + 1:
			if i % 3 != 0:
				continue
			var p := a.lerp(c, float(i) / n)
			yarn_wrap(root, p, 0.08, 1.9, 2.3, cols[i % cols.size()])
	# Concrete terminal pillars get a yellow-and-black impact band.
	for p: Vector3 in [Vector3(-44, 0, -8), Vector3(-32, 0, -8), Vector3(-44, 0, 12), Vector3(-32, 0, 12)]:
		yarn_wrap(root, p, 0.66, 0.15, 0.6, Color(0.84, 0.66, 0.18))
	# Ground power cable from the power cart to the airliner's nose.
	var cab := []
	for i in 16:
		var t := i / 15.0
		var p := Vector3(lerpf(-6.6, -4.2, t) + sin(t * 4.0) * 0.6, 0.06, lerpf(0.8, -2.2, t))
		if t > 0.75:
			p.y = lerpf(0.06, 2.0, (t - 0.75) / 0.25)
		cab.append(p)
	cable(root, cab, Color(0.15, 0.15, 0.17), 0.045)
	# A long extension cable snaking along the baggage hall wall.
	var ext := []
	for i in 30:
		var t := i / 29.0
		ext.append(Vector3(lerpf(-12.0, 30.0, t), 0.06, -25.2 + sin(t * 9.0) * 0.25))
	cable(root, ext, Color(0.82, 0.42, 0.14), 0.03)
	# Tie-down straps knotted over the cargo containers.
	for c: Vector3 in [Vector3(5, 0, -18.5), Vector3(7.3, 0, -18.3), Vector3(40, 0, -18), Vector3(42.3, 0, -18.2), Vector3(46, 0, 7), Vector3(48.4, 0, 7.4)]:
		var m := Craft.mat(Craft.Kind.KNIT, cols[rng.randi() % cols.size()], 0, Color.WHITE, 3.0, 0.0)
		for dx: float in [-0.5, 0.5]:
			Craft.box(root, c + Vector3(dx, 1.62, 0), Vector3(0.06, 0.03, 1.62), m)
			Craft.box(root, c + Vector3(dx, 0.85, -0.79), Vector3(0.06, 1.6, 0.03), m)
			Craft.part(root, Craft.sphere(0.05, 8), m, c + Vector3(dx, 1.64, -0.6))


# ---------------------------------------------------------------- brads

## Brass paper brads pinning the wall panels, as a multimesh.
static func _brads(root: Node3D) -> void:
	var xforms := []
	var add := func(p: Vector3, out: Vector3):
		var b := Basis.looking_at(out, Vector3.UP) * Basis.from_euler(Vector3(PI * 0.5, 0, 0))
		xforms.append(Transform3D(b, p + out * 0.012))
	for y: float in [0.3, 7.7]:
		var z := -29.6
		while z < 22.0:
			add.call(Vector3(-13.75, y, z), Vector3.RIGHT)
			add.call(Vector3(-58.25, y, z), Vector3.LEFT)
			z += 1.6
		var x := -57.6
		while x < -14.0:
			add.call(Vector3(x, y, 22.25), Vector3.BACK)
			add.call(Vector3(x, y, -30.25), Vector3.FORWARD)
			x += 1.6
	for y: float in [0.3, 4.75]:
		var x := -13.6
		while x < 32.0:
			add.call(Vector3(x, y, -25.8), Vector3.BACK)
			x += 1.6
	var mesh := Craft.cylinder(0.045, 0.05, 0.022, 12)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Craft.mat(Craft.Kind.FOIL, Color(0.86, 0.68, 0.3), 0, Color.WHITE, 1.0, 0.0, false)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


# ----------------------------------------------------------------- glue

## Hot-glue blobs where posts and props were stuck to the base.
static func _glue(root: Node3D) -> void:
	var glue := Craft.cellophane(Color(1.0, 0.95, 0.8, 0.55))
	var spots := []
	for p: Vector3 in [Vector3(0, 0, -24), Vector3(56, 0, -34), Vector3(56, 0, 23), Vector3(14, 0, 23)]:
		spots.append([p, 0.36])
	for p: Vector3 in [Vector3(-8, 0, -9), Vector3(-1, 0, -8.8), Vector3(-3, 0, -2), Vector3(17, 0, -4.2), Vector3(17, 0, 0.2)]:
		spots.append([p, 0.4])
	for l in [[Vector3(32, 0, -38), Vector3(60, 0, -38)], [Vector3(60, 0, -38), Vector3(60, 0, 26)], [Vector3(60, 0, 26), Vector3(-58, 0, 26)]]:
		var a: Vector3 = l[0]
		var c: Vector3 = l[1]
		var n := int(a.distance_to(c) / 3.0)
		for i in n + 1:
			spots.append([a.lerp(c, float(i) / n), 0.12])
	var st := SurfaceTool.new()
	var blob := Craft.sphere(1.0, 10)
	for s in spots:
		var p: Vector3 = s[0]
		var r: float = s[1]
		for k in 3:
			var off := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * r * rng.randf_range(0.7, 1.0)
			var size := r * rng.randf_range(0.25, 0.45)
			st.append_from(blob, 0, Transform3D(Basis.from_scale(Vector3(size, size * 0.35, size * 1.2)).rotated(Vector3.UP, rng.randf() * TAU), p + off + Vector3(0, 0.03, 0)))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = glue
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
