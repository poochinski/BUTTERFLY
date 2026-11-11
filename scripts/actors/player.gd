class_name Player
extends Soldier
## The person playing. Classic 2009-era multiplayer feel: snappy ground
## movement, limited sprint, crouch and prone, jump and mantle, aim down
## sights, recoil you pull against, knife lunge, cookable frags, and aim
## assist on gamepad.

signal hit_confirmed(headshot: bool, kill: bool)
signal streak_used(kind: String)
signal ammo_scavenged(amount: int)

const WALK := 4.8
const SPRINT_MULT := 1.5
const CROUCH_MULT := 0.6
const PRONE_MULT := 0.22
const ADS_MULT := 0.55
const GRAVITY := 18.0
const JUMP_V := 6.0
const ACCEL := 50.0
const AIR_ACCEL := 7.0
## Stopping is snappier than starting, as in classic shooters.
const DECEL := 70.0
const SPRINT_TIME := 4.0
const VM_FOV := 60.0

var camera: Camera3D
var head_pivot: Node3D
var vm: Viewmodel
var yaw := 0.0
var ads := 0.0
var sprinting := false
var stamina := SPRINT_TIME
var input_locked := false

var _look_delta := Vector2.ZERO
var _sprint_out := 0.0
var _eye := 1.62
var _swap_pending := -1
var _swap_t := 0.0
var _knife_cd := 0.0
var _knife_hit_t := -1.0
var _knife_target: Soldier
var _cook := -1.0
var _was_on_floor := true
var _fall_speed := 0.0
var _mantle_t := -1.0
var _mantle_from := Vector3.ZERO
var _mantle_to := Vector3.ZERO
var _crouch_hold := 0.0
var _recoil_vis := 0.0
var _ads_was := false
var _assist_t := 0.0
var _assist_target := Vector2.ZERO
var _semi_queued := false
## The dropped weapon we're standing over (if it isn't one we carry).
var near_pickup: WeaponPickup
var use_hold := 0.0
const USE_HOLD_TIME := 0.35


func _ready() -> void:
	super._ready()
	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, EYES[0], 0)
	add_child(head_pivot)
	camera = Camera3D.new()
	camera.fov = Game.fov()
	camera.near = 0.03
	camera.far = 900.0
	head_pivot.add_child(camera)
	camera.make_current()
	vm = Viewmodel.new()
	camera.add_child(vm)
	if not weapons.is_empty():
		vm.set_weapon(weapon().id, team_color(), weapon().att)
	model.set_shadow_only(true)


func _build_loadout() -> void:
	super._build_loadout()
	if vm:
		vm.set_weapon(weapon().id, team_color(), weapon().att)


func respawn(at: Transform3D) -> void:
	super.respawn(at)
	yaw = at.basis.get_euler().y
	aim_pitch = 0.0
	rotation = Vector3(0, yaw, 0)
	stamina = SPRINT_TIME
	ads = 0.0
	_cook = -1.0
	_swap_pending = -1
	_mantle_t = -1.0
	# The death cam moves and turns the camera; put it back exactly.
	camera.transform = Transform3D.IDENTITY
	camera.fov = Game.fov()
	head_pivot.rotation = Vector3.ZERO
	camera.make_current()
	model.set_shadow_only(true)
	vm.visible = true
	# Bring the gun up into view on spawn.
	vm._swap = 1.0
	vm.raise()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked or not alive:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := 0.0022 * float(Game.settings["sensitivity"]) * _zoom_sens()
		var inv := -1.0 if bool(Game.settings["invert_y"]) else 1.0
		yaw -= event.relative.x * sens
		aim_pitch = clampf(aim_pitch - event.relative.y * sens * inv, -1.45, 1.45)
		_look_delta += event.relative
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _zoom_sens() -> float:
	var w := weapon().data
	var ads_fov := float(w["ads_fov"])
	var base := Game.fov()
	return lerpf(1.0, tan(deg_to_rad(ads_fov) * 0.5) / tan(deg_to_rad(base) * 0.5), ads) if ads > 0.0 else 1.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not alive:
		return
	var locked := input_locked
	_gamepad_look(delta, locked)
	_handle_stance(delta, locked)
	_handle_movement(delta, locked)
	_handle_weapons(delta, locked)
	_update_camera(delta)


