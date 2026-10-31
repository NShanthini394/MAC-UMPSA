extends RefCounted
## Dedicated, modal meeting layouts in the game's 1280 × 720 UI canvas.
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const Powers = preload("res://scripts/nenek_powers.gd")
const Lang = preload("res://scripts/app_language.gd")

static func panel(app: Control, rect: Rect2) -> Panel:
	app._close_meeting_presentation()
	app.current_screen = "meeting"
	var shade := ColorRect.new()
	shade.name = "MeetingOverlay"
	shade.color = Color(0.025, 0.018, 0.03, 0.88)
	shade.size = Vector2(1280, 720)
	shade.z_index = 40
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	app._screen_ui_parent().add_child(shade)
	var result := UI.make_panel(shade, rect, Color("211912"))
	result.name = "MeetingPanel"
	return result

static func avatar(parent: Control, member: Dictionary, rect: Rect2) -> void:
	var image := TextureRect.new()
	var character := str(member.get("character", ""))
	if Data.CHARACTER_AVATARS.has(character): image.texture = load(Data.CHARACTER_AVATARS[character])
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position = rect.position; image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

static func discussion(app: Control) -> void:
	var body := panel(app, Rect2(140, 50, 1000, 620))
	UI.make_child_label(body, Lang.text("EMERGENCY MEETING  •  DISCUSSION"), 25, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 16, 940, 42)).name = "MeetingHeadingLabel"
	UI.make_child_label(body, Lang.text("DISCUSSION  •  %ds") % 45, 18, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 62, 940, 28)).name = "MeetingTimerLabel"
	var index := 0
	for member in app.lobby_players:
		if not bool(member.get("alive", true)): continue
		var card := UI.make_panel(body, Rect2(30 + (index % 5) * 188, 102 + (index / 5) * 62, 180, 58), Data.SECTION_PANEL)
		avatar(card, member, Rect2(5, 7, 42, 44))
		var sleeping := bool(member.get("sleeping", false))
		var name_label := UI.make_child_label(card, str(member.get("name", "Player")) + ("  •  " + Lang.text("ASLEEP") if sleeping else ""), 14, Color("9a9a9a") if sleeping else Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(53, 3, 121, 52))
		name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		name_label.tooltip_text = name_label.text
		name_label.max_lines_visible = 2; name_label.clip_text = true
		if sleeping: card.modulate = Color("777777")
		index += 1
	var scroll := ScrollContainer.new()
	scroll.name = "MeetingChatScroll"
	scroll.position = Vector2(30, 232); scroll.size = Vector2(940, 254)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var chat := VBoxContainer.new()
	chat.name = "MeetingChatLog"
	chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat.add_theme_constant_override("separation", 7)
	scroll.add_child(chat)
	append_chat(app, -1, "Village", Lang.text("Discussion started. Share clues you've found."))
	var input := LineEdit.new()
	input.name = "MeetingChatInput"; input.placeholder_text = Lang.text("Type a message..."); input.max_length = 200
	input.position = Vector2(30, 492); input.size = Vector2(796, 48)
	input.add_theme_font_size_override("font_size", 20)
	input.editable = app.can_local_act()
	input.text_submitted.connect(func(_text: String): app._send_meeting_chat())
	body.add_child(input)
	var send := UI.make_button(body, Lang.text("SEND"), Callable(app, "_send_meeting_chat"), 138, 48, true)
	send.name = "SendMeetingChat"; send.position = Vector2(832, 492); send.disabled = not app.can_local_act()
	UI.make_child_label(body, Lang.text("Voting begins when the discussion timer ends."), 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 560, 940, 34))


static func append_chat(app: Control, peer_id: int, player_name: String, message: String) -> void:
	var chat := app.find_child("MeetingChatLog", true, false) as VBoxContainer
	if chat == null: return
	var own: bool = peer_id == app.network_manager.local_peer_id()
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(900, 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_END if own else BoxContainer.ALIGNMENT_BEGIN
	chat.add_child(row)
	var bubble := Panel.new()
	bubble.custom_minimum_size = Vector2(clampf(170.0 + message.length() * 4.8, 220.0, 680.0), 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("4b664c") if own else Color("3b3028")
	style.set_corner_radius_all(12)
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 7; style.content_margin_bottom = 7
	bubble.add_theme_stylebox_override("panel", style)
	row.add_child(bubble)
	var label := Label.new()
	label.text = player_name + "\n" + message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", int(preload("res://scripts/settings_store.gd").get_value("text_size")))
	label.add_theme_color_override("font_color", Data.CREAM)
	label.position = Vector2(10, 7)
	label.size = Vector2(bubble.custom_minimum_size.x - 20, maxf(48.0, ceilf(message.length() / 68.0) * 26.0 + 32.0))
	bubble.custom_minimum_size.y = label.size.y + 14
	bubble.add_child(label)
	chat.custom_minimum_size.y += bubble.custom_minimum_size.y + 7
	(chat.get_parent() as ScrollContainer).set_deferred("scroll_vertical", 1000000)

static func voting(app: Control, members: Array) -> void:
	var body := panel(app, Rect2(140, 32, 1000, 656))
	UI.make_child_label(body, Lang.text("VOTE FOR A PLAYER"), 25, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 18, 940, 42)).name = "MeetingHeadingLabel"
	UI.make_child_label(body, Lang.text("VOTING  •  %ds") % 20, 18, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 62, 940, 28)).name = "MeetingTimerLabel"
	UI.make_child_label(body, Lang.text("Votes received: %d/%d") % [app.network_votes_cast, app.network_alive_count], 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 94, 940, 26)).name = "VotesCastLabel"
	var index := 0
	for member in members:
		if not bool(member.get("alive", true)): continue
		var sleeping := bool(member.get("sleeping", false))
		var id := int(member.get("id", -1))
		var button := UI.make_button(body, "", Callable(app, "_select_network_vote").bind(id), 456, 70)
		button.name = "VoteTarget_%d" % id
		button.position = Vector2(32 + (index % 2) * 480, 128 + (index / 2) * 76)
		avatar(button, member, Rect2(10, 11, 48, 48))
		var title := UI.make_child_label(button, str(member.get("name", "Player")) + ("  •  " + Lang.text("ASLEEP") if sleeping else ""), 18, Color("888888") if sleeping else Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(70, 6, 372, 28))
		title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.clip_text = true; title.tooltip_text = title.text
		UI.make_child_label(button, str(member.get("character", "")), 16, Color("888888") if sleeping else Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(70, 36, 372, 28))
		button.disabled = sleeping or id == app.network_manager.local_peer_id() or not app.can_local_act()
		if sleeping: button.modulate = Color("777777")
		index += 1
	var skip := UI.make_button(body, Lang.text("SKIP VOTE"), Callable(app, "_submit_network_vote").bind(-1), 220, 48)
	skip.name = "SkipNetworkVote"; skip.position = Vector2(230, 518); skip.disabled = not app.can_local_act()
	var confirm := UI.make_button(body, Lang.text("CONFIRM VOTE"), Callable(app, "_submit_network_vote").bind(-2), 220, 48, true)
	confirm.name = "ConfirmNetworkVote"; confirm.position = Vector2(550, 518); confirm.disabled = true
	UI.make_child_label(body, "", 16, Color("d8edb2"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 578, 940, 28)).name = "VoteSubmissionLabel"
	UI.make_child_label(body, Lang.text("Confirm a player or Skip. Your submitted choice cannot be changed."), 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 616, 940, 28))
