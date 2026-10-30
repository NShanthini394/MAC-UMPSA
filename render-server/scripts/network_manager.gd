extends Node
## Authoritative room service: ENet for Wi-Fi, WebSocket for internet play.

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
signal matchmaking_changed(waiting: int)
signal elimination_revealed(details: Dictionary)

const PORT := 7000
const MAX_PLAYERS_PER_ROOM := 10
const MAX_SERVER_CLIENTS := 100
const LOBBY_WAIT_SECONDS := 5.0
const ALARM_SECONDS := 3.2
const DISCUSSION_SECONDS := 45.0
const VOTING_SECONDS := 20.0
const REVEAL_SECONDS := 7.0
const Rules = preload("res://scripts/match_rules.gd")
const Companions = preload("res://scripts/walking_companions.gd")
var public_queue: Array[int] = []
var queue_names: Dictionary = {}
var _queue_batch_until := -1.0
var _next_bot_id := 2147483000
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
var _input_sent_at := -1000
var _last_input_direction := Vector2.ZERO
var _input_sequence := 0
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
var _warmup: HTTPRequest
var _connection_generation := 0


func _ready() -> void:
	_server_random.randomize()
	_ensure_discovery()
	server_address = str(ProjectSettings.get_setting("network/server_address", server_address))
	server_port = int(ProjectSettings.get_setting("network/server_port", PORT))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	var arguments := OS.get_cmdline_user_args()
	if "--server" in arguments:
		var port := server_port
		var port_index := arguments.find("--port")
		if port_index >= 0 and port_index + 1 < arguments.size():
			port = int(arguments[port_index + 1])
		var result := start_server(port, "--websocket" in arguments)
		if result != OK:
			push_error("Room server could not start: %s" % error_string(result))
			get_tree().quit(1)


func _process(delta: float) -> void:
	if connection_pending and Time.get_ticks_msec() >= _connection_deadline:
		_on_connection_failed()
	if not multiplayer.is_server(): return
	_tick_matchmaking()
	_position_broadcast_timer += delta
	var now := Time.get_ticks_msec() / 1000.0
	for code in rooms.keys():
		var room: Dictionary = rooms[code]
		if not bool(room.get("started", false)):
			_tick_lobby_countdown(str(code), delta)
			continue
		if bool(room.get("finished", false)): continue
		_tick_testing_bots(str(code), now)
		if bool(room.get("finished", false)): continue
		if NenekPowers.expire_sabotage(room, now): _broadcast_positions(str(code), true)
		if str(room.get("meeting_state", "")) != "":
			room["meeting_timer"] = maxf(0.0, float(room.get("meeting_timer", 0.0)) - delta)
			if room["meeting_timer"] <= 0.0:
				match str(room["meeting_state"]):
					"alarm": _set_meeting_phase(str(code), "discussion", DISCUSSION_SECONDS)
					"discussion":
						room["votes"] = {}
						_set_meeting_phase(str(code), "voting_intro", 3.2)
					"voting_intro": _set_meeting_phase(str(code), "voting", VOTING_SECONDS)
					"voting": _resolve_vote(str(code))
					"reveal":
						room["meeting_state"] = ""
						var victor := Rules.winner(room)
						if not victor.is_empty(): _finish_game(str(code), victor, _winner_message(victor))
						else: _broadcast_meeting_state(str(code))
			continue
		var entrances := NenekPowers.locked_doors(room, now)
		var map_index := int(room.get("map_index", 0))
		var bounds := MapGeometry.world_size(map_index)
		Companions.tick(room, delta, now, _server_random, entrances)
		for player in room["players"].values():
			if not bool(player.get("alive", true)): continue
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

