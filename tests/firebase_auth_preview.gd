extends Node
func _ready() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.show_create_account()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/page-previews")
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/firebase-create-account.png")
	app._close_email_auth()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/page-previews/firebase-login.png")
	get_tree().quit()
