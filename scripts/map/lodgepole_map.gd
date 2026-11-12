class_name LodgepoleMap
extends GameMap
## LODGEPOLE: an original hillside forest retreat, built for 6v6. Same
## premise as every map: a real place rebuilt by hobbyists from craft-store
## supplies. The ground is a layered felt landscape over rolling hills, the
## pines are stacked felt cones on cardboard-tube trunks, the boulders are
## crumpled grey paper, and the lodge is a modern timber-and-glass house
## of stained card siding, cellophane glazing and a paper-stone chimney.
##
##   West  : Cardstock spawn at the helipad on the high ground, the woodshed.
##   Middle: the two-storey lodge on its knoll (deck, balcony, open-plan
##           ground floor, office and bedroom upstairs), the garage
##           workshop, and the greenhouse on the slope below.
##   North : the creek gully, two footbridges, boulders, a hunting stand.
##   South : the pond with its dock, open meadow and long sightlines.
##   East  : Militia spawn at the gravel turnaround by the gate.
##
## Axes: +X east, -Z north, +Y up. 1 unit = 1 metre.

const BOUNDS := Rect2(-66.0, -46.0, 132.0, 92.0)
const LODGE_Y := 4.3
const GARAGE_Y := 3.0
const GREEN_Y := 3.5
const SHED_Y := 5.2
const HELI_Y := 6.2
const EAST_Y := 0.8
## Flattened building pads: centre x, centre z, half x, half z, height, blend.
const PADS := [
	[-10.0, 3.0, 12.5, 9.5, LODGE_Y, 6.0],
	[13.0, -6.0, 6.5, 5.5, GARAGE_Y, 5.0],
	[-6.0, 25.0, 7.0, 4.5, GREEN_Y, 5.0],
	[-34.0, -8.0, 5.5, 4.5, SHED_Y, 4.0],
	[-54.0, 2.0, 9.0, 12.0, HELI_Y, 6.0],
	[57.0, 4.0, 8.0, 9.0, EAST_Y, 6.0],
]
const POND := Vector2(34.0, 24.0)
const DRIVE := [Vector2(70, 4), Vector2(58, 4), Vector2(46, 3), Vector2(34, 0), Vector2(24, -3), Vector2(18, -5)]
const PATHS := [
	[Vector2(-8.5, 12.5), Vector2(-7.5, 17.0), Vector2(-6.0, 20.5)],
	[Vector2(-21.0, 6.2), Vector2(-25.0, 2.0), Vector2(-29.0, -4.0)],
	[Vector2(-38.0, -6.0), Vector2(-44.0, -2.0), Vector2(-46.0, 2.0)],
	[Vector2(8.0, -6.0), Vector2(1.0, -6.5), Vector2(-5.0, -6.2)],
	[Vector2(34.0, 1.0), Vector2(34.5, 8.0), Vector2(34.0, 15.0)],
	[Vector2(-22.0, -6.0), Vector2(-22.0, -14.0), Vector2(-22.0, -19.0)],
	[Vector2(22.0, -10.0), Vector2(22.0, -16.0), Vector2(22.5, -19.0)],
]
const BRIDGES := [-22.0, 22.5]

var _noise := FastNoiseLite.new()
var _forest := FastNoiseLite.new()
var _trees: Array = []
var _water_y := 0.0


func build() -> void:
	bounds = BOUNDS
	title = "Lodgepole"
	orbit = Vector4(-4, 0, 62, 50)
	orbit_height = 26.0
	heli_height = 30.0
	rng.seed = 2009
	_noise.seed = 11
	_noise.frequency = 0.028
	_noise.fractal_octaves = 3
	_forest.seed = 5
	_forest.frequency = 0.035
	_setup_roots()
	_environment()
	_tune_light()
	_terrain()
	_water()
	_paths()
	_lodge()
	_garage()
	_greenhouse()
	_woodshed()
	_helipad()
	_entrance()
	_bridges_and_stand()
	_dock()
	_forest_and_rocks()
	_ground_cover()
	_bounds_walls()
	_backdrop()
	_spawn_points()
	_bake_nav(AABB(Vector3(-66, -4, -46), Vector3(132, 24, 92)), 0.25)


# --------------------------------------------------------------- height

## The landscape: high ground in the west falling to the east, rolling
## felt hills, a creek gully across the north, a pond basin in the south,
## a rim at the map edge, and flat pads for the buildings.
func height(x: float, z: float) -> float:
	var h := 3.5 - x * 0.05
	h += _noise.get_noise_2d(x, z) * 1.6
	var cz := _creek_z(x)
	var dz := z - cz
	h -= 2.4 * exp(-dz * dz / 14.0)
	var pd := Vector2(x, z).distance_to(POND)
	h -= 1.9 * (1.0 - smoothstep(4.0, 10.0, pd))
	var ex := maxf(absf(x) - 60.0, 0.0)
	var ez := maxf(absf(z) - 40.0, 0.0)
	h += (ex + ez) * 0.7
	for p: Array in PADS:
		var ox := maxf(absf(x - float(p[0])) - float(p[2]), 0.0)
		var oz := maxf(absf(z - float(p[1])) - float(p[3]), 0.0)
		var d := maxf(ox, oz)
		var w := 1.0 - smoothstep(0.0, float(p[5]), d)
		h = lerpf(h, float(p[4]), w)
	return h


func _creek_z(x: float) -> float:
	return -25.0 + sin(x * 0.06) * 4.0


func _near_path(x: float, z: float, margin: float) -> bool:
	var pt := Vector2(x, z)
	var lines: Array = [DRIVE]
	lines.append_array(PATHS)
	for line: Array in lines:
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var c: Vector2 = line[i + 1]
			if Geometry2D.get_closest_point_to_segment(pt, a, c).distance_to(pt) < margin:
				return true
	return false


func _on_pad(x: float, z: float, margin: float) -> bool:
	for p: Array in PADS:
		if absf(x - float(p[0])) < float(p[2]) + margin and absf(z - float(p[1])) < float(p[3]) + margin:
			return true
	return false


# --------------------------------------------------------------- light

func _tune_light() -> void:
	# Late-morning mountain light: a slightly higher, cooler sun and a
	# little more haze hanging between the pines.
	sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-62.0), 0.0)
	sun.light_color = Color(1.0, 0.96, 0.9)
	sun.directional_shadow_max_distance = 120.0
	env.fog_light_color = Color(0.74, 0.8, 0.83)
	env.fog_density = 0.0032
	env.fog_aerial_perspective = 0.6


# -------------------------------------------------------------- terrain

func _terrain() -> void:
	# The visible felt landscape extends past the playable area; collision
	# covers the playable area plus a margin. Heights are sampled once on a
	# 1 m grid and shared by the mesh, its normals and the collision.
	var x0 := -110
	var z0 := -90
	var nx := 220
	var nz := 180
	var hg := PackedFloat32Array()
	hg.resize((nx + 1) * (nz + 1))
	for j in nz + 1:
		for i in nx + 1:
			hg[j * (nx + 1) + i] = height(x0 + i, z0 + j)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for j in nz + 1:
		for i in nx + 1:
			var x := float(x0 + i)
			var z := float(z0 + j)
			var y := hg[j * (nx + 1) + i]
			var hl := hg[j * (nx + 1) + maxi(i - 1, 0)]
			var hr := hg[j * (nx + 1) + mini(i + 1, nx)]
			var hd := hg[maxi(j - 1, 0) * (nx + 1) + i]
			var hu := hg[mini(j + 1, nz) * (nx + 1) + i]
			var n := Vector3((hl - hr) * 0.5, 1.0, (hd - hu) * 0.5).normalized()
			verts.append(Vector3(x, y, z))
			norms.append(n)
			cols.append(_ground_color(x, z, y, n).srgb_to_linear())
	for j in nz:
		for i in nx:
			var a := j * (nx + 1) + i
			var c := a + nx + 1
			idx.append(a)
			idx.append(a + 1)
			idx.append(c)
			idx.append(a + 1)
			idx.append(c + 1)
			idx.append(c)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "FeltLandscape"
	mi.mesh = am
	mi.material_override = Craft.felt_piece(Color.WHITE, Craft.Kind.FELT, 0, true, 0, Color.WHITE, 3.0)
	deco.add_child(mi)
	# Collision: a trimesh over the playable area (x -70..70, z -50..50).
	var faces := PackedVector3Array()
	for j in range(40, 140):
		for i in range(40, 180):
			var p00 := verts[j * (nx + 1) + i]
			var p10 := verts[j * (nx + 1) + i + 1]
			var p01 := verts[(j + 1) * (nx + 1) + i]
			var p11 := verts[(j + 1) * (nx + 1) + i + 1]
			faces.append(p00)
			faces.append(p10)
			faces.append(p01)
			faces.append(p10)
			faces.append(p11)
			faces.append(p01)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	body.collision_layer = MapBuilder.WORLD_LAYER
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	nav_region.add_child(body)


## Felt colours: meadow greens, needle litter under the pines, bare earth on
## steep banks, gravel on the pads.
func _ground_color(x: float, z: float, y: float, n: Vector3) -> Color:
	var grass := Color(0.3, 0.38, 0.2).lerp(Color(0.38, 0.42, 0.24), _noise.get_noise_2d(x * 2.3, z * 2.3) * 0.5 + 0.5)
	var litter := Color(0.33, 0.28, 0.2)
	var earth := Color(0.38, 0.31, 0.24)
	var f := _forest.get_noise_2d(x, z)
	var c := grass.lerp(litter, smoothstep(0.0, 0.35, f) * 0.85)
	var steep := 1.0 - n.y
	c = c.lerp(earth, smoothstep(0.12, 0.3, steep))
	if absf(z - _creek_z(x)) < 2.2:
		c = c.lerp(Color(0.42, 0.4, 0.36), 0.7)
	if Vector2(x, z).distance_to(POND) < 7.5:
		c = c.lerp(Color(0.34, 0.3, 0.22), 0.6)
	# Gravel only where it belongs: the garage apron, helipad surround and
	# the turnaround. Lawn stays lawn round the lodge and greenhouse.
	for k: int in [1, 4, 5]:
		var pd: Array = PADS[k]
		if absf(x - float(pd[0])) < float(pd[2]) - 0.5 and absf(z - float(pd[1])) < float(pd[3]) - 0.5:
			c = c.lerp(Color(0.5, 0.48, 0.44), 0.5)
	return c


func _water() -> void:
	# The pond and the creek: cellophane over darker felt.
	var lo := INF
	for a in 12:
		var p := POND + Vector2(cos(a * TAU / 12.0), sin(a * TAU / 12.0)) * 6.0
		lo = minf(lo, height(p.x, p.y))
	_water_y = minf(lo - 0.15, height(POND.x, POND.y) + 0.7)
	var pond := Craft.part(deco, Craft.cylinder(7.2, 7.2, 0.04, 40), Craft.cellophane(Color(0.32, 0.42, 0.42, 0.62)), Vector3(POND.x, _water_y, POND.y), Vector3.ZERO, Vector3.ONE, false)
	pond.scale = Vector3(1.0, 1.0, 0.82)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := -80.0
	while x < 80.0:
		var z0 := _creek_z(x)
		var z1 := _creek_z(x + 2.0)
		var y0 := height(x, z0) + 0.22
		var y1 := height(x + 2.0, z1) + 0.22
		var a := Vector3(x, y0, z0 - 1.4)
		var b2 := Vector3(x, y0, z0 + 1.4)
		var c := Vector3(x + 2.0, y1, z1 - 1.4)
		var d := Vector3(x + 2.0, y1, z1 + 1.4)
		for v: Vector3 in [a, c, b2, c, d, b2]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
		x += 2.0
	var creek := MeshInstance3D.new()
	creek.mesh = st.commit()
	creek.material_override = Craft.cellophane(Color(0.38, 0.5, 0.52, 0.55))
	creek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deco.add_child(creek)
	# River stones along the creek bed.
	var stone := Craft.mat(Craft.Kind.FELT, Color(0.5, 0.49, 0.46), 0, Color.WHITE, 1.0, 0.0, false)
	var xf := []
	for i in 160:
		var sx := rng.randf_range(-66.0, 66.0)
		var sz := _creek_z(sx) + rng.randf_range(-1.6, 1.6)
		var s := rng.randf_range(0.12, 0.32)
		xf.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(s * 1.3, s * 0.6, s)), Vector3(sx, height(sx, sz) + 0.12, sz)))
	FeltGround._multimesh(deco, Craft.sphere(1.0, 8), stone, xf, false)


