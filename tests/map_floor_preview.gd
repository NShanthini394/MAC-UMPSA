extends Node2D
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")


func _ready() -> void:
	_run.call_deferred()


func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/" + file_name + ".png")
	print("Map preview: " + file_name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	for map_index in 3:
		var plan := Geometry.floor_plan(map_index)
		var page := Node2D.new()
		add_child(page)
		var backdrop := ColorRect.new()
		backdrop.color = Color("172126")
		backdrop.size = Vector2(1280,720)
		page.add_child(backdrop)
		var title := Label.new()
		title.text = Data.MAPS[map_index]["name"] + "  /  PATHS & ENTRANCES"
		title.position = Vector2(24,14)
		title.add_theme_font_size_override("font_size",26)
		title.modulate = Color("f7d48d")
		page.add_child(title)
		var legend := Label.new()
		legend.text = "Green arrows: open entrances     Blue: starting position     Boundaries are invisible"
		legend.position = Vector2(24,52)
		legend.add_theme_font_size_override("font_size",16)
		page.add_child(legend)
		var image_size: Vector2 = plan.layout["world_size"]
		var fit := minf(1230 / image_size.x, 600 / image_size.y)
		var canvas := Node2D.new()
		canvas.position = Vector2((1280-image_size.x*fit)*0.5,95+(600-image_size.y*fit)*0.5)
		canvas.scale = Vector2.ONE * fit
		page.add_child(canvas)
		var art := Sprite2D.new()
		art.texture = load(Data.map_art_path(map_index))
		art.centered = false
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		canvas.add_child(art)
		var guide := load("res://scripts/map_paths_visual.gd").new() as Node2D
		guide.set("map_index",map_index)
		guide.set("overview",true)
		guide.set("player_marker",plan.layout["spawn"])
		guide.scale = plan.scale
		canvas.add_child(guide)
		await capture("map_%d_paths" % map_index)
		var trace := Node2D.new()
		trace.scale = plan.scale
		canvas.add_child(trace)
		for polygon in plan.floors:
			var shape := Polygon2D.new()
			shape.polygon = polygon
			shape.color = Color(0.2,0.9,0.6,0.20)
			trace.add_child(shape)
		for rect in plan.layout["solids"]:
			var shape := Polygon2D.new()
			shape.polygon = PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
			shape.color = Color(0.9,0.2,0.1,0.45)
			trace.add_child(shape)
		await capture("map_%d_floor_trace" % map_index)
		page.queue_free()
		await get_tree().process_frame
		var app: Control = load("res://scenes/main.tscn").instantiate()
		add_child(app)
		await get_tree().process_frame
		await get_tree().process_frame
		app.set("selected_map",map_index)
		app.set("selected_character",["Badang","Pak Kaduk","Mahsuri"][map_index])
		app.set("player_is_impostor",false)
		app.set("completed_tasks",[0,0,0,0,0,0,0,0] as Array[int])
		app.set("task_progress",[0,0,0,0,0,0,0,0] as Array[int])
		app.set("player_position",Geometry.spawn_point(map_index))
		await app.call("build_game")
		app.get("player_body").get_node("Camera2D").reset_smoothing()
		await capture("map_%d_gameplay" % map_index)
		app.call("show_map_overlay")
		await capture("map_%d_overlay" % map_index)
		if map_index == 1:
			var overlay := app.find_child("MapOverlay", true, false)
			if overlay: overlay.queue_free()
			app.set("player_position", Vector2(620,180))
			app.get("player_body").position = Vector2(620,180)
			app.get("player_body").get_node("Camera2D").reset_smoothing()
			await capture("map_1_corner_fixed")
			app.call("_start_local_practice_lobby")
			await get_tree().process_frame
			await capture("waiting_room_ready_question")
			app.call("_on_lobby_primary_action")
			await capture("waiting_room_15_seconds")
		app.queue_free()
		await get_tree().process_frame
	get_tree().quit()
