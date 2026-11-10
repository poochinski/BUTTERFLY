class_name DebugCapture
extends Node
## Developer helper for automated screenshots. Pass arguments after "--":
##   --shot=/path/out.png  --hour=17.5  --wait=4  --yaw=0.3  --pitch=-0.2
##   --dist=4.4  --pos=x,z  --swing=1.2 (seconds before a net swing)
##   --sneak  --journal  --catch (force a catch for the toast)
##   --bug=species_id (perch one in front of the player)  --flying

var args: PackedStringArray
var _opts := {}
var _t := 0.0
var _done := false
var _swung := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in args:
		var s := String(a)
		if s.begins_with("--"):
			var kv := s.substr(2).split("=", true, 1)
			_opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _opts.has("hour"):
		Game.hour = float(_opts["hour"])
	Game.time_frozen = true
	var rig: CameraRig = get_tree().current_scene.get_node("CameraRig")
	var player: Player = Game.player
	if _opts.has("pos"):
		var p := String(_opts["pos"]).split(",")
		var x := float(p[0])
		var z := float(p[1])
		player.global_position = Vector3(x, Game.world.height_at(x, z), z)
	if _opts.has("yaw"):
		rig.yaw = float(_opts["yaw"])
		player.model.rotation.y = rig.yaw
	if _opts.has("pitch"):
		rig.pitch = float(_opts["pitch"])
	if _opts.has("dist"):
		rig.distance = float(_opts["dist"])
	if _opts.has("sneak"):
		player.sneaking = true
	if _opts.has("nohud"):
		for n in get_tree().current_scene.get_children():
			if n is HUD:
				n.visible = false
	var cycle := get_tree().get_first_node_in_group("day_cycle") as DayCycle
	if cycle:
		print("hour=", Game.hour, " sun_dir=", cycle.sky_mat.get_shader_parameter("sun_dir"), " cover=", cycle.sky_mat.get_shader_parameter("cloud_cover"))
	if _opts.has("novol") and cycle:
		cycle.env.volumetric_fog_enabled = false
	if _opts.has("nofog") and cycle:
		cycle.env.fog_enabled = false
	if _opts.has("noglow") and cycle:
		cycle.env.glow_enabled = false
	if _opts.has("onlysky"):
		for n in get_tree().current_scene.get_children():
			if n is Node3D and not (n is DayCycle) and not (n is CameraRig):
				n.visible = false
		rig.camera.fov = 70.0
	if _opts.has("nossao") and cycle:
		cycle.env.ssao_enabled = false
	if _opts.has("noadj") and cycle:
		cycle.env.adjustment_enabled = false
	if _opts.has("nosun") and cycle:
		cycle.sun.visible = false
		cycle.moon.visible = false
	if _opts.has("nopost"):
		Game.settings["painterly"] = false
	if _opts.has("bug"):
		# Perch a butterfly of the given species just in front of the player.
		var fwd := -player.model.global_transform.basis.z
		var bp := player.global_position + fwd * 2.0 + Vector3(0.3, 1.2, 0)
		var b := Butterfly.new()
		get_tree().current_scene.add_child(b)
		b.setup(String(_opts["bug"]), bp, bp)
		b.set_meta("debug", true)
		if _opts.has("flying"):
			b.state = Butterfly.State.FLY
			b.target = bp + Vector3(0, 0.1, -0.2)


func _process(delta: float) -> void:
	_t += delta
	if _opts.has("swingpose"):
		Game.player.set_physics_process(false)
		Game.player.model.animate(0.016, 0.0, false, true, float(_opts["swingpose"]))
	if _opts.has("bugcam"):
		for b in get_tree().get_nodes_in_group("insects"):
			if b.has_meta("debug"):
				var rig: CameraRig = get_tree().current_scene.get_node("CameraRig")
				var from: Vector3 = b.global_position + Vector3(0.0, 0.6, 1.1)
				rig.set_process(false)
				rig.camera.global_transform = Transform3D(Basis.looking_at(b.global_position - from), from)
	if _opts.has("swing") and not _swung and _t >= float(_opts["swing"]):
		_swung = true
		Game.player.start_swing()
	if _opts.has("catch") and not _done and _t > 1.0 and not has_meta("caught"):
		set_meta("caught", true)
		Game.record_catch(String(_opts["catch"]) if _opts["catch"] != "1" else "monarch")
	if _opts.has("journal") and not has_meta("journal") and _t > 1.0:
		set_meta("journal", true)
		var j := get_tree().current_scene.find_children("*", "Journal", false, false)
		if j.size() > 0:
			j[0].toggle()
	if not _done and _t >= float(_opts.get("wait", "4")):
		_done = true
		var img := get_viewport().get_texture().get_image()
		var out := String(_opts.get("shot", "/tmp/shot.png"))
		img.save_png(out)
		for b in get_tree().get_nodes_in_group("insects"):
			if b.has_meta("debug"):
				print("debug bug at ", b.global_position, " state=", b.state, " scale=", b.scale, " visible=", b.is_visible_in_tree())
		print("player at ", Game.player.global_position, " insects=", get_tree().get_nodes_in_group("insects").size(), " journal=", Game.journal.keys())
		print("Saved ", out, " fps=", Engine.get_frames_per_second())
		get_tree().quit()