## A ribbon of cut felt laid over the ground along a polyline.
func _ribbon(line: Array, width: float, col: Color, lift := 0.06) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	for i in line.size() - 1:
		var a: Vector2 = line[i]
		var c: Vector2 = line[i + 1]
		var n := int(ceil(a.distance_to(c) / 0.8))
		for k in n:
			pts.append(a.lerp(c, float(k) / n))
	pts.append(line[line.size() - 1])
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var dir := (p1 - p0).normalized()
		var side := Vector2(-dir.y, dir.x) * width * 0.5
		var wob0 := 1.0 + sin(i * 1.7) * 0.06
		var wob1 := 1.0 + sin((i + 1) * 1.7) * 0.06
		var l0 := p0 + side * wob0
		var r0 := p0 - side * wob0
		var l1 := p1 + side * wob1
		var r1 := p1 - side * wob1
		var q := [l0, r0, l1, r0, r1, l1]
		for v: Vector2 in q:
			st.set_normal(Vector3.UP)
			st.set_color((col * (0.94 + 0.08 * sin(v.x * 3.1 + v.y * 2.3))).srgb_to_linear())
			st.add_vertex(Vector3(v.x, height(v.x, v.y) + lift, v.y))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Craft.felt_piece(Color.WHITE, Craft.Kind.FELT, 0, true, 0, Color.WHITE, 1.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deco.add_child(mi)


func _paths() -> void:
	_ribbon(DRIVE, 4.4, Color(0.56, 0.54, 0.5), 0.07)
	# Wheel ruts worn into the gravel.
	for off: float in [-0.9, 0.9]:
		var rut := []
		for p: Vector2 in DRIVE:
			rut.append(p + Vector2(0, off))
		_ribbon(rut, 0.45, Color(0.46, 0.44, 0.41), 0.09)
	for line: Array in PATHS:
		_ribbon(line, 1.5, Color(0.4, 0.33, 0.25), 0.06)


# -------------------------------------------------------------- the lodge

func _lodge() -> void:
	var y0 := LODGE_Y
	var y1 := y0 + 3.25
	var siding := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.25, 0.17), Craft.Pattern.BANDS, Color(0.29, 0.2, 0.13), 5.0)
	var stone := Craft.mat(Craft.Kind.PAPER, Color(0.52, 0.51, 0.48), Craft.Pattern.CHECKER, Color(0.43, 0.42, 0.4), 3.0)
	var plaster := Craft.mat(Craft.Kind.CARDBOARD, Color(0.84, 0.82, 0.77))
	var floor_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.4, 0.27), Craft.Pattern.PLANKS, Color.WHITE, 1.0, 0.0)
	var roof_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.2, 0.21, 0.22))
	var glass := Craft.cellophane(Color(0.55, 0.64, 0.66, 0.24))
	var frame := Craft.mat(Craft.Kind.PAPER, Color(0.14, 0.14, 0.15))
	var deck_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.5, 0.39, 0.28), Craft.Pattern.PLANKS, Color.WHITE, 1.3, 0.0)

	# Ground floor slab and walls (outside: cedar siding over a stone plinth).
	b.span(Vector3(-20, y0 - 0.4, -5), Vector3(0, y0 + 0.1, 7), floor_m)
	b.wall(Vector3(-20, y0, -5), Vector3(0, y0, -5), 3.25, 0.3, siding, [Vector4(-6, -4.6, 0, 2.2), Vector4(-16, -13, 1.0, 2.4), Vector4(-2.6, -0.8, 1.0, 2.4)])
	b.wall(Vector3(-20, y0, 7), Vector3(0, y0, 7), 3.25, 0.3, siding, [Vector4(-19, -12, 0.4, 2.9), Vector4(-9.5, -1, 0, 2.9)])
	b.wall(Vector3(-20, y0, -5), Vector3(-20, y0, 7), 3.25, 0.3, siding, [Vector4(5.4, 6.8, 0, 2.2), Vector4(3.2, 4.8, 1.0, 2.4)])
	b.wall(Vector3(0, y0, -5), Vector3(0, y0, 7), 3.25, 0.3, siding, [Vector4(-3, -1, 1.0, 2.4), Vector4(4.0, 6.0, 1.0, 2.4)])
	# Floor-to-ceiling glass on the south face, with the sliding door open.
	for g: Vector2 in [Vector2(-19, -12), Vector2(-9.5, -6.8), Vector2(-5.0, -1.0)]:
		var y_lo := y0 + (0.4 if g.x < -12.5 else 0.0)
		b.span(Vector3(g.x, y_lo, 6.97), Vector3(g.y, y0 + 2.9, 7.03), glass)
		for xi in range(int(g.x), int(g.y) + 1, 2):
			b.deco_box(Vector3(float(xi), y0 + 1.45, 7.0), Vector3(0.08, 2.9, 0.1), frame)
	for w: Array in [[Vector3(-14.5, y0 + 1.7, -5), Vector3(3, 1.4, 0.06)], [Vector3(-1.7, y0 + 1.7, -5), Vector3(1.8, 1.4, 0.06)], [Vector3(-20, y0 + 1.7, 4.0), Vector3(0.06, 1.4, 1.6)], [Vector3(0, y0 + 1.7, -2), Vector3(0.06, 1.4, 2)], [Vector3(0, y0 + 1.7, 5), Vector3(0.06, 1.4, 2)]]:
		b.solid(w[0], w[1], glass)
	# Stone plinth course around the base.
	for e: Array in [[Vector3(-10, y0 + 0.2, -5.2), Vector3(20.4, 0.5, 0.12)], [Vector3(-20.2, y0 + 0.2, 1), Vector3(0.12, 0.5, 12.4)], [Vector3(0.2, y0 + 0.2, 1), Vector3(0.12, 0.5, 12.4)]]:
		b.deco_box(e[0], e[1], stone)
	# Interior: plaster partition between kitchen and living room.
	b.wall(Vector3(-10, y0, -5), Vector3(-10, y0, 7), 3.25, 0.2, plaster, [Vector4(-1.0, 1.5, 0, 2.4), Vector4(3.5, 7, 0, 3.25)])
	# Stairs up along the north wall.
	b.stairs(Vector3(-18.5, y0, -3.6), Vector3(-11.6, y1, -3.6), 1.5, floor_m, frame)
	# Upper floor slab with the stairwell open.
	b.span(Vector3(-20, y1 - 0.25, -2.8), Vector3(0, y1, 7), floor_m)
	b.span(Vector3(-11.5, y1 - 0.25, -5), Vector3(0, y1, -2.8), floor_m)
	b.span(Vector3(-20, y1 - 0.25, -5), Vector3(-18.6, y1, -2.8), floor_m)
	b.solid(Vector3(-15, y1 + 0.5, -2.75), Vector3(7, 1.0, 0.08), glass)
	# Upper walls.
	b.wall(Vector3(-20, y1, -5), Vector3(0, y1, -5), 3.0, 0.3, siding, [Vector4(-9, -6, 1.0, 2.3), Vector4(-3, -1, 1.0, 2.3)])
	b.wall(Vector3(-20, y1, 7), Vector3(0, y1, 7), 3.0, 0.3, siding, [Vector4(-19, -13, 0.6, 2.6), Vector4(-11, -1, 0, 2.6)])
	b.wall(Vector3(-20, y1, -5), Vector3(-20, y1, 7), 3.0, 0.3, siding, [Vector4(-1, 3, 1.0, 2.3)])
	b.wall(Vector3(0, y1, -5), Vector3(0, y1, 7), 3.0, 0.3, siding, [Vector4(-3, 0, 1.0, 2.3), Vector4(2, 5, 1.0, 2.3)])
	b.wall(Vector3(-10, y1, -2.8), Vector3(-10, y1, 7), 3.0, 0.2, plaster, [Vector4(0.0, 1.4, 0, 2.3)])
	for g: Vector2 in [Vector2(-19, -13), Vector2(-11, -6.2), Vector2(-4.6, -1)]:
		b.span(Vector3(g.x, y1 + (0.6 if g.x < -12 else 0.0), 6.97), Vector3(g.y, y1 + 2.6, 7.03), glass)
	for w: Array in [[Vector3(-7.5, y1 + 1.65, -5), Vector3(3, 1.3, 0.06)], [Vector3(-2, y1 + 1.65, -5), Vector3(2, 1.3, 0.06)], [Vector3(-20, y1 + 1.65, 1), Vector3(0.06, 1.3, 4)], [Vector3(0, y1 + 1.65, -1.5), Vector3(0.06, 1.3, 3)], [Vector3(0, y1 + 1.65, 3.5), Vector3(0.06, 1.3, 3)]]:
		b.solid(w[0], w[1], glass)
	# Roof: a deep flat overhang of dark standing-seam metal.
	var ry := y1 + 3.0
	b.span(Vector3(-21.2, ry, -6.4), Vector3(1.4, ry + 0.3, 9.8), roof_m)
	for xi in range(-21, 2, 1):
		b.deco_box(Vector3(float(xi) + 0.2, ry + 0.33, 1.7), Vector3(0.05, 0.05, 16.2), roof_m)
	b.blocker(Vector3(-10, ry + 3, 1.7), Vector3(24, 5, 18))
	# The paper-stone chimney on the east wall.
	b.solid(Vector3(1.0, y0 + 4.6, 1.5), Vector3(1.6, 9.2, 2.6), stone)
	b.deco_box(Vector3(1.0, y0 + 9.3, 1.5), Vector3(1.8, 0.2, 2.8), Craft.mat(Craft.Kind.PAPER, Color(0.4, 0.4, 0.39)))
	# Fireplace opening inside.
	b.deco_box(Vector3(-0.2, y0 + 0.75, 1.5), Vector3(0.3, 1.2, 1.4), Craft.mat(Craft.Kind.PAPER, Color(0.08, 0.07, 0.07)))
	Craft.part(deco, Craft.cylinder(0.12, 0.12, 0.9, 8), Craft.mat(Craft.Kind.CARDBOARD, Color(0.4, 0.27, 0.16)), Vector3(-0.35, y0 + 0.25, 1.5), Vector3(PI * 0.5, 0, 0))
	Craft.part(deco, Craft.sphere(0.25, 8), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.55, 0.2)), Vector3(-0.35, y0 + 0.4, 1.5), Vector3.ZERO, Vector3(1.6, 0.8, 1.0), false)
	# Deck on the south side with a cable-and-timber railing, steps down.
	b.span(Vector3(-20, y0 - 0.2, 7.2), Vector3(0, y0 + 0.12, 11.5), deck_m)
	var rail := Craft.mat(Craft.Kind.CARDBOARD, Color(0.42, 0.3, 0.2))
	b.solid(Vector3(-15, y0 + 0.62, 11.5), Vector3(10, 1.0, 0.12), glass)
	b.solid(Vector3(-2.5, y0 + 0.62, 11.5), Vector3(5, 1.0, 0.12), glass)
	b.deco_box(Vector3(-10, y0 + 1.15, 11.5), Vector3(20, 0.08, 0.16), rail)
	for x: float in [-20.0, -15.0, -10.0, -5.0, 0.0]:
		b.deco_box(Vector3(x, y0 + 1.6, 11.4), Vector3(0.22, 3.0, 0.22), rail)
	b.stairs(Vector3(-8.5, height(-8.5, 14.0), 14.0), Vector3(-8.5, y0 + 0.12, 11.6), 2.6, deck_m, rail)
	# Balcony off the upstairs office.
	b.span(Vector3(-12, y1 - 0.25, 7.0), Vector3(0, y1, 9.6), deck_m)
	b.solid(Vector3(-6, y1 + 0.5, 9.55), Vector3(12, 1.0, 0.08), glass)
	b.solid(Vector3(-11.95, y1 + 0.5, 8.3), Vector3(0.08, 1.0, 2.6), glass)
	b.deco_box(Vector3(-6, y1 + 1.02, 9.55), Vector3(12, 0.05, 0.1), frame)
	_lodge_interior(y0, y1)


