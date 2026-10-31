extends Panel
## The lower-left touch area stays active in all three display modes.
const Store = preload("res://scripts/settings_store.gd")
var controller: Control
var mode := "touch"
var active := false
var touch_origin := Vector2.ZERO
var displacement := Vector2.ZERO
const BASE_RADIUS := 88.0

func _ready() -> void:
	mode = str(Store.get_value("joystick_visibility"))
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var extra := (get_viewport_rect().size - Vector2(1280, 720)).max(Vector2.ZERO) * 0.5
	offset_left = -extra.x
	offset_right = 640
	offset_top = -360
	offset_bottom = extra.y
	if active and is_instance_valid(controller): controller._stop_move()
	queue_redraw()

func _process(_delta: float) -> void:
	var preferred := str(Store.get_value("joystick_visibility"))
	if preferred != mode:
		mode = preferred; queue_redraw()
	if active and is_instance_valid(controller):
		if not is_visible_in_tree() or controller.current_screen != "game" or controller._utility_dialog_open() or controller.player_voted_out:
			controller._stop_move()

func begin_touch(at: Vector2) -> void:
	active = true; touch_origin = at; displacement = Vector2.ZERO; queue_redraw()

func move_touch(value: Vector2) -> void:
	displacement = value.limit_length(85.0); queue_redraw()

func end_touch() -> void:
	active = false; displacement = Vector2.ZERO; queue_redraw()

func visual_visible() -> bool:
	return mode == "always" or (mode == "touch" and active)

func visual_center() -> Vector2:
	return touch_origin if active else Vector2(120, size.y - 120)

func _draw() -> void:
	if not visual_visible(): return
	var centre := visual_center()
	draw_circle(centre, BASE_RADIUS, Color(0.10, 0.07, 0.04, 0.48))
	draw_arc(centre, BASE_RADIUS, 0, TAU, 64, Color("d9b76c"), 2.5, true)
	draw_circle(centre, 4, Color(0.93, 0.78, 0.48, 0.45))
	var thumb := centre + displacement * (52.0 / 85.0)
	draw_circle(thumb, 34, Color(0.86, 0.70, 0.43, 0.86))
	draw_arc(thumb, 34, 0, TAU, 48, Color("fff0cf"), 2, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(controller): controller._stop_move()
