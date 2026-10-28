extends RefCounted
## Shared UI construction helpers used by the screen controllers.

static func make_child_label(parent: Control, text: String, font_size: int, color: Color, align: HorizontalAlignment, rect: Rect2) -> Label:
	var label := Label.new()
	label.text = text; label.position = rect.position; label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1); label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = align; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


static func add_background(parent: Control, texture: Texture2D) -> void:
	var bg := TextureRect.new(); bg.texture = texture; bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); parent.add_child(bg)


static func add_color_overlay(parent: Control, color: Color) -> void:
	var rect := ColorRect.new(); rect.color = color; rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rect.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(rect)


static func make_map_texture(atlas: Texture2D, region: Rect2) -> Texture2D:
	var result := AtlasTexture.new(); result.atlas = atlas; result.region = region
	return result


static func make_label(parent: Node, text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", color); label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75)); label.add_theme_constant_override("shadow_offset_x", 1); label.add_theme_constant_override("shadow_offset_y", 2); label.horizontal_alignment = align; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.size = Vector2(1280, 32); parent.add_child(label); return label


static func make_panel(parent: Node, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new(); panel.position = rect.position; panel.size = rect.size
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = Color("c5904b"); style.set_border_width_all(2); style.set_corner_radius_all(12); style.content_margin_left = 8; style.content_margin_right = 8; style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style); parent.add_child(panel); return panel


static func make_button(parent: Node, title: String, callback: Callable, width: float, height: float, highlight: bool = false) -> Button:
	var button := Button.new(); button.text = title; button.custom_minimum_size = Vector2(width, height); button.size = Vector2(width, height); button.focus_mode = Control.FOCUS_NONE; button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new(); normal.bg_color = Color("7d431e") if highlight else Color("51321f"); normal.border_color = Color("e4b25b"); normal.set_border_width_all(2); normal.set_corner_radius_all(10); normal.content_margin_left = 10; normal.content_margin_right = 10
	var hover := normal.duplicate() as StyleBoxFlat; hover.bg_color = Color("9b5c29") if highlight else Color("704426")
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", hover); button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("fff0cf")); button.add_theme_color_override("font_hover_color", Color.WHITE); button.add_theme_color_override("font_pressed_color", Color("f7c35a"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
