class_name WeaponPickup
extends Node3D
## A weapon lying on the ground where its owner fell. Walk over a matching
## gun to scavenge ammo, or hold Use to swap it for the one in your hands.

const LIFETIME := 35.0
const REACH := 1.9

var weapon_id := ""
var att := ""
var mag := 0
var reserve := 0
var _life := LIFETIME
var _model: Node3D
var _t := 0.0


func setup(id: String, m: int, r: int, pos: Vector3, team := 0, attachment := "") -> void:
	weapon_id = id
	att = attachment
	mag = m
	reserve = r
	add_to_group("pickups")
	_model = GunBuilder.build(id, false, Game.TEAM_COLORS[team], att)
	add_child(_model)
	_model.scale = Vector3.ONE * 1.15
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 1.0, 0), pos + Vector3(0, -3.0, 0), 1)
	var hit := space.intersect_ray(q)
	var ground: Vector3 = hit["position"] if not hit.is_empty() else pos
	global_position = ground + Vector3(0, 0.05, 0)
	# Lie on its side, at a random angle, as if dropped.
	_model.rotation = Vector3(0, randf() * TAU, PI * 0.5)
	_model.position = Vector3(0, 0.04, 0)


func display_name() -> String:
	return String(WeaponDB.DATA[weapon_id]["name"]) + (" + " + String(WeaponDB.ATTACH[att]) if att != "" else "")


func _process(delta: float) -> void:
	_life -= delta
	_t += delta
	if _life <= 0.0:
		queue_free()
		return
	if _life < 4.0:
		visible = fmod(_life, 0.4) > 0.15
