class_name ModelLib
extends RefCounted
## Meshes modelled in Blender (tools/blender/build_*.py, exported to
## assets/models/*.glb). Each mesh surface carries a material *slot name*
## from Blender ("uniform", "steel", "glove"...); `part` instances a mesh
## and swaps every slot for the craft material the caller maps it to, so
## modelled parts share the felt-and-card look of everything else.

static var _files := {}


## All meshes in a .glb, by object name.
static func meshes(file: String) -> Dictionary:
	if _files.has(file):
		return _files[file]
	var d := {}
	var ps := load("res://assets/models/" + file) as PackedScene
	if ps == null:
		push_error("ModelLib: missing model " + file)
		_files[file] = d
		return d
	var inst := ps.instantiate()
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			d[String(n.name)] = (n as MeshInstance3D).mesh
	inst.free()
	_files[file] = d
	return d


static func has(file: String, name: String) -> bool:
	return meshes(file).has(name)


## The material slot names used by a mesh, in surface order.
static func slots(mesh: Mesh) -> PackedStringArray:
	var out := PackedStringArray()
	for i in mesh.get_surface_count():
		var m := mesh.surface_get_material(i)
		out.append(m.resource_name if m else "")
	return out


## Instance mesh `name` from `file` under parent. mats maps slot names to
## materials; unmapped slots use fallback.
static func part(parent: Node3D, file: String, name: String, mats: Dictionary, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE, shadows := true, fallback: Material = null) -> MeshInstance3D:
	var mesh: Mesh = meshes(file).get(name)
	var mi := MeshInstance3D.new()
	mi.name = name
	if mesh == null:
		push_error("ModelLib: no mesh %s in %s" % [name, file])
		parent.add_child(mi)
		return mi
	mi.mesh = mesh
	var names := slots(mesh)
	for i in names.size():
		var m: Material = mats.get(names[i], fallback)
		if m:
			mi.set_surface_override_material(i, m)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
