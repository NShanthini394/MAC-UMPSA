extends Control
## Nenek Kebayan: Siapa Pengkhianat? game controller.

const GameData = preload("res://scripts/game_data.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const GameScreen = preload("res://scripts/game_screen.gd")
const NetworkManagerScript = preload("res://scripts/network_manager.gd")
const MapGeometry = preload("res://scripts/map_geometry.gd")
const NenekPowers = preload("res://scripts/nenek_powers.gd")
const PageControls = preload("res://scripts/page_controls.gd")
const LoginScreen = preload("res://scripts/login_screen.gd")
const MultiplayerSetup = preload("res://scripts/multiplayer_setup.gd")
const LanHost = preload("res://scripts/lan_host.gd")
const MENU_ART := GameData.MENU_ART
const WAITING_ROOM_ART := GameData.WAITING_ROOM_ART
const MAP_ART := GameData.MAP_ART
const CAST_ART := GameData.CAST_ART
const INK := GameData.INK
const CREAM := GameData.CREAM
const GOLD := GameData.GOLD
const PANEL := GameData.PANEL
const CHARACTERS := GameData.CHARACTERS
const MAP_CHARACTERS := GameData.MAP_CHARACTERS
const CHARACTER_PORTRAITS := GameData.CHARACTER_PORTRAITS
const CHARACTER_AVATARS := GameData.CHARACTER_AVATARS
const CHARACTER_CLUES := GameData.CHARACTER_CLUES
const MAPS := GameData.MAPS
const TASKS := GameData.TASKS
const TASK_POINTS := GameData.TASK_POINTS
const TASK_STEPS := GameData.TASK_STEPS
const NPC_NAMES := GameData.NPC_NAMES
const NPC_POINTS := GameData.NPC_POINTS
const DEBUG_FORCE_NENEK_FOR_TESTING := true
var current_screen := "menu"
var selected_map := 0
var lobby_player_name := "Player 1"
var waiting_elapsed := 0.0
var room_code := ""
var room_is_host := false
var lobby_players: Array = []
var selected_character := ""
var character_reservations: Dictionary = {}
var route_target := Vector2.ZERO
var route_active := false
var auto_start_triggered := false
var impostor_character := ""
var assigned_role_character := ""
var player_is_impostor := false
var player_sleeping := false
var player_voted_out := false
var active_power_kind := ""
var active_power_area := -1
var active_power_until := 0.0
var sleep_ready_at := 0.0
var sabotage_ready_at := 0.0
var practice_power_room: Dictionary = {}
var active_fog_origin := Vector2.ZERO
var active_fog_radius := NenekPowers.FOG_RADIUS
var last_power_sequence := 0
var village_tasks_expanded := false
var player_position := Vector2(640, 390)
var move_vector := Vector2.ZERO
var completed_tasks: Array[int] = []
var task_progress: Array[int] = []
var collected_clues: Array[String] = []
var task_overlay_index := -1
var last_notice := ""
var last_notice_time := 0.0
var audio_muted := false
var audio_volume := 100.0
var page_controls: CanvasLayer
var dead_npcs: Array[String] = []
var rng := RandomNumberGenerator.new()
var map_image: Texture2D
var game_screen := GameScreen.new()
var game_world: Node2D
var game_hud: CanvasLayer
var player_body: CharacterBody2D
var current_area_name := ""
var network_manager = null
var lan_host: Node
var _lobby_refresh_queued := false
var server_address := "127.0.0.1"
var clue_points: Array = []
var network_found_clues: Array[int] = []
var network_meeting_state := ""
var network_meeting_seconds := 0
var network_meeting_tick := 0.0
var network_votes_cast := 0
var network_alive_count := 0
var network_chat_lines: Array[String] = []
var network_vote_selection := -1
var network_vote_submitted := false


func _ready() -> void:
	rng.randomize()
	# Client and optional LAN server run separate APIs with identical relative RPC paths.
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())
	var audio_bus := AudioServer.get_bus_index("Master")
	if audio_bus >= 0:
		audio_muted = AudioServer.is_bus_mute(audio_bus)
		audio_volume = clampf(db_to_linear(AudioServer.get_bus_volume_db(audio_bus)) * 100.0, 0.0, 100.0)
	server_address = str(ProjectSettings.get_setting("network/server_address", "127.0.0.1"))
	network_manager = NetworkManagerScript.new()
	network_manager.name = "NetworkManager"
	network_manager.server_port = int(ProjectSettings.get_setting("network/server_port", 7000))
	add_child(network_manager)
	if "--server" in OS.get_cmdline_user_args():
		set_process(false)
		return
	lan_host = LanHost.new()
	lan_host.name = "LanServer"
	add_child(lan_host)
	network_manager.connection_changed.connect(_on_network_connection_changed)
	network_manager.room_opened.connect(_on_network_room_opened)
	network_manager.room_changed.connect(_on_network_room_changed)
	network_manager.room_error.connect(_on_network_room_error)
	network_manager.role_received.connect(_on_network_role_received)
	network_manager.match_started.connect(_on_network_match_started)
	network_manager.positions_changed.connect(_on_network_positions_changed)
	network_manager.task_state_changed.connect(_on_network_task_state_changed)
	network_manager.task_resolved.connect(_on_network_task_resolved)
	network_manager.clue_found.connect(_on_network_clue_found)
	network_manager.meeting_changed.connect(_on_network_meeting_changed)
	network_manager.chat_received.connect(_on_network_chat_received)
	network_manager.meeting_result.connect(_on_network_meeting_result)
	network_manager.match_finished.connect(_on_network_match_finished)
	network_manager.ability_feedback.connect(show_notice)
	page_controls = PageControls.new()
	add_child(page_controls)
	page_controls.call("configure", self)
	build_login_screen()


func _process(delta: float) -> void:
	if is_instance_valid(page_controls): page_controls.call("refresh")
	var now := Time.get_ticks_msec() / 1000.0
	if active_power_kind != "" and now >= active_power_until:
		active_power_kind = ""
		active_power_area = -1
		game_screen.refresh_power_effects(self)
	if room_code.is_empty() and not practice_power_room.is_empty():
		NenekPowers.expire_sabotage(practice_power_room, now)
	if current_screen in ["game", "meeting"]:
		_update_power_view()
		_update_power_hud()
	if now - last_notice_time > 2.4:
		var notice_label := find_child("NoticeLabel", true, false) as Label
		if notice_label: notice_label.text = ""
		var menu_notice := find_child("MenuNoticeLabel", true, false) as Label
		if menu_notice: menu_notice.text = ""
		var room_notice := find_child("RoomErrorNotice", true, false) as Label
		if room_notice: room_notice.text = ""
	if current_screen == "meeting":
		var timer_label := find_child("MeetingTimerLabel", true, false) as Label
		network_meeting_tick += delta
		if timer_label and network_meeting_seconds > 0 and network_meeting_tick >= 1.0:
			network_meeting_tick -= 1.0
			network_meeting_seconds = maxi(0, network_meeting_seconds - 1)
			timer_label.text = ("DISCUSSION" if network_meeting_state == "discussion" else "VOTING") + "  •  %ds" % network_meeting_seconds
	if current_screen == "waiting_room":
		waiting_elapsed += delta
		var player_count := lobby_players.size()
		var ready_count := 0
		for member in lobby_players:
			if bool(member.get("ready", false)): ready_count += 1
		var timer_label := find_child("LobbyStatusLabel", true, false) as Label
		if timer_label:
			var elapsed := int(waiting_elapsed)
			var wait_text := "WAITING FOR PLAYERS" if player_count < 5 else ("ALL PLAYERS READY!" if _all_lobby_players_ready() else "WAITING %02d:%02d" % [floori(float(elapsed) / 60.0), elapsed % 60])
			timer_label.text = "%d / 10 PLAYERS   •   READY %d/%d   •   %s" % [player_count, ready_count, player_count, wait_text]
		var ready_button := find_child("LobbyReadyButton", true, false) as Button
		if ready_button:
			var is_ready := _local_player_is_ready()
			ready_button.text = "READY ✓" if is_ready else "NOT READY"
			_apply_ready_button_color(ready_button, is_ready)
			ready_button.disabled = selected_character.is_empty()
		var start_button := find_child("LobbyStartButton", true, false) as Button
		var all_ready := _all_lobby_players_ready()
		if start_button:
			var network_room: bool = not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server()
			start_button.visible = not network_room or room_is_host
			start_button.disabled = not all_ready or (network_room and player_count < 5) or player_count >= 10
			start_button.text = "START GAME" if player_count < 10 else "AUTO START AT 10"
		if player_count == 10 and all_ready and not auto_start_triggered and (network_manager == null or not network_manager.is_connected_to_room_server()):
			auto_start_triggered = true
			_start_from_lobby()
		return
	if current_screen != "game" or task_overlay_index >= 0 or not can_local_act() or _utility_dialog_open():
		return
	var direction := move_vector
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if direction.length() > 1.0: direction = direction.normalized()
	var online_match: bool = not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server()
	if online_match:
		network_manager.send_player_input(direction)
		_update_interaction_prompt()
		return
	if is_instance_valid(player_body):
		player_body.call("set_input_direction", direction)
		player_position = player_body.global_position
	_update_area_indicator()
	_update_interaction_prompt()
	var route_line: Line2D = null
	if is_instance_valid(game_world): route_line = game_world.get_node_or_null("RouteLine") as Line2D
	if route_active and route_line:
		route_line.clear_points()
		route_line.add_point(player_position)
		route_line.add_point(route_target)
		if player_position.distance_to(route_target) < 44.0:
			route_active = false
			route_line.visible = false
	else:
		if route_line: route_line.visible = false


func _utility_dialog_open() -> bool:
	return is_instance_valid(page_controls) and bool(page_controls.call("dialog_open"))


func _set_audio_volume(percent: float) -> void:
	audio_volume = clampf(percent, 0.0, 100.0)
	var audio_bus := AudioServer.get_bus_index("Master")
	if audio_bus >= 0:
		AudioServer.set_bus_volume_db(audio_bus, linear_to_db(maxf(0.0001, audio_volume / 100.0)))
	var label := find_child("SettingsVolumeLabel", true, false) as Label
	if label: label.text = "VOLUME · %d%%" % int(audio_volume)


