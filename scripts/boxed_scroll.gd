extends ScrollContainer
## Keep wheel and drag scrolling inside this panel, including over its content.
var _mouse_dragging := false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events = false
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _gui_input(event: InputEvent) -> void:
	# Native ScrollContainer handles touchscreen dragging and mouse wheels.
	# Add left-mouse dragging for desktop and touch devices emulating a mouse.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_dragging = event.pressed
	elif event is InputEventMouseMotion and _mouse_dragging:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			scroll_vertical -= roundi(event.relative.y)
			accept_event()
		else:
			_mouse_dragging = false
