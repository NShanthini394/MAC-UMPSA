extends RefCounted
## Shared UI construction helpers used by the screen controllers.
static var _button_textures: Dictionary = {}

static func menu_button_style(variant: String = "wood", state: String = "normal") -> StyleBoxTexture:
	var key := variant + ":" + state
	if not _button_textures.has(key):
		var colors: Array = {
			"wood": ["75421f", "3b2116", "a36132"],
			"grey": ["77746e", "393937", "a09b91"],
			"red": ["a43220", "601a14", "d65a2b"],
			"green": ["416442", "223b29", "63905a"],
			"light": ["fff8e9", "ead7b4", "fffdf5"]
		}.get(variant, ["75421f", "3b2116", "a36132"])
		var brightness := 1.14 if state == "hover" else (0.78 if state == "pressed" else (0.58 if state == "disabled" else 1.0))
		var top := Color(str(colors[0])) * Color(brightness, brightness, brightness, 1)
		var bottom := Color(str(colors[1])) * Color(brightness, brightness, brightness, 1)
		var gleam := Color(str(colors[2]))
		# Scalable, code-native artwork: wood grain, stepped corners and a gold bevel,
		# following the main menu without baking labels into the texture.
		var svg := """<svg xmlns="http://www.w3.org/2000/svg" width="320" height="64" viewBox="0 0 320 64">
<defs><linearGradient id="wood" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>
<linearGradient id="gold" x2="0" y2="1"><stop stop-color="#ffe7a1"/><stop offset=".42" stop-color="#bd7729"/><stop offset=".7" stop-color="#f5c365"/><stop offset="1" stop-color="#6e3814"/></linearGradient></defs>
<path d="M11 2H309L312 8H318V56H312L309 62H11L8 56H2V8H8Z" fill="#160e09" stroke="#301609" stroke-width="3"/>
<path d="M13 5H307V10H314V54H307V59H13V54H6V10H13Z" fill="url(#gold)"/>
<path d="M16 9H304V14H310V50H304V55H16V50H10V14H16Z" fill="url(#wood)" stroke="#532913" stroke-width="2"/>
<g fill="none" stroke="#%s" opacity=".22" stroke-width="1"><path d="M21 17Q80 12 155 19T300 16M16 26Q90 20 174 27T306 23M14 39Q80 33 165 39T306 38M23 48Q120 43 220 48T302 45"/></g>
<path d="M17 11H303M12 16V48" stroke="#ffda85" stroke-opacity=".7" fill="none"/>
<path d="M18 53H302M308 16V49" stroke="#2b140b" stroke-opacity=".8" fill="none"/>
<g fill="#f4cc74" stroke="#8b501f" stroke-width="1"><path d="m9 27 4 5-4 5-4-5zM311 27l4 5-4 5-4-5z"/><path d="m14 6 3 3-3 3-3-3zM306 6l3 3-3 3-3-3zM14 52l3 3-3 3-3-3zM306 52l3 3-3 3-3-3z"/></g>
</svg>""" % [top.to_html(false), bottom.to_html(false), gleam.to_html(false)]
		var image := Image.new()
		image.load_svg_from_string(svg)
		_button_textures[key] = ImageTexture.create_from_image(image)
	var style := StyleBoxTexture.new()
	style.texture = _button_textures[key]
	style.texture_margin_left = 17; style.texture_margin_right = 17
	style.texture_margin_top = 13; style.texture_margin_bottom = 13
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 3; style.content_margin_bottom = 3
	return style

static func apply_menu_button(button: Button, variant: String = "wood") -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, menu_button_style(variant, "hover" if state == "focus" else state))
	var ink := Color("302015") if variant == "light" else Color("fff0cf")
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", Color("bca985"))
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7) if variant != "light" else Color.TRANSPARENT)
	button.add_theme_constant_override("shadow_offset_y", 1)
	button.add_theme_constant_override("outline_size", 0)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func make_child_label(parent: Control, text: String, font_size: int, color: Color, align: HorizontalAlignment, rect: Rect2) -> Label:
	var label := Label.new()
	# Enable wrapping before assigning long text so its unwrapped minimum width
	# cannot expand the control beyond the requested panel bounds.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = rect.position; label.size = rect.size
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(18, roundi(font_size * 1.15)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1); label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = align; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.position = rect.position; label.size = rect.size
	return label


static func add_background(parent: Control, texture: Texture2D) -> void:
	var bg := TextureRect.new(); bg.texture = texture; bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); parent.add_child(bg)


static func add_color_overlay(parent: Control, color: Color) -> void:
	var rect := preload("res://scripts/fullscreen_shade.gd").new(); rect.color = color; rect.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(rect)


static func make_map_texture(atlas: Texture2D, region: Rect2) -> Texture2D:
	var result := AtlasTexture.new(); result.atlas = atlas; result.region = region
	return result


static func make_label(parent: Node, text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", maxi(18, roundi(font_size * 1.15))); label.add_theme_color_override("font_color", color); label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75)); label.add_theme_constant_override("shadow_offset_x", 1); label.add_theme_constant_override("shadow_offset_y", 2); label.horizontal_alignment = align; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.size = Vector2(1280, 32); parent.add_child(label); return label


static func make_panel(parent: Node, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new(); panel.position = rect.position; panel.size = rect.size
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = Color("c5904b"); style.set_border_width_all(2); style.set_corner_radius_all(12); style.content_margin_left = 8; style.content_margin_right = 8; style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style); parent.add_child(panel); return panel


static func make_button(parent: Node, title: String, callback: Callable, width: float, height: float, highlight: bool = false) -> Button:
	var button := Button.new(); button.text = title; button.custom_minimum_size = Vector2(width, height); button.size = Vector2(width, height); button.focus_mode = Control.FOCUS_NONE; button.add_theme_font_size_override("font_size", 20)
	apply_menu_button(button, "red" if highlight else "wood")
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
