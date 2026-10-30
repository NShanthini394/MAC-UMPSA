extends SceneTree
## Real WebSocket clients verify UI identity and contents during room updates.
const Network = preload("res://scripts/network_manager.gd")
const Data = preload("res://scripts/game_data.gd")
var apps: Array[Control] = []
var server_branch: Node
var server: Node
var checks := 0
var failures: Array[String] = []
var monitored_frames := 0
var blank_frames := 0
const URL := "ws://127.0.0.1:17860"
var endpoint := URL

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func wait_for(predicate: Callable, message: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			check(false, "Timed out: " + message)
			return false
		await process_frame
	await process_frame
	return true

func monitor() -> void:
	for app in apps:
		if not is_instance_valid(app): continue
		var node: Node
		if app.current_screen == "waiting_room": node = app.find_child("LobbyPlayersPanel", true, false)
		elif app.current_screen == "character_select": node = app.find_child("CharacterSelect_0", true, false)
		else: continue
		monitored_frames += 1
		if not is_instance_valid(node) or node.is_queued_for_deletion(): blank_frames += 1

func new_app(slot: int) -> Control:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	app.name = "RefreshClient%d" % slot
	root.add_child(app)
	apps.append(app)
	check(app.internet_mode, "Configured builds default to Internet, including on shared Wi-Fi")
	app.online_server_url = endpoint
	app.lobby_player_name = "Refresh %d" % slot
	await app.build_menu()
	return app

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var url_index := args.find("--url")
	if url_index >= 0 and url_index+1 < args.size(): endpoint = args[url_index+1]
	RenderingServer.frame_post_draw.connect(monitor)
	await validate()
	check(blank_frames == 0, "No empty lobby/character page at rendered frame boundaries")
	for app in apps: app.network_manager.leave_room()
	for app in apps: app.queue_free()
	if server != null: server.multiplayer.multiplayer_peer.close()
	if server_branch != null: server_branch.queue_free()
	await process_frame
	print("LOBBY REFRESH: %d checks; %d failures; %d rendered pages monitored; %d blank frames" % [checks, failures.size(), monitored_frames, blank_frames])
	quit(0 if failures.is_empty() else 1)

func validate() -> void:
	if endpoint == URL:
		server_branch = Node.new()
		root.add_child(server_branch)
		set_multiplayer(MultiplayerAPI.create_default_interface(), server_branch.get_path())
		server = Network.new()
		server.name = "NetworkManager"
		server_branch.add_child(server)
		check(server.start_server(17860, true) == OK, "Test WebSocket server starts")
	var host := await new_app(0)
	await host._open_create_room()
	var picker: OptionButton = host.find_child("ConnectionMode", true, false)
	check(picker.selected == 1 and picker.get_item_text(1).contains("recommended"), "Internet is selected and clearly recommended")
	host._host_selected_room()
	if not await wait_for(func() -> bool: return not host.room_code.is_empty(), "host room", 150.0): return
	host._enter_waiting_room()
	check(host.find_child("LobbyActionButton", true, false) != null, "Opening waiting room finishes without a blank frame")
	var panel := host.find_child("LobbyPlayersPanel", true, false)
	var ready := host.find_child("LobbyActionButton", true, false)
	var guest := await new_app(1)
	guest.show_join_room()
	guest.find_child("JoinCodeEntry", true, false).text = host.room_code
	guest._join_room_with_code()
	if not await wait_for(func() -> bool: return guest.current_screen == "waiting_room" and host.lobby_players.size() == 2, "guest roster"): return
	check(host.find_child("LobbyPlayersPanel", true, false) == panel and host.find_child("LobbyActionButton", true, false) == ready, "Peer joins without rebuilding host page or ready button")
	check(host.find_child("LobbyOccupancyLabel", true, false).text.contains("2 HERE"), "Occupancy updates in place")
	var guest_panel := guest.find_child("LobbyPlayersPanel", true, false)
	for turn in 4:
		host._on_lobby_primary_action()
		var expected: bool = turn % 2 == 0
		if not await wait_for(func() -> bool: return host._local_player_is_ready() == expected and bool(guest.lobby_players[0]["ready"]) == expected, "ready update"): return
		check(host.find_child("LobbyPlayersPanel", true, false) == panel and guest.find_child("LobbyPlayersPanel", true, false) == guest_panel, "Ready update keeps both pages visible")
	host.build_character_select()
	check(host.find_child("CharacterSelect_0", true, false) != null, "Character page opens synchronously")
	var card := host.find_child("CharacterSelect_0", true, false)
	var available := ""
	for character in Data.CHARACTERS:
		if character != host.selected_character and not host.character_reservations.has(character): available = character; break
	host._select_character(available)
	var confirm := host.get_node("CharacterConfirmOverlay")
	guest._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return guest._local_player_is_ready(), "remote ready while confirming"): return
	check(host.get_node_or_null("CharacterConfirmOverlay") == confirm, "Remote update preserves open character confirmation")
	check(host.find_child("CharacterSelect_0", true, false) == card, "Remote update preserves character cards")
	host._confirm_character_selection(available, confirm)
	if not await wait_for(func() -> bool: return host.selected_character == available and guest.character_reservations.has(available), "character reservation"): return
	check(host.find_child("CharacterSelect_0", true, false) == card, "Character acknowledgement updates without rebuilding")
	check(host.find_child("CharacterSelectionLabel", true, false).text.contains(available), "Selected character caption updates")
	guest.build_character_select()
	var taken := guest.find_child("CharacterSelect_%d" % Data.CHARACTERS.find(available), true, false) as Button
	check(taken.disabled and taken.text == "TAKEN", "Other player sees unavailable character")
	host.build_waiting_room()
	check(host.find_child("LobbyPlayersPanel", true, false) != null, "Return to room finishes without an empty page")
	var guest_card := guest.find_child("CharacterSelect_0", true, false)
	host.network_manager.leave_room()
	if not await wait_for(func() -> bool: return guest.lobby_players.size() == 1 and guest.room_is_host, "host migration"): return
	check(guest.find_child("CharacterSelect_0", true, false) == guest_card, "Peer departure updates character availability without blanking")
	check(not guest.character_reservations.has(available), "Departed player's character is available again")
	guest.build_waiting_room()
	await create_timer(0.1).timeout
