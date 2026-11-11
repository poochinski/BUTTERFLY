class_name Fx
extends RefCounted
## One-shot craft effects: paper-star muzzle flashes, tracers, paper-scrap
## impacts, punched bullet holes, cotton-ball explosions and confetti.

static var root: Node3D
static var _hole_tex: Texture2D
static var _scrap_mesh: QuadMesh
static var _decals: Array = []


static func _later(node: Node, seconds: float) -> void:
	node.get_tree().create_timer(seconds, false).timeout.connect(node.queue_free)


static func muzzle_flash(muzzle: Node3D, viewmodel: bool) -> void:
	if muzzle == null or not muzzle.is_inside_tree():
		return
	# Layered tissue paper: a hot yellow-white core inside ragged orange
	# petals, cut fresh for every shot, plus a side burst from the ports.
	var core := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.86, 0.55), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	var petals := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.55, 0.18), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	var s := randf_range(0.75, 1.2)
	var a := Craft.part(muzzle, Craft.cutout(Craft.star_points(0.075, 0.03, 7), 0.003), petals, Vector3(0, 0, -0.035), Vector3(0, 0, randf() * TAU), Vector3.ONE * s, false)
	var c := Craft.part(muzzle, Craft.cutout(Craft.star_points(0.04, 0.018, 5), 0.003), core, Vector3(0, 0, -0.03), Vector3(0, 0, randf() * TAU), Vector3.ONE * s, false)
	var side := Craft.part(muzzle, Craft.cutout(Craft.star_points(0.06, 0.012, 4), 0.003), petals, Vector3(0, 0, -0.07), Vector3(0, PI * 0.5, randf() * TAU), Vector3(1.0, 0.7, 1.0) * s, false)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.42)
	light.light_energy = 1.6
	light.omni_range = 3.5
	light.position = Vector3(0, 0, -0.1)
	muzzle.add_child(light)
	_later(a, 0.04)
	_later(c, 0.04)
	_later(side, 0.04)
	_later(light, 0.045)
	# A wisp of grey cotton smoke left hanging in the air.
	if root and randf() < 0.6:
		var puff := MeshInstance3D.new()
		puff.mesh = Craft.sphere(0.05, 8)
		puff.material_override = Craft.mat(Craft.Kind.FELT, Color(0.7, 0.7, 0.68), 0, Color.WHITE, 1.0, 0.0, false)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(puff)
		puff.global_position = muzzle.global_position - muzzle.global_transform.basis.z * 0.12
		puff.scale = Vector3.ONE * 0.3
		var tw := puff.create_tween()
		tw.tween_property(puff, "scale", Vector3.ONE * randf_range(1.2, 1.8), 0.5).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(puff, "global_position", puff.global_position + Vector3(randf_range(-0.05, 0.05), 0.25, randf_range(-0.05, 0.05)), 0.7)
		tw.tween_property(puff, "scale", Vector3.ONE * 0.01, 0.4)
		tw.tween_callback(puff.queue_free)


static var _casings: Array = []
static var _mags: Array = []


