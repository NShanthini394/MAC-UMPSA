extends Node2D
const Geometry = preload("res://scripts/map_geometry.gd")
const Data = preload("res://scripts/game_data.gd")
func _ready() -> void:
	run.call_deferred()
func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/"+file_name+".png")
	print("Village preview: "+file_name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.set_process(false)
	app.selected_character="Badang"
	app.player_is_impostor=false
	app.completed_tasks=[0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress=[0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map=map_index
		app.player_position=Geometry.spawn_point(map_index)
		await app.build_game()
		app.player_body.set_physics_process(false)
		app.player_body.get_node("Camera2D").reset_smoothing()
		app.show_map_overlay()
		await capture("parchment_map_%d"%map_index)
		if map_index==0:
			app.find_child("MapOverlay",true,false).call("_tab",true)
			app.find_child("MapOverlay",true,false).call("_choose",0)
			await capture("parchment_tasks_tab")
		app.find_child("MapOverlay",true,false).queue_free()
		await get_tree().process_frame
	for index in 8:
		app.player_position=Geometry.task_points(app.selected_map)[index]
		app.player_body.position=app.player_position
		app.open_task(index)
		if index in [0,1]:
			app.task_progress[index]=2
			app._update_task_dialog_progress(index,2)
		await capture("village_task_%d_%s"%[index,Data.COMMON_TASKS[index]["minigame"]])
		app._close_task()
		app.task_progress[index]=0
		await get_tree().process_frame
	app._start_local_practice_lobby()
	await get_tree().process_frame
	await capture("ready_wait_note")
	get_tree().quit()
