extends RefCounted
## Builds the playable screen while delegating game actions to the main controller.

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/game_ui.gd")
const MapGeometry = preload("res://scripts/map_geometry.gd")


func build(app) -> void:
	await app.clear_screen("game")
	app.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.get_viewport().physics_object_picking = true
	app.route_active = false
	app.map_image = app.make_map_texture(load(GameData.map_art_path(app.selected_map)), GameData.MAPS[app.selected_map]["region"])
	var world := Node2D.new()
	world.name = "GameWorld"
	app.game_world = world
	app.add_child(world)
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "GameHUDLayer"
	hud_layer.layer = 10
	app.add_child(hud_layer)
	var hud := Control.new()
	hud.name = "GameHUD"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)
	hud.set_anchors_preset(Control.PRESET_CENTER)
	hud.offset_left = -640; hud.offset_right = 640
	hud.offset_top = -360; hud.offset_bottom = 360
	app.game_hud = hud
	app._update_canvas_layout()
	var map_region: Rect2 = GameData.MAPS[app.selected_map]["region"]
	var world_size: Vector2 = MapGeometry.world_size(app.selected_map)
	var map_scale := maxf(world_size.x / map_region.size.x, world_size.y / map_region.size.y)
	var map_sprite := Sprite2D.new()
	map_sprite.name = "MapArtwork"
	map_sprite.texture = app.map_image
	map_sprite.centered = false
	map_sprite.scale = Vector2.ONE * map_scale
	map_sprite.position = (world_size - map_region.size * map_scale) / 2.0
	# The palace camera zooms into this atlas crop. Linear sampling avoids the
	# visibly enlarged square pixels while keeping the character sprites crisp.
	map_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	world.add_child(map_sprite)
	var gong := preload("res://scripts/gong_marker.gd").new()
	gong.name = "MeetingGongMarker"
	gong.map_index = app.selected_map
	gong.position = MapGeometry.gong_point(app.selected_map)
	gong.pressed.connect(func():
		if not app._utility_dialog_open() and app.find_child("MapOverlay", true, false) == null:
			app.call_meeting())
	world.add_child(gong)
	var paths := load("res://scripts/map_paths_visual.gd").new() as Node2D
	paths.name = "PathsAndEntrances"
	paths.set("map_index", app.selected_map)
	paths.scale = MapGeometry.floor_plan(app.selected_map).scale
	world.add_child(paths)
	_add_map_collisions(world, app.selected_map)
	var route_line := Line2D.new()
	route_line.name = "RouteLine"; route_line.width = 6.0
	route_line.default_color = Color("17151c"); route_line.joint_mode = Line2D.LINE_JOINT_ROUND
	route_line.begin_cap_mode = Line2D.LINE_CAP_ROUND; route_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	route_line.visible = false; world.add_child(route_line)
	var header: Panel = app.make_panel(Rect2(12, 10, 1256, 56), Color(0.11, 0.075, 0.045, 0.92))
	app._make_child_label(header, GameData.MAPS[app.selected_map]["name"], 19, GameData.GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(18, 12, 440, 32))
	app._make_child_label(header, ("NENEK KEBAYAN" if app.player_is_impostor else "VILLAGER") + "  •  " + app.selected_character, 15, GameData.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(565, 14, 420, 28))
	var progress: Label = app._make_child_label(header, "TASKS  %d / %d    •    CLUES  %d / %d" % [app.completed_tasks.count(1), GameData.TASKS[GameData.MAPS[app.selected_map]["name"]].size(), app.collected_clues.size(), app.clue_points.size() if not app.room_code.is_empty() else app.CHARACTER_CLUES.get(app.impostor_character, []).size()], 13, GameData.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, Rect2(970, 12, 265, 32))
	progress.name = "ProgressLabel"
	progress.visible = not app.player_is_impostor
	var task_panel_height := 438.0 if app.village_tasks_expanded else 68.0
	var task_panel: Panel = app.make_panel(Rect2(16, 86, 284, task_panel_height), Color(0.12, 0.09, 0.06, 0.91))
	task_panel.name = "VillageTasksPanel"
	task_panel.visible = not app.player_is_impostor
	task_panel.clip_contents = true
	task_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var toggle_text := "VILLAGE TASKS  −" if app.village_tasks_expanded else "VILLAGE TASKS  +"
	var task_toggle: Button = app.make_button(task_panel, toggle_text, Callable(app, "toggle_village_tasks"), 260, 52, true)
	task_toggle.name = "VillageTasksToggle"
	task_toggle.position = Vector2(12, 7)
	task_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	task_toggle.add_theme_font_size_override("font_size", 17)
	var tasks: Array = GameData.TASKS[GameData.MAPS[app.selected_map]["name"]]
	var task_scroll := ScrollContainer.new()
	task_scroll.name = "VillageTaskScroll"
	task_scroll.position = Vector2(8,66)
	task_scroll.size = Vector2(268,362)
	task_scroll.visible = app.village_tasks_expanded
	task_panel.add_child(task_scroll)
	var task_rows := Control.new()
	task_rows.custom_minimum_size = Vector2(248,tasks.size()*52)
	task_scroll.add_child(task_rows)
	for i in tasks.size():
		var count_text := "" if app.completed_tasks[i] == 1 else " (%d/%d)" % [app.task_progress[i], GameData.TASK_STEPS[GameData.MAPS[app.selected_map]["name"]][i]]
		var task_text := ("✓ " if app.completed_tasks[i] == 1 else "◇ ") + str(tasks[i]["name"]) + count_text
		task_text = _wrap_task_text(task_text, 30)
		var label: Label = app._make_child_label(task_rows, task_text, 13, Color("61f28a") if app.completed_tasks[i] == 1 else GameData.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(8, i * 52, 240, 48))
		label.name = "TaskEntry_%d" % i
		label.visible = app.village_tasks_expanded
		label.clip_text = true
	var task_points: Array = MapGeometry.task_points(app.selected_map)
	for i in task_points.size():
		if app.player_is_impostor: continue
		var station := load("res://scripts/realistic_task_station.gd").new() as Node2D
		station.name = "TaskMarker_%d" % i
		station.position = task_points[i]
		station.set("task_index",i)
		station.visible = app.completed_tasks[i] == 0
		station.connect("interact_requested",func():
			if app.current_screen == "game" and app.task_overlay_index < 0 and not app._utility_dialog_open() and app.find_child("MapOverlay",true,false)==null:
				app.open_task(i))
		world.add_child(station)
	var online_match: bool = not app.room_code.is_empty() and app.network_manager != null and app.network_manager.is_connected_to_room_server()
	if online_match:
		var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
		for member in app.lobby_players:
			var peer_id := int(member.get("id", -1))
			if not bool(member.get("alive", true)) and peer_id != app.network_manager.local_peer_id(): continue
			var actor_position: Vector2 = member.get("position", MapGeometry.spawn_point(app.selected_map))
			var character := str(member.get("character", ""))
			var is_local: bool = peer_id == app.network_manager.local_peer_id()
			var actor := player_scene.instantiate() as CharacterBody2D
			actor.name = "PlayerActor_%d" % peer_id
			actor.position = actor_position
			actor.set("map_index", app.selected_map)
			actor.set("is_local_player", is_local)
			actor.set("is_network_driven", true)
			if app.selected_map == 0:
				actor.set("move_speed", 150.0)
			world.add_child(actor)
			actor.call("configure", character, str(member.get("name", "Player")), is_local, true)
			var camera := actor.get_node("Camera2D") as Camera2D
			camera.limit_left = 0; camera.limit_top = 0
			camera.limit_right = ceili(world_size.x); camera.limit_bottom = ceili(world_size.y)
			if is_local:
				app.player_body = actor
				_configure_player_camera_and_vision(actor)
			actor.call("set_sleeping", bool(member.get("sleeping", false)))
			actor.set("inactive", not bool(member.get("alive", true)))
	var clue_points: Array = app.clue_points if not app.clue_points.is_empty() else MapGeometry.clue_candidates(app.selected_map).slice(0, 3)
	var character_clues: Array = GameData.CHARACTER_CLUES.get(app.impostor_character, [])
	for i in clue_points.size():
		if app.player_is_impostor: continue
		if online_match and i in app.network_found_clues: continue
		if not online_match and i < character_clues.size() and app.collected_clues.has(character_clues[i]): continue
		var clue_marker := load("res://scripts/clue_marker.gd").new() as Node2D
		clue_marker.name = "ClueMarker_%d" % i
		clue_marker.position = clue_points[i]
		clue_marker.set("clue_index",i)
		world.add_child(clue_marker)
	if not online_match:
		var player_scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
		var pawn := player_scene.instantiate() as CharacterBody2D
		pawn.name = "Pawn"
		pawn.position = app.player_position
		pawn.set("map_index", app.selected_map)
		if app.selected_map == 0:
			pawn.set("move_speed", 150.0)
		world.add_child(pawn)
		pawn.call("configure", app.selected_character, app.lobby_player_name, true, false)
		pawn.set("locked_entrances", app.locked_entrances())
		var camera := pawn.get_node("Camera2D") as Camera2D
		camera.limit_left = 0; camera.limit_top = 0
		camera.limit_right = ceili(world_size.x); camera.limit_bottom = ceili(world_size.y)
		app.player_body = pawn
		_configure_player_camera_and_vision(pawn)
	if is_instance_valid(app.player_body):
		_configure_local_visibility(world, app.player_body)
	var notice: Label = app.make_label("", 15, Color("fff3cd"), HORIZONTAL_ALIGNMENT_CENTER)
	notice.name = "NoticeLabel"; notice.position = Vector2(310, 536); notice.size = Vector2(660, 48)
	var prompt: Label = app.make_label("", 13, GameData.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	prompt.name = "InteractionPromptLabel"; prompt.position = Vector2(820, 574); prompt.size = Vector2(350, 24)
	build_control_bar(app)
	var status: Label = app.make_label("", 14, GameData.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	status.name = "PowerStatusLabel"; status.position = Vector2(310, 82); status.size = Vector2(660, 40)
	var watching: Label = app.make_label("", 16, Color("c9e4ff"), HORIZONTAL_ALIGNMENT_CENTER)
	watching.name = "WatchingLabel"; watching.position = Vector2(330, 651); watching.size = Vector2(460, 55)


func _wrap_task_text(text: String, max_chars: int) -> String:
	var words := text.split(" ", false)
	var lines: Array[String] = []
	var current_line := ""
	for word in words:
		if current_line.is_empty():
			current_line = word
		elif current_line.length() + word.length() + 1 > max_chars:
			lines.append(current_line)
			current_line = word
		else:
			current_line += " " + word
	if not current_line.is_empty():
		lines.append(current_line)
	return "\n   ".join(lines)


func _add_map_collisions(world: Node2D, map_index: int) -> void:
	var obstacles := Node2D.new()
	obstacles.name = "MapCollision"
	world.add_child(obstacles)
	var boundary := StaticBody2D.new()
	boundary.name = "FloorBoundary"
	boundary.collision_layer = 1
	boundary.collision_mask = 0
	obstacles.add_child(boundary)
	for edge in MapGeometry.floor_plan(map_index).edges:
		var segment := SegmentShape2D.new()
		segment.a = edge[0]
		segment.b = edge[1]
		var collision := CollisionShape2D.new()
		collision.shape = segment
		boundary.add_child(collision)
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


func _configure_player_camera_and_vision(player: CharacterBody2D) -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.zoom = Vector2(1.7, 1.7)
	# Bright map artwork; sight/door collision checks remain independent of tint.


func _configure_local_visibility(world: Node2D, observer: CharacterBody2D) -> void:
	var visibility_script: Script = load("res://scripts/player_visibility.gd") as Script
	for child in world.get_children():
		if child == observer or not child is CanvasItem:
			continue
		var child_name := child.name as String
		var is_actor := child is CharacterBody2D or child_name.begins_with("NPC_")
		if not is_actor:
			continue
		var visibility_tracker: Node = visibility_script.new()
		visibility_tracker.call("configure", observer, child, 160.0)
		world.add_child(visibility_tracker)


func _add_light_occluder(world: Node2D, rect: Rect2) -> void:
	var polygon := OccluderPolygon2D.new()
	var half_size := rect.size / 2.0
	polygon.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y), Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y), Vector2(-half_size.x, half_size.y)
	])
	var occluder := LightOccluder2D.new()
	occluder.occluder = polygon
	occluder.position = rect.position + half_size
	world.add_child(occluder)


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


