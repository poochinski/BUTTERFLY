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
## 30 levels. Each band of three levels shares a rank title (I, II, III).
const MAX_LEVEL := 30
const RANK_TITLES := ["Private", "Private First Class", "Specialist", "Corporal", "Sergeant",
	"Staff Sergeant", "Lieutenant", "Captain", "Major", "Colonel"]
const CUSTOM_SLOTS := 5
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
var profile := {"xp": 0, "kills": 0, "deaths": 0, "wins": 0, "matches": 0, "weapon_kills": {}, "classes": []}


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


## Total XP needed to reach a level (level 1 needs 0).
func xp_for_level(level: int) -> int:
	var total := 0
	for l in range(2, level + 1):
		total += 600 + (l - 2) * 150
	return total


func rank_for(xp: int) -> Dictionary:
	var level := 1
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
	var cur_xp := xp_for_level(level)
	var next_xp := xp_for_level(mini(level + 1, MAX_LEVEL))
	var title: String = RANK_TITLES[mini((level - 1) / 3, RANK_TITLES.size() - 1)] + " " + ["I", "II", "III"][(level - 1) % 3]
	return {"index": level - 1, "level": level, "name": title, "cur": cur_xp, "next": next_xp,
		"progress": 1.0 if next_xp == cur_xp else float(xp - cur_xp) / float(next_xp - cur_xp)}


func level() -> int:
	return int(rank_for(int(profile["xp"]))["level"])


func weapon_unlocked(id: String) -> bool:
	return level() >= int(WeaponDB.UNLOCK_LEVEL.get(id, 1))


func weapon_kills(id: String) -> int:
	return int((profile["weapon_kills"] as Dictionary).get(id, 0))


func attachment_unlocked(id: String, att: String) -> bool:
	return att == "" or weapon_kills(id) >= WeaponDB.attachment_kills(id, att)


## Custom classes live in the profile; start them as copies of the
## default classes.
func custom_classes() -> Array:
	var list: Array = profile["classes"]
	while list.size() < CUSTOM_SLOTS:
		list.append({"name": "Custom %d" % (list.size() + 1), "primary": "m4", "p_att": "", "secondary": "pistol", "s_att": ""})
	return list


## Every class the player can pick: the defaults, then the custom slots.
func class_count() -> int:
	return WeaponDB.CLASSES.size() + CUSTOM_SLOTS


func loadout(index: int) -> Dictionary:
	if index < WeaponDB.CLASSES.size():
		return WeaponDB.CLASSES[index]
	var c: Dictionary = custom_classes()[clampi(index - WeaponDB.CLASSES.size(), 0, CUSTOM_SLOTS - 1)]
	# Anything not unlocked (an old save, say) falls back to the starters.
	var out := c.duplicate()
	if not weapon_unlocked(String(out["primary"])):
		out["primary"] = "m4"
		out["p_att"] = ""
	if not weapon_unlocked(String(out["secondary"])):
		out["secondary"] = "pistol"
		out["s_att"] = ""
	if not attachment_unlocked(String(out["primary"]), String(out["p_att"])):
		out["p_att"] = ""
	if not attachment_unlocked(String(out["secondary"]), String(out["s_att"])):
		out["s_att"] = ""
	return out


func describe(c: Dictionary) -> String:
	var p := String(WeaponDB.DATA[c["primary"]]["name"])
	if String(c.get("p_att", "")) != "":
		p += " + " + String(WeaponDB.ATTACH[c["p_att"]])
	var s := String(WeaponDB.DATA[c["secondary"]]["name"])
	if String(c.get("s_att", "")) != "":
		s += " + " + String(WeaponDB.ATTACH[c["s_att"]])
	return p + "   |   " + s


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
