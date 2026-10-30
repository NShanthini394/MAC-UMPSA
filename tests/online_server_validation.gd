extends SceneTree
## Explicit live-server check: --url wss://YOUR-SERVICE.onrender.com/ws
## Creates one temporary five-player room, tests it, then disconnects every peer.
const Network = preload("res://scripts/network_manager.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var clients: Array[Node] = []
var state: Array[Dictionary] = []
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func wait_for(predicate: Callable, message: String, seconds: float = 20.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			check(false, "Timed out: " + message)
			return false
		await process_frame
	return true

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--url")
	if index < 0 or index + 1 >= args.size():
		push_error("Specify --url explicitly to run a live server test")
		quit(1)
		return
	await validate(args[index + 1])
	for client in clients: client.leave_room()
	await create_timer(0.3).timeout
	for client in clients: client.get_parent().queue_free()
	await process_frame
	print("LIVE ONLINE CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func validate(url: String) -> void:
	var started_at := Time.get_ticks_msec()
	for slot in 5:
		var branch := Node.new()
		branch.name = "OnlineProbe%d" % slot
		root.add_child(branch)
		set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
		var client := Network.new()
		client.name = "NetworkManager"
		branch.add_child(client)
		clients.append(client)
		var snapshot := {"members": [], "role": "", "started": false, "positions": []}
		state.append(snapshot)
		client.room_changed.connect(func(_code: String, _map: int, _host: int, members: Array): snapshot["members"] = members)
		client.role_received.connect(func(role: String, _character: String): snapshot["role"] = role)
		client.match_started.connect(func(_map: int, _clues: Array): snapshot["started"] = true)
		client.positions_changed.connect(func(members: Array): snapshot["positions"] = members)
		client.room_error.connect(func(message: String): check(false, "Server rejected probe: " + message))
		var result: Error = client.create_room(1, "Online Test Host", url) if slot == 0 else client.join_room(clients[0].active_room_code, "Online Test %d" % slot, url)
		check(result == OK, "Client %d starts secure connection" % slot)
		if result != OK: return
		if not await wait_for(func() -> bool: return not client.active_room_code.is_empty(), "client room", 150.0): return
	check(clients.all(func(client: Node) -> bool: return client.active_room_code == clients[0].active_room_code), "Five clients join the same public-server room")
	if not await wait_for(func() -> bool: return state.all(func(s: Dictionary) -> bool: return s["members"].size() == 5), "five lobby rosters"): return
	check(state.all(func(s: Dictionary) -> bool: return s["members"].all(func(m: Dictionary) -> bool: return not m.has("role"))), "Lobby rosters keep roles private")
	for client in clients: client.toggle_ready()
	if not await wait_for(func() -> bool: return clients.all(func(c: Node) -> bool: return c.lobby_countdown > 0), "all ready countdown"): return
	var ready_at := Time.get_ticks_msec()
	clients[0].start_match()
	await create_timer(0.3).timeout
	check(state.all(func(s: Dictionary) -> bool: return not s["started"]), "Start request cannot bypass the 15-second wait")
	if not await wait_for(func() -> bool: return state.all(func(s: Dictionary) -> bool: return s["started"]), "five active game clients", 25.0): return
	check(Time.get_ticks_msec() - ready_at >= 14000, "Public server honours the lobby countdown")
	check(state.filter(func(s: Dictionary) -> bool: return s["role"] == "nenek_kebayan").size() == 1, "Exactly one private Nenek role")
	if not await wait_for(func() -> bool: return not state[0]["positions"].is_empty(), "initial position snapshot"): return
	var peer_id: int = clients[0].local_peer_id()
	var origin := Vector2.ZERO
	for member in state[0]["positions"]:
		if member.get("id", -1) == peer_id: origin = member["position"]
	var direction := Vector2.ZERO
	for candidate in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		if not Geometry.is_step_blocked(1, origin, origin + candidate * 40, 14):
			direction = candidate
			break
	clients[0].send_player_input(direction)
	var moved := await wait_for(func() -> bool:
		for member in state[1]["positions"]:
			if member.get("id", -1) == peer_id and member["position"].distance_to(origin) > 5: return true
		return false, "movement reaches remote internet client")
	clients[0].send_player_input(Vector2.ZERO)
	check(moved, "Movement is synchronized through the public WSS server")
	print("Public-server five-client session took %.1f seconds" % ((Time.get_ticks_msec() - started_at) / 1000.0))
