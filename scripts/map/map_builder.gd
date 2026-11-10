class_name MapBuilder
extends RefCounted
## Helpers for laying out a map out of craft materials. Solid pieces get
## box collision on the "world" layer and live under the navigation region
## so bots can path around them; decoration lives elsewhere.

const WORLD_LAYER := 1

var nav_root: Node3D
var deco_root: Node3D


func _init(nav: Node3D, deco: Node3D) -> void:
	nav_root = nav
	deco_root = deco


## A solid box: collision + mesh. rot_y in radians.
func solid(pos: Vector3, size: Vector3, material: Material, rot_y := 0.0, visible := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = rot_y
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	if visible and material:
		Craft.box(body, Vector3.ZERO, size, material)
	nav_root.add_child(body)
	return body


## Solid box given min/max corners (handy for walls and floors).
func span(a: Vector3, b: Vector3, material: Material) -> StaticBody3D:
	var lo := a.min(b)
	var hi := a.max(b)
	return solid((lo + hi) * 0.5, hi - lo, material)


## A wall along X or Z from p0 to p1 (same y), with door/window gaps.
## gaps: Array of Vector4(start, end, bottom, top) measured along the wall.
func wall(p0: Vector3, p1: Vector3, height: float, thick: float, material: Material, gaps: Array = []) -> void:
	var along_x := absf(p1.x - p0.x) > absf(p1.z - p0.z)
	var a := minf(p0.x, p1.x) if along_x else minf(p0.z, p1.z)
	var b := maxf(p0.x, p1.x) if along_x else maxf(p0.z, p1.z)
	var fixed := p0.z if along_x else p0.x
	var y0 := p0.y
	# Split into vertical strips at every gap boundary, then fill each strip
	# except the gap rectangles.
	var cuts := [a, b]
	for g in gaps:
		cuts.append(clampf(g.x, a, b))
		cuts.append(clampf(g.y, a, b))
	cuts.sort()
	for i in cuts.size() - 1:
		var s: float = cuts[i]
		var e: float = cuts[i + 1]
		if e - s < 0.01:
			continue
		var mid := (s + e) * 0.5
		var holes := []
		for g in gaps:
			if mid > g.x and mid < g.y:
				holes.append(Vector2(g.z, g.w))
		holes.sort_custom(func(u, v): return u.x < v.x)
		var cur := 0.0
		for h in holes:
			if h.x > cur + 0.01:
				_wall_piece(along_x, fixed, s, e, y0 + cur, y0 + h.x, thick, material)
			cur = maxf(cur, h.y)
		if cur < height - 0.01:
			_wall_piece(along_x, fixed, s, e, y0 + cur, y0 + height, thick, material)


func _wall_piece(along_x: bool, fixed: float, s: float, e: float, ya: float, yb: float, thick: float, material: Material) -> void:
	if along_x:
		solid(Vector3((s + e) * 0.5, (ya + yb) * 0.5, fixed), Vector3(e - s, yb - ya, thick), material)
	else:
		solid(Vector3(fixed, (ya + yb) * 0.5, (s + e) * 0.5), Vector3(thick, yb - ya, e - s), material)


## Stairs from `bottom` up to `top` (they differ in y and in one horizontal
## axis). Walkable ramp collision with stepped visuals on top.
func stairs(bottom: Vector3, top: Vector3, width: float, material: Material, side_material: Material = null) -> void:
	var dir := top - bottom
	var flat := Vector3(dir.x, 0, dir.z)
	var run := flat.length()
	var rise := dir.y
	var yaw := atan2(-flat.x, -flat.z)
	var length := sqrt(run * run + rise * rise)
	var pitch := atan2(rise, run)
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = (bottom + top) * 0.5 + Vector3(0, -0.12, 0)
	body.rotation = Vector3(pitch, yaw, 0)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, 0.24, length)
	shape.shape = bs
	body.add_child(shape)
	nav_root.add_child(body)
	var steps := maxi(int(round(rise / 0.25)), 2)
	var fwd := flat.normalized()
	for i in steps:
		var t := (i + 0.5) / steps
		var y_top := bottom.y + rise * (i + 1) / steps
		var c := bottom + fwd * run * t
		var h := y_top - bottom.y
		var step := Craft.box(deco_root, Vector3(c.x, bottom.y + h * 0.5, c.z), Vector3(width, h, run / steps + 0.01), material)
		step.rotation.y = yaw
	if side_material:
		for side: float in [-1.0, 1.0]:
			var off := fwd.cross(Vector3.UP).normalized() * (width * 0.5 + 0.06) * side
			var rail := Craft.box(deco_root, (bottom + top) * 0.5 + off + Vector3(0, 0.55, 0), Vector3(0.1, 0.1, length), side_material)
			rail.rotation = Vector3(pitch, yaw, 0)


## A solid upright cylinder (pillars, drums, tanks).
func column(pos: Vector3, radius: float, height: float, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = pos + Vector3(0, height * 0.5, 0)
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = height
	shape.shape = cs
	body.add_child(shape)
	Craft.part(body, Craft.cylinder(radius, radius, height, 18), material)
	nav_root.add_child(body)
	return body


## Collision only (map edges, invisible blockers).
func blocker(pos: Vector3, size: Vector3) -> StaticBody3D:
	return solid(pos, size, null, 0.0, false)


func deco_box(pos: Vector3, size: Vector3, material: Material, rot := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	return Craft.box(deco_root, pos, size, material, rot, shadows)
