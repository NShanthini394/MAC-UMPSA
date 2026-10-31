extends SceneTree
func _initialize() -> void: run.call_deferred()
func capture(path: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/huawei/" + path)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/huawei")
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(1080,486)
	var splash: Control = load("res://scenes/splash.tscn").instantiate()
	splash.auto_continue = false
	root.add_child(splash)
	await capture("splash-wide-phone.png")
	root.size = Vector2i(960,720)
	await capture("splash-tablet.png")
	splash.queue_free(); await process_frame
	root.size = Vector2i(1080,486)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	await app.build_menu()
	app.show_settings()
	await capture("fonts-settings.png")
	app.show_how_to_play()
	await capture("fonts-guide.png")
	app.queue_free(); await process_frame
	quit()
