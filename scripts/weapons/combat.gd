class_name Combat
extends RefCounted
## Hitscan shooting, melee and explosions. All damage in the game flows
## through here so players and bots follow exactly the same rules.

const MASK_SHOTS := 1 | 2


## Fires one trigger pull. Returns { "hit": bool, "kill": bool, "head": bool }.
static func fire(shooter: Soldier, origin: Vector3, dir: Vector3, weapon: Weapon, spread_deg: float, muzzle: Node3D) -> Dictionary:
	var result := {"hit": false, "kill": false, "head": false}
	var w := weapon.data
	var space := shooter.get_world_3d().direct_space_state
	var pellets := int(w["pellets"])
	var rng_spread := deg_to_rad(spread_deg)
	var muzzle_pos := muzzle.global_position if muzzle and muzzle.is_inside_tree() else origin
	var damage_by_victim := {}
	var head_by_victim := {}
	for i in pellets:
		var d := _cone(dir, rng_spread)
		var q := PhysicsRayQueryParameters3D.create(origin, origin + d * float(w["range"]), MASK_SHOTS, [shooter.get_rid()])
		var hit := space.intersect_ray(q)
		var end := origin + d * float(w["range"])
		if hit.is_empty():
			if i < 2:
				Fx.tracer(muzzle_pos, end)
			continue
		end = hit["position"]
		if i < 2:
			Fx.tracer(muzzle_pos, end)
		var col = hit["collider"]
		if col is Soldier:
			var victim: Soldier = col
			if not victim.alive:
				continue
			var dist := origin.distance_to(end)
			var dmg := WeaponDB.damage_at(w, dist)
			var zone := victim.hit_zone(end)
			if zone == "head":
				dmg *= float(w.get("head_mult", 1.0))
				head_by_victim[victim] = true
			elif zone == "chest":
				dmg *= float(w.get("chest_mult", 1.0))
			damage_by_victim[victim] = float(damage_by_victim.get(victim, 0.0)) + dmg
			Fx.confetti(end, [victim.team_color(), Craft.CREAM], 6, 2.0)
		else:
			Fx.impact(end, hit["normal"], _surface_color(col), true)
	for victim in damage_by_victim:
		var friendly: bool = victim.team == shooter.team and victim != shooter
		if friendly:
			continue
		result["hit"] = true
		var was_alive: bool = victim.alive
		victim.take_damage(damage_by_victim[victim], shooter, weapon.id, head_by_victim.has(victim), dir)
		if was_alive and not victim.alive:
			result["kill"] = true
			result["head"] = head_by_victim.has(victim)
	return result


static func melee(attacker: Soldier, target: Soldier) -> void:
	if target == null or not target.alive:
		return
	var dir := (target.global_position - attacker.global_position).normalized()
	target.take_damage(WeaponDB.KNIFE_DAMAGE, attacker, "knife", false, dir)
	Fx.confetti(target.global_position + Vector3(0, 1.1, 0), [target.team_color(), Craft.CREAM], 14, 3.0)


static func explode(pos: Vector3, owner: Soldier, radius: float, max_damage: float, weapon_id := "frag") -> void:
	Fx.explosion(pos, radius)
	Sfx.play_3d("explosion", pos, 6.0)
	if owner == null or not owner.is_inside_tree():
		return
	var space := owner.get_world_3d().direct_space_state
	for s in owner.get_tree().get_nodes_in_group("soldiers"):
		var victim: Soldier = s
		if not victim.alive:
			continue
		if victim.team == owner.team and victim != owner:
			continue
		var c := victim.global_position + Vector3(0, 0.9, 0)
		var dist := c.distance_to(pos)
		if dist > radius:
			continue
		var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.2, 0), c, 1)
		if not space.intersect_ray(q).is_empty():
			continue
		var dmg := max_damage * clampf(1.0 - dist / radius, 0.0, 1.0) + 20.0
		victim.take_damage(dmg, owner, weapon_id, false, (c - pos).normalized())


static func _cone(dir: Vector3, angle: float) -> Vector3:
	if angle <= 0.00001:
		return dir
	var a := sqrt(randf()) * angle
	var phi := randf() * TAU
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	var x := dir.cross(up).normalized()
	var y := dir.cross(x).normalized()
	return (dir * cos(a) + (x * cos(phi) + y * sin(phi)) * sin(a)).normalized()


static func _surface_color(col: Object) -> Color:
	if col is Node:
		for c in (col as Node).get_children():
			if c is MeshInstance3D and c.material_override is ShaderMaterial:
				var m: ShaderMaterial = c.material_override
				var v = m.get_shader_parameter("color")
				if v is Color:
					return v
	return Craft.KRAFT
