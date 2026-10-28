extends SceneTree
## Launch five separate processes with --slot 0..4 --probe-dir <shared folder>.
var app: Control
var slot := 0
var folder := ""
var port := 17765


func argument(key: String, fallback: String) -> String:
	var arguments := OS.get_cmdline_user_args()
	var index := arguments.find(key)
	return arguments[index + 1] if index >= 0 and index + 1 < arguments.size() else fallback


func _initialize() -> void:
	slot = int(argument("--slot", "0"))
	folder = argument("--probe-dir", "res://.godot/lan-process")
	port = int(argument("--port", "17765"))
	_run.call_deferred()


func write_result(file_name: String, data: Dictionary) -> void:
	var temporary := folder.path_join(file_name + ".tmp")
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	DirAccess.rename_absolute(temporary, folder.path_join(file_name))


func wait_for(predicate: Callable, description: String) -> bool:
	var deadline := Time.get_ticks_msec() + 20000
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			push_error("LAN process %d timed out: %s" % [slot, description])
			write_result("failure-%d.json" % slot, {"error": description})
			quit(1)
			return false
		await process_frame
	return true


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.get("network_manager").server_port = port
	app.find_child("LoginGuestButton", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	if slot == 0:
		app.find_child("MenuAction_0", true, false).emit_signal("pressed")
		await process_frame
		await process_frame
		app.find_child("MapSelect_0", true, false).emit_signal("pressed")
		await process_frame
		await process_frame
		app.find_child("LobbyPlayerNameEntry", true, false).text = "Process Host"
		app.find_child("CreateOnlineRoomButton", true, false).emit_signal("pressed")
		if not await wait_for(func() -> bool: return app.find_child("EnterWaitingRoomButton", true, false) != null, "host invite"): return
		write_result("offer.json", {"code": app.get("room_code"), "port": port})
		app.find_child("EnterWaitingRoomButton", true, false).emit_signal("pressed")
	else:
		if not await wait_for(func() -> bool: return FileAccess.file_exists(folder.path_join("offer.json")), "host offer"): return
		var offer: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("offer.json")))
		app.find_child("MenuAction_1", true, false).emit_signal("pressed")
		app.find_child("LobbyPlayerNameEntry", true, false).text = "Process Guest %d" % slot
		app.find_child("ServerAddressEntry", true, false).text = "127.0.0.1"
		app.find_child("JoinCodeEntry", true, false).text = offer["code"]
		app.find_child("JoinOnlineRoomButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return app.get("current_screen") == "waiting_room" and app.find_child("LobbyReadyButton", true, false) != null and app.get("lobby_players").size() == 5, "five-player waiting room"): return
	app.find_child("LobbyReadyButton", true, false).emit_signal("pressed")
	if slot == 0:
		if not await wait_for(func() -> bool:
			var start_button := app.find_child("LobbyStartButton", true, false) as Button
			return start_button != null and not start_button.disabled, "all ready"): return
		app.find_child("LobbyStartButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return app.get("current_screen") == "game" and app.get("player_body") != null, "countdown and gameplay"): return
	if bool(app.get("player_is_impostor")):
		app.find_child("FogButton", true, false).emit_signal("pressed")
	if not await wait_for(func() -> bool: return app.get("active_power_kind") == "fog", "synchronized fog"): return
	var actor_count: int = app.get("game_world").get_children().filter(func(n: Node) -> bool: return n is CharacterBody2D).size()
	write_result("client-%d.json" % slot, {"slot": slot, "nenek": app.get("player_is_impostor"), "actors": actor_count, "fog": true, "screen": app.get("current_screen")})
	if slot == 0:
		if not await wait_for(func() -> bool:
			for index in 5:
				if not FileAccess.file_exists(folder.path_join("client-%d.json" % index)): return false
			return true, "all process reports"): return
		var reports: Array = []
		for index in 5:
			reports.append(JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("client-%d.json" % index))))
		var ok := reports.filter(func(report) -> bool: return bool(report["nenek"])).size() == 1 and reports.all(func(report) -> bool: return report["actors"] == 5 and report["fog"])
		write_result("finished.json", {"ok": ok, "clients": reports})
		if not ok: quit(1); return
		await create_timer(0.3).timeout
	else:
		if not await wait_for(func() -> bool: return FileAccess.file_exists(folder.path_join("finished.json")), "finished marker"): return
	print("LAN PROCESS %d: PASS (5 actors, private role, fog synchronized)" % slot)
	quit()
