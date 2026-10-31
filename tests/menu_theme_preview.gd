extends Node
const Geometry = preload("res://scripts/map_geometry.gd")
var suffix := ""
func _ready() -> void:
	suffix = "_wide" if "--wide" in OS.get_cmdline_user_args() else ""
	run.call_deferred()
func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/theme_" + file_name + suffix + ".png")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.set_process(false)
	app.online_server_url = ""
	await capture("login")
	for provider in ["Google", "Huawei"]:
		var button: Button = app.find_child("Login" + provider + "Button", true, false)
		var title: Label = button.find_child("ProviderTitle", true, false)
		assert(title.text.contains(provider), "Provider name stays in the sign-in label")
		assert(title.get_line_count() == 1, "Provider label stays on one visible line")
		var title_width := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
		assert(title_width <= title.size.x, "Entire provider label fits")
		assert(button.get_global_rect().encloses(title.get_global_rect()), "Provider label stays inside its button")
	print("Login viewport: ", get_viewport().get_visible_rect().size, "; panel center: ", app.find_child("LoginPanel", true, false).get_global_rect().get_center().x)
	app.show_create_account()
	await capture("create_account")
	app._close_email_auth()
	await get_tree().process_frame
	app.show_email_sign_in()
	await capture("email_sign_in")
	app._close_email_auth()
	await get_tree().process_frame
	await app.build_menu()
	await capture("main_menu")
	for node_name in ["StartGameButton", "MainHelpButton", "MainExitButton"]:
		var button: Button = app.find_child(node_name, true, false)
		assert(not button.text.is_empty() and button.icon != null, "Menu uses live text and icons")
		var normal := button.get_theme_stylebox("normal") as StyleBoxTexture
		assert(normal != null, "Menu uses the same textured button style as Offline Practice")
		assert(normal.texture != (button.get_theme_stylebox("hover") as StyleBoxTexture).texture, "Hover feedback differs from normal")
		assert(normal.texture != (button.get_theme_stylebox("pressed") as StyleBoxTexture).texture, "Pressed feedback differs from normal")
	print("LOGIN LABEL AND MENU STATE CHECKS PASSED")
	var hover := InputEventMouseMotion.new(); hover.position = Vector2(640,311)
	get_viewport().push_input(hover, true)
	await capture("main_menu_hover")
	var touch := InputEventScreenTouch.new(); touch.index = 0; touch.position = Vector2(640,311); touch.pressed = true
	get_viewport().push_input(touch, true)
	await capture("main_menu_pressed")
	touch = InputEventScreenTouch.new(); touch.index = 0; touch.position = Vector2(640,311); touch.pressed = false
	get_viewport().push_input(touch, true)
	await get_tree().process_frame
	app.selected_character = "Badang"
	app.play_mode = "solo"
	for map_index in 3:
		app.selected_map = map_index
		app._start_local_practice_lobby()
		await capture("waiting_room_%d" % map_index)
		var header: Panel = app.find_child("LobbyHeader", true, false)
		var previous: Control = header.get_node("LobbyHeadingLabel")
		for node_name in ["LobbyMapLabel", "LobbyModeLabel", "LobbyStatusLabel"]:
			var column: Control = header.get_node(node_name)
			assert(column.position.x - previous.get_rect().end.x >= 24, "Lobby header columns keep a clear gap")
			assert(header.get_global_rect().encloses(column.get_global_rect()), "Lobby header text fits inside its panel")
			previous = column
	app.selected_map = 1
	await app.build_waiting_room()
	await capture("waiting_room")
	print("LOBBY HEADER SPACING CHECKS PASSED")
	app.player_is_impostor = true
	app.completed_tasks.resize(load("res://scripts/game_data.gd").COMMON_TASKS.size()); app.completed_tasks.fill(0)
	app.task_progress.resize(load("res://scripts/game_data.gd").COMMON_TASKS.size()); app.task_progress.fill(0)
	app.player_position = Geometry.spawn_point(1)
	await app.build_game()
	app.player_body.set_physics_process(false)
	app.player_body.get_node("Camera2D").reset_smoothing()
	await capture("game_icons")
	app.show_map_overlay()
	app.find_child("MapOverlay", true, false)._tab(true)
	await capture("map_tasks")
	get_tree().quit()
