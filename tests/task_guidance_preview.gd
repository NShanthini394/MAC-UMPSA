extends Node2D
const Geometry = preload("res://scripts/map_geometry.gd")


func _ready() -> void:
	run.call_deferred()


func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/"+file_name+".png")
	print("Task guidance preview: "+file_name)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.set_process(false)
	app.selected_character = "Bawang Merah"
	app.player_is_impostor = true
	app.completed_tasks = [1,1,1,0,1,1,1,1] as Array[int]
	app.task_progress = [0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map = map_index
		app.player_position = [Geometry.task_points(0)[3]+Vector2(0,-50),Vector2(760,315),Vector2(843,410)][map_index]
		await app.build_game()
		app.player_body.set_physics_process(false)
		app.player_body.get_node("Camera2D").reset_smoothing()
		app.game_hud.get_node("NearbyTaskHint").call("refresh",0.0,true)
		await capture("map_%d_nearby_task"%map_index)
	app.show_settings()
	await capture("settings_leave_game_centered")
	app.page_controls.close_dialog()
	app.player_position = Vector2(775,300)
	app.player_body.position = app.player_position
	app.player_body.get_node("Camera2D").reset_smoothing()
	app.game_hud.get_node("NearbyTaskHint").call("refresh",0.0,true)
	await capture("kitchen_task_in_reach")
	app.player_position = Geometry.spawn_point(2)
	app.player_body.position = app.player_position
	app.player_body.get_node("Camera2D").reset_smoothing()
	app.game_hud.get_node("NearbyTaskHint").call("refresh",0.0,true)
	await capture("no_nearby_task")
	get_tree().quit()
