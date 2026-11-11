class_name GatewayMap
extends GameMap
## GATEWAY: an original papercraft airport, built for 6v6.
##
##   North lane  : the baggage hall: tight, conveyor belts, roll-up doors.
##   Middle lane : terminal catwalk → jet bridge → walk-through airliner
##                 → rear stair truck down onto the tarmac.
##   South lane  : the open apron and sidewalk, with long sightlines.
## Cardstock (blue) spawns in the terminal; Militia (red) on the far tarmac.
##
## Axes: +X east, -Z north, +Y up. 1 unit = 1 metre.

const BOUNDS := Rect2(-60.0, -40.0, 122.0, 68.0)

func build() -> void:
	bounds = BOUNDS
	title = "Gateway"
	orbit = Vector4(0, -2, 58, 46)
	rng.seed = 1977
	nav_region = NavigationRegion3D.new()
	nav_region.name = "Nav"
	add_child(nav_region)
	deco = Node3D.new()
	deco.name = "Deco"
	add_child(deco)
	b = MapBuilder.new(nav_region, deco)
	_environment()
	_ground()
	_terminal()
	_jet_bridge()
	_airliner()
	_baggage_hall()
	_tarmac()
	_apron()
	_bounds()
	_backdrop()
	_dressing()
	_revamp()
	FeltGround.build(self)
	Handmade.build(self)
	AirportLife.build(self)
	_polish()
	_spawn_points()
	_bake_navigation()


# ----------------------------------------------------------------- ground

func _ground() -> void:
	# The collision floor is a slab of dark felt underlay; everything you see
	# on top of it (felt tarmac, lawns, mud, gravel, markings) is laid by
	# FeltGround after the rest of the map is built.
	var underlay := Craft.mat(Craft.Kind.FELT, Color(0.25, 0.23, 0.21), 0, Color.WHITE, 3.0, 0.0)
	b.span(Vector3(-62, -0.5, -42), Vector3(64, 0.0, 30), underlay)
	# Terminal floor: construction-paper tiles.
	var tiles := Craft.mat(Craft.Kind.PAPER, Color(0.74, 0.72, 0.68), Craft.Pattern.CHECKER, Color(0.66, 0.65, 0.62), 0.5, 0.0)
	b.deco_box(Vector3(-36, 0.01, -4), Vector3(44, 0.02, 52), tiles)


# --------------------------------------------------------------- terminal

func _terminal() -> void:
	var outer := Craft.mat(Craft.Kind.CARDBOARD, Craft.CONCRETE, Craft.Pattern.WALL, Craft.CONCRETE_DARK, 1.0)
	var inner := Craft.mat(Craft.Kind.CARDBOARD, Color(0.82, 0.8, 0.76), Craft.Pattern.WALL, Color(0.44, 0.47, 0.5), 1.0)
	var accent := Craft.mat(Craft.Kind.CARDBOARD, Craft.TEAL)
	# The mezzanine is laid with carpet tiles.
	var purple := Craft.mat(Craft.Kind.FELT, Color(0.3, 0.32, 0.36), Craft.Pattern.CHECKER, Color(0.27, 0.29, 0.33), 1.0)
	var rail_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.57, 0.6))

	b.wall(Vector3(-58, 0, -30), Vector3(-58, 0, 22), 8.0, 0.5, outer)
	b.wall(Vector3(-58, 0, -30), Vector3(-14, 0, -30), 8.0, 0.5, outer)
	b.wall(Vector3(-58, 0, 22), Vector3(-14, 0, 22), 8.0, 0.5, outer, [
		Vector4(-40, -36, 0, 3), Vector4(-55, -44, 1.0, 2.6), Vector4(-32, -18, 1.0, 2.6), Vector4(-54, -18, 4.5, 7.0)])
	b.wall(Vector3(-14, 0, -30), Vector3(-14, 0, 22), 8.0, 0.5, outer, [
		Vector4(-29, -26.5, 0, 3), Vector4(-10.5, -7.5, 3, 5.7), Vector4(-6, -2, 0, 3), Vector4(10, 14, 0, 3),
		Vector4(-24, -12, 1.0, 2.6), Vector4(-1, 9, 1.0, 2.6), Vector4(15, 21, 1.0, 2.6), Vector4(-1, 20, 4.5, 7.2)])
	# Cellophane in the upper windows.
	var glass := Craft.cellophane(Color(0.58, 0.7, 0.76, 0.3))
	var g1 := Craft.box(deco, Vector3(-14, 5.85, 9.5), Vector3(0.05, 2.7, 21), glass)
	g1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var g2 := Craft.box(deco, Vector3(-36, 5.75, 22), Vector3(36, 2.5, 0.05), glass)
	g2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Roof with three cellophane skylights letting sunlight stream in. The
	# underside reads as a timber-slat ceiling; the top is dressed in a sheet
	# of grey roofing felt, like a real flat roof.
	var roof := Craft.mat(Craft.Kind.CARDBOARD, Craft.KRAFT)
	var roof_felt := Craft.mat(Craft.Kind.FELT, Color(0.34, 0.35, 0.37), Craft.Pattern.STITCH, Color(0.42, 0.43, 0.45), 2.0)
	var cuts := [-58.0, -50.0, -47.0, -38.0, -35.0, -26.0, -23.0, -14.0]
	for i in range(0, cuts.size(), 2):
		b.span(Vector3(cuts[i], 8.0, -30.2), Vector3(cuts[i + 1], 8.4, 22.2), roof)
		_roof_sheet(Vector3(cuts[i], 8.4, -30.2), Vector3(cuts[i + 1], 8.4, 22.2), roof_felt)
	for i in range(1, cuts.size() - 1, 2):
		b.span(Vector3(cuts[i], 8.0, -30.2), Vector3(cuts[i + 1], 8.4, -18), roof)
		b.span(Vector3(cuts[i], 8.0, 18), Vector3(cuts[i + 1], 8.4, 22.2), roof)
		_roof_sheet(Vector3(cuts[i], 8.4, -30.2), Vector3(cuts[i + 1], 8.4, -18), roof_felt)
		_roof_sheet(Vector3(cuts[i], 8.4, 18), Vector3(cuts[i + 1], 8.4, 22.2), roof_felt)
		var sky_glass := Craft.box(deco, Vector3((cuts[i] + cuts[i + 1]) * 0.5, 8.2, 0), Vector3(cuts[i + 1] - cuts[i], 0.05, 36), Craft.cellophane(Color(0.9, 0.92, 0.9, 0.15)))
		sky_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A blocker keeps everyone off the roof.
	b.blocker(Vector3(-36, 9.5, -4), Vector3(44, 2, 52))

	# Mezzanine floor along the north wall and a catwalk along the east windows.
	b.span(Vector3(-57.75, 2.7, -29.75), Vector3(-14.25, 3.0, -20), purple)
	b.span(Vector3(-17.2, 2.7, -20), Vector3(-14.25, 3.0, -7), purple)
	b.wall(Vector3(-57.75, 3, -20), Vector3(-17.2, 3, -20), 1.0, 0.12, rail_m, [
		Vector4(-52.6, -49.4, 0, 1.0), Vector4(-23.6, -20.4, 0, 1.0)])
	b.wall(Vector3(-17.2, 3, -20), Vector3(-17.2, 3, -7), 1.0, 0.12, rail_m)
	b.wall(Vector3(-17.2, 3, -7), Vector3(-14.25, 3, -7), 1.0, 0.12, rail_m)
	var step_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.55, 0.56))
	b.stairs(Vector3(-51, 0, -11.5), Vector3(-51, 3.0, -20), 3.0, step_m, rail_m)
	b.stairs(Vector3(-22, 0, -11.5), Vector3(-22, 3.0, -20), 3.0, step_m, rail_m)

	# Shops under the mezzanine.
	b.wall(Vector3(-58, 0, -24), Vector3(-22, 0, -24), 2.7, 0.3, inner, [
		Vector4(-57.4, -51.5, 1.1, 2.4), Vector4(-50.5, -48.5, 0, 2.4),
		Vector4(-45.4, -39.5, 1.1, 2.4), Vector4(-38.5, -36.5, 0, 2.4),
		Vector4(-33.4, -27.5, 1.1, 2.4), Vector4(-26.5, -24.5, 0, 2.4)])
	for x: float in [-46.0, -34.0, -22.0]:
		b.wall(Vector3(x, 0, -30), Vector3(x, 0, -24), 2.7, 0.3, inner)
	var shop_cols := [Color(0.2, 0.28, 0.4), Color(0.5, 0.2, 0.18), Color(0.2, 0.34, 0.3)]
	var shop_names := ["SNACKS", "BOOKS", "GIFTS"]
	for i in 3:
		var x0 := -58.0 + i * 12.0
		var sign_m := Craft.mat(Craft.Kind.FELT, shop_cols[i], Craft.Pattern.STITCH, Craft.CREAM)
		var sign := b.deco_box(Vector3(x0 + 6, 2.35, -23.8), Vector3(5.0, 0.6, 0.12), sign_m)
		sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_label(Vector3(x0 + 6, 2.35, -23.72), shop_names[i], 64, Craft.CREAM)
		for k in 3:
			var shelf := b.solid(Vector3(x0 + 2 + k * 3.2, 0.75, -28.8), Vector3(2.4, 1.5, 0.8), Craft.mat(Craft.Kind.CARDBOARD, shop_cols[i].darkened(0.25)))
			for j in 6:
				Craft.box(shelf, Vector3(-0.9 + j * 0.36, 0.84, 0.0), Vector3(0.26, 0.2 + rng.randf() * 0.2, 0.3), Craft.mat(Craft.Kind.PAPER, [Craft.YELLOW, Craft.RED, Craft.BLUE, Craft.GRASS][j % 4]))

	# Check-in counters with paper-lantern lighting above.
	for x: float in [-50.0, -41.0, -31.0, -22.0]:
		Props.counter(b, Vector3(x, 0, 3.5), 6.0, 0.0, Craft.WHITE, Color(0.4, 0.42, 0.45))
		b.solid(Vector3(x, 0.35, 5.6), Vector3(6.0, 0.7, 1.0), Craft.mat(Craft.Kind.CARDBOARD, Color(0.35, 0.35, 0.4), Craft.Pattern.BANDS, Color(0.5, 0.5, 0.55), 6.0))
	for pos in [Vector3(-44, 0, -8), Vector3(-32, 0, -8), Vector3(-44, 0, 12), Vector3(-32, 0, 12)]:
		Props.pillar(b, pos, 8.0, Craft.CONCRETE)
	# Round information desk.
	b.column(Vector3(-37.5, 0, -2), 1.6, 1.1, Craft.mat(Craft.Kind.CARDBOARD, Craft.BLUE, Craft.Pattern.BANDS, Craft.WHITE, 4.0, 1.0, false))
	_label(Vector3(-37.5, 2.6, -2), "INFO", 96, Craft.YELLOW, true)
	# Seating.
	var seat_cols := [Color(0.22, 0.24, 0.28), Craft.BLUE, Color(0.22, 0.24, 0.28), Craft.BLUE, Color(0.22, 0.24, 0.28)]
	var si := 0
	for x: float in [-52.0, -45.0, -38.0, -31.0, -24.0]:
		Props.gate_seats(b, Vector3(x, 0, 15.1), 0.0, 6, seat_cols[si])
		Props.gate_seats(b, Vector3(x, 0, 16.75), PI, 6, seat_cols[si])
		si += 1
	for z: float in [-14.0, -2.0]:
		Props.gate_seats(b, Vector3(-19.5, 0, z), PI * 0.5, 7, Craft.BLUE)
	Props.planter(b, Vector3(-55.5, 0, -18), rng)
	Props.planter(b, Vector3(-55.5, 0, 19.5), rng)
	Props.planter(b, Vector3(-16.5, 0, 19.5), rng)
	# Departure board.
	var board := b.deco_box(Vector3(-57.6, 5.2, -4), Vector3(0.15, 2.2, 7.0), Craft.mat(Craft.Kind.PAPER, Color(0.15, 0.17, 0.22)))
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_label(Vector3(-57.5, 5.9, -4), "DEPARTURES", 80, Craft.YELLOW, false, PI * 0.5)
	_label(Vector3(-57.5, 5.1, -4), "PC 101  ON TIME", 56, Craft.CREAM, false, PI * 0.5)
	_label(Vector3(-57.5, 4.5, -4), "PC 207  DELAYED", 56, Craft.ORANGE, false, PI * 0.5)
	# Hanging paper lanterns light the hall.
	var lantern := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.95, 0.86), 0, Color.WHITE, 1.0, 0.0, false)
	for x: float in [-50.0, -38.0, -26.0]:
		for z: float in [-14.0, 0.0, 14.0]:
			Craft.part(deco, Craft.sphere(0.45, 12), lantern, Vector3(x, 6.4, z), Vector3.ZERO, Vector3(1, 1.3, 1), false)
			Craft.part(deco, Craft.cylinder(0.01, 0.01, 1.6, 4), Craft.mat(Craft.Kind.PAPER, Craft.INK, 0, Color.WHITE, 1.0, 0.0, false), Vector3(x, 7.3, z))
			var l := OmniLight3D.new()
			l.position = Vector3(x, 6.0, z)
			l.light_color = Color(1.0, 0.93, 0.82)
			l.light_energy = 1.4
			l.omni_range = 13.0
			deco.add_child(l)


