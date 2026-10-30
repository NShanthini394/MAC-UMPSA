extends SceneTree
const Network = preload("res://scripts/network_manager.gd")
const Data = preload("res://scripts/game_data.gd")
var apps: Array[Control] = []
var branch: Node
var server: Node
var checks := 0
var failures: Array[String] = []
const ENDPOINT := "ws://127.0.0.1:17865"

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func wait_for(test: Callable, message: String, seconds: float = 15.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not test.call():
		if Time.get_ticks_msec() > deadline: check(false, "Timed out: " + message); return false
		await process_frame
	await process_frame
	return true
func new_app(index: int) -> Control:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	app.name = "LobbyV4Client%d" % index
	root.add_child(app)
	apps.append(app)
	app.online_server_url = ENDPOINT
	app.lobby_player_name = "Guest %d" % index
	await app.build_menu()
	return app
func add_guest(index: int, code: String) -> Control:
	var app := await new_app(index)
	app.show_join_room()
	check(app.find_child("ConnectionMode", true, false) == null, "Joining requires only a room code")
	app.find_child("JoinCodeEntry", true, false).text = code
	app._join_room_with_code()
	await wait_for(func() -> bool: return app.current_screen == "waiting_room", "guest lobby")
	return app
func run() -> void:
	await validate()
	for app in apps: app.network_manager.leave_room()
	for app in apps: app.queue_free()
	if server != null: server.multiplayer.multiplayer_peer.close()
	if branch != null: branch.queue_free()
	await process_frame
	print("LOBBY V4: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func validate() -> void:
	branch = Node.new(); root.add_child(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
	server = Network.new(); server.name = "NetworkManager"; branch.add_child(server)
	check(server.start_server(17865, true) == OK, "Server starts")
	var host := await new_app(0)
	host.selected_map = 1
	await host._open_create_room()
	check(host.find_child("ConnectionMode", true, false) == null, "Creating requires no network selector")
	host._host_selected_room()
	if not await wait_for(func() -> bool: return not host.room_code.is_empty(), "created room"): return
	var code: String = host.room_code
	host._enter_waiting_room()
	var start := host.find_child("LobbyActionButton", true, false) as Button
	check(start.text == "START" and start.disabled, "Host Start is disabled before enough guests are ready")
	check(host.find_child("LobbyChangeMapButton", true, false) == null, "Waiting room has no Change Map button")
	check(host.find_child("LobbyChooseCharacterButton", true, false).position.x == 246, "Choose Character sits next to Leave Room")
	var guest := await add_guest(1, code)
	var entry := guest.find_child("LobbyNameEntry", true, false) as LineEdit
	check(entry.editable, "Guest can edit their own name online")
	entry.text = "Changed Guest"; entry.text_submitted.emit(entry.text)
	if not await wait_for(func() -> bool: return host.lobby_players.any(func(m: Dictionary) -> bool: return m["name"] == "Changed Guest"), "renamed guest broadcast"): return
	check(true, "Renamed guest is synchronized to the host")
	entry = host.find_child("LobbyNameEntry", true, false) as LineEdit
	entry.text = "Changed Host"; entry.text_submitted.emit(entry.text)
	if not await wait_for(func() -> bool: return guest.lobby_players.any(func(m: Dictionary) -> bool: return m["name"] == "Changed Host"), "renamed host broadcast"): return
	check(true, "Host rename is synchronized to guest")
	guest._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return guest._local_player_is_ready(), "guest Ready"): return
	check(guest.find_child("LobbyActionButton", true, false).disabled, "Ready cannot be undone in UI")
	check(guest.find_child("LobbyChooseCharacterButton", true, false).disabled, "Ready locks character choice")
	var guest_id: int = guest.network_manager.local_peer_id()
	var previous_character: String = server.rooms[code]["players"][guest_id]["character"]
	guest.network_manager.toggle_ready()
	var other := ""
	for character in Data.CHARACTERS:
		if character != previous_character: other = character; break
	guest.network_manager.set_character(other)
	await create_timer(0.2).timeout
	check(server.rooms[code]["players"][guest_id]["ready"], "Server rejects unready RPC")
	check(server.rooms[code]["players"][guest_id]["character"] == previous_character, "Server rejects character change after Ready")
	host.network_manager.start_match()
	await create_timer(0.1).timeout
	check(server.rooms[code].get("start_countdown", -1) < 0, "Two players cannot start a match")
	for i in range(2, 5):
		var app := await add_guest(i, code)
		app._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return server._all_ready(server.rooms[code]), "all four guests ready"): return
	await create_timer(0.1).timeout
	check(start == host.find_child("LobbyActionButton", true, false) and not start.disabled, "Start becomes available without rebuilding host page")
	check(server.rooms[code].get("start_countdown", -1) < 0, "All ready still waits for host to click Start")
	guest.network_manager.start_match()
	await create_timer(0.1).timeout
	check(server.rooms[code].get("start_countdown", -1) < 0, "Guest cannot trigger countdown")
	host._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return host.network_manager.lobby_countdown > 0, "host starts countdown"): return
	check(host.network_manager.lobby_countdown <= 5 and host.network_manager.lobby_countdown > 4, "Countdown starts at five")
	var renamed: String = server.rooms[code]["players"][guest_id]["name"]
	guest.network_manager.set_player_name("Too Late")
	await create_timer(0.1).timeout
	check(server.rooms[code]["players"][guest_id]["name"] == renamed, "Name locks during countdown")
	apps[4].network_manager.leave_room()
	if not await wait_for(func() -> bool: return server.rooms[code]["players"].size() == 4 and host.network_manager.lobby_countdown < 0, "departure cancels countdown"): return
	check(start.disabled, "Start disables when the room drops below five")
	var replacement := await add_guest(5, code)
	replacement._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return not start.disabled, "replacement ready"): return
	var started_at := Time.get_ticks_msec()
	host._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return bool(server.rooms[code].get("started", false)), "server starts after five", 10): return
	check(Time.get_ticks_msec() - started_at >= 4950, "Host countdown cannot start early")
	if not await wait_for(func() -> bool: return host.current_screen == "game" and replacement.current_screen == "game", "role reveal and gameplay", 15): return
	check(true, "New lobby transitions to gameplay")
