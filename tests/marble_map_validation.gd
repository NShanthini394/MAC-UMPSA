extends SceneTree
const Shot = preload("res://scripts/marble_shot.gd")
const Board = preload("res://scripts/task_minigame.gd")
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
const Actions = preload("res://tests/village_task_actions.gd")
var checks := 0
var failures: Array[String] = []
var scored := 0

func _initialize() -> void: run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition: failures.append(message); push_error(message)
func run() -> void:
	validate_physics()
	await validate_board(false)
	await validate_board(true)
	await validate_map()
	print("MARBLE AND MAP CHECKS: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func validate_physics() -> void:
	var model := Shot.new()
	var good := model.pull_for_target(model.goal)
	check(model.prediction(good).distance_to(model.goal)<0.01,"Aim strength can land a marble at the circle center")
	check(model.inside_goal(model.goal+Vector2(66.5,0)),"Entire marble fits just inside the goal")
	check(not model.inside_goal(model.goal+Vector2(67.5,0)),"Partially overlapping marble receives no mark")
	check(not model.launch(Vector2(2,0)),"A tap or negligible pull cannot score")
	for angle in [-0.55,-0.2,0.0,0.2,0.55]:
		for power in [20.0,60.0,good.length(),100.0,130.0]:
			var pull: Vector2 = Vector2.from_angle(angle)*power
			var expected := model.prediction(pull)
			for fps in [30.0,60.0,144.0]:
				model.reset(); model.launch(pull)
				var status := "rolling"
				for frame in 600:
					status=model.advance(1.0/fps)
					if status!="rolling": break
				check(status!="rolling","Every shot eventually stops or leaves the board")
				if Shot.BOUNDS.has_point(expected):
					check(model.position.distance_to(expected)<0.02,"Aim preview matches actual landing at different frame rates")
					check((status=="inside")==model.inside_goal(expected),"Preview success agrees with the real score")
				else: check(status=="miss","Out-of-bounds shot never counts")
	model.reset(); model.launch(good)
	check(model.advance(10.0)=="inside","A long frame still settles a valid shot correctly")

func settle(board: Control) -> void:
	for frame in 300:
		if not board.get("_shot").rolling: break
		board._process(1.0/60.0)

func validate_board(touch: bool) -> void:
	var board := Board.new(); board.size=Vector2(792,382); root.add_child(board)
	board.configure(Data.COMMON_TASKS[5],0,4)
	board.set_process(false)
	board.step_completed.connect(func():scored+=1)
	var before := scored
	Actions.drag(board,board._source(),board._target(),touch)
	settle(board)
	check(scored==before,"Dragging and dropping a marble into the goal cannot complete this task")
	Actions.drag(board,board._source(),board._source()-Vector2(100,0),touch)
	settle(board)
	check(scored==before,"A shot passing through but stopping outside the goal receives no mark")
	check(board.input_enabled,"Missed shot can be retried")
	var pull: Vector2 = board.get("_shot").pull_for_target(board._target())
	Actions.drag(board,board._source(),board._source()-pull,touch)
	check(board.get("_shot").rolling and scored==before,"Releasing launches a rolling marble rather than scoring immediately")
	var initial: Vector2 = board.get("_shot").position
	board._process(0.2)
	check(board.get("_shot").position.distance_to(initial)>10,"Marble visibly travels after release")
	check(scored==before,"Score waits until the marble settles")
	settle(board)
	check(scored==before+1,"One fully inside landing awards one mark")
	Actions.complete_step(board,touch)
	check(scored==before+1,"Waiting for acknowledgement prevents duplicate shots")
	for stage in range(1,4):
		board.set_progress(stage)
		Actions.complete_step(board,touch)
		check(scored==before+stage+1,"All four aimed shots count independently")
	board.set_progress(4)
	Actions.complete_step(board,touch)
	check(scored==before+4 and not board.input_enabled,"Exactly four landed marbles complete the task")
	board.queue_free(); await process_frame

func validate_map() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app); await process_frame; await process_frame
	app.set_process(false); app.selected_character="Badang"; app.player_is_impostor=false
	app.completed_tasks=[0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress=[0,0,0,0,0,0,0,0] as Array[int]
	for map_index in 3:
		app.selected_map=map_index; app.player_position=Geometry.spawn_point(map_index)
		await app.build_game()
		app.show_map_overlay()
		var view: Control = app.find_child("MapOverlay",true,false)
		var controls: Node = app.page_controls
		for property in ["_settings","_music","_help"]:
			check(not controls.get(property).visible,"Utility icon cannot overlap the map modal")
		var instruction := view.find_child("MapNumberInstruction",true,false) as Label
		check(instruction.text.begins_with("Choose a task number") and instruction.text.ends_with(":"),"Map number instruction is English and retains the colon")
		var old_text := false
		for label in view.find_children("*","Label",true,false):
			if label.text.contains("Seret peta"): old_text=true
		check(not old_text,"Map no longer displays the Seret peta sentence")
		view._tab(true); view._choose(5)
		check(view.get("_buttons").size()==8,"TUGAS contains all eight task entries")
		check(not view.get("_details").visible and not view.get("_route").visible,"TUGAS shows no extra selected-task detail or route button")
		check(view.canvas.get("selected")==-1,"TUGAS shows no selected-number highlight")
		view._tab(false)
		check(view.get("_details").visible and view.canvas.get("selected")==5,"Selected task details and highlight appear on PETA")
		var title: Label = view.get("_selection")
		var place: Label = view.get("_place")
		check(title.text=="6. Shoot marbles into the circle" and title.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"Long marble task title wraps without truncation")
		check(not title.get_rect().intersects(place.get_rect()),"Selected task title and place have separate aligned rows")
		check(view.get("_route").position.y>=view.get("_details").position.y+view.get("_details").size.y,"Route button does not overlap selected details")
		view.queue_free(); await process_frame
		controls.refresh(true)
		check(controls.get("_settings").visible and controls.get("_music").visible and controls.get("_help").visible,"Utility icons return after the map closes")
	app.queue_free(); await process_frame
