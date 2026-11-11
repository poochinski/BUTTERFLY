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
## body / trim: the replica's finish (receiver paint, furniture); wood: the
## furniture is wood-grained card instead of painted polymer.

const DATA := {
	"m4": {
		"name": "M4A1", "class": "Assault Rifle", "slot": 0,
		"damage": [30.0, 20.0], "falloff": [25.0, 50.0], "rpm": 780.0, "auto": true,
		"mag": 30, "reserve": 150, "reload": 2.2, "reload_empty": 2.8,
		"spread": [3.2, 0.12], "recoil": [0.55, 0.32], "ads_fov": 50.0, "ads_time": 0.24,
		"head_mult": 1.4, "move": 1.0, "pellets": 1, "range": 200.0,
		"model": "rifle", "body": Color(0.19, 0.19, 0.2), "trim": Color(0.47, 0.41, 0.31), "sound": "rifle",
	},
	"ak": {
		"name": "AK-47", "class": "Assault Rifle", "slot": 0,
		"damage": [40.0, 30.0], "falloff": [20.0, 45.0], "rpm": 600.0, "auto": true,
		"mag": 30, "reserve": 150, "reload": 2.4, "reload_empty": 3.0,
		"spread": [3.6, 0.15], "recoil": [0.8, 0.5], "ads_fov": 50.0, "ads_time": 0.27,
		"head_mult": 1.4, "move": 0.95, "pellets": 1, "range": 200.0,
		"model": "ak", "body": Color(0.23, 0.23, 0.24), "trim": Color(0.38, 0.2, 0.1), "wood": true, "sound": "rifle_heavy",
	},
	"smg": {
		"name": "PDW-9", "class": "Submachine Gun", "slot": 0,
		"damage": [35.0, 18.0], "falloff": [10.0, 25.0], "rpm": 950.0, "auto": true,
		"mag": 32, "reserve": 160, "reload": 1.9, "reload_empty": 2.4,
		"spread": [2.4, 0.2], "recoil": [0.42, 0.42], "ads_fov": 55.0, "ads_time": 0.18,
		"head_mult": 1.25, "move": 1.07, "pellets": 1, "range": 120.0,
		"model": "smg", "body": Color(0.18, 0.18, 0.19), "trim": Color(0.25, 0.26, 0.27), "sound": "smg",
	},
	"sniper": {
		"name": "Longbow .50", "class": "Sniper Rifle", "slot": 0,
		"damage": [98.0, 98.0], "falloff": [500.0, 600.0], "rpm": 48.0, "auto": false,
		"mag": 5, "reserve": 25, "reload": 3.0, "reload_empty": 3.6,
		"spread": [9.0, 0.0], "recoil": [3.5, 0.6], "ads_fov": 16.0, "ads_time": 0.38,
		"head_mult": 1.5, "chest_mult": 1.5, "move": 0.9, "pellets": 1, "range": 400.0, "scope": true, "bolt": true,
		"model": "sniper", "body": Color(0.18, 0.18, 0.19), "trim": Color(0.27, 0.3, 0.2), "sound": "sniper",
	},
	"shotgun": {
		"name": "Pump-12", "class": "Shotgun", "slot": 1,
		"damage": [26.0, 6.0], "falloff": [7.0, 20.0], "rpm": 70.0, "auto": false,
		"mag": 6, "reserve": 24, "reload": 3.2, "reload_empty": 3.6,
		"spread": [5.5, 4.0], "recoil": [2.6, 0.8], "ads_fov": 58.0, "ads_time": 0.22,
		"head_mult": 1.0, "move": 1.0, "pellets": 8, "range": 40.0, "pump": true,
		"model": "shotgun", "body": Color(0.19, 0.19, 0.2), "trim": Color(0.36, 0.21, 0.11), "wood": true, "sound": "shotgun",
	},
	"pistol": {
		"name": "M9", "class": "Pistol", "slot": 1,
		"damage": [40.0, 20.0], "falloff": [12.0, 30.0], "rpm": 400.0, "auto": false,
		"mag": 15, "reserve": 60, "reload": 1.6, "reload_empty": 2.0,
		"spread": [2.2, 0.3], "recoil": [1.1, 0.5], "ads_fov": 58.0, "ads_time": 0.15,
		"head_mult": 1.4, "move": 1.1, "pellets": 1, "range": 80.0,
		"model": "pistol", "body": Color(0.2, 0.2, 0.21), "trim": Color(0.13, 0.13, 0.14), "sound": "pistol",
	},
	"lmg": {
		"name": "M249 SAW", "class": "Light Machine Gun", "slot": 0,
		"damage": [32.0, 24.0], "falloff": [30.0, 60.0], "rpm": 750.0, "auto": true,
		"mag": 100, "reserve": 200, "reload": 5.2, "reload_empty": 6.0,
		"spread": [4.6, 0.25], "recoil": [0.42, 0.42], "ads_fov": 50.0, "ads_time": 0.4,
		"head_mult": 1.4, "move": 0.86, "pellets": 1, "range": 220.0,
		"model": "lmg", "body": Color(0.17, 0.17, 0.18), "trim": Color(0.3, 0.32, 0.25), "sound": "rifle_heavy",
	},
	"dmr": {
		"name": "Mk 14 EBR", "class": "Marksman Rifle", "slot": 0,
		"damage": [55.0, 45.0], "falloff": [40.0, 80.0], "rpm": 480.0, "auto": false,
		"mag": 20, "reserve": 80, "reload": 2.6, "reload_empty": 3.2,
		"spread": [4.2, 0.08], "recoil": [1.5, 0.4], "ads_fov": 42.0, "ads_time": 0.3,
		"head_mult": 1.5, "move": 0.94, "pellets": 1, "range": 300.0,
		"model": "dmr", "body": Color(0.19, 0.19, 0.2), "trim": Color(0.47, 0.41, 0.31), "sound": "rifle_heavy",
	},
	"revolver": {
		"name": ".44 Magnum", "class": "Revolver", "slot": 1,
		"damage": [62.0, 36.0], "falloff": [14.0, 32.0], "rpm": 150.0, "auto": false,
		"mag": 6, "reserve": 30, "reload": 2.6, "reload_empty": 2.6,
		"spread": [2.6, 0.4], "recoil": [2.8, 0.7], "ads_fov": 56.0, "ads_time": 0.18,
		"head_mult": 1.4, "move": 1.08, "pellets": 1, "range": 90.0,
		"model": "revolver", "body": Color(0.24, 0.24, 0.26), "trim": Color(0.36, 0.21, 0.11), "wood": true, "sound": "sniper",
	},
}

