class_name World
extends Node3D
## The procedural meadow: terrain heights, ground masks, and the queries the
## rest of the game needs (ground height, flower perches, obstacles).
##
## Layout: a dirt footpath runs from the start point (south) toward the
## sunset (north, -Z), lined with pink flowering hedges and blossom trees.
## A pond sits east of the path, pine forest rings the valley, and purple
## mountains stand on the horizon.

const SIZE := 1024.0
const RES := 257
const CELL := SIZE / (RES - 1)
const HALF := SIZE * 0.5
const PLAY_RADIUS := 190.0
const POND_CENTER := Vector2(58.0, -14.0)
const POND_RADIUS := 15.0
const PATH_Z_MIN := -190.0
const PATH_Z_MAX := 110.0
const SPAWN_Z := 76.0
const BLOCK_CELL := 8.0
const PERCH_CELL := 12.0

var heights := PackedFloat32Array()
var flower_mask := PackedFloat32Array()
var forest_mask := PackedFloat32Array()
var tall_mask := PackedFloat32Array()
var water_level := 0.0

## Vector2i -> Array of Vector3(x, z, radius)
var blockers := {}
## Vector2i -> PackedVector3Array of spots butterflies can land on.
var perches := {}

var rng := RandomNumberGenerator.new()

var _n_hills := FastNoiseLite.new()
var _n_detail := FastNoiseLite.new()
var _n_ridge := FastNoiseLite.new()
var _n_zone := FastNoiseLite.new()
var _n_zone2 := FastNoiseLite.new()
var _n_zone3 := FastNoiseLite.new()


func build() -> void:
	rng.seed = 7741
	_setup_noise()
	_compute_water_level()
	_generate_heights()
	_generate_masks()
	_publish_globals()
	_build_terrain_mesh()
	Scenery.build(self)


# ---------------------------------------------------------------- queries

static func path_x(z: float) -> float:
	return 12.0 * sin(z / 37.0) + 5.0 * sin(z / 15.0 + 1.3)


static func path_dist(x: float, z: float) -> float:
	var dx := 12.0 / 37.0 * cos(z / 37.0) + 5.0 / 15.0 * cos(z / 15.0 + 1.3)
	var d := absf(x - path_x(z)) / sqrt(1.0 + dx * dx)
	var ends := maxf(0.0, maxf(PATH_Z_MIN - z, z - PATH_Z_MAX))
	return d + ends * 4.0


func spawn_point() -> Vector3:
	var x := path_x(SPAWN_Z)
	return Vector3(x, height_at(x, SPAWN_Z), SPAWN_Z)


