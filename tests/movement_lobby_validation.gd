extends SceneTree
## Corner recovery, real physics/input, invisible blockers, and lobby timing.
const Geometry = preload("res://scripts/map_geometry.gd")
const Network = preload("res://scripts/network_manager.gd")
const Data = preload("res://scripts/game_data.gd")
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	validate_corner_geometry()
	validate_server_movement()
	validate_server_countdown()
	await validate_physics()
	await validate_app()
	print("MOVEMENT AND LOBBY CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func validate_corner_geometry() -> void:
	var origin := Vector2(628,330)
	var diagonal := Vector2(-1,1).normalized() * 250.0 / 60.0
	check(not Geometry.is_position_blocked(1, origin, 14), "Regression starts on valid family-room floor")
	check(Geometry.is_step_blocked(1, origin, origin + diagonal, 14), "Inside-corner diagonal needs a safe slide")
	check(not Geometry.is_step_blocked(1, origin, origin + Vector2(diagonal.x,0), 14) and not Geometry.is_step_blocked(1, origin, origin + Vector2(0,diagonal.y), 14), "Reproduces two individually valid axes with an invalid combined move")
	var point := origin
	for frame in 60:
		var next := Geometry.move_position(1, point, diagonal)
		check(not Geometry.is_position_blocked(1, next, 14) and not Geometry.is_step_blocked(1, point, next, 14), "Corner slide %d stays on clear floor" % frame)
		point = next
	var escaped := Geometry.move_position(1, point, Vector2.RIGHT * 4)
	check(escaped.distance_to(point) > 1, "Character can move away after pressing into the corner")
	var legacy := Vector2(625.0537,332.9463)
	var recovered := Geometry.recover_position(1, legacy)
	check(not Geometry.is_position_blocked(1, recovered, 14), "Previously stuck feet recover onto nearby valid floor")
	check(legacy.distance_to(recovered) <= 16 and Geometry.has_clear_path(1, legacy, recovered), "Recovery is local and does not cross a wall")
	check(Geometry.move_position(1, legacy, Vector2.RIGHT * 4).distance_to(legacy) > 1, "Old stuck position responds to new input")
	var video_corner := Vector2(582.1,180.1)
	check(Geometry.move_position(1, video_corner, Vector2.RIGHT * 4).x > video_corner.x + 3, "Family-room corner shown in the recording has a clear rightward escape")
	for map_index in 3:
		var plan := Geometry.floor_plan(map_index)
		for landmark in plan.layout["forbidden"]:
			var forbidden := plan.world_point(plan.layout["forbidden"][landmark])
			check(Geometry.is_position_blocked(map_index, Geometry.recover_position(map_index, forbidden), 14), "Recovery does not admit forbidden map %d / %s" % [map_index,landmark])


func validate_server_movement() -> void:
	var server := Network.new()
	root.add_child(server)
	server.set_process(false)
	var room := {"map_index":1,"started":true,"players":{2:{"id":2,"alive":true,"sleeping":false,"position":Vector2(628,330),"direction":Vector2(-1,1).normalized()}}}
	server.rooms["CHECK"] = room
	for frame in 30:
		server.call("_process",1.0/60.0)
		check(not Geometry.is_position_blocked(1,room["players"][2]["position"],14), "Server diagonal %d never enters the corner clearance" % frame)
	room["players"][2]["position"] = Vector2(625.0537,332.9463)
	room["players"][2]["direction"] = Vector2.RIGHT
	server.call("_process",1.0/60.0)
	check(not Geometry.is_position_blocked(1,room["players"][2]["position"],14), "Authoritative server recovers a stuck player")
	server.queue_free()


func ready_room(count: int) -> Dictionary:
	var room := {"map_index":1,"host_id":2,"started":false,"players":{}}
	for slot in count:
		room["players"][slot+2] = {"id":slot+2,"name":"Test %d"%slot,"character":Data.CHARACTERS[slot],"ready":true,"host":slot==0,"alive":true,"position":Vector2.ZERO}
	return room


func validate_server_countdown() -> void:
	var server := Network.new()
	root.add_child(server)
	server.set_process(false)
	for count in [5,10]:
		var room := ready_room(count)
		server.rooms["TIMER"] = room
		server.call("_tick_lobby_countdown","TIMER",0.0)
		check(room["start_countdown"]==15.0 and not room["started"], "%d-player room begins with a full 15 seconds"%count)
		server.call("_try_start_room","TIMER",true,2)
		check(not room["started"], "Host cannot bypass the countdown")
		server.call("_tick_lobby_countdown","TIMER",14.9)
		check(not room["started"], "Room stays in lobby before 15 seconds")
		server.call("_tick_lobby_countdown","TIMER",0.1)
		check(bool(room["started"]), "Room starts when the 15-second wait finishes")
	var room := ready_room(5)
	server.rooms["TIMER"] = room
	server.call("_tick_lobby_countdown","TIMER",0.0)
	room["players"][3]["ready"] = false
	server.call("_tick_lobby_countdown","TIMER",4.0)
	check(room["start_countdown"] < 0 and not room["started"], "Unready cancels the countdown")
	room["players"][3]["ready"] = true
	server.call("_tick_lobby_countdown","TIMER",0.0)
	check(room["start_countdown"]==15.0,"Everyone ready again restarts the full wait")
	room["players"].erase(6)
	server.call("_tick_lobby_countdown","TIMER",2.0)
	check(room["start_countdown"] < 0 and not room["started"], "Fewer than five players cancels the LAN countdown")
	server.queue_free()


func validate_physics() -> void:
	var world := Node2D.new()
	root.add_child(world)
	load("res://scripts/game_screen.gd").new().call("_add_map_collisions",world,1)
	var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
	player.map_index = 1
	world.add_child(player)
	player.configure("Mahsuri","Corner regression",true)
	player.position = Vector2(628,330)
	player.set_input_direction(Vector2(-1,1).normalized())
	for frame in 45:
		await physics_frame
		check(not Geometry.is_position_blocked(1,player.position,14), "Actual player physics stays clear at frame %d"%frame)
	var origin := player.position
	player.set_input_direction(Vector2.RIGHT)
	await create_timer(0.16).timeout
	check(player.position.distance_to(origin)>15,"Actual physics can leave the corner")
	player.position = Vector2(625.0537,332.9463)
	await create_timer(0.16).timeout
	check(not Geometry.is_position_blocked(1,player.position,14),"Actual physics recovers the legacy stuck position")
	player.set_input_direction(Vector2.ZERO)
	world.queue_free()
	await process_frame


func validate_app() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.set_process(false)
	app.selected_map = 1
	app.call("_start_local_practice_lobby")
	await process_frame
	await process_frame
	app.call("_process",0.0)
	var action := app.find_child("LobbyActionButton",true,false) as Button
	check(action != null and action.text == "ARE YOU READY?", "Waiting room asks ARE YOU READY?")
	app.call("_on_lobby_primary_action")
	app.call("_process",0.0)
	check(app.practice_start_countdown==15.0 and action.text.contains("00:15"), "Ready starts the visible offline 15-second countdown")
	app.call("_process",14.0)
	check(app.current_screen=="waiting_room" and app.practice_start_countdown==1.0,"Offline waits the full duration")
	app.call("_confirm_character_selection","Mahsuri",null)
	await process_frame
	await process_frame
	check(app.practice_start_countdown < 0 and not app.call("_local_player_is_ready"),"Changing characters cancels the old practice countdown")
	await app.call("build_waiting_room")
	app.call("_on_lobby_primary_action")
	app.call("_process",14.0)
	app.call("_process",1.0)
	check(app.current_screen=="role_reveal", "Offline leaves the waiting room at 15 seconds")
	# Wait for the real role reveal before exercising joystick input in gameplay.
	var deadline := Time.get_ticks_msec()+8000
	while app.current_screen != "game" or not is_instance_valid(app.player_body):
		if Time.get_ticks_msec()>deadline:
			check(false,"Role reveal completes")
			app.queue_free()
			return
		await process_frame
	for map_index in 3:
		app.selected_map = map_index
		app.player_position = Geometry.spawn_point(map_index)
		await app.call("build_game")
		var guide: Node = app.game_world.get_node("PathsAndEntrances")
		check(not bool(guide.get("debug_boundaries")), "Gameplay map %d hides blocker lines"%map_index)
		var origin: Vector2 = app.player_body.position
		var direction := Vector2.ZERO
		for candidate in [Vector2.RIGHT,Vector2.DOWN,Vector2.UP,Vector2.LEFT]:
			if not Geometry.is_step_blocked(map_index,origin,origin+candidate*35,14):
				direction = candidate
				break
		var pad := app.game_hud.get_node("VirtualJoystick") as Control
		var knob := pad.get_node("JoystickKnob") as Control
		var drag := InputEventScreenDrag.new()
		drag.position = pad.size*0.5 + direction*44
		app.call("_on_joystick_input",drag,pad,knob)
		app.set_process(true)
		await create_timer(0.14).timeout
		app.set_process(false)
		app.call("_stop_move")
		check(app.player_body.position.distance_to(origin)>10,"Actual joystick moves the character on map %d"%map_index)
		app.call("show_map_overlay")
		var overlay := app.find_child("MapOverlay",true,false)
		check(overlay != null,"Full-map overlay opens")
		if overlay != null:
			for child in overlay.get_children():
				if child.get_script()==load("res://scripts/map_paths_visual.gd"):
					check(not bool(child.get("debug_boundaries")),"Full map also hides blocker lines")
			overlay.queue_free()
		await process_frame
	app.queue_free()
	await process_frame