# ------------------------------------------------------------- jet bridge

func _jet_bridge() -> void:
	var shell := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.58, 0.64), Craft.Pattern.BANDS, Color(0.6, 0.63, 0.7), 2.0)
	var floor_m := Craft.mat(Craft.Kind.FELT, Color(0.3, 0.31, 0.34), Craft.Pattern.STITCH, Color(0.45, 0.47, 0.5))
	b.span(Vector3(-14.25, 2.7, -10.5), Vector3(0.5, 3.0, -7.5), floor_m)
	b.span(Vector3(-2.5, 2.7, -7.5), Vector3(0.5, 3.0, -5.0), floor_m)
	b.wall(Vector3(-14.25, 3, -10.5), Vector3(0.5, 3, -10.5), 2.7, 0.2, shell, [Vector4(-12, -3, 0.9, 2.1)])
	b.wall(Vector3(-14.25, 3, -7.5), Vector3(-2.5, 3, -7.5), 2.7, 0.2, shell, [Vector4(-12, -4, 0.9, 2.1)])
	b.wall(Vector3(0.5, 3, -10.5), Vector3(0.5, 3, -5.1), 2.7, 0.2, shell)
	b.wall(Vector3(-2.5, 3, -7.5), Vector3(-2.5, 3, -5.1), 2.7, 0.2, shell)
	b.span(Vector3(-14.25, 5.7, -10.7), Vector3(0.7, 5.9, -5.0), shell)
	var leg := Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.76, 0.8), 0, Color.WHITE, 1.0, 0.0, false)
	b.column(Vector3(-8, 0, -9), 0.3, 2.7, leg)
	b.column(Vector3(-1, 0, -8.8), 0.3, 2.7, leg)
	b.solid(Vector3(-1, 0.4, -8.8), Vector3(1.6, 0.8, 1.2), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW, Craft.Pattern.HAZARD, Craft.INK, 2.0))


# ---------------------------------------------------------------- airliner

