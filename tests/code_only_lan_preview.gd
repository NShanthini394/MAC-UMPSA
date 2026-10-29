extends Node2D
func _ready() -> void: run.call_deferred()
func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/"+file_name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	var app: Control=load("res://scenes/main.tscn").instantiate()
	add_child(app); await get_tree().process_frame; await get_tree().process_frame
	app.set_process(false); app.selected_map=1; app.lobby_player_name="Player 1"
	await app._open_create_room()
	await capture("code_only_host_setup")
	app.room_code="B7C9D"; app._show_created_room()
	await capture("code_only_room_invite")
	app.room_code=""; app._close_menu_popups()
	await app.build_menu()
	app.show_join_room()
	await capture("code_only_join_room")
	get_tree().quit()
