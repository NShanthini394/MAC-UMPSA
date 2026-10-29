extends SceneTree
const Geometry = preload("res://scripts/map_geometry.gd")
var checks := 0
var failures: Array[String] = []
var apps: Array[Control] = []
func _initialize() -> void: run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition: failures.append(message); push_error(message)
func wait_for(predicate: Callable, message: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while not predicate.call():
		if Time.get_ticks_msec()>deadline: check(false,"Timed out: "+message); return false
		await process_frame
	return true
func new_app(slot: int) -> Control:
	var app: Control=load("res://scenes/main.tscn").instantiate()
	app.name="CodeOnly%d"%slot; root.add_child(app); apps.append(app)
	await process_frame; await process_frame
	app.network_manager.discovery_port=17821
	app.lan_host.discovery_port=17821
	app.lobby_player_name="Code player %d"%slot
	await app.build_menu()
	return app
func run() -> void:
	await validate()
	for app in apps: app.network_manager.leave_room()
	for app in apps: app.queue_free()
	await process_frame; await process_frame
	print("CODE-ONLY LAN CHECKS: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func validate() -> void:
	var host := await new_app(0)
	host.selected_map=1; host.network_manager.server_port=17820
	await host._open_create_room()
	host._host_lan_room()
	if not await wait_for(func()->bool:return not host.room_code.is_empty(),"host creates room"): return
	var code: String=host.room_code
	check(code.length()==5,"Host gets a five-character code")
	check(host.find_child("CreatedRoomAddress",true,false)==null,"Host invitation shares the code without an IP address")
	host._enter_waiting_room()
	await wait_for(func()->bool:return host.current_screen=="waiting_room","host lobby")
	for slot in range(1,5):
		var guest := await new_app(slot)
		# Deliberately stale endpoint: it must never control a code-only join.
		guest.network_manager.server_address="127.0.0.2"
		guest.network_manager.server_port=1
		guest.show_join_room()
		check(guest.find_child("ServerAddressEntry",true,false)==null,"Guest never needs an address field")
		var entry := guest.find_child("JoinCodeEntry",true,false) as LineEdit
		entry.text="BAD"; guest._join_room_with_code()
		check(not guest.network_manager.connection_pending,"Short code rejected before searching")
		entry.text="OOOOO"; guest._join_room_with_code()
		check(not guest.network_manager.connection_pending,"Invalid code characters rejected")
		if slot==1:
			entry.text="ZZZZZ"; guest._join_room_with_code()
			check(guest.network_manager.connection_pending and guest.find_child("JoinOnlineRoomButton",true,false).disabled,"Searching shows busy state")
			guest._cancel_join_room()
			await create_timer(0.55).timeout
			check(not guest.network_manager.connection_pending and guest.room_code.is_empty(),"Cancel stops lookup without joining later")
			guest.show_join_room()
			entry=guest.find_child("JoinCodeEntry",true,false) as LineEdit
			entry.text="ZZZZZ"; guest._join_room_with_code()
			if not await wait_for(func()->bool:return not guest.network_manager.connection_pending,"missing-room timeout",9.0): return
			check(guest.find_child("JoinRoomStatusLabel",true,false).text.contains("Room not found"),"Missing room has a useful same-Wi-Fi error")
			check(not guest.find_child("JoinOnlineRoomButton",true,false).disabled,"Failed lookup can be retried")
		entry.text=code.to_lower(); guest._join_room_with_code()
		if not await wait_for(func()->bool:return guest.current_screen=="waiting_room" and guest.room_code==code,"guest joins using only the code"): return
		check(guest.network_manager.server_port==17820,"Discovery supplies the actual game port")
	if not await wait_for(func()->bool:return apps.all(func(a:Control)->bool:return a.lobby_players.size()==5),"five synchronized code-only lobbies"): return
	check(true,"Five actual game clients join via one host code")
	for app in apps: app._on_lobby_primary_action()
	if not await wait_for(func()->bool:return apps.all(func(a:Control)->bool:return a.current_screen=="game" and is_instance_valid(a.player_body)),"countdown and five-player game",32.0): return
	for app in apps:
		var actors: Array=app.game_world.get_children().filter(func(node:Node)->bool:return node is CharacterBody2D)
		check(actors.size()==5,"Code-only client sees all five game actors")
	var service: Node=host.lan_host.service
	var room: Dictionary=service.rooms[code]
	var peer_id: int=host.network_manager.local_peer_id()
	var origin: Vector2=room["players"][peer_id]["position"]
	var direction := Vector2.ZERO
	for candidate in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
		if not Geometry.is_step_blocked(1,origin,origin+candidate*35,14): direction=candidate; break
	host.move_vector=direction
	if await wait_for(func()->bool:return room["players"][peer_id]["position"].distance_to(origin)>5,"live movement after code-only join",2.0): check(true,"Code discovery hands off to normal authoritative gameplay")
	host._stop_move()
	var late := await new_app(5)
	late.show_join_room()
	late.find_child("JoinCodeEntry",true,false).text=code
	late._join_room_with_code()
	if not await wait_for(func()->bool:return late.find_child("JoinRoomStatusLabel",true,false).text.contains("Already Started"),"started-room discovery still reaches the authoritative server"): return
	check(late.room_code.is_empty(),"A discovered room still enforces the already-started rule")
	check(not late.find_child("JoinOnlineRoomButton",true,false).disabled,"Started-room rejection leaves the join screen usable")
	host.lan_host.stop()
	if await wait_for(func()->bool:return apps.all(func(a:Control)->bool:return a.current_screen=="menu" and a.room_code.is_empty()),"host-loss recovery"):
		check(true,"Closing the host returns connected players cleanly to the menu")
