class_name GunBuilder
extends RefCounted
## Builds cardboard-and-tape guns. The barrel points along -Z; the origin is
## where the firing hand grips. The returned root carries metadata:
##   "sight"  : Vector3 point the eye lines up with when aiming
##   "muzzle" : Node3D at the barrel tip
##   "mag"    : Node3D magazine (animated during reloads)
##   "pump"   : Node3D fore-end (shotgun) or null
##   "left"   : Vector3 where the support hand holds

static func build(id: String, viewmodel: bool, team_color := Color(0.24, 0.45, 0.85)) -> Node3D:
	var w := WeaponDB.get_data(id)
	var root := Node3D.new()
	root.name = "Gun_" + id
	var body_c: Color = w["body"]
	var trim_c: Color = w["trim"]
	var ow := 0.0035 if viewmodel else 0.012
	var m_body := Craft.outlined(Craft.mat(Craft.Kind.PAPER, body_c, 0, Color.WHITE, 1.0, 0.3, true, viewmodel), ow, viewmodel)
	var m_trim := Craft.outlined(Craft.mat(Craft.Kind.CARDBOARD, trim_c, 0, Color.WHITE, 1.0, 1.0, true, viewmodel), ow, viewmodel)
	var m_tape := Craft.mat(Craft.Kind.TAPE, Color(0.93, 0.86, 0.66), 0, Color.WHITE, 1.0, 0.0, true, viewmodel)
	var m_foil := Craft.outlined(Craft.mat(Craft.Kind.FOIL, Color(0.78, 0.8, 0.84), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), ow, viewmodel)
	var m_dark := Craft.outlined(Craft.mat(Craft.Kind.PAPER, Color(0.14, 0.14, 0.16), 0, Color.WHITE, 1.0, 0.0, true, viewmodel), ow, viewmodel)
	var m_cap := Craft.mat(Craft.Kind.PLASTIC, team_color, 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	var m_sight := Craft.mat(Craft.Kind.PLASTIC, Color(1.0, 0.85, 0.2), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	var shadows := not viewmodel

	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	root.add_child(muzzle)
	var mag := Node3D.new()
	mag.name = "Mag"
	root.add_child(mag)
	var pump: Node3D = null

	match String(w["model"]):
		"rifle":
			_b(root, Vector3(0, 0.035, -0.08), Vector3(0.055, 0.085, 0.36), m_body, shadows)
			_b(root, Vector3(0, 0.035, -0.37), Vector3(0.064, 0.072, 0.26), m_trim, shadows)
			for z: float in [-0.29, -0.37, -0.45]:
				_b(root, Vector3(0, 0.035, z), Vector3(0.068, 0.076, 0.022), m_tape, shadows)
			_c(root, Vector3(0, 0.045, -0.62), 0.011, 0.26, m_foil, shadows)
			_b(root, Vector3(0, 0.03, 0.2), Vector3(0.045, 0.075, 0.2), m_trim, shadows)
			_b(root, Vector3(0, -0.005, 0.31), Vector3(0.05, 0.11, 0.035), m_dark, shadows)
			_b(root, Vector3(0, -0.05, 0.0), Vector3(0.036, 0.1, 0.045), m_dark, shadows, Vector3(-0.3, 0, 0))
			_b(root, Vector3(0, 0.083, -0.08), Vector3(0.05, 0.012, 0.3), m_dark, shadows)
			for sx: float in [-1.0, 1.0]:
				_b(root, Vector3(sx * 0.014, 0.1, 0.04), Vector3(0.008, 0.03, 0.02), m_dark, shadows)
			_b(root, Vector3(0, 0.098, -0.5), Vector3(0.012, 0.034, 0.012), m_dark, shadows)
			_cap(root, Vector3(0, 0.12, -0.5), 0.006, m_sight, shadows)
			_b(mag, Vector3(0, -0.075, -0.15), Vector3(0.03, 0.13, 0.065), m_dark, shadows, Vector3(0.25, 0, 0))
			_cap(root, Vector3(0.03, 0.035, -0.12), 0.012, m_cap, shadows)
			muzzle.position = Vector3(0, 0.045, -0.76)
			root.set_meta("sight", Vector3(0, 0.12, 0.0))
			root.set_meta("left", Vector3(0, 0.0, -0.38))
		"ak":
			_b(root, Vector3(0, 0.03, -0.08), Vector3(0.055, 0.08, 0.38), m_body, shadows)
			_b(root, Vector3(0, 0.03, -0.38), Vector3(0.06, 0.065, 0.24), m_trim, shadows)
			_c(root, Vector3(0, 0.05, -0.62), 0.012, 0.3, m_foil, shadows)
			_c(root, Vector3(0, 0.075, -0.42), 0.01, 0.22, m_foil, shadows)
			_b(root, Vector3(0, 0.0, 0.24), Vector3(0.045, 0.07, 0.26), m_trim, shadows, Vector3(0.12, 0, 0))
			_b(root, Vector3(0, -0.05, 0.0), Vector3(0.036, 0.1, 0.045), m_trim, shadows, Vector3(-0.3, 0, 0))
			_b(root, Vector3(0, 0.08, -0.05), Vector3(0.016, 0.02, 0.04), m_dark, shadows)
			_b(root, Vector3(0, 0.09, -0.72), Vector3(0.012, 0.04, 0.012), m_dark, shadows)
			_cap(root, Vector3(0, 0.115, -0.72), 0.006, m_sight, shadows)
			_b(mag, Vector3(0, -0.07, -0.16), Vector3(0.03, 0.1, 0.065), m_trim, shadows, Vector3(0.2, 0, 0))
			_b(mag, Vector3(0, -0.15, -0.19), Vector3(0.03, 0.09, 0.062), m_trim, shadows, Vector3(0.55, 0, 0))
			_b(mag, Vector3(0, -0.07, -0.16), Vector3(0.034, 0.02, 0.07), m_tape, shadows, Vector3(0.2, 0, 0))
			muzzle.position = Vector3(0, 0.05, -0.78)
			root.set_meta("sight", Vector3(0, 0.115, 0.0))
			root.set_meta("left", Vector3(0, -0.005, -0.38))
		"smg":
			_b(root, Vector3(0, 0.035, -0.06), Vector3(0.055, 0.085, 0.28), m_body, shadows)
			_b(root, Vector3(0, 0.03, -0.25), Vector3(0.06, 0.06, 0.12), m_trim, shadows)
			_c(root, Vector3(0, 0.045, -0.36), 0.013, 0.12, m_foil, shadows)
			_b(root, Vector3(0, 0.02, 0.18), Vector3(0.012, 0.012, 0.18), m_foil, shadows)
			_b(root, Vector3(0, -0.03, 0.27), Vector3(0.04, 0.07, 0.02), m_dark, shadows)
			_b(root, Vector3(0, -0.05, 0.0), Vector3(0.034, 0.1, 0.042), m_dark, shadows, Vector3(-0.25, 0, 0))
			_b(root, Vector3(0, 0.09, -0.06), Vector3(0.044, 0.03, 0.12), Craft.outlined(Craft.mat(Craft.Kind.PAPER, team_color, 0, Color.WHITE, 1.0, 0.0, true, viewmodel), ow, viewmodel), shadows)
			_cap(root, Vector3(0, 0.112, -0.06), 0.008, Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.25, 0.2), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), shadows)
			_b(mag, Vector3(0, -0.11, -0.12), Vector3(0.028, 0.17, 0.05), m_dark, shadows)
			muzzle.position = Vector3(0, 0.045, -0.43)
			root.set_meta("sight", Vector3(0, 0.112, 0.0))
			root.set_meta("left", Vector3(0, -0.01, -0.25))
		"sniper":
			_b(root, Vector3(0, 0.03, -0.12), Vector3(0.055, 0.075, 0.5), m_trim, shadows)
			_c(root, Vector3(0, 0.05, -0.75), 0.013, 0.55, m_foil, shadows)
			_b(root, Vector3(0, 0.0, 0.25), Vector3(0.048, 0.09, 0.3), m_trim, shadows)
			_b(root, Vector3(0, -0.05, 0.02), Vector3(0.036, 0.1, 0.045), m_trim, shadows, Vector3(-0.3, 0, 0))
			_c(root, Vector3(0, 0.12, -0.1), 0.026, 0.32, m_body, shadows)
			_cap(root, Vector3(0, 0.12, -0.27), 0.03, Craft.mat(Craft.Kind.PLASTIC, Color(0.4, 0.75, 1.0), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), shadows, true)
			_b(root, Vector3(0, 0.085, -0.05), Vector3(0.02, 0.03, 0.03), m_dark, shadows)
			_b(root, Vector3(0, 0.085, -0.16), Vector3(0.02, 0.03, 0.03), m_dark, shadows)
			_b(root, Vector3(0.045, 0.05, 0.03), Vector3(0.05, 0.012, 0.012), m_foil, shadows)
			_cap(root, Vector3(0.07, 0.05, 0.03), 0.012, m_cap, shadows)
			_b(mag, Vector3(0, -0.04, -0.08), Vector3(0.03, 0.06, 0.08), m_dark, shadows)
			muzzle.position = Vector3(0, 0.05, -1.03)
			root.set_meta("sight", Vector3(0, 0.12, 0.0))
			root.set_meta("left", Vector3(0, -0.005, -0.42))
		"shotgun":
			_b(root, Vector3(0, 0.035, -0.06), Vector3(0.055, 0.08, 0.3), m_body, shadows)
			_c(root, Vector3(0, 0.055, -0.48), 0.016, 0.62, m_foil, shadows)
			_c(root, Vector3(0, 0.015, -0.42), 0.013, 0.5, m_dark, shadows)
			_b(root, Vector3(0, 0.0, 0.22), Vector3(0.045, 0.08, 0.26), m_trim, shadows, Vector3(0.1, 0, 0))
			_b(root, Vector3(0, -0.05, 0.02), Vector3(0.036, 0.1, 0.045), m_trim, shadows, Vector3(-0.3, 0, 0))
			pump = Node3D.new()
			pump.name = "Pump"
			root.add_child(pump)
			_b(pump, Vector3(0, 0.015, -0.4), Vector3(0.05, 0.05, 0.18), Craft.outlined(Craft.mat(Craft.Kind.FELT, trim_c, Craft.Pattern.STITCH, Craft.CREAM, 0.3, 0.0, true, viewmodel), ow, viewmodel), shadows)
			_cap(root, Vector3(0, 0.08, -0.76), 0.007, m_sight, shadows)
			_b(root, Vector3(0, 0.083, -0.04), Vector3(0.03, 0.01, 0.02), m_dark, shadows)
			muzzle.position = Vector3(0, 0.055, -0.8)
			root.set_meta("sight", Vector3(0, 0.088, 0.0))
			root.set_meta("left", Vector3(0, -0.01, -0.4))
		"pistol":
			_b(root, Vector3(0, 0.055, -0.07), Vector3(0.034, 0.04, 0.2), m_foil, shadows)
			_b(root, Vector3(0, 0.025, -0.06), Vector3(0.032, 0.03, 0.17), m_body, shadows)
			_b(root, Vector3(0, -0.035, 0.0), Vector3(0.032, 0.1, 0.05), m_body, shadows, Vector3(-0.22, 0, 0))
			_b(root, Vector3(0, 0.0, -0.035), Vector3(0.008, 0.02, 0.05), m_dark, shadows)
			_b(root, Vector3(0, 0.08, -0.16), Vector3(0.006, 0.012, 0.008), m_dark, shadows)
			_b(root, Vector3(0, 0.08, 0.02), Vector3(0.022, 0.012, 0.008), m_dark, shadows)
			_cap(root, Vector3(0, 0.09, -0.16), 0.004, m_sight, shadows)
			_b(mag, Vector3(0, -0.09, 0.012), Vector3(0.026, 0.03, 0.04), m_dark, shadows, Vector3(-0.22, 0, 0))
			muzzle.position = Vector3(0, 0.055, -0.18)
			root.set_meta("sight", Vector3(0, 0.09, 0.0))
			root.set_meta("left", Vector3(-0.02, -0.04, 0.01))
	if String(w["model"]) != "pistol":
		_details(root, viewmodel, team_color, ow, m_dark, m_tape)
	root.set_meta("muzzle", muzzle)
	root.set_meta("mag", mag)
	root.set_meta("pump", pump)
	return root


