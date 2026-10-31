extends Panel
## Covers the complete lower-left viewport, including wide phone margins.
var touch_active := false
var touch_origin := Vector2.ZERO
var knob_offset := Vector2.ZERO
const RADIUS := 85.0

func begin_touch(at: Vector2) -> void:
	touch_active = true
	touch_origin = at
	knob_offset = Vector2.ZERO
	queue_redraw()

func update_touch(at: Vector2) -> void:
	knob_offset = (at - touch_origin).limit_length(RADIUS)
	queue_redraw()

func end_touch() -> void:
	touch_active = false
	knob_offset = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not touch_active: return
	draw_circle(touch_origin, RADIUS, Color(0.08, 0.06, 0.04, 0.42), true, -1, true)
	draw_arc(touch_origin, RADIUS, 0, TAU, 64, Color(0.96, 0.80, 0.48, 0.75), 3.0, true)
	draw_circle(touch_origin + knob_offset, 31.0, Color(0.90, 0.72, 0.40, 0.80), true, -1, true)
	draw_arc(touch_origin + knob_offset, 31.0, 0, TAU, 48, Color(1.0, 0.93, 0.77, 0.95), 2.0, true)

func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var extra := (get_viewport_rect().size - Vector2(1280, 720)).max(Vector2.ZERO) * 0.5
	offset_left = -extra.x
	offset_right = 640
	offset_top = -360
	offset_bottom = extra.y
