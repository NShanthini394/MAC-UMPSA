extends Node
const Geometry = preload("res://scripts/map_geometry.gd")
const Actions = preload("res://tests/village_task_actions.gd")
var app: Control
func _ready() -> void: run.call_deferred()
func capture(file_name:String) -> void:
	app.page_controls.refresh(true)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/english_"+file_name+".png")
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate();add_child(app)
	await get_tree().process_frame;await get_tree().process_frame
	app.set_process(false)
	await capture("login")
	await app.build_menu();await capture("menu")
	app.selected_map=1;app.selected_character="Badang";app.impostor_character="Pak Kaduk"
	app.player_is_impostor=false
	app.completed_tasks=[0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress=[0,0,0,0,0,0,0,0] as Array[int]
	app.player_position=Geometry.task_points(1)[7]
	await app.build_game();app.player_body.set_physics_process(false)
	app.player_body.get_node("Camera2D").reset_smoothing()
	app.open_task(7);await capture("shoes_start")
	for pair in 2: Actions.complete_step(app.task_minigame,true)
	await capture("shoes_pairs")
	app._close_task();await get_tree().process_frame
	for index in 7:
		app.player_position=Geometry.task_points(1)[index];app.player_body.global_position=app.player_position
		app.open_task(index);await capture("task_%d"%index)
		app._close_task();await get_tree().process_frame
	app.toggle_village_tasks();app._update_interaction_prompt()
	app.game_hud.get_node("NearbyTaskHint").refresh(0,true)
	await capture("game")
	app.show_map_overlay()
	app.find_child("MapOverlay",true,false)._tab(true)
	await capture("map_tasks")
	get_tree().quit()
