extends "res://tests/village_network_validation.gd"
## Same five-client gameplay checks through the actual HTTP/WebSocket gateway.
## Run server.py --proxy-only with GAME_PORT=17765, PORT=17831 first.

func _start_room_server() -> Error:
	return server.call("start_server", 17765, true)


func _server_endpoint() -> String:
	return "ws://127.0.0.1:17831/ws"


func run_checks() -> void:
	await super.run_checks()
	if not failures.is_empty(): return
	check(server.get("lan_discovery").get("_listener") == null, "Online server does not require LAN broadcast discovery")
	var host := apps[0]
	host.internet_mode = true
	host.online_server_url = ""
	host.network_manager.leave_room()
	await host._open_create_room()
	host._host_selected_room()
	check(not host.network_manager.connection_pending, "Unconfigured online mode gives feedback without creating a LAN room")
	check(host.find_child("CreateRoomStatusLabel", true, false).text.contains("not configured"), "Missing public URL is explained")
	host.online_server_url = _server_endpoint()
	host._host_selected_room()
	if not await wait_for(func() -> bool: return host.find_child("EnterWaitingRoomButton", true, false) != null, "internet host UI creates room"): return
	check(host.lan_host.service == null, "Internet room does not start a server on the phone")
	var new_code: String = host.room_code
	var guest := apps[1]
	guest.network_manager.leave_room()
	guest.internet_mode = true
	guest.online_server_url = _server_endpoint()
	await guest.build_menu()
	guest.show_join_room()
	guest.find_child("JoinCodeEntry", true, false).text = new_code
	guest._join_room_with_code()
	if not await wait_for(func() -> bool: return guest.room_code == new_code, "internet join UI uses room code"): return
	check(guest.find_child("ServerAddressEntry", true, false) == null, "Internet players never enter the server address")
	var cancelled := Network.new()
	var branch := Node.new()
	root.add_child(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
	branch.add_child(cancelled)
	check(cancelled.create_room(0, "Cancelled", "wss://127.0.0.1:17831/ws") == OK, "HTTPS warmup starts asynchronously")
	cancelled.leave_room()
	await create_timer(0.2).timeout
	check(not cancelled.connection_pending and cancelled.active_room_code.is_empty(), "Cancel stops a pending internet warmup")
	branch.queue_free()
