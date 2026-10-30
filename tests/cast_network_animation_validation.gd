extends SceneTree
## Five real game clients: selected artwork and moving remote sprites over ENet.
const Data = preload("res://scripts/game_data.gd")
const Network = preload("res://scripts/network_manager.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var apps: Array[Control] = []
var server_branch: Node
var server: Node
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func wait_for(predicate: Callable, description: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			check(false, "Timed out: " + description)
			return false
		await process_frame
	return true


func _run() -> void:
	await run_checks()
	for app in apps: app.get("network_manager").leave_room()
	for app in apps: app.queue_free()
	if server != null: server.set_process(false)
	if server != null and server.multiplayer.multiplayer_peer != null:
		server.multiplayer.multiplayer_peer.close()
	if server_branch != null: server_branch.queue_free()
	await process_frame
	await process_frame
	print("CAST NETWORK CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func run_checks() -> void:
	server_branch = Node.new()
	server_branch.name = "CastServer"
	root.add_child(server_branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(), server_branch.get_path())
	server = Network.new()
	server.name = "NetworkManager"
	server_branch.add_child(server)
	check(_start_room_server() == OK, "Room server starts for animation integration")
	for slot in 5:
		var app: Control = load("res://scenes/main.tscn").instantiate()
		app.name = "CastClient%d" % slot
		root.add_child(app)
		apps.append(app)
		await process_frame
		await process_frame
		app.get("network_manager").server_port = 17765
		app.get("network_manager").connect_to_server(_server_endpoint(), 17765)
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("network_manager").is_connected_to_room_server()), "five connected clients"): return
	var host := apps[0]
	host.get("network_manager").create_room(1, "Cast Host", _server_endpoint())
	if not await wait_for(func() -> bool: return not str(host.get("room_code")).is_empty(), "room creation"): return
	var code: String = host.get("room_code")
	for slot in range(1, 5): apps[slot].get("network_manager").join_room(code, "Cast Guest %d" % slot, _server_endpoint())
	if not await wait_for(func() -> bool: return server.get("rooms")[code]["players"].size() == 5, "all players join"): return
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("lobby_players").size() == 5), "all lobby rosters"): return
	await host.call("build_waiting_room")
	for app in apps.slice(1): app.get("network_manager").toggle_ready()
	if not await wait_for(func() -> bool: return server.call("_all_ready", server.get("rooms")[code]), "ready guests"): return
	check(apps.all(func(a: Control) -> bool: return a.get("network_manager").lobby_countdown < 0), "Guests ready does not auto-start the match")
	apps[1].get("network_manager").toggle_ready()
	await create_timer(0.1).timeout
	check(server.get("rooms")[code]["players"][apps[1].network_manager.local_peer_id()]["ready"], "Guest cannot undo readiness")
	var ready_at := Time.get_ticks_msec()
	host.get("network_manager").start_match()
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("network_manager").lobby_countdown > 0), "host starts five-second countdown"): return
	check(apps.all(func(a: Control) -> bool: return a.get("network_manager").lobby_countdown > 3 and a.get("network_manager").lobby_countdown <= 5), "All clients receive the host's five-second countdown")
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("current_screen") == "game" and is_instance_valid(a.get("player_body"))), "game views after lobby countdown and role reveal", 32.0): return
	check(true, "Five real app screens enter the match")
	check(Time.get_ticks_msec()-ready_at >= 5000,"Match does not bypass the five-second countdown")
	for app in apps:
		var players: Array = app.get("lobby_players")
		for member in players:
			var body: Node = app.get("game_world").get_node("PlayerActor_%d" % int(member["id"]))
			var actor: Node = body.get_node("CharacterActor")
			check(actor.get("_animations") != null and str(actor.get("_character")) == str(member["character"]), "Every local/remote actor displays its network-selected animated character")
	var host_id: int = host.get("network_manager").local_peer_id()
	var room: Dictionary = server.get("rooms")[code]
	var origin: Vector2 = room["players"][host_id]["position"]
	var direction := Vector2.ZERO
	for candidate in [Vector2.RIGHT, Vector2.DOWN, Vector2.UP, Vector2.LEFT]:
		if not Geometry.is_step_blocked(1, origin, origin + candidate * 45, 14):
			direction = candidate
			break
	host.set("move_vector", direction)
	var remote_actor: Node = apps[1].get("game_world").get_node("PlayerActor_%d/CharacterActor" % host_id)
	var moving := await wait_for(func() -> bool: return room["players"][host_id]["position"].distance_to(origin) > 1 and bool(remote_actor.get("_is_running")), "server movement reaches the remote walk animation", 2.0)
	if moving:
		check(true, "Remote walking starts from actual server movement")
	else:
		print("Movement diagnostic: direction=%s origin=%s server=%s host_input=%s can_act=%s remote=%s" % [direction, origin, room["players"][host_id]["position"], host.get("move_vector"), host.call("can_local_act"), remote_actor.get("_is_running")])
	host.call("_stop_move")
	await create_timer(0.55).timeout
	check(not bool(remote_actor.get("_is_running")), "Remote walking returns to standing after movement stops")
	room["players"][host_id]["position"] = Vector2(628,330)
	host.set("move_vector",Vector2(-1,1).normalized())
	await create_timer(0.3).timeout
	host.call("_stop_move")
	var corner_position: Vector2 = room["players"][host_id]["position"]
	check(not Geometry.is_position_blocked(1,corner_position,14),"Real network input stays outside the inside-corner clearance")
	host.set("move_vector",Vector2.RIGHT)
	await create_timer(0.16).timeout
	host.call("_stop_move")
	check(room["players"][host_id]["position"].distance_to(corner_position)>10,"Real LAN character moves away after pressing into a corner")
	room["players"][host_id]["position"] = Vector2(625.0537,332.9463)
	host.set("move_vector",Vector2.RIGHT)
	await create_timer(0.16).timeout
	host.call("_stop_move")
	check(not Geometry.is_position_blocked(1,room["players"][host_id]["position"],14),"Previously stuck LAN position recovers with actual player input")


func _start_room_server() -> Error:
	return server.call("start_server", 17765)


func _server_endpoint() -> String:
	return "127.0.0.1"
