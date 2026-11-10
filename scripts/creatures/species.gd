class_name Species
extends RefCounted
## Every catchable species: journal info, behaviour, and the wing-painting
## parameters used by shaders/wing.gdshaderinc.
##
## rarity:  1 common · 2 uncommon · 3 rare · 4 very rare
## alert:   distance (m) at which it notices a walking player. Sneaking
##          shrinks this to about a quarter; running grows it by ~60%.
## style:   "flutter", "glide" or "erratic" flight.
## hours:   [start, end] active window (24h clock; may wrap past midnight).

const RARITY_NAMES := ["", "Common", "Uncommon", "Rare", "Very Rare"]
const RARITY_WEIGHT := [0.0, 10.0, 4.0, 1.4, 0.45]

const BLACK := Color(0.06, 0.05, 0.045)

static var ORDER: Array[String] = [
	"monarch", "tiger_swallowtail", "painted_lady", "tailed_blue", "sulphur",
	"checkered_white", "buckeye", "pipevine", "zebra_longwing", "lustrous_copper",
	"red_spotted_purple", "malachite", "zebra_swallowtail", "diana", "purple_hairstreak",
]

static var DATA := {
	"monarch": {
		"name": "Monarch", "sci": "Danaus plexippus", "rarity": 1, "size": 1.0,
		"alert": 1.7, "speed": 1.5, "style": "glide", "hours": [6.5, 20.0],
		"habitat": {"flowers": 1.0, "meadow": 0.6},
		"fact": "Each autumn, monarchs from eastern North America fly thousands of kilometres to spend the winter in the mountain forests of central Mexico.",
		"wing": {
			"fore_apex": Vector2(0.95, 0.62), "fore_tornus": Vector2(0.6, 0.02),
			"hind_outer": Vector2(0.66, -0.28), "hind_bottom": Vector2(0.3, -0.68),
			"fore_in": Color(0.85, 0.36, 0.05), "fore_out": Color(0.98, 0.55, 0.12),
			"hind_in": Color(0.85, 0.38, 0.06), "hind_out": Color(0.98, 0.58, 0.15),
			"border_col": BLACK, "border_fore": 0.09, "border_hind": 0.085,
			"spot_col": Color(0.98, 0.96, 0.9), "spot_count": 9.0, "spot_size": 0.014, "spot_rows": 2.0,
			"vein_col": BLACK, "vein_width": 0.022, "vein_count": 9.0,
			"apex_col": BLACK, "apex_size": 0.3, "apex_dots": 1.0, "apex_dot_col": Color(1.0, 0.82, 0.55),
			"root_dark": 0.5,
		},
	},
	"tiger_swallowtail": {
		"name": "Eastern Tiger Swallowtail", "sci": "Papilio glaucus", "rarity": 1, "size": 1.25,
		"alert": 1.9, "speed": 1.6, "style": "glide", "hours": [7.0, 19.5],
		"habitat": {"flowers": 0.8, "forest_edge": 1.0},
		"fact": "Some females are almost completely black — a dark form thought to mimic the bad-tasting Pipevine Swallowtail.",
		"wing": {
			"fore_apex": Vector2(0.98, 0.6), "fore_tornus": Vector2(0.55, 0.02),
			"hind_outer": Vector2(0.62, -0.3), "hind_bottom": Vector2(0.26, -0.66),
			"tail_len": 0.22, "tail_width": 0.035, "tail_dir": Vector2(0.25, -1.0), "scallop": 0.012,
			"fore_in": Color(1.0, 0.8, 0.2), "fore_out": Color(1.0, 0.88, 0.36),
			"hind_in": Color(1.0, 0.8, 0.22), "hind_out": Color(1.0, 0.88, 0.38),
			"stripe_col": BLACK, "stripe_width": 0.26, "stripe_freq": 4.2, "stripe_mode": 0.0,
			"stripe_angle": 0.0, "stripe_offset": 0.15,
			"border_col": BLACK, "border_fore": 0.1, "border_hind": 0.15,
			"spot_col": Color(1.0, 0.86, 0.3), "spot_count": 8.0, "spot_size": 0.016,
			"sub_col": Color(0.35, 0.55, 0.95), "sub_size": 0.024, "sub_offset": -0.05, "sub_count": 6.0,
			"vein_col": BLACK, "vein_width": 0.01, "vein_count": 10.0,
		},
	},
	"painted_lady": {
		"name": "Painted Lady", "sci": "Vanessa cardui", "rarity": 1, "size": 0.9,
		"alert": 1.8, "speed": 1.9, "style": "erratic", "hours": [7.0, 19.0],
		"habitat": {"flowers": 1.0, "meadow": 0.8},
		"fact": "One of the most widespread butterflies in the world, found across Europe, Africa, Asia and North America.",
		"wing": {
			"fore_apex": Vector2(0.93, 0.64), "fore_tornus": Vector2(0.6, 0.04),
			"hind_outer": Vector2(0.62, -0.28), "hind_bottom": Vector2(0.3, -0.64), "scallop": 0.008,
			"fore_in": Color(0.72, 0.4, 0.22), "fore_out": Color(0.98, 0.56, 0.32),
			"hind_in": Color(0.72, 0.42, 0.24), "hind_out": Color(0.98, 0.6, 0.36),
			"apex_col": BLACK, "apex_size": 0.36, "apex_dots": 1.0, "apex_dot_col": Color(0.97, 0.95, 0.9),
			"band_col": BLACK, "band_line": Vector4(0.42, 0.52, 0.62, 0.16), "band_width": 0.045,
			"dot_col": BLACK, "dot_density": 0.12, "dot_size": 0.022,
			"border_col": Color(0.2, 0.12, 0.08), "border_hind": 0.05,
			"sub_col": BLACK, "sub_size": 0.02, "sub_offset": 0.04, "sub_count": 7.0,
			"root_dark": 0.4,
		},
	},
	"tailed_blue": {
		"name": "Eastern Tailed-Blue", "sci": "Cupido comyntas", "rarity": 1, "size": 0.62,
		"alert": 1.4, "speed": 1.3, "style": "erratic", "hours": [8.0, 18.5],
		"habitat": {"meadow": 1.0, "flowers": 0.6},
		"fact": "The tiny tails and orange spots on its hindwings look like a second head, tricking birds into pecking at the wrong end.",
		"wing": {
			"fore_apex": Vector2(0.9, 0.62), "fore_tornus": Vector2(0.62, 0.0),
			"hind_outer": Vector2(0.64, -0.3), "hind_bottom": Vector2(0.3, -0.62),
			"tail_len": 0.12, "tail_width": 0.012,
			"fore_in": Color(0.32, 0.46, 0.94), "fore_out": Color(0.46, 0.62, 1.0),
			"hind_in": Color(0.34, 0.48, 0.95), "hind_out": Color(0.5, 0.66, 1.0),
			"border_col": Color(0.14, 0.14, 0.28), "border_fore": 0.03, "border_hind": 0.03,
			"fringe": 0.014, "fringe_col": Color(0.97, 0.97, 1.0),
			"sub_col": Color(1.0, 0.55, 0.2), "sub_size": 0.022, "sub_offset": 0.015, "sub_count": 5.0,
			"irid": 0.3, "irid_col": Color(0.4, 0.6, 1.0), "irid_start": 0.1,
		},
	},
	"sulphur": {
		"name": "Orange-barred Sulphur", "sci": "Phoebis philea", "rarity": 1, "size": 1.05,
		"alert": 1.7, "speed": 2.0, "style": "flutter", "hours": [7.5, 18.5],
		"habitat": {"flowers": 1.0, "meadow": 0.7},
		"fact": "A big, fast-flying sulphur that loves to sip nectar from bright, tube-shaped flowers.",
		"wing": {
			"fore_apex": Vector2(0.94, 0.62), "fore_tornus": Vector2(0.64, 0.02),
			"hind_outer": Vector2(0.66, -0.3), "hind_bottom": Vector2(0.32, -0.66),
			"fore_in": Color(1.0, 0.86, 0.22), "fore_out": Color(1.0, 0.92, 0.42),
			"hind_in": Color(1.0, 0.72, 0.2), "hind_out": Color(1.0, 0.6, 0.14),
			"cell_col": Color(1.0, 0.56, 0.12), "cell_size": 0.09,
			"border_col": Color(0.85, 0.42, 0.12), "border_fore": 0.02,
			"fringe": 0.012, "fringe_col": Color(0.92, 0.5, 0.55), "root_dark": 0.15,
		},
	},
	"checkered_white": {
		"name": "Checkered White", "sci": "Pontia protodice", "rarity": 1, "size": 0.78,
		"alert": 1.3, "speed": 1.5, "style": "flutter", "hours": [7.0, 18.0],
		"habitat": {"meadow": 1.0},
		"fact": "Its caterpillars feed on wild plants in the mustard family.",
		"wing": {
			"fore_apex": Vector2(0.92, 0.6), "fore_tornus": Vector2(0.64, 0.02),
			"hind_outer": Vector2(0.66, -0.3), "hind_bottom": Vector2(0.32, -0.66),
			"fore_in": Color(0.92, 0.92, 0.9), "fore_out": Color(1.0, 1.0, 0.98),
			"hind_in": Color(0.9, 0.92, 0.88), "hind_out": Color(0.98, 0.99, 0.96),
			"dot_col": Color(0.16, 0.16, 0.2), "dot_density": 0.22, "dot_size": 0.028,
			"cell_col": Color(0.16, 0.16, 0.2), "cell_size": 0.06,
			"apex_col": Color(0.2, 0.2, 0.24), "apex_size": 0.12, "root_dark": 0.35,
		},
	},
	"buckeye": {
		"name": "Common Buckeye", "sci": "Junonia coenia", "rarity": 2, "size": 0.85,
		"alert": 2.4, "speed": 1.8, "style": "erratic", "hours": [8.0, 19.0],
		"habitat": {"meadow": 1.0, "flowers": 0.5},
		"fact": "Its big, bold eyespots are thought to startle or distract hungry birds.",
		"wing": {
			"fore_apex": Vector2(0.9, 0.64), "fore_tornus": Vector2(0.6, 0.02),
			"hind_outer": Vector2(0.64, -0.3), "hind_bottom": Vector2(0.3, -0.64),
			"fore_in": Color(0.4, 0.29, 0.19), "fore_out": Color(0.5, 0.36, 0.24),
			"hind_in": Color(0.4, 0.29, 0.19), "hind_out": Color(0.5, 0.37, 0.25),
			"band_col": Color(0.96, 0.9, 0.78), "band_line": Vector4(0.55, 0.6, 0.72, 0.3), "band_width": 0.05,
			"eye_fore": Vector4(0.6, 0.2, 0.1, 0.0), "eye_hind": Vector4(0.44, -0.24, 0.1, 0.0),
			"eye_hind2": Vector4(0.33, -0.45, 0.07, 0.0),
			"eye_ring": Color(0.98, 0.84, 0.4), "eye_mid": Color(0.15, 0.1, 0.25), "eye_pupil": Color(0.48, 0.38, 0.92),
			"border_col": Color(0.3, 0.2, 0.12), "border_fore": 0.04, "border_hind": 0.04,
			"sub_col": Color(0.92, 0.5, 0.2), "sub_size": 0.018, "sub_offset": 0.02,
			"cell_col": Color(0.92, 0.46, 0.16), "cell_size": 0.07,
		},
	},
	"pipevine": {
		"name": "Pipevine Swallowtail", "sci": "Battus philenor", "rarity": 2, "size": 1.15,
		"alert": 2.6, "speed": 1.8, "style": "flutter", "hours": [7.5, 19.0],
		"habitat": {"forest_edge": 1.0, "flowers": 0.6},
		"fact": "Its caterpillars eat pipevine plants and store their toxins, so birds learn to leave the adults alone.",
		"wing": {
			"fore_apex": Vector2(0.96, 0.6), "fore_tornus": Vector2(0.56, 0.02),
			"hind_outer": Vector2(0.64, -0.3), "hind_bottom": Vector2(0.28, -0.64),
			"tail_len": 0.12, "tail_width": 0.03, "scallop": 0.01,
			"fore_in": Color(0.05, 0.06, 0.08), "fore_out": Color(0.09, 0.11, 0.14),
			"hind_in": Color(0.05, 0.08, 0.12), "hind_out": Color(0.12, 0.32, 0.48),
			"irid": 0.9, "irid_col": Color(0.15, 0.55, 0.9), "irid_start": 0.15,
			"border_col": BLACK, "border_fore": 0.03, "border_hind": 0.07,
			"spot_col": Color(0.95, 0.95, 0.98), "spot_count": 7.0, "spot_size": 0.012,
		},
	},
	"zebra_longwing": {
		"name": "Zebra Longwing", "sci": "Heliconius charithonia", "rarity": 2, "size": 1.1,
		"alert": 2.2, "speed": 1.1, "style": "glide", "hours": [8.0, 18.0],
		"habitat": {"forest_edge": 1.0, "flowers": 0.7},
		"fact": "Adults eat pollen as well as nectar, which helps them live for months — far longer than most butterflies.",
		"wing": {
			"fore_apex": Vector2(1.0, 0.42), "fore_tornus": Vector2(0.78, 0.12),
			"hind_outer": Vector2(0.72, -0.18), "hind_bottom": Vector2(0.25, -0.42),
			"fore_in": Color(0.06, 0.05, 0.05), "fore_out": Color(0.08, 0.07, 0.06),
			"hind_in": Color(0.06, 0.05, 0.05), "hind_out": Color(0.08, 0.07, 0.06),
			"stripe_col": Color(1.0, 0.92, 0.45), "stripe_mode": 1.0, "stripe_freq": 7.0,
			"stripe_width": 0.22, "stripe_offset": 0.2,
			"spot_col": Color(1.0, 0.92, 0.5), "border_hind": 0.05, "border_col": Color(0.06, 0.05, 0.05),
			"spot_count": 8.0, "spot_size": 0.01, "root_dark": 0.1,
		},
	},
	"lustrous_copper": {
		"name": "Lustrous Copper", "sci": "Lycaena cuprea", "rarity": 2, "size": 0.58,
		"alert": 2.6, "speed": 2.0, "style": "erratic", "hours": [9.0, 17.5],
		"habitat": {"flowers": 1.0},
		"fact": "A tiny butterfly of high mountain meadows whose wings shine a fiery red-orange.",
		"wing": {
			"fore_apex": Vector2(0.9, 0.62), "fore_tornus": Vector2(0.62, 0.02),
			"hind_outer": Vector2(0.64, -0.3), "hind_bottom": Vector2(0.32, -0.6),
			"fore_in": Color(0.98, 0.32, 0.08), "fore_out": Color(1.0, 0.45, 0.12),
			"hind_in": Color(0.95, 0.3, 0.08), "hind_out": Color(1.0, 0.42, 0.12),
			"border_col": Color(0.2, 0.08, 0.04), "border_fore": 0.035, "border_hind": 0.04,
			"dot_col": Color(0.15, 0.06, 0.03), "dot_density": 0.18, "dot_size": 0.022,
			"irid": 0.25, "irid_col": Color(1.0, 0.5, 0.2), "irid_start": 0.0,
		},
	},
	"red_spotted_purple": {
		"name": "Red-spotted Purple", "sci": "Limenitis arthemis", "rarity": 3, "size": 1.1,
		"alert": 3.8, "speed": 1.8, "style": "glide", "hours": [8.0, 19.5],
		"habitat": {"forest_edge": 1.0},
		"fact": "It mimics the toxic Pipevine Swallowtail, so birds that learned to avoid one tend to avoid the other too.",
		"wing": {
			"fore_apex": Vector2(0.94, 0.62), "fore_tornus": Vector2(0.6, 0.02),
			"hind_outer": Vector2(0.66, -0.3), "hind_bottom": Vector2(0.3, -0.66), "scallop": 0.01,
			"fore_in": Color(0.06, 0.07, 0.12), "fore_out": Color(0.12, 0.18, 0.36),
			"hind_in": Color(0.08, 0.1, 0.18), "hind_out": Color(0.2, 0.38, 0.72),
			"irid": 1.0, "irid_col": Color(0.3, 0.55, 1.0), "irid_start": 0.25,
			"sub_col": Color(0.95, 0.45, 0.15), "sub_size": 0.02, "sub_offset": 0.07, "sub_fore": 1.0, "sub_count": 7.0,
			"border_col": BLACK, "border_fore": 0.04, "border_hind": 0.04,
			"spot_col": Color(0.6, 0.75, 1.0), "spot_count": 8.0, "spot_size": 0.01,
		},
	},
	"malachite": {
		"name": "Malachite", "sci": "Siproeta stelenes", "rarity": 3, "size": 1.15,
		"alert": 3.5, "speed": 1.6, "style": "glide", "hours": [9.0, 18.0],
		"habitat": {"forest_edge": 1.0, "flowers": 0.4},
		"fact": "Named after the green mineral malachite, it often feeds on rotting fruit as well as flowers.",
		"wing": {
			"fore_apex": Vector2(0.96, 0.62), "fore_tornus": Vector2(0.62, 0.0),
			"hind_outer": Vector2(0.66, -0.32), "hind_bottom": Vector2(0.3, -0.66),
			"tail_len": 0.08, "tail_width": 0.025, "scallop": 0.012,
			"fore_in": Color(0.48, 0.84, 0.36), "fore_out": Color(0.36, 0.7, 0.26),
			"hind_in": Color(0.5, 0.85, 0.38), "hind_out": Color(0.38, 0.72, 0.28),
			"vein_col": Color(0.14, 0.1, 0.07), "vein_width": 0.018, "vein_count": 7.0,
			"border_col": Color(0.14, 0.1, 0.07), "border_fore": 0.13, "border_hind": 0.1,
			"spot_col": Color(0.5, 0.85, 0.4), "spot_count": 6.0, "spot_size": 0.022,
			"apex_col": Color(0.14, 0.1, 0.07), "apex_size": 0.28, "apex_dots": 1.0,
			"apex_dot_col": Color(0.5, 0.85, 0.4), "root_dark": 0.4,
		},
	},
	"zebra_swallowtail": {
		"name": "Zebra Swallowtail", "sci": "Eurytides marcellus", "rarity": 3, "size": 1.15,
		"alert": 3.6, "speed": 2.1, "style": "glide", "hours": [8.0, 18.0],
		"habitat": {"forest_edge": 1.0, "meadow": 0.4},
		"fact": "Its caterpillars feed only on the leaves of pawpaw trees.",
		"wing": {
			"fore_apex": Vector2(1.0, 0.5), "fore_tornus": Vector2(0.58, 0.05),
			"hind_outer": Vector2(0.6, -0.28), "hind_bottom": Vector2(0.24, -0.6),
			"tail_len": 0.45, "tail_width": 0.028, "tail_dir": Vector2(0.15, -1.0),
			"fore_in": Color(0.9, 0.94, 0.86), "fore_out": Color(0.94, 0.97, 0.9),
			"hind_in": Color(0.9, 0.94, 0.86), "hind_out": Color(0.94, 0.97, 0.9),
			"stripe_col": BLACK, "stripe_width": 0.3, "stripe_freq": 5.0, "stripe_angle": 0.35,
			"border_col": BLACK, "border_fore": 0.06, "border_hind": 0.06,
			"sub_col": Color(0.9, 0.12, 0.1), "sub_size": 0.03, "sub_offset": 0.02, "sub_count": 2.0,
		},
	},
	"diana": {
		"name": "Diana Fritillary", "sci": "Speyeria diana", "rarity": 4, "size": 1.25,
		"alert": 4.6, "speed": 2.0, "style": "glide", "hours": [15.5, 20.0],
		"habitat": {"forest_edge": 1.0, "flowers": 0.8},
		"fact": "Males are black and orange while females are black and blue — they look so different they were once thought to be two species.",
		"wing": {
			"fore_apex": Vector2(0.95, 0.62), "fore_tornus": Vector2(0.62, 0.02),
			"hind_outer": Vector2(0.66, -0.3), "hind_bottom": Vector2(0.3, -0.66), "scallop": 0.01,
			"fore_in": Color(0.09, 0.07, 0.06), "fore_out": Color(1.0, 0.55, 0.12),
			"hind_in": Color(0.09, 0.07, 0.06), "hind_out": Color(1.0, 0.6, 0.15),
			"grad_start": 0.6, "grad_end": 0.68,
			"sub_col": Color(0.12, 0.08, 0.06), "sub_size": 0.016, "sub_offset": 0.08, "sub_fore": 1.0,
			"border_col": Color(0.85, 0.42, 0.08), "border_fore": 0.015, "border_hind": 0.015,
			"root_dark": 0.2,
		},
	},
	"purple_hairstreak": {
		"name": "Great Purple Hairstreak", "sci": "Atlides halesus", "rarity": 4, "size": 0.72,
		"alert": 4.2, "speed": 2.4, "style": "erratic", "hours": [10.0, 16.0],
		"habitat": {"forest_edge": 1.0},
		"fact": "Its caterpillars feed only on mistletoe — and despite the name, its wings flash iridescent blue, not purple.",
		"wing": {
			"fore_apex": Vector2(0.92, 0.6), "fore_tornus": Vector2(0.62, 0.02),
			"hind_outer": Vector2(0.64, -0.3), "hind_bottom": Vector2(0.3, -0.6),
			"tail_len": 0.3, "tail_width": 0.014,
			"fore_in": Color(0.1, 0.45, 0.62), "fore_out": Color(0.05, 0.05, 0.07),
			"hind_in": Color(0.1, 0.48, 0.62), "hind_out": Color(0.05, 0.05, 0.07),
			"grad_start": 0.45, "grad_end": 0.78,
			"irid": 1.2, "irid_col": Color(0.2, 0.75, 0.95), "irid_start": -0.5,
			"border_col": BLACK, "border_fore": 0.04, "border_hind": 0.04,
		},
	},
}


static func get_data(id: String) -> Dictionary:
	return DATA[id]


static func apply_wing(mat: ShaderMaterial, sp: Dictionary) -> void:
	var wing: Dictionary = sp["wing"]
	for k in wing:
		mat.set_shader_parameter(k, wing[k])


static func is_active(sp: Dictionary, hour: float) -> bool:
	var h: Array = sp["hours"]
	var a := float(h[0])
	var b := float(h[1])
	if a <= b:
		return hour >= a and hour <= b
	return hour >= a or hour <= b


static func rarity_stars(rarity: int) -> String:
	return "*".repeat(rarity)
