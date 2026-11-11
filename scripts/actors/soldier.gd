class_name Soldier
extends CharacterBody3D
## Everything a combatant has in common, whether a person or a bot drives
## it: health and regeneration, stance, the loadout, firing, knifing,
## grenades, taking damage, dying in a puff of confetti, and respawning.

signal died(victim: Soldier, killer: Soldier, weapon_id: String, headshot: bool)
signal damaged(amount: float, from_dir: Vector3)
signal fired(soldier: Soldier)

enum Stance { STAND, CROUCH, PRONE }

const HEIGHTS := [1.8, 1.25, 0.6]
const EYES := [1.62, 1.05, 0.42]
const RADIUS := 0.35
const MAX_HEALTH := 100.0
const REGEN_DELAY := 5.0
const REGEN_RATE := 40.0

var team := 0
var display_name := "Soldier"
var class_index := 0
var health := MAX_HEALTH
var alive := true
var stance: int = Stance.STAND
var weapons: Array[Weapon] = []
var current := 0
var frags := 2
var kills := 0
var deaths := 0
var assists := 0
var score := 0
var streak := 0
var aim_pitch := 0.0
var model: SoldierModel
var last_attacker: Soldier
var attackers := {}

var _shape: CollisionShape3D
var _capsule: CapsuleShape3D
var _regen_wait := 0.0
var _spawn_protect := 0.0


func _ready() -> void:
	add_to_group("soldiers")
	collision_layer = 2
	collision_mask = 1 | 2
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.45
	_capsule = CapsuleShape3D.new()
	_capsule.radius = RADIUS
	_shape = CollisionShape3D.new()
	_shape.shape = _capsule
	add_child(_shape)
	_apply_stance_shape()
	model = SoldierModel.new()
	model.team = team
	add_child(model)
	if not weapons.is_empty():
		model.set_weapon(weapon().id, weapon().att)


func setup(t: int, nm: String, cls: int) -> void:
	team = t
	display_name = nm
	class_index = cls
	_build_loadout()


func _build_loadout() -> void:
	var c: Dictionary
	if self is Player:
		c = Game.loadout(class_index)
	else:
		var pool: Array = WeaponDB.CLASSES + WeaponDB.BOT_CLASSES
		c = (pool[class_index % pool.size()] as Dictionary).duplicate()
		var opts: Array = WeaponDB.ATTACHMENTS.get(c["primary"], [])
		if not opts.is_empty() and randf() < 0.7:
			c["p_att"] = opts[randi() % opts.size()][0]
	weapons = [Weapon.new(c["primary"], String(c.get("p_att", ""))), Weapon.new(c["secondary"], String(c.get("s_att", "")))]
	current = 0
	frags = 2
	if model:
		model.set_weapon(weapon().id, weapon().att)


func team_color() -> Color:
	return Game.TEAM_COLORS[team]


func weapon() -> Weapon:
	return weapons[current]


func eye_height() -> float:
	return EYES[stance]


func eye_position() -> Vector3:
	return global_position + Vector3(0, eye_height(), 0)


func head_position() -> Vector3:
	if stance == Stance.PRONE:
		return global_position + Vector3(0, 0.35, 0) - global_transform.basis.z * 0.7
	return global_position + Vector3(0, HEIGHTS[stance] - 0.18, 0)


func center_position() -> Vector3:
	return global_position + Vector3(0, HEIGHTS[stance] * 0.55, 0)


func hit_zone(point: Vector3) -> String:
	if point.distance_to(head_position()) < 0.26:
		return "head"
	var y: float = (point.y - global_position.y) / float(HEIGHTS[stance])
	if stance != Stance.PRONE and y > 0.55:
		return "chest"
	return "body"


# ---------------------------------------------------------------- stance

func set_stance(s: int) -> bool:
	if s == stance:
		return true
	if s < stance and not _has_headroom(HEIGHTS[s]):
		return false
	stance = s
	_apply_stance_shape()
	return true


func _apply_stance_shape() -> void:
	var h: float = HEIGHTS[stance]
	_capsule.height = maxf(h, RADIUS * 2.0)
	_shape.position = Vector3(0, h * 0.5, 0)


func _has_headroom(h: float) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = RADIUS * 0.9
	cap.height = h
	q.shape = cap
	q.transform = Transform3D(Basis(), global_position + Vector3(0, h * 0.5 + 0.05, 0))
	q.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


# --------------------------------------------------------------- weapons

func switch_weapon(index: int) -> bool:
	if index == current or index < 0 or index >= weapons.size():
		return false
	weapon().cancel_reload()
	current = index
	if model:
		model.set_weapon(weapon().id, weapon().att)
	return true