func _airliner() -> void:
	var zc := -2.0
	var yc := 4.4
	var r := 3.2
	var skin := Craft.mat(Craft.Kind.PAPER, Color(0.88, 0.88, 0.86), Craft.Pattern.WALL, Color(0.8, 0.81, 0.82), 1.4, 0.0, false)
	var cabin := Craft.mat(Craft.Kind.PAPER, Color(0.82, 0.8, 0.76), 0, Color.WHITE, 1.0, 0.0, false)
	var livery := Craft.mat(Craft.Kind.PAPER, Craft.BLUE, 0, Color.WHITE, 1.0, 0.0, false)
	var livery2 := Craft.mat(Craft.Kind.PAPER, Craft.TEAL, 0, Color.WHITE, 1.0, 0.0, false)

	# Collision shell of the cabin.
	var floor_m := Craft.mat(Craft.Kind.FELT, Color(0.24, 0.27, 0.34), Craft.Pattern.STITCH, Color(0.45, 0.48, 0.55))
	b.span(Vector3(-4.6, 2.7, -4.85), Vector3(36, 3.0, 0.85), floor_m)
	b.wall(Vector3(-4.6, 3, -5.0), Vector3(36, 3, -5.0), 3.4, 0.3, null, [Vector4(-2.4, 0.4, 0, 2.4)])
	b.wall(Vector3(-4.6, 3, 1.0), Vector3(36, 3, 1.0), 3.4, 0.3, null, [Vector4(31.5, 33.5, 0, 2.4)])
	b.span(Vector3(-4.6, 6.3, -5.1), Vector3(36, 6.5, 1.1), null)
	b.span(Vector3(-4.9, 3.0, -5.0), Vector3(-4.6, 6.3, 1.0), Craft.mat(Craft.Kind.CARDBOARD, Craft.CREAM))
	b.span(Vector3(36, 3.0, -5.0), Vector3(36.3, 6.3, 1.0), Craft.mat(Craft.Kind.CARDBOARD, Craft.CREAM))
	b.span(Vector3(-5, 1.25, -4.4), Vector3(37, 2.7, 0.4), null)
	b.span(Vector3(-9.5, 2.0, -4.4), Vector3(-5, 6.8, 0.4), null)
	b.span(Vector3(37, 2.4, -4.2), Vector3(44, 7.0, 0.2), null)
	# A blocker over the top so nobody stands on the fuselage.
	b.blocker(Vector3(16, 9.5, zc), Vector3(56, 5, 10))

	# Paper-towel-roll fuselage, split around the two doors.
	var sections := [[-5.0, -2.4, 0], [-2.4, 0.4, 1], [0.4, 31.5, 0], [31.5, 33.5, 2], [33.5, 37.0, 0]]
	for s in sections:
		var x0: float = s[0]
		var x1: float = s[1]
		var gap: int = s[2]
		var arc := TAU if gap == 0 else TAU - 1.15
		var flip := Vector3(PI, 0, 0) if gap == 1 else Vector3.ZERO
		var cx := (x0 + x1) * 0.5
		Craft.part(deco, Craft.tube(r, x1 - x0, 32, false, arc), skin, Vector3(cx, yc, zc), flip)
		Craft.part(deco, Craft.tube(r - 0.22, x1 - x0, 32, true, arc), cabin, Vector3(cx, yc, zc), flip, Vector3.ONE, false)
	# Livery stripes and windows.
	for side: float in [-1.0, 1.0]:
		var z := zc + side * (r + 0.01)
		for seg in [[-4.6, -2.6], [0.6, 31.3], [33.7, 36.8]]:
			var len: float = seg[1] - seg[0]
			Craft.box(deco, Vector3((seg[0] + seg[1]) * 0.5, yc - 0.55, z), Vector3(len, 0.35, 0.03), livery)
			Craft.box(deco, Vector3((seg[0] + seg[1]) * 0.5, yc - 0.95, z), Vector3(len, 0.12, 0.03), livery2)
		var win := Craft.mat(Craft.Kind.PAPER, Color(0.2, 0.3, 0.45), 0, Color.WHITE, 1.0, 0.0, false)
		var x := 2.0
		while x < 31.0:
			Craft.part(deco, Craft.cylinder(0.2, 0.2, 0.04, 12), win, Vector3(x, yc + 0.35, zc + side * (r + 0.005)), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 1.3), false)
			x += 1.1
	_label(Vector3(14, yc + 1.4, zc - r - 0.05), "PAPERCUT AIR", 220, Craft.BLUE, false, PI)
	_label(Vector3(14, yc + 1.4, zc + r + 0.05), "PAPERCUT AIR", 220, Craft.BLUE)

	# Nose and cockpit.
	Craft.part(deco, Craft.sphere(r, 28), skin, Vector3(-5.0, yc, zc), Vector3.ZERO, Vector3(1.55, 1.0, 1.0))
	var cockpit := Craft.mat(Craft.Kind.PAPER, Color(0.18, 0.24, 0.35), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.box(deco, Vector3(-8.6, yc + 0.9, zc), Vector3(0.9, 0.55, 3.2), cockpit, Vector3(0, 0, -0.6))
	# Tail cone, fin and stabilisers.
	Craft.part(deco, Craft.cylinder(r, 0.7, 7.5, 28), skin, Vector3(40.7, yc + 0.6, zc), Vector3(0, 0, -PI * 0.5 + 0.1))
	var fin_pts := PackedVector2Array([Vector2(0, 0), Vector2(6.5, 0), Vector2(8.2, 7.0), Vector2(5.4, 7.2)])
	Craft.part(deco, Craft.cutout(fin_pts, 0.35), Craft.mat(Craft.Kind.CARDBOARD, Craft.BLUE, 0, Color.WHITE, 1.0, 0.0, false), Vector3(36.5, yc + 2.4, zc))
	var star := Craft.part(deco, Craft.cutout(Craft.star_points(1.2, 0.5), 0.4), Craft.mat(Craft.Kind.FELT, Craft.TEAL, 0, Color.WHITE, 1.0, 0.0, false), Vector3(42.3, yc + 6.0, zc))
	star.scale = Vector3(1, 1, 1.1)
	for side: float in [-1.0, 1.0]:
		var stab := PackedVector2Array([Vector2(0, 0), Vector2(4.0, 0), Vector2(5.0, 5.5), Vector2(3.4, 5.6)])
		Craft.part(deco, Craft.cutout(stab, 0.25), skin, Vector3(38.5, yc + 1.4, zc + side * 0.8), Vector3(side * PI * 0.5, 0, 0))

	# Wings with engines (you can walk underneath).
	var wing_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.76, 0.77, 0.78), Craft.Pattern.STITCH, Color(0.6, 0.62, 0.64))
	for side: float in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(11, 2.4), Vector2(21, 2.4), Vector2(26, 19), Vector2(22.5, 19.5)])
		_slab_polygon(pts, side, zc, 2.65, 0.35, wing_m)
		var ez := zc + side * 8.5
		var eng := Craft.mat(Craft.Kind.FOIL, Color(0.82, 0.84, 0.88), 0, Color.WHITE, 1.0, 1.0, false)
		var body := b.solid(Vector3(16.5, 1.7, ez), Vector3(5.0, 2.0, 2.0), null)
		Craft.part(body, Craft.cylinder(1.0, 1.0, 5.0, 24), eng, Vector3.ZERO, Vector3(0, 0, PI * 0.5))
		Craft.part(body, Craft.cylinder(0.75, 0.75, 0.1, 20), Craft.mat(Craft.Kind.PAPER, Color(0.12, 0.12, 0.14), 0, Color.WHITE, 1.0, 0.0, false), Vector3(-2.52, 0, 0), Vector3(0, 0, PI * 0.5))
		Craft.part(body, Craft.cylinder(0.3, 0.3, 0.12, 10), Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.71, 0.73), 0, Color.WHITE, 1.0, 0.0, false), Vector3(-2.56, 0, 0), Vector3(0, 0, PI * 0.5))
		Craft.box(deco, Vector3(17, 2.55, ez), Vector3(3.0, 0.5, 0.3), wing_m)
	# Landing gear.
	var tyre := Craft.mat(Craft.Kind.PLASTIC, Color(0.12, 0.12, 0.13), 0, Color.WHITE, 1.0, 0.0, false)
	for g in [Vector3(-3, 0, zc), Vector3(17, 0, zc - 2.2), Vector3(17, 0, zc + 2.2)]:
		b.column(g + Vector3(0, 0, 0), 0.18, 1.4, Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.7, 0.72), 0, Color.WHITE, 1.0, 0.0, false))
		Craft.part(deco, Craft.cylinder(0.55, 0.55, 0.45, 16), tyre, g + Vector3(0, 0.55, 0), Vector3(PI * 0.5, 0, 0))

	# Cabin: rows of felt seats either side of the aisle, a galley mid-way.
	var seat_m := Craft.mat(Craft.Kind.FELT, Craft.BLUE, Craft.Pattern.STITCH, Craft.BLUE.darkened(0.4))
	var head_m := Craft.mat(Craft.Kind.FELT, Craft.CREAM)
	var x := 2.0
	while x < 30.5:
		if x > 14.5 and x < 17.5:
			x += 1.1
			continue
		for block in [[-4.7, -3.0], [-1.0, 0.7]]:
			var z0: float = block[0]
			var z1: float = block[1]
			var seat := b.solid(Vector3(x, 3.25, (z0 + z1) * 0.5), Vector3(0.55, 0.5, z1 - z0), seat_m)
			Craft.box(seat, Vector3(0.3, 0.45, 0), Vector3(0.14, 1.0, z1 - z0), seat_m)
			Craft.box(seat, Vector3(0.3, 0.92, 0), Vector3(0.16, 0.16, z1 - z0 - 0.1), head_m)
		x += 1.1
	b.solid(Vector3(16, 3.55, -4.3), Vector3(2.4, 1.1, 0.9), Craft.mat(Craft.Kind.FOIL, Color(0.8, 0.82, 0.85)))
	b.solid(Vector3(16, 3.55, 0.3), Vector3(2.4, 1.1, 0.9), Craft.mat(Craft.Kind.FOIL, Color(0.8, 0.82, 0.85)))
	# Overhead bins and cabin lights.
	var bins := Craft.mat(Craft.Kind.CARDBOARD, Craft.CREAM)
	Craft.box(deco, Vector3(16, 5.85, -4.45), Vector3(40, 0.6, 0.8), bins)
	Craft.box(deco, Vector3(16, 5.85, 0.45), Vector3(40, 0.6, 0.8), bins)
	for lx: float in [3.0, 13.0, 23.0, 32.0]:
		var l := OmniLight3D.new()
		l.position = Vector3(lx, 5.8, zc)
		l.light_color = Color(1.0, 0.9, 0.75)
		l.light_energy = 1.1
		l.omni_range = 8.0
		deco.add_child(l)

	# Rear stair truck down to the tarmac.
	b.stairs(Vector3(32.5, 0, 9.5), Vector3(32.5, 3.0, 1.3), 1.8, Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW), Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.75, 0.78)))
	b.span(Vector3(31.5, 2.7, 1.0), Vector3(33.5, 3.0, 1.6), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW))
	Props.truck(b, Vector3(32.5, 0, 13.6), PI, Craft.YELLOW)


