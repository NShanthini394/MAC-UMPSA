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
	await capture("login")
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
	app.selected_map = 1
	app.selected_character = "Badang"
	await app.build_waiting_room()
	await capture("waiting_room")
	app.player_is_impostor = true
	app.completed_tasks = [0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress = [0,0,0,0,0,0,0,0] as Array[int]
	app.player_position = Geometry.spawn_point(1)
	await app.build_game()
	app.player_body.set_physics_process(false)
	app.player_body.get_node("Camera2D").reset_smoothing()
	await capture("game_icons")
	app.show_map_overlay()
	app.find_child("MapOverlay", true, false)._tab(true)
	await capture("map_tasks")
	get_tree().quit()