func start_server(port: int = PORT, websocket: bool = false) -> Error:
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return ERR_ALREADY_IN_USE
	# All gameplay travels through this server. Clients do not need direct peer
	# relays, including relay notifications racing simultaneous disconnects.
	var scene_api := multiplayer as SceneMultiplayer
	if scene_api: scene_api.server_relay = false
	var peer: MultiplayerPeer
	var result: Error
	if websocket:
		var socket := WebSocketMultiplayerPeer.new()
		result = socket.create_server(port, "127.0.0.1")
		peer = socket
	else:
		var enet := ENetMultiplayerPeer.new()
		result = enet.create_server(port, MAX_SERVER_CLIENTS)
		peer = enet
	if result != OK:
		return result
	if not websocket:
		var discovery_result := _ensure_discovery().listen(discovery_port,_discovery_room)
		if discovery_result!=OK:
			peer.close()
			return discovery_result
	server_port = port
	multiplayer.multiplayer_peer = peer
	print("Nenek Kebayan room server listening on %s %d" % ["WebSocket" if websocket else "UDP", port])
	return OK


func connect_to_server(address: String, port: int = PORT) -> Error:
	var destination := address.strip_edges()
	if destination.is_empty() or port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	if is_connected_to_room_server() and destination == server_address and port == server_port: return OK
	_disconnect_peer()
	server_address = destination
	server_port = port
	if destination.begins_with("wss://") or destination.begins_with("ws://"):
		connection_pending = true
		_connection_deadline = Time.get_ticks_msec() + 120000
		if destination.begins_with("wss://"):
			_warmup = HTTPRequest.new()
			_warmup.timeout = 110.0
			add_child(_warmup)
			var generation := _connection_generation
			_warmup.request_completed.connect(func(result_code: int, response: int, _headers: PackedStringArray, _body: PackedByteArray):
				if generation != _connection_generation or not connection_pending: return
				if result_code != HTTPRequest.RESULT_SUCCESS or response != 200:
					_on_connection_failed()
					return
				if not _body.get_string_from_utf8().contains("lobby_protocol=4"):
					_pending_action.clear()
					_disconnect_peer()
					connection_changed.emit(false, "The online server needs the latest meeting update. Upload the new render-server folder and redeploy it first.")
					return
				if _connect_websocket(destination) != OK: _on_connection_failed()
			)
			var origin := destination.trim_prefix("wss://").get_slice("/", 0)
			var warm_result := _warmup.request("https://" + origin + "/healthz")
			if warm_result != OK: _disconnect_peer(); return warm_result
			connection_changed.emit(false, "Connecting online… A sleeping server may take up to two minutes to start.")
			return OK
		return _connect_websocket(destination)
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(server_address, server_port)
	if result != OK:
		return result
	multiplayer.multiplayer_peer = peer
	connection_pending = true
	_connection_deadline = Time.get_ticks_msec() + 8000
	connection_changed.emit(false, "Connecting to room server…")
	return OK


func _connect_websocket(url: String) -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	peer.handshake_timeout = 20.0
	var result := peer.create_client(url)
	if result != OK: return result
	multiplayer.multiplayer_peer = peer
	connection_pending = true
	_connection_deadline = Time.get_ticks_msec() + 20000
	connection_changed.emit(false, "Connecting to online room server…")
	return OK


func _on_peer_connected(peer_id: int) -> void:
	var transport := multiplayer.multiplayer_peer as WebSocketMultiplayerPeer
	if transport:
		transport.get_peer(peer_id).heartbeat_interval = 10.0
	if multiplayer.is_server() and multiplayer.get_peers().size() > MAX_SERVER_CLIENTS:
		multiplayer.disconnect_peer(peer_id)


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
		"matchmaking":
			request_find_match.rpc_id(1, local_player_name)
	_pending_action.clear()


func set_character(character: String) -> void:
	if active_room_code.is_empty() or multiplayer.is_server():
		return
	request_select_character.rpc_id(1, character)


func set_player_name(player_name: String) -> void:
	if not active_room_code.is_empty() and is_connected_to_room_server():
		local_player_name = _clean_player_name(player_name)
		request_set_player_name.rpc_id(1, local_player_name)


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
	var now := Time.get_ticks_msec()
	if direction == _last_input_direction and now - _input_sent_at < 80: return
	_input_sent_at = now
	_last_input_direction = direction
	_input_sequence += 1
	if direction.is_zero_approx(): request_stop_moving.rpc_id(1, _input_sequence)
	else: request_player_input.rpc_id(1, direction, _input_sequence)

