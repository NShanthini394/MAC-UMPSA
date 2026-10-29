extends Node
## Authoritative ENet room service shared by the game client and headless server.

signal connection_changed(connected: bool, message: String)
signal room_opened(code: String, map_index: int, members: Array, is_host: bool)
signal room_changed(code: String, map_index: int, host_id: int, members: Array)
signal room_error(message: String)
signal lobby_countdown_changed(seconds_left: float)
signal role_received(role: String, secret_character: String)
signal match_started(map_index: int, clue_positions: Array)
signal positions_changed(members: Array)
signal task_state_changed(completed: Array, progress: Array)
signal task_resolved(task_index: int, success: bool, progress: int, complete: bool)
signal clue_found(index: int, clue_name: String, found_by: int)
signal meeting_changed(state: String, seconds_left: int, members: Array, votes_cast: int, alive_count: int)
signal chat_received(peer_id: int, player_name: String, message: String)
signal meeting_result(target_id: int, message: String, winner: String)
signal match_finished(winner: String, message: String)
signal ability_feedback(message: String)

const PORT := 7000
const MAX_PLAYERS_PER_ROOM := 10
const MAX_SERVER_CLIENTS := 100
const LOBBY_WAIT_SECONDS := 15.0
var force_host_nenek_for_testing := false
const GameData = preload("res://scripts/game_data.gd")
const MapGeometry = preload("res://scripts/map_geometry.gd")
const NenekPowers = preload("res://scripts/nenek_powers.gd")
const Discovery = preload("res://scripts/lan_discovery.gd")
var discovery_port := int(ProjectSettings.get_setting("network/discovery_port",Discovery.PORT))
var lan_discovery: Discovery
const CLUE_CANDIDATE_POINTS := [
	Vector2(370, 235), Vector2(530, 235), Vector2(880, 245), Vector2(1050, 370),
	Vector2(880, 530), Vector2(625, 555), Vector2(350, 520), Vector2(340, 390),
	Vector2(250, 320), Vector2(720, 450), Vector2(1100, 520), Vector2(640, 300)
]

var server_address := "127.0.0.1"
var server_port := PORT
var rooms: Dictionary = {}
var peer_room_codes: Dictionary = {}
var active_room_code := ""
var lobby_countdown := -1.0
var local_player_name := "Player"
var local_character := ""
var local_player_role := ""
var local_secret_character := ""
var local_role_character := ""
var _pending_action: Dictionary = {}
var _server_random := RandomNumberGenerator.new()
var _position_broadcast_timer := 0.0
var connection_pending := false
var _connection_deadline := 0


func _ready() -> void:
	_server_random.randomize()
	_ensure_discovery()
	server_address = str(ProjectSettings.get_setting("network/server_address", server_address))
	server_port = int(ProjectSettings.get_setting("network/server_port", PORT))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	var arguments := OS.get_cmdline_user_args()
	if "--server" in arguments:
		var port := server_port
		var port_index := arguments.find("--port")
		if port_index >= 0 and port_index + 1 < arguments.size():
			port = int(arguments[port_index + 1])
		start_server(port)


func _process(delta: float) -> void:
	if connection_pending and Time.get_ticks_msec() >= _connection_deadline:
		_on_connection_failed()
	if not multiplayer.is_server(): return
	_position_broadcast_timer += delta
	var now := Time.get_ticks_msec() / 1000.0
	for code in rooms.keys():
		var room: Dictionary = rooms[code]
		if not bool(room.get("started", false)):
			_tick_lobby_countdown(str(code), delta)
			continue
		if bool(room.get("finished", false)): continue
		if NenekPowers.expire_sabotage(room, now): _broadcast_positions(str(code), true)
		if str(room.get("meeting_state", "")) != "":
			room["meeting_timer"] = maxf(0.0, float(room.get("meeting_timer", 0.0)) - delta)
			if room["meeting_timer"] <= 0.0:
				if room["meeting_state"] == "discussion":
					room["meeting_state"] = "voting"
					room["meeting_timer"] = 30.0
					room["votes"] = {}
					_broadcast_meeting_state(str(code))
				else: _resolve_vote(str(code))
			continue
		var entrances := NenekPowers.locked_doors(room, now)
		var map_index := int(room.get("map_index", 0))
		var bounds := MapGeometry.world_size(map_index)
		for player in room["players"].values():
			if not NenekPowers.is_active(player): continue
			var direction: Vector2 = player.get("direction", Vector2.ZERO)
			if direction == Vector2.ZERO: continue
			var origin: Vector2 = player.get("position", MapGeometry.spawn_point(map_index))
			var candidate := origin + direction * minf(delta, 0.1) * 250.0
			candidate = candidate.clamp(Vector2(14, 14), bounds - Vector2(14, 14))
			origin = MapGeometry.move_position(map_index, origin, candidate - origin, 14.0, entrances)
			player["position"] = origin
	if _position_broadcast_timer >= 0.05:
		_position_broadcast_timer = 0.0
		for code in rooms.keys():
			var room: Dictionary = rooms[code]
			if bool(room.get("started", false)) and not bool(room.get("finished", false)): _broadcast_positions(str(code))