func _slab_polygon(pts: PackedVector2Array, side: float, zc: float, y: float, thick: float, material: Material) -> void:
	# A flat polygon in the XZ plane (pts are (x, distance from centreline)).
	var poly3 := PackedVector3Array()
	var poly2 := PackedVector2Array()
	for p in pts:
		poly2.append(Vector2(p.x, zc + side * p.y))
	if Geometry2D.is_polygon_clockwise(poly2):
		poly2.reverse()
	for p in poly2:
		poly3.append(Vector3(p.x, y, p.y))
		poly3.append(Vector3(p.x, y + thick, p.y))
	var body := StaticBody3D.new()
	body.collision_layer = MapBuilder.WORLD_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cps := ConvexPolygonShape3D.new()
	cps.points = poly3
	shape.shape = cps
	body.add_child(shape)
	nav_region.add_child(body)
	# Visual: the cut-out shape laid flat.
	var mesh := Craft.cutout(poly2, thick)
	var mi := Craft.part(deco, mesh, material, Vector3(0, y + thick * 0.5, 0), Vector3(PI * 0.5, 0, 0))
	mi.scale = Vector3(1, 1, 1)


# ----------------------------------------------------------- baggage hall

## A thin sheet of roofing felt laid over a roof span (visual only).
func _roof_sheet(a: Vector3, c: Vector3, material: Material) -> void:
	var sheet := Craft.box(deco, Vector3((a.x + c.x) * 0.5, a.y + 0.012, (a.z + c.z) * 0.5), Vector3(absf(c.x - a.x) - 0.06, 0.02, absf(c.z - a.z) - 0.06), material)
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _baggage_hall() -> void:
	var wall_m := Craft.mat(Craft.Kind.CARDBOARD, Craft.SLATE, Craft.Pattern.WALL, Craft.CONCRETE_DARK, 1.0)
	var inner_m := Craft.mat(Craft.Kind.CARDBOARD, Color(0.66, 0.68, 0.7))
	b.wall(Vector3(-14, 0, -38), Vector3(32, 0, -38), 5.0, 0.4, wall_m)
	b.wall(Vector3(-14, 0, -26), Vector3(32, 0, -26), 5.0, 0.4, wall_m, [
		Vector4(-6, -2, 0, 3.2), Vector4(8, 12, 0, 3.2), Vector4(22, 26, 0, 3.2), Vector4(1, 6, 1.2, 2.6), Vector4(15, 20, 1.2, 2.6)])
	b.wall(Vector3(-14, 0, -38), Vector3(-14, 0, -30), 5.0, 0.4, wall_m)
	b.wall(Vector3(32, 0, -38), Vector3(32, 0, -26), 5.0, 0.4, wall_m, [Vector4(-34.5, -28.5, 0, 3.6)])
	b.span(Vector3(-14.2, 5.0, -38.2), Vector3(32.2, 5.3, -25.8), Craft.mat(Craft.Kind.CARDBOARD, Craft.KRAFT))
	_roof_sheet(Vector3(-14.2, 5.3, -38.2), Vector3(32.2, 5.3, -25.8), Craft.mat(Craft.Kind.FELT, Color(0.34, 0.35, 0.37), Craft.Pattern.STITCH, Color(0.42, 0.43, 0.45), 2.0))
	b.blocker(Vector3(9, 6.5, -32), Vector3(48, 2, 14))
	# Rolled-up corrugated doors above each opening.
	var roll := Craft.mat(Craft.Kind.CARDBOARD, Color(0.75, 0.75, 0.8), 0, Color.WHITE, 1.0, 0.0, false)
	for x: float in [-4.0, 10.0, 24.0]:
		Craft.part(deco, Craft.cylinder(0.35, 0.35, 4.2, 16), roll, Vector3(x, 3.6, -25.6), Vector3(0, 0, PI * 0.5))
		Craft.box(deco, Vector3(x, 3.4, -25.75), Vector3(4.2, 0.12, 0.05), Craft.mat(Craft.Kind.CARDBOARD, Craft.YELLOW, Craft.Pattern.HAZARD, Craft.INK, 2.0))
	# Conveyor belts with luggage riding on them.
	var belt := Craft.mat(Craft.Kind.CARDBOARD, Color(0.25, 0.26, 0.3), Craft.Pattern.BANDS, Color(0.35, 0.36, 0.4), 3.0)
	var rail := Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.76, 0.8))
	for seg in [[-10.0, 3.0], [8.0, 21.0]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		var body := b.solid(Vector3((x0 + x1) * 0.5, 0.4, -32.5), Vector3(x1 - x0, 0.8, 1.6), belt)
		Craft.box(body, Vector3(0, 0.45, 0.78), Vector3(x1 - x0, 0.12, 0.08), rail)
		Craft.box(body, Vector3(0, 0.45, -0.78), Vector3(x1 - x0, 0.12, 0.08), rail)
		var lx := x0 + 0.8
		while lx < x1 - 0.6:
			Props.luggage(b, Vector3(lx, 0.8, -32.5 + rng.randf_range(-0.3, 0.3)), rng, false)
			lx += rng.randf_range(1.2, 2.2)
	Props.baggage_cart(b, Vector3(27, 0, -30.5), 0.1, rng)
	Props.baggage_cart(b, Vector3(-9, 0, -29), -0.2, rng)
	for p in [Vector3(4.5, 0, -36.6), Vector3(5.7, 0, -36.6), Vector3(26, 0, -36.6)]:
		Props.crate(b, p, 1.1, rng.randf() * 0.3)
	Props.crate(b, Vector3(5.1, 1.1, -36.6), 0.9, 0.2)
	for x: float in [-1.0, 13.0]:
		Props.pillar(b, Vector3(x, 0, -29.6), 5.0, Color(0.6, 0.62, 0.64))
	for x: float in [-6.0, 7.0, 20.0]:
		var l := OmniLight3D.new()
		l.position = Vector3(x, 4.4, -32)
		l.light_color = Color(0.95, 0.96, 0.95)
		l.light_energy = 1.3
		l.omni_range = 11.0
		deco.add_child(l)
		Craft.part(deco, Craft.cylinder(0.5, 0.7, 0.3, 14), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.92, 0.75), 0, Color.WHITE, 1.0, 0.0, false), Vector3(x, 4.75, -32), Vector3.ZERO, Vector3.ONE, false)
	_label(Vector3(9, 4.2, -25.6), "BAGGAGE", 160, Craft.CREAM, false, 0.0)
	var _unused := inner_m


# ----------------------------------------------------------------- tarmac

func _tarmac() -> void:
	Props.container(b, Vector3(5, 0, -18.5), 0.1, Color(0.3, 0.4, 0.42))
	Props.container(b, Vector3(7.3, 0, -18.3), -0.05, Craft.ALUMINIUM)
	Props.container(b, Vector3(6.2, 0, -15.8), 0.2, Craft.ALUMINIUM)
	Props.container(b, Vector3(40, 0, -18), 0.0, Color(0.56, 0.3, 0.2))
	Props.container(b, Vector3(42.3, 0, -18.2), 0.08, Craft.ALUMINIUM)
	Props.container(b, Vector3(43, 0, -14.8), -0.3, Craft.BLUE)
	Props.container(b, Vector3(46, 0, 7), 0.15, Craft.ALUMINIUM)
	Props.container(b, Vector3(48.4, 0, 7.4), 0.0, Color(0.3, 0.4, 0.42))
	Props.container(b, Vector3(22, 0, 9), 0.4, Craft.ALUMINIUM)
	Props.baggage_cart(b, Vector3(2, 0, 9.5), 0.2, rng)
	Props.baggage_cart(b, Vector3(5.2, 0, 10.4), 0.25, rng)
	Props.baggage_cart(b, Vector3(25, 0, -14), 1.4, rng)
	Props.baggage_cart(b, Vector3(12, 0, -22), 0.0, rng)
	Props.truck(b, Vector3(44.5, 0, -4), 0.0, Craft.WHITE, true)
	Props.truck(b, Vector3(-6, 0, 13), PI * 0.5, Craft.RED)
	for z: float in [-20.0, -16.5, 11.0, 14.5, 18.0]:
		Props.barrier(b, Vector3(51.5, 0, z), PI * 0.5, 3.0)
	for x: float in [26.0, 29.5]:
		Props.barrier(b, Vector3(x, 0, 18.5), 0.0, 3.0)
	Props.barrier(b, Vector3(-8, 0, -21.5), 0.3, 3.0)
	var c1 := Props.crate(b, Vector3(55, 0, -7), 1.4, 0.1)
	Props.crate(b, Vector3(55.2, 1.4, -7), 1.0, 0.4)
	Props.crate(b, Vector3(54.2, 0, 2.5), 1.2, -0.2, Craft.KRAFT)
	Props.crate(b, Vector3(36, 0, 18), 1.3, 0.3, Craft.OLIVE)
	Props.crate(b, Vector3(14, 0, -9.5), 1.2, 0.2)
	Props.crate(b, Vector3(-9, 0, -16), 1.2, -0.3, Craft.KRAFT_DARK)
	for p in [Vector3(0, 0, -12), Vector3(1.5, 0, -12.5), Vector3(28, 0, -9), Vector3(38, 0, 4), Vector3(9, 0, 15), Vector3(50, 0, -2)]:
		Props.cone(b, p)
	for p: Vector3 in [Vector3(0, 0, -24), Vector3(56, 0, -34), Vector3(56, 0, 23), Vector3(14, 0, 23)]:
		Props.light_mast(b, p, 9.0, atan2(p.x - 20.0, p.z + 2.0))
	var _unused := c1


