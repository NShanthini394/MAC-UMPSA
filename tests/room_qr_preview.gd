extends SceneTree
func _initialize() -> void: run.call_deferred()
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/huawei")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	app.set_process(false)
	await app.build_menu()
	app.show_join_room()
	await capture("res://output/huawei/join-type-or-scan.png")
	app._close_menu_popups()
	app.room_code="7KX9Q"; app.room_is_host=true; app.internet_mode=true
	app.MultiplayerSetup.show_created(app)
	await capture("res://output/huawei/host-share-qr.png")
	app._show_room_qr()
	await capture("res://output/huawei/room-qr.png")
	print("Rendered Join Room and host QR sharing.")
	quit()