func start_server(port: int = PORT) -> Error:
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return ERR_ALREADY_IN_USE
	# All gameplay travels through this server. Clients do not need direct peer
	# relays, including relay notifications racing simultaneous disconnects.
	var scene_api := multiplayer as SceneMultiplayer
	if scene_api: scene_api.server_relay = false
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(port, MAX_SERVER_CLIENTS)
	if result != OK:
		return result
	var discovery_result := _ensure_discovery().listen(discovery_port,_discovery_room)
	if discovery_result!=OK:
		peer.close()
		return discovery_result
	server_port = port
	multiplayer.multiplayer_peer = peer
	print("Nenek Kebayan room server listening on UDP %d" % port)
	return OK


func connect_to_server(address: String, port: int = PORT) -> Error:
	var destination := address.strip_edges()
	if destination.is_empty() or port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	if is_connected_to_room_server() and destination == server_address and port == server_port: return OK
	_disconnect_peer()
	server_address = destination
	server_port = port
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(server_address, server_port)
	if result != OK:
		return result
	multiplayer.multiplayer_peer = peer
	connection_pending = true
	_connection_deadline = Time.get_ticks_msec() + 8000
	connection_changed.emit(false, "Connecting to room server…")
	return OK


func create_room(map_index: int, player_name: String, address: String = "") -> Error:
	if map_index < 0 or map_index >= GameData.MAPS.size():
		return ERR_INVALID_PARAMETER
	local_player_name = _clean_player_name(player_name)
	_pending_action = {"kind": "create", "map_index": map_index}
	return _connect_for_pending_action(address)


func join_room(code: String, player_name: String, address: String = "") -> Error:
	local_player_name = _clean_player_name(player_name)
	var normalized := Discovery.normalize_code(code)
	if normalized.is_empty(): return ERR_INVALID_PARAMETER
	if connection_pending or not active_room_code.is_empty(): return ERR_ALREADY_IN_USE
	_pending_action = {"kind": "join", "code": normalized}
	# Explicit addresses remain available to developer tools and existing direct
	# clients. The player-facing form omits them and always uses code discovery.
	if not address.strip_edges().is_empty(): return _connect_for_pending_action(address)
	_disconnect_peer()
	var result := _ensure_discovery().search(normalized,discovery_port)
	if result!=OK: _pending_action.clear(); return result
	connection_pending=true
	_connection_deadline=Time.get_ticks_msec()+Discovery.SEARCH_MS+1000
	connection_changed.emit(false,"Finding the host on your Wi-Fi…")
	return OK


func _ensure_discovery() -> Discovery:
	if not is_instance_valid(lan_discovery):
		lan_discovery=Discovery.new()
		lan_discovery.name="LanDiscovery"
		add_child(lan_discovery)
		lan_discovery.host_found.connect(_on_discovery_found)
		lan_discovery.search_failed.connect(_on_discovery_failed)
	return lan_discovery


func _discovery_room(code: String) -> Dictionary:
	return {"port":server_port} if rooms.has(code) else {}


func _on_discovery_found(address: String, port: int) -> void:
	if not connection_pending or _pending_action.get("kind")!="join": return
	var result := connect_to_server(address,port)
	if result!=OK: _on_discovery_failed("The host was found but could not be reached. Keep its game open and try again.")


func _on_discovery_failed(message: String) -> void:
	_pending_action.clear()
	_disconnect_peer()
	connection_changed.emit(false,message)


func _connect_for_pending_action(address: String) -> Error:
	var destination := address.strip_edges() if not address.strip_edges().is_empty() else server_address
	if is_connected_to_room_server() and destination == server_address:
		_send_pending_action()
		return OK
	return connect_to_server(destination, server_port)


func _send_pending_action() -> void:
	if _pending_action.is_empty():
		return
	match str(_pending_action.get("kind", "")):
		"create":
			request_create_room.rpc_id(1, int(_pending_action["map_index"]), local_player_name)
		"join":
			request_join_room.rpc_id(1, str(_pending_action["code"]), local_player_name)
	_pending_action.clear()


func set_character(character: String) -> void:
	if active_room_code.is_empty() or multiplayer.is_server():
		return
	request_select_character.rpc_id(1, character)


func toggle_ready() -> void:
	if active_room_code.is_empty() or multiplayer.is_server():
		return
	request_toggle_ready.rpc_id(1)