func navigate_back() -> void:
	if _utility_dialog_open():
		page_controls.call("close_dialog")
		return
	if not room_code.is_empty() and find_child("CreateRoomOverlay", true, false) != null:
		show_leave_room_confirmation()
		return
	if find_child("JoinRoomCodeOverlay", true, false) != null:
		_cancel_join_room()
		return
	for overlay_name in ["CreateAccountOverlay", "ConnectionLostOverlay", "CharacterConfirmOverlay", "TaskOverlay", "MapOverlay", "JournalOverlay", "ClueOverlay", "VoteOverlay", "JoinRoomChoiceOverlay", "JoinRoomOverlay", "OnlineUnavailableOverlay", "CreateRoomOverlay"]:
		var overlay := find_child(overlay_name, true, false)
		if overlay:
			overlay.get_parent().remove_child(overlay)
			overlay.queue_free()
			if overlay_name == "TaskOverlay": task_overlay_index = -1
			return
	match current_screen:
		"login": page_controls.call("confirm", "EXIT GAME?", "Close Nenek Kebayan?", Callable(get_tree(), "quit"))
		"menu": build_login_screen()
		"map_select":
			if room_code.is_empty(): build_menu()
			else: show_leave_room_confirmation()
		"create_room":
			network_manager.leave_room()
			build_map_select()
		"character_select": build_waiting_room()
		"waiting_room": show_leave_room_confirmation()
		"game", "meeting", "role_reveal": show_exit_confirmation()
		"result": _return_to_menu_cleanly()


func can_local_act() -> bool:
	return not player_sleeping and not player_voted_out


func _reset_power_state() -> void:
	last_power_sequence = 0
	player_sleeping = false
	player_voted_out = false
	active_power_kind = ""
	active_power_area = -1
	active_power_until = 0.0
	sleep_ready_at = 0.0
	sabotage_ready_at = 0.0
	practice_power_room.clear()
	active_fog_origin = Vector2.ZERO
	active_fog_radius = NenekPowers.FOG_RADIUS


func _apply_power_state(state: Dictionary) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var next_kind := str(state.get("kind", ""))
	var next_area := int(state.get("area", -1))
	var remaining := maxf(0.0, float(state.get("seconds_left", 0.0)))
	if remaining <= 0.0: next_kind = ""
	var next_origin: Vector2 = state.get("fog_origin", player_position)
	var changed := next_kind != active_power_kind or next_area != active_power_area or next_origin != active_fog_origin
	active_fog_origin = next_origin
	active_fog_radius = maxf(1.0, float(state.get("fog_radius", NenekPowers.FOG_RADIUS)))
	active_power_kind = next_kind
	active_power_area = next_area
	active_power_until = now + remaining
	sleep_ready_at = now + maxf(0.0, float(state.get("sleep_cooldown", 0.0)))
	sabotage_ready_at = now + maxf(0.0, float(state.get("sabotage_cooldown", 0.0)))
	if changed: game_screen.refresh_power_effects(self)
	_update_power_view()
	_update_power_hud()


func locked_entrances() -> Array:
	if active_power_kind != "lock" or Time.get_ticks_msec() / 1000.0 >= active_power_until: return []
	return MapGeometry.area_doors(selected_map, active_power_area)


func _update_power_view() -> void:
	if not is_instance_valid(player_body): return
	var entrances := locked_entrances()
	player_body.set("locked_entrances", entrances)
	player_body.set_meta("locked_entrances", entrances)
	var fogged := active_power_kind == "fog" and not player_is_impostor and player_body.global_position.distance_to(active_fog_origin) < active_fog_radius and (active_power_area < 0 or MapGeometry.point_in_area(selected_map, active_power_area, player_body.global_position))
	player_body.set_meta("sight_radius", NenekPowers.FOG_VILLAGER_SIGHT if fogged else 160.0)
	var light := player_body.get_node_or_null("LocalVisionLight") as PointLight2D
	if light: light.texture_scale = 0.45 if fogged else 1.7


func _update_power_hud() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var watching := not can_local_act()
	for button_name in ["InteractButton", "InspectClueButton", "GameMapButton", "GameJournalButton", "VillageTasksToggle"]:
		var button := find_child(button_name, true, false) as Button
		if button and watching: button.disabled = true
	var pad := find_child("VirtualJoystick", true, false) as Control
	if pad: pad.visible = not watching
	var sleep_button := find_child("SleepSpellButton", true, false) as Button
	var sleep_seconds := ceili(maxf(0.0, sleep_ready_at - now))
	if sleep_button:
		sleep_button.visible = not watching
		sleep_button.text = "JAMPI TIDUR" + ("\n%ds" % sleep_seconds if sleep_seconds > 0 else "")
		sleep_button.disabled = watching or sleep_seconds > 0 or current_screen != "game"
		sleep_button.add_theme_font_size_override("font_size", 14)
	var sabotage_seconds := ceili(maxf(0.0, sabotage_ready_at - now))
	for info in [["FogButton", "KABUS"], ["DoorLockButton", "SUMPAHAN PINTU"]]:
		var button := find_child(info[0], true, false) as Button
		if button:
			button.visible = not watching
			button.text = info[1] + ("\n%ds" % sabotage_seconds if sabotage_seconds > 0 else "")
			button.disabled = watching or sabotage_seconds > 0 or current_screen != "game"
			button.add_theme_font_size_override("font_size", 14)
	var banner := find_child("WatchingLabel", true, false) as Label
	if banner:
		banner.text = ("ASLEEP · WATCHING ONLY\nYou cannot act until the next match." if player_sleeping else "VOTED OUT · WATCHING ONLY") if watching else ""
	var status := find_child("PowerStatusLabel", true, false) as Label
	if status:
		status.text = ""
		var areas := MapGeometry.sabotage_areas(selected_map)
		if active_power_kind != "":
			var section_name := str(areas[active_power_area]["name"]) if active_power_area >= 0 and active_power_area < areas.size() else "Nearby surroundings"
			status.text = ("KABUS · " if active_power_kind == "fog" else "ENTRANCES LOCKED · ") + section_name + " · %ds" % ceili(maxf(0.0, active_power_until - now))


func _enter_watch_mode() -> void:
	_stop_move()
	task_overlay_index = -1
	for overlay_name in ["TaskOverlay", "MapOverlay", "JournalOverlay", "ClueOverlay", "VoteOverlay", "MeetingOverlay"]:
		var overlay := find_child(overlay_name, true, false)
		if overlay:
			overlay.get_parent().remove_child(overlay)
			overlay.queue_free()
	if current_screen == "meeting": current_screen = "game"
	if is_instance_valid(player_body):
		player_body.set("inactive", player_voted_out)
		player_body.call("set_sleeping", player_sleeping)
	_update_power_hud()
	_update_interaction_prompt()


func _update_area_indicator() -> void:
	var area_name := "Village Yard"
	for area in MapGeometry.areas(selected_map):
		var area_rect: Rect2 = area["rect"]
		if area_rect.has_point(player_position):
			area_name = str(area["name"])
			break
	if area_name != current_area_name:
		current_area_name = area_name
		show_notice(area_name)


func _update_interaction_prompt() -> void:
	var prompt := find_child("InteractionPromptLabel", true, false) as Label
	var inspect := find_child("InspectClueButton", true, false) as Button
	var interact := find_child("InteractButton", true, false) as Button
	if prompt == null or inspect == null or interact == null:
		return
	var online_match: bool = not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server()
	var clue_positions: Array = clue_points if clue_points.size() == 3 else MapGeometry.clue_candidates(selected_map).slice(0, 3)
	var clue_index := _nearest_index(clue_positions, 72.0)
	var clue_available := clue_index >= 0 and not player_is_impostor
	if clue_available and online_match and clue_index in network_found_clues:
		clue_available = false
	elif clue_available and not online_match:
		var local_clues: Array = CHARACTER_CLUES.get(impostor_character, [])
		if clue_index < local_clues.size() and collected_clues.has(local_clues[clue_index]):
			clue_available = false
	inspect.disabled = not clue_available
	var task_index := _nearest_index(MapGeometry.task_points(selected_map), 72.0)
	var gong_near := player_position.distance_to(MapGeometry.gong_point(selected_map)) < 78.0
	if clue_available:
		prompt.text = "A clue is nearby • tap INSPECT CLUE"
		interact.disabled = false
	elif task_index >= 0:
		var tasks: Array = TASKS[MAPS[selected_map]["name"]]
		prompt.text = "Task nearby • " + str(tasks[task_index]["name"])
		interact.disabled = completed_tasks.size() > task_index and completed_tasks[task_index] == 1
	elif gong_near:
		prompt.text = "Emergency meeting gong • tap INTERACT"
		interact.disabled = false
	else:
		prompt.text = ""
		interact.disabled = false
	if not can_local_act():
		prompt.text = "Asleep until the match ends • watching only" if player_sleeping else "Voted out • watching only"
		inspect.disabled = true
		interact.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if current_screen == "game" and can_local_act() and task_overlay_index < 0 and not _utility_dialog_open() and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		interact_nearest()


func clear_screen(screen_name: String) -> void:
	current_screen = screen_name
	game_world = null
	game_hud = null
	player_body = null
	current_area_name = ""
	for child in get_children():
		if child != network_manager and child != page_controls and child != lan_host: child.queue_free()
	await get_tree().process_frame


func build_login_screen() -> void:
	await clear_screen("login")
	LoginScreen.build(self)
	if is_instance_valid(page_controls): page_controls.call("refresh", true)


func show_create_account() -> void:
	LoginScreen.show_create_account(self)


func _login_provider_unavailable(provider: String) -> void:
	var notice := find_child("LoginNoticeLabel", true, false) as Label
	if notice: notice.text = provider + " sign-in needs provider setup. You can play as a guest for now."


func _continue_as_guest() -> void:
	room_code = ""
	room_is_host = false
	build_menu()


