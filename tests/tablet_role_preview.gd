extends Node
const Geometry = preload("res://scripts/map_geometry.gd")
var app: Control
func _ready() -> void: run.call_deferred()
func capture(file_name: String) -> void:
	app.page_controls.refresh(true)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/tablet_fix_" + file_name + ".png")
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.set_process(false)
	await capture("login")
	app.show_email_sign_in()
	await capture("email")
	app._close_email_auth()
	await get_tree().process_frame
	await app.build_menu()
	get_window().size = Vector2i(1024,768)
	await capture("menu_tablet")
	get_window().size = Vector2i(1280,720)
	app.selected_character = "Badang"
	await app.build_character_select()
	await capture("characters")
	app.completed_tasks = [0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress = [0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map = map_index
		app.player_position = Geometry.task_points(map_index)[5]
		for nenek in [false,true]:
			app.player_is_impostor = nenek
			app._reset_power_state()
			await app.build_game()
			app.player_body.set_physics_process(false)
			app.player_body.get_node("Camera2D").reset_smoothing()
			app._update_interaction_prompt()
			app.game_hud.get_node("NearbyTaskHint").refresh(0.0,true)
			await capture("%s_map_%d" % ["nenek" if nenek else "villager", map_index])
			app._apply_power_state({"kind":"fog", "area":Geometry.section_at_position(map_index,app.player_position), "fog_origin":app.player_position, "fog_radius":180.0, "seconds_left":20.0})
			await capture("fog_%s_map_%d" % ["nenek" if nenek else "villager", map_index])
	get_tree().quit()
