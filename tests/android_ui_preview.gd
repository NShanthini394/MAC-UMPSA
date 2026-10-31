extends SceneTree
func _initialize() -> void: run.call_deferred()
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/huawei/" + path)
func run() -> void:
	root.size = Vector2i(1080, 486)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	var languages: Node = app.huawei_translation.app_language
	languages.selected = 0; TranslationServer.set_locale("en")
	await app.build_login_screen()
	await capture("phone-login-consistent.png")
	await app.build_menu()
	languages.selected = 2; TranslationServer.set_locale("zh")
	app.show_settings()
	await capture("phone-settings-chinese.png")
	languages.selected = 3; TranslationServer.set_locale("ta")
	app.show_settings()
	await capture("phone-settings-tamil.png")
	app.page_controls.close_dialog()
	await capture("phone-menu-tamil.png")
	languages.selected = 1; TranslationServer.set_locale("ms")
	app.selected_map = 0
	app._start_local_practice_lobby()
	await process_frame; await process_frame
	await capture("phone-waiting-malay.png")
	await app.build_character_select()
	await capture("phone-characters-malay.png")
	TranslationServer.set_locale("en"); languages.selected = 0
	app.queue_free(); await process_frame
	quit()
