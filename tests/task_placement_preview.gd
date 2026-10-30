extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
const Station = preload("res://scripts/realistic_task_station.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600,1000)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.size = Vector2(1280,800)
	root.add_child(display)
	for map_index in [0,2]:
		var page := Node2D.new()
		viewport.add_child(page)
		var background := ColorRect.new()
		background.color = Color("202720")
		background.size = Vector2(1600,1000)
		page.add_child(background)
		_label(page,Data.MAPS[map_index]["name"],Vector2(30,20),30)
		var world_size := Geometry.world_size(map_index)
		var fit := minf(1160/world_size.x,880/world_size.y)
		var world := Node2D.new()
		world.position = Vector2(20,90)+(Vector2(1160,880)-world_size*fit)*0.5
		world.scale = Vector2.ONE*fit
		page.add_child(world)
		var artwork := Sprite2D.new()
		artwork.texture = load(Data.map_art_path(map_index))
		artwork.centered = false
		artwork.scale = world_size/Vector2(artwork.texture.get_size())
		world.add_child(artwork)
		var sections: Array = Geometry.floor_plan(map_index).layout["task_sections"]
		for i in Data.COMMON_TASKS.size():
			var point: Vector2 = Geometry.task_points(map_index)[i]
			var station := Station.new()
			station.task_index = i
			station.position = point
			world.add_child(station)
			_label(page,str(i+1),world.position+point*fit+Vector2(8,-14),19)
			var area: String = Geometry.floor_plan(map_index).layout["sections"][sections[i]]["name"]
			_label(page,"%d. %s"%[i+1,Data.COMMON_TASKS[i]["name"]],Vector2(1200,100+i*70),18)
			_label(page,area,Vector2(1222,124+i*70),16,Color("d8bb7e"))
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://output/task-art")
		viewport.get_texture().get_image().save_png("res://output/task-art/task-locations-%s.png"%("istana" if map_index==0 else "mahsuri"))
		page.queue_free()
		await process_frame
	print("Rendered task placements for Istana and Mahsuri.")
	quit()

func _label(parent: Node, copy: String, at: Vector2, font_size: int, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = copy
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(label)
