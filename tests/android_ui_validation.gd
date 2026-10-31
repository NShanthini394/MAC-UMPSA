extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.size = Vector2i(1920, 864)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	var languages: Node = app.huawei_translation.app_language
	await app.build_login_screen()
	var background := app.find_child("LoginBackground", true, false) as TextureRect
	check(background.texture.resource_path == app.GameData.MENU_ART, "Login and main menu share the supplied artwork")
	check(app.find_child("LoginAccountSurface", true, false) == null, "Login has no dark slab behind its buttons")
	var provider := app.find_child("LoginHuaweiButton", true, false) as Button
	check(provider.accessibility_name == "Continue with Huawei ID", "Huawei sign-in has its full accessible title")
	await app.build_menu()
	app.show_settings()
	await process_frame
	var shade: ColorRect = app.page_controls._dialog
	check(shade.global_position.is_equal_approx(Vector2.ZERO), "Settings shade starts at the viewport edge")
	check(shade.size.is_equal_approx(app.get_viewport_rect().size), "Settings shade covers the expanded phone viewport")
	var settings_language := app.find_child("SettingsLanguageButton", true, false) as OptionButton
	check(settings_language.item_count == 4, "Settings offers English, Malay, Chinese and Tamil")
	for index in [1, 2, 3, 0]:
		settings_language.select(index); settings_language.item_selected.emit(index)
		check(TranslationServer.get_locale() == languages.CODES[index], "Settings changes the app-wide locale")
		check(app.find_child("PlayArtworkButton",true,false).text == "PLAY", "Localisation preserves source button text for game logic")
		check(TranslationServer.translate("PLAY") == ("PLAY" if index == 0 else languages.Core.TEXT[0][index]), "Main menu text is translated immediately")
	languages.selected = 2; TranslationServer.set_locale("zh")
	languages._enqueue("PrivatePlayerName123")
	check(not languages.queue.has("PrivatePlayerName123"), "Player-authored text cannot enter the translation queue")
	var source := "Look for petals behind the leaves."
	languages._enqueue(source)
	check(languages.queue.has(source), "Authored task instructions are eligible for automatic translation")
	languages.active_source = source; languages.active_id = 1000008
	app.huawei_translation._on_translated(1000007, "stale")
	check(not languages.active_source.is_empty(), "Stale app translation cannot finish a new request")
	app.huawei_translation._on_translated(1000008, "寻找叶子后面的花瓣。")
	check(TranslationServer.translate(source) == "寻找叶子后面的花瓣。", "Huawei UI result enters the app-wide catalogue")
	languages.active_source = "Count %d"; languages.active_id = 1000009
	languages._on_translated(1000009, "计数")
	check(not languages.dictionaries.zh.has("Count %d"), "Translations cannot break formatting placeholders")
	app.page_controls.close_dialog()
	app.show_how_to_play()
	check(app.find_child("GuideTranslateButton",true,false)==null, "Guide follows Settings without a separate Translate button")
	app.huawei_translation.open_text(app.page_controls._dialog, "Internal bridge test", "Cook rice")
	await process_frame
	check(app.huawei_translation.overlay.global_position.is_equal_approx(Vector2.ZERO), "Translation shade starts at the viewport edge")
	check(app.huawei_translation.overlay.size.is_equal_approx(app.get_viewport_rect().size), "Translation shade covers both phone margins")
	root.size = Vector2i(1600, 1200)
	await process_frame; await process_frame
	check(app.huawei_translation.overlay.size.is_equal_approx(app.get_viewport_rect().size), "Shade responds when the device viewport changes")
	TranslationServer.set_locale("en"); languages.selected = 0
	app.queue_free(); await process_frame
	print("ANDROID UI CHECKS: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
