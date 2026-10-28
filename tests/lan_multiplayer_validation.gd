extends SceneTree
## Real app screens with independent client APIs and an embedded LAN host.
const Geometry = preload("res://scripts/map_geometry.gd")
var apps: Array[Control] = []
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func wait_for(predicate: Callable, description: String, timeout: float = 10.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			check(false, "Timed out: " + description)
			return false
		await process_frame
	return true


func new_app(slot: int) -> Control:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	app.name = "LANClient%d" % slot
	root.add_child(app)
	apps.append(app)
	await process_frame
	await process_frame
	app.get("network_manager").server_port = 17764
	app.find_child("LoginGuestButton", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	return app


func _run() -> void:
	await run_checks()
	for app in apps:
		app.get("network_manager").leave_room()
	for app in apps: app.queue_free()
	await process_frame
	await process_frame
	print("LAN APP CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func run_checks() -> void:
	var host := await new_app(0)
	host.find_child("MenuAction_0", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	host.find_child("MapSelect_2", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	check(host.get("current_screen") == "create_room", "Map selection opens host/practice choices")
	host.find_child("LobbyPlayerNameEntry", true, false).text = "LAN Host"
	host.find_child("CreateOnlineRoomButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return host.find_child("EnterWaitingRoomButton", true, false) != null, "host room invitation"): return
	var code: String = host.get("room_code")
	var service: Node = host.get("lan_host").service
	check(code.length() == 5 and host.get("network_manager").local_peer_id() != 1, "Embedded server and host's player use separate peers")
	check(not bool(service.get("force_host_nenek_for_testing")), "LAN games use random secret role assignment")
	check(host.find_child("CreatedRoomAddress", true, false) != null, "Host sees the address and code to share")
	host.find_child("EnterWaitingRoomButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return host.find_child("LobbyReadyButton", true, false) != null, "host lobby"): return
	for slot in range(1, 5):
		var client := await new_app(slot)
		client.find_child("MenuAction_1", true, false).emit_signal("pressed")
		check(client.find_child("JoinRoomCodeOverlay", true, false) != null, "Join Room opens working connection form")
		client.find_child("LobbyPlayerNameEntry", true, false).text = "Guest %d" % slot
		client.find_child("ServerAddressEntry", true, false).text = "127.0.0.1"
		client.find_child("JoinCodeEntry", true, false).text = "BAD"
		client.find_child("JoinOnlineRoomButton", true, false).emit_signal("pressed")
		check(not client.get("network_manager").connection_pending, "Short room code is rejected before connecting")
		if slot == 1:
			client.find_child("JoinCodeEntry", true, false).text = "ZZZZZ"
			client.find_child("JoinOnlineRoomButton", true, false).emit_signal("pressed")
			if not await wait_for(func() -> bool: return "Not Found" in client.find_child("JoinRoomStatusLabel", true, false).text, "invalid-room feedback"): return
			check(not client.find_child("JoinOnlineRoomButton", true, false).disabled, "Failed join can be retried")
		client.find_child("JoinCodeEntry", true, false).text = code.to_lower()
		client.find_child("JoinOnlineRoomButton", true, false).emit_signal("pressed")
		if not await wait_for(func() -> bool: return client.get("current_screen") == "waiting_room" and client.find_child("LobbyReadyButton", true, false) != null, "join automatically enters waiting room"): return
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("lobby_players").size() == 5 and a.find_children("LobbyReadyButton", "Button", true, false).size() == 1), "five synchronized app lobbies"): return
	var characters: Array = []
	for member in host.get("lobby_players"):
		check(not member.has("role") and not member.has("role_character"), "Lobby state does not reveal secret roles")
		characters.append(member["character"])
	check(characters.size() == 5 and characters.all(func(c) -> bool: return characters.count(c) == 1), "All players get unique available public characters")
	for app in apps: app.find_child("LobbyReadyButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return service.call("_all_ready", service.get("rooms")[code]), "ready states"): return
	var room: Dictionary = service.get("rooms")[code]
	apps[1].get("network_manager").start_match()
	await create_timer(0.1).timeout
	check(not room["started"], "A non-host cannot start the room")
	# Choose a deterministic seed that gives a guest the role; production remains random.
	var picker := RandomNumberGenerator.new()
	for seed_value in range(1, 100):
		picker.seed = seed_value
		if picker.randi_range(0, 4) > 0:
			service.get("_server_random").seed = seed_value
			break
	host.find_child("LobbyStartButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("current_screen") == "game" and a.get("player_body") != null), "private reveal and automatic countdown"): return
	var neneks := apps.filter(func(a: Control) -> bool: return bool(a.get("player_is_impostor")))
	check(neneks.size() == 1 and neneks[0] != host, "Exactly one secret Nenek can be a guest, not always the host")
	check(apps.all(func(a: Control) -> bool: return a.get("game_world").get_children().filter(func(n: Node) -> bool: return n is CharacterBody2D).size() == 5), "All clients instantiate the five actual player actors")
	var actor_id: int = host.get("network_manager").local_peer_id()
	var origin: Vector2 = room["players"][actor_id]["position"]
	var direction := Vector2.ZERO
	for candidate in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		if not Geometry.is_step_blocked(2, origin, origin + candidate * 28.0, 14.0): direction = candidate; break
	host.set("move_vector", direction)
	await create_timer(0.18).timeout
	host.call("_stop_move")
	check(room["players"][actor_id]["position"].distance_to(origin) > 1.0, "App controls move the authoritative player")
	var remote_actor := apps[1].get("game_world").get_node("PlayerActor_%d" % actor_id) as Node2D
	await create_timer(0.15).timeout
	check(remote_actor.global_position.distance_to(room["players"][actor_id]["position"]) < 8.0, "Movement reaches another real app view")
	neneks[0].find_child("FogButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("active_power_kind") == "fog"), "fog reaches every client"): return
	check(true, "Nenek's fog button is synchronized through the server")
	# Abruptly closing the hosting service must not leave clients in a dead match.
	host.get("lan_host").stop()
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.get("current_screen") == "menu" and a.find_child("ConnectionLostOverlay", true, false) != null), "host lost UI recovery", 12.0): return
	check(true, "Host loss returns every player to a usable menu with an explanation")
	var retry := apps[1]
	retry.call("show_join_room")
	retry.find_child("ServerAddressEntry", true, false).text = "127.0.0.1"
	retry.find_child("JoinCodeEntry", true, false).text = code
	retry.find_child("JoinOnlineRoomButton", true, false).emit_signal("pressed")
	retry.call("_cancel_join_room")
	check(not retry.get("network_manager").connection_pending and retry.find_child("JoinRoomCodeOverlay", true, false) == null, "Cancelling a join clears the pending connection")
	retry.call("_show_role_reveal")
	await create_timer(0.12).timeout
	await retry.call("_return_after_connection_loss", "The host closed the game during the shuffle.")
	await create_timer(0.5).timeout
	check(retry.get("current_screen") == "menu" and retry.find_child("PrivateRoleReveal", true, false) == null, "A disconnect safely cancels an in-progress role shuffle")