func start_match() -> void:
	if active_room_code.is_empty() or multiplayer.is_server():
		return
	request_start_match.rpc_id(1)


func send_player_input(direction: Vector2) -> void:
	if active_room_code.is_empty() or not is_connected_to_room_server():
		return
	request_player_input.rpc_id(1, direction)


func cast_sleep_spell(target_id: int) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_sleep_spell.rpc_id(1, target_id)


func submit_task_action(task_index: int) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_task_action.rpc_id(1, task_index)


func inspect_clue(clue_index: int) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_inspect_clue.rpc_id(1, clue_index)


func call_meeting() -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_call_meeting.rpc_id(1)


func send_chat(message: String) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_send_chat.rpc_id(1, message)


func cast_vote(target_id: int) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_cast_vote.rpc_id(1, target_id)


func cast_sabotage(kind: String) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		request_sabotage.rpc_id(1, kind)


func leave_room() -> void:
	if not active_room_code.is_empty() and not multiplayer.is_server():
		request_leave_room.rpc_id(1)
	active_room_code = ""
	local_character = ""
	local_player_role = ""
	local_secret_character = ""
	local_role_character = ""
	_pending_action.clear()
	_disconnect_peer()


func _disconnect_peer() -> void:
	if is_instance_valid(lan_discovery): lan_discovery.cancel_search()
	lobby_countdown = -1.0
	connection_pending = false
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _on_connected_to_server() -> void:
	connection_pending = false
	connection_changed.emit(true, "Connected to room server.")
	_send_pending_action()


func local_peer_id() -> int:
	return multiplayer.get_unique_id()


func is_connected_to_room_server() -> bool:
	var peer := multiplayer.get_multiplayer_peer()
	return peer is ENetMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _on_connection_failed() -> void:
	_pending_action.clear()
	_disconnect_peer()
	connection_changed.emit(false, "Cannot reach the host. Use the same Wi-Fi, keep the host's game open, and allow the game on Private networks if Windows asks.")


func _on_server_disconnected() -> void:
	active_room_code = ""
	local_character = ""
	local_player_role = ""
	local_secret_character = ""
	local_role_character = ""
	_pending_action.clear()
	_disconnect_peer()
	connection_changed.emit(false, "The room server disconnected.")


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		_remove_player(peer_id)


func _clean_player_name(value: String) -> String:
	var result := value.strip_edges()
	if result.is_empty():
		result = "Player"
	return result.substr(0, 20)


func _new_room_code() -> String:
	const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code := ""
	for _i in 5:
		code += ALPHABET.substr(_server_random.randi_range(0, ALPHABET.length() - 1), 1)
	return code


func _find_room_code() -> String:
	for _attempt in 256:
		var candidate := _new_room_code()
		if not rooms.has(candidate):
			return candidate
	return ""


func _make_player(peer_id: int, player_name: String, is_host: bool = false, character: String = "") -> Dictionary:
	return {"id": peer_id, "name": _clean_player_name(player_name), "character": character, "ready": false, "host": is_host, "alive": true, "sleeping": false, "position": Vector2(640, 390), "direction": Vector2.ZERO, "role": "villager", "role_character": "", "sleep_ready_at": 0.0}

func _random_available_character(players: Dictionary) -> String:
	var available: Array[String] = []
	for character in GameData.CHARACTERS:
		var taken := false
		for member in players.values():
			if str(member.get("character", "")) == character:
				taken = true
				break
		if not taken:
			available.append(character)
	if available.is_empty(): return ""
	return available[_server_random.randi_range(0, available.size() - 1)]


func _room_members(room: Dictionary) -> Array:
	var members: Array = []
	for member in room["players"].values():
		var visible_member: Dictionary = member.duplicate(true)
		visible_member.erase("role")
		visible_member.erase("role_character")
		visible_member.erase("direction")
		visible_member.erase("sleep_ready_at")
		members.append(visible_member)
	return members


func _send_room_state(code: String) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var members := _room_members(room)
	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_room_state.rpc_id(int(peer_id), code, int(room["map_index"]), int(room["host_id"]), members)
		_rpc_lobby_countdown.rpc_id(int(peer_id), float(room.get("start_countdown", -1.0)))


func _can_send_to(peer_id: int) -> bool:
	if peer_id not in multiplayer.get_peers(): return false
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport == null: return false
	var peer := transport.get_peer(peer_id)
	return peer != null and peer.is_active() and peer.get_state() == ENetPacketPeer.STATE_CONNECTED


