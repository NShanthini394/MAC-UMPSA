extends Control
## Responsive, localized first-match walkthrough. The dimmer blocks gameplay
## input; only the joystick and Interact control have a guided pass-through.
const Lang = preload("res://scripts/app_language.gd")
const Store = preload("res://scripts/settings_store.gd")
const Data = preload("res://scripts/game_data.gd")

var app: Control
var step := 0
var highlight := Rect2()
var card: Panel
var title_label: Label
var body_label: Label
var progress_label: Label
var hint_label: Label
var back_button: Button
var next_button: Button
var skip_button: Button
var finish_button: Button
var blockers: Array[ColorRect] = []
var target_blocker: ColorRect
var moved_from := Vector2.ZERO
var movement_seen := false
var interact_seen := false
var step_sources := [
	["Welcome to the village", "Villagers complete their tasks and identify both Nenek Kebayan imposters. Work together and watch carefully."],
	["Move around", "Drag the joystick at the lower left, or use WASD / arrow keys. Try moving a little to continue."],
	["Use Interact", "Near a task or the gong, tap the Interact button on the right or press E. Tap it now to continue; this tutorial tap will not trigger a game action."],
	["Tasks, map & routes", "Villagers use the task list and map to find village tasks. Markers show task stations; choose a task on the map to see route guidance."],
	["Sleep spell", "Nenek Kebayan can put Villagers to sleep. Sleeping players can still move, but cannot complete tasks or vote."],
	["Gong, discussion & voting", "Use the gong to call an emergency discussion, then vote carefully. It opens at the start of a match and has a one-minute cooldown after each meeting."],
	["How to win", "Villagers win only after all required tasks are complete and both Nenek Kebayan are identified. Nenek Kebayan win when their number equals or exceeds the remaining awake Villagers."]
]

func configure(controller: Control) -> void:
	app = controller
	name = "FirstTimeTutorial"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 120
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)
	if is_instance_valid(Lang.instance):
		Lang.instance.language_changed.connect(refresh_language)
	for i in 4:
		var blocker := ColorRect.new()
		blocker.name = "TutorialInputBlocker%d" % i
		blocker.color = Color(0.015, 0.012, 0.01, 0.78)
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(blocker)
		blockers.append(blocker)
	target_blocker = ColorRect.new()
	target_blocker.name = "TutorialSpotlightInputBlocker"
	target_blocker.color = Color.TRANSPARENT
	target_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(target_blocker)
	_build_ui()
	_show_step()

func _build_ui() -> void:
	card = Panel.new()
	card.name = "TutorialSpeechPanel"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("302319")
	style.border_color = Color("e4b25b")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	progress_label = Label.new()
	progress_label.name = "TutorialProgress"
	progress_label.set_meta("language_source_text", "%d / %d")
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.add_theme_color_override("font_color", Color("d6c5aa"))
	card.add_child(progress_label)
	title_label = Label.new()
	title_label.name = "TutorialTitle"
	title_label.add_theme_color_override("font_color", Data.GOLD)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 25)
	card.add_child(title_label)
	body_label = Label.new()
	body_label.name = "TutorialExplanation"
	body_label.add_theme_color_override("font_color", Data.CREAM)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body_label.add_theme_font_size_override("font_size", 20)
	card.add_child(body_label)
	hint_label = Label.new()
	hint_label.name = "TutorialActionHint"
	hint_label.set_meta("language_source_text", "Tap or move the highlighted control to continue.")
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color("f1c66d"))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 16)
	card.add_child(hint_label)
	back_button = _button("Back", false, _back)
	back_button.name = "TutorialBack"
	skip_button = _button("Skip Tutorial", false, _skip)
	skip_button.name = "TutorialSkip"
	next_button = _button("Next", true, _next)
	next_button.name = "TutorialNext"
	finish_button = _button("Finish", true, _finish)
	finish_button.name = "TutorialFinish"
	_layout()