@rpc("any_peer", "call_remote", "reliable")
func request_stop_moving(sequence: int = 0) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender): return
	var room: Dictionary = rooms.get(peer_room_codes[sender], {})
	if not room.get("players", {}).has(sender): return
	var member: Dictionary = room["players"][sender]
	if sequence > 0 and sequence <= int(member.get("input_sequence", 0)): return
	member["input_sequence"] = sequence
	member["direction"] = Vector2.ZERO


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
	_connection_generation += 1
	if is_instance_valid(_warmup):
		_warmup.cancel_request()
		_warmup.queue_free()
		_warmup = null
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
	return (peer is ENetMultiplayerPeer or peer is WebSocketMultiplayerPeer) and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _on_connection_failed() -> void:
	var online := server_address.begins_with("ws")
	_pending_action.clear()
	_disconnect_peer()
	connection_changed.emit(false, "Cannot reach the online server. Check your internet connection and try again. The server may be restarting." if online else "Cannot reach the host. Use the same Wi-Fi, keep the host's game open, and allow the game on Private networks if Windows asks.")


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


func _strip_companions(room: Dictionary) -> void:
	for id in room["players"].keys():
		if bool(room["players"][id].get("is_bot", false)): room["players"].erase(id)


func _fill_companions(room: Dictionary) -> void:
	const NAMES := ["Aiman", "Suri", "Farah", "Hakim", "Melati", "Arif", "Dahlia", "Irfan", "Lina", "Johan", "Arjun", "Priya", "Kavitha", "Ravi", "Mei Ling", "Wei Jian", "Jia Xin", "Jun Hao", "Siti", "Devi"]
	while room["players"].size() < MAX_PLAYERS_PER_ROOM:
		while _next_bot_id in multiplayer.get_peers() or room["players"].has(_next_bot_id): _next_bot_id -= 1
		var name_index := _server_random.randi_range(0, NAMES.size()-1)
		var player_name: String = NAMES[name_index]
		while room["players"].values().any(func(m: Dictionary) -> bool: return str(m["name"]) == player_name):
			name_index = (name_index + 1) % NAMES.size()
			player_name = NAMES[name_index]
		var companion := _make_player(_next_bot_id, player_name, false, _random_available_character(room["players"]))
		companion["is_bot"] = true; companion["ready"] = true
		room["players"][_next_bot_id] = companion
		_next_bot_id -= 1


func find_match(player_name: String, address: String) -> Error:
	if connection_pending or not active_room_code.is_empty(): return ERR_ALREADY_IN_USE
	local_player_name = _clean_player_name(player_name)
	_pending_action = {"kind": "matchmaking"}
	return _connect_for_pending_action(address)


@rpc("any_peer", "call_remote", "reliable")
func request_find_match(player_name: String) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	if peer_room_codes.has(sender): return
	if sender not in public_queue: public_queue.append(sender)
	queue_names[sender] = _clean_player_name(player_name)
	_broadcast_queue()


func _broadcast_queue() -> void:
	for peer_id in public_queue:
		if _can_send_to(peer_id): _rpc_matchmaking.rpc_id(peer_id, public_queue.size())


func _tick_matchmaking() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	# Searching people may join an existing public lobby until its host starts.
	# This also replenishes a lobby when someone leaves before the countdown.
	for code in rooms:
		var existing: Dictionary = rooms[code]
		if not bool(existing.get("public",false)) or bool(existing.get("started",false)) or (float(existing.get("start_countdown",-1.0)) >= 0 and not bool(existing.get("bot_wait", false))): continue
		var changed := false
		while not public_queue.is_empty() and Rules.human_ids(existing).size() < MAX_PLAYERS_PER_ROOM:
			var id: int = public_queue.pop_front()
			existing["players"][id] = _make_player(id,str(queue_names[id]),false,_random_available_character(existing["players"]))
			queue_names.erase(id); peer_room_codes[id] = str(code)
			if _can_send_to(id): _rpc_room_opened.rpc_id(id,str(code),int(existing["map_index"]),_room_members(existing),false)
			changed = true
		if changed: _send_room_state(str(code)); _broadcast_queue()
	if public_queue.is_empty(): _queue_batch_until = -1.0; return
	if _queue_batch_until < 0.0: _queue_batch_until = now + 3.0
	if now < _queue_batch_until and public_queue.size() < MAX_PLAYERS_PER_ROOM: return
	var code := _find_room_code()
	if code.is_empty(): return
	var group := public_queue.slice(0, mini(MAX_PLAYERS_PER_ROOM, public_queue.size()))
	var room := {"map_index": _server_random.randi_range(0, GameData.MAPS.size()-1), "host_id": group[0], "players": {}, "started": false, "public": true}
	for id in group:
		room["players"][id] = _make_player(id, str(queue_names[id]), id == group[0], _random_available_character(room["players"]))
		peer_room_codes[id] = code
		public_queue.erase(id); queue_names.erase(id)
	rooms[code] = room
	for id in group:
		if _can_send_to(id): _rpc_room_opened.rpc_id(id, code, room["map_index"], _room_members(room), id == group[0])
	_send_room_state(code)
	_queue_batch_until = -1.0
	_broadcast_queue()


