extends Node
## Code lookup over LAN UDP. Clients use ephemeral reply ports, never IP scans.
signal host_found(address: String, port: int)
signal search_failed(message: String)
const PORT := 7001
const PROTOCOL := "kampung-legenda-lan"
const VERSION := 1
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const SEARCH_MS := 6000
const SETTLE_MS := 400
const RETRY_MS := 450
var searching := false
var probe_addresses := PackedStringArray(["255.255.255.255","127.0.0.1"])
var _listener: PacketPeerUDP
var _lookup := Callable()
var _identity := ""
var _listener_port := PORT
var _queries: Array[Dictionary] = []
var _search_port := PORT
var _code := ""
var _nonce := ""
var _deadline := 0
var _next_probe := 0
var _settle_at := 0
var _matches := {}
var _last_reply := {}

static func normalize_code(value: String) -> String:
	var code := value.strip_edges().to_upper()
	if code.length()!=5: return ""
	for character in code:
		if character not in ALPHABET: return ""
	return code

static func _valid_token(value: Variant) -> bool:
	if not value is String or value.length()!=24: return false
	for character in value:
		if character not in "0123456789abcdef": return false
	return true

func listen(port: int, room_lookup: Callable) -> Error:
	stop_listener()
	var socket := PacketPeerUDP.new()
	var result := socket.bind(port,"0.0.0.0",65536)
	if result!=OK: socket.close(); return result
	_listener=socket; _listener_port=port; _lookup=room_lookup
	_identity=Crypto.new().generate_random_bytes(12).hex_encode()
	return OK

func stop_listener() -> void:
	if _listener!=null: _listener.close()
	_listener=null; _lookup=Callable(); _identity=""; _last_reply.clear()

func search(code: String, port: int = PORT) -> Error:
	cancel_search()
	_code=normalize_code(code)
	if _code.is_empty() or port<1 or port>65535: return ERR_INVALID_PARAMETER
	var socket := PacketPeerUDP.new()
	var result := socket.bind(0,"0.0.0.0",65536)
	if result!=OK: socket.close(); return result
	socket.set_broadcast_enabled(true)
	_queries.append({"socket":socket,"targets":probe_addresses})
	# Bind each interface explicitly too, so a VPN or virtual adapter need not
	# become the only route used for Wi-Fi discovery. No subnet mask is assumed.
	for address in IP.get_local_addresses():
		if ":" in address or address.begins_with("127.") or address=="0.0.0.0" or not address.is_valid_ip_address(): continue
		var interface_socket := PacketPeerUDP.new()
		if interface_socket.bind(0,address,65536)!=OK: interface_socket.close(); continue
		interface_socket.set_broadcast_enabled(true)
		var broadcasts := PackedStringArray()
		for target in probe_addresses:
			if not target.begins_with("127."): broadcasts.append(target)
		_queries.append({"socket":interface_socket,"targets":broadcasts})
	_search_port=port; _nonce=Crypto.new().generate_random_bytes(12).hex_encode()
	_deadline=Time.get_ticks_msec()+SEARCH_MS; _next_probe=0; searching=true
	_send_queries()
	return OK

func cancel_search() -> void:
	searching=false
	for query in _queries: (query["socket"] as PacketPeerUDP).close()
	_queries.clear(); _matches.clear(); _code=""; _nonce=""; _settle_at=0; _deadline=0

func _send_queries() -> void:
	var packet := JSON.stringify({"p":PROTOCOL,"v":VERSION,"type":"find","code":_code,"nonce":_nonce}).to_utf8_buffer()
	for query in _queries:
		var socket: PacketPeerUDP=query["socket"]
		for target in query["targets"]:
			if socket.set_dest_address(target,_search_port)==OK: socket.put_packet(packet)
	_next_probe=Time.get_ticks_msec()+RETRY_MS

func _decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.size()>512 or bytes.is_empty(): return {}
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8())!=OK: return {}
	var data = parser.data
	if not data is Dictionary: return {}
	for key in ["p","type","code","nonce"]:
		if not data.get(key) is String: return {}
	if not (data.get("v") is int or data.get("v") is float): return {}
	if data.get("p")!=PROTOCOL or data.get("v")!=VERSION: return {}
	return data

func _poll_listener(now: int) -> void:
	if _listener==null or not _lookup.is_valid(): return
	for index in 64:
		if _listener.get_available_packet_count()==0: break
		var data := _decode(_listener.get_packet())
		var address := _listener.get_packet_ip()
		var reply_port := _listener.get_packet_port()
		if data.get("type")!="find" or not data.get("code") is String or normalize_code(data["code"])!=data["code"] or not _valid_token(data.get("nonce")): continue
		var key := address+":"+str(reply_port)
		if now-int(_last_reply.get(key,-1000))<150: continue
		var room: Dictionary=_lookup.call(str(data["code"]))
		if room.is_empty(): continue
		var game_port := int(room.get("port",0))
		if game_port<1 or game_port>65535: continue
		_last_reply[key]=now
		if _last_reply.size()>256: _last_reply.clear()
		var response := {"p":PROTOCOL,"v":VERSION,"type":"room","code":data["code"],"nonce":data["nonce"],"port":game_port,"host":_identity}
		if _listener.set_dest_address(address,reply_port)==OK: _listener.put_packet(JSON.stringify(response).to_utf8_buffer())

func _accept_response(data: Dictionary, address: String, source_port: int, now: int) -> void:
	if data.get("type")!="room" or data.get("code")!=_code or data.get("nonce")!=_nonce or source_port!=_search_port: return
	if not _valid_token(data.get("host")) or not address.is_valid_ip_address() or ":" in address: return
	var port_value = data.get("port")
	if not (port_value is int or port_value is float): return
	if not is_finite(float(port_value)) or float(port_value)<1 or float(port_value)>65535: return
	var game_port := int(port_value)
	if game_port<1 or game_port>65535 or float(game_port)!=float(port_value): return
	var identity: String=data["host"]
	# Multiple interfaces may report the same host; they are one room, not a
	# collision. A true collision between distinct hosts must not pick at random.
	if not _matches.has(identity) or address.begins_with("127."):
		_matches[identity]={"address":address,"port":game_port}
	if _settle_at==0: _settle_at=now+SETTLE_MS

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	_poll_listener(now)
	if not searching: return
	for query in _queries:
		var socket: PacketPeerUDP=query["socket"]
		for index in 64:
			if socket.get_available_packet_count()==0: break
			var data := _decode(socket.get_packet())
			_accept_response(data,socket.get_packet_ip(),socket.get_packet_port(),now)
	if _settle_at>0 and now>=_settle_at:
		var matches := _matches.values()
		cancel_search()
		if matches.size()==1: host_found.emit(matches[0]["address"],matches[0]["port"])
		else: search_failed.emit("More than one host has this code. Ask the host to create a new room.")
		return
	if now>=_deadline:
		cancel_search()
		search_failed.emit("Room not found on this Wi-Fi. Check the code and keep the host's game open. Guest networks may block nearby devices.")
	elif now>=_next_probe: _send_queries()

func _exit_tree() -> void:
	cancel_search(); stop_listener()
