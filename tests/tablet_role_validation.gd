extends SceneTree
const Geometry = preload("res://scripts/map_geometry.gd")
var app: Control
var checks := 0
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func settle() -> void:
	await process_frame
	await process_frame
	await process_frame
func tap(point: Vector2) -> void:
	# Inject actual screen-touch events, including letterbox and scale conversion.
	var scale := minf(root.size.x / 1280.0, root.size.y / 720.0)
	var position := (Vector2(root.size) - Vector2(1280, 720) * scale) * 0.5 + point * scale
	var press := InputEventScreenTouch.new()
	press.index = 0; press.position = position; press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0; release.position = position; release.pressed = false
	Input.parse_input_event(release)
	await settle()
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.set_process(false)
	check(ProjectSettings.get_setting("display/window/handheld/orientation") == 0, "APK requests landscape")
	var export_config := ConfigFile.new()
	export_config.load("res://export_presets.cfg")
	check(export_config.get_value("preset.1.options", "package/app_category") == 2, "Android export uses Godot's Game category")
	check(app.find_child("LoginHuaweiButton", true, false) != null, "Huawei ID button restored")
	app.show_email_sign_in()
	var reset: Control = app.find_child("AuthResetButton", true, false)
	var submit: Control = app.find_child("AuthSubmitButton", true, false)
	check(submit.position.y - reset.get_rect().end.y == 12, "Forgot password and sign-in have a compact gap")
	app._close_email_auth()
	await settle()
	for window_size in [Vector2i(1280,720), Vector2i(1024,768), Vector2i(960,600), Vector2i(640,960), Vector2i(1560,720)]:
		root.size = window_size
		await settle()
		await app.build_menu()
		check(root.get_visible_rect().size.is_equal_approx(Vector2(1280,720)), "Artwork and controls share a fixed viewport: " + str(window_size))
		await tap(Vector2(640,322))
		check(app.current_screen == "map_select", "PLAY responds to tablet touch: " + str(window_size))
		await app.build_menu()
		await tap(Vector2(640,384))
		check(app.current_screen == "create_room", "CREATE ROOM responds to tablet touch: " + str(window_size))
		await tap(Vector2(963,125))
		check(app.current_screen == "menu", "Host setup X returns straight to the main menu: " + str(window_size))
		check(app.find_child("SettingsArtworkButton",true,false)==null, "No duplicate centre Settings button")
		await app.build_menu()
		await tap(Vector2(1099,49))
		check(app.page_controls.dialog_open(), "SETTINGS responds to tablet touch: " + str(window_size))
		app.page_controls.close_dialog()
		await app.build_menu()
		await tap(Vector2(640,430))
		check(app.find_child("JoinRoomCodeOverlay", true, false) != null, "JOIN ROOM responds to tablet touch: " + str(window_size))
		await app.build_menu()
		await tap(Vector2(640,476))
		check(app.page_controls.dialog_open(), "HOW TO PLAY responds to tablet touch: " + str(window_size))
		app.page_controls.close_dialog()
		await app.build_menu()
		await tap(Vector2(640,520))
		check(app.page_controls.dialog_open(), "EXIT opens confirmation from tablet touch: " + str(window_size))
		app.page_controls.close_dialog()
	root.size = Vector2i(1280,720)
	await settle()
	app.selected_character = "Badang"
	await app.build_character_select()
	app.page_controls.refresh(true)
	for node_name in ["UtilityBackButton", "UtilityMusicButton", "UtilitySettingsButton"]:
		check(not app.page_controls.find_child(node_name, true, false).visible, "Character selection hides " + node_name)
	app.completed_tasks = [0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress = [0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map = map_index
		app.player_position = Geometry.task_points(map_index)[5]
		for nenek in [false, true]:
			app.player_is_impostor = nenek
			app._reset_power_state()
			await app.build_game()
			app.player_body.set_physics_process(false)
			app._update_interaction_prompt()
			var hint = app.game_hud.get_node("NearbyTaskHint")
			hint.refresh(0.0, true)
			check(hint.visible == not nenek, "Only villagers get the green task hint: map " + str(map_index))
			check(not app.find_child("InteractionPromptLabel", true, false).text.contains("Tugasan"), "No duplicate yellow task sentence")
			check(app.find_child("VillageTasksPanel", true, false).visible == not nenek, "Task list visibility follows role")
			check((app.game_world.get_node_or_null("TaskMarker_5") == null) == nenek, "Task markers follow role")
			app.show_map_overlay()
			var view = app.find_child("MapOverlay", true, false)
			check(view.find_child("MapTasksTab", true, false).visible == not nenek, "Map task tab follows role")
			if nenek:
				view._tab(true)
				check(not view._tasks.visible, "Nenek cannot open hidden task list")
			view.queue_free()
			await settle()
			app._apply_power_state({"kind":"fog", "area":Geometry.section_at_position(map_index, app.player_position), "fog_origin":app.player_position, "fog_radius":180.0, "seconds_left":20.0})
			var effect = app.game_world.get_node("AreaPowerEffects")
			if nenek:
				check(effect.get_child_count() == 0, "Nenek has no fog tint or blur")
				check(app.player_body.get_meta("sight_radius") == 160.0, "Nenek keeps normal sight")
			else:
				check(effect.get_child_count() > 0, "Villager fog is rendered")
				if effect.get_child_count():
					var material: ShaderMaterial = effect.get_child(0).material
					check(material.get_shader_parameter("mist_density") >= 0.99, "Villager fog is dense")
	print("TABLET AND ROLE CHECKS: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
