extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Board = preload("res://scripts/task_minigame.gd")
const Actions = preload("res://tests/village_task_actions.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: run.call_deferred()
func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition: failures.append(message); push_error(message)

func run() -> void:
    for index in Data.COMMON_TASKS.size():
        var board := Board.new()
        root.add_child(board)
        board.configure(Data.COMMON_TASKS[index],0,Data.COMMON_TASK_STEPS[index])
        board.set_process(false)
        var art: RefCounted = board.realistic_art
        check(art.atlas!=null and art.wood!=null,"Image assets load for task %d"%index)
        var image: Image = art.atlas.get_image()
        check(image.get_size()==Vector2i(1536,1024),"Atlas has expected six-by-four cell dimensions")
        check(image.get_pixel(256,256).a<0.05,"Transparent sprite gutters are preserved")
        var clock_before: float = art.clock
        board._process(0.1)
        check(art.clock>clock_before,"Task animation advances with elapsed time")
        check(board.current_progress==0 and not board._pending,"Idle animation never submits task progress")
        Actions.complete_step(board,true)
        check(not art.effects.is_empty(),"Successful action produces a task-specific effect")
        check(board._pending,"Visual effect preserves the server acknowledgement gate")
        board._process(0.2)
        check(not art.effects.is_empty(),"Action effects survive while waiting for acknowledgement")
        board.set_progress(1)
        check(not art.effects.is_empty(),"Acknowledgement preserves in-flight visual effects")
        board._process(1.0)
        check(art.effects.is_empty(),"Expired effects are removed")
        check(board.current_progress==1,"Animation never awards additional steps")
        board.queue_free()
        await process_frame
    for task_index in [1,8]:
        var board := Board.new()
        root.add_child(board)
        var stage: int = 2 if task_index==1 else 3
        board.configure(Data.COMMON_TASKS[task_index],stage,Data.COMMON_TASK_STEPS[task_index])
        Actions.tap(board,Vector2(140,180) if task_index==1 else board._target(),true)
        check(board._sparks==1 and not board._pending,"One strike animates without completing the five-strike stage")
        check(board.realistic_art.impact>0,"Flint and pestle animate on each individual strike")
        board.queue_free()
        await process_frame
    print("TASK ANIMATION CHECKS: %d checks; %d failures"%[checks,failures.size()])
    quit(0 if failures.is_empty() else 1)