## Small hand-made details that sell the craft look up close: brass-button
## rivets, an inked ejection port, a pipe-cleaner trigger guard, a team
## sticker and a felt sling.
static func _details(root: Node3D, viewmodel: bool, team_color: Color, ow: float, m_dark: Material, m_tape: Material) -> void:
	var shadows := not viewmodel
	var rivet := Craft.mat(Craft.Kind.PLASTIC, Color(0.85, 0.66, 0.25), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	for side: float in [-1.0, 1.0]:
		for z: float in [-0.17, -0.05, 0.06]:
			Craft.part(root, Craft.cylinder(0.006, 0.006, 0.006, 8), rivet, Vector3(side * 0.029, 0.05, z), Vector3(0, 0, PI * 0.5), Vector3.ONE, shadows)
	_b(root, Vector3(0.0285, 0.045, -0.07), Vector3(0.004, 0.022, 0.07), m_dark, shadows)
	var pipe := Craft.mat(Craft.Kind.FELT, Color(0.2, 0.2, 0.22), 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	_b(root, Vector3(0, -0.035, -0.07), Vector3(0.01, 0.008, 0.075), pipe, shadows)
	_b(root, Vector3(0, -0.02, -0.035), Vector3(0.006, 0.03, 0.006), Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.76, 0.8), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), shadows, Vector3(0.3, 0, 0))
	var sticker := Craft.mat(Craft.Kind.PAPER, team_color, 0, Color.WHITE, 1.0, 0.0, false, viewmodel)
	Craft.part(root, Craft.cutout(Craft.star_points(0.022, 0.01), 0.002), sticker, Vector3(0.0285, 0.035, 0.17), Vector3(0, PI * 0.5, 0.3), Vector3.ONE, shadows)
	var sling := Craft.mat(Craft.Kind.KNIT, team_color.darkened(0.2), 0, Color.WHITE, 3.0, 0.0, true, viewmodel)
	_b(root, Vector3(-0.03, -0.02, 0.12), Vector3(0.006, 0.02, 0.28), sling, shadows, Vector3(0.12, 0, 0))


