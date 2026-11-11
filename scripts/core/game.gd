extends Node
## Global state (autoload "Game"): settings, player profile and ranks, teams,
## input map, and input-device detection.

signal input_mode_changed(mode: int)
signal settings_changed

enum InputMode { KEYBOARD, GAMEPAD }

const SAVE_PATH := "user://papercut_profile.json"
const TEAM_NAMES := ["Task Force Cardstock", "Corrugated Militia"]
const TEAM_SHORT := ["CARDSTOCK", "MILITIA"]
const TEAM_COLORS := [Color(0.2, 0.28, 0.44), Color(0.6, 0.25, 0.18)]
const RANKS := [
	["Recruit", 0], ["Private", 800], ["Private First Class", 2000], ["Corporal", 4000],
	["Sergeant", 7000], ["Staff Sergeant", 11000], ["Lieutenant", 16000], ["Captain", 23000],
	["Major", 32000], ["Colonel", 44000], ["Commander", 60000],
]
const BOT_NAMES := ["Origami", "Glue Stick", "Thimble", "Staples", "Crayon", "Doily", "Pom-Pom",
	"Bookmark", "Ribbon", "Scissors", "Tassel", "Pinecone", "Sequin", "Buttons", "Washi", "Felt Tip"]
const DIFFICULTIES := ["Recruit", "Regular", "Hardened", "Veteran"]

var input_mode: int = InputMode.KEYBOARD
var settings := {
	"sensitivity": 1.0,
	"fov": 65.0,
	"invert_y": false,
	"volume": 0.8,
	"bot_difficulty": 1,
	"class": 0,
	"player_name": "You",
	"fullscreen": false,
	"graphics": "high",
	"map": "gateway",
}
## Playable maps: id, display name, one-line description.
const MAPS := [
	{"id": "gateway", "name": "Gateway", "desc": "papercraft airport"},
	{"id": "lodgepole", "name": "Lodgepole", "desc": "hillside forest lodge"},
]
var profile := {"xp": 0, "kills": 0, "deaths": 0, "wins": 0, "matches": 0}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.register()
	load_profile()
	apply_settings()


func fov() -> float:
	return float(settings["fov"])


func apply_settings() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(settings["volume"]), 0.001)))
	if not OS.has_feature("headless") and DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and (want == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(want)
	settings_changed.emit()


func _input(event: InputEvent) -> void:
	var mode := input_mode
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.45):
		mode = InputMode.GAMEPAD
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 3.0):
		mode = InputMode.KEYBOARD
	if mode != input_mode:
		input_mode = mode
		input_mode_changed.emit(mode)


func rank_for(xp: int) -> Dictionary:
	var idx := 0
	for i in RANKS.size():
		if xp >= int(RANKS[i][1]):
			idx = i
	var next_xp := int(RANKS[mini(idx + 1, RANKS.size() - 1)][1])
	var cur_xp := int(RANKS[idx][1])
	return {"index": idx, "name": RANKS[idx][0], "cur": cur_xp, "next": next_xp,
		"progress": 1.0 if next_xp == cur_xp else float(xp - cur_xp) / float(next_xp - cur_xp)}


func add_xp(amount: int) -> bool:
	## Returns true if this ranked the player up.
	var before := int(rank_for(int(profile["xp"]))["index"])
	profile["xp"] = int(profile["xp"]) + amount
	return int(rank_for(int(profile["xp"]))["index"]) > before


func save_profile() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"settings": settings, "profile": profile}, "\t"))


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	for key in ["settings", "profile"]:
		var src = data.get(key, {})
		if typeof(src) == TYPE_DICTIONARY:
			var dst: Dictionary = settings if key == "settings" else profile
			for k in src:
				if dst.has(k):
					dst[k] = src[k]