# ------------------------------------------------------------------ apron

func _apron() -> void:
	# A little cardboard business jet out on the apron: long sightlines.
	var skin := Craft.mat(Craft.Kind.PAPER, Craft.WHITE, 0, Color.WHITE, 1.0, 0.0, false)
	var y := 1.7
	var jet := b.solid(Vector3(18, y, 20.5), Vector3(10, 2.2, 2.2), null)
	Craft.part(jet, Craft.tube(1.15, 9.0, 24), skin, Vector3.ZERO)
	Craft.part(jet, Craft.sphere(1.15, 20), skin, Vector3(-4.5, 0, 0), Vector3.ZERO, Vector3(1.6, 1, 1))
	Craft.part(jet, Craft.cylinder(1.15, 0.3, 3.0, 20), skin, Vector3(6.0, 0.3, 0), Vector3(0, 0, -PI * 0.5 + 0.12))
	Craft.box(jet, Vector3(0.5, -0.6, 0), Vector3(2.6, 0.2, 9.0), Craft.mat(Craft.Kind.CARDBOARD, Color(0.78, 0.78, 0.78)))
	Craft.box(jet, Vector3(-5.1, 0.35, 0), Vector3(0.6, 0.4, 1.6), Craft.mat(Craft.Kind.PAPER, Color(0.2, 0.25, 0.35)), Vector3(0, 0, -0.5))
	var fin := Craft.cutout(PackedVector2Array([Vector2(0, 0), Vector2(2.2, 0), Vector2(3.0, 2.6), Vector2(2.0, 2.7)]), 0.15)
	Craft.part(jet, fin, Craft.mat(Craft.Kind.CARDBOARD, Color(0.42, 0.14, 0.16), 0, Color.WHITE, 1.0, 0.0, false), Vector3(4.6, 0.9, 0))
	for x: float in [14.0, 21.0]:
		b.column(Vector3(x, 0, 20.5), 0.12, 0.6, Craft.mat(Craft.Kind.FOIL, Color(0.7, 0.7, 0.72), 0, Color.WHITE, 1.0, 0.0, false))
	Props.luggage(b, Vector3(10, 0, 21), rng)
	Props.luggage(b, Vector3(10.6, 0, 21.4), rng)
	Props.crate(b, Vector3(-4, 0, 21), 1.3, 0.2, Color(0.56, 0.46, 0.32))
	Props.crate(b, Vector3(42, 0, 22), 1.4, -0.1)
	Props.container(b, Vector3(2, 0, 22.5), 0.0, Craft.ALUMINIUM)
	# Sidewalk outside the terminal.
	Props.planter(b, Vector3(-50, 0, 24.2), rng)
	Props.planter(b, Vector3(-28, 0, 24.2), rng)
	Props.bench(b, Vector3(-44, 0, 24.6), 0.0)
	Props.bench(b, Vector3(-21, 0, 24.6), 0.0)


# ------------------------------------------------------------------ edges

func _bounds() -> void:
	var post_m := Craft.mat(Craft.Kind.CARDBOARD, Craft.KRAFT_DARK, 0, Color.WHITE, 1.0, 0.0, false)
	var yarn := Craft.mat(Craft.Kind.KNIT, Color(0.85, 0.85, 0.88), 0, Color.WHITE, 0.4, 0.0, false)
	var lines := [
		[Vector3(32, 0, -38), Vector3(60, 0, -38)],
		[Vector3(60, 0, -38), Vector3(60, 0, 26)],
		[Vector3(60, 0, 26), Vector3(-58, 0, 26)],
		[Vector3(-58, 0, 26), Vector3(-58, 0, 22)],
	]
	for l in lines:
		var a: Vector3 = l[0]
		var c: Vector3 = l[1]
		var mid := (a + c) * 0.5
		var len := a.distance_to(c)
		var along_x := absf(c.x - a.x) > absf(c.z - a.z)
		b.blocker(mid + Vector3(0, 6, 0), Vector3(len + 0.6, 14, 0.6) if along_x else Vector3(0.6, 14, len + 0.6))
		var n := int(len / 3.0)
		for i in n + 1:
			var p := a.lerp(c, float(i) / n)
			Craft.part(deco, Craft.cylinder(0.08, 0.08, 2.6, 8), post_m, p + Vector3(0, 1.3, 0))
		var fence := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(len, 2.4)
		fence.mesh = qm
		fence.material_override = Architecture.chain_link()
		fence.position = mid + Vector3(0, 1.25, 0)
		fence.rotation.y = 0.0 if along_x else PI * 0.5
		deco.add_child(fence)
		var top_rail := Craft.box(deco, mid + Vector3(0, 2.5, 0), Vector3(len, 0.06, 0.06) if along_x else Vector3(0.06, 0.06, len), yarn)
		top_rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _backdrop() -> void:
	var far := Node3D.new()
	far.name = "Backdrop"
	deco.add_child(far)
	# Runway beyond the south fence.
	Craft.box(far, Vector3(0, 0.01, 50), Vector3(260, 0.04, 22), Craft.mat(Craft.Kind.FELT, Color(0.3, 0.31, 0.34), 0, Color.WHITE, 1.0, 0.0))
	for i in 20:
		Craft.box(far, Vector3(-120 + i * 13.0, 0.03, 50), Vector3(6, 0.02, 0.8), Craft.mat(Craft.Kind.PAPER, Craft.WHITE))
	Craft.box(far, Vector3(0, -0.1, 0), Vector3(800, 0.1, 800), Craft.mat(Craft.Kind.FELT, Color(0.34, 0.41, 0.25), 0, Color.WHITE, 1.0, 0.0, false), Vector3.ZERO, false)
	# Cardboard city flats, painted like real concrete, brick and glass towers.
	var cols := [Color(0.62, 0.6, 0.56), Color(0.5, 0.52, 0.54), Color(0.7, 0.66, 0.58), Color(0.38, 0.44, 0.5), Color(0.56, 0.47, 0.4), Color(0.44, 0.5, 0.56), Color(0.66, 0.66, 0.64)]
	for i in 40:
		var a := TAU * i / 40.0 + rng.randf_range(-0.05, 0.05)
		var d := rng.randf_range(115.0, 165.0)
		var h := rng.randf_range(14.0, 48.0)
		var w := rng.randf_range(10.0, 22.0)
		var col: Color = cols[rng.randi() % cols.size()]
		var p := Vector3(cos(a) * d, h * 0.5, sin(a) * d)
		var m := Craft.mat(Craft.Kind.CARDBOARD, col, Craft.Pattern.WINDOWS, Color(0.3, 0.36, 0.42), 0.35)
		var flat := Craft.box(far, p, Vector3(w, h, 1.5), m, Vector3(0, -a + PI * 0.5, 0))
		flat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Control tower.
	var tower := Craft.mat(Craft.Kind.CARDBOARD, Craft.CONCRETE, Craft.Pattern.BANDS, Craft.CONCRETE_DARK, 0.2, 1.0, false)
	Craft.part(far, Craft.cylinder(2.2, 3.0, 34, 20), tower, Vector3(84, 17, -62))
	Craft.part(far, Craft.cylinder(5.0, 3.6, 4.5, 20), Craft.mat(Craft.Kind.PAPER, Color(0.24, 0.3, 0.36), 0, Color.WHITE, 1.0, 0.0, false), Vector3(84, 36, -62))
	Craft.part(far, Craft.cylinder(5.4, 5.4, 0.8, 20), Craft.mat(Craft.Kind.CARDBOARD, Craft.CONCRETE_DARK, 0, Color.WHITE, 1.0, 0.0, false), Vector3(84, 38.6, -62))
	# Felt hills and paper trees.
	for i in 16:
		var a := TAU * i / 16.0 + 0.2
		var d := rng.randf_range(190.0, 260.0)
		var hill := Craft.part(far, Craft.sphere(1.0, 24), Craft.mat(Craft.Kind.KNIT, [Color(0.34, 0.41, 0.26), Color(0.3, 0.37, 0.27), Color(0.4, 0.44, 0.3)][i % 3], 0, Color.WHITE, 0.05, 0.0, false), Vector3(cos(a) * d, -4, sin(a) * d))
		hill.scale = Vector3(rng.randf_range(40, 70), rng.randf_range(22, 40), rng.randf_range(30, 50))
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 26:
		var a := rng.randf() * TAU
		var d := rng.randf_range(78.0, 105.0)
		Props.paper_tree(far, Vector3(cos(a) * d, 0, sin(a) * d), rng.randf_range(1.6, 2.6), rng)
	# Teased cotton-wadding clouds on near-invisible fishing line.
	var cloud_m := Craft.mat(Craft.Kind.FELT, Color(0.93, 0.93, 0.92), 0, Color.WHITE, 4.0, 0.0, false)
	var string_m := Craft.mat(Craft.Kind.PLASTIC, Color(0.62, 0.7, 0.78), 0, Color.WHITE, 1.0, 0.0, false)
	for i in 14:
		var a := rng.randf() * TAU
		var d := rng.randf_range(110.0, 220.0)
		var y := rng.randf_range(45.0, 85.0)
		var w := rng.randf_range(20.0, 38.0)
		var p := Vector3(cos(a) * d, y, sin(a) * d)
		var cl := Craft.part(far, Craft.cutout(Craft.cloud_points(w, w * 0.45, 5, i + 3), 2.0), cloud_m, p, Vector3(0, -a + PI * 0.5, 0))
		cl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Craft.part(far, Craft.cylinder(0.025, 0.025, 120, 4), string_m, p + Vector3(0, w * 0.2 + 60, 0), Vector3.ZERO, Vector3.ONE, false)


