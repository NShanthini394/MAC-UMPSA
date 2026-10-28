extends SceneTree
## Run with Godot --headless --path <project> --script res://tests/nenek_powers_validation.gd
const Powers = preload("res://scripts/nenek_powers.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
const Data = preload("res://scripts/game_data.gd")
const Network = preload("res://scripts/network_manager.gd")
var failures: Array[String] = []
var checks := 0
var clients: Array = []
var branches: Array[Node] = []
var snapshots: Dictionary = {}
var chats: Dictionary = {}
var results: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAILED: " + description)


func fixture() -> Dictionary:
	var room := {"started": true, "finished": false, "meeting_state": "", "map_index": 0, "players": {
		1: {"role": "nenek_kebayan", "position": Vector2(950, 380), "direction": Vector2.ZERO},
		2: {"role": "villager", "position": Vector2(930, 380), "direction": Vector2.RIGHT},
		3: {"role": "villager", "position": Vector2(970, 380), "direction": Vector2.ZERO}
	}}
	Powers.reset_match(room, 100.0)
	return room


func rules_checks() -> void:
	var room := fixture()
	check(Powers.try_sleep(room, 1, 2, 100.0).is_empty(), "Nearby awake villager can be put to sleep")
	check(room["players"][2]["sleeping"] and not Powers.is_active(room["players"][2]), "Sleep is permanent inactive state, not death/removal")
	check(room["players"][2]["alive"] and room["players"][2]["direction"] == Vector2.ZERO, "Sleeping avatar stays present and stops moving")
	Powers.expire_sabotage(room, 10000.0)
	check(room["players"][2]["sleeping"], "Time and sabotage expiry never wake a sleeper")
	check(not Powers.try_sleep(room, 1, 3, 101.0).is_empty(), "Sleep cooldown rejects repeated attacks")
	check(Powers.try_sleep(room, 1, 3, 125.0).is_empty(), "Sleep works again after its recharge")
	check(Powers.winner(room) == "nenek_kebayan", "No awake villagers means Nenek victory")
	Powers.reset_match(room, 200.0)
	check(Powers.is_active(room["players"][2]), "New match restores sleeping players")
	var scale := Geometry.world_size(0) / Vector2(1420, 505)
	room["players"][1]["position"] = Vector2(500, 150) * scale
	room["players"][2]["position"] = Vector2(535, 150) * scale
	check(not Powers.try_sleep(room, 1, 2, 200.0).is_empty(), "Jampi Tidur cannot cross a room wall")
	room = fixture()
	room["players"][1]["position"] = Geometry.sabotage_areas(0)[3]["zones"][0].get_center()
	check(Powers.try_sabotage(room, 1, "fog", 100.0).is_empty(), "Fog activates at the caster current kitchen")
	check(int(room["sabotage_area"]) == 3 and room["fog_origin"] == room["players"][1]["position"], "Server derives fog origin and section from the caster")
	check(is_equal_approx(room["sabotage_until"], 120.0), "Fog lasts twenty seconds")
	check(not Powers.try_sabotage(room, 1, "lock", 121.0).is_empty(), "Fog and locks share one recharge")
	check(Powers.expire_sabotage(room, 120.0), "Fog ends automatically")
	check(Powers.try_sabotage(room, 1, "lock", 220.0).is_empty(), "Door lock becomes available after two minutes")
	check(is_equal_approx(room["sabotage_until"], 230.0), "Door lock lasts ten seconds")
	var doors := Powers.locked_doors(room, 220.0)
	check(doors.size() == 2, "Kitchen sabotage locks both entrances")
	for door in doors:
		var a: Vector2 = door.get_center() - Vector2(30, 0) if door.size.y > door.size.x else door.get_center() - Vector2(0, 30)
		var b: Vector2 = door.get_center() + Vector2(30, 0) if door.size.y > door.size.x else door.get_center() + Vector2(0, 30)
		check(not Geometry.is_step_blocked(0, a, b, 1.0), "Real doorway is passable when unlocked")
		check(Geometry.is_step_blocked(0, a, b, 1.0, doors), "Locked entrance blocks crossing")
		check(Geometry.is_step_blocked(0, b, a, 1.0, doors), "Locked entrance blocks exit as well as entry")
		check(not Geometry.has_clear_path(0, a, b, doors), "Spell cannot cross a locked entrance")
	check(Powers.locked_doors(room, 230.0).is_empty(), "Entrances reopen automatically after ten seconds")
	room["sabotage_ready_at"] = 0.0
	room["players"][1]["position"] = Geometry.sabotage_areas(0)[7]["zones"][0].get_center()
	check(not Powers.try_sabotage(room, 1, "lock", 240.0).is_empty(), "Open garden does not receive invented door barriers")
	check(Powers.try_sabotage(room, 1, "fog", 240.0).is_empty(), "Outdoor gardens support fog")
	for section_case in [[0, 3, 2], [2, 2, 3], [0, 6, 4]]:
		var section_room := fixture()
		section_room["map_index"] = section_case[0]
		section_room["players"][1]["position"] = Geometry.sabotage_areas(section_case[0])[section_case[1]]["zones"][0].get_center()
		check(Powers.try_sabotage(section_room, 1, "lock", 100.0).is_empty(), "Local section lock activates")
		check(Powers.locked_doors(section_room, 100.0).size() == section_case[2], "Every entrance of a two-, three-, or four-exit section is locked")
	room["players"][1]["alive"] = false
	check(Powers.winner(room) == "villagers", "Removing Nenek produces a villager victory")
	for map_index in 3:
		check(Geometry.sabotage_areas(map_index).size() >= 7, "Map %d includes indoor and outdoor targets" % map_index)
		for area in Geometry.sabotage_areas(map_index):
			check(not area["zones"].is_empty(), "Area has visible fog coverage: " + str(area["name"]))
			for zone in area["zones"]:
				check(Rect2(Vector2.ZERO, Geometry.world_size(map_index)).encloses(zone), "Fog stays inside its map bounds")


func wait_until(predicate: Callable, description: String) -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	while not predicate.call():
		if Time.get_ticks_msec() >= deadline:
			check(false, "Timed out: " + description)
			return false
		await create_timer(0.03).timeout
	return true


func manager_branch(branch_name: String) -> Node:
	var branch := Node.new()
	branch.name = branch_name
	root.add_child(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
	var manager := Network.new()
	manager.name = "NetworkManager"
	branch.add_child(manager)
	branches.append(branch)
	return manager


func record_snapshot(members: Array, slot: int) -> void:
	snapshots[slot] = members


func record_chat(_id: int, _name: String, message: String, slot: int) -> void:
	chats[slot].append(message)


func record_result(winner: String, _message: String, slot: int) -> void:
	results[slot] = winner


func snapshot_sleeping(slot: int, peer_id: int) -> bool:
	for item in snapshots.get(slot, []):
		if int(item.get("id", -1)) == peer_id: return bool(item.get("sleeping", false))
	return false


func network_checks() -> void:
	var server = manager_branch("PowerServer")
	check(server.start_server(17763) == OK, "Local ENet server starts")
	for i in 5:
		var client = manager_branch("PowerClient%d" % i)
		clients.append(client)
		chats[i] = []
		client.positions_changed.connect(record_snapshot.bind(i))
		client.chat_received.connect(record_chat.bind(i))
		client.match_finished.connect(record_result.bind(i))
		check(client.connect_to_server("127.0.0.1", 17763) == OK, "Client connection requested")
	if not await wait_until(func() -> bool: return clients.all(func(c) -> bool: return c.is_connected_to_room_server()), "five connected clients"): return
	clients[0].create_room(0, "Host")
	if not await wait_until(func() -> bool: return not clients[0].active_room_code.is_empty(), "room creation"): return
	var code: String = clients[0].active_room_code
	for i in range(1, 5): clients[i].join_room(code, "Villager %d" % i)
	if not await wait_until(func() -> bool: return server.rooms[code]["players"].size() == 5, "joined players"): return
	for client in clients: client.toggle_ready()
	if not await wait_until(func() -> bool: return server._all_ready(server.rooms[code]), "all ready"): return
	clients[0].start_match()
	if not await wait_until(func() -> bool: return bool(server.rooms[code].get("started", false)), "match start"): return
	var room: Dictionary = server.rooms[code]
	var host_id: int = clients[0].local_peer_id()
	var sleeper_id: int = clients[1].local_peer_id()
	var awake_id: int = clients[2].local_peer_id()
	var nenek_count := 0
	for member in room["players"].values():
		if member["role"] == "nenek_kebayan": nenek_count += 1
	check(nenek_count == 1 and room["players"][host_id]["role"] == "nenek_kebayan", "Debug role selects only the host as Nenek")
	room["players"][host_id]["position"] = Vector2(950, 380)
	room["players"][sleeper_id]["position"] = Vector2(930, 380)
	clients[0].cast_sleep_spell(sleeper_id)
	if not await wait_until(func() -> bool: return snapshot_sleeping(1, sleeper_id), "sleep state reaches victim"): return
	check(server._alive_player_ids(room).size() == 4, "Sleeper is excluded from voting quorum")
	var fixed_point: Vector2 = room["players"][sleeper_id]["position"]
	clients[1].send_player_input(Vector2.RIGHT)
	room["clue_positions"][0] = fixed_point
	var tasks: Array = Data.TASKS[Data.MAPS[0]["name"]]
	clients[1].submit_task_answer(7, int(tasks[7]["answer"]))
	clients[1].inspect_clue(0)
	await create_timer(0.15).timeout
	check(room["players"][sleeper_id]["position"] == fixed_point, "Real sleeper RPC input cannot move frozen body")
	check(int(room["task_progress"][7]) == 0 and room["found_clues"].is_empty(), "Sleeper cannot work or inspect a nearby clue")
	room["meeting_state"] = "discussion"
	room["meeting_timer"] = 100.0
	clients[1].send_chat("SLEEPER MUST NOT SPEAK")
	clients[2].send_chat("awake message")
	await wait_until(func() -> bool: return chats[0].size() > 0, "awake chat")
	check(chats[0] == ["awake message"], "Server rejects sleeper chat")
	check(chats[1].is_empty(), "Sleeper receives no discussion chat")
	room["meeting_state"] = "voting"
	room["votes"] = {}
	clients[1].cast_vote(-1)
	clients[2].cast_vote(sleeper_id)
	await create_timer(0.12).timeout
	check(room["votes"].is_empty(), "Sleeper cannot vote or be selected as a vote target")
	clients[2].cast_vote(-1)
	await wait_until(func() -> bool: return room["votes"].has(awake_id), "awake vote")
	room["meeting_state"] = ""
	room["players"][sleeper_id]["position"] = Geometry.gong_point(0)
	clients[1].call_meeting()
	await create_timer(0.1).timeout
	check(room["meeting_state"] == "", "Sleeper cannot call a meeting even beside the gong")
	clients[0].cast_sabotage("fog")
	if not await wait_until(func() -> bool: return room["sabotage_kind"] == "fog", "surrounding fog"): return
	check(int(room["sabotage_area"]) == Geometry.section_at_position(0, room["players"][host_id]["position"]), "Network fog cannot select a distant room")
	check(float(room["sabotage_until"]) - Time.get_ticks_msec() / 1000.0 > 19.0, "Network fog uses twenty-second duration")
	clients[0].cast_sabotage("lock")
	await create_timer(0.1).timeout
	check(room["sabotage_kind"] == "fog", "Network shared cooldown blocks immediate lock after fog")
	room["sabotage_until"] = Time.get_ticks_msec() / 1000.0 - 1.0
	await wait_until(func() -> bool: return room["sabotage_kind"] == "", "fog automatic expiry")
	room["sabotage_ready_at"] = 0.0
	room["players"][host_id]["position"] = Geometry.sabotage_areas(0)[3]["zones"][0].get_center()
	clients[0].cast_sabotage("lock")
	await wait_until(func() -> bool: return room["sabotage_kind"] == "lock", "current room lock")
	check(Powers.locked_doors(room, Time.get_ticks_msec() / 1000.0).size() == 2, "Network kitchen lock covers both exits")
	check(float(room["sabotage_until"]) - Time.get_ticks_msec() / 1000.0 > 9.0, "Network lock uses ten-second duration")
	room["sabotage_kind"] = ""
	room["players"][host_id]["position"] = Vector2(950, 380)
	for i in range(2, 5):
		var target_id: int = clients[i].local_peer_id()
		room["players"][host_id]["sleep_ready_at"] = 0.0
		room["players"][target_id]["position"] = Vector2(930, 380)
		clients[0].cast_sleep_spell(target_id)
		await wait_until(func() -> bool: return bool(room["players"][target_id]["sleeping"]), "next villager asleep")
	await wait_until(func() -> bool: return results.get(0, "") == "nenek_kebayan", "sleep victory broadcast")
	check(bool(room["finished"]) and results.get(0, "") == "nenek_kebayan", "Last awake villager sleeping ends the match")
	# A separate fixture in the same connected room validates task and vote victories.
	room["finished"] = false
	Powers.reset_match(room, Time.get_ticks_msec() / 1000.0)
	room["completed_tasks"] = [1, 1, 1, 1, 1, 1, 1, 0]
	room["task_progress"][7] = int(Data.TASK_STEPS[Data.MAPS[0]["name"]][7]) - 1
	room["players"][awake_id]["position"] = Geometry.task_points(0)[7]
	clients[2].submit_task_answer(7, int(tasks[7]["answer"]))
	await wait_until(func() -> bool: return results.get(0, "") == "villagers", "task victory broadcast")
	check(bool(room["finished"]), "Awake villagers can still win by completing the tasks")
	results.clear()
	room["finished"] = false
	room["meeting_state"] = "voting"
	room["meeting_timer"] = 100.0
	room["votes"] = {}
	Powers.reset_match(room, Time.get_ticks_msec() / 1000.0)
	clients[0].cast_vote(-1)
	for i in range(1, 5): clients[i].cast_vote(host_id)
	await wait_until(func() -> bool: return results.get(0, "") == "villagers", "vote victory broadcast")
	check(not room["players"][host_id]["alive"], "Correct vote removes Nenek and wins for villagers")
	for client in clients: client._disconnect_peer()
	server.multiplayer.multiplayer_peer.close()
	for branch in branches: branch.queue_free()
	await process_frame


func ui_checks() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var app := main_scene.instantiate() as Control
	root.add_child(app)
	await process_frame
	await process_frame
	var login_panel := app.find_child("LoginPanel", true, false) as Control
	check(login_panel != null and login_panel.find_children("*", "Button", true, false).size() == 4, "Login offers Google, Huawei, Create Account, and Guest")
	check(app.find_child("LoginTitleArtwork", true, false) != null, "Login uses the game's title artwork")
	var login_hero := app.find_child("LoginHero", true, false) as Control
	var login_art := app.find_child("LoginTitleArtwork", true, false) as Control
	check(login_hero.get_global_rect().encloses(login_art.get_global_rect()) and login_hero.get_global_rect().end.y <= login_panel.position.y, "Login artwork stays above the form and inside its hero frame")
	check(app.find_child("LoginEmailEntry", true, false) == null and app.find_child("LoginPasswordEntry", true, false) == null, "Login has no email or password fields")
	app.find_child("LoginGoogleButton", true, false).emit_signal("pressed")
	check("Google" in app.find_child("LoginNoticeLabel", true, false).text, "Google option still shows provider setup feedback")
	app.find_child("LoginHuaweiButton", true, false).emit_signal("pressed")
	check("Huawei" in app.find_child("LoginNoticeLabel", true, false).text, "Huawei option still shows provider setup feedback")
	app.find_child("LoginCreateAccountButton", true, false).emit_signal("pressed")
	check(app.find_child("CreateGoogleButton", true, false) != null and app.find_child("CreateHuaweiButton", true, false) != null, "Create Account offers the two supported providers")
	app.find_child("CreateHuaweiButton", true, false).emit_signal("pressed")
	await process_frame
	check(app.find_child("CreateAccountOverlay", true, false) == null and "Huawei" in app.find_child("LoginNoticeLabel", true, false).text, "Create Account routes to the chosen provider without adding email/password")
	app.find_child("LoginGuestButton", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	check(app.get("current_screen") == "menu", "Guest option opens the game menu")
	for map_index in 3:
		app.call("_reset_power_state")
		app.set("selected_map", map_index)
		app.set("selected_character", "Bawang Merah")
		app.set("player_is_impostor", true)
		app.set("completed_tasks", [0, 0, 0, 0, 0, 0, 0, 0] as Array[int])
		app.set("task_progress", [0, 0, 0, 0, 0, 0, 0, 0] as Array[int])
		app.set("player_position", Geometry.spawn_point(map_index))
		await app.call("build_game")
		var local_room := fixture()
		local_room["map_index"] = map_index
		local_room["players"][1]["position"] = Geometry.spawn_point(map_index)
		Powers.reset_match(local_room, Time.get_ticks_msec() / 1000.0)
		app.set("practice_power_room", local_room)
		app.call("cast_sabotage", "fog")
		check(app.find_child("PowerTargetOverlay", true, false) == null, "No area-selection popup in map %d" % map_index)
		check(app.get("active_power_kind") == "fog", "Fog button activates immediately")
		check(app.get("active_fog_origin") == Geometry.spawn_point(map_index), "Fog stays around activation location")
		app.set("player_is_impostor", false)
		var body: Node2D = app.get("player_body")
		app.call("_update_power_view")
		check(float(body.get_meta("sight_radius")) == Powers.FOG_VILLAGER_SIGHT and Powers.FOG_VILLAGER_SIGHT < 55.0, "Thicker fog limits villagers to close surroundings in map %d" % map_index)
		app.get("game_screen").call("refresh_power_effects", app)
		var effect: Node = app.find_child("AreaPowerEffects", true, false)
		var fog_material := effect.get_child(0).material as ShaderMaterial
		check(float(fog_material.get_shader_parameter("fog_opacity")) > 0.95 and bool(fog_material.get_shader_parameter("nearby_view")), "Villager fog is dense with a nearby visibility pocket")
		body.global_position += Vector2(0, 5)
		effect.call("_process", 0.0)
		check(fog_material.get_shader_parameter("observer_position") == body.global_position, "Clear pocket follows the villager")
		var target := Node2D.new()
		app.get("game_world").add_child(target)
		target.global_position = body.global_position
		var tracker: Node = load("res://scripts/player_visibility.gd").new()
		app.get("game_world").add_child(tracker)
		tracker.call("configure", body, target, 160.0)
		check(target.visible, "Fog leaves immediately nearby players visible")
		var clear_target := body.global_position
		for direction_index in 16:
			var candidate := body.global_position + Vector2.RIGHT.rotated(TAU * direction_index / 16.0) * 75.0
			if Geometry.has_clear_path(map_index, body.global_position, candidate):
				clear_target = candidate
				break
		check(clear_target != body.global_position, "Visibility check uses an unobstructed nearby path")
		target.global_position = clear_target
		tracker.call("_update_visibility")
		check(not target.visible, "Villagers cannot see players through dense fog beyond nearby sight")
		body.global_position += Vector2(500, 0)
		app.call("_update_power_view")
		check(float(body.get_meta("sight_radius")) == 160.0, "Fog does not obscure distant surroundings")
		body.global_position = Geometry.spawn_point(map_index)
		check(app.find_child("AreaPowerEffects", true, false) != null, "Fog world effect exists")
		app.set("player_is_impostor", true)
		app.call("_update_power_view")
		check(float(body.get_meta("sight_radius")) == 160.0, "Nenek keeps navigation vision in fog")
		tracker.call("_update_visibility")
		check(target.visible, "Nenek can see the same nearby player hidden from fogged villagers")
		app.get("game_screen").call("refresh_power_effects", app)
		effect = app.find_child("AreaPowerEffects", true, false)
		fog_material = effect.get_child(0).material as ShaderMaterial
		check(float(fog_material.get_shader_parameter("fog_opacity")) <= 0.10 and float(fog_material.get_shader_parameter("blur_strength")) == 0.0, "Nenek has a clear unblurred fog view")
		app.set("player_is_impostor", false)
		app.call("_apply_power_state", {"kind": "", "area": -1, "seconds_left": 0.0})
		check(float(body.get_meta("sight_radius")) == 160.0, "Villager vision returns when fog ends")
	app.set("player_is_impostor", false)
	var local_id: int = app.get("network_manager").local_peer_id()
	app.set("lobby_players", [{"id": local_id, "position": app.get("player_position"), "alive": true}])
	app.call("_on_network_positions_changed", [{"id": local_id, "position": app.get("player_position"), "alive": true, "sleeping": true}, {"powers": {}, "revision": 2}])
	app.call("_on_network_positions_changed", [{"id": local_id, "position": Vector2.ZERO, "alive": true, "sleeping": false}, {"powers": {}, "revision": 1}])
	check(bool(app.get("player_sleeping")), "Delayed network snapshot cannot wake a permanent sleeper")
	check(app.get("player_position") != Vector2.ZERO, "Delayed snapshot cannot move a sleeping spectator")
	check(app.find_child("VirtualJoystick", true, false).visible == false, "Sleeping observer has no movement pad")
	check(app.find_child("GameMapButton", true, false).disabled, "Sleeping observer cannot open map")
	check(body_camera_enabled(app), "Sleeping observer retains the fixed player camera")
	app.call("interact_nearest")
	app.call("show_map_overlay")
	app.call("show_journal")
	app.call("_submit_network_vote", -1)
	app.call("_on_network_meeting_changed", "discussion", 60, [], 0, 2)
	check(app.find_child("MeetingOverlay", true, false) == null, "Sleeping observer never receives voting/chat UI")
	check(app.find_child("MapOverlay", true, false) == null and app.find_child("JournalOverlay", true, false) == null, "Observer action callbacks cannot reopen overlays")
	check(not bool(app.get("network_vote_submitted")), "Observer callback cannot submit a vote")
	await navigation_checks(app)
	app.queue_free()
	await process_frame


func navigation_checks(app: Control) -> void:
	var audio_bus := AudioServer.get_bus_index("Master")
	var original_muted := AudioServer.is_bus_mute(audio_bus)
	var original_volume := AudioServer.get_bus_volume_db(audio_bus)
	var controls: Node = app.get("page_controls")
	controls.call("refresh", true)
	check(not app.find_child("UtilityBackButton", true, false).visible, "Gameplay has no wording Back button")
	for button_name in ["UtilitySettingsButton", "UtilityMusicButton", "UtilityHelpButton"]:
		var button := app.find_child(button_name, true, false) as Button
		check(button.visible and button.text.is_empty() and button.find_child("MenuArtworkIcon", true, false).visible, "Gameplay uses a menu artwork icon for " + button_name)
	app.find_child("UtilitySettingsButton", true, false).emit_signal("pressed")
	app.find_child("SettingsLeaveGameButton", true, false).emit_signal("pressed")
	check(bool(controls.call("dialog_open")) and app.get("current_screen") == "game", "Game Back asks before leaving")
	app.find_child("CancelLeaveButton", true, false).emit_signal("pressed")
	check(not bool(controls.call("dialog_open")), "Cancel keeps the current match")
	await app.call("build_menu")
	var menu_panel := app.find_child("MainMenuPanel", true, false) as Control
	check(menu_panel.position.y >= 230.0, "Menu leaves the full title and subtitle visible")
	check(menu_panel.find_children("*", "Button", true, false).size() == 3 and app.find_child("MenuAction_2", true, false).text == "EXIT", "Main menu has only Play, Join Room, and Exit")
	check(not app.find_child("UtilityBackButton", true, false).visible, "Main menu has no Back button")
	app.find_child("MenuAction_2", true, false).emit_signal("pressed")
	check(app.find_child("LeaveConfirmation", true, false) != null, "Exit opens a quit confirmation rather than account navigation")
	app.find_child("CancelLeaveButton", true, false).emit_signal("pressed")
	var menu_badge := app.find_child("MenuStatusBadge", true, false) as Control
	check(menu_badge.get_global_rect().end.y <= 720.0, "Menu footer text stays within the page")
	app.call("_toggle_audio")
	check(AudioServer.is_bus_mute(audio_bus) == bool(app.get("audio_muted")), "Music toggle changes the actual audio bus")
	var muted: bool = app.get("audio_muted")
	await app.call("build_map_select")
	controls.call("refresh", true)
	check(bool(app.get("audio_muted")) == muted and not app.find_child("UtilityMusicButton", true, false).visible, "Music state persists while the map selector has no bottom toolbar")
	check(app.find_child("MapSelectionCloseButton", true, false) != null, "Map selector has a close cross beside its heading")
	app.call("show_settings", "")
	app.find_child("SettingsVolumeSlider", true, false).value = 35
	check(absf(db_to_linear(AudioServer.get_bus_volume_db(audio_bus)) - 0.35) < 0.01, "Settings volume slider changes actual output volume")
	app.call("_toggle_audio")
	check(bool(controls.call("dialog_open")), "Music toggle keeps settings open")
	app.call("navigate_back")
	check(not bool(controls.call("dialog_open")) and app.get("current_screen") == "map_select", "Back closes settings before navigating away")
	app.find_child("MapSelectionCloseButton", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	check(app.get("current_screen") == "menu", "Map selection Back returns to the menu")
	app.set("lobby_players", [{"id": "local", "character": "Bawang Merah", "name": "Tester", "host": true, "ready": false}])
	app.set("player_sleeping", false)
	await app.call("build_waiting_room")
	controls.call("refresh", true)
	check(not app.find_child("UtilityBackButton", true, false).visible and not app.find_child("UtilityMusicButton", true, false).visible and not app.find_child("UtilitySettingsButton", true, false).visible, "Waiting room has no extra bottom toolbar")
	app.call("navigate_back")
	check(app.get("current_screen") == "waiting_room" and bool(controls.call("dialog_open")), "Waiting-room Back confirms before leaving")
	app.find_child("CancelLeaveButton", true, false).emit_signal("pressed")
	await app.call("build_character_select")
	app.call("navigate_back")
	await process_frame
	await process_frame
	check(app.get("current_screen") == "waiting_room", "Character selection Back returns to the waiting room")
	for screen in ["login", "role_reveal", "meeting", "result"]:
		await app.call("clear_screen", screen)
		controls.call("refresh", true)
		if screen in ["login", "role_reveal"]:
			check(not app.find_child("UtilityBackButton", true, false).visible and not app.find_child("UtilitySettingsButton", true, false).visible and not app.find_child("UtilityMusicButton", true, false).visible, "No bottom toolbar on " + screen)
		else:
			check(app.find_child("UtilitySettingsButton", true, false).visible and app.find_child("UtilityMusicButton", true, false).visible, "Shared controls are available on " + screen)
		app.call("show_settings", "")
		check(bool(controls.call("dialog_open")), "Settings opens on " + screen)
		app.call("navigate_back")
		check(not bool(controls.call("dialog_open")), "Back closes settings on " + screen)
	app.call("show_result", true, "All awake villagers completed their tasks.")
	await process_frame
	var result_panel := app.find_child("ResultPanel", true, false) as Control
	var result_title := app.find_child("ResultTitle", true, false) as Control
	check(result_panel.get_global_rect().encloses(result_title.get_global_rect()), "Result title stays aligned inside its box")
	AudioServer.set_bus_mute(audio_bus, original_muted)
	AudioServer.set_bus_volume_db(audio_bus, original_volume)


func body_camera_enabled(app: Control) -> bool:
	var body: Node = app.get("player_body")
	return body != null and bool(body.get_node("Camera2D").enabled) and bool(body.get("sleeping"))


func _run() -> void:
	rules_checks()
	await network_checks()
	await ui_checks()
	print("NENEK POWERS CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
