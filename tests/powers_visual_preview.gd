extends SceneTree
## Render the menu, shared controls, and automatic surrounding powers.
const Geometry = preload("res://scripts/map_geometry.gd")
const Powers = preload("res://scripts/nenek_powers.gd")
var app: Control


func _initialize() -> void:
	_run.call_deferred()


func capture(file_name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/" + file_name + ".png")
	print("Rendered preview: " + file_name)


func build_map(map_index: int, nenek: bool = true) -> void:
	app.call("_reset_power_state")
	app.set("selected_map", map_index)
	app.set("selected_character", "Bawang Merah")
	app.set("player_is_impostor", nenek)
	var empty_tasks: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
	app.set("completed_tasks", empty_tasks.duplicate())
	app.set("task_progress", empty_tasks.duplicate())
	app.set("player_position", Geometry.spawn_point(map_index))
	var room := {"started": true, "finished": false, "meeting_state": "", "map_index": map_index, "players": {1: {"role": "nenek_kebayan" if nenek else "villager", "position": Geometry.spawn_point(map_index)}}}
	Powers.reset_match(room, Time.get_ticks_msec() / 1000.0)
	app.set("practice_power_room", room)
	await app.call("build_game")


func move_to_section(map_index: int, section_index: int) -> void:
	var center: Vector2 = Geometry.sabotage_areas(map_index)[section_index]["zones"][0].get_center()
	app.set("player_position", center)
	var body: Node2D = app.get("player_body")
	body.global_position = center
	body.get_node("Camera2D").reset_smoothing()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	app = main_scene.instantiate() as Control
	root.add_child(app)
	await process_frame
	await process_frame
	await capture("login_controls")
	app.call("show_create_account")
	await capture("login_create_account")
	app.find_child("CreateAccountBackButton", true, false).emit_signal("pressed")
	await process_frame
	await app.call("build_menu")
	await capture("menu_title_clear")
	app.call("show_settings", "")
	await capture("menu_settings")
	app.get("page_controls").close_dialog()
	await app.call("build_map_select")
	await capture("map_selection_controls")
	app.set("selected_character", "Bawang Merah")
	app.set("lobby_players", [{"id": "local", "character": "Bawang Merah", "name": "Player 1", "host": true, "ready": false}])
	await app.call("build_waiting_room")
	await capture("waiting_room_controls")
	await app.call("build_character_select")
	await capture("character_selection_controls")
	app.set("assigned_role_character", "Nenek Kebayan")
	app.set("player_is_impostor", true)
	app.set("completed_tasks", [0, 0, 0, 0, 0, 0, 0, 0] as Array[int])
	app.set("task_progress", [0, 0, 0, 0, 0, 0, 0, 0] as Array[int])
	_capture_shuffle.call_deferred()
	await app.call("_show_role_reveal")
	for i in 3:
		await build_map(i)
		app.call("cast_sabotage", "fog")
		await capture("local_fog_map_%d" % i)
		if i == 0:
			app.call("show_how_to_play", "")
			await capture("gameplay_how_to_play")
			app.get("page_controls").close_dialog()
			app.call("_toggle_audio")
			await capture("gameplay_muted_icons")
			app.call("_toggle_audio")
	await build_map(0, false)
	var origin: Vector2 = app.get("player_position")
	app.call("_apply_power_state", {"kind": "fog", "area": Geometry.section_at_position(0, origin), "fog_origin": origin, "fog_radius": Powers.FOG_RADIUS, "seconds_left": 20.0})
	await capture("local_fog_villager")
	app.set("player_sleeping", true)
	app.call("_apply_power_state", {"kind": "", "area": -1, "seconds_left": 0.0})
	app.call("_enter_watch_mode")
	await capture("spectator_page_controls")
	app.call("show_settings", "")
	await capture("spectator_settings")
	app.get("page_controls").close_dialog()
	for section_case in [[0, 3], [2, 2]]:
		await build_map(section_case[0])
		move_to_section(section_case[0], section_case[1])
		app.call("cast_sabotage", "lock")
		await capture("section_exits_locked_map_%d" % section_case[0])
	app.call("navigate_back")
	await capture("leave_game_confirmation")
	app.get("page_controls").close_dialog()
	app.call("_show_network_discussion")
	await capture("meeting_page_controls")
	app.call("show_result", true, "The villagers have discovered Nenek Kebayan.")
	await capture("result_page_controls")
	app.queue_free()
	await process_frame
	quit()


func _capture_shuffle() -> void:
	await create_timer(0.25).timeout
	await capture("shuffle_clean")
	await create_timer(1.70).timeout
	await capture("role_reveal_clean")
