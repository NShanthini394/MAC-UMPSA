extends SceneTree
const Network = preload("res://scripts/network_manager.gd")
const Rules = preload("res://scripts/match_rules.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var apps: Array[Control] = []
var server: Node
var branch: Node
var checks := 0
var failures: Array[String] = []
var code := ""
var room: Dictionary
var endpoint := "ws://127.0.0.1:17890"

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func wait_for(test: Callable, message: String, seconds: float = 18) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while not test.call():
		if Time.get_ticks_msec()>deadline: check(false,"Timed out: "+message); return false
		await process_frame
	return true
func new_app(slot: int) -> Control:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	app.name = "MeetingClient%d" % slot; root.add_child(app); apps.append(app)
	app.online_server_url = endpoint; app.lobby_player_name = "Human %d" % slot
	await app.build_menu(); app._menu_action(0)
	return app
func run() -> void:
	await validate()
	for app in apps: app.network_manager.leave_room()
	for app in apps: app.queue_free()
	if server: server.multiplayer.multiplayer_peer.close()
	if branch: branch.queue_free()
	await process_frame
	print("MEETINGS / MATCHMAKING: %d checks; %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func phase(state: String) -> bool:
	return await wait_for(func() -> bool: return str(room.get("meeting_state","")) == state and apps.all(func(a: Control) -> bool: return a.network_meeting_state == state),state)
func fast_finish_phase() -> void:
	room["meeting_timer"] = 0.01
	await create_timer(0.1).timeout
func vote_for(target: int) -> void:
	for app in apps:
		var id: int = app.network_manager.local_peer_id()
		if id in Rules.human_ids(room,true): app.network_manager.cast_vote(-1 if id==target else target)
	await create_timer(0.15).timeout
func call_gong(app: Control) -> bool:
	var id: int = app.network_manager.local_peer_id()
	room["players"][id]["position"] = Geometry.gong_point(room["map_index"])
	server._broadcast_positions(code,true)
	app.network_manager.call_meeting()
	return await phase("alarm")
func quick_vote(app: Control, target: int) -> bool:
	if not await call_gong(app): return false
	await fast_finish_phase()
	if not await phase("discussion"): return false
	await fast_finish_phase()
	if not await phase("voting"): return false
	await vote_for(target)
	await fast_finish_phase()
	return await phase("reveal")
func validate() -> void:
	branch=Node.new();root.add_child(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(),branch.get_path())
	server=Network.new();server.name="NetworkManager";branch.add_child(server)
	server.force_host_nenek_for_testing = true
	check(server.start_server(17890,true)==OK,"WebSocket server starts")
	for slot in 4: await new_app(slot)
	if not await wait_for(func() -> bool: return server.public_queue.size()==4,"four queued people"): return
	await create_timer(3.3).timeout
	check(server.rooms.is_empty(),"Four real people stay waiting; bots cannot start the match")
	check(apps[0].current_screen=="matchmaking" and apps[0].find_child("KeepWaitingButton",true,false)!=null,"Play shows Keep Waiting")
	apps[0]._keep_waiting();await create_timer(0.1).timeout
	check(server.public_queue.size()==4,"Keep Waiting never duplicates a queued player")
	for slot in range(4,6): await new_app(slot)
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.current_screen=="waiting_room"),"six strangers matched"): return
	code=apps[0].room_code;room=server.rooms[code]
	check(apps.all(func(a: Control) -> bool: return a.room_code==code),"Searching humans share one room")
	check(Rules.human_ids(room).size()==6 and server.public_queue.is_empty(),"Queue is drained exactly once")
	var departing: Control=apps.pop_back()
	departing.network_manager.leave_room();departing.queue_free()
	if not await wait_for(func() -> bool: return Rules.human_ids(room).size()==5,"public lobby departure"): return
	await new_app(6)
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.current_screen=="waiting_room" and a.room_code==code and a.lobby_players.size()==6),"replacement joins existing public lobby"): return
	check(Rules.human_ids(room).size()==6 and server.public_queue.is_empty(),"A searching person fills an existing public lobby before Start")
	var host: Control
	for app in apps:
		if app.room_is_host: host=app
		else: app._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return server._all_ready(room),"guests ready"): return
	host._on_lobby_primary_action()
	if not await wait_for(func() -> bool: return room["players"].size()==10,"four companions added"): return
	check(Rules.human_ids(room).size()==6,"Companions never count toward the minimum")
	check(server._room_members(room).all(func(m: Dictionary) -> bool: return not m.has("is_bot") and not m.has("role") and not m.has("bot_path")),"Public roster contains no role or bot internals")
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.current_screen=="game" and is_instance_valid(a.player_body)),"gameplay",40): return
	check(room["players"].values().filter(func(m: Dictionary) -> bool: return m["role"]=="nenek_kebayan").size()==2,"Exactly two Nenek roles")
	check(room["impostor_ids"].all(func(id: int) -> bool: return id in Rules.human_ids(room)),"Both Nenek are humans")
	check(host.player_is_impostor,"Nenek can call the gong")
	check(apps.all(func(a: Control) -> bool: return a.game_world.find_child("MeetingGongMarker",true,false)==null),"Yellow circle is absent")
	check(apps.all(func(a: Control) -> bool: return a.lobby_players.size()==10),"Every client sees ten characters")
	var bots: Array=room["players"].values().filter(func(m: Dictionary) -> bool: return m.get("is_bot",false))
	var origins: Array=bots.map(func(m: Dictionary) -> Vector2: return m["position"])
	await create_timer(4.0).timeout
	check(bots.any(func(m: Dictionary) -> bool: return m["position"].distance_to(origins[bots.find(m)])>2),"Companions walk on server routes")
	check(bots.all(func(m: Dictionary) -> bool: return not Geometry.is_position_blocked(room["map_index"],m["position"],14)),"Companions stay off walls and roofs")
	if not await call_gong(host): return
	check(apps.all(func(a: Control) -> bool: return a.find_child("MeetingCinematic",true,false)!=null),"All devices receive alarm animation")
	check(apps.all(func(a: Control) -> bool: return a.audio_director.gong_player.playing and a.audio_director.gong_player.stream.resource_path.ends_with("gong.mp3")),"Supplied gong audio reaches every device")
	if not await phase("discussion"): return
	check(room["meeting_timer"]>19 and room["meeting_timer"]<=20,"Discussion begins at twenty seconds")
	host.network_manager.send_chat("Who was near the kitchen?")
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.network_chat_lines.size()==1),"shared chat"): return
	var discussion_at:=Time.get_ticks_msec()
	if not await wait_for(func() -> bool: return room["meeting_state"]=="voting","natural discussion timer",24): return
	check(Time.get_ticks_msec()-discussion_at>=19000,"Discussion does not end early")
	if not await phase("voting"): return
	var innocent: int=Rules.human_ids(room).filter(func(id: int) -> bool: return room["players"][id]["role"]=="villager")[0]
	await vote_for(innocent)
	check(room["meeting_state"]=="voting","All submitted votes still wait for the ten-second deadline")
	if not await wait_for(func() -> bool: return room["meeting_state"]=="reveal","natural voting timer",12): return
	if not await phase("reveal"): return
	check(not room["last_reveal"]["was_nenek"] and room["last_reveal"]["remaining"]==2,"Wrong accusation reveals an innocent and keeps two Nenek")
	await fast_finish_phase(); if not await phase(""): return
	var innocent_app: Control
	for app in apps:
		if app.network_manager.local_peer_id()==innocent: innocent_app=app
	check(not innocent_app.can_local_act(),"Voted-out human becomes a spectator")
	check(not innocent_app.player_body.get_node("CharacterActor").visible,"Departed character also disappears from the spectator's own map")
	if not await quick_vote(host,int(room["impostor_ids"][0])): return
	check(room["last_reveal"]["was_nenek"] and room["last_reveal"]["remaining"]==1,"First correct reveal says one Nenek remains")
	check(not room.get("finished",false),"First Nenek never ends the match")
	check(innocent_app.find_child("MeetingCinematic",true,false)!=null,"Spectators also see later reveals")
	await fast_finish_phase(); if not await phase(""): return
	var caller: Control
	for app in apps:
		if app.can_local_act(): caller=app; break
	room["completed_tasks"]=[1,1,1,1,1,1,1,1];server._broadcast_task_state(code)
	check(Rules.winner(room).is_empty(),"Eight tasks alone cannot win")
	if not await quick_vote(caller,int(room["impostor_ids"][1])): return
	check(room["last_reveal"]["remaining"]==0,"Second reveal reports both found")
	check(not room.get("finished",false),"Final result waits for the elimination animation")
	await fast_finish_phase()
	if not await wait_for(func() -> bool: return apps.all(func(a: Control) -> bool: return a.current_screen=="result"),"shared village victory"): return
	check(Rules.winner(room)=="villagers","Both Nenek and all tasks are required for victory")