## Furniture kit for the lodge: each piece built from card, felt and foil.
func _legs(at: Vector3, size: Vector2, h: float, m: Material, r := 0.03) -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.deco_box(at + Vector3(sx * (size.x * 0.5 - r), h * 0.5, sz * (size.y * 0.5 - r)), Vector3(r * 2.0, h, r * 2.0), m)


func _chair(at: Vector3, yaw: float, wood: Material, pad: Material) -> void:
	var root := Craft.pivot(deco, at, Vector3(0, yaw, 0))
	Craft.box(root, Vector3(0, 0.45, 0), Vector3(0.44, 0.05, 0.44), wood)
	Craft.box(root, Vector3(0, 0.49, 0), Vector3(0.4, 0.04, 0.4), pad)
	Craft.box(root, Vector3(0, 0.75, 0.2), Vector3(0.44, 0.5, 0.04), wood)
	for sx: float in [-0.19, 0.19]:
		for sz: float in [-0.19, 0.19]:
			Craft.box(root, Vector3(sx, 0.22, sz), Vector3(0.04, 0.45, 0.04), wood)


func _sofa(at: Vector3, yaw: float, length: float, felt: Material, cushion: Material, solid := true) -> void:
	var root := Craft.pivot(deco, at, Vector3(0, yaw, 0))
	if solid:
		b.solid(at + Vector3(0, 0.4, 0), Vector3(length, 0.8, 0.95) if absf(sin(yaw)) < 0.5 else Vector3(0.95, 0.8, length), null, 0.0, false)
	Craft.box(root, Vector3(0, 0.22, 0), Vector3(length, 0.3, 0.9), felt)
	Craft.box(root, Vector3(0, 0.6, 0.36), Vector3(length, 0.5, 0.2), felt)
	var n := maxi(int(length / 0.75), 1)
	for k in n:
		var x := -length * 0.5 + (k + 0.5) * length / n
		Craft.box(root, Vector3(x, 0.43, -0.06), Vector3(length / n - 0.04, 0.14, 0.7), cushion)
		Craft.box(root, Vector3(x, 0.66, 0.22), Vector3(length / n - 0.06, 0.4, 0.14), cushion, Vector3(-0.15, 0, 0))
	for sx: float in [-1.0, 1.0]:
		Craft.box(root, Vector3(sx * (length * 0.5 + 0.08), 0.38, 0), Vector3(0.16, 0.5, 0.9), felt)


func _frame(at: Vector3, yaw: float, size: Vector2, print_c: Color) -> void:
	var root := Craft.pivot(deco, at, Vector3(0, yaw, 0))
	Craft.box(root, Vector3.ZERO, Vector3(size.x + 0.08, size.y + 0.08, 0.03), Craft.mat(Craft.Kind.CARDBOARD, Color(0.16, 0.13, 0.1)))
	Craft.box(root, Vector3(0, 0, -0.016), Vector3(size.x - 0.04, size.y - 0.04, 0.005), Craft.mat(Craft.Kind.PAPER, Color(0.88, 0.86, 0.8)))
	# A simple mountain print: two paper peaks over a sky wash.
	Craft.box(root, Vector3(0, 0.0, -0.02), Vector3(size.x - 0.16, size.y - 0.16, 0.004), Craft.mat(Craft.Kind.PAPER, print_c))
	var peak := PackedVector2Array([Vector2(-size.x * 0.35, -size.y * 0.3), Vector2(-size.x * 0.05, size.y * 0.2), Vector2(size.x * 0.12, -size.y * 0.05), Vector2(size.x * 0.25, size.y * 0.08), Vector2(size.x * 0.38, -size.y * 0.3)])
	Craft.part(root, Craft.cutout(peak, 0.004), Craft.mat(Craft.Kind.PAPER, print_c.darkened(0.45)), Vector3(0, 0, -0.024), Vector3(0, PI, 0))


func _lamp_pendant(at: Vector3, drop: float, warm: Material, shade: Material) -> void:
	b.deco_box(at - Vector3(0, drop * 0.5, 0), Vector3(0.012, drop, 0.012), shade)
	Craft.part(deco, Craft.cylinder(0.06, 0.2, 0.22, 14), shade, at - Vector3(0, drop + 0.1, 0))
	Craft.part(deco, Craft.sphere(0.07, 8), warm, at - Vector3(0, drop + 0.2, 0), Vector3.ZERO, Vector3.ONE, false)


