extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
const Board = preload("res://scripts/task_minigame.gd")
const Actions = preload("res://tests/village_task_actions.gd")
const Navigation = preload("res://scripts/map_navigation.gd")
var checks := 0
var failures: Array[String] = []
var actions := 0

func _initialize() -> void: run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition: failures.append(message); push_error(message)
func run() -> void:
	validate_placements()
	for touch in [false,true]:
		for index in Data.COMMON_TASKS.size(): await validate_board(index,touch)
	await validate_delayed_touch()
	await validate_app()
	print("VILLAGE TASK CHECKS: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func validate_placements() -> void:
	for map_index in 3:
		var plan := Geometry.floor_plan(map_index)
		var sections: Array = plan.layout["task_sections"]
		var used := {}
		check(Data.TASKS[Data.MAPS[map_index]["name"]]==Data.COMMON_TASKS,"Same twelve chores on map %d"%map_index)
		for index in Data.COMMON_TASKS.size():
			var point: Vector2 = Geometry.task_points(map_index)[index]
			check(not Geometry.is_position_blocked(map_index,point,14),"Task station has player clearance: map %d task %d"%[map_index,index])
			check(Geometry.point_in_area(map_index,sections[index],point),"Station lies in its assigned room or garden")
			check(Navigation.path(map_index,Geometry.spawn_point(map_index),point).size()>=2,"Task is reachable from spawn: map %d task %d"%[map_index,index])
			check(not used.has(point),"Task stations have distinct locations")
			used[point]=true
		check(plan.layout["sections"][sections[0]]["name"]=="Kitchen","Cooking is in the kitchen")
		check(sections[0]!=sections[1],"Cooking and lighting wood are separate stations")
		check(Data.COMMON_TASKS[0]["minigame"]!=Data.COMMON_TASKS[1]["minigame"],"Cooking and lighting wood are separate interactions")

func validate_board(index: int, touch: bool) -> void:
	var board := Board.new()
	board.size=Vector2(792,382)
	root.add_child(board)
	board.configure(Data.COMMON_TASKS[index],0,Data.COMMON_TASK_STEPS[index])
	board.step_completed.connect(func(): actions+=1)
	for step in Data.COMMON_TASK_STEPS[index]:
		board.set_progress(step)
		var before := actions
		Actions.tap(board,Vector2(750,320),touch)
		check(actions==before,"Wrong location cannot complete %s stage %d"%[board.task_kind,step])
		board.set_input_enabled(false)
		Actions.complete_step(board,touch)
		check(actions==before,"Disabled board does not accept input")
		board.set_input_enabled(true)
		if board.task_kind=="rice" and step==2:
			board.set("_heat",0.1); Actions.tap(board,Vector2(610,290),touch)
			check(actions==before,"Uncooked rice does not pass the timing check")
		Actions.complete_step(board,touch)
		check(actions==before+1,"Actual %s input completes %s stage %d"%["touch" if touch else "mouse",board.task_kind,step])
		Actions.complete_step(board,touch)
		check(actions==before+1,"Pending server acknowledgement prevents duplicate steps")
	board.set_progress(board.required_progress)
	var before := actions
	Actions.complete_step(board,touch)
	check(actions==before,"Completed task cannot gain extra progress")
	board.queue_free()
	await process_frame

func validate_app() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	app.set_process(false)
	app.selected_character="Badang"
	app.player_is_impostor=false
	for map_index in 3:
		app.selected_map=map_index
		app.completed_tasks=[0,0,0,0,0,0,0,0,0,0,0,0] as Array[int]
		app.task_progress=[0,0,0,0,0,0,0,0,0,0,0,0] as Array[int]
		app.player_position=Geometry.spawn_point(map_index)
		await app.build_game()
		app.player_body.set_physics_process(false)
		app.toggle_village_tasks()
		check(app.find_child("VillageTaskScroll",true,false).visible,"Expanded task list is scrollable")
		app.toggle_village_tasks()
		check(not app.find_child("VillageTaskScroll",true,false).visible,"Collapsed task list hides all twelve rows")
		app.show_map_overlay()
		var view := app.find_child("MapOverlay",true,false) as Control
		check(view.get("_buttons").size()==Data.COMMON_TASKS.size(),"Map lists all twelve tasks")
		check(view != null and view.get_parent()==app.game_hud,"Parchment map opens above gameplay HUD")
		var canvas := view.find_child("FloorPlanCanvas",true,false) as Control
		check(canvas != null,"Map is an actual schematic rather than the artwork preview")
		var marker: Vector2 = canvas.call("world_to_screen",app.player_position)
		check(Rect2(Vector2.ZERO,canvas.size).has_point(marker),"Player marker is inside the floor plan")
		view.call("_tab",true); view.call("_choose",0)
		check(view.get("selected")==0,"Tasks tab selects an actual map task")
		canvas.call("change_zoom",1.2); check(canvas.get("zoom")>1,"Map supports zoom controls")
		canvas.call("reset_view"); check(canvas.get("zoom")==1.0,"Map fit reset works")
		view.queue_free(); await process_frame
		for index in Data.COMMON_TASKS.size():
			app.player_position=Geometry.task_points(map_index)[index]
			app.player_body.position=app.player_position
			var station: Node = app.game_world.get_node("TaskMarker_%d"%index)
			if index%2==0:
				var click := InputEventMouseButton.new()
				click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true
				if map_index==0 and index==0:
					await physics_frame
					await process_frame
					click.position=station.get_global_transform_with_canvas()*Vector2(0,-15)
					root.push_input(click,true)
					await physics_frame
					await process_frame
				else: station.call("_on_input_event",root,click,0)
			else:
				var touch := InputEventScreenTouch.new()
				touch.pressed=true
				station.call("_on_input_event",root,touch,0)
			check(app.task_overlay_index==index,"Click or touch opens the corresponding station")
			check(is_instance_valid(app.task_minigame),"Task opens at its relevant physical station")
			if map_index==1 and index==3:
				var cloth_board: Control = app.task_minigame
				Actions.press(cloth_board,cloth_board._source(),true)
				app._on_network_task_state_changed(app.completed_tasks.duplicate(),app.task_progress.duplicate())
				check(cloth_board.get("_dragging"),"Unrelated shared progress does not interrupt a cloth drag")
				check(cloth_board.get("_touch_id")==0,"Shared updates preserve active touch ownership")
				Actions.release(cloth_board,cloth_board._source(),true)
			for step in Data.COMMON_TASK_STEPS[index]:
				var board: Control = app.task_minigame
				if not is_instance_valid(board): check(false,"Task closed before completing all stages"); break
				Actions.complete_step(board,true)
			check(app.completed_tasks[index]==1,"Actual app marks task %d complete on map %d"%[index,map_index])
			await process_frame
		check(app.current_screen=="result","Completing all twelve tasks wins offline on map %d"%map_index)
	app._start_local_practice_lobby()
	await process_frame; await process_frame
	app._process(0)
	var button := app.find_child("LobbyActionButton",true,false) as Button
	var note := app.find_child("LobbyReadyWaitNote",true,false) as Label
	check(note != null and note.text.contains("5-second"),"Ready instruction is permanently visible once")
	check(note.position.y>=button.position.y+button.size.y,"Wait sentence sits below the Ready button")
	check(button.tooltip_text.contains("All guests"),"Host tooltip explains online readiness")
	app._on_lobby_primary_action()
	check(app.practice_start_countdown==5,"Countdown logic remains unchanged")
	app.queue_free(); await process_frame

func validate_delayed_touch() -> void:
	var board := Board.new()
	board.size=Vector2(792,382); root.add_child(board)
	board.configure(Data.COMMON_TASKS[2],0,5)
	board.step_completed.connect(func():actions+=1)
	for step in 5:
		var before := actions
		Actions.complete_step(board,true)
		check(actions==before+1,"Consecutive touch swipe works with delayed acknowledgement")
		check(board.get("_touch_id")==-1,"Finger release is recognized while waiting for the server")
		await process_frame
		board.set_progress(step+1)
	board.queue_free(); await process_frame
