extends Node3D
## Builds the whole game at startup: world, sky, player, camera, butterflies,
## effects and interface.


func _ready() -> void:
	var world := World.new()
	world.name = "World"
	add_child(world)
	var t0 := Time.get_ticks_msec()
	world.build()
	print("World built in %d ms" % (Time.get_ticks_msec() - t0))
	Game.world = world

	var cycle := DayCycle.new()
	cycle.name = "DayCycle"
	add_child(cycle)

	var player := Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = world.spawn_point()
	Game.player = player

	var rig := CameraRig.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.target = player
	player.camera_rig = rig
	# Start looking down the path toward the sunset.
	var ahead := World.path_x(World.SPAWN_Z - 12.0) - player.global_position.x
	rig.yaw = atan2(-ahead, 12.0)
	player.model.rotation.y = rig.yaw

	var grass := GrassField.new()
	grass.name = "Grass"
	add_child(grass)

	var spawner := InsectSpawner.new()
	spawner.name = "Insects"
	add_child(spawner)

	var fx := AmbientFX.new()
	fx.name = "AmbientFX"
	add_child(fx)

	add_child(PostFX.new())
	add_child(HUD.new())
	add_child(Journal.new())
	add_child(PauseMenu.new())
	add_child(TouchControls.new())

	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var cap := DebugCapture.new()
		cap.args = args
		add_child(cap)
	elif not OS.has_feature("mobile") and not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Game.save_game()