func _grid_sample(arr: PackedFloat32Array, x: float, z: float) -> float:
	var fx := clampf((x + HALF) / CELL, 0.0, RES - 1.001)
	var fz := clampf((z + HALF) / CELL, 0.0, RES - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var i := iz * RES + ix
	var a := lerpf(arr[i], arr[i + 1], tx)
	var b := lerpf(arr[i + RES], arr[i + RES + 1], tx)
	return lerpf(a, b, tz)


func height_at(x: float, z: float) -> float:
	return _grid_sample(heights, x, z)


func flowers_at(x: float, z: float) -> float:
	return _grid_sample(flower_mask, x, z)


func forest_at(x: float, z: float) -> float:
	return _grid_sample(forest_mask, x, z)


func tall_grass_at(x: float, z: float) -> float:
	return _grid_sample(tall_mask, x, z)


func normal_at(x: float, z: float) -> Vector3:
	var e := 1.0
	var hl := height_at(x - e, z)
	var hr := height_at(x + e, z)
	var hd := height_at(x, z - e)
	var hu := height_at(x, z + e)
	return Vector3(hl - hr, 2.0 * e, hd - hu).normalized()


func is_water(x: float, z: float) -> bool:
	return dist_to_pond(x, z) < POND_RADIUS * 2.6 and height_at(x, z) < water_level - 0.05


func dist_to_pond(x: float, z: float) -> float:
	return Vector2(x, z).distance_to(POND_CENTER)


func add_blocker(x: float, z: float, radius: float) -> void:
	var c := Vector2i(floori(x / BLOCK_CELL), floori(z / BLOCK_CELL))
	if not blockers.has(c):
		blockers[c] = []
	blockers[c].append(Vector3(x, z, radius))


## Pushes a position out of tree trunks, rocks and the world edge.
func resolve(pos: Vector3, radius: float) -> Vector3:
	var c := Vector2i(floori(pos.x / BLOCK_CELL), floori(pos.z / BLOCK_CELL))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var list = blockers.get(c + Vector2i(dx, dz))
			if list == null:
				continue
			for b in list:
				var d := Vector2(pos.x - b.x, pos.z - b.y)
				var min_d: float = radius + b.z
				var l2 := d.length_squared()
				if l2 < min_d * min_d:
					if l2 < 0.0001:
						d = Vector2(1, 0)
					d = d.normalized() * min_d
					pos.x = b.x + d.x
					pos.z = b.y + d.y
	var r := Vector2(pos.x, pos.z).length()
	var limit := PLAY_RADIUS + 25.0
	if r > limit:
		pos.x *= limit / r
		pos.z *= limit / r
	return pos


func add_perch(p: Vector3) -> void:
	var c := Vector2i(floori(p.x / PERCH_CELL), floori(p.z / PERCH_CELL))
	if not perches.has(c):
		perches[c] = PackedVector3Array()
	var arr: PackedVector3Array = perches[c]
	arr.append(p)
	perches[c] = arr


## Random landing spot (flower head, shrub top) within `radius` of `pos`.
func random_perch_near(pos: Vector3, radius: float) -> Variant:
	var cr := int(ceil(radius / PERCH_CELL))
	var c := Vector2i(floori(pos.x / PERCH_CELL), floori(pos.z / PERCH_CELL))
	var best: Variant = null
	var seen := 0
	for dz in range(-cr, cr + 1):
		for dx in range(-cr, cr + 1):
			var arr = perches.get(c + Vector2i(dx, dz))
			if arr == null:
				continue
			for i in 4:
				var p: Vector3 = arr[randi() % arr.size()]
				if p.distance_to(pos) <= radius:
					seen += 1
					if randi() % seen == 0:
						best = p
	return best


# ------------------------------------------------------------- generation

func _setup_noise() -> void:
	_n_hills.seed = 11
	_n_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_n_hills.frequency = 1.0 / 170.0
	_n_hills.fractal_octaves = 3
	_n_detail.seed = 23
	_n_detail.frequency = 1.0 / 38.0
	_n_detail.fractal_octaves = 2
	_n_ridge.seed = 5
	_n_ridge.frequency = 1.0 / 240.0
	_n_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_n_ridge.fractal_octaves = 4
	_n_zone.seed = 91
	_n_zone.frequency = 1.0 / 55.0
	_n_zone.fractal_octaves = 2
	_n_zone2.seed = 57
	_n_zone2.frequency = 1.0 / 80.0
	_n_zone2.fractal_octaves = 2
	_n_zone3.seed = 33
	_n_zone3.frequency = 1.0 / 30.0
	_n_zone3.fractal_octaves = 2


func _base_height(x: float, z: float) -> float:
	var h := _n_hills.get_noise_2d(x, z) * 8.0 + _n_detail.get_noise_2d(x, z) * 1.3
	var r := sqrt(x * x + z * z)
	var edge := smoothstep(170.0, 430.0, r)
	h += edge * (30.0 + _n_ridge.get_noise_2d(x, z) * 28.0)
	var pd := path_dist(x, z)
	h -= (1.0 - smoothstep(3.0, 30.0, pd)) * 1.2
	return h


func _compute_water_level() -> void:
	var lowest := INF
	for i in 24:
		var a := TAU * i / 24.0
		for rr in [1.6, 2.1, 2.6]:
			var p: Vector2 = POND_CENTER + Vector2(cos(a), sin(a)) * POND_RADIUS * rr
			lowest = minf(lowest, _base_height(p.x, p.y))
	water_level = lowest - 0.35


func _height_fn(x: float, z: float) -> float:
	var h := _base_height(x, z)
	var d := Vector2(x, z).distance_to(POND_CENTER)
	if d < POND_RADIUS * 2.6:
		var t := clampf((d - POND_RADIUS * 0.3) / (POND_RADIUS * 1.3), 0.0, 1.0)
		var basin := lerpf(water_level - 1.8, water_level + 0.6, smoothstep(0.0, 1.0, t))
		var blend := smoothstep(POND_RADIUS * 1.6, POND_RADIUS * 2.6, d)
		h = lerpf(basin, h, blend)
	return h


func _generate_heights() -> void:
	heights.resize(RES * RES)
	for iz in RES:
		var z := -HALF + iz * CELL
		for ix in RES:
			var x := -HALF + ix * CELL
			heights[iz * RES + ix] = _height_fn(x, z)


func _generate_masks() -> void:
	flower_mask.resize(RES * RES)
	forest_mask.resize(RES * RES)
	tall_mask.resize(RES * RES)
	var spawn := Vector2(path_x(SPAWN_Z), SPAWN_Z)
	for iz in RES:
		var z := -HALF + iz * CELL
		for ix in RES:
			var x := -HALF + ix * CELL
			var i := iz * RES + ix
			var r := sqrt(x * x + z * z)
			var pd := path_dist(x, z)
			var pond := Vector2(x, z).distance_to(POND_CENTER)
			var near_spawn := Vector2(x, z).distance_to(spawn)

			var fl := smoothstep(0.05, 0.4, _n_zone.get_noise_2d(x, z))
			var strip := (1.0 - smoothstep(9.0, 26.0, pd)) * smoothstep(-0.35, 0.15, _n_zone.get_noise_2d(x + 300.0, z))
			fl = maxf(fl, strip)
			fl *= smoothstep(1.5, 4.0, pd)
			fl *= 1.0 - smoothstep(PLAY_RADIUS, PLAY_RADIUS + 60.0, r)
			fl *= smoothstep(POND_RADIUS * 1.3, POND_RADIUS * 1.9, pond)

			var forest := smoothstep(PLAY_RADIUS - 25.0, PLAY_RADIUS + 25.0, r)
			var grove := smoothstep(0.36, 0.55, _n_zone2.get_noise_2d(x, z))
			forest = maxf(forest, grove)
			forest *= smoothstep(8.0, 22.0, pd)
			forest *= smoothstep(26.0, 45.0, near_spawn)
			forest *= smoothstep(POND_RADIUS * 1.8, POND_RADIUS * 2.6, pond)
			fl *= 1.0 - forest * 0.85

			var tall := smoothstep(0.12, 0.45, _n_zone3.get_noise_2d(x * 0.6 + 100.0, z * 0.6))
			tall *= (1.0 - forest) * smoothstep(3.0, 6.0, pd) * (1.0 - fl * 0.6)
			var reeds := (1.0 - smoothstep(POND_RADIUS * 1.1, POND_RADIUS * 1.6, pond)) * smoothstep(POND_RADIUS * 0.85, POND_RADIUS * 1.05, pond)
			tall = maxf(tall, reeds)

			flower_mask[i] = fl
			forest_mask[i] = forest
			tall_mask[i] = tall


func _publish_globals() -> void:
	var himg := Image.create_from_data(RES, RES, false, Image.FORMAT_RF, heights.to_byte_array())
	var htex := ImageTexture.create_from_image(himg)

	var mimg := Image.create(RES, RES, false, Image.FORMAT_RGBA8)
	for iz in RES:
		for ix in RES:
			var i := iz * RES + ix
			mimg.set_pixel(ix, iz, Color(0.0, flower_mask[i], forest_mask[i], tall_mask[i]))
	var mtex := ImageTexture.create_from_image(mimg)

	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	var nimg := noise.get_seamless_image(256, 256, false, false, 0.1, true)
	nimg.convert(Image.FORMAT_RGBA8)
	nimg.generate_mipmaps()
	var ntex := ImageTexture.create_from_image(nimg)

	RenderingServer.global_shader_parameter_set("height_tex", htex)
	RenderingServer.global_shader_parameter_set("mask_tex", mtex)
	RenderingServer.global_shader_parameter_set("noise_tex", ntex)
	RenderingServer.global_shader_parameter_set("water_level", water_level)


func _build_terrain_mesh() -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	verts.resize(RES * RES)
	normals.resize(RES * RES)
	for iz in RES:
		for ix in RES:
			var i := iz * RES + ix
			var x := -HALF + ix * CELL
			var z := -HALF + iz * CELL
			verts[i] = Vector3(x, heights[i], z)
			var hl := heights[iz * RES + maxi(ix - 1, 0)]
			var hr := heights[iz * RES + mini(ix + 1, RES - 1)]
			var hd := heights[maxi(iz - 1, 0) * RES + ix]
			var hu := heights[mini(iz + 1, RES - 1) * RES + ix]
			normals[i] = Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized()
	var indices := PackedInt32Array()
	indices.resize((RES - 1) * (RES - 1) * 6)
	var k := 0
	for iz in RES - 1:
		for ix in RES - 1:
			var a := iz * RES + ix
			var b := a + 1
			var c := a + RES
			var d := c + 1
			indices[k] = a
			indices[k + 1] = b
			indices[k + 2] = d
			indices[k + 3] = a
			indices[k + 4] = d
			indices[k + 5] = c
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/terrain.gdshader")
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = mesh
	add_child(mi)