func _lodge_interior(y0: float, y1: float) -> void:
	var felt_sofa := Craft.mat(Craft.Kind.FELT, Color(0.3, 0.33, 0.3), Craft.Pattern.STITCH, Color(0.22, 0.24, 0.22))
	var cushion := Craft.mat(Craft.Kind.FELT, Color(0.36, 0.38, 0.34))
	var throw_c := Craft.mat(Craft.Kind.KNIT, Color(0.55, 0.3, 0.22))
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.46, 0.33, 0.22))
	var oak := Craft.mat(Craft.Kind.CARDBOARD, Color(0.6, 0.45, 0.3), Craft.Pattern.PLANKS, Color.WHITE, 0.6, 0.0)
	var counter := Craft.mat(Craft.Kind.PAPER, Color(0.82, 0.81, 0.78))
	var cab := Craft.mat(Craft.Kind.PAPER, Color(0.32, 0.36, 0.34))
	var steel := Craft.mat(Craft.Kind.FOIL, Color(0.62, 0.63, 0.65))
	var black := Craft.mat(Craft.Kind.PAPER, Color(0.1, 0.1, 0.11))
	var plaster := Craft.mat(Craft.Kind.CARDBOARD, Color(0.86, 0.85, 0.81))
	var timber := Craft.mat(Craft.Kind.CARDBOARD, Color(0.62, 0.48, 0.33), Craft.Pattern.PLANKS, Color.WHITE, 0.8, 0.0)
	var warm := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.86, 0.66), 0, Color.WHITE, 1.0, 0.0, false)
	var stone := Craft.mat(Craft.Kind.PAPER, Color(0.5, 0.49, 0.46), Craft.Pattern.CHECKER, Color(0.43, 0.42, 0.4), 3.0)
	# Ceilings: plaster under the upper floor (around the stairwell), timber
	# boards under the roof.
	for c: Array in [[Vector3(-10, y1 - 0.27, 2.1), Vector3(19.6, 0.02, 9.6)], [Vector3(-5.75, y1 - 0.27, -3.9), Vector3(11.1, 0.02, 2.0)]]:
		b.deco_box(c[0], c[1], plaster, Vector3.ZERO, false)
	b.deco_box(Vector3(-10, y1 + 2.98, 1), Vector3(19.6, 0.02, 11.6), timber, Vector3.ZERO, false)
	for xi in range(-19, 0, 3):
		b.deco_box(Vector3(float(xi), y1 + 2.9, 1), Vector3(0.16, 0.16, 11.6), wood)

	# ---- Kitchen (west half).
	# Base cabinets with door seams and handles along the west wall.
	b.solid(Vector3(-19.4, y0 + 0.47, 1.0), Vector3(0.9, 0.94, 4.0), cab)
	b.deco_box(Vector3(-19.4, y0 + 0.97, 1.0), Vector3(1.0, 0.06, 4.1), counter)
	for k in 7:
		var z := -0.7 + k * 0.6
		b.deco_box(Vector3(-18.94, y0 + 0.5, z - 0.3), Vector3(0.02, 0.8, 0.012), black)
		b.deco_box(Vector3(-18.93, y0 + 0.78, z), Vector3(0.03, 0.03, 0.16), steel)
	# Upper cabinets, hob, hood, sink and tap.
	b.deco_box(Vector3(-19.62, y0 + 1.95, 1.0), Vector3(0.45, 0.75, 4.0), cab)
	for k in 6:
		b.deco_box(Vector3(-19.39, y0 + 1.95, -0.65 + k * 0.66), Vector3(0.01, 0.7, 0.01), black)
	b.deco_box(Vector3(-19.35, y0 + 1.015, 2.2), Vector3(0.6, 0.02, 0.7), black)
	for r: Vector2 in [Vector2(-0.15, -0.15), Vector2(-0.15, 0.15), Vector2(0.15, -0.15), Vector2(0.15, 0.15)]:
		Craft.part(deco, Craft.torus_ring(0.08, 0.012), steel, Vector3(-19.35 + r.x, y0 + 1.03, 2.2 + r.y), Vector3.ZERO, Vector3(1, 0.3, 1), false)
	Craft.part(deco, Craft.cylinder(0.15, 0.42, 0.45, 4), steel, Vector3(-19.45, y0 + 1.95, 2.2), Vector3(0, PI * 0.25, 0))
	b.deco_box(Vector3(-19.4, y0 + 0.99, -0.2), Vector3(0.5, 0.02, 0.7), steel)
	b.deco_box(Vector3(-19.7, y0 + 1.15, -0.2), Vector3(0.04, 0.3, 0.04), steel)
	b.deco_box(Vector3(-19.6, y0 + 1.28, -0.2), Vector3(0.22, 0.03, 0.03), steel)
	# Fridge with handles.
	b.solid(Vector3(-19.3, y0 + 1.0, -2.6), Vector3(0.9, 2.0, 1.0), steel)
	b.deco_box(Vector3(-18.83, y0 + 1.25, -2.25), Vector3(0.04, 0.8, 0.04), black)
	b.deco_box(Vector3(-18.84, y0 + 1.1, -2.6), Vector3(0.01, 0.01, 0.98), black)
	# Island with a stone top, stools and pendants over it.
	b.solid(Vector3(-15, y0 + 0.47, 1.5), Vector3(3.2, 0.94, 1.2), cab)
	b.deco_box(Vector3(-15, y0 + 0.97, 1.5), Vector3(3.4, 0.06, 1.35), counter)
	for x: float in [-16.1, -15.0, -13.9]:
		Craft.part(deco, Craft.cylinder(0.2, 0.2, 0.05, 14), felt_sofa, Vector3(x, y0 + 0.72, 2.5))
		Craft.part(deco, Craft.cylinder(0.025, 0.025, 0.7, 6), steel, Vector3(x, y0 + 0.36, 2.5))
		Craft.part(deco, Craft.torus_ring(0.16, 0.012), steel, Vector3(x, y0 + 0.28, 2.5), Vector3.ZERO, Vector3(1, 0.3, 1))
		_lamp_pendant(Vector3(x, y0 + 3.2, 1.5), 1.1, warm, black)
	# Dining table, chairs, a jug of dried flowers.
	b.solid(Vector3(-14.5, y0 + 0.74, 5.0), Vector3(2.4, 0.06, 1.1), oak)
	_legs(Vector3(-14.5, y0, 5.0), Vector2(2.3, 1.0), 0.71, wood, 0.04)
	for x: float in [-15.2, -13.8]:
		_chair(Vector3(x, y0, 4.1), 0.0, wood, cushion)
		_chair(Vector3(x, y0, 5.9), PI, wood, cushion)
	Craft.part(deco, Craft.cylinder(0.06, 0.08, 0.22, 10), Craft.mat(Craft.Kind.PAPER, Color(0.82, 0.8, 0.74)), Vector3(-14.5, y0 + 0.88, 5.0))
	for k in 5:
		b.deco_box(Vector3(-14.5 + (k - 2) * 0.03, y0 + 1.1, 5.0), Vector3(0.012, 0.35, 0.012), Craft.mat(Craft.Kind.FELT, Color(0.62, 0.52, 0.32)), Vector3(0, 0, (k - 2) * 0.15))

	# ---- Living room (east half), round the stone fireplace.
	Props.rug(deco, Vector3(-4.5, y0 + 0.1, 1.8), Vector2(5.0, 4.0), Color(0.42, 0.38, 0.32))
	_sofa(Vector3(-7.4, y0 + 0.1, 1.8), PI * 0.5, 3.6, felt_sofa, cushion)
	_sofa(Vector3(-5.2, y0 + 0.1, 4.1), PI, 2.8, felt_sofa, cushion)
	b.deco_box(Vector3(-7.2, y0 + 0.62, 0.6), Vector3(0.5, 0.06, 0.9), throw_c, Vector3(0, 0, 0.2))
	# Armchair facing the fire, coffee table with books and a mug.
	_sofa(Vector3(-3.0, y0 + 0.1, -0.9), 0.6, 1.0, felt_sofa, Craft.mat(Craft.Kind.FELT, Color(0.5, 0.42, 0.32)))
	b.solid(Vector3(-4.4, y0 + 0.45, 1.8), Vector3(1.4, 0.06, 0.8), oak)
	_legs(Vector3(-4.4, y0 + 0.1, 1.8), Vector2(1.3, 0.7), 0.32, wood, 0.04)
	for k in 3:
		b.deco_box(Vector3(-4.7, y0 + 0.5 + k * 0.035, 1.7), Vector3(0.3, 0.03, 0.22), Craft.mat(Craft.Kind.PAPER, [Color(0.5, 0.2, 0.18), Color(0.2, 0.28, 0.4), Color(0.75, 0.72, 0.62)][k]), Vector3(0, k * 0.2, 0))
	Craft.part(deco, Craft.cylinder(0.045, 0.045, 0.1, 10), Craft.mat(Craft.Kind.PAPER, Color(0.85, 0.84, 0.8)), Vector3(-4.0, y0 + 0.53, 1.95))
	# Floor lamp by the sofa.
	Craft.part(deco, Craft.cylinder(0.15, 0.15, 0.03, 12), black, Vector3(-7.6, y0 + 0.12, 4.1))
	Craft.part(deco, Craft.cylinder(0.015, 0.015, 1.5, 6), black, Vector3(-7.6, y0 + 0.86, 4.1))
	Craft.part(deco, Craft.cylinder(0.14, 0.2, 0.28, 14), Craft.mat(Craft.Kind.PAPER, Color(0.9, 0.85, 0.72)), Vector3(-7.6, y0 + 1.66, 4.1))
	# Hearth, mantel, log basket.
	b.deco_box(Vector3(-0.6, y0 + 0.15, 1.5), Vector3(0.9, 0.12, 2.4), stone)
	b.deco_box(Vector3(-0.3, y0 + 1.5, 1.5), Vector3(0.3, 0.1, 2.2), wood)
	for z: float in [0.8, 1.2, 2.1]:
		Craft.part(deco, Craft.cylinder(0.035, 0.035, 0.18, 8), Craft.mat(Craft.Kind.PAPER, Color(0.88, 0.86, 0.8)), Vector3(-0.3, y0 + 1.64, z))
	Craft.part(deco, Craft.cylinder(0.25, 0.22, 0.35, 12), Craft.mat(Craft.Kind.KNIT, Color(0.42, 0.33, 0.22)), Vector3(-0.7, y0 + 0.28, 3.3))
	for k in 4:
		Craft.part(deco, Craft.cylinder(0.06, 0.06, 0.5, 8), Craft.mat(Craft.Kind.CARDBOARD, Color(0.42, 0.3, 0.18)), Vector3(-0.7 + (k % 2) * 0.1 - 0.05, y0 + 0.5, 3.3 + (k / 2) * 0.12 - 0.06), Vector3(PI * 0.5, 0.3, 0))
	# Bookcase on the north wall.
	b.solid(Vector3(-8.2, y0 + 1.1, -4.65), Vector3(3.0, 2.2, 0.4), wood)
	for k in 4:
		b.deco_box(Vector3(-8.2, y0 + 0.3 + k * 0.55, -4.44), Vector3(2.9, 0.03, 0.04), wood)
		for n in 12:
			if (n + k) % 5 == 0:
				continue
			var bc: Color = [Color(0.5, 0.2, 0.18), Color(0.2, 0.28, 0.4), Color(0.75, 0.72, 0.62), Color(0.3, 0.36, 0.28), Color(0.6, 0.5, 0.3)][(n * 3 + k) % 5]
			b.deco_box(Vector3(-9.45 + n * 0.21, y0 + 0.48 + k * 0.55, -4.48), Vector3(0.12, 0.3 + (n % 3) * 0.04, 0.24), Craft.mat(Craft.Kind.PAPER, bc))
	# Prints on the plaster partition.
	_frame(Vector3(-9.88, y0 + 1.7, -3.0), PI * 0.5, Vector2(0.9, 0.65), Color(0.62, 0.7, 0.74))
	_frame(Vector3(-9.88, y0 + 1.6, 2.6), PI * 0.5, Vector2(0.6, 0.8), Color(0.74, 0.7, 0.6))
	# Coat hooks and boots by the back door.
	b.deco_box(Vector3(-3.6, y0 + 1.7, -4.82), Vector3(1.0, 0.08, 0.03), wood)
	for k in 3:
		b.deco_box(Vector3(-3.9 + k * 0.3, y0 + 1.35, -4.75), Vector3(0.22, 0.6, 0.1), Craft.mat(Craft.Kind.FELT, [Color(0.3, 0.34, 0.26), Color(0.5, 0.3, 0.2), Color(0.25, 0.27, 0.32)][k]))
	for k in 2:
		b.deco_box(Vector3(-3.9 + k * 0.2, y0 + 0.2, -4.6), Vector3(0.12, 0.3, 0.26), Craft.mat(Craft.Kind.FELT, Color(0.3, 0.22, 0.15)))

	# ---- Upstairs office (east): desks, office chairs, radio, whiteboard.
	for z: float in [-1.5, 2.5]:
		b.solid(Vector3(-2.5, y1 + 0.74, z), Vector3(1.6, 0.05, 2.2), oak)
		_legs(Vector3(-2.5, y1, z), Vector2(1.5, 2.1), 0.72, black, 0.025)
		for k in 2:
			var mz := z - 0.5 + k
			b.deco_box(Vector3(-1.95, y1 + 1.05, mz), Vector3(0.06, 0.5, 0.8), black)
			b.deco_box(Vector3(-2.0, y1 + 1.05, mz), Vector3(0.02, 0.42, 0.72), Craft.mat(Craft.Kind.GLOW, Color(0.3, 0.42, 0.5)))
			b.deco_box(Vector3(-2.05, y1 + 0.82, mz), Vector3(0.18, 0.12, 0.12), black)
		b.deco_box(Vector3(-2.7, y1 + 0.78, z), Vector3(0.2, 0.02, 0.5), black)
		var ch := Craft.pivot(deco, Vector3(-3.5, y1, z))
		Craft.box(ch, Vector3(0, 0.48, 0), Vector3(0.5, 0.08, 0.5), black)
		Craft.box(ch, Vector3(0.24, 0.85, 0), Vector3(0.06, 0.6, 0.46), black)
		Craft.part(ch, Craft.cylinder(0.03, 0.03, 0.4, 6), steel, Vector3(0, 0.25, 0))
		for a in 5:
			Craft.box(ch, Vector3(cos(a * TAU / 5.0) * 0.2, 0.05, sin(a * TAU / 5.0) * 0.2), Vector3(0.04, 0.04, 0.04), black)
		b.solid(Vector3(-3.5, y1 + 0.5, z), Vector3(0.55, 1.0, 0.55), null, 0.0, false)
	# Radio set with an antenna, and a whiteboard on the partition.
	b.deco_box(Vector3(-2.6, y1 + 0.9, 0.5), Vector3(0.4, 0.25, 0.5), Craft.mat(Craft.Kind.PAPER, Color(0.28, 0.31, 0.24)))
	for k in 3:
		Craft.part(deco, Craft.cylinder(0.03, 0.03, 0.02, 10), black, Vector3(-2.8, y1 + 0.92, 0.35 + k * 0.15), Vector3(0, 0, PI * 0.5))
	b.deco_box(Vector3(-2.5, y1 + 1.35, 0.7), Vector3(0.012, 0.7, 0.012), black)
	b.deco_box(Vector3(-9.88, y1 + 1.5, 4.6), Vector3(0.03, 1.0, 1.8), Craft.mat(Craft.Kind.PAPER, Color(0.9, 0.9, 0.88)))
	for k in 4:
		b.deco_box(Vector3(-9.86, y1 + 1.7 - k * 0.15, 4.4 + (k % 2) * 0.2), Vector3(0.005, 0.02, 0.9 - k * 0.12), Craft.mat(Craft.Kind.PAPER, Color(0.2, 0.3, 0.55)))
	b.deco_box(Vector3(-0.2, y1 + 1.6, 1.0), Vector3(0.04, 1.4, 2.4), Craft.mat(Craft.Kind.PAPER, Color(0.82, 0.8, 0.7), Craft.Pattern.CHECKER, Color(0.74, 0.76, 0.66), 4.0))
	for z: float in [5.0, 5.8]:
		b.solid(Vector3(-0.5, y1 + 0.65, z), Vector3(0.7, 1.3, 0.7), steel)
		for k in 3:
			b.deco_box(Vector3(-0.86, y1 + 0.25 + k * 0.42, z), Vector3(0.02, 0.03, 0.3), black)
	Props.rug(deco, Vector3(-3.5, y1 + 0.02, 0.5), Vector2(3.0, 5.5), Color(0.3, 0.32, 0.36))

	# ---- Bedroom (west): bed with headboard and pillows, nightstands.
	b.solid(Vector3(-17.5, y1 + 0.25, 3.5), Vector3(2.2, 0.5, 2.6), wood)
	b.deco_box(Vector3(-17.5, y1 + 0.58, 3.65), Vector3(2.1, 0.16, 2.3), Craft.mat(Craft.Kind.FELT, Color(0.85, 0.84, 0.8)))
	b.deco_box(Vector3(-17.5, y1 + 0.68, 4.1), Vector3(2.12, 0.08, 1.4), Craft.mat(Craft.Kind.KNIT, Color(0.4, 0.46, 0.5)))
	for x: float in [-18.0, -17.0]:
		b.deco_box(Vector3(x, y1 + 0.72, 2.55), Vector3(0.75, 0.14, 0.4), Craft.mat(Craft.Kind.FELT, Color(0.9, 0.89, 0.85)))
	b.deco_box(Vector3(-17.5, y1 + 0.85, 2.2), Vector3(2.3, 1.2, 0.08), wood)
	for x: float in [-19.0, -16.0]:
		b.solid(Vector3(x, y1 + 0.3, 2.4), Vector3(0.5, 0.6, 0.45), wood)
		Craft.part(deco, Craft.cylinder(0.06, 0.08, 0.3, 10), black, Vector3(x, y1 + 0.75, 2.4))
		Craft.part(deco, Craft.cylinder(0.1, 0.15, 0.18, 12), Craft.mat(Craft.Kind.PAPER, Color(0.9, 0.85, 0.72)), Vector3(x, y1 + 0.98, 2.4))
	Props.rug(deco, Vector3(-17.5, y1 + 0.02, 5.4), Vector2(3.0, 1.4), Color(0.52, 0.4, 0.3))
	b.solid(Vector3(-19.5, y1 + 1.0, -0.5), Vector3(0.7, 2.0, 2.0), wood)
	b.deco_box(Vector3(-19.14, y1 + 1.0, -0.5), Vector3(0.01, 1.9, 0.02), black)
	for z: float in [-0.62, -0.38]:
		b.deco_box(Vector3(-19.13, y1 + 1.0, z), Vector3(0.03, 0.2, 0.03), steel)
	_frame(Vector3(-19.83, y1 + 1.5, 4.0), -PI * 0.5, Vector2(1.1, 0.7), Color(0.66, 0.72, 0.7))

	# Warm interior light.
	for p: Vector3 in [Vector3(-5, y0 + 2.8, 1.5), Vector3(-15, y0 + 2.8, 1.5), Vector3(-5, y1 + 2.6, 1.5), Vector3(-15, y1 + 2.6, 2)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.88, 0.72)
		l.light_energy = 0.9
		l.omni_range = 8.0
		l.position = p
		deco.add_child(l)
	_lamp_pendant(Vector3(-4.5, y0 + 3.2, 1.8), 0.9, warm, black)
	_lamp_pendant(Vector3(-5.0, y1 + 3.0, 1.0), 0.6, warm, black)
	_lamp_pendant(Vector3(-15.0, y1 + 3.0, 2.0), 0.6, warm, black)

	# ---- Outside: deck chairs and table, a grill, planters, wall lights,
	# downpipes, a propane tank and a satellite dish.
	var deck_wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.42, 0.3))
	for x: float in [-4.0, -2.0]:
		var ac := Craft.pivot(deco, Vector3(x, y0 + 0.12, 9.6), Vector3(0, PI + (x + 3.0) * 0.2, 0))
		Craft.box(ac, Vector3(0, 0.35, 0), Vector3(0.6, 0.05, 0.6), deck_wood, Vector3(-0.1, 0, 0))
		Craft.box(ac, Vector3(0, 0.7, 0.33), Vector3(0.6, 0.7, 0.05), deck_wood, Vector3(-0.35, 0, 0))
		for sx: float in [-0.33, 0.33]:
			Craft.box(ac, Vector3(sx, 0.55, 0.0), Vector3(0.08, 0.04, 0.75), deck_wood)
			Craft.box(ac, Vector3(sx, 0.28, -0.25), Vector3(0.05, 0.55, 0.05), deck_wood)
		b.solid(Vector3(x, y0 + 0.5, 9.6), Vector3(0.7, 0.8, 0.7), null, 0.0, false)
	b.solid(Vector3(-3.0, y0 + 0.45, 10.5), Vector3(0.6, 0.06, 0.6), deck_wood)
	_legs(Vector3(-3.0, y0 + 0.12, 10.5), Vector2(0.55, 0.55), 0.33, deck_wood, 0.03)
	var grill := b.solid(Vector3(-17.5, y0 + 0.62, 10.2), Vector3(1.0, 0.6, 0.6), black)
	Craft.part(grill, Craft.cylinder(0.3, 0.3, 0.95, 14), black, Vector3(0, 0.32, 0), Vector3(0, 0, PI * 0.5), Vector3(1, 1, 0.9))
	for sx: float in [-0.4, 0.4]:
		Craft.box(grill, Vector3(sx, -0.55, 0), Vector3(0.04, 0.5, 0.04), black)
	for p: Vector3 in [Vector3(-19.4, y0 + 0.12, 8.0), Vector3(-0.6, y0 + 0.12, 8.0)]:
		Craft.part(deco, Craft.cylinder(0.32, 0.26, 0.55, 12), Craft.mat(Craft.Kind.PAPER, Color(0.32, 0.3, 0.28)), p + Vector3(0, 0.28, 0))
		Craft.part(deco, Craft.sphere(0.36, 10), Craft.mat(Craft.Kind.FELT, Color(0.26, 0.36, 0.2)), p + Vector3(0, 0.75, 0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	for p: Vector3 in [Vector3(-7.7, y0 + 2.3, 7.18), Vector3(-5.3, y0 + 2.3, -5.18), Vector3(-20.18, y0 + 2.3, 6.1)]:
		b.deco_box(p, Vector3(0.14, 0.24, 0.14), black)
		b.deco_box(p + Vector3(0, -0.02, 0), Vector3(0.1, 0.12, 0.16), warm, Vector3.ZERO, false)
	for c: Vector3 in [Vector3(-20.2, 0, -5.2), Vector3(0.2, 0, -5.2), Vector3(-20.2, 0, 7.2)]:
		b.deco_box(Vector3(c.x, y0 + 3.1, c.z), Vector3(0.12, 6.2, 0.12), Craft.mat(Craft.Kind.FOIL, Color(0.3, 0.31, 0.32)))
	var tank := b.solid(Vector3(-21.6, y0 + 0.55, -2.0), Vector3(0.9, 1.1, 2.0), null, 0.0, false)
	Craft.part(tank, Craft.capsule(0.45, 2.0), Craft.mat(Craft.Kind.PAPER, Color(0.85, 0.85, 0.82)), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	Craft.part(tank, Craft.cylinder(0.12, 0.12, 0.15, 10), steel, Vector3(0, 0.5, 0))
	var dish := Craft.pivot(deco, Vector3(0.95, y0 + 6.2, 3.0), Vector3(0, PI * 0.5, 0))
	Craft.part(dish, Craft.sphere(0.4, 16), Craft.mat(Craft.Kind.PAPER, Color(0.82, 0.82, 0.8)), Vector3(0, 0, 0.3), Vector3.ZERO, Vector3(1.0, 1.0, 0.25))
	Craft.box(dish, Vector3(0, 0, 0.0), Vector3(0.05, 0.05, 0.6), steel)


# ------------------------------------------------------------- outbuildings

func _garage() -> void:
	var y := GARAGE_Y
	var siding := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.25, 0.17), Craft.Pattern.BANDS, Color(0.29, 0.2, 0.13), 5.0)
	var roof_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.2, 0.21, 0.22))
	var conc := Craft.mat(Craft.Kind.PAPER, Color(0.56, 0.55, 0.52), Craft.Pattern.FLOOR, Color(0.5, 0.49, 0.47), 1.2)
	b.span(Vector3(8.5, y - 0.4, -10), Vector3(17.5, y + 0.06, -2), conc)
	b.wall(Vector3(8.5, y, -10), Vector3(17.5, y, -10), 3.4, 0.25, siding, [Vector4(11, 14, 1.2, 2.3)])
	b.wall(Vector3(8.5, y, -2), Vector3(17.5, y, -2), 3.4, 0.25, siding, [Vector4(14.8, 16.8, 1.2, 2.3)])
	b.wall(Vector3(8.5, y, -10), Vector3(8.5, y, -2), 3.4, 0.25, siding, [Vector4(-7, -5.8, 0, 2.2)])
	b.wall(Vector3(17.5, y, -10), Vector3(17.5, y, -2), 3.4, 0.25, siding, [Vector4(-8.6, -3.4, 0, 2.8)])
	b.span(Vector3(8, y + 3.4, -10.6), Vector3(18.2, y + 3.65, -1.4), roof_m)
	b.blocker(Vector3(13, y + 6, -6), Vector3(11, 4, 10))
	# Rolled-up door, workbench, tool wall, quad bike, cans and tyres.
	Craft.part(deco, Craft.cylinder(0.32, 0.32, 5.4, 14), Craft.mat(Craft.Kind.CARDBOARD, Color(0.7, 0.7, 0.68), Craft.Pattern.BANDS, Color(0.62, 0.62, 0.6), 12.0), Vector3(17.6, y + 3.05, -6), Vector3(PI * 0.5, 0, 0))
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.5, 0.38, 0.26))
	b.solid(Vector3(11.4, y + 0.48, -2.6), Vector3(3.6, 0.95, 0.9), wood)
	b.deco_box(Vector3(11.4, y + 1.8, -2.16), Vector3(3.4, 1.4, 0.05), Craft.mat(Craft.Kind.CARDBOARD, Color(0.62, 0.55, 0.42), Craft.Pattern.DOTS, Color(0.3, 0.26, 0.2), 3.0))
	# Quad bike: frame, fenders, seat, tank, handlebars, racks, chunky tyres.
	if ModelLib.has(Props.VEH, "quad"):
		Props.quad(b, Vector3(13.5, y, -7.2), 0.0, Color(0.3, 0.33, 0.24))
	else:
		var quad := b.solid(Vector3(13.5, y + 0.55, -7.2), Vector3(1.2, 0.8, 2.0), null, 0.0, false)
		var qpaint := GunBuilder.painted(Craft.Kind.PAPER, Color(0.3, 0.33, 0.24), 0.5, false)
		var tyre := Craft.mat(Craft.Kind.PLASTIC, Color(0.1, 0.1, 0.11))
		var qblack := Craft.mat(Craft.Kind.PAPER, Color(0.12, 0.12, 0.13))
		var qsteel := Craft.mat(Craft.Kind.FOIL, Color(0.55, 0.56, 0.58))
		Craft.box(quad, Vector3(0, -0.15, 0), Vector3(0.5, 0.25, 1.6), qblack)
		for sz: float in [-0.65, 0.65]:
			Craft.box(quad, Vector3(0, 0.08, sz), Vector3(1.25, 0.08, 0.6), qpaint, Vector3(0.12 * signf(sz), 0, 0))
			Craft.box(quad, Vector3(0, 0.2, sz * 1.15), Vector3(1.0, 0.04, 0.4), qsteel)
			for sx: float in [-0.6, 0.6]:
				Craft.part(quad, Craft.cylinder(0.28, 0.28, 0.26, 14), tyre, Vector3(sx, -0.27, sz), Vector3(0, 0, PI * 0.5))
				Craft.part(quad, Craft.cylinder(0.12, 0.12, 0.28, 8), qsteel, Vector3(sx, -0.27, sz), Vector3(0, 0, PI * 0.5))
		Craft.box(quad, Vector3(0, 0.12, -0.05), Vector3(0.45, 0.25, 0.55), qpaint)
		Craft.box(quad, Vector3(0, 0.22, 0.32), Vector3(0.38, 0.12, 0.7), qblack)
		Craft.box(quad, Vector3(0, 0.38, -0.42), Vector3(0.06, 0.3, 0.06), qblack)
		Craft.box(quad, Vector3(0, 0.52, -0.45), Vector3(0.75, 0.04, 0.04), qblack)
		Craft.part(quad, Craft.sphere(0.07, 8), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.95, 0.85)), Vector3(0, 0.15, -0.95))
	# Shelving with boxes and tins on the north wall; a strip light.
	var shelf_w := Craft.mat(Craft.Kind.CARDBOARD, Color(0.5, 0.38, 0.26))
	b.solid(Vector3(16.3, y + 1.0, -9.55), Vector3(2.0, 2.0, 0.6), null, 0.0, false)
	for k in 4:
		b.deco_box(Vector3(16.3, y + 0.15 + k * 0.6, -9.55), Vector3(2.0, 0.04, 0.6), shelf_w)
		for n in 4:
			if (n + k) % 3 == 0:
				Craft.part(deco, Craft.cylinder(0.12, 0.12, 0.25, 10), Craft.mat(Craft.Kind.FOIL, [Color(0.6, 0.18, 0.14), Color(0.62, 0.63, 0.65), Color(0.3, 0.36, 0.3)][n % 3]), Vector3(15.6 + n * 0.45, y + 0.3 + k * 0.6, -9.5))
			else:
				b.deco_box(Vector3(15.6 + n * 0.45, y + 0.33 + k * 0.6, -9.5), Vector3(0.38, 0.32, 0.45), Craft.mat(Craft.Kind.CARDBOARD, Craft.KRAFT.darkened(0.1 * (n % 2))))
	for sx: float in [15.3, 17.3]:
		for sz: float in [-9.85, -9.25]:
			b.deco_box(Vector3(sx, y + 1.0, sz), Vector3(0.04, 2.0, 0.04), shelf_w)
	b.deco_box(Vector3(13.0, y + 3.3, -6.0), Vector3(0.2, 0.06, 2.4), Craft.mat(Craft.Kind.GLOW, Color(0.95, 0.97, 0.95)))
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.95, 0.97, 1.0)
	gl.light_energy = 0.8
	gl.omni_range = 7.0
	gl.position = Vector3(13.0, y + 2.9, -6.0)
	deco.add_child(gl)
	for i in 3:
		b.solid(Vector3(16.6, y + 0.3, -9.6 + i * 0.35), Vector3(0.35, 0.6, 0.25), Craft.mat(Craft.Kind.PAPER, Color(0.6, 0.16, 0.13)))
	var tyre_stack := Craft.mat(Craft.Kind.PLASTIC, Color(0.1, 0.1, 0.11))
	for i in 4:
		Craft.part(deco, Craft.cylinder(0.36, 0.36, 0.25, 14), tyre_stack, Vector3(9.3, y + 0.13 + i * 0.25, -9.2))
	b.solid(Vector3(9.3, y + 0.5, -9.2), Vector3(0.7, 1.0, 0.7), null, 0.0, false)


