extends SceneTree
const Station = preload("res://scripts/realistic_task_station.gd")
const Data = preload("res://scripts/game_data.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,540)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.size = Vector2(960,540)
	root.add_child(display)
	var background := TextureRect.new()
	background.texture = load("res://assets/tasks/realistic/timber_table.png")
	background.size = Vector2(960,540)
	viewport.add_child(background)
	for i in 12:
		var station := Station.new()
		station.task_index = i
		station.position = Vector2(120+(i%4)*240,120+(i/4)*170)
		station.scale = Vector2.ONE*1.6
		viewport.add_child(station)
		var label := Label.new()
		label.text = Data.COMMON_TASKS[i]["name"]
		label.position = station.position+Vector2(-110,35)
		label.size = Vector2(220,48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_shadow_color",Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x",2)
		label.add_theme_constant_override("shadow_offset_y",2)
		viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/task-art")
	viewport.get_texture().get_image().save_png("res://output/task-art/realistic-map-stations.png")
	print("Rendered all twelve outlined map task props.")
	quit()
