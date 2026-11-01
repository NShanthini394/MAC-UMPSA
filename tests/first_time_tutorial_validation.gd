extends SceneTree
const Store = preload("res://scripts/settings_store.gd")
const Lang = preload("res://scripts/app_language.gd")
const Data = preload("res://scripts/game_data.gd")
var app: Control
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func run() -> void:
	Store.load_values()
	Store.values["tutorial_completed"] = false
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.set_process(false)
	await app._continue_as_guest()
	var welcome: Control = app.find_child("LoginWelcomePanel", true, false)
	check(welcome != null, "First login/guest entry shows the welcome panel")
	if welcome:
		var start_action: Button = welcome.find_child("LoginWelcomeStartTutorial", true, false)
		var close_action: Button = welcome.find_child("LoginWelcomeClose", true, false)
		var corner_close: Button = welcome.find_child("PopupCloseButton", true, false)
		check(start_action.pressed.is_connected(Callable(app, "start_tutorial_from_welcome")), "Start Tutorial begins the practice tutorial flow")
		check(close_action.pressed.is_connected(Callable(app, "finish_login_welcome")), "Close dismisses the welcome panel")
		check(corner_close == null or not corner_close.visible, "Welcome offers the two requested actions without a duplicate close button")
		for index in 4:
			Lang.instance.selected = index
			TranslationServer.set_locale(Lang.CODES[index])
			app.page_controls.call("_refresh_guide_language", Lang.CODES[index])
			var welcome_title: Label = welcome.find_child("LoginWelcomeTitle", true, false)
			var welcome_body: Label = welcome.find_child("LoginWelcomeMessage", true, false)
			var welcome_start: Button = welcome.find_child("LoginWelcomeStartTutorial", true, false)
			var welcome_close: Button = welcome.find_child("LoginWelcomeClose", true, false)
			check(welcome_title.text == Lang.text("Welcome to Nenek Kebayan"), "Login welcome title follows " + Lang.CODES[index])
			check(welcome_body.text == Lang.text("Start the tutorial. Then play a short practice match with 9 bots as Puteri Gunung Ledang."), "Login welcome explains tutorial and practice match in " + Lang.CODES[index])
			check(welcome.get_global_rect().encloses(welcome_body.get_global_rect()), "Login welcome body fits in " + Lang.CODES[index])
			check(welcome_body.get_line_count() * welcome_body.get_line_height() <= welcome_body.size.y + 1, "Login welcome wraps cleanly in " + Lang.CODES[index])
			check(welcome_start.text == Lang.text("Start Tutorial"), "Login welcome start action follows " + Lang.CODES[index])
			check(welcome_close.text == Lang.text("CLOSE"), "Login welcome close action follows " + Lang.CODES[index])
		check(not bool(Store.values["tutorial_completed"]), "Welcome does not complete the full tutorial")
		app.page_controls.close_dialog()
	await app.build_login_screen()
	app.firebase_auth.user = {"uid": "tutorial-validation", "display_name": "Tester"}
	await app._on_authenticated()
	check(app.current_screen == "menu" and app.find_child("LoginWelcomePanel", true, false) != null, "Authenticated login also opens the welcome panel")
	app.page_controls.close_dialog()
	app.firebase_auth.user.clear()
	app.selected_character = ""
	app._ensure_practice_character()
	check(not app.selected_character.is_empty(), "Menu replay receives a visible default character")
	app.selected_map = 0
	app.selected_character = "Badang"
	app.player_position = Vector2(420, 360)
	app.completed_tasks.clear()
	app.task_progress.clear()
	for index in Data.COMMON_TASKS.size():
		app.completed_tasks.append(0)
		app.task_progress.append(0)
	await app.build_game()
	var tutorial := app.find_child("FirstTimeTutorial", true, false)
	check(tutorial != null, "First game entry starts the tutorial")
	if tutorial == null:
		quit(1)
		return
	check(not bool(Store.values["tutorial_completed"]), "Opening the tutorial does not mark it complete")
	app.open_task(0)
	app.show_map_overlay()
	app.call_meeting()
	check(app.task_overlay_index < 0 and app.find_child("MapOverlay", true, false) == null and app.find_child("VoteOverlay", true, false) == null, "Tutorial backdrop blocks gameplay actions")
	for window_size in [Vector2i(1280, 720), Vector2i(1560, 720), Vector2i(960, 600)]:
		root.size = window_size
		await settle()
		tutorial._layout()
		var card: Control = tutorial.find_child("TutorialSpeechPanel", true, false)
		check(root.get_visible_rect().encloses(card.get_global_rect()), "Tutorial panel fits " + str(window_size) + ": viewport=" + str(root.get_visible_rect()) + " card=" + str(card.get_global_rect()))
		for label_name in ["TutorialTitle", "TutorialExplanation", "TutorialProgress", "TutorialActionHint"]:
			var label: Label = tutorial.find_child(label_name, true, false)
			if label.visible:
				check(label.get_line_count() * label.get_line_height() <= label.size.y + 1, label_name + " fits " + str(window_size))
				check(card.get_global_rect().encloses(label.get_global_rect()), label_name + " remains inside the card")
		for button_name in ["TutorialBack", "TutorialSkip", "TutorialNext", "TutorialFinish"]:
			var button: Control = tutorial.find_child(button_name, true, false)
			if button.visible:
				check(card.get_global_rect().encloses(button.get_global_rect()), button_name + " remains inside the card")
	for index in 4:
		Lang.instance.selected = index
		TranslationServer.set_locale(Lang.CODES[index])
		tutorial.refresh_language()
		check(tutorial.skip_button.text == Lang.text("Skip Tutorial"), "Skip label follows " + Lang.CODES[index])
		for impostor in [false, true]:
			app.player_is_impostor = impostor
			var frame: Panel = app.make_panel(Rect2(240, 70, 800, 580), Color("21180f"))
			var role_card: Panel = app._build_revealed_role_card(frame)
			await process_frame
			var reminder: Label = role_card.find_child("RoleInstructions", true, false)
			var reminder_source := "Nenek Kebayan: blend in; put Villagers to sleep unseen; mislead during discussions; respect action cooldowns; win when you equal or outnumber the awake Villagers." if impostor else "Villagers: complete the village tasks; watch for suspicious behaviour; discuss and vote carefully; find both Nenek Kebayan to win."
			check(reminder.text == Lang.text(reminder_source), "Role reminder follows " + Lang.CODES[index])
			check(reminder.get_line_count() * reminder.get_line_height() <= reminder.size.y + 1, "Role reminder fits " + Lang.CODES[index])
			frame.queue_free()
			await process_frame
		for step_index in tutorial.step_sources.size():
			tutorial.step = step_index
			tutorial._show_step()
			await process_frame
			var source: Array = tutorial.step_sources[step_index]
			check(tutorial.title_label.text == Lang.text(str(source[0])), "Title follows " + Lang.CODES[index] + " step " + str(step_index + 1))
			check(tutorial.body_label.text == Lang.text(str(source[1])), "Explanation follows " + Lang.CODES[index] + " step " + str(step_index + 1))
			check(tutorial.body_label.get_line_count() * tutorial.body_label.get_line_height() <= tutorial.body_label.size.y + 1, "Explanation fits " + Lang.CODES[index] + " step " + str(step_index + 1))
		tutorial.step = 1
		tutorial.moved_from = app.player_position
		tutorial.movement_seen = false
		tutorial._show_step()
		check(tutorial.next_button.disabled, "Movement gate starts closed in " + Lang.CODES[index])
		app.player_position += Vector2(20, 0)
		tutorial._process(0.016)
		check(tutorial.movement_seen and not tutorial.next_button.disabled, "Movement gate opens after movement in " + Lang.CODES[index])
		tutorial.step = 2
		tutorial.interact_seen = false
		tutorial._show_step()
		var interact: BaseButton = app.find_child("InteractButton", true, false)
		check(interact.accessibility_name == Lang.text("Interact · E"), "Interact accessibility follows " + Lang.CODES[index])
		tutorial.on_interact()
		check(tutorial.interact_seen and not tutorial.next_button.disabled, "Interact gate opens without running gameplay in " + Lang.CODES[index])
		tutorial.step = 0
		tutorial._show_step()
	tutorial.queue_free()
	await process_frame
	Store.values["tutorial_completed"] = true
	await app.build_game()
	check(app.find_child("FirstTimeTutorial", true, false) == null, "Completed tutorial does not auto-repeat on later match entry")
	await app.build_menu()
	app.selected_character = ""
	app.replay_tutorial()
	check(not app.selected_character.is_empty(), "Replay from menu assigns a visible player character")
	var deadline := Time.get_ticks_msec() + 15000
	while app.current_screen != "game" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(app.current_screen == "game", "Menu replay returns from role reveal to gameplay")
	check(app.find_child("FirstTimeTutorial", true, false) != null, "Completed tutorial remains replayable")
	var actor := app.player_body.get_node_or_null("CharacterActor/CharacterSprite") as TextureRect if is_instance_valid(app.player_body) else null
	check(actor != null and actor.texture != null, "Menu replay keeps the selected character visible")
	app.queue_free()
	await process_frame
	print("FIRST-TIME TUTORIAL: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