# --------------------------------------------------------------- dressing

func _dressing() -> void:
	var d := Node3D.new()
	d.name = "Dressing"
	deco.add_child(d)
	# Hanging wayfinding signs: real airport convention, dark panels with
	# yellow or white lettering.
	Dressing.hanging_sign(d, Vector3(-16.0, 6.4, -9.0), -PI * 0.5, "GATE 7", Color(0.2, 0.22, 0.25), 2.6)
	Dressing.hanging_sign(d, Vector3(-36.0, 5.6, 3.5), 0.0, "CHECK-IN", Color(0.2, 0.22, 0.25), 4.0)
	Dressing.hanging_sign(d, Vector3(-50.0, 5.4, 12.0), PI * 0.5, "DEPARTURES", Color(0.2, 0.22, 0.25), 4.4)
	# Printed notices and adverts, the kind any real terminal has.
	var titles := ["FLY PAPERCUT AIR", "NO SMOKING", "PASSPORT CONTROL", "VISIT THE COAST", "LOST PROPERTY", "SECURITY NOTICE", "DUTY FREE", "BAGGAGE CLAIM"]
	var t := 0
	for z: float in [-15.0, 5.0, 16.0]:
		Dressing.poster(d, Vector3(-57.72, 1.9, z), PI * 0.5, Vector2(1.1, 1.5), rng, titles[t % titles.size()])
		t += 1
	for x: float in [-50.0, -38.0, -27.0, -20.0]:
		Dressing.poster(d, Vector3(x, 1.8, 21.72), PI, Vector2(1.0, 1.4), rng, titles[t % titles.size()])
		t += 1
	for x: float in [-9.0, 6.0, 16.0, 28.0]:
		Dressing.poster(d, Vector3(x, 2.0, -37.77), 0.0, Vector2(1.2, 1.6), rng, titles[t % titles.size()])
		t += 1
	for z: float in [-23.0, -15.0, 18.0]:
		Dressing.poster(d, Vector3(-13.72, 3.4, z), PI * 0.5, Vector2(1.6, 2.1), rng, titles[t % titles.size()])
		t += 1



# ----------------------------------------------------------------- revamp