func _room_members(room: Dictionary) -> Array:
	var members: Array = []
	for member in room["players"].values():
		var visible_member: Dictionary = member.duplicate(true)
		visible_member.erase("role")
		visible_member.erase("role_character")
		visible_member.erase("direction")
		visible_member.erase("sleep_ready_at")
		for key in visible_member.keys():
			if str(key) == "is_bot" or str(key).begins_with("bot_"): visible_member.erase(key)
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
	var websocket := multiplayer.multiplayer_peer as WebSocketMultiplayerPeer
	if websocket:
		var socket := websocket.get_peer(peer_id)
		return socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport == null: return false
	var peer := transport.get_peer(peer_id)
	return peer != null and peer.is_active() and peer.get_state() == ENetPacketPeer.STATE_CONNECTED


func _broadcast_positions(code: String, reliable: bool = false, sleep_cast: Dictionary = {}) -> void:
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
		if not sleep_cast.is_empty(): power_state["sleep_cast"] = sleep_cast.duplicate(true)
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
	var alive_count := Rules.voter_ids(room).size()
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


func _set_meeting_phase(code: String, state: String, seconds: float) -> void:
	rooms[code]["meeting_state"] = state
	rooms[code]["meeting_timer"] = seconds
	_broadcast_meeting_state(code)


func _winner_message(winner: String) -> String:
	return "All twelve tasks are complete and both Nenek Kebayan have been found. The Villagers win!" if winner == "villagers" else "No human villagers remain awake in the match. The Nenek Kebayan team wins!"


func _resolve_vote(code: String) -> void:
	if not rooms.has(code): return
	var room: Dictionary = rooms[code]
	if str(room.get("meeting_state", "")) != "voting": return
	var tally: Dictionary = {}
	var skip_count := 0
	# Companions abstain. Only active humans affect the outcome; unanswered human
	# votes become Skip, so companions can never outvote the people playing.
	for voter in Rules.voter_ids(room):
		var target := int(room["votes"].get(voter, -1))
		if target < 0 or not room["players"].has(target) or not NenekPowers.is_active(room["players"][target]): skip_count += 1
		else: tally[target] = int(tally.get(target, 0)) + 1
	var highest := 0
	var leaders: Array[int] = []
	for target in tally:
		var count := int(tally[target])
		if count > highest: highest = count; leaders = [int(target)]
		elif count == highest: leaders.append(int(target))
	var target_id := leaders[0] if leaders.size() == 1 and highest > skip_count else -1
	var details := {"id": target_id, "name": "", "character": "", "was_nenek": false, "remaining": Rules.remaining_nenek(room), "tasks_complete": Rules.tasks_complete(room)}
	var message := "No one was eliminated. The vote was tied or skipped."
	if target_id >= 0:
		var member: Dictionary = room["players"][target_id]
		member["alive"] = false; member["direction"] = Vector2.ZERO
		details["name"] = member["name"]; details["character"] = member["character"]
		details["was_nenek"] = str(member["role"]) == "nenek_kebayan"
		details["remaining"] = Rules.remaining_nenek(room)
		message = str(member["name"]) + (" was Nenek Kebayan." if details["was_nenek"] else " was not Nenek Kebayan.")
	room["meeting_state"] = "reveal"
	room["meeting_timer"] = REVEAL_SECONDS
	room["votes"] = {}
	room["last_reveal"] = details
	_broadcast_positions(code, true)
	for peer_id in room["players"]:
		if not _can_send_to(int(peer_id)): continue
		_rpc_meeting_result.rpc_id(int(peer_id), target_id, message, "")
		_rpc_elimination_reveal.rpc_id(int(peer_id), details)
	_send_room_state(code)