func _greenhouse() -> void:
	var y := GREEN_Y
	var frame := Craft.mat(Craft.Kind.CARDBOARD, Color(0.82, 0.8, 0.76))
	var glass := Craft.cellophane(Color(0.7, 0.78, 0.74, 0.22))
	var x0 := -11.0
	var x1 := -1.0
	var z0 := 22.5
	var z1 := 27.5
	b.span(Vector3(x0, y - 0.3, z0), Vector3(x1, y + 0.05, z1), Craft.mat(Craft.Kind.PAPER, Color(0.5, 0.48, 0.44)))
	# Glass walls, doors open at both ends.
	b.solid(Vector3((x0 + x1) * 0.5, y + 1.2, z0), Vector3(x1 - x0, 2.4, 0.06), glass)
	b.solid(Vector3((x0 + x1) * 0.5, y + 1.2, z1), Vector3(x1 - x0, 2.4, 0.06), glass)
	for x: float in [x0, x1]:
		b.solid(Vector3(x, y + 1.2, (z0 + 24.3) * 0.5), Vector3(0.06, 2.4, 24.3 - z0), glass)
		b.solid(Vector3(x, y + 1.2, (25.7 + z1) * 0.5), Vector3(0.06, 2.4, z1 - 25.7), glass)
	# Frame posts and a gabled glass roof.
	var x := x0
	while x <= x1 + 0.01:
		for z: float in [z0, z1]:
			b.deco_box(Vector3(x, y + 1.2, z), Vector3(0.08, 2.4, 0.08), frame)
		b.deco_box(Vector3(x, y + 2.95, z0 + 1.25), Vector3(0.06, 0.06, 2.9), frame, Vector3(-0.45, 0, 0))
		b.deco_box(Vector3(x, y + 2.95, z1 - 1.25), Vector3(0.06, 0.06, 2.9), frame, Vector3(0.45, 0, 0))
		x += 2.0
	for s: float in [1.0, -1.0]:
		var pane := b.deco_box(Vector3((x0 + x1) * 0.5, y + 2.95, 25.0 - s * 1.25), Vector3(x1 - x0, 0.03, 2.9), glass, Vector3(-0.45 * s, 0, 0), false)
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.blocker(Vector3((x0 + x1) * 0.5, y + 4.5, 25), Vector3(11, 3, 6))
	# Potting benches with seedlings.
	var bench := Craft.mat(Craft.Kind.CARDBOARD, Color(0.5, 0.38, 0.26))
	var pot := Craft.mat(Craft.Kind.PAPER, Color(0.6, 0.34, 0.22))
	var leaf := Craft.mat(Craft.Kind.FELT, Color(0.3, 0.42, 0.2))
	for z: float in [23.4, 26.6]:
		b.solid(Vector3(-6, y + 0.45, z), Vector3(8.4, 0.9, 0.9), bench)
		for i in 11:
			var px := -9.8 + i * 0.76
			Craft.part(deco, Craft.cylinder(0.14, 0.1, 0.18, 10), pot, Vector3(px, y + 0.99, z))
			Craft.part(deco, Craft.sphere(0.16, 8), leaf, Vector3(px, y + 1.17, z), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))