func build_menu() -> void:
	await clear_screen("menu")
	add_background(load(MENU_ART))
	add_color_overlay(Color(0.05, 0.07, 0.08, 0.32))
	# Keep the original title artwork as the menu header.
	var menu_panel := make_panel(Rect2(480, 270, 320, 340), Color(0.13, 0.075, 0.045, 1.0))
	menu_panel.name = "MainMenuPanel"
	var menu_buttons := ["PLAY", "JOIN ROOM", "EXIT"]
	for i in menu_buttons.size():
		var btn := make_button(menu_panel, menu_buttons[i], Callable(self, "_menu_action").bind(i), 280, 48, i == 0)
		btn.position = Vector2(20, 82 + i * 64)
		btn.name = "MenuAction_%d" % i
	var badge := make_label("PLAY WITH FRIENDS ON THE SAME WI-FI  •  OR PRACTICE OFFLINE", 14, Color("f7d9a2"), HORIZONTAL_ALIGNMENT_CENTER)
	badge.name = "MenuStatusBadge"
	badge.position = Vector2(300, 680); badge.size = Vector2(680, 24)
	var menu_notice := make_label("", 14, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	menu_notice.name = "MenuNoticeLabel"; menu_notice.position = Vector2(900, 78); menu_notice.size = Vector2(350, 28)
	if is_instance_valid(page_controls): page_controls.call("refresh", true)


func _toggle_audio() -> void:
	audio_muted = not audio_muted
	var audio_bus := AudioServer.get_bus_index("Master")
	if audio_bus >= 0: AudioServer.set_bus_mute(audio_bus, audio_muted)
	if is_instance_valid(page_controls): page_controls.call("refresh", true)

func _close_menu_popups() -> void:
	if is_instance_valid(page_controls): page_controls.call("close_dialog")
	for popup_name in ["ConnectionLostOverlay", "JoinRoomChoiceOverlay", "JoinRoomCodeOverlay", "CreateRoomOverlay", "JoinRoomOverlay", "OnlineUnavailableOverlay"]:
		var popup := find_child(popup_name, true, false)
		if popup:
			popup.get_parent().remove_child(popup)
			popup.queue_free()

func show_menu_notice(message: String) -> void:
	last_notice_time = Time.get_ticks_msec() / 1000.0
	var label := get_node_or_null("MenuNoticeLabel") as Label
	if label: label.text = message


func _menu_action(index: int) -> void:
	match index:
		0:
			room_code = ""
			room_is_host = false
			build_map_select()
		1: show_join_room()
		2: page_controls.call("confirm", "EXIT GAME?", "Close Nenek Kebayan?", Callable(get_tree(), "quit"))


func show_join_room() -> void:
	_close_menu_popups()
	MultiplayerSetup.show_join(self)


func _create_room_code() -> void:
	_create_online_room()


func _host_lan_room() -> void:
	if network_manager.connection_pending: return
	var status := find_child("CreateRoomStatusLabel", true, false) as Label
	var result: Error = lan_host.call("start", network_manager.server_port)
	if result != OK:
		if status: status.text = "Cannot host on port %d. Another copy may already be hosting; use Join Room instead." % network_manager.server_port
		return
	server_address = "127.0.0.1"
	_set_connection_busy(true)
	_create_online_room()


func _set_connection_busy(busy: bool) -> void:
	for button_name in ["CreateOnlineRoomButton", "JoinOnlineRoomButton", "PracticeOfflineButton"]:
		var button := find_child(button_name, true, false) as Button
		if button: button.disabled = busy


func _cancel_join_room() -> void:
	if room_code.is_empty(): network_manager.leave_room()
	_close_menu_popups()


func _lan_address_text() -> String:
	var addresses := LanHost.addresses()
	return ", ".join(addresses) if not addresses.is_empty() else "No Wi-Fi address found; check your network connection."


func _queue_network_lobby_refresh() -> void:
	if _lobby_refresh_queued: return
	_lobby_refresh_queued = true
	_refresh_network_lobby.call_deferred()


func _refresh_network_lobby() -> void:
	if not room_code.is_empty():
		if current_screen == "character_select": await build_character_select()
		elif current_screen not in ["role_reveal", "game", "meeting", "result"]: await build_waiting_room()
	_lobby_refresh_queued = false


func _return_after_connection_loss(message: String) -> void:
	_reset_power_state()
	room_code = ""
	room_is_host = false
	lobby_players.clear()
	character_reservations.clear()
	player_is_impostor = false
	network_meeting_state = ""
	page_controls.call("close_dialog")
	await build_menu()
	MultiplayerSetup.show_disconnected(self, message)


func _copy_created_room_code() -> void:
	DisplayServer.clipboard_set(GameData.GAME_TITLE + "\nRoom code: " + room_code + "\nHost Wi-Fi address: " + _lan_address_text() + "\nPort: %d\nJoin on the same Wi-Fi." % network_manager.server_port)
	var copy := find_child("CopyCreatedRoomCodeButton", true, false) as Button
	if copy: copy.text = "INVITE COPIED"


func _continue_to_room_map() -> void:
	_close_menu_popups()
	build_map_select()


func _open_room_code_entry() -> void:
	show_join_room()


func _join_room_with_code() -> void:
	if network_manager.connection_pending: return
	var join_button := find_child("JoinOnlineRoomButton", true, false) as Button
	if join_button and join_button.disabled: return
	var entry := find_child("JoinCodeEntry", true, false) as LineEdit
	var status := find_child("JoinRoomStatusLabel", true, false) as Label
	if not entry or not status: return
	if entry.text.strip_edges().length() != 5:
		status.text = "Enter the five-character code shown on the host's screen."
		return
	status.text = "Connecting to room server…"
	var name_entry := find_child("LobbyPlayerNameEntry", true, false) as LineEdit
	if name_entry and not name_entry.text.strip_edges().is_empty(): lobby_player_name = name_entry.text.strip_edges().substr(0, 20)
	var address_entry := find_child("ServerAddressEntry", true, false) as LineEdit
	var address := address_entry.text.strip_edges() if address_entry else server_address
	if not address.is_empty(): server_address = address
	_set_connection_busy(true)
	var result: Error = network_manager.join_room(entry.text, lobby_player_name, address)
	if result != OK:
		_set_connection_busy(false)
		status.text = "Check the room code and host Wi-Fi address, then try again."


func _open_create_room() -> void:
	await clear_screen("create_room")
	MultiplayerSetup.build_host(self)


func _create_online_room() -> void:
	var status := find_child("CreateRoomStatusLabel", true, false) as Label
	if status: status.text = "Connecting to room server…"
	var name_entry := find_child("LobbyPlayerNameEntry", true, false) as LineEdit
	if name_entry and not name_entry.text.strip_edges().is_empty(): lobby_player_name = name_entry.text.strip_edges().substr(0, 20)
	var address_entry := find_child("ServerAddressEntry", true, false) as LineEdit
	var address := address_entry.text.strip_edges() if address_entry else server_address
	if not address.is_empty(): server_address = address
	var result: Error = network_manager.create_room(selected_map, lobby_player_name, address)
	if result != OK and status:
		_set_connection_busy(false)
		status.text = "Room creation failed. Check the selected map and server address."


func _start_local_practice_lobby() -> void:
	var name_entry := find_child("LobbyPlayerNameEntry", true, false) as LineEdit
	if name_entry and not name_entry.text.strip_edges().is_empty(): lobby_player_name = name_entry.text.strip_edges().substr(0, 20)
	if network_manager != null:
		network_manager.leave_room()
	character_reservations.clear()
	selected_character = _random_available_character()
	waiting_elapsed = 0.0
	auto_start_triggered = false
	room_code = ""
	room_is_host = true
	lobby_players = [{"id": "local", "name": lobby_player_name, "character": selected_character, "ready": false, "host": true}]
	build_waiting_room()


func _random_available_character() -> String:
	var available: Array[String] = []
	for character in CHARACTERS:
		if not character_reservations.has(character):
			available.append(character)
	if available.is_empty(): return ""
	return available[rng.randi_range(0, available.size() - 1)]


func _show_created_room() -> void:
	MultiplayerSetup.show_created(self, _lan_address_text())


func _enter_waiting_room() -> void:
	_close_menu_popups()
	build_waiting_room()


func build_map_select() -> void:
	await clear_screen("map_select")
	add_background(load(MENU_ART))
	add_color_overlay(Color(0.04, 0.07, 0.08, 0.76))
	var heading := make_panel(Rect2(24, 18, 1232, 90), Color(0.12, 0.09, 0.07, 1.0))
	heading.name = "MapSelectionHeading"
	_make_child_label(heading, "Choose a Map", 36, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(80, 16, 1072, 58))
	var close := make_button(heading, "×", Callable(self, "navigate_back"), 48, 48)
	close.name = "MapSelectionCloseButton"
	close.position = Vector2(1168, 21)
	close.tooltip_text = "Close map selection"
	close.add_theme_font_size_override("font_size", 30)
	var atlas := load(MAP_ART) as Texture2D
	for i in MAPS.size():
		var card := make_panel(Rect2(40 + i * 400, 120, 380, 500), Color(0.12, 0.09, 0.07, 0.97))
		var preview := TextureRect.new()
		preview.texture = make_map_texture(atlas, MAPS[i]["region"])
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.position = Vector2(12, 12); preview.size = Vector2(356, 230)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		_make_child_label(card, MAPS[i]["name"], 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(20, 252, 340, 42))
		var description := _make_child_label(card, MAPS[i]["description"], 14, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(26, 298, 328, 66))
		description.clip_contents = true
		var choose := make_button(card, "SELECT", Callable(self, "_choose_map").bind(i), 316, 50, true)
		choose.name = "MapSelect_%d" % i
		choose.position = Vector2(32, 422)


func _choose_map(index: int) -> void:
	selected_map = index
	selected_character = ""
	character_reservations.clear()
	waiting_elapsed = 0.0
	auto_start_triggered = false
	_open_create_room()


func _on_network_connection_changed(connected: bool, message: String) -> void:
	if connected:
		return
	_set_connection_busy(false)
	if not room_code.is_empty() and not network_manager.is_connected_to_room_server():
		_return_after_connection_loss(message)
		return
	var create_status := find_child("CreateRoomStatusLabel", true, false) as Label
	var join_status := find_child("JoinRoomStatusLabel", true, false) as Label
	if create_status: create_status.text = message
	if join_status: join_status.text = "Invalid Room Code" if message == "Invalid Room Code" else message


func _on_network_room_opened(code: String, map_index: int, members: Array, is_host: bool) -> void:
	selected_map = map_index
	room_code = code
	room_is_host = is_host
	lobby_players = members.duplicate(true)
	_set_connection_busy(false)
	if is_host:
		_show_created_room()
	else:
		_close_menu_popups()
		_queue_network_lobby_refresh()
	# The server follows this with a room_state RPC containing the authoritative
	# player list; the join flow builds from that update to avoid a duplicate screen.


func _on_network_room_changed(code: String, map_index: int, host_id: int, members: Array) -> void:
	room_code = code
	selected_map = map_index
	room_is_host = network_manager.local_peer_id() == host_id
	lobby_players = members.duplicate(true)
	character_reservations.clear()
	for member in lobby_players:
		var character := str(member.get("character", ""))
		var is_local_member: bool = int(member.get("id", -1)) == network_manager.local_peer_id()
		if not character.is_empty() and not is_local_member:
			character_reservations[character] = str(member.get("name", "Another player"))
	var local_index := _local_player_index()
	if local_index >= 0:
		selected_character = str(lobby_players[local_index].get("character", ""))
	if current_screen in ["waiting_room", "character_select"]: _queue_network_lobby_refresh()


func _on_network_room_error(message: String) -> void:
	_set_connection_busy(false)
	var create_status := find_child("CreateRoomStatusLabel", true, false) as Label
	var join_status := find_child("JoinRoomStatusLabel", true, false) as Label
	if create_status: create_status.text = message
	if join_status: join_status.text = message
	if not create_status and not join_status and current_screen == "menu":
		show_menu_notice(message)
	elif current_screen in ["game", "meeting", "waiting_room", "character_select"]:
		show_notice(message)


func _on_network_role_received(role: String, secret_character: String) -> void:
	player_is_impostor = role == "nenek_kebayan"
	impostor_character = secret_character
	assigned_role_character = network_manager.local_role_character


func _on_network_match_started(map_index: int, new_clue_points: Array) -> void:
	selected_map = map_index
	clue_points = new_clue_points.duplicate()
	completed_tasks.clear(); collected_clues.clear(); dead_npcs.clear()
	village_tasks_expanded = false
	network_found_clues.clear()
	_reset_power_state()
	task_progress.clear()
	player_position = MapGeometry.spawn_point(selected_map)
	for i in lobby_players.size():
		lobby_players[i]["position"] = MapGeometry.spawn_point_for_player(selected_map, i)
	var tasks: Array = TASKS[MAPS[selected_map]["name"]]
	for _i in tasks.size():
		completed_tasks.append(0)
		task_progress.append(0)
	_show_role_reveal()


func _on_network_positions_changed(members: Array) -> void:
	for data in members:
		if not data.has("revision"): continue
		var revision := int(data["revision"])
		if revision <= last_power_sequence: return
		last_power_sequence = revision
	var was_watching := not can_local_act()
	for data in members:
		if data.has("powers"):
			_apply_power_state(data["powers"])
			continue
		var peer_id := int(data.get("id", -1))
		if peer_id < 0: continue
		var point: Vector2 = data.get("position", Vector2.ZERO)
		var sleeping := bool(data.get("sleeping", false))
		var alive := bool(data.get("alive", true))
		for member in lobby_players:
			if int(member.get("id", -1)) != peer_id: continue
			member["position"] = point
			member["sleeping"] = sleeping
			member["alive"] = alive
			break
		var is_local: bool = network_manager.local_peer_id() == peer_id
		if is_local:
			player_position = point
			player_sleeping = sleeping
			player_voted_out = not alive
		var actor: Node = game_world.get_node_or_null("PlayerActor_%d" % peer_id) if is_instance_valid(game_world) else null
		if actor:
			if not alive and not is_local:
				actor.queue_free()
			else:
				actor.call("set_network_target", point)
				actor.call("set_sleeping", sleeping)
				actor.set("inactive", not alive)
	if not was_watching and not can_local_act(): _enter_watch_mode()
	if current_screen == "game":
		_update_area_indicator()
		_update_interaction_prompt()
	_update_power_hud()

func _on_network_task_state_changed(completed: Array, progress: Array) -> void:
	completed_tasks.clear(); task_progress.clear()
	for value in completed: completed_tasks.append(int(value))
	for value in progress: task_progress.append(int(value))
	_update_progress()
	for i in completed_tasks.size():
		var row := find_child("TaskEntry_%d" % i, true, false) as Label
		if row:
			var tasks: Array = TASKS[MAPS[selected_map]["name"]]
			var count_text := "" if completed_tasks[i] == 1 else " (%d/%d)" % [task_progress[i], TASK_STEPS[MAPS[selected_map]["name"]][i]]
			row.text = ("✓ " if completed_tasks[i] == 1 else "◇ ") + str(tasks[i]["name"]) + count_text


func _on_network_task_resolved(_task_index: int, success: bool, progress: int, complete: bool) -> void:
	task_overlay_index = -1
	var overlay := find_child("TaskOverlay", true, false)
	if overlay: overlay.queue_free()
	if success:
		show_notice("Task complete." if complete else "Progress %d." % progress)
	else:
		show_notice("Nenek Kebayan cannot add task progress." if player_is_impostor else "Move closer or choose the correct answer.")


func _on_network_clue_found(clue_index: int, clue_name: String, found_by: int) -> void:
	if clue_index not in network_found_clues:
		network_found_clues.append(clue_index)
	if not collected_clues.has(clue_name):
		collected_clues.append(clue_name)
	_update_progress()
	if network_manager.local_peer_id() == found_by:
		show_clue_panel(clue_name, "the hidden character")
	elif current_screen == "game":
		show_notice("Clue found: " + clue_name)
	var marker := game_world.get_node_or_null("ClueMarker_%d" % clue_index) if is_instance_valid(game_world) else null
	if marker: marker.queue_free()
	_update_interaction_prompt()


func _on_network_meeting_changed(state: String, seconds_left: int, members: Array, votes_cast: int, alive_count: int) -> void:
	var previous_state := network_meeting_state
	network_meeting_state = state
	network_meeting_seconds = seconds_left
	network_meeting_tick = 0.0
	network_votes_cast = votes_cast
	network_alive_count = alive_count
	if not state.is_empty(): _stop_move()
	if not can_local_act():
		_enter_watch_mode()
		return
	if state == "discussion" and previous_state != "discussion":
		network_chat_lines.clear()
		_show_network_discussion()
	elif state == "voting" and previous_state != "voting":
		_show_network_voting(members)
	elif state == "voting":
		var vote_label := find_child("VotesCastLabel", true, false) as Label
		if vote_label: vote_label.text = "Votes received: %d/%d" % [votes_cast, alive_count]
	var timer_label := find_child("MeetingTimerLabel", true, false) as Label
	if timer_label: timer_label.text = ("DISCUSSION" if state == "discussion" else "VOTING") + "  •  %ds" % seconds_left
	if state == "voting":
		var votes_label := find_child("VotesCastLabel", true, false) as Label
		if votes_label: votes_label.text = "Votes received: %d/%d" % [votes_cast, alive_count]


func _on_network_chat_received(_peer_id: int, player_name: String, message: String) -> void:
	network_chat_lines.append(player_name + ": " + message)
	var chat_log := find_child("MeetingChatLog", true, false) as Label
	if chat_log: chat_log.text = "\n".join(network_chat_lines.slice(maxi(0, network_chat_lines.size() - 7), network_chat_lines.size()))


func _on_network_meeting_result(target_id: int, message: String, _winner: String) -> void:
	network_meeting_state = ""
	var overlay := find_child("MeetingOverlay", true, false)
	if overlay: overlay.queue_free()
	if target_id >= 0:
		for i in lobby_players.size():
			if int(lobby_players[i].get("id", -1)) == target_id:
				lobby_players[i]["alive"] = false
		var actor := game_world.get_node_or_null("PlayerActor_%d" % target_id) if is_instance_valid(game_world) else null
		if target_id == network_manager.local_peer_id():
			player_voted_out = true
			if actor: actor.set("inactive", true)
			_enter_watch_mode()
		elif actor: actor.queue_free()
	show_notice(message)
	if current_screen == "meeting": current_screen = "game"


func _on_network_match_finished(winner: String, message: String) -> void:
	show_result(winner == "villagers", message)


func _show_network_discussion() -> void:
	var old_overlay := find_child("MeetingOverlay", true, false)
	if old_overlay:
		old_overlay.queue_free()
		await get_tree().process_frame
	current_screen = "meeting"
	var overlay := make_panel(Rect2(300, 100, 680, 520), Color(0.12, 0.08, 0.06, 0.99))
	overlay.name = "MeetingOverlay"
	_make_child_label(overlay, "EMERGENCY MEETING  •  DISCUSSION", 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 16, 632, 38))
	var timer := _make_child_label(overlay, "DISCUSSION  •  60s", 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 54, 632, 26))
	timer.name = "MeetingTimerLabel"
	for i in mini(lobby_players.size(), 10):
		var member: Dictionary = lobby_players[i]
		if not NenekPowers.is_active(member): continue
		var avatar := TextureRect.new()
		var character := str(member.get("character", ""))
		if CHARACTER_AVATARS.has(character): avatar.texture = load(CHARACTER_AVATARS[character])
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.position = Vector2(26 + i * 62, 82); avatar.size = Vector2(34, 34); avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(avatar)
		_make_child_label(overlay, str(member.get("name", "Player")), 8, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(13 + i * 62, 117, 60, 18))
	var chat := _make_child_label(overlay, "Discussion started. Share clues you've found.", 16, CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(36, 143, 608, 208))
	chat.name = "MeetingChatLog"
	chat.autowrap_mode = TextServer.AUTOWRAP_WORD
	var input := LineEdit.new()
	input.name = "MeetingChatInput"; input.placeholder_text = "Type a message..."; input.max_length = 200
	input.position = Vector2(36, 365); input.size = Vector2(480, 42); overlay.add_child(input)
	var send := make_button(overlay, "SEND", Callable(self, "_send_meeting_chat"), 120, 42, true)
	send.position = Vector2(524, 365)
	_make_child_label(overlay, "Voting begins when the discussion timer ends.", 12, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(50, 436, 580, 20))


