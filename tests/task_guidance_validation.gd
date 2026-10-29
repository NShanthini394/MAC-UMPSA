extends SceneTree
const Geometry = preload("res://scripts/map_geometry.gd")
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


func put_player(app: Control, point: Vector2) -> void:
	app.player_position = point
	app.player_body.position = point
	app.player_body.set_physics_process(false)


func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.set_process(false)
	app.selected_character = "Bawang Merah"
	app.completed_tasks = [0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress = [0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map = map_index
		app.player_position = Geometry.spawn_point(map_index)
		await app.build_game()
		var hint: PanelContainer = app.game_hud.get_node("NearbyTaskHint")
		hint.set_process(false)
		check(hint.mouse_filter == Control.MOUSE_FILTER_IGNORE,"Task popup does not swallow game input")
		var points: Array = Geometry.task_points(map_index)
		for index in points.size():
			app.completed_tasks.fill(1)
			app.completed_tasks[index] = 0
			var probe: Vector2 = points[index]
			for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
				var candidate: Vector2 = points[index] + direction * 45
				if not Geometry.is_step_blocked(map_index,points[index],candidate,14):
					probe = candidate
					break
			put_player(app,probe)
			hint.call("refresh",0.0,true)
			check(hint.visible and hint.get("task_index")==index,"Nearby unfinished task appears: map %d / task %d"%[map_index,index])
			var name_label := hint.find_child("NearbyTaskName",true,false) as Label
			check(name_label.text == str(Data.TASKS[Data.MAPS[map_index]["name"]][index]["name"]),"Popup identifies the actual task")
			var instruction := hint.find_child("NearbyTaskInstruction",true,false) as Label
			check(instruction.text.contains("INTERACT"),"Task within reach explains how to start in English")
			var arrow := hint.find_child("TaskDirectionArrow",true,false) as TextureRect
			if probe.distance_to(points[index])>4:
				check(arrow.visible and absf(angle_difference(arrow.rotation,(points[index]-probe).angle()+PI*0.5))<0.01,"Green arrow points toward the nearby task")
			app.last_notice = "Existing notice"
			app._process(0)
			check(app.last_notice=="Existing notice","Entering another map section does not announce its name")
			app.completed_tasks[index] = 1
			hint.call("refresh",0.0,true)
			check(not hint.visible,"Completed tasks no longer show a nearby popup")
	app.selected_map = 2
	app.player_position = Geometry.spawn_point(2)
	await app.build_game()
	var hint: PanelContainer = app.game_hud.get_node("NearbyTaskHint")
	hint.set_process(false)
	app.completed_tasks.fill(1)
	app.completed_tasks[0] = 0
	put_player(app,Vector2(843,410))
	hint.call("refresh",0.0,true)
	check(hint.visible and hint.get("task_index")==0,"Passing the kitchen reveals its nearby task")
	var path: PackedVector2Array = hint.get("waypoints")
	check(path.size()>2 and path[1].y<410,"Kitchen arrow first guides through its entrance")
	var clear := true
	for index in range(path.size()-1):
		if Geometry.is_step_blocked(2,path[index],path[index+1],14): clear = false
	check(clear,"Task guidance follows open walkways rather than crossing walls")
	put_player(app,Geometry.spawn_point(2))
	app.route_active = true
	app.route_target = Geometry.task_points(2)[0]
	hint.call("refresh",0.0,true)
	check(not hint.visible,"Distant tasks do not leave a permanent arrow over the header")
	put_player(app,Vector2(843,410))
	app.active_power_kind = "lock"
	app.active_power_area = 1
	app.active_power_until = Time.get_ticks_msec()/1000.0+10
	hint.call("refresh",0.0,true)
	check(not hint.visible,"A locked kitchen entrance does not advertise an inaccessible route")
	app.active_power_kind = ""
	app.player_sleeping = true
	hint.call("refresh",0.0,true)
	check(not hint.visible,"Sleeping players receive no actionable task prompt")
	app.player_sleeping = false
	app.task_overlay_index = 3
	hint.call("refresh",0.0,true)
	check(not hint.visible,"Task minigame hides the nearby prompt")
	app.task_overlay_index = -1
	app.show_map_overlay()
	hint.call("refresh",0.0,true)
	check(not hint.visible,"Full-map modal hides the nearby prompt")
	app.find_child("MapOverlay",true,false).queue_free()
	await process_frame
	app.show_settings()
	hint.call("refresh",0.0,true)
	check(not hint.visible,"Settings modal hides the nearby prompt")
	await process_frame
	var panel := app.page_controls.find_child("SettingsOverlay",true,false) as Control
	var leave := app.page_controls.find_child("SettingsLeaveGameButton",true,false) as Button
	check(absf(leave.get_global_rect().get_center().x-panel.get_global_rect().get_center().x)<0.1,"Leave Game is centered horizontally in Settings")
	check(panel.get_global_rect().encloses(leave.get_global_rect()),"Leave Game stays fully inside the settings panel")
	app.page_controls.close_dialog()
	hint.call("refresh",0.0,true)
	check(hint.visible,"Nearby guidance returns after closing settings")
	app.queue_free()
	await process_frame
	print("TASK GUIDANCE CHECKS: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
