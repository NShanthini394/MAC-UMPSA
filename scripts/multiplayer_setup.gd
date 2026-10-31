extends RefCounted
## Code-only online hosting/joining; no provider account is needed for a guest.
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")


static func field(parent: Control, node_name: String, value: String, placeholder: String, rect: Rect2) -> LineEdit:
	var entry := LineEdit.new()
	entry.name = node_name; entry.text = value; entry.placeholder_text = placeholder
	entry.add_theme_font_size_override("font_size", 16)
	entry.position = rect.position; entry.size = rect.size
	parent.add_child(entry)
	return entry


static func show_join(app: Control) -> void:
	var shade := preload("res://scripts/fullscreen_shade.gd").new()
	shade.name = "JoinRoomCodeOverlay"
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app._screen_ui_parent().add_child(shade)
	var panel := UI.make_panel(shade.get_node("ShadeContent"), Rect2(360, 100, 560, 520), Color("24180f"))
	UI.make_child_label(panel, "JOIN A ROOM", 27, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 18, 510, 42))
	UI.make_child_label(panel, "Type the room code or scan the host's room QR.\nYour devices can use the same or different networks.", 15, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 64, 490, 48))
	UI.make_child_label(panel, "Player name", 14, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(50, 122, 460, 22))
	field(panel, "LobbyPlayerNameEntry", app.lobby_player_name, "Your name", Rect2(50, 148, 460, 36)).max_length = 20
	UI.make_child_label(panel, "Room code", 14, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(50, 212, 460, 22))
	var code := field(panel, "JoinCodeEntry", "", "5-CHARACTER CODE", Rect2(50, 240, 460, 46))
	code.max_length = 5; code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	code.text_submitted.connect(func(_value: String): app.call("_join_room_with_code"))
	var scan := UI.make_button(panel,"SCAN QR",Callable(app,"_scan_room_qr"),250,40)
	scan.name = "ScanRoomQrButton"; scan.position = Vector2(155,301)
	var status := UI.make_child_label(panel, "", 14, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 345, 490, 65))
	status.name = "JoinRoomStatusLabel"
	status.text = "Enter the host's code. Works on the same or different networks.\nAn internet connection is required."
	var join := UI.make_button(panel, "JOIN ROOM", Callable(app, "_join_room_with_code"), 205, 46, true)
	join.name = "JoinOnlineRoomButton"; join.position = Vector2(55, 430)
	var close := UI.make_button(panel, "CANCEL", Callable(app, "_cancel_join_room"), 205, 46)
	close.position = Vector2(300, 430)


static func build_host(app: Control) -> void:
	app.add_background(load(Data.MENU_ART))
	app.add_color_overlay(Color(0.04, 0.05, 0.055, 0.78))
	var panel := UI.make_panel(app._screen_ui_parent(), Rect2(280, 90, 720, 540), Color("24180f"))
	panel.name = "MultiplayerHostPanel"
	UI.make_child_label(panel, "PLAY WITH FRIENDS", 28, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(45, 18, 630, 42))
	var close := UI.make_button(panel, "×", Callable(app, "navigate_back"), 42, 42)
	close.name = "HostSetupCloseButton"; close.position = Vector2(662, 14)
	var preview := TextureRect.new()
	preview.texture = UI.make_map_texture(load(Data.map_art_path(app.selected_map)), Data.MAPS[app.selected_map]["region"])
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.position = Vector2(35, 92); preview.size = Vector2(300, 210)
	panel.add_child(preview)
	UI.make_child_label(panel, Data.MAPS[app.selected_map]["name"], 18, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 309, 300, 62))
	UI.make_child_label(panel, "Player name", 15, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(370, 100, 310, 26))
	field(panel, "LobbyPlayerNameEntry", app.lobby_player_name, "Your name", Rect2(370, 136, 310, 38)).max_length = 20
	var explanation := UI.make_child_label(panel, "", 15, Data.CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(370, 232, 310, 144))
	explanation.text = "Share the room code with your friends.\nWorks on the same or different networks.\n\n1–10 players · bots join after 2 minutes"
	var status := UI.make_child_label(panel, "No Google or Huawei account is required for this test.", 14, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 382, 650, 56))
	status.name = "CreateRoomStatusLabel"
	var host := UI.make_button(panel, "CREATE ROOM", Callable(app, "_host_selected_room"), 300, 48, true)
	host.name = "CreateOnlineRoomButton"; host.position = Vector2(210, 458)



static func show_created(app: Control) -> void:
	var shade := preload("res://scripts/fullscreen_shade.gd").new()
	shade.name = "CreateRoomOverlay"
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app._screen_ui_parent().add_child(shade)
	var panel := UI.make_panel(shade.get_node("ShadeContent"), Rect2(350, 110, 580, 500), Color("24180f"))
	UI.make_child_label(panel, "ONLINE ROOM CREATED" if app.internet_mode else "WI-FI ROOM CREATED", 27, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 20, 530, 42))
	UI.make_child_label(panel, "Share this code with your friends." if app.internet_mode else "Share this code with friends on the same Wi-Fi.", 15, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 70, 510, 36))
	UI.make_child_label(panel, app.room_code, 48, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 118, 510, 70))
	UI.make_child_label(panel, "Friends only need this room code.\nWorks on the same or different networks." if app.internet_mode else "Friends only need this room code.\nTheir game will find your device automatically.", 17, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 204, 510, 64))
	UI.make_child_label(panel, "Keep the game open. Empty slots fill with bots after 2 minutes.\nAn internet connection is required on every device." if app.internet_mode else "Allow the game on Private networks if Windows asks.\nKeep the host's game open. Empty slots fill with bots after 2 minutes.", 14, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 277, 510, 58))
	var copy := UI.make_button(panel, "COPY ROOM CODE", Callable(app, "_copy_created_room_code"), 205, 48)
	copy.name = "CopyCreatedRoomCodeButton"; copy.position = Vector2(55, 362)
	var enter := UI.make_button(panel, "ENTER WAITING ROOM", Callable(app, "_enter_waiting_room"), 245, 48, true)
	enter.name = "EnterWaitingRoomButton"; enter.position = Vector2(280, 362)
	if app.internet_mode:
		var qr := UI.make_button(panel,"SHOW ROOM QR",Callable(app,"_show_room_qr"),250,44,true)
		qr.name = "ShowRoomQrButton"; qr.position = Vector2(165,425)


static func show_disconnected(app: Control, message: String) -> void:
	var panel := UI.make_panel(app._screen_ui_parent(), Rect2(360, 205, 560, 310), Color("24180f"))
	panel.name = "ConnectionLostOverlay"
	UI.make_child_label(panel, "CONNECTION LOST", 25, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 20, 510, 42))
	UI.make_child_label(panel, message, 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(40, 88, 480, 100))
	var close := UI.make_button(panel, "OK", func(): panel.queue_free(), 160, 44, true)
	close.position = Vector2(200, 225)

