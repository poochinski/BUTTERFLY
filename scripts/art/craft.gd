class_name Craft
extends RefCounted
## The art-supply cupboard: cached craft materials and the mesh kit every
## builder (map, props, weapons, soldiers) uses. Keeping materials cached
## means the whole game shares a handful of shader variants.

enum Kind { CARDBOARD, PAPER, FELT, KNIT, TAPE, PLASTIC, FOIL, GLOW }
enum Pattern { NONE, HAZARD, DOTS, CHECKER, WINDOWS, STITCH, BANDS, FLOOR, WALL, CAMO, PLANKS }

const CRAFT_SHADER := preload("res://shaders/craft.gdshader")
const CRAFT_VM_SHADER := preload("res://shaders/craft_vm.gdshader")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
const OUTLINE_VM_SHADER := preload("res://shaders/outline_vm.gdshader")
const CELLO_SHADER := preload("res://shaders/cellophane.gdshader")

# A real-world palette: the colours of an actual airport, as a hobbyist
# would match them with paint swatches and craft-store paper (see
# docs/ART_DIRECTION.md). Saturated colour is kept for safety paint,
# signage and liveries.
const KRAFT := Color(0.68, 0.52, 0.36)
const KRAFT_DARK := Color(0.5, 0.38, 0.27)
const CREAM := Color(0.85, 0.82, 0.75)
const INK := Color(0.15, 0.13, 0.12)
const TEAL := Color(0.22, 0.42, 0.46)
const PINK := Color(0.58, 0.38, 0.38)
const PURPLE := Color(0.36, 0.38, 0.46)
const ORANGE := Color(0.84, 0.4, 0.13)
const YELLOW := Color(0.88, 0.69, 0.16)
const GRASS := Color(0.3, 0.4, 0.21)
const RED := Color(0.64, 0.17, 0.14)
const BLUE := Color(0.17, 0.24, 0.38)
const SLATE := Color(0.42, 0.45, 0.5)
const ASPHALT := Color(0.27, 0.28, 0.3)
const WHITE := Color(0.88, 0.87, 0.84)
const CONCRETE := Color(0.7, 0.68, 0.64)
const CONCRETE_DARK := Color(0.5, 0.49, 0.47)
const ALUMINIUM := Color(0.68, 0.7, 0.72)
const OLIVE := Color(0.36, 0.38, 0.26)

static var _mats := {}
static var _meshes := {}


## Material for a craft supply. Identical requests share one material.
static func mat(kind: int, color: Color, pattern := 0, color2 := Color.WHITE, pattern_scale := 1.0, wear := 1.0, box_edges := true, viewmodel := false) -> ShaderMaterial:
	var key := "%d|%s|%d|%s|%.3f|%.2f|%s|%s" % [kind, color.to_html(), pattern, color2.to_html(), pattern_scale, wear, box_edges, viewmodel]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = CRAFT_VM_SHADER if viewmodel else CRAFT_SHADER
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("color2", color2)
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("pattern_scale", pattern_scale)
	m.set_shader_parameter("wear", wear)
	m.set_shader_parameter("box_edges", box_edges)
	_mats[key] = m
	return m


## Felt (or paper) for cut pieces: their side walls show a cut edge, and
## merged meshes can tint each piece through vertex colours.
static func felt_piece(color: Color, kind := Kind.FELT, side_mode := 2, vertex_color := true, pattern := 0, color2 := Color.WHITE, pattern_scale := 1.0) -> ShaderMaterial:
	var key := "piece|%d|%s|%d|%s|%d|%s|%.3f" % [kind, color.to_html(), side_mode, vertex_color, pattern, color2.to_html(), pattern_scale]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = CRAFT_SHADER
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("color2", color2)
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("pattern_scale", pattern_scale)
	m.set_shader_parameter("wear", 0.0)
	m.set_shader_parameter("box_edges", false)
	m.set_shader_parameter("side_mode", side_mode)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	_mats[key] = m
	return m


