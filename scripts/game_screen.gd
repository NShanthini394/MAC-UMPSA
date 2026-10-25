extends RefCounted
## Builds the playable screen while delegating game actions to the main controller.

const GameData = preload("res://scripts/game_data.gd")


func build(app) -> void:
	await app.clear_screen("game")
	app.route_active = false
	app.map_image = app.make_map_texture(load(GameData.MAP_ART), GameData.MAPS[app.selected_map]["region"])
	var map_bg := TextureRect.new(); map_bg.texture = app.map_image; map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; map_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; map_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); app.add_child(map_bg)
	var shade := ColorRect.new(); shade.color = Color(0.04, 0.04, 0.03, 0.22); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); app.add_child(shade)
	var route_line := Line2D.new()
	route_line.name = "RouteLine"; route_line.width = 6.0
	route_line.default_color = Color("ffd263"); route_line.joint_mode = Line2D.LINE_JOINT_ROUND
	route_line.begin_cap_mode = Line2D.LINE_CAP_ROUND; route_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	route_line.visible = false; app.add_child(route_line)
	var header: Panel = app.make_panel(Rect2(12, 10, 1256, 56), Color(0.11, 0.075, 0.045, 0.92))
	var title: Label = app.make_label(GameData.MAPS[app.selected_map]["name"], 19, GameData.GOLD)
	title.position = Vector2(18, 12); title.size = Vector2(440, 32); title.reparent(header, false)
	var role: Label = app.make_label(("NENEK KEBAYAN" if app.player_is_impostor else "VILLAGER") + "  •  " + app.selected_character, 15, GameData.CREAM)
	role.position = Vector2(565, 14); role.size = Vector2(520, 28); role.reparent(header, false)
	var progress: Label = app.make_label("TASKS  %d / 8    •    CLUES  %d / 3" % [app.completed_tasks.count(1), app.collected_clues.size()], 14, GameData.CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	progress.name = "ProgressLabel"; progress.position = Vector2(1010, 12); progress.size = Vector2(225, 32); progress.reparent(header, false)
	var task_panel: Panel = app.make_panel(Rect2(16, 86, 284, 421), Color(0.12, 0.09, 0.06, 0.91))
	var task_title: Label = app.make_label("VILLAGE TASKS", 17, GameData.GOLD)
	task_title.position = Vector2(16, 12); task_title.size = Vector2(250, 27); task_title.reparent(task_panel, false)
	var tasks: Array = GameData.TASKS[GameData.MAPS[app.selected_map]["name"]]
	for i in tasks.size():
		var count_text := "" if app.completed_tasks[i] == 1 else " (%d/%d)" % [app.task_progress[i], GameData.TASK_STEPS[GameData.MAPS[app.selected_map]["name"]][i]]
		var label: Label = app.make_label(("✓ " if app.completed_tasks[i] == 1 else "◇ ") + str(tasks[i]["name"]) + count_text, 13, Color("d8edb2") if app.completed_tasks[i] == 1 else GameData.CREAM)
		label.name = "TaskEntry_%d" % i
		label.position = Vector2(16, 50 + i * 42); label.size = Vector2(254, 39); label.reparent(task_panel, false)
	for i in GameData.TASK_POINTS.size():
		var place: Button = app.make_button(app, "✦ " + str(tasks[i]["place"]), Callable(app, "_travel_hint").bind(i), 148, 34)
		place.position = GameData.TASK_POINTS[i]; place.add_theme_font_size_override("font_size", 11)
		place.modulate = Color(1, 1, 1, 0.9)
	var gong: Button = app.make_button(app, "◉ GONG", Callable(app, "call_meeting"), 104, 38, true)
	gong.position = Vector2(586, 106)
	var online_match: bool = not app.room_code.is_empty() and app.network_manager != null and app.network_manager.is_connected_to_room_server()
	if online_match:
		for member in app.lobby_players:
			if not bool(member.get("alive", true)): continue
			var peer_id := int(member.get("id", -1))
			var actor_position: Vector2 = member.get("position", Vector2(640, 390))
			var actor := Panel.new()
			actor.name = "PlayerActor_%d" % peer_id
			actor.position = actor_position - Vector2(22, 40)
			actor.size = Vector2(44, 56)
			var actor_style := StyleBoxFlat.new()
			actor_style.bg_color = Color("382a1e")
			actor_style.border_color = Color("f7c35a") if peer_id == app.network_manager.local_peer_id() else Color("c5904b")
			actor_style.set_border_width_all(2); actor_style.set_corner_radius_all(8)
			actor.add_theme_stylebox_override("panel", actor_style)
			var portrait := TextureRect.new()
			var character := str(member.get("character", ""))
			if GameData.CHARACTER_AVATARS.has(character): portrait.texture = load(GameData.CHARACTER_AVATARS[character])
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			portrait.position = Vector2(5, 3); portrait.size = Vector2(34, 34); portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			actor.add_child(portrait)
			var name_label: Label = app.make_label(str(member.get("name", "Player")), 9, GameData.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			name_label.position = Vector2(-14, 36); name_label.size = Vector2(72, 18); name_label.clip_text = true
			actor.add_child(name_label)
			app.add_child(actor)
			if app.player_is_impostor and peer_id != app.network_manager.local_peer_id():
				var eliminate: Button = app.make_button(actor, "ELIM", Callable(app, "_request_eliminate_player").bind(peer_id), 50, 24, true)
				eliminate.position = Vector2(-3, 57)
	else:
		for i in GameData.NPC_NAMES.size():
			if app.dead_npcs.has(GameData.NPC_NAMES[i]): continue
			var npc: Button = app.make_button(app, "● " + GameData.NPC_NAMES[i], Callable(app, "_travel_npc").bind(i), 142, 32)
			npc.position = GameData.NPC_POINTS[i]; npc.add_theme_font_size_override("font_size", 11)
	var clue_points: Array = app.clue_points if online_match and app.clue_points.size() == 3 else [Vector2(335, 320), Vector2(720, 520), Vector2(1065, 265)]
	var character_clues: Array = GameData.CHARACTER_CLUES.get(app.impostor_character, [])
	for i in clue_points.size():
		if online_match and i in app.network_found_clues: continue
		if not online_match and i < character_clues.size() and app.collected_clues.has(character_clues[i]): continue
		var clue: Button = app.make_button(app, "⌕ CLUE", Callable(app, "_travel_clue").bind(i), 84, 32)
		clue.name = "ClueMarker_%d" % i
		clue.position = clue_points[i]; clue.add_theme_font_size_override("font_size", 11)
	if not online_match:
		var pawn: Panel = app.make_panel(Rect2(app.player_position - Vector2(20, 24), Vector2(40, 48)), Color("f5bc51"))
		pawn.name = "Pawn"
		var pawn_label: Label = app.make_label("YOU", 12, GameData.INK, HORIZONTAL_ALIGNMENT_CENTER)
		pawn_label.position = Vector2(1, 13); pawn_label.size = Vector2(38, 20); pawn_label.reparent(pawn, false)
	var notice: Label = app.make_label("", 15, Color("fff3cd"), HORIZONTAL_ALIGNMENT_CENTER)
	notice.name = "NoticeLabel"; notice.position = Vector2(310, 612); notice.size = Vector2(660, 28)
	build_control_bar(app)
	var leave: Button = app.make_button(app, "MENU", Callable(app, "show_exit_confirmation"), 88, 36)
	leave.position = Vector2(1180, 665)


func build_control_bar(app) -> void:
	var pad := Panel.new()
	pad.name = "VirtualJoystick"; pad.position = Vector2(30, 540); pad.size = Vector2(148, 148)
	var pad_style := StyleBoxFlat.new(); pad_style.bg_color = Color(0.12, 0.09, 0.06, 0.70); pad_style.border_color = Color("d3a24e")
	pad_style.set_border_width_all(2); pad_style.set_corner_radius_all(74); pad.add_theme_stylebox_override("panel", pad_style)
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	var knob := Panel.new(); knob.name = "JoystickKnob"; knob.position = Vector2(49, 49); knob.size = Vector2(50, 50)
	var knob_style := StyleBoxFlat.new(); knob_style.bg_color = Color("e6bd7d", 0.85); knob_style.border_color = Color("fff0cf")
	knob_style.set_border_width_all(2); knob_style.set_corner_radius_all(25); knob.add_theme_stylebox_override("panel", knob_style)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE; pad.add_child(knob)
	pad.gui_input.connect(Callable(app, "_on_joystick_input").bind(pad, knob))
	app.add_child(pad)
	var interact: Button = app.make_button(app, "INTERACT  [E]", Callable(app, "interact_nearest"), 164, 46, true)
	interact.position = Vector2(1005, 605)
	var inspect: Button = app.make_button(app, "INSPECT CLUE", Callable(app, "inspect_nearest_clue"), 164, 42)
	inspect.position = Vector2(1005, 657)
	var map_button: Button = app.make_button(app, "MAP", Callable(app, "show_map_overlay"), 120, 38)
	map_button.position = Vector2(824, 610)
	var journal: Button = app.make_button(app, "CLUE JOURNAL", Callable(app, "show_journal"), 156, 38)
	journal.position = Vector2(824, 657)
	if app.player_is_impostor:
		var kill: Button = app.make_button(app, "ELIMINATE", Callable(app, "eliminate_nearest"), 136, 42, true)
		kill.position = Vector2(620, 664)