func _gamepad_look(delta: float, locked: bool) -> void:
	if locked:
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look.length() < 0.01 and _assist_t <= 0.0:
		return
	# Response curve: precise near the centre, fast at the edges.
	var mag := pow(look.length(), 1.8)
	var dir := look.normalized() if look.length() > 0.0 else Vector2.ZERO
	var speed := Vector2(4.2, 2.6) * float(Game.settings["sensitivity"]) * _zoom_sens()
	var slow := 1.0
	if _enemy_near_crosshair(4.0) != null:
		slow = 0.45
	var inv := -1.0 if bool(Game.settings["invert_y"]) else 1.0
	yaw -= dir.x * mag * speed.x * delta * slow
	aim_pitch = clampf(aim_pitch - dir.y * mag * speed.y * delta * slow * inv, -1.45, 1.45)
	_look_delta += dir * mag * 600.0 * delta
	if _assist_t > 0.0:
		_assist_t -= delta
		yaw = lerp_angle(yaw, _assist_target.x, minf(delta * 14.0, 1.0))
		aim_pitch = lerpf(aim_pitch, _assist_target.y, minf(delta * 14.0, 1.0))


func _handle_stance(delta: float, locked: bool) -> void:
	if locked:
		return
	if Input.is_action_just_pressed("crouch"):
		_crouch_hold = 0.0
		if stance == Stance.CROUCH:
			set_stance(Stance.STAND)
		elif stance == Stance.PRONE:
			set_stance(Stance.CROUCH)
		else:
			set_stance(Stance.CROUCH)
		sprinting = false
	if Input.is_action_pressed("crouch"):
		_crouch_hold += delta
		if _crouch_hold > 0.35 and _crouch_hold - delta <= 0.35 and stance != Stance.PRONE:
			set_stance(Stance.PRONE)
	if Input.is_action_just_pressed("prone"):
		set_stance(Stance.STAND if stance == Stance.PRONE else Stance.PRONE)
		sprinting = false


func _handle_movement(delta: float, locked: bool) -> void:
	if _mantle_t >= 0.0:
		_mantle_t += delta / 0.38
		var t := clampf(_mantle_t, 0.0, 1.0)
		var up := smoothstep(0.0, 0.6, t)
		var fwd := smoothstep(0.4, 1.0, t)
		global_position = Vector3(lerpf(_mantle_from.x, _mantle_to.x, fwd), lerpf(_mantle_from.y, _mantle_to.y, up), lerpf(_mantle_from.z, _mantle_to.z, fwd))
		velocity = Vector3.ZERO
		if _mantle_t >= 1.0:
			_mantle_t = -1.0
		return

	var iv := Vector2.ZERO if locked else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	rotation.y = yaw
	var basis_y := Basis(Vector3.UP, yaw)
	var wish := basis_y * Vector3(iv.x, 0, iv.y)

	# Sprint: forward only, standing, not aiming; limited stamina.
	var want_sprint := not locked and Input.is_action_pressed("sprint") and iv.y < -0.5 and is_on_floor()
	if Input.is_action_just_pressed("sprint") and stance != Stance.STAND and iv.y < -0.5:
		set_stance(Stance.STAND)
	if want_sprint and stance == Stance.STAND and ads < 0.3 and stamina > 0.0:
		if not sprinting:
			weapon().cancel_reload()
			vm.cancel_reload()
		sprinting = true
	elif sprinting and (not want_sprint or stamina <= 0.0):
		sprinting = false
		_sprint_out = 0.22
	if Game.input_mode == Game.InputMode.GAMEPAD and sprinting and iv.length() < 0.4:
		sprinting = false
	if sprinting:
		stamina = maxf(0.0, stamina - delta)
	else:
		stamina = minf(SPRINT_TIME, stamina + delta * 0.5)
		_sprint_out = maxf(0.0, _sprint_out - delta)

	var speed := WALK * float(weapon().data["move"])
	match stance:
		Stance.CROUCH:
			speed *= CROUCH_MULT
		Stance.PRONE:
			speed *= PRONE_MULT
	speed *= lerpf(1.0, ADS_MULT, ads)
	if sprinting:
		speed *= SPRINT_MULT
	var target := wish * speed
	var hv := Vector3(velocity.x, 0, velocity.z)
	var acc := ACCEL if is_on_floor() else AIR_ACCEL
	if is_on_floor() and target.length() < hv.length() - 0.05:
		acc = DECEL
	hv = hv.move_toward(target, acc * delta)
	velocity.x = hv.x
	velocity.z = hv.z

	if is_on_floor():
		if not locked and Input.is_action_just_pressed("jump"):
			if stance == Stance.PRONE:
				set_stance(Stance.CROUCH)
			elif stance == Stance.CROUCH:
				set_stance(Stance.STAND)
			elif not _try_mantle():
				velocity.y = JUMP_V
				Sfx.play_3d("jump", global_position, -6.0)
	else:
		velocity.y -= GRAVITY * delta
		if not locked and Input.is_action_just_pressed("jump"):
			_try_mantle()
		_fall_speed = maxf(_fall_speed, -velocity.y)
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		vm.land(_fall_speed / 10.0)
		_land_dip = clampf(_fall_speed / 10.0, 0.0, 1.0) * 0.14
		if _fall_speed > 11.0:
			take_damage((_fall_speed - 11.0) * 9.0, self, "fall", false, Vector3.DOWN)
		if _fall_speed > 3.0:
			Sfx.play_3d("land", global_position, -4.0)
		_fall_speed = 0.0
	_was_on_floor = is_on_floor()
	_footsteps(delta, hv.length())