## Spread in degrees given how steady the shooter is.
func current_spread(ads: float, moving: float, airborne: bool) -> float:
	var sp: Array = weapon().data["spread"]
	var hip := float(sp[0])
	if stance == Stance.CROUCH:
		hip *= 0.8
	elif stance == Stance.PRONE:
		hip *= 0.65
	hip *= 1.0 + moving * 0.4
	if airborne:
		hip *= 2.0
	return lerpf(hip, float(sp[1]) * (1.0 + moving * 0.5), ads)


## Pulls the trigger once. Returns the Combat result, or {} if it couldn't fire.
func fire_weapon(origin: Vector3, dir: Vector3, spread_deg: float, muzzle: Node3D) -> Dictionary:
	var w := weapon()
	if not alive or not w.can_fire():
		return {}
	w.consume()
	_spawn_protect = 0.0
	var res := Combat.fire(self, origin, dir, w, spread_deg, muzzle)
	var vol := (0.0 if self is Player else -2.0) - (16.0 if bool(w.data.get("suppressed", false)) else 0.0)
	Sfx.play_3d(String(w.data["sound"]), origin, vol)
	fired.emit(self)
	if model:
		model.kick()
	return res


## Knife target in front of us within lunge range, or null.
func knife_target(origin: Vector3, forward: Vector3) -> Soldier:
	var best: Soldier = null
	var best_d := WeaponDB.KNIFE_LUNGE
	var space := get_world_3d().direct_space_state
	for s in get_tree().get_nodes_in_group("soldiers"):
		var o: Soldier = s
		if o == self or not o.alive or o.team == team:
			continue
		var to := o.center_position() - origin
		var d := to.length()
		if d > best_d:
			continue
		if forward.dot(to.normalized()) < 0.75:
			continue
		var q := PhysicsRayQueryParameters3D.create(origin, o.center_position(), 1)
		if not space.intersect_ray(q).is_empty():
			continue
		best = o
		best_d = d
	return best


func throw_frag(origin: Vector3, dir: Vector3, fuse_left: float) -> void:
	if frags <= 0:
		return
	frags -= 1
	var g := Grenade.new()
	get_tree().current_scene.add_child(g)
	g.setup(self, origin + dir * 0.4, dir * 17.0 + Vector3(0, 3.0, 0) + velocity * 0.5, fuse_left)
	Sfx.play_3d("throw", origin, -2.0)


# ------------------------------------------------------------ damage

func take_damage(amount: float, attacker: Soldier, weapon_id: String, headshot: bool, from_dir: Vector3) -> void:
	if not alive:
		return
	if _spawn_protect > 0.0 and attacker != self:
		amount *= 0.25
	health -= amount
	_regen_wait = REGEN_DELAY
	if attacker and attacker != self:
		last_attacker = attacker
		attackers[attacker] = true
	damaged.emit(amount, from_dir)
	if attacker is Player and attacker != self:
		(attacker as Player).on_hit_confirm(headshot, health <= 0.0)
	if health <= 0.0:
		die(attacker, weapon_id, headshot)


func die(killer: Soldier, weapon_id: String, headshot: bool) -> void:
	if not alive:
		return
	alive = false
	health = 0.0
	velocity = Vector3.ZERO
	_shape.disabled = true
	deaths += 1
	streak = 0
	Sfx.play_3d("death", center_position(), 0.0)
	Fx.confetti(center_position(), [team_color(), team_color().darkened(0.35), Craft.CREAM, Craft.KRAFT], 70, 4.5)
	if model:
		model.play_death(headshot)
	died.emit(self, killer, weapon_id, headshot)


func respawn(at: Transform3D) -> void:
	global_transform = Transform3D(Basis(Vector3.UP, at.basis.get_euler().y), at.origin)
	alive = true
	health = MAX_HEALTH
	velocity = Vector3.ZERO
	_shape.disabled = false
	set_stance(Stance.STAND)
	stance = Stance.STAND
	_apply_stance_shape()
	aim_pitch = 0.0
	attackers.clear()
	last_attacker = null
	_spawn_protect = 1.5
	_build_loadout()
	for w in weapons:
		w.refill()
	if model:
		model.reset()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_spawn_protect = maxf(0.0, _spawn_protect - delta)
	_regen_wait -= delta
	if _regen_wait <= 0.0 and health < MAX_HEALTH:
		health = minf(MAX_HEALTH, health + REGEN_RATE * delta)
		if health >= MAX_HEALTH:
			attackers.clear()
	for i in weapons.size():
		var finished := weapons[i].tick(delta if i == current else 0.0)
		if finished and i == current:
			_on_reload_finished()


func _on_reload_finished() -> void:
	pass
