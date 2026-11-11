class_name WeaponDB
extends RefCounted
## Every weapon's numbers. Tuned for classic 2009-era multiplayer pacing:
## 100 health, quick time-to-kill, damage falloff with range, headshot
## multipliers, hip-fire spread and aim-down-sights precision.
##
## damage: [close, far], falloff: [start metres, end metres]
## rpm: rounds per minute. spread: [hip degrees, ads degrees]
## recoil: [vertical degrees per shot, horizontal random degrees]
## ads_fov: field of view while aiming. ads_time: seconds to aim.
## move: movement speed multiplier while holding it.

const DATA := {
	"m4": {
		"name": "M4A1", "class": "Assault Rifle", "slot": 0,
		"damage": [30.0, 20.0], "falloff": [25.0, 50.0], "rpm": 780.0, "auto": true,
		"mag": 30, "reserve": 150, "reload": 2.2, "reload_empty": 2.8,
		"spread": [3.2, 0.12], "recoil": [0.55, 0.32], "ads_fov": 50.0, "ads_time": 0.24,
		"head_mult": 1.4, "move": 1.0, "pellets": 1, "range": 200.0,
		"model": "rifle", "body": Color(0.46, 0.5, 0.58), "trim": Color(0.82, 0.62, 0.4), "sound": "rifle",
	},
	"ak": {
		"name": "AK-47", "class": "Assault Rifle", "slot": 0,
		"damage": [40.0, 30.0], "falloff": [20.0, 45.0], "rpm": 600.0, "auto": true,
		"mag": 30, "reserve": 150, "reload": 2.4, "reload_empty": 3.0,
		"spread": [3.6, 0.15], "recoil": [0.8, 0.5], "ads_fov": 50.0, "ads_time": 0.27,
		"head_mult": 1.4, "move": 0.95, "pellets": 1, "range": 200.0,
		"model": "ak", "body": Color(0.44, 0.42, 0.42), "trim": Color(0.86, 0.48, 0.22), "sound": "rifle_heavy",
	},
	"smg": {
		"name": "PDW-9", "class": "Submachine Gun", "slot": 0,
		"damage": [35.0, 18.0], "falloff": [10.0, 25.0], "rpm": 950.0, "auto": true,
		"mag": 32, "reserve": 160, "reload": 1.9, "reload_empty": 2.4,
		"spread": [2.4, 0.2], "recoil": [0.42, 0.42], "ads_fov": 55.0, "ads_time": 0.18,
		"head_mult": 1.25, "move": 1.07, "pellets": 1, "range": 120.0,
		"model": "smg", "body": Color(0.4, 0.46, 0.56), "trim": Color(0.3, 0.6, 0.85), "sound": "smg",
	},
	"sniper": {
		"name": "Longbow .50", "class": "Sniper Rifle", "slot": 0,
		"damage": [98.0, 98.0], "falloff": [500.0, 600.0], "rpm": 48.0, "auto": false,
		"mag": 5, "reserve": 25, "reload": 3.0, "reload_empty": 3.6,
		"spread": [9.0, 0.0], "recoil": [3.5, 0.6], "ads_fov": 16.0, "ads_time": 0.38,
		"head_mult": 1.5, "chest_mult": 1.5, "move": 0.9, "pellets": 1, "range": 400.0, "scope": true, "bolt": true,
		"model": "sniper", "body": Color(0.42, 0.52, 0.36), "trim": Color(0.84, 0.66, 0.42), "sound": "sniper",
	},
	"shotgun": {
		"name": "Pump-12", "class": "Shotgun", "slot": 1,
		"damage": [26.0, 6.0], "falloff": [7.0, 20.0], "rpm": 70.0, "auto": false,
		"mag": 6, "reserve": 24, "reload": 3.2, "reload_empty": 3.6,
		"spread": [5.5, 4.0], "recoil": [2.6, 0.8], "ads_fov": 58.0, "ads_time": 0.22,
		"head_mult": 1.0, "move": 1.0, "pellets": 8, "range": 40.0, "pump": true,
		"model": "shotgun", "body": Color(0.42, 0.38, 0.36), "trim": Color(0.82, 0.54, 0.3), "sound": "shotgun",
	},
	"pistol": {
		"name": "M9", "class": "Pistol", "slot": 1,
		"damage": [40.0, 20.0], "falloff": [12.0, 30.0], "rpm": 400.0, "auto": false,
		"mag": 15, "reserve": 60, "reload": 1.6, "reload_empty": 2.0,
		"spread": [2.2, 0.3], "recoil": [1.1, 0.5], "ads_fov": 58.0, "ads_time": 0.15,
		"head_mult": 1.4, "move": 1.1, "pellets": 1, "range": 80.0,
		"model": "pistol", "body": Color(0.4, 0.42, 0.48), "trim": Color(0.7, 0.5, 0.3), "sound": "pistol",
	},
}

const CLASSES := [
	{"name": "Assault", "primary": "m4", "secondary": "pistol", "desc": "M4A1 + M9. Steady and accurate at every range."},
	{"name": "Raider", "primary": "ak", "secondary": "shotgun", "desc": "AK-47 + Pump-12. Hard-hitting, built for pushing."},
	{"name": "Rusher", "primary": "smg", "secondary": "pistol", "desc": "PDW-9 + M9. Fast hands, fast feet."},
	{"name": "Marksman", "primary": "sniper", "secondary": "pistol", "desc": "Longbow .50 + M9. One shot, one kill."},
]

const KNIFE_DAMAGE := 135.0
const KNIFE_RANGE := 2.2
const KNIFE_LUNGE := 3.6
const FRAG_DAMAGE := 150.0
const FRAG_RADIUS := 7.0
const FRAG_FUSE := 3.2


static func get_data(id: String) -> Dictionary:
	return DATA[id]


## Damage at a distance, including falloff.
static func damage_at(w: Dictionary, dist: float) -> float:
	var d: Array = w["damage"]
	var f: Array = w["falloff"]
	var t := clampf((dist - float(f[0])) / maxf(float(f[1]) - float(f[0]), 0.01), 0.0, 1.0)
	return lerpf(float(d[0]), float(d[1]), t)
