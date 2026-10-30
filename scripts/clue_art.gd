extends RefCounted
## Wordless clue illustrations; clue names remain internal network identifiers.
static func asset_path(clue_name: String) -> String:
	return "res://assets/clues/" + clue_name.to_lower().replace("-", "_").replace(" ", "_") + ".png"

static func add_icon(parent: Control, clue_name: String, rect: Rect2) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "ClueIllustration_" + str(parent.get_child_count())
	icon.texture = load(asset_path(clue_name))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = rect.position
	icon.size = rect.size
	icon.pivot_offset = rect.size * 0.5
	parent.add_child(icon)
	icon.modulate.a = 0.0
	icon.scale = Vector2.ONE * 0.8
	var reveal := icon.create_tween().set_parallel(true)
	reveal.tween_property(icon, "modulate:a", 1.0, 0.3)
	reveal.tween_property(icon, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var drift := icon.create_tween().set_loops()
	drift.tween_property(icon, "position:y", rect.position.y - 5.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property(icon, "position:y", rect.position.y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return icon
