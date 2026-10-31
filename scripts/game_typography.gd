extends RefCounted
## Shared offline fonts, including deterministic Tamil and Chinese fallbacks.
const BODY = preload("res://assets/fonts/body.tres")
const HEADING = preload("res://assets/fonts/heading.tres")
const THEME = preload("res://assets/fonts/game_theme.tres")

static func apply_label(label: Label, requested_size: int) -> void:
	label.add_theme_font_override("font", HEADING if requested_size >= 24 else BODY)
