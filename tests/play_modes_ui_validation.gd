extends SceneTree
var app:Control
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func settle()->void:
	await process_frame;await process_frame;await process_frame
func wait_for(predicate:Callable)->bool:
	var deadline:=Time.get_ticks_msec()+10000
	while not predicate.call():
		if Time.get_ticks_msec()>deadline:check(false,"UI timed out: "+app.current_screen);return false
		await process_frame
	return true
func tap(node_name:String)->void:
	var button:Control=app.find_child(node_name,true,false)
	if button==null:check(false,"Missing "+node_name);return
	var point:=button.get_global_rect().get_center()
	var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=true;root.push_input(event,true);await process_frame
	event=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=false;root.push_input(event,true);await settle()
func capture(name_:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/modes_"+name_+".png")
func run()->void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await settle()
	app.online_server_url=""
	await validate()
	app.network_manager.leave_room();app.lan_host.stop();app.queue_free();await settle()
	print("PLAY MODES UI: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
func validate()->void:
	for screen_size in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(1920,1200)]:
		root.size=screen_size;await settle();await app.build_menu();await settle()
		check(app.find_child("CreateRoomArtworkButton",true,false)==null and app.find_child("OfflinePracticeButton",true,false)==null,"Centre menu removes duplicate modes")
		await capture("main_%dx%d"%[screen_size.x,screen_size.y])
		await tap("StartGameButton")
		check(app.current_screen=="play_modes","Start Game opens three modes with touch")
		await capture("choices_%dx%d"%[screen_size.x,screen_size.y])
		await tap("FriendsModeButton")
		check(app.current_screen=="friends_menu","Friends opens Create and Join")
		await capture("friends_%dx%d"%[screen_size.x,screen_size.y])
		await tap("JoinRoomButton")
		check(app.find_child("JoinRoomCodeOverlay",true,false)!=null,"Friends Join opens code form")
		app._cancel_join_room();await settle()
		await tap("CreateRoomButton")
		check(app.current_screen=="map_select" and app.map_selection_mode=="room_host","Friends Create opens map selection")
		app.navigate_back();await settle();await tap("SoloModeButton")
		check(app.current_screen=="map_select" and app.map_selection_mode=="solo","Solo opens map selection directly")
	await app.build_menu();app.page_controls.show_settings();await settle()
	check(app.find_child("SettingsAccountInformation",true,false)!=null,"Account actions live under Settings Account")
	await capture("settings")
	app.page_controls.close_dialog()
	await app.build_play_modes();await tap("QuickMatchButton")
	check(app.current_screen=="matchmaking" and app.play_mode=="quick","Quick Match opens online search")
	app._leave_matchmaking();await settle()
	await app._choose_solo_mode();await tap("MapSelect_0")
	if not await wait_for(func():return app.current_screen=="waiting_room"):return
	check(app.play_mode=="solo" and not app.internet_mode,"Solo uses local server without internet")
	check(app.find_child("LobbyModeLabel",true,false).text=="SOLO VS BOTS","Solo lobby is labelled clearly")
	check(app.find_child("RoomCodeButton",true,false)==null,"Solo does not show a join code")
	await capture("solo_lobby")
	await tap("LobbyChooseCharacterButton")
	check(app.current_screen=="character_select","Solo permits character choice")
	await app.build_waiting_room()
	await tap("LobbyActionButton")
	if not await wait_for(func():return app.network_manager.lobby_locked):return
	check(app.lobby_players.size()==10,"Solo shows one human and nine bots after locking")
	var server:Node=app.lan_host.service
	var room:Dictionary=server.rooms[app.room_code]
	check(room.start_countdown>4,"Solo gets five-second preparation countdown")
	server._tick_lobby_countdown(app.room_code,5)
	if not await wait_for(func():return app.current_screen=="role_reveal"):return
	check(not app.player_is_impostor,"Solo role reveal makes human a Villager")
	if not await wait_for(func():return app.current_screen=="game"):return
	check(app.lobby_players.size()==10 and app.game_world!=null,"Solo enters real gameplay with ten participants")
	await capture("solo_game")
	app._return_to_menu_cleanly();await settle()
	check(app.current_screen=="menu" and app.lan_host.service==null,"Leaving Solo releases local server")
