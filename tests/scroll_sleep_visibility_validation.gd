extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor := preload("res://scripts/character_actor.gd").new()
	root.add_child(actor)
	actor.configure("Badang", "Test")
	var sprite := actor.get_node("CharacterSprite") as TextureRect
	var standing_size := sprite.size
	actor.set_sleeping(true)
	assert(sprite.size.x == 90 and sprite.size.y == 72)
	actor.set_sleeping(false)
	assert(sprite.size.is_equal_approx(standing_size))
	var observer := Node2D.new()
	var target := Node2D.new()
	root.add_child(observer); root.add_child(target)
	target.position = Vector2(10000, 10000)
	target.visible = false; target.modulate.a = 0
	var tracker := preload("res://scripts/player_visibility.gd").new()
	root.add_child(tracker)
	tracker.configure(observer, target, 160)
	assert(target.visible and target.modulate.a == 1)
	var scroll := preload("res://scripts/boxed_scroll.gd").new()
	scroll.size = Vector2(250, 150)
	root.add_child(scroll)
	var content := Control.new()
	content.custom_minimum_size = Vector2(200, 1000)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)
	await process_frame
	await process_frame
	assert(scroll.clip_contents and not scroll.mouse_force_pass_scroll_events)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true
	scroll._gui_input(press)
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT; drag.relative = Vector2(0, -80)
	scroll._gui_input(drag)
	assert(scroll.scroll_vertical == 80)
	print("SCROLL / SLEEP / VISIBILITY: all checks passed")
	quit()
