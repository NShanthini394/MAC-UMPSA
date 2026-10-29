extends SceneTree
const Discovery = preload("res://scripts/lan_discovery.gd")
var checks := 0
var failures: Array[String] = []
var found: Array = []
var errors: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition: failures.append(message); push_error(message)
func wait_for(predicate: Callable, seconds: float = 8.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while not predicate.call():
		if Time.get_ticks_msec()>deadline: check(false,"Timed out waiting for UDP discovery"); return false
		await process_frame
	return true
func run() -> void:
	check(Discovery.normalize_code(" abcde ")=="ABCDE","Code normalization accepts case and surrounding whitespace")
	for code in ["AB","OOOOO","00000","AAAAAA","A$CDE"]: check(Discovery.normalize_code(code)=="","Malformed codes are rejected")
	var listener := Discovery.new(); root.add_child(listener)
	check(listener.listen(17831,func(code: String)->Dictionary:return {"port":17830} if code=="ABCDE" else {})==OK,"Host opens a discovery listener")
	var seeker := Discovery.new(); root.add_child(seeker)
	for packet in ["{","[]","false",'{"p":[],"v":1}',JSON.stringify({"p":Discovery.PROTOCOL,"v":{},"type":"room","code":"ABCDE","nonce":"a"}),JSON.stringify({"p":Discovery.PROTOCOL,"v":1,"type":[],"code":"ABCDE","nonce":"a"})]:
		check(seeker.call("_decode",packet.to_utf8_buffer()).is_empty(),"Malformed or unrelated UDP payload is ignored without script errors")
	check(seeker.call("_decode",("x".repeat(513)).to_utf8_buffer()).is_empty(),"Oversized payload is discarded")
	seeker.host_found.connect(func(address: String, port: int):found.append({"address":address,"port":port}))
	seeker.search_failed.connect(func(message: String):errors.append(message))
	check(seeker.search("abcde",17831)==OK,"Lookup starts without a host address")
	if await wait_for(func()->bool:return not found.is_empty()):
		check(found[0]["port"]==17830 and str(found[0]["address"]).is_valid_ip_address(),"Lookup returns the replying host and real game port")
		check(not seeker.searching and seeker.get("_queries").is_empty(),"Successful search releases all client sockets")
	found.clear(); errors.clear()
	seeker.probe_addresses=PackedStringArray(["255.255.255.255"])
	seeker.search("ABCDE",17831)
	if await wait_for(func()->bool:return not found.is_empty() or not errors.is_empty()):
		check(not found.is_empty(),"Actual LAN broadcast discovers the host with loopback probes disabled")
		if not found.is_empty(): check(not str(found[0]["address"]).begins_with("127."),"Broadcast lookup obtains an interface address")
	found.clear(); errors.clear()
	seeker.probe_addresses=PackedStringArray(["127.0.0.1"])
	seeker.search("ZZZZZ",17831)
	seeker.set("_deadline",Time.get_ticks_msec()+200)
	await wait_for(func()->bool:return not errors.is_empty())
	check(found.is_empty() and errors[0].contains("Room not found"),"Wrong room code times out instead of selecting another room")
	errors.clear()
	seeker.search("ABCDE",17831); seeker.cancel_search()
	await create_timer(0.55).timeout
	check(found.is_empty() and errors.is_empty() and not seeker.searching,"Cancellation ignores late host replies")
	# Reject unsolicited/malformed responses before selecting any endpoint.
	seeker.search("ABCDE",17832)
	var nonce: String=seeker.get("_nonce")
	var valid := {"type":"room","code":"ABCDE","nonce":nonce,"host":"aaaaaaaaaaaaaaaaaaaaaaaa","port":17830}
	for alteration in [{"nonce":"bbbbbbbbbbbbbbbbbbbbbbbb"},{"code":"QWERT"},{"type":"find"},{"host":"bad"},{"port":0},{"port":70000},{"port":17830.5},{"port":"17830"}]:
		var bad := valid.duplicate(); bad.merge(alteration,true)
		seeker.call("_accept_response",bad,"127.0.0.1",17832,Time.get_ticks_msec())
		check(seeker.get("_matches").is_empty(),"Invalid host response is ignored")
	seeker.call("_accept_response",valid,"not-an-address",17832,Time.get_ticks_msec())
	check(seeker.get("_matches").is_empty(),"Response cannot supply an arbitrary destination")
	seeker.call("_accept_response",valid,"127.0.0.1",17833,Time.get_ticks_msec())
	check(seeker.get("_matches").is_empty(),"Response must originate at the discovery service port")
	seeker.call("_accept_response",valid,"127.0.0.1",17832,Time.get_ticks_msec())
	seeker.call("_accept_response",valid,"127.0.0.2",17832,Time.get_ticks_msec())
	check(seeker.get("_matches").size()==1,"Multiple interfaces for one host are deduplicated")
	var second := valid.duplicate(); second["host"]="bbbbbbbbbbbbbbbbbbbbbbbb"
	seeker.call("_accept_response",second,"127.0.0.2",17832,Time.get_ticks_msec())
	seeker.set("_settle_at",Time.get_ticks_msec())
	seeker.call("_process",0.0)
	check(not errors.is_empty() and errors[0].contains("More than one host"),"Code collisions are reported rather than joining a random host")
	found.clear(); errors.clear()
	seeker.search("ABCDE",17831)
	await wait_for(func()->bool:return not found.is_empty())
	check(errors.is_empty(),"A fresh retry works after cancellation and lookup errors")
	listener.stop_listener()
	found.clear(); seeker.search("ABCDE",17831); seeker.set("_deadline",Time.get_ticks_msec()+200)
	await wait_for(func()->bool:return not errors.is_empty())
	check(found.is_empty(),"Stopped host no longer advertises a room")
	listener.queue_free(); seeker.queue_free(); await process_frame
	print("LAN DISCOVERY CHECKS: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
