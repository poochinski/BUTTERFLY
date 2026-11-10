class_name InsectSpawner
extends Node3D
## Keeps a lively population of butterflies around the player, choosing
## species by rarity, time of day and the habitat at each spot.

const TARGET_COUNT := 18
const SPAWN_MIN := 10.0
const SPAWN_MAX := 42.0
const DESPAWN := 70.0

var _timer := 0.0
var _initial_done := false


func _process(delta: float) -> void:
	var player: Player = Game.player
	if player == null:
		return
	if not _initial_done:
		_initial_done = true
		for i in TARGET_COUNT:
			_spawn_one(player.global_position, 4.0 if i < 6 else SPAWN_MIN, 26.0)
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.6
	var active := 0
	for b in get_children():
		var bf := b as Butterfly
		if bf == null or bf.is_released():
			continue
		if bf.global_position.distance_to(player.global_position) > DESPAWN:
			bf.queue_free()
			continue
		active += 1
	if active < TARGET_COUNT:
		_spawn_one(player.global_position, SPAWN_MIN, SPAWN_MAX)


func _habitat_score(world: World, x: float, z: float, habitat: Dictionary) -> float:
	var flowers := world.flowers_at(x, z)
	var forest := world.forest_at(x, z)
	var edge := clampf(forest * (1.0 - forest) * 4.0, 0.0, 1.0)
	var meadow := (1.0 - forest) * (1.0 - flowers * 0.5)
	var pond := 1.0 - smoothstep(World.POND_RADIUS, World.POND_RADIUS * 2.5, world.dist_to_pond(x, z))
	var s := 0.05
	s += float(habitat.get("flowers", 0.0)) * flowers
	s += float(habitat.get("meadow", 0.0)) * meadow
	s += float(habitat.get("forest_edge", 0.0)) * maxf(edge, forest * 0.3)
	s += float(habitat.get("pond", 0.0)) * pond
	return s


func _pick_species(world: World, x: float, z: float) -> String:
	var total := 0.0
	var weights := {}
	for id in Species.ORDER:
		var sp: Dictionary = Species.DATA[id]
		if not Species.is_active(sp, Game.hour):
			continue
		var w: float = Species.RARITY_WEIGHT[int(sp["rarity"])] * _habitat_score(world, x, z, sp["habitat"])
		weights[id] = w
		total += w
	if total <= 0.0:
		return ""
	var roll := randf() * total
	for id in weights:
		roll -= weights[id]
		if roll <= 0.0:
			return id
	return weights.keys()[0]


func _spawn_one(center: Vector3, rmin: float, rmax: float) -> void:
	var world: World = Game.world
	for attempt in 6:
		var a := randf() * TAU
		var r := randf_range(rmin, rmax)
		var x := center.x + cos(a) * r
		var z := center.z + sin(a) * r
		if Vector2(x, z).length() > World.PLAY_RADIUS + 20.0 or world.is_water(x, z):
			continue
		var id := _pick_species(world, x, z)
		if id == "":
			return
		var perch = world.random_perch_near(Vector3(x, 0, z), 6.0) if randf() < 0.5 else null
		var g := world.height_at(x, z)
		var b := Butterfly.new()
		add_child(b)
		b.setup(id, Vector3(x, g + randf_range(0.8, 2.2), z), perch)
		return