var _step_t := 0.0


func _footsteps(delta: float, speed: float) -> void:
	if not is_on_floor() or speed < 1.0:
		return
	_step_t += delta * speed * (0.42 if not sprinting else 0.36)
	if _step_t > 1.0:
		_step_t = 0.0
		var vol := -17.0 if stance == Stance.STAND else -25.0
		if sprinting:
			vol += 3.0
		Sfx.play_ui("step%d" % (randi() % 4), vol)


## Climb over low walls and onto ledges up to chest height.
func _try_mantle() -> bool:
	var space := get_world_3d().direct_space_state
	var fwd := -global_transform.basis.z
	var chest := global_position + Vector3(0, 0.9, 0)
	var q := PhysicsRayQueryParameters3D.create(chest, chest + fwd * 0.75, 1)
	q.exclude = [get_rid()]
	if space.intersect_ray(q).is_empty():
		var knee := global_position + Vector3(0, 0.5, 0)
		var q2 := PhysicsRayQueryParameters3D.create(knee, knee + fwd * 0.75, 1)
		q2.exclude = [get_rid()]
		if space.intersect_ray(q2).is_empty():
			return false
	var above := global_position + fwd * 0.75 + Vector3(0, 1.6, 0)
	var down := PhysicsRayQueryParameters3D.create(above, above + Vector3(0, -1.6, 0), 1)
	var hit := space.intersect_ray(down)
	if hit.is_empty():
		return false
	var top: Vector3 = hit["position"]
	var h := top.y - global_position.y
	if h < 0.4 or h > 1.45:
		return false
	var clear := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = RADIUS
	cap.height = 1.25
	clear.shape = cap
	clear.transform = Transform3D(Basis(), top + Vector3(0, 0.7, 0))
	clear.collision_mask = 1
	if not space.intersect_shape(clear, 1).is_empty():
		set_stance(Stance.CROUCH)
	_mantle_from = global_position
	_mantle_to = top + Vector3(0, 0.02, 0) + fwd * 0.15
	_mantle_t = 0.0
	sprinting = false
	vm.land(0.6)
	Sfx.play_3d("mantle", global_position, -6.0)
	return true


