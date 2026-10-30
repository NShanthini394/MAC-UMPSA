extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Board = preload("res://scripts/task_minigame.gd")
const Actions = preload("res://tests/village_task_actions.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
    DirAccess.make_dir_recursive_absolute("res://tmp/task-art-preview")
    var viewport := SubViewport.new()
    viewport.size = Vector2i(792,382)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var display := TextureRect.new()
    display.texture = viewport.get_texture()
    display.size = Vector2(792,382)
    root.add_child(display)
    var shoes_only := "--shoes" in OS.get_cmdline_user_args()
    var contact := Image.create(2376,1528,false,Image.FORMAT_RGBA8)
    for index in Data.COMMON_TASKS.size():
        if shoes_only and index!=7: continue
        var board := Board.new()
        viewport.add_child(board)
        board.size = Vector2(792,382)
        board.configure(Data.COMMON_TASKS[index],0,Data.COMMON_TASK_STEPS[index])
        board.set_process(false)
        var stage: int = 0 if shoes_only else 2 if index in [0,1] else 3 if index==8 else 1
        board.set_progress(stage)
        board.realistic_art.advance(0.6)
        board.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        var image := viewport.get_texture().get_image()
        image.save_png("res://tmp/task-art-preview/task_%02d.png"%index)
        contact.blit_rect(image,Rect2i(0,0,792,382),Vector2i((index%3)*792,(index/3)*382))
        if index in [1,8]:
            Actions.tap(board,board._target() if index==8 else Vector2(140,180),false)
        elif index==7:
            Actions.complete_step(board,false)
        else:
            board.realistic_art.action(board.task_kind,stage,board._flower_position() if index==4 else board._target())
        for frame in 4:
            board._process(0.1)
            await process_frame
            await RenderingServer.frame_post_draw
            viewport.get_texture().get_image().save_png("res://tmp/task-art-preview/task_%02d_motion_%d.png"%[index,frame])
        board.queue_free()
        await process_frame
    if not shoes_only: contact.save_png("res://tmp/task-art-preview/all_twelve_tasks.png")
    print("Rendered traditional footwear and placement animation." if shoes_only else "Rendered twelve task boards and 48 animation frames.")
    quit()
