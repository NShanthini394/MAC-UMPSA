extends Node
## Move the focused field's panel above Android's keyboard, then restore it.
var shifted: Control
var original_position := Vector2.ZERO
var original_z := 0
var lift := 0.0
var full_window_height := 0.0
var window_width := 0.0

func _process(_delta: float) -> void:
	if OS.get_name() != "Android": return
	var physical_height := DisplayServer.virtual_keyboard_get_height()
	var viewport_height := get_viewport().get_visible_rect().size.y
	var window_height := maxf(1.0, DisplayServer.window_get_size().y)
	var width := float(DisplayServer.window_get_size().x)
	if physical_height == 0:
		full_window_height = window_height
		window_width = width
	elif full_window_height == 0 or window_width != width:
		full_window_height = maxf(window_height, DisplayServer.screen_get_size().y)
		window_width = width
	# adjustResize may already have removed part or all of the keyboard area.
	var occluded := maxf(0.0, physical_height - maxf(0.0, full_window_height - window_height))
	avoid(get_viewport().gui_get_focus_owner(), occluded * viewport_height / window_height, viewport_height)

func restore() -> void:
	if is_instance_valid(shifted):
		shifted.position = original_position
		shifted.z_index = original_z
	shifted = null
	lift = 0.0

func avoid(field: Control, keyboard_height: float, viewport_height: float) -> void:
	if keyboard_height <= 0 or not is_instance_valid(field) or not (field is LineEdit or field is TextEdit):
		restore(); return
	var panel := field.get_parent() as Control
	while is_instance_valid(panel) and not panel is Panel and panel.get_parent() is Control:
		panel = panel.get_parent() as Control
	if not is_instance_valid(panel): restore(); return
	if shifted != panel:
		restore()
		shifted = panel
		original_position = panel.position
		original_z = panel.z_index
	var original_bottom := field.get_global_rect().end.y + lift
	lift = maxf(0.0, original_bottom + 20.0 - (viewport_height - keyboard_height))
	shifted.position = original_position - Vector2(0, lift)
	shifted.z_index = 300 if lift > 0 else original_z

func _exit_tree() -> void: restore()
