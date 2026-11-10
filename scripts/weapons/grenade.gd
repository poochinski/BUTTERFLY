class_name Grenade
extends RigidBody3D
## A knitted frag grenade: bounces, rolls, and pops in a burst of confetti.

var owner_soldier: Soldier
var fuse := WeaponDB.FRAG_FUSE
var _done := false


func setup(by: Soldier, pos: Vector3, velocity: Vector3, fuse_left: float) -> void:
	owner_soldier = by
	fuse = fuse_left
	collision_layer = 4
	collision_mask = 1
	mass = 0.4
	continuous_cd = true
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.35
	mat.friction = 0.8
	physics_material_override = mat
	linear_damp = 0.25
	angular_damp = 1.0
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.06
	shape.shape = s
	add_child(shape)
	add_child(GunBuilder.frag(false))
	global_position = pos
	linear_velocity = velocity
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))
	add_to_group("grenades")
	body_entered.connect(func(_b): Sfx.play_3d("bounce", global_position, -4.0))
	contact_monitor = true
	max_contacts_reported = 2


func _physics_process(delta: float) -> void:
	fuse -= delta
	if fuse <= 0.0 and not _done:
		_done = true
		Combat.explode(global_position, owner_soldier, WeaponDB.FRAG_RADIUS, WeaponDB.FRAG_DAMAGE)
		queue_free()