func _handle_weapons(delta: float, locked: bool) -> void:
	var w := weapon()
	_knife_cd = maxf(0.0, _knife_cd - delta)
	if _update_pickups(delta, locked):
		return

	# Aim down sights.
	var want_ads := not locked and Input.is_action_pressed("ads") and not sprinting and _swap_pending < 0 and _knife_hit_t < 0.0
	var ads_speed := 1.0 / float(w.data["ads_time"])
	ads = move_toward(ads, 1.0 if want_ads else 0.0, delta * ads_speed)
	if want_ads and not _ads_was and Game.input_mode == Game.InputMode.GAMEPAD:
		_start_ads_assist()
	_ads_was = want_ads

	# Swapping weapons.
	if _swap_pending >= 0:
		_swap_t += delta
		if _swap_t > 0.28 and current != _swap_pending:
			switch_weapon(_swap_pending)
			vm.set_weapon(weapon().id, team_color(), weapon().att)
			vm.lower()
			vm._swap = 1.0
			vm.raise()
		if _swap_t > 0.6:
			_swap_pending = -1
		return
	if not locked and (Input.is_action_just_pressed("switch_weapon") or Input.is_action_just_pressed("weapon_1") and current != 0 or Input.is_action_just_pressed("weapon_2") and current != 1):
		var target := 1 - current
		if Input.is_action_just_pressed("weapon_1"):
			target = 0
		elif Input.is_action_just_pressed("weapon_2"):
			target = 1
		_swap_pending = target
		_swap_t = 0.0
		vm.cancel_reload()
		vm.lower()
		Sfx.play_ui("swap")
		return

	# Knife lunge.
	if _knife_hit_t >= 0.0:
		_knife_hit_t += delta
		if _knife_target and _knife_target.alive:
			var to := _knife_target.global_position - global_position
			to.y = 0.0
			if to.length() > 1.1:
				velocity = to.normalized() * 14.0
				move_and_slide()
		if _knife_hit_t > 0.14:
			if _knife_target and _knife_target.alive and _knife_target.global_position.distance_to(global_position) < WeaponDB.KNIFE_RANGE + 0.6:
				Combat.melee(self, _knife_target)
				Sfx.play_3d("knife_hit", global_position, 0.0)
			_knife_hit_t = -1.0
			_knife_target = null
		return
	if not locked and Input.is_action_just_pressed("melee") and _knife_cd <= 0.0:
		_knife_cd = 0.9
		sprinting = false
		w.cancel_reload()
		vm.cancel_reload()
		vm.start_knife()
		Sfx.play_3d("knife", global_position, -2.0)
		_knife_target = knife_target(camera.global_position, -camera.global_transform.basis.z)
		_knife_hit_t = 0.0
		return

	# Frag: hold to cook, release to throw.
	if not locked and Input.is_action_just_pressed("frag") and frags > 0 and _cook < 0.0:
		_cook = 0.0
		Sfx.play_3d("pin", global_position, -4.0)
		w.cancel_reload()
		vm.cancel_reload()
	if _cook >= 0.0:
		_cook += delta
		if _cook >= WeaponDB.FRAG_FUSE:
			_cook = -1.0
			frags -= 1
			Combat.explode(global_position + Vector3(0, 1.0, 0), self, WeaponDB.FRAG_RADIUS, WeaponDB.FRAG_DAMAGE)
			return
		if locked or not Input.is_action_pressed("frag"):
			vm.start_throw()
			throw_frag(camera.global_position, -camera.global_transform.basis.z, WeaponDB.FRAG_FUSE - _cook)
			_cook = -1.0
		return

	# Reloading.
	var reload_pressed := Input.is_action_just_pressed("reload")
	if near_pickup and Game.input_mode == Game.InputMode.GAMEPAD:
		# Tap X reloads, hold X swaps: decide on release.
		reload_pressed = Input.is_action_just_released("use") and use_hold < USE_HOLD_TIME
	if not locked and reload_pressed and w.can_reload():
		w.start_reload()
		vm.start_reload(w.reload_total, w.mag <= 0)
		sprinting = false
		Sfx.play_3d("reload", global_position, -4.0)

	# Firing.
	var pressed := not locked and Input.is_action_pressed("fire")
	var just := not locked and Input.is_action_just_pressed("fire")
	if just:
		_semi_queued = true
	if (pressed or _semi_queued) and sprinting:
		sprinting = false
		_sprint_out = 0.18
	if _sprint_out > 0.0 or vm.is_lowered():
		return
	var wants := pressed if w.is_auto() else _semi_queued
	if wants:
		if w.mag <= 0:
			if just:
				Sfx.play_3d("dry", global_position, -4.0)
				if w.can_reload():
					w.start_reload()
					vm.start_reload(w.reload_total, w.mag <= 0)
					Sfx.play_3d("reload", global_position, -4.0)
			_semi_queued = false
		elif w.can_fire():
			_semi_queued = false
			_fire_once(w)
	if w.mag <= 0 and w.reloading <= 0.0 and w.can_reload() and w.cooldown <= 0.0:
		w.start_reload()
		vm.start_reload(w.reload_total, w.mag <= 0)
		Sfx.play_3d("reload", global_position, -4.0)


