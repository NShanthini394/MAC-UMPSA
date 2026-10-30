extends SceneTree
const Marker = preload("res://scripts/clue_marker.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640,240)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.size = Vector2(640,240)
	root.add_child(display)
	var background := ColorRect.new()
	background.color = Color("242d27")
	background.size = Vector2(640,240)
	viewport.add_child(background)
	for i in 4:
		var marker := Marker.new()
		marker.position = Vector2(100+i*145,155)
		marker.scale = Vector2.ONE*2.5
		viewport.add_child(marker)
		marker.set_process(false)
		marker.animation_time = i*0.65
		marker.queue_redraw()
	var label := Label.new()
	label.text = "CLUE  •  floating parchment, fireflies and soft ripples"
	label.position = Vector2(50,200)
	viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/task-art")
	viewport.get_texture().get_image().save_png("res://output/task-art/animated-clue-markers.png")
	print("Rendered four phases of the animated clue marker.")
	quit()