func _all_ready(room: Dictionary) -> bool:
	if room["players"].is_empty():
		return false
	for member in room["players"].values():
		if str(member.get("character", "")).is_empty(): return false
		if int(member["id"]) != int(room["host_id"]) and not bool(member.get("ready", false)): return false
	return true

func _tick_testing_bots(code: String, now: float) -> void:
	var room: Dictionary = rooms[code]
	if not bool(room.get("bot_match", false)): return
	var state := str(room.get("meeting_state", ""))
	if state == "" and now >= float(room.get("bot_meeting_at", now + 90.0)):
		for member in room["players"].values():
			if bool(member.get("is_bot", false)) and NenekPowers.is_active(member) and member["position"].distance_to(MapGeometry.gong_point(int(room["map_index"]))) <= 78.0:
				room["bot_meeting_at"] = now + 90.0
				_set_meeting_phase(code, "alarm", ALARM_SECONDS)
				return
	for member in room["players"].values():
		if not bool(member.get("is_bot", false)) or not NenekPowers.is_active(member): continue
		var id := int(member["id"])
		if state == "voting" and not room["votes"].has(id):
			var candidates := Rules.voter_ids(room)
			candidates.erase(id)
			room["votes"][id] = candidates[_server_random.randi_range(0, candidates.size()-1)] if not candidates.is_empty() else -1
		if state != "" or now < float(member.get("bot_action_at", 0.0)): continue
		member["bot_action_at"] = now + 4.0
		if str(member["role"]) == "villager":
			var points := MapGeometry.task_points(int(room["map_index"]))
			for i in points.size():
				if int(room["completed_tasks"][i]) == 1 or member["position"].distance_to(points[i]) > 72.0: continue
				room["task_progress"][i] += 1
				if int(room["task_progress"][i]) >= int(GameData.COMMON_TASK_STEPS[i]): room["completed_tasks"][i] = 1
				_broadcast_task_state(code)
				break
		else:
			for target in room["players"].values():
				if NenekPowers.try_sleep(room, id, int(target["id"]), now).is_empty():
					_broadcast_positions(code, true, {"caster_id":id,"target_id":int(target["id"])})
					break
	if state == "":
		var victor := Rules.winner(room)
		if not victor.is_empty(): _finish_game(code, victor, _winner_message(victor))


func _tick_lobby_countdown(code: String, delta: float) -> void:
	var room: Dictionary = rooms[code]
	var previous := float(room.get("start_countdown", -1.0))
	if previous < 0.0:
		previous = 120.0
		room["bot_wait"] = true
	if bool(room.get("bot_wait", false)):
		var wait_left := maxf(0.0, previous - delta)
		room["start_countdown"] = wait_left
		if ceili(previous) != ceili(wait_left):
			for id in Rules.human_ids(room):
				if _can_send_to(id): _rpc_lobby_countdown.rpc_id(id, wait_left)
		if wait_left <= 0.0:
			room["bot_match"] = Rules.human_ids(room).size() < 5
			_fill_companions(room)
			for member in room["players"].values(): member["ready"] = true
			_try_start_room(code, false)
		return
	var count := Rules.human_ids(room).size()
	var eligible := count >= 5 and count <= MAX_PLAYERS_PER_ROOM and _all_ready(room)
	var remaining := maxf(0.0, previous - delta) if eligible else -1.0
	room["start_countdown"] = remaining
	if ceili(previous) != ceili(remaining):
		for peer_id in room["players"]:
			if _can_send_to(int(peer_id)): _rpc_lobby_countdown.rpc_id(int(peer_id), remaining)
	if eligible and remaining <= 0.0: _try_start_room(code, false)