## Scavenge ammo from matching guns; hold Use to swap for a different one.
## Returns true while a swap is in progress (blocks other weapon input).
func _update_pickups(delta: float, locked: bool) -> bool:
	near_pickup = null
	var best_d := WeaponPickup.REACH
	for n in get_tree().get_nodes_in_group("pickups"):
		var pk: WeaponPickup = n
		var d := Vector2(pk.global_position.x - global_position.x, pk.global_position.z - global_position.z).length()
		if d > WeaponPickup.REACH or absf(pk.global_position.y - global_position.y) > 1.5:
			continue
		var carried := -1
		for i in weapons.size():
			if weapons[i].id == pk.weapon_id:
				carried = i
		if carried >= 0:
			var cw := weapons[carried]
			var cap := int(cw.data["reserve"])
			if cw.reserve < cap and d < 1.3:
				var take := mini(cap - cw.reserve, pk.mag + pk.reserve)
				cw.reserve += take
				pk.queue_free()
				Sfx.play_ui("swap", -6.0)
				ammo_scavenged.emit(take)
			continue
		if d < best_d:
			best_d = d
			near_pickup = pk
	if near_pickup == null or locked:
		use_hold = 0.0
		return false
	if Input.is_action_pressed("use"):
		use_hold += delta
		if use_hold >= USE_HOLD_TIME:
			use_hold = 0.0
			_swap_to_pickup(near_pickup)
			return true
	else:
		use_hold = 0.0
	return false


func _swap_to_pickup(pk: WeaponPickup) -> void:
	var old := weapon()
	var drop := WeaponPickup.new()
	get_parent().add_child(drop)
	drop.setup(old.id, old.mag, old.reserve, global_position + (-global_transform.basis.z) * 0.6, team)
	var nw := Weapon.new(pk.weapon_id, pk.att)
	nw.mag = pk.mag
	nw.reserve = pk.reserve
	weapons[current] = nw
	pk.queue_free()
	near_pickup = null
	if model:
		model.set_weapon(nw.id, nw.att)
	vm.cancel_reload()
	vm.set_weapon(nw.id, team_color(), nw.att)
	vm._swap = 1.0
	vm.raise()
	ads = 0.0
	Sfx.play_ui("swap")


func _fire_once(w: Weapon) -> void:
	var origin := camera.global_position
	var dir := -camera.global_transform.basis.z
	var moving := clampf(Vector2(velocity.x, velocity.z).length() / WALK, 0.0, 1.0)
	var spread := current_spread(ads, moving, not is_on_floor())
	var muzzle := vm.muzzle()
	var res := fire_weapon(origin, dir, spread, muzzle)
	if res.is_empty():
		return
	var rec: Array = w.data["recoil"]
	var steady := lerpf(1.0, 0.65, ads) * (0.8 if stance != Stance.STAND else 1.0)
	aim_pitch = clampf(aim_pitch + deg_to_rad(float(rec[0])) * steady, -1.45, 1.45)
	yaw += deg_to_rad(randf_range(-float(rec[1]), float(rec[1]))) * steady
	_recoil_vis = minf(_recoil_vis + float(rec[0]) * 0.02, 0.08)
	vm.kick(clampf(float(rec[0]) / 1.2, 0.4, 2.0))
	vm.fired(w.mag <= 0)
	Fx.muzzle_flash(muzzle, true)
	if bool(w.data.get("pump", false)) or bool(w.data.get("bolt", false)):
		Sfx.play_3d("pump", global_position, -6.0)