func _woodshed() -> void:
	var y := SHED_Y
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.42, 0.3, 0.2))
	var roof_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.22, 0.23, 0.24))
	b.wall(Vector3(-38, y, -11), Vector3(-30, y, -11), 2.6, 0.2, wood)
	for x: float in [-38.0, -30.0]:
		b.solid(Vector3(x, y + 1.2, -6.2), Vector3(0.22, 2.4, 0.22), wood)
	b.deco_box(Vector3(-34, y + 2.55, -8.6), Vector3(8.6, 0.12, 5.6), roof_m, Vector3(-0.12, 0, 0))
	# Split-log stacks: solid cover with every log end showing.
	var log_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.46, 0.32, 0.2))
	var end_m := Craft.mat(Craft.Kind.PAPER, Color(0.78, 0.66, 0.48))
	for stack: Vector3 in [Vector3(-36, y, -10.2), Vector3(-32, y, -10.2), Vector3(-34, y, -5.2)]:
		b.solid(stack + Vector3(0, 0.7, 0), Vector3(3.2, 1.4, 1.0), null, 0.0, false)
		var xf := []
		var ends := []
		for row in 5:
			for k in 9:
				var p := stack + Vector3(-1.45 + k * 0.36 + (row % 2) * 0.18, 0.16 + row * 0.28, 0)
				xf.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)).scaled(Vector3(0.16, 1.0, 0.16)), p))
				ends.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)).scaled(Vector3(0.15, 0.02, 0.15)), p + Vector3(0, 0, 0.5)))
				ends.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)).scaled(Vector3(0.15, 0.02, 0.15)), p - Vector3(0, 0, 0.5)))
		FeltGround._multimesh(deco, Craft.cylinder(1.0, 1.0, 1.0, 8), log_m, xf, true)
		FeltGround._multimesh(deco, Craft.cylinder(1.0, 1.0, 1.0, 8), end_m, ends, false)
	# Chopping block with an axe in it.
	b.column(Vector3(-28.5, y, -7.5), 0.35, 0.6, log_m)
	b.deco_box(Vector3(-28.5, y + 0.85, -7.5), Vector3(0.05, 0.6, 0.05), wood, Vector3(0, 0, 0.5))


func _helipad() -> void:
	var y := HELI_Y
	var pad := Craft.mat(Craft.Kind.PAPER, Color(0.46, 0.46, 0.44), Craft.Pattern.FLOOR, Color(0.42, 0.42, 0.4), 1.6)
	b.span(Vector3(-61, y - 0.3, -6), Vector3(-47, y + 0.08, 8), pad)
	var white := Craft.mat(Craft.Kind.PAPER, Color(0.86, 0.86, 0.82))
	var yellow := Craft.mat(Craft.Kind.PAPER, Craft.YELLOW)
	Craft.part(deco, Craft.torus_ring(5.6, 0.3), yellow, Vector3(-54, y + 0.09, 1), Vector3.ZERO, Vector3(1, 0.05, 1), false)
	for bar: Array in [[Vector3(-55.2, y + 0.1, 1), Vector3(0.6, 0.02, 4.0)], [Vector3(-52.8, y + 0.1, 1), Vector3(0.6, 0.02, 4.0)], [Vector3(-54, y + 0.1, 1), Vector3(2.4, 0.02, 0.6)]]:
		b.deco_box(bar[0], bar[1], white, Vector3.ZERO, false)
	# Fuel drums and a storage box: cover at the spawn.
	for p: Vector3 in [Vector3(-48.5, y, -4.5), Vector3(-47.7, y, -4.5), Vector3(-48.1, y, -3.7)]:
		b.column(p, 0.36, 1.0, Craft.mat(Craft.Kind.PAPER, Color(0.24, 0.32, 0.24), Craft.Pattern.BANDS, Color(0.2, 0.27, 0.2), 6.0))
	Props.container(b, Vector3(-48.5, y, 10.5), PI * 0.5, Color(0.3, 0.36, 0.3))
	# Windsock on its pole.
	b.column(Vector3(-60, y, -5), 0.08, 5.0, Craft.mat(Craft.Kind.CARDBOARD, Color(0.85, 0.85, 0.85), Craft.Pattern.BANDS, Craft.RED, 1.2))
	for i in 4:
		Craft.part(deco, Craft.cylinder(0.34 - i * 0.05, 0.3 - i * 0.05, 0.42, 12), Craft.mat(Craft.Kind.FELT, Craft.ORANGE if i % 2 == 0 else Craft.WHITE), Vector3(-59.6 + i * 0.4, y + 4.7 - i * 0.04, -5), Vector3(0, 0, PI * 0.5 - 0.1))


func _entrance() -> void:
	# Gravel turnaround, stone gate pillars, an open timber gate, the
	# owners' SUV and a little gatehouse.
	var stone := Craft.mat(Craft.Kind.PAPER, Color(0.52, 0.51, 0.48), Craft.Pattern.CHECKER, Color(0.43, 0.42, 0.4), 3.0)
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.44, 0.31, 0.2))
	for z: float in [0.6, 7.4]:
		b.solid(Vector3(64.5, height(64.5, z) + 1.0, z), Vector3(1.0, 2.4, 1.0), stone)
	var gate := b.solid(Vector3(62.4, height(62.4, 0.0) + 0.7, -1.4), Vector3(0.12, 1.2, 4.0), wood, 0.4)
	gate.rotation.y = 1.2
	var sign_y := height(63.5, -2.0)
	b.solid(Vector3(63.5, sign_y + 0.9, -2.5), Vector3(0.16, 1.8, 0.16), wood)
	var board := b.deco_box(Vector3(63.4, sign_y + 1.75, -2.5), Vector3(0.08, 0.6, 1.8), wood)
	_label(Vector3(63.32, sign_y + 1.78, -2.5), "PRIVATE ROAD", 64, Color(0.86, 0.82, 0.7), false, -PI * 0.5)
	var _unused := board
	# SUV parked on the turnaround.
	Props.suv(b, Vector3(54.0, height(54.0, 9.0), 9.0), 0.3, Color(0.2, 0.25, 0.22))
	# Gatehouse shed.
	var gy := height(60.0, -8.0)
	var siding := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.25, 0.17), Craft.Pattern.BANDS, Color(0.29, 0.2, 0.13), 5.0)
	b.wall(Vector3(58, gy, -10), Vector3(62, gy, -10), 2.6, 0.2, siding)
	b.wall(Vector3(58, gy, -6), Vector3(62, gy, -6), 2.6, 0.2, siding, [Vector4(59.4, 60.6, 0, 2.1)])
	b.wall(Vector3(58, gy, -10), Vector3(58, gy, -6), 2.6, 0.2, siding, [Vector4(-8.8, -7.2, 1.0, 1.9)])
	b.wall(Vector3(62, gy, -10), Vector3(62, gy, -6), 2.6, 0.2, siding)
	b.span(Vector3(57.6, gy + 2.6, -10.4), Vector3(62.4, gy + 2.8, -5.6), Craft.mat(Craft.Kind.CARDBOARD, Color(0.2, 0.21, 0.22)))
	# Split-rail fence along the road.
	var rail := Craft.mat(Craft.Kind.CARDBOARD, Color(0.5, 0.4, 0.3))
	for i in 9:
		var x := 40.0 + i * 3.0
		for z: float in [-2.6, 9.8]:
			var fy := height(x, z)
			b.deco_box(Vector3(x, fy + 0.6, z), Vector3(0.14, 1.2, 0.14), rail)
			if i < 8:
				for ry: float in [0.45, 0.95]:
					var ny := height(x + 3.0, z)
					var mid := Vector3(x + 1.5, (fy + ny) * 0.5 + ry, z)
					b.deco_box(mid, Vector3(3.0, 0.1, 0.08), rail, Vector3(0, 0, atan2(ny - fy, 3.0)))


