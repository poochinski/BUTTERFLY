class_name GrassField
extends MultiMeshInstance3D
## A dense patch of grass clumps that travels with the player. The grass
## shader places every blade on the terrain and keeps it fixed in the world.

const SPACING := 0.25
const RADIUS := 34.0


func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/grass.gdshader")
	mat.set_shader_parameter("spacing", SPACING)
	mat.set_shader_parameter("field_radius", RADIUS)
	var mesh := _clump_mesh()
	mesh.surface_set_material(0, mat)

	var n := int(RADIUS * 2.0 / SPACING)
	var xforms := PackedFloat32Array()
	var count := 0
	for iz in n:
		for ix in n:
			var x := -RADIUS + ix * SPACING
			var z := -RADIUS + iz * SPACING
			if x * x + z * z > RADIUS * RADIUS:
				continue
			xforms.append_array([1, 0, 0, x, 0, 1, 0, 0, 0, 0, 1, z])
			count += 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	mm.buffer = xforms
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-RADIUS - 2, -200, -RADIUS - 2), Vector3(RADIUS * 2 + 4, 400, RADIUS * 2 + 4))


func _process(_delta: float) -> void:
	var p: Node3D = Game.player
	if p == null:
		return
	var pos := p.global_position
	global_position = Vector3(snappedf(pos.x, SPACING), 0.0, snappedf(pos.z, SPACING))


## Three tapered blades leaning out from a common root. y runs 0..1 so the
## shader can scale height freely.
func _clump_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 4
	for b in 3:
		var a := TAU * b / 3.0 + 0.4
		var lean := Vector3(cos(a), 0, sin(a)) * 0.12
		var off := Vector3(cos(a), 0, sin(a)) * 0.04
		var side := Vector3(-sin(a), 0, cos(a))
		var w := 0.03
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for s in segs + 1:
			var t := float(s) / segs
			var center := off + lean * t * t + Vector3(0, t, 0)
			var hw := w * (1.0 - t * 0.92)
			var l := center - side * hw
			var r := center + side * hw
			if s > 0:
				var t0 := float(s - 1) / segs
				for v in [[prev_l, t0], [l, t], [r, t], [prev_l, t0], [r, t], [prev_r, t0]]:
					st.set_normal(Vector3.UP)
					st.set_uv(Vector2(0, v[1]))
					st.add_vertex(v[0])
			prev_l = l
			prev_r = r
	return st.commit()