func _broadcast_positions(code: String, reliable: bool = false) -> void:
	if not rooms.has(code): return
	var room: Dictionary = rooms[code]
	var now := Time.get_ticks_msec() / 1000.0
	room["state_sequence"] = int(room.get("state_sequence", 0)) + 1
	var positions: Array = []
	for member in room["players"].values():
		positions.append({"id": member["id"], "position": member["position"], "alive": member["alive"], "sleeping": bool(member.get("sleeping", false))})
	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		var receiver_state := positions.duplicate(true)
		var power_state := NenekPowers.snapshot(room, room["players"][peer_id], now)
		if str(room["players"][peer_id].get("role", "")) != "nenek_kebayan":
			power_state["sleep_cooldown"] = 0.0
			power_state["sabotage_cooldown"] = 0.0
		receiver_state.append({"powers": power_state, "revision": room["state_sequence"]})
		if reliable: _rpc_power_snapshot.rpc_id(int(peer_id), receiver_state)
		else: _rpc_player_positions.rpc_id(int(peer_id), receiver_state)

func _broadcast_task_state(code: String) -> void:
	var room: Dictionary = rooms.get(code, {})
	for peer_id in room.get("players", {}).keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_task_state.rpc_id(int(peer_id), room["completed_tasks"], room["task_progress"])