func _send_meeting_chat() -> void:
	if not can_local_act(): return
	var input := find_child("MeetingChatInput", true, false) as LineEdit
	if input == null or input.text.strip_edges().is_empty(): return
	network_manager.send_chat(input.text)
	input.clear()


func _show_network_voting(members: Array) -> void:
	var old_overlay := find_child("MeetingOverlay", true, false)
	if old_overlay:
		old_overlay.queue_free()
		await get_tree().process_frame
	current_screen = "meeting"
	network_vote_selection = -1
	network_vote_submitted = false
	var overlay := make_panel(Rect2(235, 82, 810, 556), Color(0.12, 0.08, 0.06, 0.99))
	overlay.name = "MeetingOverlay"
	_make_child_label(overlay, "VOTE FOR A PLAYER", 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 14, 750, 40))
	var timer := _make_child_label(overlay, "VOTING  •  30s", 14, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 52, 750, 24))
	timer.name = "MeetingTimerLabel"
	var votes := _make_child_label(overlay, "Votes received: %d/%d" % [network_votes_cast, network_alive_count], 13, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 78, 750, 22))
	votes.name = "VotesCastLabel"
	var alive_members: Array = []
	for member in members:
		if NenekPowers.is_active(member): alive_members.append(member)
	for i in alive_members.size():
		var member: Dictionary = alive_members[i]
		var peer_id := int(member.get("id", -1))
		var text := str(member.get("name", "Player")) + "  •  " + str(member.get("character", "No character"))
		var vote_button := make_button(overlay, text, Callable(self, "_select_network_vote").bind(peer_id), 340, 46)
		vote_button.name = "VoteTarget_%d" % peer_id
		vote_button.position = Vector2(48 + (i % 2) * 365, 112 + floori(float(i) / 2.0) * 61)
		var avatar := TextureRect.new()
		var character := str(member.get("character", ""))
		if CHARACTER_AVATARS.has(character): avatar.texture = load(CHARACTER_AVATARS[character])
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.position = Vector2(6, 5); avatar.size = Vector2(34, 34); avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vote_button.add_child(avatar)
		if peer_id == network_manager.local_peer_id(): vote_button.disabled = true
	var skip := make_button(overlay, "SKIP VOTE", Callable(self, "_submit_network_vote").bind(-1), 170, 42)
	skip.position = Vector2(164, 438)
	var confirm := make_button(overlay, "CONFIRM VOTE", Callable(self, "_submit_network_vote").bind(-2), 210, 42, true)
	confirm.name = "ConfirmNetworkVote"; confirm.position = Vector2(432, 438); confirm.disabled = true
	_make_child_label(overlay, "Select one awake player, then confirm. You may vote only once.", 12, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(60, 496, 690, 22))


func _select_network_vote(peer_id: int) -> void:
	if not can_local_act(): return
	if network_vote_submitted: return
	network_vote_selection = peer_id
	var confirm := find_child("ConfirmNetworkVote", true, false) as Button
	if confirm: confirm.disabled = false
	for child in find_children("VoteTarget_*", "Button", true, false):
		var vote_button := child as Button
		if vote_button: vote_button.modulate = Color("f7c35a") if vote_button.name == "VoteTarget_%d" % peer_id else Color.WHITE