func _button(source: String, primary: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.text = Lang.text(source)
	button.set_meta("language_source_text", source)
	button.accessibility_name = Lang.text(source)
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(90, 48)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("fff4dc"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("7d281f") if primary else Color("513a28")
	style.border_color = Color("e4b25b")
	style.set_border_width_all(2 if primary else 1)
	style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("a83b29") if primary else Color("745232")
	button.add_theme_stylebox_override("hover", hover)
	card.add_child(button)
	return button

func _layout() -> void:
	if not is_instance_valid(card): return
	var viewport := size
	var card_size := Vector2(minf(820.0, viewport.x - 28.0), minf(420.0, viewport.y - 28.0))
	card_size.x = maxf(360.0, card_size.x)
	card_size.y = maxf(310.0, card_size.y)
	var panel_y := 18.0 if highlight.size != Vector2.ZERO and highlight.get_center().y > viewport.y * 0.53 else viewport.y - card_size.y - 18.0
	card.position = Vector2((viewport.x - card_size.x) * 0.5, panel_y)
	card.size = card_size
	progress_label.position = Vector2(card_size.x - 174, 12)
	progress_label.size = Vector2(146, 28)
	title_label.position = Vector2(24, 14)
	title_label.size = Vector2(card_size.x - 220, 40)
	body_label.position = Vector2(24, 62)
	body_label.size = Vector2(card_size.x - 48, card_size.y - 174)
	hint_label.position = Vector2(24, card_size.y - 96)
	hint_label.size = Vector2(card_size.x - 48, 34)
	var button_y := card_size.y - 54.0
	var widths := [86.0, 150.0, 100.0, 100.0]
	var buttons: Array[Button] = [back_button, skip_button, next_button, finish_button]
	var gap := 8.0
	var total := gap * 3.0
	for width in widths: total += width
	var x := (card_size.x - total) * 0.5
	for i in buttons.size():
		buttons[i].position = Vector2(x, button_y)
		buttons[i].size = Vector2(widths[i], 46)
		x += widths[i] + gap
	_draw_highlight()

func _draw() -> void:
	var view := size
	var shade := Color(0.015, 0.012, 0.01, 0.78)
	if highlight.size == Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, view), shade)
		return
	var hole := highlight.grow(9.0).intersection(Rect2(Vector2.ZERO, view))
	draw_rect(Rect2(0, 0, view.x, hole.position.y), shade)
	draw_rect(Rect2(0, hole.end.y, view.x, view.y - hole.end.y), shade)
	draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), shade)
	draw_rect(Rect2(hole.end.x, hole.position.y, view.x - hole.end.x, hole.size.y), shade)
	var gold := Color("f3c45e")
	draw_rect(hole, gold, false, 4.0)
	var center := hole.get_center()
	draw_line(center + Vector2(-12, -hole.size.y * 0.5 - 20), center + Vector2(0, -hole.size.y * 0.5 - 5), gold, 4.0)
	draw_line(center + Vector2(12, -hole.size.y * 0.5 - 20), center + Vector2(0, -hole.size.y * 0.5 - 5), gold, 4.0)

func _target_rect() -> Rect2:
	var name := ""
	match step:
		1: return Rect2(20, size.y - 230, 220, 205)
		2: name = "InteractButton"
		3: name = "VillageTasksPanel" if not app.player_is_impostor else "GameMapButton"
		4: name = "SleepSpellButton" if app.player_is_impostor else "InteractButton"
		5: name = "InteractButton"
		6: name = "ProgressLabel" if not app.player_is_impostor else "PowerActionButtons"
	if name.is_empty(): return Rect2()
	var target := app.find_child(name, true, false) as Control
	if target == null or not target.is_visible_in_tree(): return Rect2()
	var rect := target.get_global_rect()
	return Rect2(rect.position - global_position, rect.size)

func _draw_highlight() -> void:
	highlight = _target_rect()
	queue_redraw()
	var view := size
	var hole := highlight.grow(9.0).intersection(Rect2(Vector2.ZERO, view)) if highlight.size != Vector2.ZERO else Rect2()
	var rects: Array[Rect2]
	if hole.size == Vector2.ZERO:
		rects = [Rect2(Vector2.ZERO, view), Rect2(), Rect2(), Rect2()]
	else:
		rects = [
			Rect2(0, 0, view.x, hole.position.y),
			Rect2(0, hole.end.y, view.x, view.y - hole.end.y),
			Rect2(0, hole.position.y, hole.position.x, hole.size.y),
			Rect2(hole.end.x, hole.position.y, view.x - hole.end.x, hole.size.y)
		]
	for i in blockers.size():
		blockers[i].position = rects[i].position
		blockers[i].size = rects[i].size
		blockers[i].visible = rects[i].size.x > 0 and rects[i].size.y > 0
	target_blocker.position = hole.position
	target_blocker.size = hole.size
	target_blocker.visible = hole.size != Vector2.ZERO and step not in [1, 2]
	if is_instance_valid(card): _layout_card_only()

