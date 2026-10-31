extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	await app.build_menu()
	app.show_how_to_play()
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/huawei")
	root.get_texture().get_image().save_png("res://output/huawei/translation-dialog.png")
	print("Rendered translation dialog above the guide.")
	quit()
