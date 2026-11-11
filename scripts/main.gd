extends Node
## Boots the game: builds the map once, photographs it for the minimap,
## then runs the menu ⇄ match loop on top of it.

var world: Node3D
var map: GameMap
var _loading := false
var menu: MainMenu
var match_node: MatchManager
var hud: HUD
var pause: PauseMenu
var minimap_tex: Texture2D
var menu_cam: Camera3D
var _orbit := 0.0
var _end_t := -1.0


func _ready() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	menu_cam = Camera3D.new()
	menu_cam.fov = 55.0
	menu_cam.far = 900.0
	world.add_child(menu_cam)
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--map="):
			Game.settings["map"] = String(arg).substr(6)
	_build_map()
	Fx.root = world
	menu_cam.make_current()
	_update_menu_cam(0.0)
	await _capture_minimap()

	menu = MainMenu.new()
	add_child(menu)
	menu.play_pressed.connect(start_match)
	menu.map_changed.connect(_change_map)
	menu.quit_pressed.connect(func():
		Game.save_profile()
		get_tree().quit())
	menu.show_menu()

	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var cap := DebugCapture.new()
		cap.args = args
		cap.main = self
		add_child(cap)


## Builds the map chosen in the settings (Gateway or Lodgepole).
func _build_map() -> void:
	var id := String(Game.settings.get("map", "gateway"))
	map = LodgepoleMap.new() if id == "lodgepole" else GatewayMap.new()
	map.name = id.capitalize()
	world.add_child(map)
	var t0 := Time.get_ticks_msec()
	map.build()
	print("Map %s built in %d ms" % [id, Time.get_ticks_msec() - t0])


## Swap maps from the menu: tear down the old one, build the new one and
## photograph it for the minimap.
func _change_map() -> void:
	if _loading or match_node:
		return
	_loading = true
	map.queue_free()
	await get_tree().process_frame
	_build_map()
	menu_cam.make_current()
	await _capture_minimap()
	_loading = false


func _capture_minimap() -> void:
	var vp := SubViewport.new()
	var b := map.bounds
	var px := 4
	vp.size = Vector2i(int(b.size.x * px), int(b.size.y * px))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	world.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = b.size.y
	cam.far = 200.0
	vp.add_child(cam)
	cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(b.position.x + b.size.x * 0.5, 80.0, b.position.y + b.size.y * 0.5))
	cam.make_current()
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	minimap_tex = ImageTexture.create_from_image(img)
	vp.queue_free()
	menu_cam.make_current()


func _process(delta: float) -> void:
	if match_node == null:
		_update_menu_cam(delta)
	elif match_node.ended:
		_end_t += delta
		if _end_t > 9.0 or (_end_t > 2.5 and (Input.is_action_just_pressed("fire") or Input.is_action_just_pressed("ui_accept"))):
			end_match()


func _update_menu_cam(delta: float) -> void:
	_orbit += delta * 0.035
	var o := map.orbit if map else Vector4(0, -2, 58, 46)
	var c := Vector3(o.x, 3, o.y)
	var p := c + Vector3(cos(_orbit) * o.z, map.orbit_height + sin(_orbit * 0.7) * 4.0 if map else 22.0, sin(_orbit) * o.w)
	menu_cam.global_transform = Transform3D(Basis.looking_at(c - p), p)


func start_match() -> void:
	if match_node or _loading:
		return
	menu.visible = false
	match_node = MatchManager.new()
	match_node.name = "Match"
	world.add_child(match_node)
	match_node.start(map)
	Fx.root = match_node
	hud = HUD.new()
	add_child(hud)
	hud.setup(match_node)
	hud._minimap.texture = minimap_tex
	pause = PauseMenu.new()
	add_child(pause)
	pause.leave_pressed.connect(end_match)
	_end_t = -1.0
	match_node.match_ended.connect(func(_w): _end_t = 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func end_match() -> void:
	if match_node == null:
		return
	get_tree().paused = false
	match_node.queue_free()
	hud.queue_free()
	pause.queue_free()
	for g in get_tree().get_nodes_in_group("grenades"):
		g.queue_free()
	match_node = null
	Fx.root = world
	Game.save_profile()
	menu_cam.make_current()
	menu.show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Game.save_profile()