func _bridges_and_stand() -> void:
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.46, 0.34, 0.22), Craft.Pattern.FLOOR, Color(0.4, 0.29, 0.19), 0.2)
	var rail := Craft.mat(Craft.Kind.CARDBOARD, Color(0.4, 0.29, 0.19))
	for x: float in BRIDGES:
		var cz := _creek_z(x)
		var za := cz - 4.5
		var zb := cz + 4.5
		var ya := height(x, za)
		var yb := height(x, zb)
		var top := maxf(ya, yb) + 0.15
		b.span(Vector3(x - 1.1, top - 0.2, za), Vector3(x + 1.1, top, zb), wood)
		for sx: float in [-1.15, 1.15]:
			b.deco_box(Vector3(x + sx, top + 0.85, cz), Vector3(0.1, 0.1, 9.0), rail)
			for k in 4:
				b.deco_box(Vector3(x + sx, top + 0.45, za + 0.5 + k * 2.65), Vector3(0.12, 0.9, 0.12), rail)
		# Ramps on to the deck where the bank is lower.
		if ya < top - 0.3:
			b.stairs(Vector3(x, height(x, za - 2.0), za - 2.0), Vector3(x, top, za + 0.1), 2.2, wood)
		if yb < top - 0.3:
			b.stairs(Vector3(x, height(x, zb + 2.0), zb + 2.0), Vector3(x, top, zb - 0.1), 2.2, wood)
	# Hunting stand on the far bank: a platform on four legs, steps up.
	var sx0 := 18.0
	var sz0 := -37.0
	var hy := height(sx0, sz0)
	for lx: float in [-1.1, 1.1]:
		for lz: float in [-1.1, 1.1]:
			b.solid(Vector3(sx0 + lx, hy + 1.4, sz0 + lz), Vector3(0.18, 2.8, 0.18), rail)
	b.span(Vector3(sx0 - 1.4, hy + 2.6, sz0 - 1.4), Vector3(sx0 + 1.4, hy + 2.8, sz0 + 1.4), wood)
	b.solid(Vector3(sx0, hy + 3.3, sz0 - 1.35), Vector3(2.8, 1.0, 0.1), rail)
	b.solid(Vector3(sx0 - 1.35, hy + 3.3, sz0), Vector3(0.1, 1.0, 2.8), rail)
	b.solid(Vector3(sx0 + 1.35, hy + 3.3, sz0), Vector3(0.1, 1.0, 2.8), rail)
	b.deco_box(Vector3(sx0, hy + 4.6, sz0), Vector3(3.2, 0.1, 3.2), Craft.mat(Craft.Kind.FELT, Color(0.3, 0.32, 0.22)))
	b.stairs(Vector3(sx0, height(sx0, sz0 + 5.5), sz0 + 5.5), Vector3(sx0, hy + 2.8, sz0 + 1.5), 1.2, wood, rail)


func _dock() -> void:
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.48, 0.36, 0.24), Craft.Pattern.FLOOR, Color(0.4, 0.3, 0.2), 0.2)
	var post := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.26, 0.17))
	var top := _water_y + 0.45
	var shore := height(34.0, 15.5)
	b.span(Vector3(33.0, top - 0.2, 16.0), Vector3(35.0, top, 22.0), wood)
	for z: float in [16.5, 19.0, 21.5]:
		for x: float in [32.9, 35.1]:
			Craft.part(deco, Craft.cylinder(0.12, 0.12, 1.4, 8), post, Vector3(x, top - 0.5, z))
	if shore > top + 0.3:
		b.stairs(Vector3(34.0, top, 16.2), Vector3(34.0, shore, 14.0), 2.0, wood)
	# Upturned canoe on the bank and a pair of paddles.
	var cy := height(28.0, 17.0)
	var canoe := Craft.part(deco, Craft.sphere(1.0, 14), Craft.mat(Craft.Kind.PAPER, Color(0.5, 0.2, 0.15)), Vector3(28.0, cy + 0.25, 17.0), Vector3(0, 0.6, 0), Vector3(0.45, 0.3, 2.4))
	var _c := canoe
	b.blocker(Vector3(28.0, cy + 0.3, 17.0), Vector3(0.9, 0.6, 4.6)).rotation.y = 0.6


# --------------------------------------------------------- forest & rocks

func _rock_mesh(seed_v: int) -> ArrayMesh:
	# A ball of crumpled grey paper: a sphere pushed in and out at random,
	# with flat facets like creased sheets.
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var src := SphereMesh.new()
	src.radius = 1.0
	src.height = 2.0
	src.radial_segments = 12
	src.rings = 7
	var arr := src.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var bumps := {}
	for i in verts.size():
		var key := verts[i].snapped(Vector3(0.01, 0.01, 0.01))
		if not bumps.has(key):
			bumps[key] = r.randf_range(0.78, 1.12)
		verts[i] = verts[i] * float(bumps[key])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in idx.size():
		st.add_vertex(verts[idx[i]])
	st.generate_normals()
	return st.commit()


func _clear_spot(x: float, z: float) -> bool:
	if not BOUNDS.grow(-1.5).has_point(Vector2(x, z)):
		return true
	if _on_pad(x, z, 3.0) or _near_path(x, z, 2.6):
		return false
	if absf(z - _creek_z(x)) < 3.0:
		return false
	if Vector2(x, z).distance_to(POND) < 10.0:
		return false
	for bx: float in BRIDGES:
		if absf(x - bx) < 3.5 and absf(z - _creek_z(x)) < 8.0:
			return false
	if Vector2(x, z).distance_to(Vector2(18, -37)) < 3.5:
		return false
	return true


