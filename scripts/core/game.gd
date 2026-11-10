extends Node
## Global game state (autoload "Game"): time of day, field journal, input mode,
## settings, and saving/loading.

signal species_caught(species_id: String, is_new: bool)
signal input_mode_changed(mode: int)
signal journal_changed

enum InputMode { KEYBOARD, GAMEPAD, TOUCH }

const SAVE_PATH := "user://meadowlight_save.json"
const SAVE_VERSION := 1

var input_mode: int = InputMode.KEYBOARD
var hour: float = 17.1
var day: int = 1
var day_speed: float = 1.0
var time_frozen := false

var world: Node = null
var player: Node = null

## species_id -> { "count": int, "first_day": int }
var journal: Dictionary = {}
var total_catches: int = 0

var settings := {
	"painterly": true,
	"mouse_sensitivity": 1.0,
	"invert_y": false,
	"volumetric_fog": true,
}

## Written by the on-screen touch controls, read by the player and camera.
var touch_move := Vector2.ZERO
var touch_look := Vector2.ZERO

var _autosave := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controls.register()
	load_game()


func _process(delta: float) -> void:
	if get_tree().paused or time_frozen:
		return
	# One game hour per real minute, lingering through the golden hour and
	# moving a bit faster through the deep night.
	var rate := 1.0 / 60.0
	if hour > 16.0 and hour < 20.5:
		rate *= 0.45
	elif hour > 22.0 or hour < 4.5:
		rate *= 1.6
	hour += rate * delta * day_speed
	if hour >= 24.0:
		hour -= 24.0
		day += 1
	_autosave += delta
	if _autosave > 30.0:
		_autosave = 0.0
		save_game()


func _input(event: InputEvent) -> void:
	var mode := input_mode
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		mode = InputMode.TOUCH
	elif event is InputEventJoypadButton:
		mode = InputMode.GAMEPAD
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		mode = InputMode.GAMEPAD
	elif event is InputEventKey:
		mode = InputMode.KEYBOARD
	elif (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseMotion and event.relative.length() < 2.0:
			return
		mode = InputMode.KEYBOARD
	if mode != input_mode:
		input_mode = mode
		input_mode_changed.emit(mode)


## Returns true if this species was new to the journal.
func record_catch(species_id: String) -> bool:
	var is_new := not journal.has(species_id)
	if is_new:
		journal[species_id] = {"count": 0, "first_day": day}
	journal[species_id]["count"] = int(journal[species_id]["count"]) + 1
	total_catches += 1
	species_caught.emit(species_id, is_new)
	journal_changed.emit()
	save_game()
	return is_new


func caught_count(species_id: String) -> int:
	if journal.has(species_id):
		return int(journal[species_id]["count"])
	return 0


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"hour": hour,
		"day": day,
		"journal": journal,
		"total_catches": total_catches,
		"settings": settings,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	hour = float(data.get("hour", hour))
	day = int(data.get("day", day))
	total_catches = int(data.get("total_catches", 0))
	var j = data.get("journal", {})
	if typeof(j) == TYPE_DICTIONARY:
		journal = j
	var s = data.get("settings", {})
	if typeof(s) == TYPE_DICTIONARY:
		for k in s:
			settings[k] = s[k]


func reset_save() -> void:
	journal = {}
	total_catches = 0
	day = 1
	hour = 17.1
	journal_changed.emit()
	save_game()


## 0 at night, 1 in full day — handy for lighting and spawning.
func daylight() -> float:
	var a := (hour - 6.0) / 12.0 * PI
	return clampf(sin(a) * 3.0 + 0.3, 0.0, 1.0)


func clock_text() -> String:
	var h := int(hour)
	var m := int((hour - h) * 60.0)
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, suffix]