## Same material with an ink outline pass (for characters, weapons, props).
static func outlined(base: ShaderMaterial, width := 0.012, viewmodel := false) -> ShaderMaterial:
	var key := "outline|%d|%.4f|%s" % [base.get_instance_id(), width, viewmodel]
	if _mats.has(key):
		return _mats[key]
	var m := base.duplicate() as ShaderMaterial
	var o := ShaderMaterial.new()
	o.shader = OUTLINE_VM_SHADER if viewmodel else OUTLINE_SHADER
	o.set_shader_parameter("width", width)
	m.next_pass = o
	_mats[key] = m
	return m


## A copy of a craft material for something that moves: its seed is fixed,
## so its fibres, tint and camo stay put instead of re-rolling every frame.
static func moving(m: Material) -> Material:
	if not m is ShaderMaterial or m.has_meta("moving"):
		return m
	var sm := m as ShaderMaterial
	if sm.shader != CRAFT_SHADER:
		return m
	var key := "moving|%d" % sm.get_instance_id()
	if _mats.has(key):
		return _mats[key]
	var d := sm.duplicate() as ShaderMaterial
	d.set_shader_parameter("seed_override", 0.37)
	d.set_meta("moving", true)
	_mats[key] = d
	return d


## Give every craft material under a node its moving variant.
static func make_moving(root: Node) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is GeometryInstance3D:
			var g := n as GeometryInstance3D
			if g.material_override:
				g.material_override = moving(g.material_override)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi := n as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var sm := mi.get_surface_override_material(i)
				if sm:
					mi.set_surface_override_material(i, moving(sm))


static func cellophane(color: Color) -> ShaderMaterial:
	var key := "cello|" + color.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = CELLO_SHADER
	m.set_shader_parameter("color", color)
	_mats[key] = m
	return m


# ------------------------------------------------------------------ meshes

static func unit_box() -> BoxMesh:
	if not _meshes.has("box"):
		var b := BoxMesh.new()
		b.size = Vector3.ONE
		_meshes["box"] = b
	return _meshes["box"]


static func cylinder(top: float, bottom: float, height: float, segs := 16) -> CylinderMesh:
	var key := "cyl|%.3f|%.3f|%.3f|%d" % [top, bottom, height, segs]
	if not _meshes.has(key):
		var c := CylinderMesh.new()
		c.top_radius = top
		c.bottom_radius = bottom
		c.height = height
		c.radial_segments = segs
		c.rings = 1
		_meshes[key] = c
	return _meshes[key]


static func sphere(radius: float, segs := 16) -> SphereMesh:
	var key := "sph|%.3f|%d" % [radius, segs]
	if not _meshes.has(key):
		var s := SphereMesh.new()
		s.radius = radius
		s.height = radius * 2.0
		s.radial_segments = segs
		s.rings = maxi(segs / 2, 4)
		_meshes[key] = s
	return _meshes[key]


## A thin ring (clock bezels, windsock hoops).
static func torus_ring(radius: float, thickness := 0.025) -> TorusMesh:
	var key := "torus|%.3f|%.3f" % [radius, thickness]
	if not _meshes.has(key):
		var t := TorusMesh.new()
		t.inner_radius = radius - thickness
		t.outer_radius = radius
		t.rings = 32
		t.ring_segments = 8
		_meshes[key] = t
	return _meshes[key]


static func capsule(radius: float, height: float) -> CapsuleMesh:
	var key := "cap|%.3f|%.3f" % [radius, height]
	if not _meshes.has(key):
		var c := CapsuleMesh.new()
		c.radius = radius
		c.height = maxf(height, radius * 2.0)
		c.radial_segments = 14
		c.rings = 5
		_meshes[key] = c
	return _meshes[key]