func _layout_card_only() -> void:
	var viewport := size
	var card_size := card.size
	var panel_y := 18.0 if highlight.size != Vector2.ZERO and highlight.get_center().y > viewport.y * 0.53 else viewport.y - card_size.y - 18.0
	card.position = Vector2((viewport.x - card_size.x) * 0.5, panel_y)

func _show_step() -> void:
	var source: Array = step_sources[step]
	title_label.text = Lang.text(str(source[0]))
	body_label.text = Lang.text(str(source[1]))
	title_label.set_meta("language_source_text", str(source[0]))
	body_label.set_meta("language_source_text", str(source[1]))
	progress_label.text = Lang.text("%d / %d") % [step + 1, step_sources.size()]
	hint_label.text = Lang.text("Tap or move the highlighted control to continue.") if step in [1, 2] and not _action_done() else ""
	var interact := app.find_child("InteractButton", true, false) as BaseButton
	if interact:
		if not interact.has_meta("tutorial_original_accessibility"):
			interact.set_meta("tutorial_original_accessibility", interact.accessibility_name)
			interact.set_meta("tutorial_original_tooltip", interact.tooltip_text)
		if step == 2:
			interact.disabled = false
			interact.accessibility_name = Lang.text("Interact · E")
			interact.tooltip_text = Lang.text("Interact · E")
	back_button.disabled = step == 0
	next_button.visible = step < step_sources.size() - 1
	finish_button.visible = step == step_sources.size() - 1
	next_button.disabled = step in [1, 2] and not _action_done()
	_draw_highlight()

func _action_done() -> bool:
	return movement_seen if step == 1 else interact_seen if step == 2 else true

func _process(_delta: float) -> void:
	if not is_instance_valid(app): return
	if step == 1 and not movement_seen and app.player_position.distance_to(moved_from) >= 12.0:
		movement_seen = true
		_show_step()
	var current := _target_rect()
	if current != highlight:
		_draw_highlight()

func allow_movement() -> bool:
	return step == 1

func on_interact() -> bool:
	if step == 2:
		interact_seen = true
		_show_step()
		return true
	return false

func _next() -> void:
	if step in [1, 2] and not _action_done(): return
	step = mini(step + 1, step_sources.size() - 1)
	if step == 1:
		moved_from = app.player_position
		movement_seen = false
	_show_step()

func _back() -> void:
	step = maxi(0, step - 1)
	_show_step()

func _finish() -> void:
	_complete(false)

func _skip() -> void:
	_complete(true)

func _complete(skipped: bool) -> void:
	Store.set_value("tutorial_completed", true)
	var interact := app.find_child("InteractButton", true, false) as BaseButton
	if interact and interact.has_meta("tutorial_original_accessibility"):
		interact.accessibility_name = str(interact.get_meta("tutorial_original_accessibility"))
		interact.tooltip_text = str(interact.get_meta("tutorial_original_tooltip"))
	app.show_notice(Lang.text("Tutorial skipped. Replay it from How to Play or Settings.") if skipped else Lang.text("Tutorial complete. Good luck in the village!"))
	queue_free()
	if app.has_method("on_tutorial_finished"):
		app.call_deferred("on_tutorial_finished")

func refresh_language() -> void:
	for button in [back_button, next_button, skip_button, finish_button]:
		button.text = Lang.text(str(button.get_meta("language_source_text")))
		button.accessibility_name = button.text
	_show_step()
	if step == 2:
		var interact := app.find_child("InteractButton", true, false) as BaseButton
		if interact:
			interact.accessibility_name = Lang.text("Interact · E")
			interact.tooltip_text = Lang.text("Interact · E")
