extends RefCounted
## Builds the playable screen while delegating game actions to the main controller.

const GameData = preload("res://scripts/game_data.gd")
const MapGeometry = preload("res://scripts/map_geometry.gd")


func build(app) -> void:
	await app.clear_screen("game")
	app.route_active = false
	app.map_image = app.make_map_texture(load(GameData.MAP_ART), GameData.MAPS[app.selected_map]["region"])
	var world := Node2D.new()
	world.name = "GameWorld"
	app.game_world = world
	app.add_child(world)
	var hud := CanvasLayer.new()
	hud.name = "GameHUD"
	hud.layer = 10
	app.game_hud = hud
	app.add_child(hud)
	var map_region: Rect2 = GameData.MAPS[app.selected_map]["region"]
	var world_size: Vector2 = MapGeometry.world_size(app.selected_map)
	var map_scale := maxf(world_size.x / map_region.size.x, world_size.y / map_region.size.y)
	var map_sprite := Sprite2D.new()
	map_sprite.name = "MapArtwork"
	map_sprite.texture = app.map_image
	map_sprite.centered = false
	map_sprite.scale = Vector2.ONE * map_scale
	map_sprite.position = (world_size - map_region.size * map_scale) / 2.0
	map_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(map_sprite)
	_add_map_collisions(world, app.selected_map)
	var route_line := Line2D.new()
	route_line.name = "RouteLine"; route_line.width = 6.0
	route_line.default_color = Color("ffd263"); route_line.joint_mode = Line2D.LINE_JOINT_ROUND
	route_line.begin_cap_mode = Line2D.LINE_CAP_ROUND; route_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	route_line.visible = false; world.add_child(route_line)
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
	var task_points: Array = MapGeometry.task_points(app.selected_map)
	for i in task_points.size():
		_add_world_marker(world, task_points[i], "✦", GameData.GOLD, "TaskMarker_%d" % i)
	_add_world_marker(world, MapGeometry.gong_point(app.selected_map), "◉", Color("ffdb6b"), "MeetingGongMarker")
	var online_match: bool = not app.room_code.is_empty() and app.network_manager != null and app.network_manager.is_connected_to_room_server()
	if online_match:
		var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
		for member in app.lobby_players:
			if not bool(member.get("alive", true)): continue
			var peer_id := int(member.get("id", -1))
			var actor_position: Vector2 = member.get("position", MapGeometry.spawn_point(app.selected_map))
			var character := str(member.get("character", ""))
			var is_local: bool = peer_id == app.network_manager.local_peer_id()
			var actor := player_scene.instantiate() as CharacterBody2D
			actor.name = "PlayerActor_%d" % peer_id
			actor.position = actor_position
			actor.set("is_local_player", is_local)
			actor.set("is_network_driven", true)
			world.add_child(actor)
			actor.call("configure", character, str(member.get("name", "Player")), is_local, true)
			var camera := actor.get_node("Camera2D") as Camera2D
			camera.limit_left = 0; camera.limit_top = 0
			camera.limit_right = ceili(world_size.x); camera.limit_bottom = ceili(world_size.y)
			if is_local: app.player_body = actor
			if app.player_is_impostor and peer_id != app.network_manager.local_peer_id():
				_add_world_marker(world, actor_position + Vector2(0, -66), "!", Color("ff7770"), "EliminateMarker_%d" % peer_id)
	else:
		for i in GameData.NPC_NAMES.size():
			if app.dead_npcs.has(GameData.NPC_NAMES[i]): continue
			_add_npc_actor(world, GameData.NPC_NAMES[i], MapGeometry.npc_points(app.selected_map)[i])
	var clue_points: Array = app.clue_points if app.clue_points.size() == 3 else MapGeometry.clue_candidates(app.selected_map).slice(0, 3)
	var character_clues: Array = GameData.CHARACTER_CLUES.get(app.impostor_character, [])
	for i in clue_points.size():
		if online_match and i in app.network_found_clues: continue
		if not online_match and i < character_clues.size() and app.collected_clues.has(character_clues[i]): continue
		_add_world_marker(world, clue_points[i], "?", Color("8fe4ff"), "ClueMarker_%d" % i)
	if not online_match:
		var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
		var pawn := player_scene.instantiate() as CharacterBody2D
		pawn.name = "Pawn"
		pawn.position = app.player_position
		world.add_child(pawn)
		pawn.call("configure", app.selected_character, app.lobby_player_name, true, false)
		var camera := pawn.get_node("Camera2D") as Camera2D
		camera.limit_left = 0; camera.limit_top = 0
		camera.limit_right = ceili(world_size.x); camera.limit_bottom = ceili(world_size.y)
		app.player_body = pawn
	if app.selected_map == 1:
		var foreground := Sprite2D.new()
		foreground.name = "PakKadukForeground"
		foreground.texture = load("res://assets/maps/pak_kaduk_foreground.png") as Texture2D
		foreground.region_enabled = true
		foreground.region_rect = map_region
		foreground.centered = false
		foreground.scale = Vector2.ONE * map_scale
		foreground.position = map_sprite.position
		foreground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		foreground.z_index = 20
		world.add_child(foreground)
	var notice: Label = app.make_label("", 15, Color("fff3cd"), HORIZONTAL_ALIGNMENT_CENTER)
	notice.name = "NoticeLabel"; notice.position = Vector2(310, 612); notice.size = Vector2(660, 28)
	var prompt: Label = app.make_label("", 13, GameData.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	prompt.name = "InteractionPromptLabel"; prompt.position = Vector2(820, 574); prompt.size = Vector2(350, 24)
	build_control_bar(app)
	var leave: Button = app.make_button(app, "MENU", Callable(app, "show_exit_confirmation"), 88, 36)
	leave.position = Vector2(1180, 665)
	app.current_area_name = ""


func _add_map_collisions(world: Node2D, map_index: int) -> void:
	var obstacles := Node2D.new()
	obstacles.name = "MapCollision"
	world.add_child(obstacles)
	for rect in MapGeometry.obstacles(map_index):
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = rect.position + rect.size / 2.0
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		body.add_child(shape)
		obstacles.add_child(body)


func _add_world_marker(world: Node2D, position: Vector2, text: String, color: Color, marker_name: String) -> void:
	var marker := Label.new()
	marker.name = marker_name
	marker.text = text
	marker.position = position - Vector2(15, 19)
	marker.size = Vector2(30, 38)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_theme_font_size_override("font_size", 24)
	marker.add_theme_color_override("font_color", color)
	marker.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	marker.add_theme_constant_override("shadow_offset_x", 2)
	marker.add_theme_constant_override("shadow_offset_y", 2)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(marker)


func _add_npc_actor(world: Node2D, character: String, position: Vector2) -> void:
	var npc := Node2D.new()
	npc.name = "NPC_%s" % character.replace(" ", "_")
	npc.position = position
	var sprite := Sprite2D.new()
	if GameData.CHARACTER_AVATARS.has(character):
		sprite.texture = load(GameData.CHARACTER_AVATARS[character])
	sprite.scale = Vector2(0.18, 0.18)
	sprite.position = Vector2(0, -10)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc.add_child(sprite)
	var name_label := Label.new()
	name_label.text = character
	name_label.position = Vector2(-56, -52)
	name_label.size = Vector2(112, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", GameData.CREAM)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	npc.add_child(name_label)
	world.add_child(npc)


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
	app.game_hud.add_child(pad)
	var interact: Button = app.make_button(app, "INTERACT  [E]", Callable(app, "interact_nearest"), 164, 46, true)
	interact.name = "InteractButton"
	interact.position = Vector2(1005, 605)
	var inspect: Button = app.make_button(app, "INSPECT CLUE", Callable(app, "inspect_nearest_clue"), 164, 42)
	inspect.name = "InspectClueButton"
	inspect.position = Vector2(1005, 657)
	var map_button: Button = app.make_button(app, "MAP", Callable(app, "show_map_overlay"), 120, 38)
	map_button.position = Vector2(824, 610)
	var journal: Button = app.make_button(app, "CLUE JOURNAL", Callable(app, "show_journal"), 156, 38)
	journal.position = Vector2(824, 657)
	if app.player_is_impostor:
		var kill: Button = app.make_button(app, "KILL", Callable(app, "eliminate_nearest"), 136, 42, true)
		kill.position = Vector2(620, 664)
