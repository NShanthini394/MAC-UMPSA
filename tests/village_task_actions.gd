extends RefCounted
## Drive the same pointer events used by desktop and phone task boards.
static func press(board: Control, at: Vector2, touch: bool) -> void:
	if touch:
		var event := InputEventScreenTouch.new(); event.index=0; event.position=at; event.pressed=true
		board._gui_input(event)
	else:
		var event := InputEventMouseButton.new(); event.position=at; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
		board._gui_input(event)
static func release(board: Control, at: Vector2, touch: bool) -> void:
	if touch:
		var event := InputEventScreenTouch.new(); event.index=0; event.position=at; event.pressed=false
		board._gui_input(event)
	else:
		var event := InputEventMouseButton.new(); event.position=at; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=false
		board._gui_input(event)
static func tap(board: Control, at: Vector2, touch: bool) -> void:
	press(board,at,touch); release(board,at,touch)
static func drag(board: Control, start: Vector2, finish: Vector2, touch: bool) -> void:
	press(board,start,touch)
	if touch:
		var event := InputEventScreenDrag.new(); event.index=0; event.position=finish; event.relative=finish-start
		board._gui_input(event)
	else:
		var event := InputEventMouseMotion.new(); event.position=finish; event.relative=finish-start; event.button_mask=MOUSE_BUTTON_MASK_LEFT
		board._gui_input(event)
	release(board,finish,touch)
static func complete_step(board: Control, touch: bool) -> void:
	match board.task_kind:
		"slippers":
			# Both independently movable shoes are required for one scored pair.
			for shoe in 2: drag(board,board._source(),board._target(),touch)
		"herbs":
			if board.current_progress==3:
				for index in 5: tap(board,board._target(),touch)
			else: drag(board,board._source(),board._target(),touch)
		"rice":
			if board.current_progress==2:
				board.set("_heat",0.67); tap(board,Vector2(610,290),touch)
			else: drag(board,board._source(),board._target(),touch)
		"fire":
			if board.current_progress==2:
				for index in 5: tap(board,Vector2(140,180),touch)
			else: drag(board,board._source(),board._target(),touch)
		"sweep": drag(board,board._dust_position()-Vector2(60,0),board._dust_position()+Vector2(60,0),touch)
		"flowers": tap(board,board._flower_position(),touch)
		"marbles":
			var pull: Vector2 = board.get("_shot").pull_for_target(board._target())
			drag(board,board._source(),board._source()-pull,touch)
			for frame in 240:
				if not board.get("_shot").rolling: break
				board._process(1.0/60.0)
		_: drag(board,board._source(),board._target(),touch)
