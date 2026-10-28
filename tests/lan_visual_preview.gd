extends SceneTree
var app: Control


func _initialize() -> void:
	_run.call_deferred()


func capture(file_name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/" + file_name + ".png")
	print("LAN preview: " + file_name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await app.call("build_menu")
	await capture("lan_main_menu")
	app.set("selected_map", 0)
	await app.call("_open_create_room")
	await capture("lan_host_setup")
	app.set("room_code", "AB2CD")
	app.call("_show_created_room")
	await capture("lan_host_invite")
	app.set("room_code", "")
	await app.call("build_menu")
	app.call("show_join_room")
	await capture("lan_join_room")
	app.find_child("JoinCodeEntry", true, false).text = "BAD"
	app.find_child("JoinOnlineRoomButton", true, false).emit_signal("pressed")
	await capture("lan_join_validation")
	app.queue_free()
	await process_frame
	quit()