func _forest_and_rocks() -> void:
	var trunk_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.36, 0.26, 0.18), Craft.Pattern.BANDS, Color(0.3, 0.21, 0.14), 3.0, 0.0, false)
	var needles := [Craft.mat(Craft.Kind.FELT, Color(0.13, 0.21, 0.13), 0, Color.WHITE, 1.0, 0.0, false), Craft.mat(Craft.Kind.FELT, Color(0.17, 0.26, 0.15), 0, Color.WHITE, 1.0, 0.0, false), Craft.mat(Craft.Kind.FELT, Color(0.12, 0.19, 0.14), 0, Color.WHITE, 1.0, 0.0, false)]
	var trunks := []
	var cones := [[], [], []]
	var placed := {}
	var tries := 0
	var inside := 0
	var outside := 0
	while (inside < 230 or outside < 420) and tries < 20000:
		tries += 1
		var x := rng.randf_range(-105.0, 105.0)
		var z := rng.randf_range(-85.0, 85.0)
		var in_bounds := BOUNDS.grow(-1.0).has_point(Vector2(x, z))
		if in_bounds and inside >= 230:
			continue
		if not in_bounds and outside >= 420:
			continue
		var dens := _forest.get_noise_2d(x, z)
		if in_bounds and dens < -0.12:
			continue
		if not _clear_spot(x, z):
			continue
		var cell := Vector2i(int(floor(x / 2.6)), int(floor(z / 2.6)))
		if placed.has(cell):
			continue
		placed[cell] = true
		var h := rng.randf_range(7.0, 12.5)
		var y := height(x, z)
		var r := h * 0.024
		trunks.append(Transform3D(Basis().scaled(Vector3(r, h * 0.55, r)), Vector3(x, y + h * 0.27, z)))
		var shade := rng.randi() % 3
		var spread := h * rng.randf_range(0.21, 0.27)
		for t in 6:
			var cr := spread * (1.0 - t * 0.15)
			var ch := h * 0.26
			var yaw := rng.randf() * TAU
			cones[shade].append(Transform3D(Basis.from_euler(Vector3(0, yaw, 0)).scaled(Vector3(cr, ch, cr)), Vector3(x, y + h * (0.3 + t * 0.12), z)))
		if in_bounds:
			inside += 1
			var body := StaticBody3D.new()
			body.collision_layer = MapBuilder.WORLD_LAYER
			body.collision_mask = 0
			body.position = Vector3(x, y + 2.0, z)
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = maxf(r * 1.3, 0.22)
			cyl.height = 4.0
			cs.shape = cyl
			body.add_child(cs)
			nav_region.add_child(body)
		else:
			outside += 1
	FeltGround._multimesh(deco, Craft.cylinder(1.0, 1.0, 1.0, 8), trunk_m, trunks, true)
	for k in 3:
		FeltGround._multimesh(deco, Craft.cylinder(0.0, 1.0, 1.0, 9), needles[k], cones[k], true)

	# Crumpled-paper boulders: scattered, and clustered as cover.
	var rock_m := Craft.mat(Craft.Kind.PAPER, Color(0.56, 0.55, 0.52), 0, Color.WHITE, 1.0, 0.0, false)
	var moss_m := Craft.mat(Craft.Kind.FELT, Color(0.3, 0.38, 0.2), 0, Color.WHITE, 1.0, 0.0, false)
	var meshes := []
	for i in 4:
		meshes.append(_rock_mesh(100 + i))
	var spots := [Vector2(4, -20), Vector2(6, -18.5), Vector2(-8, -30), Vector2(-36, -24), Vector2(40, -30), Vector2(30, -12),
		Vector2(-28, 14), Vector2(-40, 20), Vector2(12, 14), Vector2(18, 30), Vector2(48, 20), Vector2(-50, -26), Vector2(-16, -16),
		Vector2(0, 36), Vector2(26, 8), Vector2(-24, 30), Vector2(44, -14), Vector2(-46, 30), Vector2(8, -34), Vector2(-4, 14)]
	for i in 26:
		spots.append(Vector2(rng.randf_range(-60, 60), rng.randf_range(-40, 40)))
	for i in spots.size():
		var p: Vector2 = spots[i]
		if not _clear_spot(p.x, p.y) and i >= 20:
			continue
		if _on_pad(p.x, p.y, 1.0) or _near_path(p.x, p.y, 1.8):
			continue
		var s := rng.randf_range(0.7, 1.7) if i >= 20 else rng.randf_range(1.2, 2.0)
		var sc := Vector3(s * rng.randf_range(1.0, 1.5), s * rng.randf_range(0.6, 0.9), s)
		var y := height(p.x, p.y)
		var body := b.solid(Vector3(p.x, y + sc.y * 0.45, p.y), sc * 1.5, null, rng.randf() * TAU, false)
		var mi := Craft.part(body, meshes[i % 4], rock_m, Vector3(0, -sc.y * 0.1, 0), Vector3.ZERO, sc)
		var _m := mi
		Craft.part(body, Craft.sphere(1.0, 8), moss_m, Vector3(0, sc.y * 0.55, 0), Vector3.ZERO, Vector3(sc.x * 0.7, sc.y * 0.25, sc.z * 0.7))
	# Fallen logs: hollow-looking cardboard tubes with pale cut ends.
	var log_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.4, 0.29, 0.19), Craft.Pattern.BANDS, Color(0.34, 0.24, 0.16), 4.0)
	var end_m := Craft.mat(Craft.Kind.PAPER, Color(0.74, 0.62, 0.45), Craft.Pattern.DOTS, Color(0.6, 0.48, 0.34), 2.0)
	for lg: Array in [[Vector2(-30, 8), 0.4, 6.0], [Vector2(28, -20), 1.3, 7.0], [Vector2(-12, -18), 0.2, 5.0], [Vector2(46, 16), -0.6, 6.0], [Vector2(-44, -16), 1.0, 6.5], [Vector2(6, 26), 1.6, 5.0], [Vector2(-50, 22), 0.2, 5.0], [Vector2(36, -38), 0.5, 6.0]]:
		var p: Vector2 = lg[0]
		var yaw: float = lg[1]
		var len: float = lg[2]
		var y := height(p.x, p.y)
		var body := b.solid(Vector3(p.x, y + 0.4, p.y), Vector3(0.8, 0.8, len), null, yaw, false)
		Craft.part(body, Craft.cylinder(0.4, 0.42, len, 12), log_m, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
		for e: float in [-0.5, 0.5]:
			Craft.part(body, Craft.cylinder(0.39, 0.39, 0.02, 12), end_m, Vector3(0, 0, e * len + signf(e) * 0.01), Vector3(PI * 0.5, 0, 0))


func _ground_cover() -> void:
	# Fringe-cut felt grass in the open, ferns under the trees.
	var tuft := Craft.cutout(PackedVector2Array([Vector2(-0.18, 0), Vector2(-0.22, 0.24), Vector2(-0.1, 0.06), Vector2(-0.04, 0.3), Vector2(0.02, 0.07), Vector2(0.12, 0.27), Vector2(0.13, 0.05), Vector2(0.24, 0.2), Vector2(0.2, 0)]), 0.01)
	var fern := Craft.cutout(PackedVector2Array([Vector2(0, 0), Vector2(0.08, 0.1), Vector2(0.05, 0.12), Vector2(0.12, 0.24), Vector2(0.07, 0.26), Vector2(0.1, 0.4), Vector2(0, 0.55), Vector2(-0.1, 0.4), Vector2(-0.07, 0.26), Vector2(-0.12, 0.24), Vector2(-0.05, 0.12), Vector2(-0.08, 0.1)]), 0.008)
	var grass := []
	var ferns := []
	for i in 2600:
		var x := rng.randf_range(-70, 70)
		var z := rng.randf_range(-50, 50)
		if _on_pad(x, z, 0.5) or _near_path(x, z, 1.2):
			continue
		var y := height(x, z)
		var f := _forest.get_noise_2d(x, z)
		var s := rng.randf_range(0.6, 1.1)
		if f > 0.15:
			if rng.randf() < 0.35:
				for k in 3:
					ferns.append(Transform3D(Basis.from_euler(Vector3(-0.7, k * TAU / 3.0 + rng.randf(), 0)).scaled(Vector3.ONE * s), Vector3(x, y, z)))
		else:
			grass.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3.ONE * s), Vector3(x, y - 0.02, z)))
	FeltGround._multimesh(deco, tuft, Craft.mat(Craft.Kind.FELT, Color(0.34, 0.42, 0.22), 0, Color.WHITE, 1.0, 0.0, false), grass, false)
	FeltGround._multimesh(deco, fern, Craft.mat(Craft.Kind.FELT, Color(0.24, 0.36, 0.18), 0, Color.WHITE, 1.0, 0.0, false), ferns, false)
	# Shrubs: clumps of felt balls along the forest edges and by buildings.
	var shrub_m := [Craft.mat(Craft.Kind.FELT, Color(0.22, 0.32, 0.18), 0, Color.WHITE, 1.0, 0.0, false), Craft.mat(Craft.Kind.FELT, Color(0.28, 0.36, 0.2), 0, Color.WHITE, 1.0, 0.0, false)]
	var shrubs := [[], []]
	for i in 900:
		var x := rng.randf_range(-64, 64)
		var z := rng.randf_range(-44, 44)
		var f := _forest.get_noise_2d(x, z)
		if f < -0.15 or f > 0.25 or _on_pad(x, z, 1.5) or _near_path(x, z, 1.6) or absf(z - _creek_z(x)) < 2.5:
			continue
		if rng.randf() > 0.25:
			continue
		var y := height(x, z)
		var s0 := rng.randf_range(0.35, 0.7)
		for k in 4:
			var o := Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5)) * s0
			var sk := s0 * rng.randf_range(0.6, 1.0)
			shrubs[k % 2].append(Transform3D(Basis().scaled(Vector3(sk, sk * 0.75, sk)), Vector3(x, y + sk * 0.45, z) + o))
	for k in 2:
		FeltGround._multimesh(deco, Craft.sphere(1.0, 8), shrub_m[k], shrubs[k], true)
	# Wildflowers dotted through the meadows: muted whites, yellows, mauve.
	var fl_cols := [Color(0.88, 0.87, 0.83), Color(0.84, 0.74, 0.36), Color(0.62, 0.55, 0.68)]
	var flowers := [[], [], []]
	for i in 1800:
		var x := rng.randf_range(-64, 64)
		var z := rng.randf_range(-44, 44)
		if _forest.get_noise_2d(x, z) > 0.0 or _on_pad(x, z, 0.5) or _near_path(x, z, 1.0):
			continue
		var y := height(x, z)
		flowers[i % 3].append(Transform3D(Basis().scaled(Vector3(0.05, 0.03, 0.05)), Vector3(x, y + 0.2, z)))
	for k in 3:
		FeltGround._multimesh(deco, Craft.sphere(1.0, 6), Craft.mat(Craft.Kind.FELT, fl_cols[k], 0, Color.WHITE, 1.0, 0.0, false), flowers[k], false)
	# Stumps from trees felled for the clearing, and young saplings.
	var stump_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.38, 0.28, 0.19), Craft.Pattern.BANDS, Color(0.32, 0.23, 0.15), 4.0)
	var ring_m := Craft.mat(Craft.Kind.PAPER, Color(0.74, 0.62, 0.45), Craft.Pattern.DOTS, Color(0.62, 0.5, 0.36), 2.0)
	for i in 30:
		var x := rng.randf_range(-62, 62)
		var z := rng.randf_range(-42, 42)
		if not _clear_spot(x, z):
			continue
		var y := height(x, z)
		var r := rng.randf_range(0.22, 0.4)
		var st := b.column(Vector3(x, y - 0.05, z), r, 0.45, stump_m)
		Craft.part(st, Craft.cylinder(r - 0.01, r - 0.01, 0.02, 12), ring_m, Vector3(0, 0.23, 0))
	var sap := []
	for i in 60:
		var x := rng.randf_range(-62, 62)
		var z := rng.randf_range(-42, 42)
		if not _clear_spot(x, z) or _forest.get_noise_2d(x, z) < -0.2:
			continue
		var y := height(x, z)
		var h := rng.randf_range(0.8, 1.8)
		for t in 3:
			sap.append(Transform3D(Basis().scaled(Vector3(h * 0.3 * (1.0 - t * 0.25), h * 0.4, h * 0.3 * (1.0 - t * 0.25))), Vector3(x, y + h * (0.3 + t * 0.25), z)))
	FeltGround._multimesh(deco, Craft.cylinder(0.0, 1.0, 1.0, 8), Craft.mat(Craft.Kind.FELT, Color(0.2, 0.3, 0.17), 0, Color.WHITE, 1.0, 0.0, false), sap, true)
	# Pine cones in the needle litter.
	var cones := []
	for i in 300:
		var x := rng.randf_range(-64, 64)
		var z := rng.randf_range(-44, 44)
		if _forest.get_noise_2d(x, z) < 0.1 or _on_pad(x, z, 0.5):
			continue
		cones.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, rng.randf() * TAU, 0)).scaled(Vector3(0.05, 0.08, 0.05)), Vector3(x, height(x, z) + 0.04, z)))
	FeltGround._multimesh(deco, Craft.sphere(1.0, 6), Craft.mat(Craft.Kind.KNIT, Color(0.4, 0.28, 0.18), 0, Color.WHITE, 2.0, 0.0, false), cones, false)


func _bounds_walls() -> void:
	var bx := BOUNDS
	var hgt := 40.0
	b.blocker(Vector3(bx.position.x - 0.5, 15, bx.get_center().y), Vector3(1, hgt, bx.size.y + 2))
	b.blocker(Vector3(bx.end.x + 0.5, 15, bx.get_center().y), Vector3(1, hgt, bx.size.y + 2))
	b.blocker(Vector3(bx.get_center().x, 15, bx.position.y - 0.5), Vector3(bx.size.x + 2, hgt, 1))
	b.blocker(Vector3(bx.get_center().x, 15, bx.end.y + 0.5), Vector3(bx.size.x + 2, hgt, 1))


func _backdrop() -> void:
	# Distant felt mountains with snowcaps, layered paler with distance.
	var far := Node3D.new()
	far.name = "Backdrop"
	deco.add_child(far)
	for i in 22:
		var a := TAU * i / 22.0 + rng.randf_range(-0.08, 0.08)
		var d := rng.randf_range(230.0, 320.0)
		var hgt := rng.randf_range(55.0, 110.0)
		var w := rng.randf_range(70.0, 120.0)
		var tone := clampf((d - 230.0) / 90.0, 0.0, 1.0)
		var col := Color(0.32, 0.38, 0.36).lerp(Color(0.52, 0.58, 0.62), tone)
		var p := Vector3(cos(a) * d, -6.0, sin(a) * d)
		var m := Craft.part(far, Craft.cylinder(0.0, 1.0, 1.0, 7), Craft.mat(Craft.Kind.FELT, col, 0, Color.WHITE, 6.0, 0.0, false), p + Vector3(0, hgt * 0.5, 0), Vector3(0, rng.randf() * TAU, 0), Vector3(w, hgt, w * 0.8), false)
		var _mm := m
		Craft.part(far, Craft.cylinder(0.0, 1.0, 1.0, 7), Craft.mat(Craft.Kind.FELT, Color(0.9, 0.9, 0.9), 0, Color.WHITE, 4.0, 0.0, false), p + Vector3(0, hgt * 0.87, 0), Vector3(0, rng.randf() * TAU, 0), Vector3(w * 0.27, hgt * 0.26, w * 0.22), false)
	# Teased cotton clouds on fishing line, as on Gateway.
	var cloud_m := Craft.mat(Craft.Kind.FELT, Color(0.93, 0.93, 0.92), 0, Color.WHITE, 4.0, 0.0, false)
	for i in 12:
		var a := rng.randf() * TAU
		var d := rng.randf_range(110.0, 220.0)
		var p := Vector3(cos(a) * d, rng.randf_range(55.0, 90.0), sin(a) * d)
		var w := rng.randf_range(20.0, 36.0)
		var cl := Craft.part(far, Craft.cutout(Craft.cloud_points(w, w * 0.45, 5, i + 3), 2.0), cloud_m, p, Vector3(0, -a + PI * 0.5, 0))
		cl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _spawn_points() -> void:
	for z: float in [-9.0, -5.0, -1.0, 3.0, 7.0, 11.0]:
		spawns[0].append(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-56, HELI_Y + 0.15, z)))
	for z: float in [-4.0, -1.0, 2.0, 5.0, 8.0, 11.0]:
		spawns[1].append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(58.0, height(58.0, z) + 0.15, z)))
	for p: Vector2 in [Vector2(-34, -2), Vector2(-15, 1), Vector2(-5, 3), Vector2(13, -5), Vector2(-6, 24.5), Vector2(34, 10),
			Vector2(20, -30), Vector2(-22, -30), Vector2(0, 34), Vector2(44, -20), Vector2(-40, 26), Vector2(26, 30)]:
		var y := height(p.x, p.y)
		if _on_pad(p.x, p.y, 0.0):
			for pd: Array in PADS:
				if absf(p.x - float(pd[0])) < float(pd[2]) and absf(p.y - float(pd[1])) < float(pd[3]):
					y = float(pd[4]) + 0.15
		spawns[-1].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(p.x, y + 0.2, p.y)))