## Attachments: id -> display name. Each gun takes one.
const ATTACH := {
	"reddot": "Red Dot Sight", "holo": "Holographic Sight", "acog": "ACOG Scope",
	"suppressor": "Suppressor", "grip": "Foregrip", "extmag": "Extended Mags",
}
## Which attachments each gun takes, and the weapon kills that unlock them.
const ATTACHMENTS := {
	"m4": [["reddot", 0], ["holo", 5], ["suppressor", 10], ["grip", 20], ["acog", 30], ["extmag", 45]],
	"ak": [["reddot", 5], ["grip", 10], ["holo", 15], ["suppressor", 25], ["acog", 35], ["extmag", 50]],
	"smg": [["holo", 0], ["reddot", 5], ["suppressor", 10], ["extmag", 20], ["grip", 30]],
	"lmg": [["reddot", 5], ["grip", 10], ["holo", 20], ["acog", 30], ["suppressor", 45]],
	"dmr": [["reddot", 5], ["acog", 10], ["suppressor", 20], ["extmag", 30]],
	"sniper": [["suppressor", 10], ["extmag", 20]],
	"shotgun": [["grip", 5], ["reddot", 10], ["extmag", 20]],
	"pistol": [["suppressor", 5], ["extmag", 15]],
	"revolver": [],
}
## The player level that unlocks each gun for Create-a-Class.
const UNLOCK_LEVEL := {"m4": 1, "smg": 1, "pistol": 1, "shotgun": 2, "ak": 4, "revolver": 6, "sniper": 8, "lmg": 10, "dmr": 13}

const CLASSES := [
	{"name": "Assault", "primary": "m4", "p_att": "reddot", "secondary": "pistol", "s_att": "", "desc": "M4A1 Red Dot + M9. Steady and accurate at every range."},
	{"name": "Raider", "primary": "ak", "p_att": "", "secondary": "shotgun", "s_att": "", "desc": "AK-47 + Pump-12. Hard-hitting, built for pushing."},
	{"name": "Rusher", "primary": "smg", "p_att": "holo", "secondary": "pistol", "s_att": "", "desc": "PDW-9 Holo + M9. Fast hands, fast feet."},
	{"name": "Marksman", "primary": "sniper", "p_att": "", "secondary": "pistol", "s_att": "", "desc": "Longbow .50 + M9. One shot, one kill."},
]
## Extra loadouts only bots draw from (players build their own).
const BOT_CLASSES := [
	{"name": "Gunner", "primary": "lmg", "p_att": "", "secondary": "pistol", "s_att": ""},
	{"name": "Sharpshooter", "primary": "dmr", "p_att": "acog", "secondary": "revolver", "s_att": ""},
]

const KNIFE_DAMAGE := 135.0
const KNIFE_RANGE := 2.2
const KNIFE_LUNGE := 3.6
const FRAG_DAMAGE := 150.0
const FRAG_RADIUS := 7.0
const FRAG_FUSE := 3.2


static func get_data(id: String) -> Dictionary:
	return DATA[id]


## A gun's stats with one attachment fitted.
static func with_attachment(id: String, att: String) -> Dictionary:
	var d: Dictionary = DATA[id].duplicate(true)
	d["att"] = att
	match att:
		"extmag":
			d["mag"] = int(d["mag"]) + maxi(int(int(d["mag"]) * 0.5), 2)
			d["reserve"] = int(d["reserve"]) + int(d["mag"])
		"grip":
			var rec: Array = d["recoil"]
			d["recoil"] = [float(rec[0]) * 0.65, float(rec[1]) * 0.55]
			var sp: Array = d["spread"]
			d["spread"] = [float(sp[0]) * 0.85, float(sp[1])]
		"suppressor":
			d["suppressed"] = true
			var fo: Array = d["falloff"]
			d["falloff"] = [float(fo[0]) * 0.8, float(fo[1]) * 0.8]
		"acog":
			d["ads_fov"] = 30.0
			d["ads_time"] = float(d["ads_time"]) + 0.05
		"reddot", "holo":
			d["ads_fov"] = float(d["ads_fov"]) - 3.0
	return d


static func attachment_kills(id: String, att: String) -> int:
	for a: Array in ATTACHMENTS.get(id, []):
		if a[0] == att:
			return int(a[1])
	return 0


## Damage at a distance, including falloff.
static func damage_at(w: Dictionary, dist: float) -> float:
	var d: Array = w["damage"]
	var f: Array = w["falloff"]
	var t := clampf((dist - float(f[0])) / maxf(float(f[1]) - float(f[0]), 0.01), 0.0, 1.0)
	return lerpf(float(d[0]), float(d[1]), t)
