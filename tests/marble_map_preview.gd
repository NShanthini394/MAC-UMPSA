extends Node2D
const Geometry = preload("res://scripts/map_geometry.gd")
const Actions = preload("res://tests/village_task_actions.gd")
func _ready() -> void: run.call_deferred()
func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/"+file_name+".png")
	print("Marble/map preview: "+file_name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	add_child(app); await get_tree().process_frame; await get_tree().process_frame
	app.set_process(false); app.selected_character="Pak Kaduk"; app.player_is_impostor=false
	app.completed_tasks=[0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress=[0,0,0,0,0,0,0,0] as Array[int]
	for map_index in [1,2]:
		app.selected_map=map_index; app.player_position=Geometry.spawn_point(map_index)
		await app.build_game()
		app.player_body.set_physics_process(false)
		app.player_body.get_node("Camera2D").reset_smoothing()
		app.show_map_overlay()
		var view: Control = app.find_child("MapOverlay",true,false)
		view._tab(true); view._choose(5)
		await capture("map_%d_tasks_list_clean"%map_index)
		view._tab(false)
		await capture("map_%d_selected_marble_aligned"%map_index)
		view.queue_free(); await get_tree().process_frame
		app.page_controls.refresh(true)
	app.player_position=Geometry.task_points(app.selected_map)[5]
	app.player_body.position=app.player_position
	app.open_task(5)
	app.page_controls.refresh(true)
	var board: Control = app.task_minigame
	board.set_process(false)
	var good_pull: Vector2 = board.get("_shot").pull_for_target(board._target())
	Actions.press(board,board._source(),true)
	var aim := InputEventScreenDrag.new(); aim.index=0
	aim.position=board._source()-good_pull; aim.relative=-good_pull
	board._gui_input(aim)
	await capture("marble_aim_inside")
	aim.position=board._source()-Vector2(100,0)
	board._gui_input(aim)
	await capture("marble_aim_miss")
	aim.position=board._source()-good_pull
	board._gui_input(aim)
	Actions.release(board,aim.position,true)
	board._process(0.6)
	await capture("marble_rolling")
	get_tree().quit()