func _try_start_room(code: String, require_host: bool, requester_id: int = 0) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var player_count := Rules.human_ids(room).size()
	if bool(room["started"]) or player_count < 1 or player_count > MAX_PLAYERS_PER_ROOM or not _all_ready(room):
		return
	if require_host and requester_id != int(room["host_id"]):
		return
	if float(room.get("start_countdown", -1.0)) != 0.0: return
	room["started"] = true
	var members: Array = room["players"].values()
	var human_ids := Rules.human_ids(room)
	human_ids.shuffle()
	if force_host_nenek_for_testing:
		human_ids.erase(int(room["host_id"])); human_ids.push_front(int(room["host_id"]))
	if bool(room.get("bot_match", false)):
		human_ids.assign(room["players"].keys())
		human_ids.shuffle()
	var impostors: Array[int] = human_ids.slice(0, 2)
	var secret_characters: Array[String] = []
	for id in impostors: secret_characters.append(str(room["players"][id]["character"]))
	room["secret_characters"] = secret_characters
	room["impostor_ids"] = impostors
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
	if candidate_points.size() < 6:
		candidate_points = MapGeometry.clue_candidates(map_index).duplicate()
	candidate_points.shuffle()
	room["clue_positions"] = candidate_points.slice(0, 6)
	room["clue_names"] = []
	for character in secret_characters: room["clue_names"].append_array(GameData.CHARACTER_CLUES[character])
	room["found_clues"] = []
	room["bot_meeting_at"] = Time.get_ticks_msec() / 1000.0 + 90.0
	room["meeting_state"] = ""
	room["meeting_timer"] = 0.0
	room["votes"] = {}
	NenekPowers.reset_match(room, Time.get_ticks_msec() / 1000.0)
	for i in members.size():
		var member: Dictionary = members[i]
		var player_id := int(member["id"])
		room["players"][player_id]["position"] = MapGeometry.spawn_point_for_player(map_index, i)
		room["players"][player_id]["direction"] = Vector2.ZERO
		room["players"][player_id]["bot_action_at"] = Time.get_ticks_msec() / 1000.0 + 20.0
		var role := "nenek_kebayan" if player_id in impostors else "villager"
		var role_character := str(member["character"])
		room["players"][player_id]["role"] = role
		room["players"][player_id]["role_character"] = role_character
		if _can_send_to(player_id): _rpc_private_role.rpc_id(player_id, role, role_character if role == "nenek_kebayan" else "", role_character)

	for peer_id in room["players"].keys():
		if not _can_send_to(int(peer_id)): continue
		_rpc_match_started.rpc_id(int(peer_id), int(room["map_index"]), room["clue_positions"])
	_send_room_state(code)
	_broadcast_task_state(code)
	print("Started room %s with %d players" % [code, player_count])


func _remove_player(peer_id: int) -> void:
	if peer_id in public_queue:
		public_queue.erase(peer_id); queue_names.erase(peer_id); _broadcast_queue()
	if not peer_room_codes.has(peer_id):
		return
	var code: String = peer_room_codes[peer_id]
	peer_room_codes.erase(peer_id)
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	if int(room["host_id"]) == peer_id:
		_finish_game(code, "host_left", "The host left. This game has ended for everyone.")
		for id in room["players"]: peer_room_codes.erase(id)
		rooms.erase(code)
		return
	room["players"].erase(peer_id)
	if not bool(room.get("started", false)): room["start_countdown"] = -1.0
	if room.has("votes"): room["votes"].erase(peer_id)
	if Rules.human_ids(room).is_empty():
		rooms.erase(code)
		return
	if not bool(room.get("started", false)): _strip_companions(room)
	if int(room["host_id"]) == peer_id:
		var remaining_ids := Rules.human_ids(room)
		remaining_ids.sort()
		room["host_id"] = int(remaining_ids[0])
		for member in room["players"].values():
			member["host"] = int(member["id"]) == int(room["host_id"])
	_send_room_state(code)
	if str(room.get("meeting_state", "")) != "": _broadcast_meeting_state(code)
	if bool(room.get("started", false)) and str(room.get("meeting_state", "")) != "reveal":
		var victor := Rules.winner(room)
		if not victor.is_empty(): _finish_game(code, victor, _winner_message(victor))