func _submit_network_vote(target_id: int) -> void:
	if not can_local_act(): return
	if network_vote_submitted: return
	var selected_id := target_id
	if target_id == -2:
		if network_vote_selection < 0: return
		selected_id = network_vote_selection
	network_vote_submitted = true
	network_manager.cast_vote(selected_id)
	var overlay := find_child("MeetingOverlay", true, false)
	if overlay:
		for child in overlay.find_children("*", "Button", true, false): child.disabled = true
		_make_child_label(overlay, "Vote submitted.", 16, Color("d8edb2"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(240, 548, 330, 24))


func _show_role_reveal() -> void:
	await clear_screen("role_reveal")
	add_background(load(WAITING_ROOM_ART))
	add_color_overlay(Color(0.025, 0.025, 0.025, 0.58))
	var card := make_panel(Rect2(370, 132, 540, 456), Color(0.105, 0.073, 0.047, 0.97))
	card.name = "PrivateRoleReveal"
	_make_child_label(card, "YOUR SECRET ROLE", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(28, 18, 484, 42))
	var shuffle_status := _make_child_label(card, "Cards are being shuffled…", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(34, 62, 472, 32))
	var shuffle_row := Control.new()
	shuffle_row.name = "ShuffleCards"
	shuffle_row.position = Vector2(140, 112)
	shuffle_row.size = Vector2(260, 182)
	card.add_child(shuffle_row)
	var shuffle_cards: Array[Panel] = []
	for i in 3:
		var back := _make_child_panel(shuffle_row, Rect2(72 + i * 8, 14, 116, 156), Color("53351f"))
		var back_style := StyleBoxFlat.new()
		back_style.bg_color = Color("53351f")
		back_style.border_color = Color("e4b25b")
		back_style.set_border_width_all(3)
		back_style.set_corner_radius_all(12)
		back.add_theme_stylebox_override("panel", back_style)
		_make_child_label(back, "✦", 42, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(12, 30, 92, 60))
		_make_child_label(back, "ROLE CARD", 11, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(8, 103, 100, 28))
		shuffle_cards.append(back)
	var revealed := _make_child_panel(card, Rect2(42, 96, 456, 238), Color("182e38"))
	revealed.name = "RevealedRoleCard"
	revealed.visible = false
	var revealed_style := StyleBoxFlat.new()
	revealed_style.bg_color = Color("4a1d22") if player_is_impostor else Color("182e38")
	revealed_style.border_color = Color("e4b25b")
	revealed_style.set_border_width_all(2)
	revealed_style.set_corner_radius_all(12)
	revealed.add_theme_stylebox_override("panel", revealed_style)
	var role_portrait := TextureRect.new()
	role_portrait.name = "RolePortrait"
	var card_character := assigned_role_character if not assigned_role_character.is_empty() else selected_character
	role_portrait.texture = load(CHARACTER_PORTRAITS.get(card_character, CHARACTER_PORTRAITS["Orang Kampung Lelaki"]))
	role_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	role_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	role_portrait.position = Vector2(8, 18)
	role_portrait.size = Vector2(160, 202)
	revealed.add_child(role_portrait)
	var role_color := Color("a92625") if player_is_impostor else Color("185b9d")
	var role_style := StyleBoxFlat.new()
	role_style.bg_color = role_color
	role_style.border_color = Color("e4b25b")
	role_style.set_border_width_all(2)
	role_style.set_corner_radius_all(10)
	var role_badge := Panel.new()
	role_badge.name = "RoleBadge"
	role_badge.position = Vector2(174, 16)
	role_badge.size = Vector2(266, 48)
	role_badge.add_theme_stylebox_override("panel", role_style)
	revealed.add_child(role_badge)
	var role_title := "You are Nenek Kebayan" if player_is_impostor else "You are Orang Kampung"
	_make_child_label(role_badge, role_title, 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, Rect2(6, 3, 254, 42))
	var lobby_pick_label := _make_child_label(revealed, "Lobby pick:\n" + selected_character, 12, Color("fff0cf"), HORIZONTAL_ALIGNMENT_LEFT, Rect2(174, 70, 266, 42))
	lobby_pick_label.clip_text = true
	var role_character_label := _make_child_label(revealed, "Shuffled character:\n" + card_character, 13, GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(174, 114, 266, 42))
	role_character_label.clip_text = true
	var role_copy := "Complete tasks and clues\nto discover Nenek Kebayan."
	if player_is_impostor:
		role_copy = "Sleep villagers permanently.\nFog your surroundings or lock\nall exits of your current section."
	var role_copy_label := _make_child_label(revealed, role_copy, 12, CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(174, 162, 266, 64))
	role_copy_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	role_copy_label.clip_text = true
	var footer := _make_child_label(card, "Only you can see this role. Other players see their own reveal.", 13, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(34, 342, 472, 28))
	footer.name = "RoleRevealPrivacy"
	var countdown := _make_child_label(card, "", 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(34, 376, 472, 50))
	countdown.name = "RoleRevealCountdown"
	for turn in 7:
		if not is_instance_valid(card) or current_screen != "role_reveal": return
		var shuffle_tween := create_tween()
		shuffle_tween.set_parallel(true)
		for i in shuffle_cards.size():
			var shuffle_card := shuffle_cards[i]
			var target_x: float = [20.0, 72.0, 124.0][(i + turn) % 3]
			var target_y: float = [18.0, 4.0, 18.0][(i + turn) % 3]
			var target_angle: float = [-9.0, 0.0, 9.0][(i + turn) % 3]
			shuffle_tween.tween_property(shuffle_card, "position", Vector2(target_x, target_y), 0.11)
			shuffle_tween.tween_property(shuffle_card, "rotation", deg_to_rad(target_angle), 0.11)
		await shuffle_tween.finished
		await get_tree().create_timer(0.07).timeout
	if not is_instance_valid(card): return
	shuffle_status.text = "Your card has been revealed"
	var reveal_tween := create_tween()
	reveal_tween.tween_property(shuffle_row, "scale", Vector2(0.05, 1.0), 0.16)
	await reveal_tween.finished
	if not is_instance_valid(card) or current_screen != "role_reveal": return
	shuffle_row.visible = false
	revealed.visible = true
	revealed.scale = Vector2(0.05, 1.0)
	var flip_tween := create_tween()
	flip_tween.tween_property(revealed, "scale", Vector2.ONE, 0.2)
	await flip_tween.finished
	for seconds in [3, 2, 1]:
		if not is_instance_valid(countdown): return
		countdown.text = "Starting in  %d" % seconds
		countdown.scale = Vector2(1.25, 1.25)
		var count_tween := create_tween()
		count_tween.tween_property(countdown, "scale", Vector2.ONE, 0.25)
		await count_tween.finished
		await get_tree().create_timer(0.65).timeout
	if is_instance_valid(card): await build_game()


func build_waiting_room() -> void:
	await clear_screen("waiting_room")
	var network_room: bool = not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server()
	add_background(load(WAITING_ROOM_ART))
	add_color_overlay(Color(0.025, 0.025, 0.025, 0.38))

	var header := make_panel(Rect2(40, 28, 1200, 86), Color(0.11, 0.075, 0.045, 0.94))
	_make_child_label(header, "WAITING ROOM", 30, GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(24, 12, 300, 58))
	_make_child_label(header, "MAP  •  " + MAPS[selected_map]["name"], 15, CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(300, 18, 260, 48))
	if network_room:
		var copy_code := make_button(header, "CODE  " + room_code, Callable(self, "_copy_room_code"), 165, 42)
		copy_code.name = "RoomCodeButton"
		copy_code.position = Vector2(560, 22); copy_code.add_theme_font_size_override("font_size", 13)
	else:
		_make_child_label(header, "OFFLINE PRACTICE", 13, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(560, 18, 165, 48))
	var status := _make_child_label(header, "%d / 10 PLAYERS   •   WAITING" % lobby_players.size(), 13, Color("d8edb2"), HORIZONTAL_ALIGNMENT_RIGHT, Rect2(735, 18, 435, 48))
	status.name = "LobbyStatusLabel"

	var map_panel := make_panel(Rect2(55, 140, 420, 430), Color(0.12, 0.08, 0.055, 0.96))
	_make_child_label(map_panel, "YOUR SELECTED MAP", 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(20, 14, 380, 34))
	var map_preview := TextureRect.new()
	map_preview.texture = make_map_texture(load(MAP_ART), MAPS[selected_map]["region"])
	map_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_preview.position = Vector2(18, 58); map_preview.size = Vector2(384, 222)
	map_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_preview)
	_make_child_label(map_panel, "Selected character: " + (selected_character if not selected_character.is_empty() else "None") + "\nUse Choose Character to switch.", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 298, 372, 52))
	_make_child_label(map_panel, "Room code is server-generated." if network_room else "No online room was created.", 13, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 358, 372, 34))

	var players_panel := make_panel(Rect2(500, 140, 725, 430), Color(0.12, 0.08, 0.055, 0.96))
	var open_slots := maxi(0, 10 - lobby_players.size())
	_make_child_label(players_panel, "PLAYERS IN ROOM", 18, GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(22, 10, 300, 34))
	_make_child_label(players_panel, "%d HERE  •  %d OPEN SLOTS" % [lobby_players.size(), open_slots], 13, CREAM, HORIZONTAL_ALIGNMENT_RIGHT, Rect2(400, 10, 300, 34))
	for i in 10:
		var row := floori(float(i) / 5.0)
		var col := i % 5
		var slot := _make_child_panel(players_panel, Rect2(22 + col * 138, 52 + row * 174, 124, 160), Color(0.17, 0.12, 0.085, 0.96))
		if i < lobby_players.size():
			var member: Dictionary = lobby_players[i]
			var member_character := str(member.get("character", ""))
			var member_name := str(member.get("name", "Player"))
			var is_local := str(member.get("id", "")) == (str(network_manager.local_peer_id()) if network_room else "local")
			var is_host := bool(member.get("host", false))
			var is_ready := bool(member.get("ready", false))
			_add_player_avatar(slot, member_character)
			if is_local:
				var name_entry := LineEdit.new()
				name_entry.name = "LobbyNameEntry"
				name_entry.text = lobby_player_name
				name_entry.placeholder_text = "Your name"
				name_entry.max_length = 20
				name_entry.editable = not network_room
				name_entry.position = Vector2(7, 82); name_entry.size = Vector2(110, 28)
				name_entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
				name_entry.add_theme_font_size_override("font_size", 12)
				name_entry.add_theme_color_override("font_color", CREAM)
				var field_style := StyleBoxFlat.new()
				field_style.bg_color = Color("35271c"); field_style.border_color = Color("c5904b")
				field_style.set_border_width_all(1); field_style.set_corner_radius_all(7)
				name_entry.add_theme_stylebox_override("normal", field_style)
				name_entry.add_theme_stylebox_override("focus", field_style)
				name_entry.text_changed.connect(_on_lobby_name_changed)
				name_entry.editable = not network_room
				slot.add_child(name_entry)
				var host_status := _make_child_label(slot, ("HOST  •  " if is_host else "YOU  •  ") + ("READY" if is_ready else "WAITING"), 10, Color("d8edb2"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(4, 117, 116, 26))
				host_status.name = "LocalReadyStatusLabel"
			else:
				_make_child_label(slot, member_name + ("  •  HOST" if is_host else ""), 10, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(4, 82, 116, 28))
				_make_child_label(slot, ("READY" if is_ready else "WAITING"), 10, Color("d8edb2") if is_ready else Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(4, 117, 116, 26))
		else:
			var empty_avatar := _make_child_panel(slot, Rect2(29, 10, 66, 66), Color(0.20, 0.17, 0.13, 1.0))
			empty_avatar.add_theme_stylebox_override("panel", _circle_style(Color(0.20, 0.17, 0.13, 1.0), Color("8d785f")))
			_make_child_label(slot, "+", 30, Color("b8a58b"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(29, 9, 66, 66))
			_make_child_label(slot, "OPEN SLOT", 10, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(4, 82, 116, 28))
			_make_child_label(slot, "Waiting", 10, Color("a99b86"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(4, 117, 116, 26))

	var back := make_button(self, "LEAVE ROOM" if network_room else "CHANGE MAP", Callable(self, "show_leave_room_confirmation") if network_room else Callable(self, "build_map_select"), 210, 48)
	back.position = Vector2(55, 610)
	var choose := make_button(self, "CHOOSE CHARACTER", Callable(self, "build_character_select"), 245, 48)
	choose.position = Vector2(290, 610)
	if not network_room:
		var leave_room := make_button(self, "LEAVE ROOM", Callable(self, "show_leave_room_confirmation"), 190, 48)
		leave_room.name = "LobbyLeaveRoomButton"
		leave_room.position = Vector2(780, 610)
	var ready_button := make_button(self, "NOT READY", Callable(self, "_toggle_lobby_ready"), 185, 48, true)
	ready_button.name = "LobbyReadyButton"; ready_button.position = Vector2(560, 610); ready_button.disabled = selected_character.is_empty()
	_apply_ready_button_color(ready_button, _local_player_is_ready())
	var start_button := make_button(self, "START GAME", Callable(self, "_start_from_lobby"), 210, 48, true)
	start_button.name = "LobbyStartButton"; start_button.position = Vector2(1015, 610)
	start_button.visible = not network_room or room_is_host
	start_button.disabled = not _all_lobby_players_ready() or lobby_players.size() >= 10 or (network_room and lobby_players.size() < 5)
	var lobby_note := _make_child_label(self, ("Wi-Fi room · host " + (_lan_address_text() if is_instance_valid(lan_host.service) else server_address)) if network_room else "Offline practice lobby", 12, Color("f7d9a2"), HORIZONTAL_ALIGNMENT_RIGHT, Rect2(650, 578, 575, 24))
	lobby_note.clip_text = true


func _leave_room_to_menu() -> void:
	page_controls.call("close_dialog")
	if network_manager != null and not room_code.is_empty():
		network_manager.leave_room()
	room_code = ""
	room_is_host = false
	selected_character = ""
	character_reservations.clear()
	build_menu()


func show_leave_room_confirmation() -> void:
	page_controls.call("confirm", "LEAVE ROOM?", "Leave this room and return to the main menu?", Callable(self, "_leave_room_to_menu"))

func _copy_room_code() -> void:
	DisplayServer.clipboard_set(room_code)
	var button := find_child("RoomCodeButton", true, false) as Button
	if button: button.text = "COPIED  " + room_code


func _local_player_index() -> int:
	var local_id := "local"
	if not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server():
		local_id = str(network_manager.local_peer_id())
	for i in lobby_players.size():
		if str(lobby_players[i].get("id", "")) == local_id: return i
	return -1


func _local_player_is_ready() -> bool:
	var index := _local_player_index()
	return index >= 0 and bool(lobby_players[index].get("ready", false))


func _all_lobby_players_ready() -> bool:
	if lobby_players.is_empty(): return false
	for member in lobby_players:
		if not bool(member.get("ready", false)): return false
	return true


func _toggle_lobby_ready() -> void:
	if selected_character.is_empty(): return
	if network_manager != null and not room_code.is_empty() and network_manager.is_connected_to_room_server():
		network_manager.toggle_ready()
		return
	var index := _local_player_index()
	if index < 0: return
	lobby_players[index]["ready"] = not bool(lobby_players[index].get("ready", false))
	var host_status := find_child("LocalReadyStatusLabel", true, false) as Label
	if host_status: host_status.text = "HOST  •  " + ("READY" if _local_player_is_ready() else "WAITING")


func _apply_ready_button_color(button: Button, is_ready: bool) -> void:
	var state := "ready" if is_ready else "not_ready"
	if button.has_meta("ready_color_state") and str(button.get_meta("ready_color_state")) == state:
		return
	button.set_meta("ready_color_state", state)
	var base_color := Color("3d7848") if is_ready else Color("9b342d")
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = Color("e4b25b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("4d9658") if is_ready else Color("b94439")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("2d5b37") if is_ready else Color("762721")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = base_color.darkened(0.38)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff0cf"))
	button.add_theme_color_override("font_disabled_color", Color("d0c1a8"))


func _start_from_lobby() -> void:
	if selected_character.is_empty() or not _all_lobby_players_ready(): return
	if network_manager != null and not room_code.is_empty() and network_manager.is_connected_to_room_server():
		if room_is_host: network_manager.start_match()
		return
	start_practice()


func toggle_village_tasks() -> void:
	village_tasks_expanded = not village_tasks_expanded
	var task_panel := find_child("VillageTasksPanel", true, false) as Panel
	if task_panel == null: return
	task_panel.size.y = 421.0 if village_tasks_expanded else 56.0
	var toggle := task_panel.get_node_or_null("VillageTasksToggle") as Button
	if toggle: toggle.text = "VILLAGE TASKS  −" if village_tasks_expanded else "VILLAGE TASKS  +"
	for i in 8:
		var entry := task_panel.get_node_or_null("TaskEntry_%d" % i) as Label
		if entry: entry.visible = village_tasks_expanded


func update_lobby_players(players: Array) -> void:
	lobby_players.clear()
	character_reservations.clear()
	for player in players:
		if lobby_players.size() >= 10: break
		if player is Dictionary: lobby_players.append(player.duplicate(true))
	for member in lobby_players:
		var character := str(member.get("character", ""))
		if character.is_empty() or str(member.get("id", "")) == "local": continue
		character_reservations[character] = str(member.get("name", "Another player"))
	if character_reservations.has(selected_character):
		selected_character = ""
		var local_index := _local_player_index()
		if local_index >= 0:
			lobby_players[local_index]["character"] = ""
			lobby_players[local_index]["ready"] = false
	if current_screen == "waiting_room": build_waiting_room()
	elif current_screen == "character_select": build_character_select()


func _add_player_avatar(parent: Control, character: String) -> void:
	var avatar_bg := _make_child_panel(parent, Rect2(27, 8, 70, 70), Color(0.12, 0.18, 0.20, 1.0))
	avatar_bg.add_theme_stylebox_override("panel", _circle_style(Color("283a38"), Color("d3a24e")))
	if not character.is_empty() and CHARACTER_AVATARS.has(character):
		var portrait := TextureRect.new()
		portrait.texture = load(CHARACTER_AVATARS[character])
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_bg.add_child(portrait)
	else:
		_make_child_panel(parent, Rect2(47, 48, 30, 25), Color("734c77"))
		_make_child_panel(parent, Rect2(49, 26, 26, 31), Color("e8b58a"))
		_make_child_panel(parent, Rect2(48, 22, 29, 13), Color("30231d"))
		_make_child_panel(parent, Rect2(54, 36, 3, 3), Color("251a17"))
		_make_child_panel(parent, Rect2(67, 36, 3, 3), Color("251a17"))


func _on_lobby_name_changed(new_name: String) -> void:
	lobby_player_name = new_name.strip_edges()
	var index := _local_player_index()
	if index >= 0: lobby_players[index]["name"] = lobby_player_name


func _circle_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill; style.border_color = border
	style.set_border_width_all(2); style.set_corner_radius_all(48)
	return style


func _make_child_panel(parent: Control, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new(); panel.position = rect.position; panel.size = rect.size
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = Color("8d6436")
	style.set_border_width_all(1); style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func build_character_select() -> void:
	await clear_screen("character_select")
	add_background(load(MENU_ART)); add_color_overlay(Color(0.035, 0.055, 0.06, 0.86))
	_make_child_label(self, "CHOOSE YOUR CHARACTER", 32, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(250, 10, 780, 44))
	_make_child_label(self, MAPS[selected_map]["name"] + "  •  10 CHARACTERS", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(270, 54, 740, 30))
	var roster: Array = CHARACTERS
	for i in roster.size():
		var character: String = roster[i]
		var col := i % 5
		var row := floori(float(i) / 5.0)
		var cards_in_row := 5
		var row_width := cards_in_row * 195 + (cards_in_row - 1) * 12
		var row_start_x := (1280.0 - row_width) / 2.0
		var card_x := row_start_x + col * 207
		var card := make_panel(Rect2(card_x, 94 + row * 244, 195, 224), Color(0.13, 0.085, 0.055, 0.97))
		# Use the existing head-and-shoulders artwork so the selection cards do not
		# shrink the full-body sprites into narrow thumbnails.
		var portrait_frame := _make_child_panel(card, Rect2(43, 8, 109, 104), Color(0.10, 0.075, 0.055, 1.0))
		var portrait := TextureRect.new()
		portrait.texture = load(CHARACTER_AVATARS[character])
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.position = Vector2(4, 4); portrait.size = Vector2(101, 96)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_frame.add_child(portrait)
		var display_character := character.replace("Puteri Gunung Ledang", "Puteri Gunung\nLedang")
		display_character = display_character.replace("Orang Kampung Lelaki", "Orang Kampung\nLelaki")
		display_character = display_character.replace("Orang Kampung Perempuan", "Orang Kampung\nPerempuan")
		var character_name: Label = _make_child_label(card, display_character, 12, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(8, 116, 179, 48))
		character_name.clip_text = true
		character_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var reserved := character_reservations.has(character)
		var is_selected := selected_character == character
		var button_text := "SELECTED" if is_selected else ("TAKEN" if reserved else "SELECT")
		var select := make_button(card, button_text, Callable(self, "_select_character").bind(character), 108, 38, is_selected)
		select.position = Vector2(43, 174)
		select.disabled = is_selected or reserved
		if reserved: select.tooltip_text = "Selected by " + str(character_reservations[character])
	var selection_text := selected_character if not selected_character.is_empty() else "Choose one character"
	_make_child_label(self, "Selected: " + selection_text, 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(220, 590, 620, 30))
	var return_room := make_button(self, "RETURN TO ROOM", Callable(self, "build_waiting_room"), 230, 48, true)
	return_room.position = Vector2(1000, 590); return_room.disabled = selected_character.is_empty()
	_make_child_label(self, "Characters are reserved by the server in online rooms.", 12, Color("ead6b9"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(330, 650, 620, 22))


func _select_character(character: String) -> void:
	if character_reservations.has(character): return
	if get_node_or_null("CharacterConfirmOverlay") != null: return
	var overlay := make_panel(Rect2(390, 145, 500, 430), Color(0.12, 0.08, 0.06, 0.99))
	overlay.name = "CharacterConfirmOverlay"
	_make_child_label(overlay, "CONFIRM CHARACTER", 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 18, 452, 40))
	var portrait := TextureRect.new()
	if CHARACTER_PORTRAITS.has(character): portrait.texture = load(CHARACTER_PORTRAITS[character])
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(175, 76); portrait.size = Vector2(150, 176)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(portrait)
	_make_child_label(overlay, character, 19, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(34, 263, 432, 36))
	_make_child_label(overlay, "Choose this character for your player?", 14, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(34, 302, 432, 30))
	var confirm := make_button(overlay, "CONFIRM", Callable(self, "_confirm_character_selection").bind(character, overlay), 160, 44, true)
	confirm.position = Vector2(62, 354)
	var cancel := make_button(overlay, "CANCEL", func(): overlay.queue_free(), 160, 44)
	cancel.position = Vector2(278, 354)


func _confirm_character_selection(character: String, overlay: Control) -> void:
	if is_instance_valid(overlay): overlay.queue_free()
	if character_reservations.has(character):
		show_notice("That character is no longer available.")
		return
	if network_manager != null and not room_code.is_empty() and network_manager.is_connected_to_room_server():
		network_manager.set_character(character)
		return
	selected_character = character
	var index := _local_player_index()
	if index >= 0:
		lobby_players[index]["character"] = character
		lobby_players[index]["ready"] = false
	build_character_select()


func update_character_reservations(reservations: Dictionary) -> void:
	character_reservations = reservations.duplicate()
	if character_reservations.has(selected_character):
		selected_character = ""
		var local_index := _local_player_index()
		if local_index >= 0:
			lobby_players[local_index]["character"] = ""
			lobby_players[local_index]["ready"] = false
	if current_screen == "character_select": build_character_select()


func _character_sigil(index: int) -> String:
	return ["♛", "🐓", "✦", "❀", "🐸", "♧", "✿", "♜", "☾", "⌂", "❀"][index]


func start_practice() -> void:
	_reset_power_state()
	completed_tasks.clear(); collected_clues.clear(); dead_npcs.clear()
	village_tasks_expanded = false
	task_progress.clear()
	player_position = MapGeometry.spawn_point(selected_map)
	clue_points.clear()
	for candidate in MapGeometry.clue_candidates(selected_map):
		if not MapGeometry.is_position_blocked(selected_map, candidate): clue_points.append(candidate)
	clue_points.shuffle()
	clue_points = clue_points.slice(0, 3)
	var tasks: Array = TASKS[MAPS[selected_map]["name"]]
	for i in tasks.size():
		completed_tasks.append(0)
		task_progress.append(0)
	player_is_impostor = DEBUG_FORCE_NENEK_FOR_TESTING or rng.randi_range(0, 4) == 0
	if player_is_impostor:
		impostor_character = selected_character
		assigned_role_character = selected_character
	else:
		var available := NPC_NAMES.filter(func(c: String) -> bool: return c != selected_character)
		impostor_character = available[rng.randi_range(0, available.size() - 1)]
		var role_characters := CHARACTERS.filter(func(c: String) -> bool: return c != selected_character)
		assigned_role_character = role_characters[rng.randi_range(0, role_characters.size() - 1)]
	practice_power_room = {"map_index": selected_map, "started": true, "finished": false, "meeting_state": "", "players": {1: {"id": 1, "role": "nenek_kebayan" if player_is_impostor else "villager", "alive": true, "sleeping": false, "position": player_position}}}
	NenekPowers.reset_match(practice_power_room, Time.get_ticks_msec() / 1000.0)
	_show_role_reveal()


func build_game() -> void:
	await game_screen.build(self)
	game_screen.refresh_power_effects(self)
	_update_power_view()
	_update_power_hud()
	if not can_local_act(): _enter_watch_mode()

func build_control_bar() -> void:
	game_screen.build_control_bar(self)


func interact_nearest() -> void:
	if _utility_dialog_open(): return
	if not can_local_act(): return
	var task_index := _nearest_index(MapGeometry.task_points(selected_map), 72.0)
	if task_index >= 0:
		if completed_tasks[task_index] == 1: show_notice("That task is already complete."); return
		open_task(task_index); return
	if player_position.distance_to(MapGeometry.gong_point(selected_map)) < 78.0:
		call_meeting(); return
	show_notice("Move closer to a marked task or gong.")


func cast_sleep_spell() -> void:
	if _utility_dialog_open(): return
	if not player_is_impostor or not can_local_act(): return
	if Time.get_ticks_msec() / 1000.0 < sleep_ready_at:
		show_notice("Jampi Tidur is still recharging."); return
	if room_code.is_empty() or network_manager == null or not network_manager.is_connected_to_room_server():
		show_notice("Jampi Tidur needs another player in an online room."); return
	var nearest_peer := -1
	var nearest_distance := NenekPowers.SLEEP_RANGE + 0.01
	for member in lobby_players:
		var peer_id := int(member.get("id", -1))
		if peer_id == network_manager.local_peer_id() or not NenekPowers.is_active(member): continue
		var point: Vector2 = member.get("position", Vector2.ZERO)
		var distance := player_position.distance_to(point)
		if distance < nearest_distance and MapGeometry.has_clear_path(selected_map, player_position, point, locked_entrances()):
			nearest_distance = distance
			nearest_peer = peer_id
	if nearest_peer < 0:
		show_notice("Find an awake villager nearby with no wall or locked entrance between you."); return
	network_manager.cast_sleep_spell(nearest_peer)


func cast_sabotage(kind: String) -> void:
	if not player_is_impostor or not can_local_act() or current_screen != "game" or _utility_dialog_open(): return
	if Time.get_ticks_msec() / 1000.0 < sabotage_ready_at:
		show_notice("Fog and door locking share a two-minute recharge."); return
	if not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server():
		network_manager.cast_sabotage(kind)
	else:
		var now := Time.get_ticks_msec() / 1000.0
		practice_power_room["players"][1]["position"] = player_position
		var error := NenekPowers.try_sabotage(practice_power_room, 1, kind, now)
		if not error.is_empty(): show_notice(error); return
		player_position = practice_power_room["players"][1]["position"]
		if is_instance_valid(player_body): player_body.global_position = player_position
		_apply_power_state(NenekPowers.snapshot(practice_power_room, practice_power_room["players"][1], now))
		show_notice("Fog surrounds your current location." if kind == "fog" else "All entrances to this section are locked for 10 seconds.")


func open_task(index: int) -> void:
	if not can_local_act(): return
	task_overlay_index = index
	_stop_move()
	if not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server():
		network_manager.send_player_input(Vector2.ZERO)
	var task: Dictionary = TASKS[MAPS[selected_map]["name"]][index]
	var overlay := make_panel(Rect2(345, 154, 590, 408), Color(0.13, 0.085, 0.05, 0.98))
	overlay.name = "TaskOverlay"
	var title := make_label(str(task["name"]), 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(24, 20); title.size = Vector2(542, 54); title.reparent(overlay, false)
	var instruction := make_label(str(task["prompt"]), 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	instruction.position = Vector2(35, 95); instruction.size = Vector2(520, 65); instruction.reparent(overlay, false)
	for i in task["choices"].size():
		var choice := make_button(overlay, str(task["choices"][i]), Callable(self, "_answer_task").bind(index, i), 500, 48, i == 0)
		choice.position = Vector2(45, 185 + i * 61)
	var cancel := make_button(overlay, "CANCEL", Callable(self, "_close_task"), 120, 38)
	cancel.position = Vector2(235, 373)


func _answer_task(task_index: int, answer: int) -> void:
	if not can_local_act(): return
	var task: Dictionary = TASKS[MAPS[selected_map]["name"]][task_index]
	if not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server():
		network_manager.submit_task_answer(task_index, answer)
		return
	if player_is_impostor:
		task_overlay_index = -1
		build_game(); show_notice("Nenek Kebayan cannot increase shared task progress."); return
	if answer == int(task["answer"]):
		task_progress[task_index] += 1
		var required: int = TASK_STEPS[MAPS[selected_map]["name"]][task_index]
		if task_progress[task_index] >= required: completed_tasks[task_index] = 1
		task_overlay_index = -1
		var task_overlay := find_child("TaskOverlay", true, false)
		if task_overlay: task_overlay.queue_free()
		if completed_tasks.count(1) == 8:
			show_result(true, "The village is safe. All shared tasks are complete.")
		else:
			build_game()
			if completed_tasks[task_index] == 1:
				show_notice("Task complete: " + str(task["name"]))
			else:
				show_notice("Progress %d/%d: %s" % [task_progress[task_index], required, str(task["name"])])
	else:
		show_notice("That choice doesn't fit. Try another answer.")


func _close_task() -> void:
	task_overlay_index = -1
	var overlay := find_child("TaskOverlay", true, false)
	if overlay: overlay.queue_free()


func inspect_nearest_clue() -> void:
	if not can_local_act(): return
	var online_match: bool = not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server()
	var clue_points_local: Array = clue_points if clue_points.size() == 3 else MapGeometry.clue_candidates(selected_map).slice(0, 3)
	var nearest := _nearest_index(clue_points_local, 72.0)
	if nearest < 0: show_notice("Move close to a glowing clue marker to inspect it."); return
	if online_match:
		if nearest in network_found_clues: show_notice("This clue has already been recorded."); return
		network_manager.inspect_clue(nearest)
		return
	var clues: Array = CHARACTER_CLUES[impostor_character]
	var clue_name: String = clues[nearest]
	if collected_clues.has(clue_name): show_notice("You already recorded this clue."); return
	collected_clues.append(clue_name)
	var clue_marker := game_world.get_node_or_null("ClueMarker_%d" % nearest) if is_instance_valid(game_world) else null
	if clue_marker: clue_marker.queue_free()
	show_clue_panel(clue_name, impostor_character)
	_update_progress()


func show_clue_panel(clue_name: String, character: String) -> void:
	if not can_local_act(): return
	_stop_move()
	var overlay := make_panel(Rect2(370, 190, 540, 300), Color(0.12, 0.08, 0.06, 0.98))
	overlay.name = "ClueOverlay"
	var title := make_label("CLUE RECORDED", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(25, 24); title.size = Vector2(490, 40); title.reparent(overlay, false)
	var copy := make_label("Found: " + clue_name + "\n\nThis evidence is linked to the visual character " + character + ". A character's appearance does not prove their role.", 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	copy.position = Vector2(35, 82); copy.size = Vector2(470, 130); copy.reparent(overlay, false)
	var close := make_button(overlay, "ADD TO JOURNAL", func(): overlay.queue_free(), 250, 46, true)
	close.position = Vector2(145, 229)


func show_journal() -> void:
	if not can_local_act(): return
	_stop_move()
	var overlay := make_panel(Rect2(320, 115, 640, 480), Color(0.12, 0.08, 0.06, 0.98))
	overlay.name = "JournalOverlay"
	var title := make_label("CLUE JOURNAL", 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(20, 18); title.size = Vector2(600, 40); title.reparent(overlay, false)
	var intro := make_label("Evidence is separate from task progress. The visual character is not the secret role.", 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	intro.position = Vector2(32, 65); intro.size = Vector2(576, 40); intro.reparent(overlay, false)
	var list_text := "No clues recorded yet. Inspect the glowing markers on the map."
	if not collected_clues.is_empty(): list_text = "\n".join(collected_clues.map(func(c: String) -> String: return "• " + c))
	var list := make_label(list_text, 19, CREAM)
	list.position = Vector2(70, 135); list.size = Vector2(500, 245); list.reparent(overlay, false)
	var close := make_button(overlay, "CLOSE", func(): overlay.queue_free(), 135, 43)
	close.position = Vector2(252, 414)


func show_map_overlay() -> void:
	if not can_local_act(): return
	if find_child("MapOverlay", true, false) != null: return
	_stop_move()
	var overlay := make_panel(Rect2(250, 110, 780, 500), Color(0.12, 0.08, 0.06, 0.99))
	overlay.name = "MapOverlay"
	_make_child_label(overlay, MAPS[selected_map]["name"], 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 14, 732, 36))
	var preview := TextureRect.new()
	preview.texture = map_image
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.position = Vector2(24, 58); preview.size = Vector2(732, 380)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(preview)
	var close := make_button(overlay, "CLOSE MAP", func(): overlay.queue_free(), 150, 40)
	close.position = Vector2(315, 445)


func call_meeting() -> void:
	if not can_local_act(): return
	if not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server():
		network_manager.call_meeting()
		return
	if player_position.distance_to(MapGeometry.gong_point(selected_map)) > 78.0:
		show_notice("Move close to the central gong to call a meeting."); return
	show_vote_panel()


func show_vote_panel() -> void:
	if not can_local_act(): return
	_stop_move()
	var overlay := make_panel(Rect2(300, 120, 680, 480), Color(0.12, 0.08, 0.06, 0.99))
	overlay.name = "VoteOverlay"
	var title := make_label("EMERGENCY MEETING", 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(30, 20); title.size = Vector2(620, 46); title.reparent(overlay, false)
	var intro := make_label("Discuss the clues. Vote for the player you suspect, or skip the vote.", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	intro.position = Vector2(40, 72); intro.size = Vector2(600, 40); intro.reparent(overlay, false)
	var suspects := NPC_NAMES.filter(func(n: String) -> bool: return not dead_npcs.has(n))
	if player_is_impostor: suspects.append(selected_character)
	for i in suspects.size():
		var vote := make_button(overlay, "Vote: " + suspects[i], Callable(self, "_cast_vote").bind(suspects[i]), 470, 48)
		vote.position = Vector2(105, 126 + i * 59)
	var skip := make_button(overlay, "SKIP VOTE", Callable(self, "_cast_vote").bind(""), 180, 42, true)
	skip.position = Vector2(250, 423)


func _cast_vote(suspect: String) -> void:
	if not can_local_act(): return
	if suspect.is_empty():
		var skipped_overlay := find_child("VoteOverlay", true, false)
		if skipped_overlay: skipped_overlay.queue_free()
		build_game(); show_notice("The group skipped the vote."); return
	var picked_impostor := (not player_is_impostor and suspect == impostor_character) or (player_is_impostor and suspect == selected_character)
	if picked_impostor:
		show_result(true, suspect + " was revealed as Nenek Kebayan. The Villagers win!")
	else:
		if not suspect.is_empty() and not dead_npcs.has(suspect): dead_npcs.append(suspect)
		var vote_overlay := find_child("VoteOverlay", true, false)
		if vote_overlay: vote_overlay.queue_free()
		build_game(); show_notice("" if suspect.is_empty() else suspect + " was a Villager. The investigation continues.")


func show_result(villagers_win: bool, message: String) -> void:
	_stop_move()
	page_controls.call("close_dialog")
	var meeting_overlay := find_child("MeetingOverlay", true, false)
	if meeting_overlay:
		meeting_overlay.get_parent().remove_child(meeting_overlay)
		meeting_overlay.queue_free()
	current_screen = "result"
	var backdrop := ColorRect.new()
	backdrop.name = "ResultOverlay"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen_ui_parent().add_child(backdrop)
	var panel := GameUI.make_panel(backdrop, Rect2(310, 200, 660, 330), Color(0.1, 0.07, 0.04, 0.98))
	panel.name = "ResultPanel"
	var title := _make_child_label(panel, "VILLAGERS WIN!" if villagers_win else "NENEK KEBAYAN WINS!", 32, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 26, 600, 52))
	title.name = "ResultTitle"
	_make_child_label(panel, message + ("\n\nSecret role character: " + impostor_character if not impostor_character.is_empty() else ""), 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(45, 105, 570, 90))
	var again := make_button(panel, "RETURN TO MENU", Callable(self, "_return_to_menu_cleanly"), 220, 48, true)
	again.position = Vector2(220, 240)


func show_exit_confirmation() -> void:
	page_controls.call("confirm", "LEAVE GAME?", "Leave the current match and return to the main menu?", Callable(self, "_return_to_menu_cleanly"))

func _return_to_menu_cleanly() -> void:
	page_controls.call("close_dialog")
	_reset_power_state()
	if network_manager != null and not room_code.is_empty(): network_manager.leave_room()
	room_code = ""
	room_is_host = false
	player_is_impostor = false
	impostor_character = ""
	network_meeting_state = ""
	build_menu()


func _travel_hint(index: int) -> void:
	var task_points: Array = MapGeometry.task_points(selected_map)
	if index >= 0 and index < task_points.size(): _set_route(task_points[index], "Follow the gold route, then press INTERACT at the task.")


func _travel_npc(index: int) -> void:
	var npc_points: Array = MapGeometry.npc_points(selected_map)
	if index >= 0 and index < npc_points.size(): _set_route(npc_points[index], "Follow the route to the villager and press INTERACT.")


func _travel_clue(index: int) -> void:
	var route_points: Array = clue_points if not clue_points.is_empty() else MapGeometry.clue_candidates(selected_map).slice(0, 3)
	if index >= 0 and index < route_points.size(): _set_route(route_points[index], "Follow the route to the clue and press INSPECT CLUE.")


func _set_route(target: Vector2, message: String) -> void:
	if not can_local_act(): return
	route_target = target
	route_active = true
	var route_line: Line2D = null
	if is_instance_valid(game_world): route_line = game_world.get_node_or_null("RouteLine") as Line2D
	if route_line:
		route_line.clear_points()
		route_line.add_point(player_position)
		route_line.add_point(route_target)
		route_line.visible = true
	show_notice(message)


func _nearest_index(points: Array, max_distance: float) -> int:
	var best := -1; var distance := max_distance
	for i in points.size():
		var candidate: float = player_position.distance_to(points[i])
		if candidate < distance: distance = candidate; best = i
	return best


func _set_move(direction: Vector2) -> void:
	if _utility_dialog_open(): return
	if not can_local_act(): return
	move_vector = direction


func _on_joystick_input(event: InputEvent, pad: Control, knob: Control) -> void:
	if _utility_dialog_open(): return
	if not can_local_act(): return
	var active := false
	var local_position := Vector2.ZERO
	if event is InputEventScreenTouch:
		active = event.pressed
		local_position = event.position
	elif event is InputEventScreenDrag:
		active = true
		local_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		active = event.pressed
		local_position = event.position
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		active = true
		local_position = event.position
	if not active:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			_stop_move()
			knob.position = (pad.size - knob.size) / 2.0
		return
	var center := pad.size / 2.0
	var offset := local_position - center
	var radius := 44.0
	if offset.length() > radius: offset = offset.normalized() * radius
	knob.position = center + offset - knob.size / 2.0
	_set_move(offset / radius)


func _stop_move() -> void:
	move_vector = Vector2.ZERO
	if not room_code.is_empty() and network_manager != null and network_manager.is_connected_to_room_server(): network_manager.send_player_input(Vector2.ZERO)
	if is_instance_valid(player_body): player_body.call("set_input_direction", Vector2.ZERO)


func _update_progress() -> void:
	var progress := find_child("ProgressLabel", true, false) as Label
	if progress: progress.text = "TASKS  %d / 8    •    CLUES  %d / 3" % [completed_tasks.count(1), collected_clues.size()]


func show_notice(message: String) -> void:
	last_notice = message; last_notice_time = Time.get_ticks_msec() / 1000.0
	var label := find_child("NoticeLabel", true, false) as Label
	if label:
		label.text = message
		return
	var room_notice := find_child("RoomErrorNotice", true, false) as Label
	if room_notice == null:
		room_notice = make_label("", 15, Color("fff3cd"), HORIZONTAL_ALIGNMENT_CENTER)
		room_notice.name = "RoomErrorNotice"; room_notice.position = Vector2(250, 665); room_notice.size = Vector2(780, 32)
	room_notice.text = message


func show_how_to_play(_return_screen: String = "") -> void:
	page_controls.call("show_help")

func show_settings(_return_screen: String = "") -> void:
	page_controls.call("show_settings")

func _make_child_label(parent: Control, text: String, font_size: int, color: Color, align: HorizontalAlignment, rect: Rect2) -> Label:
	return GameUI.make_child_label(parent, text, font_size, color, align, rect)


func add_background(texture: Texture2D) -> void:
	GameUI.add_background(self, texture)


func add_color_overlay(color: Color) -> void:
	GameUI.add_color_overlay(self, color)


func make_map_texture(atlas: Texture2D, region: Rect2) -> Texture2D:
	return GameUI.make_map_texture(atlas, region)


func make_label(text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return GameUI.make_label(_screen_ui_parent(), text, font_size, color, align)


func make_panel(rect: Rect2, color: Color) -> Panel:
	return GameUI.make_panel(_screen_ui_parent(), rect, color)


func make_button(parent: Control, title: String, callback: Callable, width: float, height: float, highlight: bool = false) -> Button:
	var target_parent: Node = _screen_ui_parent() if parent == self else parent
	return GameUI.make_button(target_parent, title, callback, width, height, highlight)


func _screen_ui_parent() -> Node:
	if is_instance_valid(game_hud): return game_hud
	return self
