extends SceneTree
const Net=preload("res://scripts/network_manager.gd")
var apps:Array[Control]=[]
var server:Node
var branch:Node
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func wait_for(predicate:Callable)->bool:
	var deadline:=Time.get_ticks_msec()+7000
	while not predicate.call():
		if Time.get_ticks_msec()>deadline:check(false,"Online UI timeout");return false
		await process_frame
	return true
func run()->void:
	await validate()
	for app in apps:app.network_manager.leave_room();app.queue_free()
	if server:server.set_process(false);server.multiplayer.multiplayer_peer.close()
	if branch:branch.queue_free()
	await process_frame
	print("PLAY MODES ONLINE UI: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
func validate()->void:
	branch=Node.new();branch.name="ModesServer";root.add_child(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(),branch.get_path())
	server=Net.new();server.name="NetworkManager";branch.add_child(server)
	check(server.start_server(17996,true,false)==OK,"Local WSS-equivalent transport starts")
	for index in 2:
		var app:Control=load("res://scenes/main.tscn").instantiate();app.name="ModeApp%d"%index;root.add_child(app);apps.append(app)
		app.online_server_url="ws://127.0.0.1:17996";app.lobby_player_name="Human %d"%index
		await app.build_menu()
	var host:Control=apps[0];var guest:Control=apps[1]
	host.selected_map=1;await host._open_create_room();host._host_selected_room()
	if not await wait_for(func():return not host.room_code.is_empty()):return
	var code:String=host.room_code
	host._enter_waiting_room();guest.show_join_room()
	guest.find_child("JoinCodeEntry",true,false).text=code;guest._join_room_with_code()
	if not await wait_for(func():return guest.current_screen=="waiting_room" and host.lobby_players.size()==2):return
	check(host.play_mode=="friends" and guest.play_mode=="friends","Private mode is synchronized")
	check(host.find_child("LobbyActionButton",true,false).disabled,"Private host initially waits for guest Ready")
	guest._on_lobby_primary_action()
	if not await wait_for(func():return not host.find_child("LobbyActionButton",true,false).disabled):return
	check(host.find_child("LobbyActionButton",true,false).text=="START WITH BOTS","Two ready humans can start through UI")
	host._on_lobby_primary_action()
	if not await wait_for(func():return guest.network_manager.lobby_locked):return
	await process_frame
	check(guest.find_child("LobbyChooseCharacterButton",true,false).disabled,"Start countdown locks guest controls")
	check(host.find_child("LobbyStatusLabel",true,false).text.begins_with("STARTING"),"Private countdown uses the start phase")
	guest._leave_room_to_menu();host._leave_room_to_menu();await create_timer(0.1).timeout
	host._find_public_match();guest._find_public_match()
	if not await wait_for(func():return host.current_screen=="waiting_room" and guest.current_screen=="waiting_room" and host.room_code==guest.room_code):return
	code=host.room_code
	check(host.play_mode=="quick" and guest.play_mode=="quick","Quick Match merges users into one public lobby")
	check(host.find_child("LobbyActionButton",true,false).text=="ARE YOU READY?","Public host uses Ready, not manual Start")
	check(host.find_child("LobbyModeLabel",true,false).text=="QUICK MATCH","Public lobby mode label is clear")
	check(not host.find_child("LobbyChooseCharacterButton",true,false).disabled,"Search phase keeps character choice available")
	check(host.find_child("LobbyNameEntry",true,false).editable,"Search phase permits renaming")
	check(host.find_child("LobbyCountdownLabel",true,false).text.contains(":"),"Search shows a minute/second timer")
	server._tick_lobby_countdown(code,60)
	if not await wait_for(func():return guest.network_manager.lobby_locked):return
	await process_frame
	check(guest.lobby_players.size()==10,"Public deadline fills eight bots in UI")
	check(not guest.find_child("LobbyCountdownLabel",true,false).text.contains(":"),"Public start countdown differs from search timer")
	server._tick_lobby_countdown(code,5)
	if not await wait_for(func():return host.current_screen=="role_reveal" and guest.current_screen=="role_reveal"):return
	check(true,"Both devices enter their role reveal together")