@rpc("any_peer", "call_remote", "reliable")
func request_create_room(map_index: int, player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if map_index < 0 or map_index >= GameData.MAPS.size():
		_rpc_room_error.rpc_id(sender, "Invalid map selection.")
		return
	if peer_room_codes.has(sender) or sender in public_queue:
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
	if peer_room_codes.has(sender) or sender in public_queue:
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
	if bool(room["started"]) or (float(room.get("start_countdown", -1.0)) >= 0.0 and not bool(room.get("bot_wait", false))):
		_rpc_room_error.rpc_id(sender, "Game already started or starting. Please join another room.")
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
	if (float(room.get("start_countdown", -1.0)) >= 0.0 and not bool(room.get("bot_wait", false))) or (sender != int(room["host_id"]) and bool(room["players"][sender].get("ready", false))):
		_rpc_room_error.rpc_id(sender, "Your character is locked after Ready or during the countdown.")
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
	if sender == int(room["host_id"]) or bool(member.get("ready", false)) or (float(room.get("start_countdown", -1.0)) >= 0.0 and not bool(room.get("bot_wait", false))): return
	member["ready"] = true
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
	var room: Dictionary = rooms[code]
	if int(room["host_id"]) != sender or bool(room.get("started", false)): return
	if float(room.get("start_countdown", -1.0)) >= 0.0 and not bool(room.get("bot_wait", false)): return
	if Rules.human_ids(room).size() < 5 or Rules.human_ids(room).size() > MAX_PLAYERS_PER_ROOM or not _all_ready(room): return
	_fill_companions(room)
	room["bot_wait"] = false
	room["start_countdown"] = LOBBY_WAIT_SECONDS
	_send_room_state(code)


@rpc("any_peer", "call_remote", "reliable")
func request_set_player_name(player_name: String) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender): return
	var code: String = peer_room_codes[sender]
	var room: Dictionary = rooms[code]
	if bool(room.get("started", false)) or (float(room.get("start_countdown", -1.0)) >= 0.0 and not bool(room.get("bot_wait", false))): return
	room["players"][sender]["name"] = _clean_player_name(player_name)
	_send_room_state(code)


@rpc("any_peer", "call_remote", "reliable")
func request_leave_room() -> void:
	if multiplayer.is_server():
		_remove_player(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "unreliable_ordered")
func request_player_input(direction: Vector2, sequence: int = 0) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peer_room_codes.has(sender):
		return
	var room: Dictionary = rooms.get(peer_room_codes[sender], {})
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "":
		return
	if not room["players"].has(sender) or not bool(room["players"][sender].get("alive", true)):
		return
	if direction.length() > 1.25:
		return
	if not direction.is_finite(): return
	var member: Dictionary = room["players"][sender]
	if sequence > 0 and sequence <= int(member.get("input_sequence", 0)): return
	member["input_sequence"] = sequence
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
	if Rules.winner(room) == "villagers":
		_finish_game(code, "villagers", _winner_message("villagers"))


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
	var gong := MapGeometry.gong_point(int(room["map_index"]))
	if position.distance_to(gong) > 78.0 or not MapGeometry.has_clear_path(int(room["map_index"]),position,gong,NenekPowers.locked_doors(room,Time.get_ticks_msec()/1000.0)):
		_rpc_room_error.rpc_id(sender, "Move close to the gong to call a meeting.")
		return
	room["meeting_state"] = "alarm"
	room["meeting_timer"] = ALARM_SECONDS
	room["votes"] = {}
	room["chat_messages"] = []
	room["meeting_caller"] = sender
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
		if _can_send_to(int(peer_id)):
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
	_broadcast_positions(str(context["code"]), true, {"caster_id": sender, "target_id": target_id})
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


@rpc("authority", "call_remote", "reliable")
func _rpc_elimination_reveal(details: Dictionary) -> void:
	elimination_revealed.emit(details)


@rpc("authority", "call_remote", "reliable")
func _rpc_matchmaking(waiting: int) -> void:
	matchmaking_changed.emit(waiting)