## A spent case thrown from the ejection port. It bounces on the floor and
## lies there a while. kind: 0 rifle, 1 pistol, 2 shotgun hull, 3 magnum.
static func casing(pos: Vector3, basis: Basis, kind := 0) -> void:
	if root == null:
		return
	var body := RigidBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	body.mass = 0.02
	body.continuous_cd = true
	var size: Vector3 = [Vector3(0.011, 0.011, 0.045), Vector3(0.01, 0.01, 0.02), Vector3(0.02, 0.02, 0.06), Vector3(0.015, 0.015, 0.07)][kind]
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = Craft.cylinder(size.x * 0.5, size.x * 0.5, size.z, 8)
	mi.rotation.x = PI * 0.5
	if kind == 2:
		mi.material_override = Craft.mat(Craft.Kind.PLASTIC, Color(0.55, 0.12, 0.1), 0, Color.WHITE, 1.0, 0.0, false)
	else:
		mi.material_override = Craft.mat(Craft.Kind.FOIL, Color(0.74, 0.57, 0.27), 0, Color.WHITE, 1.0, 0.0, false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	root.add_child(body)
	body.global_transform = Transform3D(basis, pos)
	var out := (basis.x * 1.0 + basis.y * 0.75 + basis.z * 0.25).normalized()
	body.linear_velocity = out * randf_range(2.2, 3.2)
	body.angular_velocity = Vector3(randf_range(-20, 20), randf_range(-30, 30), randf_range(-20, 20))
	_casings.append(body)
	if _casings.size() > 40:
		var old = _casings.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	_later(body, 6.0)


## The empty magazine stripped out during a reload falls to the floor and
## stays there for a while.
static func dropped_mag(mag: Node3D) -> void:
	if root == null or mag == null or not mag.is_inside_tree():
		return
	var box := AABB()
	var first := true
	for c in mag.get_children():
		var mis: Array = [c] if c is MeshInstance3D else c.get_children()
		for m in mis:
			if not m is MeshInstance3D:
				continue
			var xf: Transform3D = (c.transform * m.transform) if m != c else (m as Node3D).transform
			var bb: AABB = xf * (m as MeshInstance3D).get_aabb()
			box = bb if first else box.merge(bb)
			first = false
	if first:
		return
	var body := RigidBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	body.mass = 0.4
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = Craft.unit_box()
	mi.scale = box.size
	mi.material_override = Craft.mat(Craft.Kind.PAPER, Color(0.13, 0.13, 0.14), 0, Color.WHITE, 1.0, 0.0, false)
	body.add_child(mi)
	root.add_child(body)
	var gx := mag.global_transform
	body.global_transform = Transform3D(gx.basis.orthonormalized(), gx * box.get_center())
	body.linear_velocity = -gx.basis.y.normalized() * 1.5
	body.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-2, 2), randf_range(-3, 3))
	_mags.append(body)
	if _mags.size() > 8:
		var old = _mags.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	_later(body, 12.0)


static func tracer(from: Vector3, to: Vector3, color := Color(1.0, 0.82, 0.55)) -> void:
	if root == null:
		return
	var d := from.distance_to(to)
	if d < 0.5:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = Craft.unit_box()
	mi.material_override = Craft.mat(Craft.Kind.GLOW, color, 0, Color.WHITE, 1.0, 0.0, false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var len := minf(d * 0.6, 6.0)
	var start := from.lerp(to, randf_range(0.05, 0.3))
	mi.global_transform = Transform3D(Basis.looking_at(to - from), start.lerp(start + (to - from).normalized() * len, 0.5))
	mi.scale = Vector3(0.012, 0.012, len)
	_later(mi, 0.04)


static func impact(pos: Vector3, normal: Vector3, color: Color, hole := true) -> void:
	if root == null:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 10
	p.lifetime = 0.9
	p.explosiveness = 0.95
	p.direction = normal
	p.spread = 50.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -7.0, 0)
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.mesh = _scrap()
	p.material_override = Craft.mat(Craft.Kind.PAPER, color, 0, Color.WHITE, 1.0, 0.0, false)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(p)
	p.global_position = pos + normal * 0.02
	p.emitting = true
	_later(p, 1.2)
	if hole:
		_bullet_hole(pos, normal)


static func _scrap() -> QuadMesh:
	if _scrap_mesh == null:
		_scrap_mesh = QuadMesh.new()
		_scrap_mesh.size = Vector2(0.05, 0.035)
	return _scrap_mesh


