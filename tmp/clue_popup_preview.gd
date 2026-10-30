extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var app=load("res://scenes/main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 await process_frame
 await create_timer(1.0).timeout
 await app.build_menu()
 app.set_process(false)
 app.show_clue_panel("Gold chest", "hidden")
 await create_timer(0.7).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tmp/clue-popup-preview.png")
 app.queue_free()
 await process_frame
 quit()
