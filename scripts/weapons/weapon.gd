class_name Weapon
extends RefCounted
## Runtime state of one carried weapon: ammo, fire-rate timing, reloads.

var id := ""
var data: Dictionary
var mag := 0
var reserve := 0
var cooldown := 0.0
var reloading := 0.0
var reload_total := 0.0
var trigger_released := true


func _init(weapon_id: String) -> void:
	id = weapon_id
	data = WeaponDB.get_data(weapon_id)
	refill()


func refill() -> void:
	mag = int(data["mag"])
	reserve = int(data["reserve"])
	cooldown = 0.0
	reloading = 0.0


func tick(delta: float) -> bool:
	## Returns true on the frame a reload finishes.
	cooldown = maxf(0.0, cooldown - delta)
	if reloading > 0.0:
		reloading -= delta
		if reloading <= 0.0:
			reloading = 0.0
			var need := int(data["mag"]) - mag
			var take := mini(need, reserve)
			mag += take
			reserve -= take
			return true
	return false


func can_fire() -> bool:
	return mag > 0 and cooldown <= 0.0 and reloading <= 0.0


func can_reload() -> bool:
	return reloading <= 0.0 and mag < int(data["mag"]) and reserve > 0


func start_reload() -> void:
	if not can_reload():
		return
	reload_total = float(data["reload_empty"] if mag == 0 else data["reload"])
	reloading = reload_total


func cancel_reload() -> void:
	reloading = 0.0


func consume() -> void:
	mag -= 1
	cooldown = 60.0 / float(data["rpm"])


func is_auto() -> bool:
	return bool(data["auto"])