func _revamp() -> void:
	var r := Node3D.new()
	r.name = "Revamp"
	deco.add_child(r)
	var frame_c := Color(0.82, 0.83, 0.84)
	# Window mullions everywhere there's glass.
	for w in [[Vector3(-14, 1, -24), Vector3(-14, 2.6, -12)], [Vector3(-14, 1, -1), Vector3(-14, 2.6, 9)], [Vector3(-14, 1, 15), Vector3(-14, 2.6, 21)],
			[Vector3(-14, 4.5, -1), Vector3(-14, 7.2, 20)], [Vector3(-55, 1, 22), Vector3(-44, 2.6, 22)], [Vector3(-32, 1, 22), Vector3(-18, 2.6, 22)],
			[Vector3(-54, 4.5, 22), Vector3(-18, 7.0, 22)]]:
		Architecture.window_frame(r, w[0], w[1], 1.6, frame_c)
	for w in [[Vector3(1, 1.2, -26), Vector3(6, 2.6, -26)], [Vector3(15, 1.2, -26), Vector3(20, 2.6, -26)]]:
		Architecture.window_frame(r, w[0], w[1], 1.25, Color(0.5, 0.52, 0.55), false)
	for w in [[Vector3(-12, 3.9, -10.5), Vector3(-3, 5.1, -10.5)], [Vector3(-12, 3.9, -7.5), Vector3(-4, 5.1, -7.5)]]:
		Architecture.window_frame(r, w[0], w[1], 1.0, Color(0.7, 0.72, 0.78), false)
	# Ceiling structure: long beams and cross beams under the roof.
	for x: float in [-54.0, -42.0, -30.0, -18.0]:
		Architecture.beam(r, Vector3(x, 7.7, -29.7), Vector3(x, 7.7, 21.7), 0.42, 0.55, Craft.KRAFT_DARK)
	for z: float in [-18.0, -4.0, 10.0]:
		Architecture.beam(r, Vector3(-57.7, 7.35, z), Vector3(-14.3, 7.35, z), 0.3, 0.4, Craft.KRAFT)
	for p: Vector3 in [Vector3(-44, 0, -8), Vector3(-32, 0, -8), Vector3(-44, 0, 12), Vector3(-32, 0, 12)]:
		Architecture.column_trim(r, p, 8.0, 0.9, Craft.CREAM)
	# Gate furniture, screens, queue ropes, vending, bins, trees, rugs.
	Props.info_screen(r, Vector3(-40, 0, -14), 0.0, ["DEPARTURES", "PC 101  ORIGAMI CITY", "PC 207  FELT FALLS", "PC 330  YARN HARBOR"])
	Props.info_screen(r, Vector3(-27, 0, 11.5), PI, ["GATE 7", "BOARDING", "PC 101 ORIGAMI CITY"])
	Props.info_screen(r, Vector3(-47.5, 0, 9.5), PI * 0.5, ["ARRIVALS", "PC 118  CRAYON COVE", "PC 220  GLUE GULCH"])
	var q1 := []
	var q2 := []
	var x := -53.0
	while x < -18.5:
		q1.append(Vector3(x, 0, 1.2))
		q2.append(Vector3(x, 0, -0.6))
		x += 2.6
	Props.stanchions(r, q1)
	Props.stanchions(r, q2)
	for z: float in [-10.5, -9.3, 13.6]:
		Props.vending(b, Vector3(-57.1, 0, z), -PI * 0.5, [Craft.RED, Craft.BLUE, Craft.PURPLE][int(absf(z)) % 3], rng)
	for p: Vector3 in [Vector3(-43, 0, -9.2), Vector3(-31, 0, 13.2), Vector3(-20.6, 0, -6.5), Vector3(-55, 0, 1.0), Vector3(-17, 0, 6.5)]:
		Props.trash_bin(b, p, Color(0.3, 0.32, 0.34))
	for p: Vector3 in [Vector3(-38, 0, 8.5), Vector3(-26, 0, -8.5), Vector3(-49.5, 0, -7.5)]:
		Props.potted_tree(b, p, rng)
	Props.rug(r, Vector3(-36, 0, -6.5), Vector2(40, 2.6), Color(0.3, 0.33, 0.4))
	Props.rug(r, Vector3(-38, 0, 15.9), Vector2(33, 5.6), Color(0.28, 0.33, 0.37))
	Props.rug(r, Vector3(-36, 0, 1.0 - 0.3), Vector2(36, 2.6), Color(0.33, 0.21, 0.21))
	# Terminal exterior: parapet, rooftop plant, big cardboard lettering.
	Architecture.parapet(r, Vector3(-58.2, 8.4, -30.2), Vector3(-13.8, 8.4, 22.2), 0.7, Craft.CONCRETE, Craft.CONCRETE_DARK)
	Architecture.rooftop(r, Vector3(-36, 8.4, -4), rng, 6, Vector2(16, 18))
	Architecture.letters(r, "GATEWAY", Vector3(-13.6, 9.3, -4.0), PI * 0.5, 3.4, Craft.WHITE)
	Architecture.letters(r, "TERMINAL 1", Vector3(-38, 3.55, 22.35), 0.0, 0.85, Craft.CREAM, 0.12)
	Props.awning(r, Vector3(-38, 3.3, 22.3), 0.0, 6.0, Color(0.3, 0.33, 0.38))
	# Baggage hall roof.
	Architecture.parapet(r, Vector3(-14.2, 5.3, -38.2), Vector3(32.2, 5.3, -25.8), 0.5, Craft.SLATE, Craft.CONCRETE_DARK)
	Architecture.rooftop(r, Vector3(9, 5.3, -32), rng, 4, Vector2(18, 3))
	# Tarmac: stand markings and ground support equipment.
	var stand := Architecture.letters(r, "07", Vector3(-8.5, 0.045, 6.0), 0.0, 2.6, Craft.WHITE, 0.02)
	stand.rotation = Vector3(-PI * 0.5, PI * 0.5, 0)
	Craft.box(r, Vector3(-7, 0.045, -9.0), Vector3(10.0, 0.012, 2.8), Craft.mat(Craft.Kind.FELT, Craft.YELLOW, Craft.Pattern.HAZARD, Color(0.3, 0.32, 0.36), 0.6), Vector3.ZERO, false)
	for i in 6:
		var arrow := Craft.cutout(PackedVector2Array([Vector2(-0.3, -0.8), Vector2(0.3, -0.8), Vector2(0.3, 0.2), Vector2(0.7, 0.2), Vector2(0, 1.0), Vector2(-0.7, 0.2), Vector2(-0.3, 0.2)]), 0.02)
		Craft.part(r, arrow, Craft.mat(Craft.Kind.PAPER, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false), Vector3(-2 + i * 9.0, 0.045, 20.0), Vector3(-PI * 0.5, -PI * 0.5, 0))
	Props.gpu_cart(b, Vector3(-6.8, 0, 1.8), 0.25)
	Props.belt_loader(b, Vector3(3.2, 0, 4.6), PI, 2.0)
	Props.tug(b, Vector3(9, 0, 7.5), 0.5)
	Props.chocks(r, Vector3(-3, 0, -2))
	Props.chocks(r, Vector3(17, 0, -4.2))
	Props.chocks(r, Vector3(17, 0, 0.2))
	# Airliner details: engine fans, wingtip lights, door frames.
	var zc := -2.0
	for side: float in [-1.0, 1.0]:
		var ez := zc + side * 8.5
		Craft.part(r, Craft.cutout(Craft.star_points(0.72, 0.25, 9), 0.03), Craft.mat(Craft.Kind.FOIL, Color(0.75, 0.76, 0.8), 0, Color.WHITE, 1.0, 0.0, false), Vector3(13.95, 1.7, ez), Vector3(0, PI * 0.5, 0.2))
		var tip := zc + side * 19.2
		Craft.part(r, Craft.sphere(0.25, 10), Craft.mat(Craft.Kind.GLOW, Color(0.2, 1.0, 0.3) if side > 0.0 else Color(1.0, 0.15, 0.1), 0, Color.WHITE, 1.0, 0.0, false), Vector3(24.3, 2.85, tip))
	var door_m := Craft.mat(Craft.Kind.PAPER, Color(0.55, 0.6, 0.7), 0, Color.WHITE, 1.0, 0.0, false)
	for d in [[-2.4, 0.4, zc - 3.22], [31.5, 33.5, zc + 3.22]]:
		var x0: float = d[0]
		var x1: float = d[1]
		var dz: float = d[2]
		Craft.box(r, Vector3(x0 - 0.06, 4.2, dz), Vector3(0.1, 2.5, 0.04), door_m)
		Craft.box(r, Vector3(x1 + 0.06, 4.2, dz), Vector3(0.1, 2.5, 0.04), door_m)
	# Background: a big corrugated hangar and planes parked on remote stands.
	var hangar := Craft.pivot(r, Vector3(110, 0, -8))
	Craft.part(hangar, Craft.tube(20.0, 46.0, 36, false, PI), Craft.mat(Craft.Kind.CARDBOARD, Color(0.62, 0.66, 0.72), Craft.Pattern.BANDS, Color(0.55, 0.58, 0.64), 0.8, 1.0, false), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	Craft.part(hangar, Craft.tube(19.6, 46.0, 36, true, PI), Craft.mat(Craft.Kind.CARDBOARD, Color(0.35, 0.38, 0.42), 0, Color.WHITE, 1.0, 0.0, false), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	Craft.box(hangar, Vector3(23, 10, 0), Vector3(0.5, 20, 40), Craft.mat(Craft.Kind.CARDBOARD, Color(0.35, 0.38, 0.42)))
	Architecture.letters(hangar, "HANGAR 3", Vector3(-23.2, 16.5, 0), -PI * 0.5, 3.0, Craft.CREAM, 0.3)
	_simple_plane(hangar, Vector3(0, 0, 0), 0.0, Craft.BLUE)
	_simple_plane(r, Vector3(95, 0, -70), 0.7, Craft.TEAL)
	_simple_plane(r, Vector3(-30, 0, -78), -0.4, Color(0.5, 0.16, 0.16))
	for i in 30:
		for side: float in [39.0, 61.0]:
			Craft.part(r, Craft.sphere(0.25, 6), Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.9, 0.55), 0, Color.WHITE, 1.0, 0.0, false), Vector3(-130 + i * 9.0, 0.25, side), Vector3.ZERO, Vector3.ONE, false)


func _simple_plane(parent: Node3D, pos: Vector3, yaw: float, livery: Color) -> void:
	var root := Craft.pivot(parent, pos, Vector3(0, yaw, 0))
	var skin := Craft.mat(Craft.Kind.PAPER, Color(0.88, 0.88, 0.86), 0, Color.WHITE, 1.0, 0.0, false)
	Craft.part(root, Craft.tube(2.6, 30.0, 24), skin, Vector3(0, 3.6, 0))
	Craft.part(root, Craft.sphere(2.6, 20), skin, Vector3(-15, 3.6, 0), Vector3.ZERO, Vector3(1.5, 1, 1))
	Craft.part(root, Craft.cylinder(2.6, 0.5, 6.0, 20), skin, Vector3(18, 4.1, 0), Vector3(0, 0, -PI * 0.5 + 0.1))
	Craft.box(root, Vector3(-1, 3.0, 0), Vector3(6.0, 0.3, 30.0), Craft.mat(Craft.Kind.CARDBOARD, Color(0.9, 0.9, 0.92)))
	Craft.part(root, Craft.cutout(PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(6.5, 6), Vector2(4.5, 6.2)]), 0.3), Craft.mat(Craft.Kind.CARDBOARD, livery, 0, Color.WHITE, 1.0, 0.0, false), Vector3(16, 5.6, 0))
	Craft.box(root, Vector3(0, 3.2, 2.62), Vector3(28, 0.4, 0.04), Craft.mat(Craft.Kind.PAPER, livery))
	Craft.box(root, Vector3(0, 3.2, -2.62), Vector3(28, 0.4, 0.04), Craft.mat(Craft.Kind.PAPER, livery))


# ----------------------------------------------------------------- spawns

func _spawn_points() -> void:
	for z: float in [-8.0, -3.0, 2.0, 7.0, 12.0, 17.0]:
		spawns[0].append(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-55, 0.05, z)))
	for z: float in [-18.0, -11.0, -4.0, 4.0, 11.0, 18.0]:
		spawns[1].append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(57, 0.05, z)))
	for p in [Vector3(-40, 0.05, -27), Vector3(-30, 3.05, -26), Vector3(18, 0.05, -35), Vector3(-6, 0.05, -34),
			Vector3(10, 0.05, 18), Vector3(38, 0.05, 22), Vector3(-36, 0.05, 24.5), Vector3(28, 0.05, -20),
			Vector3(20, 0.05, 13), Vector3(-25, 0.05, 8), Vector3(8, 3.05, -2), Vector3(30, 0.05, -32)]:
		spawns[-1].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p))


# ------------------------------------------------------------- navigation

func _bake_navigation() -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = MapBuilder.WORLD_LAYER | MapBuilder.GLASS_LAYER
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.25
	nm.agent_max_slope = 40.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.filter_baking_aabb = AABB(Vector3(-60, -1, -40), Vector3(122, 7.5, 68))
	nav_region.navigation_mesh = nm
	nav_region.bake_navigation_mesh(false)


# ------------------------------------------------------------------ polish

