extends Panel
## Covers the complete lower-left viewport, including wide phone margins.
func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var extra := (get_viewport_rect().size - Vector2(1280, 720)).max(Vector2.ZERO) * 0.5
	offset_left = -extra.x
	offset_right = 640
	offset_top = -360
	offset_bottom = extra.y
