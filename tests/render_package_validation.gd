extends SceneTree
## Connect two independent clients to the generated standalone server process.
const Network = preload("res://scripts/network_manager.gd")
var clients: Array[Node] = []
var failed := false

func _initialize() -> void: run.call_deferred()

func wait_for(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			failed = true
			push_error("Standalone package client check timed out")
			return false
		await process_frame
	return true

func run() -> void:
	await validate()
	for client in clients: client.leave_room()
	await process_frame
	print("STANDALONE RENDER PACKAGE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func validate() -> void:
	for index in 2:
		var branch := Node.new()
		branch.name = "Client%d" % index
		root.add_child(branch)
		set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
		var client := Network.new()
		client.name = "NetworkManager"
		branch.add_child(client)
		clients.append(client)
		var result: Error = client.create_room(0, "Package Host", "ws://127.0.0.1:17841/ws") if index == 0 else client.join_room(clients[0].active_room_code, "Package Guest", "ws://127.0.0.1:17841/ws")
		if result != OK: failed = true; return
		if not await wait_for(func() -> bool: return not client.active_room_code.is_empty()): return
	if clients[0].active_room_code != clients[1].active_room_code:
		failed = true
		push_error("Standalone clients joined different rooms")