## A detail pass over the spots that read as bare: the baggage hall's
## walls and ceiling, the mezzanine lounge and the airliner cabin.
func _polish() -> void:
	var p := Node3D.new()
	p.name = "Polish"
	deco.add_child(p)
	var steel := Craft.mat(Craft.Kind.FOIL, Color(0.62, 0.63, 0.66), 0, Color.WHITE, 1.0, 0.0, false)
	var dark := Craft.mat(Craft.Kind.PAPER, Color(0.16, 0.16, 0.18))
	var yellow := Craft.mat(Craft.Kind.FELT, Craft.YELLOW, 0, Color.WHITE, 1.0, 0.0, false)
	var red := Craft.mat(Craft.Kind.PAPER, Color(0.62, 0.14, 0.12))
	var glow := Craft.mat(Craft.Kind.GLOW, Color(1.0, 0.95, 0.85), 0, Color.WHITE, 1.0, 0.0, false)

	# ---- Baggage hall: corrugated cladding ribs on the inside of the
	# north wall, ducts and cable trays under the roof, caged lights,
	# walkway lines, extinguishers and belt signs.
	var ribs := []
	var x := -13.5
	while x < 31.6:
		ribs.append(Transform3D(Basis().scaled(Vector3(0.06, 4.6, 0.05)), Vector3(x, 2.4, -37.77)))
		x += 0.6
	FeltGround._multimesh(p, Craft.unit_box(), Craft.mat(Craft.Kind.CARDBOARD, Color(0.46, 0.49, 0.53)), ribs, false)
	Craft.part(p, Craft.cylinder(0.32, 0.32, 45.0, 16), steel, Vector3(9, 4.45, -36.6), Vector3(0, 0, PI * 0.5))
	for k in 9:
		Craft.part(p, Craft.cylinder(0.34, 0.34, 0.06, 16), dark, Vector3(-12 + k * 5.5, 4.45, -36.6), Vector3(0, 0, PI * 0.5))
		Craft.box(p, Vector3(-12 + k * 5.5, 4.85, -36.6), Vector3(0.04, 0.3, 0.04), dark)
	Craft.box(p, Vector3(9, 4.55, -28.0), Vector3(45.0, 0.06, 0.4), steel)
	for k in 12:
		Craft.box(p, Vector3(-12 + k * 4.0, 4.78, -28.0), Vector3(0.03, 0.45, 0.03), dark)
	Handmade.cable(p, [Vector3(-13, 4.6, -27.95), Vector3(31, 4.6, -27.95)], Color(0.12, 0.12, 0.14), 0.03)
	Handmade.cable(p, [Vector3(-13, 4.62, -28.1), Vector3(31, 4.62, -28.1)], Color(0.6, 0.2, 0.15), 0.025)
	for lx: float in [-6.0, 7.0, 20.0]:
		Craft.part(p, Craft.torus_ring(0.66, 0.025), dark, Vector3(lx, 4.55, -32), Vector3.ZERO, Vector3(1, 0.6, 1))
		for a in 4:
			Craft.box(p, Vector3(lx + cos(a * PI * 0.5) * 0.5, 4.5, -32 + sin(a * PI * 0.5) * 0.5), Vector3(0.02, 0.3, 0.02), dark)
	# Yellow walkway lines and hatched keep-clear boxes by the doors.
	for z: float in [-35.0, -30.0]:
		Craft.box(p, Vector3(9, 0.035, z), Vector3(44.0, 0.01, 0.12), yellow, Vector3.ZERO, false)
	for dx: float in [-4.0, 10.0, 24.0]:
		Craft.box(p, Vector3(dx, 0.033, -27.4), Vector3(4.0, 0.01, 2.0), Craft.mat(Craft.Kind.FELT, Craft.YELLOW, Craft.Pattern.HAZARD, Color(0.25, 0.26, 0.28), 1.2), Vector3.ZERO, false)
	# Extinguishers on red wall boards, an alarm point, and belt numbers.
	for ex: float in [-12.0, 15.0, 30.0]:
		Craft.box(p, Vector3(ex, 1.3, -37.74), Vector3(0.5, 0.9, 0.02), red)
		Craft.part(p, Craft.cylinder(0.09, 0.09, 0.5, 10), red, Vector3(ex, 1.05, -37.6))
		Craft.part(p, Craft.cylinder(0.03, 0.03, 0.1, 8), dark, Vector3(ex, 1.35, -37.6))
		Craft.box(p, Vector3(ex + 0.6, 1.5, -37.74), Vector3(0.14, 0.14, 0.05), red)
	var nums := ["BELT 1", "BELT 2", "BELT 3"]
	for k in 3:
		var bx := -6.0 + k * 13.0
		Craft.box(p, Vector3(bx, 3.6, -34.2), Vector3(1.6, 0.5, 0.06), dark)
		Craft.box(p, Vector3(bx, 4.35, -34.2), Vector3(0.03, 1.0, 0.03), dark)
		_label(Vector3(bx, 3.6, -34.16), nums[k], 70, Craft.YELLOW)
	# A wall clock.
	Craft.part(p, Craft.cylinder(0.32, 0.32, 0.05, 20), Craft.mat(Craft.Kind.PAPER, Color(0.9, 0.9, 0.88)), Vector3(9, 3.4, -37.74), Vector3(PI * 0.5, 0, 0))
	Craft.part(p, Craft.torus_ring(0.33, 0.04), dark, Vector3(9, 3.4, -37.72), Vector3(PI * 0.5, 0, 0))
	Craft.box(p, Vector3(9, 3.48, -37.7), Vector3(0.02, 0.2, 0.01), dark)
	Craft.box(p, Vector3(9.07, 3.4, -37.7), Vector3(0.15, 0.02, 0.01), dark)

	# ---- Mezzanine lounge (carpet tiles are on the floor material).
	var felt_chair := Craft.mat(Craft.Kind.FELT, Color(0.42, 0.36, 0.3), Craft.Pattern.STITCH, Color(0.32, 0.27, 0.22))
	var wood := Craft.mat(Craft.Kind.CARDBOARD, Color(0.55, 0.42, 0.3))
	for lx: float in [-52.0, -44.0, -36.0, -28.0]:
		for side: float in [-1.0, 1.0]:
			var cx := lx + side * 1.0
			var ch := b.solid(Vector3(cx, 3.35, -25.5), Vector3(0.9, 0.7, 0.9), null, 0.0, false)
			Craft.box(ch, Vector3(0, -0.12, 0), Vector3(0.85, 0.35, 0.85), felt_chair)
			Craft.box(ch, Vector3(0, 0.22, 0.36), Vector3(0.85, 0.5, 0.15), felt_chair)
			for ax: float in [-0.38, 0.38]:
				Craft.box(ch, Vector3(ax, 0.08, 0), Vector3(0.12, 0.3, 0.85), felt_chair)
		b.solid(Vector3(lx, 3.25, -24.6), Vector3(0.8, 0.05, 0.6), wood)
		for sx: float in [-0.35, 0.35]:
			for sz: float in [-0.25, 0.25]:
				b.deco_box(Vector3(lx + sx, 3.12, -24.6 + sz), Vector3(0.04, 0.22, 0.04), dark)
		Craft.part(p, Craft.cylinder(0.05, 0.04, 0.1, 10), Craft.mat(Craft.Kind.PAPER, Color(0.88, 0.87, 0.84)), Vector3(lx + 0.15, 3.33, -24.6))
	for px: float in [-56.5, -40.0, -24.0]:
		Props.potted_tree(b, Vector3(px, 3.0, -28.8), rng)

	# ---- Airliner cabin: interior windows, aisle runner, ceiling lights.
	var zc := -2.0
	var yc := 4.4
	var sky := Craft.mat(Craft.Kind.GLOW, Color(0.62, 0.7, 0.76), 0, Color.WHITE, 1.0, 0.0, false)
	var surround := Craft.mat(Craft.Kind.PAPER, Color(0.74, 0.72, 0.68))
	for side: float in [-1.0, 1.0]:
		var wx := 2.0
		while wx < 31.0:
			Craft.part(p, Craft.cylinder(0.24, 0.24, 0.02, 14), surround, Vector3(wx, yc + 0.35, zc + side * 2.93), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 1.35), false)
			Craft.part(p, Craft.cylinder(0.17, 0.17, 0.02, 14), sky, Vector3(wx, yc + 0.35, zc + side * 2.91), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 1.35), false)
			wx += 1.1
	Craft.box(p, Vector3(16, 3.012, -1.95), Vector3(38, 0.01, 1.7), Craft.mat(Craft.Kind.FELT, Color(0.24, 0.26, 0.32), Craft.Pattern.STITCH, Color(0.17, 0.19, 0.24)), Vector3.ZERO, false)
	for side: float in [-1.0, 1.0]:
		Craft.box(p, Vector3(16, 6.22, zc + side * 0.7), Vector3(36, 0.03, 0.12), glow, Vector3.ZERO, false)
	# Seat dividers: armrests between each of the three seats in a block.
	var arm := Craft.mat(Craft.Kind.PAPER, Color(0.3, 0.32, 0.36))
	var sx := 2.0
	while sx < 30.5:
		if sx > 14.5 and sx < 17.5:
			sx += 1.1
			continue
		for z: float in [-4.7, -4.13, -3.57, -3.0, -1.0, -0.43, 0.13, 0.7]:
			Craft.box(p, Vector3(sx, 3.62, z), Vector3(0.45, 0.05, 0.05), arm)
		sx += 1.1