func build_control_bar(app) -> void:
	var pad := preload("res://scripts/invisible_joystick_area.gd").new()
	pad.name = "VirtualJoystick"; pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pad.offset_left = 0; pad.offset_top = -360; pad.offset_right = 640; pad.offset_bottom = 0
	pad.size = Vector2(640, 360)
	pad.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	var knob := Control.new()
	knob.name = "JoystickKnob"
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(knob)
	pad.gui_input.connect(Callable(app, "_on_joystick_input").bind(pad, knob))
	app.game_hud.add_child(pad)
	app.game_hud.move_child(pad, 0)
	# Map and journal sit high at the right edge; the action cluster stays low
	# beside the player's right thumb without a large, opaque dock panel.
	var navigation := VBoxContainer.new()
	navigation.name = "NavigationButtons"
	navigation.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	navigation.offset_left = -88; navigation.offset_top = 148
	navigation.offset_right = -12; navigation.offset_bottom = 268
	navigation.add_theme_constant_override("separation", 8)
	app.game_hud.add_child(navigation)
	_add_dock_button(app, navigation, "GameMapButton", "res://assets/ui/map_icon.svg", "Map", Callable(app, "show_map_overlay"), false)
	_add_dock_button(app, navigation, "GameJournalButton", "res://assets/ui/journal_icon.svg", "Clue journal", Callable(app, "show_journal"), false)
	var actions := Control.new()
	actions.name = "GameActionButtons"
	actions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# This transparent full-screen holder must not swallow taps meant for the
	# task list, joystick, or other HUD controls behind its child buttons.
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.game_hud.add_child(actions)
	var interact := _add_dock_button(app, actions, "InteractButton", "res://assets/ui/interact_icon.svg", "Interact · E", Callable(app, "interact_nearest"), true, Vector2(88, 88))
	interact.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	interact.offset_left = -114; interact.offset_top = -146
	interact.offset_right = -26; interact.offset_bottom = -58
	var inspect := _add_dock_button(app, actions, "InspectClueButton", "res://assets/ui/clue_icon.svg", "Inspect clue", Callable(app, "inspect_nearest_clue"), false, Vector2(88, 88))
	inspect.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	inspect.offset_left = -114; inspect.offset_top = -246
	inspect.offset_right = -26; inspect.offset_bottom = -158
	inspect.visible = not app.player_is_impostor
	if app.player_is_impostor:
		var powers := HBoxContainer.new()
		powers.name = "PowerActionButtons"
		powers.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		powers.offset_left = -194; powers.offset_top = -292
		powers.offset_right = -20; powers.offset_bottom = -236
		powers.add_theme_constant_override("separation", 6)
		app.game_hud.add_child(powers)
		_add_dock_button(app, powers, "SleepSpellButton", "res://assets/ui/sleep_icon.svg", "Sleep spell", Callable(app, "cast_sleep_spell"), true, Vector2(54, 54))
		_add_dock_button(app, powers, "FogButton", "res://assets/ui/fog_icon.svg", "Fog", Callable(app, "cast_sabotage").bind("fog"), true, Vector2(54, 54))
		_add_dock_button(app, powers, "DoorLockButton", "res://assets/ui/lock_icon.svg", "Door lock", Callable(app, "cast_sabotage").bind("lock"), true, Vector2(54, 54))
	var task_hint := load("res://scripts/nearby_task_hint.gd").new() as PanelContainer
	app.game_hud.add_child(task_hint)
	task_hint.call("configure", app)