func _alive_player_ids(room: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for peer_id in room["players"].keys():
		if NenekPowers.is_active(room["players"][peer_id]):
			result.append(int(peer_id))
	return result


func _broadcast_meeting_state(code: String) -> void:
	var room: Dictionary = rooms.get(code, {})
	var seconds_left := ceili(float(room.get("meeting_timer", 0.0)))
	var members := _room_members(room)
	var votes_cast: int = room.get("votes", {}).size()
	var alive_count := _alive_player_ids(room).size()
	for peer_id in room.get("players", {}).keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_meeting_state.rpc_id(int(peer_id), str(room.get("meeting_state", "")), seconds_left, members, votes_cast, alive_count)


func _finish_game(code: String, winner: String, message: String) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	if bool(room.get("finished", false)):
		return
	room["finished"] = true
	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_game_finished.rpc_id(int(peer_id), winner, message)


func _resolve_vote(code: String) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	if str(room.get("meeting_state", "")) != "voting":
		return
	var tally: Dictionary = {}
	var skip_count := 0
	for target in room["votes"].values():
		var target_id := int(target)
		if target_id < 0:
			skip_count += 1
		else:
			tally[target_id] = int(tally.get(target_id, 0)) + 1
	var highest := 0
	var leaders: Array[int] = []
	for target_id in tally.keys():
		var count := int(tally[target_id])
		if count > highest:
			highest = count
			leaders = [int(target_id)]
		elif count == highest:
			leaders.append(int(target_id))
	var eliminated_id := -1
	if leaders.size() == 1 and highest > skip_count:
		eliminated_id = leaders[0]
	var result_message := "No player was voted out."
	var winner := ""
	if eliminated_id >= 0 and room["players"].has(eliminated_id):
		var eliminated: Dictionary = room["players"][eliminated_id]
		eliminated["alive"] = false
		var eliminated_name := str(eliminated.get("name", "A player"))
		if str(eliminated.get("role", "villager")) == "nenek_kebayan":
			result_message = eliminated_name + " was Nenek Kebayan. The Villagers win!"
			winner = "villagers"
		else:
			result_message = eliminated_name + " was voted out. Nenek Kebayan is still among you."
			var any_villager_alive := false
			for member in room["players"].values():
				if str(member.get("role", "villager")) == "villager" and NenekPowers.is_active(member):
					any_villager_alive = true
					break
			if not any_villager_alive:
				winner = "nenek_kebayan"
				result_message = "No awake villager remain. Nenek Kebayan wins!"
	room["meeting_state"] = ""
	room["meeting_timer"] = 0.0
	room["votes"] = {}
	_broadcast_positions(code, true)
	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_meeting_result.rpc_id(int(peer_id), eliminated_id, result_message, winner)
	if not winner.is_empty():
		_finish_game(code, winner, result_message)
	else:
		_send_room_state(code)


func _all_ready(room: Dictionary) -> bool:
	if room["players"].is_empty():
		return false
	for member in room["players"].values():
		if not bool(member.get("ready", false)) or str(member.get("character", "")).is_empty():
			return false
	return true


func _tick_lobby_countdown(code: String, delta: float) -> void:
	var room: Dictionary = rooms[code]
	var previous := float(room.get("start_countdown", -1.0))
	var count: int = room["players"].size()
	var eligible := count >= 5 and count <= MAX_PLAYERS_PER_ROOM and _all_ready(room)
	var remaining := -1.0
	if eligible:
		remaining = LOBBY_WAIT_SECONDS if previous < 0.0 else maxf(0.0, previous - delta)
	room["start_countdown"] = remaining
	if ceili(previous) != ceili(remaining):
		for peer_id in room["players"]:
			if _can_send_to(int(peer_id)): _rpc_lobby_countdown.rpc_id(int(peer_id), remaining)
	if eligible and remaining <= 0.0: _try_start_room(code, false)


func _try_start_room(code: String, require_host: bool, requester_id: int = 0) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var player_count: int = room["players"].size()
	if bool(room["started"]) or player_count < 5 or player_count > MAX_PLAYERS_PER_ROOM or not _all_ready(room):
		return
	if require_host and requester_id != int(room["host_id"]):
		return
	if float(room.get("start_countdown", -1.0)) > 0.0: return
	room["started"] = true
	var members: Array = room["players"].values()
	var role_player_index := _server_random.randi_range(0, members.size() - 1)
	if force_host_nenek_for_testing:
		for i in members.size():
			if int(members[i].get("id", -1)) == int(room["host_id"]):
				role_player_index = i
				break
	var secret_character := str(members[role_player_index].get("character", ""))
	var villager_role_characters: Array[String] = []
	for i in members.size():
		if i != role_player_index:
			villager_role_characters.append(str(members[i].get("character", "")))
	villager_role_characters.shuffle()
	var map_name: String = GameData.MAPS[int(room["map_index"])]["name"]
	var map_index := int(room["map_index"])
	room["completed_tasks"] = []
	room["task_progress"] = []
	for _task in GameData.TASKS[map_name].size():
		room["completed_tasks"].append(0)
		room["task_progress"].append(0)
	var candidate_points: Array = []
	for point in MapGeometry.clue_candidates(map_index):
		if not MapGeometry.is_position_blocked(map_index, point): candidate_points.append(point)
	if candidate_points.size() < 3:
		candidate_points = MapGeometry.clue_candidates(map_index).duplicate()
	candidate_points.shuffle()
	room["clue_positions"] = candidate_points.slice(0, 3)
	room["clue_names"] = GameData.CHARACTER_CLUES[secret_character].duplicate()
	room["found_clues"] = []
	room["meeting_state"] = ""
	room["meeting_timer"] = 0.0
	room["votes"] = {}
	room["secret_character"] = secret_character
	NenekPowers.reset_match(room, Time.get_ticks_msec() / 1000.0)
	var villager_character_index := 0
	for i in members.size():
		var member: Dictionary = members[i]
		var player_id := int(member["id"])
		room["players"][player_id]["position"] = MapGeometry.spawn_point_for_player(map_index, i)
		room["players"][player_id]["direction"] = Vector2.ZERO
		var role := "nenek_kebayan" if i == role_player_index else "villager"
		var role_character := secret_character
		if role == "villager":
			role_character = villager_role_characters[villager_character_index]
			villager_character_index += 1
		room["players"][int(member["id"])]["role"] = role
		room["players"][int(member["id"])]["role_character"] = role_character
		if _can_send_to(player_id): _rpc_private_role.rpc_id(player_id, role, secret_character if role == "nenek_kebayan" else "", role_character)
	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_match_started.rpc_id(int(peer_id), int(room["map_index"]), room["clue_positions"])
	_send_room_state(code)
	_broadcast_task_state(code)
	print("Started room %s with %d players" % [code, player_count])


func _remove_player(peer_id: int) -> void:
	if not peer_room_codes.has(peer_id):
		return
	var code: String = peer_room_codes[peer_id]
	peer_room_codes.erase(peer_id)
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	room["players"].erase(peer_id)
	if room.has("votes"): room["votes"].erase(peer_id)
	if room["players"].is_empty():
		rooms.erase(code)
		return
	if int(room["host_id"]) == peer_id:
		var remaining_ids: Array = room["players"].keys()
		remaining_ids.sort()
		room["host_id"] = int(remaining_ids[0])
		for member in room["players"].values():
			member["host"] = int(member["id"]) == int(room["host_id"])
	_send_room_state(code)
	if str(room.get("meeting_state", "")) != "": _broadcast_meeting_state(code)
	if bool(room.get("started", false)):
		var living_villagers := 0
		var living_kebayan := 0
		for member in room["players"].values():
			if not NenekPowers.is_active(member): continue
			if str(member.get("role", "villager")) == "nenek_kebayan": living_kebayan += 1
			else: living_villagers += 1
		if living_kebayan == 0:
			_finish_game(code, "villagers", "Nenek Kebayan left the room. The Villagers win!")
		elif living_villagers == 0:
			_finish_game(code, "nenek_kebayan", "No awake villager remain. Nenek Kebayan wins!")
	if str(room.get("meeting_state", "")) == "voting" and room["votes"].size() >= _alive_player_ids(room).size():
		_resolve_vote(code)


@rpc("any_peer", "call_remote", "reliable")
func request_create_room(map_index: int, player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if map_index < 0 or map_index >= GameData.MAPS.size():
		_rpc_room_error.rpc_id(sender, "Invalid map selection.")
		return
	if peer_room_codes.has(sender):
		_rpc_room_error.rpc_id(sender, "Leave your current room before creating another.")
		return
	var code := _find_room_code()
	if code.is_empty():
		_rpc_room_error.rpc_id(sender, "Room creation failed. Try again.")
		return
	var host := _make_player(sender, player_name, true, _random_available_character({}))
	rooms[code] = {"map_index": map_index, "host_id": sender, "players": {sender: host}, "started": false, "selected_characters": {}}
	peer_room_codes[sender] = code
	_rpc_room_opened.rpc_id(sender, code, map_index, _room_members(rooms[code]), true)
	_send_room_state(code)


@rpc("any_peer", "call_remote", "reliable")
func request_join_room(code: String, player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var normalized_code := code.strip_edges().to_upper()
	if peer_room_codes.has(sender):
		_rpc_room_error.rpc_id(sender, "Leave your current room before joining another.")
		return
	if normalized_code.length() != 5:
		_rpc_room_error.rpc_id(sender, "Invalid Room Code")
		return
	for i in normalized_code.length():
		if not "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains(normalized_code.substr(i, 1)):
			_rpc_room_error.rpc_id(sender, "Invalid Room Code")
			return
	if not rooms.has(normalized_code):
		_rpc_room_error.rpc_id(sender, "Room Not Found")
		return
	var room: Dictionary = rooms[normalized_code]
	if bool(room["started"]):
		_rpc_room_error.rpc_id(sender, "Game Already Started")
		return
	if room["players"].size() >= MAX_PLAYERS_PER_ROOM:
		_rpc_room_error.rpc_id(sender, "Room Is Full")
		return
	room["players"][sender] = _make_player(sender, player_name, false, _random_available_character(room["players"]))
	_tick_lobby_countdown(normalized_code, 0.0)
	peer_room_codes[sender] = normalized_code
	_rpc_room_opened.rpc_id(sender, normalized_code, int(room["map_index"]), _room_members(room), false)
	_send_room_state(normalized_code)


@rpc("any_peer", "call_remote", "reliable")
func request_select_character(character: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender) or character not in GameData.CHARACTERS:
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if bool(room.get("started", true)) or not room["players"].has(sender):
		return
	var selected_by_other := false
	for peer_id in room["players"].keys():
		if int(peer_id) != sender and str(room["players"][peer_id].get("character", "")) == character:
			selected_by_other = true
			break
	if selected_by_other:
		_rpc_room_error.rpc_id(sender, "That character is already selected.")
		return
	room["players"][sender]["character"] = character
	room["players"][sender]["ready"] = false
	_tick_lobby_countdown(code, 0.0)
	_send_room_state(code)


@rpc("any_peer", "call_remote", "reliable")
func request_toggle_ready() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if bool(room.get("started", true)) or not room["players"].has(sender):
		return
	var member: Dictionary = room["players"][sender]
	if str(member.get("character", "")).is_empty():
		_rpc_room_error.rpc_id(sender, "Choose a character before marking Ready.")
		return
	member["ready"] = not bool(member.get("ready", false))
	_tick_lobby_countdown(code, 0.0)
	_send_room_state(code)


@rpc("any_peer", "call_remote", "reliable")
func request_start_match() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	if int(rooms[code]["host_id"]) != sender: return
	_tick_lobby_countdown(code, 0.0)


@rpc("any_peer", "call_remote", "reliable")
func request_leave_room() -> void:
	if multiplayer.is_server():
		_remove_player(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "unreliable_ordered")
func request_player_input(direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var room: Dictionary = rooms.get(peer_room_codes[sender], {})
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "":
		return
	if not room["players"].has(sender) or not NenekPowers.is_active(room["players"][sender]):
		return
	if direction.length() > 1.25:
		return
	room["players"][sender]["direction"] = direction.normalized() if direction.length() > 1.0 else direction


@rpc("any_peer", "call_remote", "reliable")
func request_task_action(task_index: int) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "":
		return
	if not room["players"].has(sender):
		return
	var member: Dictionary = room["players"][sender]
	if not NenekPowers.is_active(member) or str(member.get("role", "villager")) != "villager":
		_rpc_task_resolved.rpc_id(sender, task_index, false, 0, false)
		return
	var map_name: String = GameData.MAPS[int(room["map_index"])]["name"]
	var tasks: Array = GameData.TASKS[map_name]
	if task_index < 0 or task_index >= tasks.size():
		_rpc_task_resolved.rpc_id(sender, task_index, false, 0, false)
		return
	var position: Vector2 = member.get("position", Vector2.ZERO)
	var task_point: Vector2 = MapGeometry.task_points(int(room["map_index"]))[task_index]
	if position.distance_to(task_point) > 72.0 or not MapGeometry.has_clear_path(int(room["map_index"]),position,task_point,NenekPowers.locked_doors(room,Time.get_ticks_msec()/1000.0)):
		_rpc_task_resolved.rpc_id(sender, task_index, false, int(room["task_progress"][task_index]), bool(room["completed_tasks"][task_index]))
		return
	if int(room["completed_tasks"][task_index]) == 1:
		_rpc_task_resolved.rpc_id(sender, task_index, false, int(room["task_progress"][task_index]), true)
		return
	room["task_progress"][task_index] = int(room["task_progress"][task_index]) + 1
	var required: int = GameData.TASK_STEPS[map_name][task_index]
	if int(room["task_progress"][task_index]) >= required:
		room["completed_tasks"][task_index] = 1
	_rpc_task_resolved.rpc_id(sender, task_index, true, int(room["task_progress"][task_index]), int(room["completed_tasks"][task_index]) == 1)
	_broadcast_task_state(code)
	if room["completed_tasks"].count(1) == tasks.size():
		_finish_game(code, "villagers", "All required tasks are complete. The Villagers win!")


@rpc("any_peer", "call_remote", "reliable")
func request_inspect_clue(clue_index: int) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "":
		return
	if not room["players"].has(sender):
		return
	var member: Dictionary = room["players"][sender]
	if not NenekPowers.is_active(member) or str(member.get("role", "villager")) != "villager":
		_rpc_room_error.rpc_id(sender, "Only awake villagers can inspect clues.")
		return
	var positions: Array = room["clue_positions"]
	if clue_index < 0 or clue_index >= positions.size() or clue_index in room["found_clues"]:
		return
	var position: Vector2 = member.get("position", Vector2.ZERO)
	if position.distance_to(positions[clue_index]) > 72.0:
		_rpc_room_error.rpc_id(sender, "Move close to the clue to inspect it.")
		return
	room["found_clues"].append(clue_index)
	var clue_name: String = room["clue_names"][clue_index]
	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_clue_found.rpc_id(int(peer_id), clue_index, clue_name, sender)


@rpc("any_peer", "call_remote", "reliable")
func request_call_meeting() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "":
		return
	if not room["players"].has(sender) or not NenekPowers.is_active(room["players"][sender]):
		return
	var position: Vector2 = room["players"][sender].get("position", Vector2.ZERO)
	if position.distance_to(MapGeometry.gong_point(int(room["map_index"]))) > 78.0:
		_rpc_room_error.rpc_id(sender, "Move close to the gong to call a meeting.")
		return
	room["meeting_state"] = "discussion"
	room["meeting_timer"] = 60.0
	room["votes"] = {}
	room["chat_messages"] = []
	for member in room["players"].values(): member["direction"] = Vector2.ZERO
	_broadcast_meeting_state(code)


@rpc("any_peer", "call_remote", "reliable")
func request_send_chat(message: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if str(room.get("meeting_state", "")) != "discussion" or not room["players"].has(sender) or not NenekPowers.is_active(room["players"][sender]):
		return
	var clean_message := message.strip_edges().substr(0, 200)
	if clean_message.is_empty():
		return
	var player_name := str(room["players"][sender].get("name", "Player"))
	for peer_id in room["players"].keys():
		if NenekPowers.is_active(room["players"][peer_id]):
			_rpc_chat_message.rpc_id(int(peer_id), sender, player_name, clean_message)


@rpc("any_peer", "call_remote", "reliable")
func request_cast_vote(target_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	if str(room.get("meeting_state", "")) != "voting" or not room["players"].has(sender) or not NenekPowers.is_active(room["players"][sender]):
		return
	if room["votes"].has(sender):
		_rpc_room_error.rpc_id(sender, "You have already voted.")
		return
	if target_id >= 0 and (not room["players"].has(target_id) or not NenekPowers.is_active(room["players"][target_id])):
		return
	room["votes"][sender] = target_id
	_broadcast_meeting_state(code)
	if room["votes"].size() >= _alive_player_ids(room).size():
		_resolve_vote(code)


func _ability_room_for_sender(sender: int) -> Dictionary:
	if not peer_room_codes.has(sender):
		return {}
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms.get(code, {})
	var players: Dictionary = room.get("players", {})
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "" or not players.has(sender):
		return {}
	return {"code": code, "room": room, "player": room["players"][sender]}


func _ability_error(sender: int, message: String) -> void:
	_rpc_room_error.rpc_id(sender, message)


@rpc("any_peer", "call_remote", "reliable")
func request_sleep_spell(target_id: int) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	var context := _ability_room_for_sender(sender)
	if context.is_empty(): return
	var room: Dictionary = context["room"]
	var error := NenekPowers.try_sleep(room, sender, target_id, Time.get_ticks_msec() / 1000.0)
	if not error.is_empty():
		_ability_error(sender, error)
		return
	_rpc_ability_feedback.rpc_id(sender, "Sleep Spell cast. That villager is asleep for the rest of this match.")
	_broadcast_positions(str(context["code"]), true)
	_send_room_state(str(context["code"]))
	if NenekPowers.winner(room) == "nenek_kebayan":
		_finish_game(str(context["code"]), "nenek_kebayan", "No awake villager remain. Nenek Kebayan wins!")


@rpc("any_peer", "call_remote", "reliable")
func request_sabotage(kind: String) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	var context := _ability_room_for_sender(sender)
	if context.is_empty(): return
	var room: Dictionary = context["room"]
	var error := NenekPowers.try_sabotage(room, sender, kind, Time.get_ticks_msec() / 1000.0)
	if not error.is_empty():
		_ability_error(sender, error)
		return
	var areas := MapGeometry.sabotage_areas(int(room["map_index"]))
	var area_index := int(room.get("sabotage_area", -1))
	var area_name := str(areas[area_index]["name"]) if area_index >= 0 else "your surroundings"
	_rpc_ability_feedback.rpc_id(sender, ("Fog covers " if kind == "fog" else "Entrances locked: ") + area_name)
	_broadcast_positions(str(context["code"]), true)


@rpc("authority", "call_remote", "reliable")
func _rpc_room_opened(code: String, map_index: int, members: Array, is_host: bool) -> void:
	active_room_code = code
	lobby_countdown = -1.0
	local_player_role = ""
	local_secret_character = ""
	local_role_character = ""
	room_opened.emit(code, map_index, members, is_host)


@rpc("authority", "call_remote", "reliable")
func _rpc_room_state(code: String, map_index: int, host_id: int, members: Array) -> void:
	active_room_code = code
	for member in members:
		if int(member.get("id", -1)) == multiplayer.get_unique_id():
			local_character = str(member.get("character", ""))
	room_changed.emit(code, map_index, host_id, members)


@rpc("authority", "call_remote", "reliable")
func _rpc_room_error(message: String) -> void:
	room_error.emit(message)


@rpc("authority", "call_remote", "reliable")
func _rpc_ability_feedback(message: String) -> void:
	ability_feedback.emit(message)


@rpc("authority", "call_remote", "reliable")
func _rpc_private_role(role: String, secret_character: String, role_character: String) -> void:
	local_player_role = role
	local_secret_character = secret_character
	local_role_character = role_character
	role_received.emit(role, secret_character)


@rpc("authority", "call_remote", "reliable")
func _rpc_lobby_countdown(seconds_left: float) -> void:
	lobby_countdown = seconds_left
	lobby_countdown_changed.emit(seconds_left)


@rpc("authority", "call_remote", "reliable")
func _rpc_match_started(map_index: int, clue_positions: Array) -> void:
	lobby_countdown = -1.0
	match_started.emit(map_index, clue_positions)


@rpc("authority", "call_remote", "reliable")
func _rpc_power_snapshot(members: Array) -> void:
	positions_changed.emit(members)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_player_positions(members: Array) -> void:
	positions_changed.emit(members)


@rpc("authority", "call_remote", "reliable")
func _rpc_task_state(completed: Array, progress: Array) -> void:
	task_state_changed.emit(completed, progress)


@rpc("authority", "call_remote", "reliable")
func _rpc_task_resolved(task_index: int, success: bool, progress: int, complete: bool) -> void:
	task_resolved.emit(task_index, success, progress, complete)


@rpc("authority", "call_remote", "reliable")
func _rpc_clue_found(clue_index: int, clue_name: String, found_by: int) -> void:
	clue_found.emit(clue_index, clue_name, found_by)


@rpc("authority", "call_remote", "reliable")
func _rpc_meeting_state(state: String, seconds_left: int, members: Array, votes_cast: int, alive_count: int) -> void:
	meeting_changed.emit(state, seconds_left, members, votes_cast, alive_count)


@rpc("authority", "call_remote", "reliable")
func _rpc_chat_message(peer_id: int, player_name: String, message: String) -> void:
	chat_received.emit(peer_id, player_name, message)


@rpc("authority", "call_remote", "reliable")
func _rpc_meeting_result(target_id: int, message: String, winner: String) -> void:
	meeting_result.emit(target_id, message, winner)


@rpc("authority", "call_remote", "reliable")
func _rpc_game_finished(winner: String, message: String) -> void:
	match_finished.emit(winner, message)