static func _bullet_hole(pos: Vector3, normal: Vector3) -> void:
	if _hole_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var v := Vector2(x - 31.5, y - 31.5)
				var a := atan2(v.y, v.x)
				var r := v.length() / 32.0
				var edge := 0.55 + 0.12 * sin(a * 7.0) + 0.06 * sin(a * 13.0 + 1.0)
				var col := Color(0, 0, 0, 0)
				if r < edge * 0.62:
					col = Color(0.08, 0.06, 0.05, 1.0)
				elif r < edge:
					col = Color(0.95, 0.9, 0.78, 0.9)
				img.set_pixel(x, y, col)
		_hole_tex = ImageTexture.create_from_image(img)
	var d := Decal.new()
	d.texture_albedo = _hole_tex
	d.size = Vector3(0.12, 0.1, 0.12)
	d.cull_mask = 1
	root.add_child(d)
	var up := normal
	var ref := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(up).normalized()
	var z := x.cross(up).normalized()
	d.global_transform = Transform3D(Basis(x, up, z).rotated(up, randf() * TAU), pos)
	_decals.append(d)
	if _decals.size() > 80:
		var old = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()


static func confetti(pos: Vector3, colors: Array, amount := 60, force := 4.0) -> void:
	if root == null:
		return
	for i in colors.size():
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.emitting = false
		p.amount = maxi(amount / colors.size(), 4)
		p.lifetime = 2.2
		p.explosiveness = 0.95
		p.direction = Vector3.UP
		p.spread = 80.0
		p.initial_velocity_min = force * 0.5
		p.initial_velocity_max = force * 1.2
		p.gravity = Vector3(0, -4.0, 0)
		p.damping_min = 1.5
		p.damping_max = 3.0
		p.angular_velocity_min = -540.0
		p.angular_velocity_max = 540.0
		p.mesh = _scrap()
		p.scale_amount_min = 0.8
		p.scale_amount_max = 1.6
		p.material_override = Craft.mat(Craft.Kind.PAPER, colors[i], 0, Color.WHITE, 1.0, 0.0, false)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.3
		root.add_child(p)
		p.global_position = pos
		p.emitting = true
		_later(p, 2.5)


static func explosion(pos: Vector3, radius: float) -> void:
	if root == null:
		return
	confetti(pos + Vector3(0, 0.3, 0), [Craft.KRAFT, Color(0.3, 0.3, 0.31), Color(0.5, 0.48, 0.44), Color(0.82, 0.42, 0.14)], 90, 9.0)
	# Teased cotton smoke, grey and sooty, around a tissue-paper fireball.
	var puff_m := Craft.mat(Craft.Kind.FELT, Color(0.6, 0.59, 0.56), 0, Color.WHITE, 1.0, 0.0, false)
	var soot_m := Craft.mat(Craft.Kind.FELT, Color(0.32, 0.31, 0.3), 0, Color.WHITE, 1.0, 0.0, false)
	var fire_m := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.58, 0.22), 0, Color.WHITE, 1.0, 0.0, false)
	for i in 9:
		var mi := MeshInstance3D.new()
		mi.mesh = Craft.sphere(0.5, 12)
		mi.material_override = fire_m if i <= 2 else (soot_m if i % 3 == 0 else puff_m)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		var off := Vector3(randf_range(-1, 1), randf_range(0.2, 1.2), randf_range(-1, 1)) * radius * 0.25
		mi.global_position = pos + off * 0.3
		mi.scale = Vector3.ONE * 0.2
		var tw := mi.create_tween()
		var s := randf_range(1.6, 2.8) * (0.6 if i <= 2 else 1.0)
		tw.tween_property(mi, "scale", Vector3.ONE * s, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(mi, "global_position", pos + off + Vector3(0, 0.8, 0), 0.6)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 1.2 if i > 2 else 0.25).set_delay(0.3)
		tw.tween_callback(mi.queue_free)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.3)
	light.light_energy = 6.0
	light.omni_range = radius * 1.8
	root.add_child(light)
	light.global_position = pos + Vector3(0, 1, 0)
	var lt := light.create_tween()
	lt.tween_property(light, "light_energy", 0.0, 0.35)
	lt.tween_callback(light.queue_free)