func _add_dock_button(app, parent: Control, node_name: String, icon_path: String, hint: String, callback: Callable, highlighted: bool, button_size: Vector2 = Vector2(72, 72)) -> Button:
	var button: Button = app.make_button(parent, "", callback, button_size.x, button_size.y, highlighted)
	button.name = node_name
	button.custom_minimum_size = button_size
	button.icon = load(icon_path) as Texture2D
	button.expand_icon = true
	button.tooltip_text = hint
	button.accessibility_name = hint
	UI.apply_menu_button(button)
	button.add_theme_constant_override("icon_max_width", roundi(button_size.x - 16))
	return button


func refresh_power_effects(app) -> void:
	if not is_instance_valid(app.game_world): return
	var old_effect: Node = app.game_world.get_node_or_null("AreaPowerEffects")
	if old_effect:
		app.game_world.remove_child(old_effect)
		old_effect.queue_free()
	if app.active_power_kind.is_empty(): return
	var effect: Node2D = load("res://scripts/area_power_effects.gd").new()
	effect.name = "AreaPowerEffects"
	app.game_world.add_child(effect)
	effect.call("configure", app.selected_map, app.active_power_kind, app.active_power_area, app.player_is_impostor, app.active_fog_origin, app.active_fog_radius, app.player_body)
