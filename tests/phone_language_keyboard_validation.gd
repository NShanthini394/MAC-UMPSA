extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.size = Vector2i(1080,486)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	var languages: Node = app.huawei_translation.app_language
	languages.select_language(1)
	for key in ["WAITING ROOM", "CHOOSE YOUR CHARACTER", "SELECT", "SELECTED", "RETURN TO ROOM", "YOUR SELECTED MAP", "%d HERE  •  %d OPEN SLOTS", "White handkerchief"]:
		check(TranslationServer.translate(key)!=key, "Malay has bundled copy for " + key)
	for task in app.GameData.COMMON_TASKS:
		for key in ["name", "prompt", "place"]:
			check(TranslationServer.translate(task[key])!=task[key], "Malay covers task " + key + ": " + task[key])
	languages._enqueue("Private text typed by the player")
	check(languages.queue.is_empty(), "Malay does not require cloud requests")
	app.selected_map = 0
	app._start_local_practice_lobby()
	await process_frame; await process_frame
	check(TranslationServer.get_locale()=="ms", "Entering a map keeps Malay selected")
	var field := app.find_child("LobbyNameEntry",true,false) as LineEdit
	check(field!=null, "Real waiting-room name field exists")
	var keyboard: Node = app.huawei_translation.get_node("KeyboardAvoider")
	var panel := field.get_parent() as Control
	var before := panel.position
	var value := field.text
	keyboard.avoid(field, 500.0, 720.0)
	check(field.get_global_rect().end.y<=200.1, "Focused field rises above the keyboard with padding")
	check(panel.position.y < before.y, "Keyboard avoidance moves the field's panel")
	check(field.text==value, "Keyboard avoidance preserves typed text")
	keyboard.avoid(field, 540.0, 720.0)
	check(field.get_global_rect().end.y<=160.1, "Keyboard size changes update the field position")
	keyboard.restore()
	check(panel.position.is_equal_approx(before), "Closing the keyboard restores the exact panel position")
	await app.build_character_select()
	var selected := app.find_child("CharacterSelectionLabel",true,false) as Label
	check(selected.text.begins_with("Dipilih: "), "Dynamic character caption uses Malay")
	app.completed_tasks.resize(12); app.completed_tasks.fill(0)
	app.task_progress.resize(12); app.task_progress.fill(0)
	app.player_is_impostor = false; app.selected_character = "Badang"
	await app.build_game()
	check(app.find_child("GameRoleLabel",true,false).text.begins_with("ORANG KAMPUNG"), "Gameplay role caption uses Malay")
	check(not app.find_child("ProgressLabel",true,false).text.contains("TASKS"), "Gameplay progress uses Malay")
	app.show_settings()
	check(app.find_child("SettingsLanguageButton",true,false).selected==1, "In-game Settings retains the selected language")
	app.page_controls.close_dialog()
	app.show_clue_panel("White handkerchief","Hidden Impostor")
	var clue := app.find_child("ClueNameLabel",true,false) as Label
	check(clue!=null and clue.tr(clue.text)=="Sapu tangan putih", "Clue name is translated without an extra action")
	check(app.find_child("ClueTranslateButton",true,false)==null, "Clue has no redundant Translate button")
	check(not clue.text.contains("Hidden Impostor"), "Clue caption does not expose the hidden role")
	languages.select_language(0)
	app.queue_free(); await process_frame
	print("PHONE LANGUAGE / KEYBOARD CHECKS: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
