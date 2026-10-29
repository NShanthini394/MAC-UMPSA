extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Board = preload("res://scripts/task_minigame.gd")
const Actions = preload("res://tests/village_task_actions.gd")
var checks := 0
var failures := 0
var scored := 0
func _initialize() -> void: run.call_deferred()
func check(condition:bool,message:String) -> void:
	checks+=1
	if not condition: failures+=1; printerr("FAIL: "+message)
func run() -> void:
	for touch in [false,true]:
		var board := Board.new()
		root.add_child(board)
		board.configure(Data.COMMON_TASKS[7],0,4)
		var start := scored
		board.step_completed.connect(func():scored+=1;board.set_progress(scored-start))
		var shoes: Control = board.shoe_board
		check(shoes.textures.size()==4 and shoes.slots.size()==8,"Four pictured footwear types provide eight independent pieces")
		for pair in [3,1,2,0]:
			var before := scored
			var source: Vector2 = shoes.shoe_centre(pair)
			Actions.drag(board,source,shoes.pair_rect((pair+1)%4).get_center(),touch)
			check(scored==before and shoes.slots[pair]==-1,"Wrong pair cannot take the shoe or award progress")
			Actions.drag(board,source,shoes.slot_centre(pair*2),touch)
			check(scored==before and shoes.slots[pair]>=0,"First shoe snaps into place without scoring")
			Actions.drag(board,shoes.shoe_centre(pair+4),shoes.slot_centre(pair*2+1),touch)
			check(scored==before+1,"Second matching shoe scores one pair, in any order")
			check(shoes.slots[pair]/2==pair and shoes.slots[pair+4]/2==pair,"Both shoes are aligned in the correct right-hand pair")
		check(board.current_progress==4 and not board.input_enabled,"All four pairs complete the task exactly once")
		board.queue_free();await process_frame
	var board := Board.new()
	root.add_child(board);board.configure(Data.COMMON_TASKS[7],0,4)
	var before := scored
	board.step_completed.connect(func():scored+=1)
	Actions.complete_step(board,true)
	check(scored==before+1 and board.get("_pending"),"Pair waits for server acknowledgement")
	check(board.shoe_board.get("_touch_id")==-1,"Finger release is handled while waiting for the network")
	Actions.complete_step(board,true)
	check(scored==before+1,"No duplicate or extra pair while acknowledgement is pending")
	board.set_progress(1)
	check(board.shoe_board.credited_pairs==[0],"Acknowledgement preserves the arranged pair")
	Actions.complete_step(board,true)
	check(scored==before+2,"Next pair works after acknowledgement")
	board.queue_free();await process_frame
	print("ENGLISH AND SHOE CHECKS: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