## A tube along +X (paper-towel-roll fuselage). inward = visible from inside.
static func tube(radius: float, length: float, segs := 28, inward := false, arc := TAU) -> ArrayMesh:
	var key := "tube|%.2f|%.2f|%d|%s|%.3f" % [radius, length, segs, inward, arc]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start := -arc * 0.5 - PI * 0.5
	for i in segs:
		var a0 := start + arc * i / segs
		var a1 := start + arc * (i + 1) / segs
		var n0 := Vector3(0, cos(a0), sin(a0))
		var n1 := Vector3(0, cos(a1), sin(a1))
		var p00 := Vector3(-length * 0.5, 0, 0) + n0 * radius
		var p01 := Vector3(length * 0.5, 0, 0) + n0 * radius
		var p10 := Vector3(-length * 0.5, 0, 0) + n1 * radius
		var p11 := Vector3(length * 0.5, 0, 0) + n1 * radius
		var quad := [p00, p11, p10, p00, p01, p11] if not inward else [p00, p10, p11, p00, p11, p01]
		var norms := [n0, n1, n1, n0, n0, n1] if not inward else [-n0, -n1, -n1, -n0, -n1, -n0]
		for k in 6:
			st.set_normal(norms[k])
			var v: Vector3 = quad[k]
			st.set_uv(Vector2(v.x / length + 0.5, float(i) / segs))
			st.add_vertex(v)
	var m := st.commit()
	_meshes[key] = m
	return m


## A flat paper cut-out extruded to `depth` (stars, clouds, signs, fins...).
## The polygon is in the XY plane; the shape faces +Z.
static func cutout(points: PackedVector2Array, depth := 0.02) -> ArrayMesh:
	var key := "cut|%d|%.4f|%s" % [points.size(), depth, str(points).md5_text()]
	if _meshes.has(key):
		return _meshes[key]
	var pts := points.duplicate()
	if Geometry2D.is_polygon_clockwise(pts):
		pts.reverse()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := Geometry2D.triangulate_polygon(pts)
	var hz := depth * 0.5
	var bmin := Vector2(INF, INF)
	var bmax := Vector2(-INF, -INF)
	for p in pts:
		bmin = bmin.min(p)
		bmax = bmax.max(p)
	var ext := (bmax - bmin).max(Vector2(0.001, 0.001))
	for side: float in [1.0, -1.0]:
		var n := Vector3(0, 0, side)
		for t in range(0, tris.size(), 3):
			var a: Vector2 = pts[tris[t]]
			var b: Vector2 = pts[tris[t + 1]]
			var c: Vector2 = pts[tris[t + 2]]
			_tri(st, Vector3(a.x, a.y, hz * side), Vector3(b.x, b.y, hz * side), Vector3(c.x, c.y, hz * side), n,
				(a - bmin) / ext, (b - bmin) / ext, (c - bmin) / ext)
	var count := pts.size()
	for i in count:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % count]
		var e := (b - a).normalized()
		var nrm := Vector3(e.y, -e.x, 0)
		var va := Vector3(a.x, a.y, hz)
		var vb := Vector3(b.x, b.y, hz)
		var va2 := Vector3(a.x, a.y, -hz)
		var vb2 := Vector3(b.x, b.y, -hz)
		_tri(st, va, va2, vb2, nrm, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		_tri(st, va, vb2, vb, nrm, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	var m := st.commit()
	_meshes[key] = m
	return m


## Emits a triangle wound so that its front face (clockwise in Godot) faces
## along the normal, whatever order the corners arrive in.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


# ------------------------------------------------------------ shape lists

static func star_points(r_out: float, r_in: float, n := 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := PI * 0.5 + PI * i / n
		var r := r_out if i % 2 == 0 else r_in
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


static func cloud_points(w: float, h: float, bumps := 5, seed_value := 1) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts := PackedVector2Array()
	var steps := 48
	for i in steps:
		var a := TAU * i / steps
		var r := 1.0 + 0.16 * absf(sin(a * bumps * 0.5 + rng.randf() * 0.2))
		var p := Vector2(cos(a) * w * 0.5, sin(a) * h * 0.5) * r
		if p.y < -h * 0.25:
			p.y = -h * 0.25
		pts.append(p)
	return pts


static func blob_points(r: float, wobble := 0.15, steps := 24, seed_value := 1) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * i / steps
		pts.append(Vector2(cos(a), sin(a)) * r * (1.0 + rng.randf_range(-wobble, wobble)))
	return pts


# ------------------------------------------------------------- instancing

## A visual-only box (no collision) under `parent`.
static func box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, rot := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = unit_box()
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = size
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func part(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func pivot(parent: Node3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	return n