static func knife(viewmodel: bool) -> Node3D:
	var root := Node3D.new()
	var ow := 0.0035 if viewmodel else 0.012
	var blade := Craft.outlined(Craft.mat(Craft.Kind.FOIL, Color(0.86, 0.88, 0.92), 0, Color.WHITE, 1.0, 0.0, true, viewmodel), ow, viewmodel)
	var grip := Craft.outlined(Craft.mat(Craft.Kind.TAPE, Color(0.2, 0.2, 0.22), 0, Color.WHITE, 1.0, 0.0, true, viewmodel), ow, viewmodel)
	_b(root, Vector3(0, 0, 0.04), Vector3(0.03, 0.03, 0.11), grip, not viewmodel)
	var pts := PackedVector2Array([Vector2(-0.016, 0), Vector2(0.016, 0), Vector2(0.012, 0.15), Vector2(-0.016, 0.19)])
	Craft.part(root, Craft.cutout(pts, 0.006), blade, Vector3(0, 0, -0.01), Vector3(-PI * 0.5, 0, 0), Vector3.ONE, not viewmodel)
	return root


static func frag(viewmodel: bool) -> Node3D:
	var root := Node3D.new()
	var ow := 0.0035 if viewmodel else 0.01
	var body := Craft.outlined(Craft.mat(Craft.Kind.KNIT, Color(0.36, 0.5, 0.3), 0, Color.WHITE, 3.0, 0.0, false, viewmodel), ow, viewmodel)
	Craft.part(root, Craft.sphere(0.045, 12), body, Vector3.ZERO, Vector3.ZERO, Vector3(1, 1.15, 1), not viewmodel)
	Craft.part(root, Craft.cylinder(0.016, 0.02, 0.03, 8), Craft.mat(Craft.Kind.FOIL, Color(0.8, 0.8, 0.82), 0, Color.WHITE, 1.0, 0.0, false, viewmodel), Vector3(0, 0.06, 0))
	Craft.part(root, Craft.cylinder(0.012, 0.012, 0.004, 10), Craft.mat(Craft.Kind.PLASTIC, Craft.RED, 0, Color.WHITE, 1.0, 0.0, false, viewmodel), Vector3(0.022, 0.07, 0), Vector3(0, 0, PI * 0.5))
	return root


static func _b(parent: Node3D, pos: Vector3, size: Vector3, m: Material, shadows: bool, rot := Vector3.ZERO) -> MeshInstance3D:
	return Craft.box(parent, pos, size, m, rot, shadows)


static func _c(parent: Node3D, pos: Vector3, r: float, length: float, m: Material, shadows: bool) -> MeshInstance3D:
	return Craft.part(parent, Craft.cylinder(r, r, length, 10), m, pos, Vector3(PI * 0.5, 0, 0), Vector3.ONE, shadows)


## A bottle-cap disc facing -Z (sights, logos, lens covers).
static func _cap(parent: Node3D, pos: Vector3, r: float, m: Material, shadows: bool, facing_z := false) -> MeshInstance3D:
	var rot := Vector3(PI * 0.5, 0, 0) if facing_z else Vector3.ZERO
	return Craft.part(parent, Craft.cylinder(r, r, r * 0.6, 10), m, pos, rot, Vector3.ONE, shadows)
