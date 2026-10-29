extends Node2D
const Data = preload("res://scripts/game_data.gd")
const Actor = preload("res://scripts/character_actor.gd")
const Geometry = preload("res://scripts/map_geometry.gd")


func _ready() -> void:
	_run.call_deferred()


func label(parent: Node, text: String, point: Vector2, font_size: int = 17) -> void:
	var item := Label.new()
	item.text = text
	item.position = point
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", Color("fff0cf"))
	parent.add_child(item)


func capture(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/" + file_name + ".png")
	print("Cast preview: " + file_name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	for page in 2:
		var gallery := Node2D.new()
		add_child(gallery)
		var backdrop := ColorRect.new()
		backdrop.color = Color("1b2928")
		backdrop.size = Vector2(1280, 720)
		gallery.add_child(backdrop)
		label(gallery, "CHARACTER WALKING PREVIEW  /  %d" % (page + 1), Vector2(26, 15), 26)
		for column in 5:
			label(gallery, ["STANDING", "WALK DOWN", "WALK UP", "WALK RIGHT", "WALK LEFT"][column], Vector2(245 + column * 205, 65), 15)
		for row in 5:
			var character: String = Data.CHARACTERS[page * 5 + row]
			label(gallery, character.replace("Orang Kampung ", "Orang Kampung\n"), Vector2(24, 142 + row * 111), 16)
			for column in 5:
				var actor := Actor.new()
				gallery.add_child(actor)
				actor.position = Vector2(234 + column * 205, 102 + row * 111)
				actor.scale = Vector2(1.25, 1.25)
				actor.configure(character, "")
				actor.set_facing_direction([Vector2.DOWN, Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT][column])
				actor.set_running(column > 0)
		await get_tree().create_timer(0.18).timeout
		await capture("cast_walk_gallery_%d" % (page + 1))
		await get_tree().create_timer(0.25).timeout
		await capture("cast_walk_gallery_%d_alternate" % (page + 1))
		gallery.queue_free()
		await get_tree().process_frame
	var app: Control = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.set("selected_character", "Bawang Putih")
	app.set("selected_map", 1)
	app.set("player_is_impostor", false)
	app.set("lobby_player_name", "Walk Test")
	app.set("completed_tasks", [0, 0, 0, 0, 0, 0, 0, 0] as Array[int])
	app.set("task_progress", [0, 0, 0, 0, 0, 0, 0, 0] as Array[int])
	app.set("player_position", Geometry.spawn_point(1))
	await app.call("build_game")
	app.get("player_body").get_node("Camera2D").reset_smoothing()
	await capture("cast_new_character_gameplay")
	app.set("lobby_players", [{"id": "local", "name": "Walk Test", "character": "Bawang Putih", "host": true, "ready": false}])
	await app.call("build_character_select")
	await capture("cast_character_selection")
	app.queue_free()
	await get_tree().process_frame
	get_tree().quit()
