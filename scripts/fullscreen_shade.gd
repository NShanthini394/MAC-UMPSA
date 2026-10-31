extends ColorRect
## Extend dimming beyond a centred design without moving its content.
var content: Control

func _ready() -> void:
	content = Control.new()
	content.name = "ShadeContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var parent := get_parent() as Control
	var parent_position := parent.global_position if parent else Vector2.ZERO
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = -parent_position
	size = viewport_size
	content.position = parent_position
	content.size = parent.size if parent else viewport_size