var _cam_bob := 0.0
var _land_dip := 0.0


func _update_camera(delta: float) -> void:
	_eye = lerpf(_eye, eye_height(), 1.0 - exp(-12.0 * delta))
	# A gentle head bob while moving (settles when aiming) and a dip on
	# landing that springs back.
	var hs0 := Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		_cam_bob += delta * hs0 * (1.05 if sprinting else 1.2)
	var bob_amt := clampf(hs0 / WALK, 0.0, 1.6) * (1.0 - ads * 0.85) * (1.0 if is_on_floor() else 0.0)
	var bob_y := (absf(sin(_cam_bob * PI)) - 0.5) * 0.03 * bob_amt
	var bob_x := sin(_cam_bob * PI) * 0.014 * bob_amt
	_land_dip = lerpf(_land_dip, 0.0, 1.0 - exp(-7.0 * delta))
	head_pivot.position = Vector3(bob_x, _eye + bob_y - _land_dip, head_pivot.position.z)
	_recoil_vis = move_toward(_recoil_vis, 0.0, delta * 0.4)
	head_pivot.rotation.x = aim_pitch + _recoil_vis
	# Sprinting gently tilts the view; strafing leans it a touch.
	var side := Vector3(velocity.x, 0, velocity.z).dot(global_transform.basis.x)
	head_pivot.rotation.z = lerpf(head_pivot.rotation.z, -side * 0.006 + sin(_cam_bob * PI) * 0.004 * bob_amt, minf(delta * 8.0, 1.0))
	var w := weapon().data
	var base := Game.fov()
	var target_fov := lerpf(base, float(w["ads_fov"]), ads)
	if sprinting:
		target_fov += 4.0
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-18.0 * delta))
	var vm_fov := lerpf(VM_FOV, VM_FOV - 8.0, ads)
	RenderingServer.global_shader_parameter_set("vm_fov_scale", tan(deg_to_rad(camera.fov) * 0.5) / tan(deg_to_rad(vm_fov) * 0.5))
	var scoped := bool(w.get("scope", false)) and ads > 0.85
	vm.visible = not scoped
	var hs := Vector2(velocity.x, velocity.z).length()
	var crouch := 1.0 if stance != Stance.STAND else 0.0
	vm.animate(delta, _look_delta, hs, is_on_floor(), ads, 1.0 if sprinting else 0.0, crouch)
	_look_delta = Vector2.ZERO
	if model:
		model.animate(delta, hs, stance, aim_pitch, sprinting)


func is_scoped() -> bool:
	return bool(weapon().data.get("scope", false)) and ads > 0.85


func on_hit_confirm(headshot: bool, kill: bool) -> void:
	hit_confirmed.emit(headshot, kill)
	Sfx.play_ui("hitmarker" if not kill else "hit_kill")


func cooking() -> float:
	return _cook


# ----------------------------------------------------------- aim assist

func _enemy_near_crosshair(max_deg: float) -> Soldier:
	var fwd := -camera.global_transform.basis.z
	var origin := camera.global_position
	var best: Soldier = null
	var best_a := deg_to_rad(max_deg)
	for s in get_tree().get_nodes_in_group("soldiers"):
		var o: Soldier = s
		if o == self or not o.alive or o.team == team:
			continue
		var to := o.center_position() - origin
		var d := to.length()
		if d > 70.0:
			continue
		var a := fwd.angle_to(to)
		var allowance := best_a + atan(0.5 / maxf(d, 0.5))
		if a < allowance:
			var q := PhysicsRayQueryParameters3D.create(origin, o.center_position(), 1)
			if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				best = o
				best_a = a
	return best


func _start_ads_assist() -> void:
	var t := _enemy_near_crosshair(9.0)
	if t == null:
		return
	var to := t.center_position() + Vector3(0, 0.2, 0) - camera.global_position
	_assist_target = Vector2(atan2(-to.x, -to.z), atan2(to.y, Vector2(to.x, to.z).length()))
	_assist_t = 0.15
