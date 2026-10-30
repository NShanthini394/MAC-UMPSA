extends SceneTree
var app: Control
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	await process_frame; await process_frame; await process_frame
func tap(point: Vector2) -> void:
	var factor := minf(root.size.x / 1280.0, root.size.y / 720.0)
	var physical := (Vector2(root.size) - Vector2(1280,720) * factor) * 0.5 + point * factor
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = physical; event.pressed = true; Input.parse_input_event(event)
	await process_frame
	event = InputEventScreenTouch.new()
	event.index = 0; event.position = physical; event.pressed = false; Input.parse_input_event(event)
	await settle()
func capture(name_: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/v4_" + name_ + ".png")
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	app.online_server_url = ""
	await settle()
	for size_ in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(2400,1080),Vector2i(1920,1200),Vector2i(1024,768)]:
		root.size = size_
		await settle()
		await app.build_menu()
		await settle()
		var viewport := app.get_viewport_rect().size
		var expected_ratio: float = float(root.size.x)/root.size.y
		check(absf(viewport.x/viewport.y - expected_ratio) < 0.01, "Viewport fills aspect ratio " + str(size_))
		var scenery := app.get_node("FullScreenScenery") as TextureRect
		check(scenery.size.distance_to(viewport) < 2, "Scenery fills expanded viewport " + str(size_))
		check(app.screen_root.size == Vector2(1280,720), "Menu design keeps original proportions " + str(size_))
		await capture("menu_%dx%d" % [size_.x,size_.y])
		var pixels := root.get_texture().get_image()
		if viewport.x > 1281 or viewport.y > 721:
			var sample := Vector2i(2, pixels.get_height()/2) if viewport.x > 1281 else Vector2i(pixels.get_width()/2,2)
			var colour := pixels.get_pixelv(sample)
			check(colour.r + colour.g + colour.b > 0.02, "Extra screen area contains scenery rather than black bars " + str(size_))
		await tap(Vector2(640,320))
		check(app.current_screen == "matchmaking", "Painted Play button opens matchmaking with aligned touch " + str(size_))
		await app._open_create_room()
		check(app.find_child("ConnectionMode", true, false) == null, "Network choice removed " + str(size_))
		await tap(Vector2(962,125))
		check(app.current_screen == "menu", "Host close button responds after resize " + str(size_))
		app._start_local_practice_lobby()
		await settle()
		check(app.find_child("LobbyChangeMapButton", true, false) == null, "No map button in waiting room")
		check(app.find_child("LobbyActionButton", true, false).text == "START", "Solo practice uses host Start")
		await capture("waiting_%dx%d" % [size_.x,size_.y])
		await app.build_character_select()
		await capture("characters_%dx%d" % [size_.x,size_.y])
		await app.build_menu()
	root.size = Vector2i(1280,720)
	await settle()
	app.selected_character = "Badang"
	app.completed_tasks = [0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress = [0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map = map_index
		app.player_position = load("res://scripts/map_geometry.gd").gong_point(map_index)
		await app.build_game()
		app.player_body.set_physics_process(false)
		app.player_body.get_node("Camera2D").reset_smoothing()
		await settle()
		await capture("gong_map_%d" % map_index)
	for size_ in [Vector2i(2340,1080),Vector2i(1920,1200),Vector2i(1024,768)]:
		root.size = size_; await settle()
		await app.build_game(); await settle()
		check(app.game_hud.size == Vector2(1280,720), "HUD design stays fixed after resize " + str(size_))
		var pad := app.find_child("VirtualJoystick", true, false) as Control
		check(app.get_viewport_rect().encloses(pad.get_global_rect()), "Touch pad remains inside screen " + str(size_))
		await tap(Vector2(98,632))
		await capture("game_%dx%d" % [size_.x,size_.y])
	print("RESPONSIVE V4: %d checks; %d failures" % [checks, failures.size()])
	app.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
