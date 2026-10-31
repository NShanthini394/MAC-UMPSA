extends RefCounted
## Dedicated, modal meeting layouts in the game's 1280 × 720 UI canvas.
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const Powers = preload("res://scripts/nenek_powers.gd")

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
	UI.make_child_label(body, "EMERGENCY MEETING  •  DISCUSSION", 25, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 16, 940, 42))
	UI.make_child_label(body, "DISCUSSION  •  45s", 18, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 62, 940, 28)).name = "MeetingTimerLabel"
	var index := 0
	for member in app.lobby_players:
		if not Powers.is_active(member): continue
		var card := UI.make_panel(body, Rect2(30 + (index % 5) * 188, 102 + (index / 5) * 62, 180, 58), Data.SECTION_PANEL)
		avatar(card, member, Rect2(5, 7, 42, 44))
		var name_label := UI.make_child_label(card, str(member.get("name", "Player")), 16, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(53, 3, 121, 52))
		name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		name_label.tooltip_text = name_label.text
		name_label.max_lines_visible = 2; name_label.clip_text = true
		index += 1
	var chat := RichTextLabel.new()
	chat.name = "MeetingChatLog"
	chat.position = Vector2(30, 238); chat.size = Vector2(940, 240)
	chat.bbcode_enabled = false
	chat.scroll_active = true; chat.scroll_following = true
	chat.add_theme_font_size_override("normal_font_size", int(preload("res://scripts/settings_store.gd").get_value("text_size")))
	chat.add_theme_color_override("default_color", Data.CREAM)
	chat.text = "Discussion started. Share clues you have found."
	body.add_child(chat)
	var input := LineEdit.new()
	input.name = "MeetingChatInput"; input.placeholder_text = "Type a message…"; input.max_length = 200
	input.position = Vector2(30, 492); input.size = Vector2(796, 48)
	input.add_theme_font_size_override("font_size", 20)
	input.editable = app.can_local_act()
	input.text_submitted.connect(func(_text: String): app._send_meeting_chat())
	body.add_child(input)
	var send := UI.make_button(body, "SEND", Callable(app, "_send_meeting_chat"), 138, 48, true)
	send.name = "SendMeetingChat"; send.position = Vector2(832, 492); send.disabled = not app.can_local_act()
	UI.make_child_label(body, "Voting begins when the discussion timer ends.", 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 560, 940, 34))

static func voting(app: Control, members: Array) -> void:
	var body := panel(app, Rect2(140, 32, 1000, 656))
	UI.make_child_label(body, "VOTE FOR A PLAYER", 25, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 18, 940, 42))
	UI.make_child_label(body, "VOTING  •  20s", 18, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 62, 940, 28)).name = "MeetingTimerLabel"
	UI.make_child_label(body, "Votes received: %d/%d" % [app.network_votes_cast, app.network_alive_count], 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 94, 940, 26)).name = "VotesCastLabel"
	var index := 0
	for member in members:
		if not Powers.is_active(member): continue
		var id := int(member.get("id", -1))
		var button := UI.make_button(body, "", Callable(app, "_select_network_vote").bind(id), 456, 70)
		button.name = "VoteTarget_%d" % id
		button.position = Vector2(32 + (index % 2) * 480, 128 + (index / 2) * 76)
		avatar(button, member, Rect2(10, 11, 48, 48))
		var title := UI.make_child_label(button, str(member.get("name", "Player")), 18, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(70, 6, 372, 28))
		title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.clip_text = true; title.tooltip_text = title.text
		UI.make_child_label(button, str(member.get("character", "")), 16, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(70, 36, 372, 28))
		button.disabled = id == app.network_manager.local_peer_id() or not app.can_local_act()
		index += 1
	var skip := UI.make_button(body, "SKIP VOTE", Callable(app, "_submit_network_vote").bind(-1), 220, 48)
	skip.name = "SkipNetworkVote"; skip.position = Vector2(230, 518); skip.disabled = not app.can_local_act()
	var confirm := UI.make_button(body, "CONFIRM VOTE", Callable(app, "_submit_network_vote").bind(-2), 220, 48, true)
	confirm.name = "ConfirmNetworkVote"; confirm.position = Vector2(550, 518); confirm.disabled = true
	UI.make_child_label(body, "", 16, Color("d8edb2"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 578, 940, 28)).name = "VoteSubmissionLabel"
	UI.make_child_label(body, "Confirm a player or Skip. Your submitted choice cannot be changed.", 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 616, 940, 28))
