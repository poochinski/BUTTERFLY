class_name Craft
extends RefCounted
## The art-supply cupboard: cached craft materials and the mesh kit every
## builder (map, props, weapons, soldiers) uses. Keeping materials cached
## means the whole game shares a handful of shader variants.

enum Kind { CARDBOARD, PAPER, FELT, KNIT, TAPE, PLASTIC, FOIL, GLOW }
enum Pattern { NONE, HAZARD, DOTS, CHECKER, WINDOWS, STITCH, BANDS, FLOOR, WALL }

const CRAFT_SHADER := preload("res://shaders/craft.gdshader")
const CRAFT_VM_SHADER := preload("res://shaders/craft_vm.gdshader")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
const OUTLINE_VM_SHADER := preload("res://shaders/outline_vm.gdshader")
const CELLO_SHADER := preload("res://shaders/cellophane.gdshader")

# A palette pulled from the reference crafts.
const KRAFT := Color(0.76, 0.55, 0.34)
const KRAFT_DARK := Color(0.62, 0.45, 0.3)
const CREAM := Color(0.97, 0.93, 0.84)
const INK := Color(0.17, 0.11, 0.08)
const TEAL := Color(0.0, 0.55, 0.62)
const PINK := Color(0.96, 0.32, 0.55)
const PURPLE := Color(0.44, 0.28, 0.82)
const ORANGE := Color(0.98, 0.46, 0.1)
const YELLOW := Color(1.0, 0.76, 0.12)
const GRASS := Color(0.3, 0.66, 0.22)
const RED := Color(0.86, 0.25, 0.2)
const BLUE := Color(0.24, 0.45, 0.85)
const SLATE := Color(0.42, 0.45, 0.52)
const ASPHALT := Color(0.4, 0.42, 0.45)
const WHITE := Color(0.96, 0.95, 0.92)

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
	var key := "cut|%d|%.3f|%s" % [points.size(), depth, str(points).md5_text()]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := Geometry2D.triangulate_polygon(points)
	var hz := depth * 0.5
	var bmin := Vector2(INF, INF)
	var bmax := Vector2(-INF, -INF)
	for p in points:
		bmin = bmin.min(p)
		bmax = bmax.max(p)
	var ext := (bmax - bmin).max(Vector2(0.001, 0.001))
	for side: float in [1.0, -1.0]:
		var order := [0, 1, 2] if side > 0.0 else [0, 2, 1]
		for t in range(0, tris.size(), 3):
			for o in order:
				var p: Vector2 = points[tris[t + o]]
				st.set_normal(Vector3(0, 0, side))
				st.set_uv((p - bmin) / ext)
				st.add_vertex(Vector3(p.x, p.y, hz * side))
	var n := points.size()
	for i in n:
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % n]
		var e := (b - a).normalized()
		var nrm := Vector3(e.y, -e.x, 0)
		if Geometry2D.is_polygon_clockwise(points):
			nrm = -nrm
		var va := Vector3(a.x, a.y, hz)
		var vb := Vector3(b.x, b.y, hz)
		var va2 := Vector3(a.x, a.y, -hz)
		var vb2 := Vector3(b.x, b.y, -hz)
		for v in [va, va2, vb2, va, vb2, vb]:
			st.set_normal(nrm)
			st.set_uv(Vector2(0, 0))
			st.add_vertex(v)
	var m := st.commit()
	_meshes[key] = m
	return m


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
