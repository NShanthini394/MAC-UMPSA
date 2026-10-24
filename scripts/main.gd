extends Control
## Playable local practice build for Kampung Legenda: Misteri Tiga Rumah.

const MENU_ART := "res://assets/ui/main_menu.png"
const WAITING_ROOM_ART := "res://assets/ui/waiting_room.png"
const MAP_ART := "res://assets/maps/palace_village_maps.png"
const CAST_ART := "res://assets/characters/folklore_cast.png"
const INK := Color("21170f")
const CREAM := Color("fff0cf")
const GOLD := Color("f7c35a")
const PANEL := Color("241b18", 0.94)

const CHARACTERS := [
	"Puteri Gunung Ledang", "Pak Kaduk", "Badang", "Mahsuri", "Pak Pandir",
	"Bawang Putih", "Bawang Merah", "Raja Bersiung", "Nenek Kebayan",
	"Orang Kampung Lelaki", "Orang Kampung Perempuan"
]

const MAP_CHARACTERS := {
	"Istana Puteri Gunung Ledang": ["Puteri Gunung Ledang", "Pak Kaduk", "Badang", "Mahsuri", "Raja Bersiung", "Nenek Kebayan", "Orang Kampung Lelaki", "Orang Kampung Perempuan"],
	"Rumah Pak Kaduk": ["Pak Kaduk", "Pak Pandir", "Badang", "Bawang Putih", "Bawang Merah", "Nenek Kebayan", "Orang Kampung Lelaki", "Orang Kampung Perempuan"],
	"Rumah Mahsuri": ["Mahsuri", "Puteri Gunung Ledang", "Pak Pandir", "Bawang Putih", "Bawang Merah", "Nenek Kebayan", "Orang Kampung Lelaki", "Orang Kampung Perempuan"]
}

const CHARACTER_PORTRAITS := {
	"Puteri Gunung Ledang": "res://assets/characters/portraits/puteri_gunung_ledang.png",
	"Pak Kaduk": "res://assets/characters/portraits/pak_kaduk.png",
	"Badang": "res://assets/characters/portraits/badang.png",
	"Mahsuri": "res://assets/characters/portraits/mahsuri.png",
	"Pak Pandir": "res://assets/characters/portraits/pak_pandir.png",
	"Bawang Putih": "res://assets/characters/portraits/bawang_putih.png",
	"Bawang Merah": "res://assets/characters/portraits/bawang_merah.png",
	"Raja Bersiung": "res://assets/characters/portraits/raja_bersiung.png",
	"Nenek Kebayan": "res://assets/characters/portraits/nenek_kebayan.png",
	"Orang Kampung Lelaki": "res://assets/characters/portraits/orang_kampung_lelaki.png",
	"Orang Kampung Perempuan": "res://assets/characters/portraits/orang_kampung_perempuan.png"
}

const CHARACTER_CLUES := {
	"Puteri Gunung Ledang": ["Golden jewelry box", "Purple silk cloth", "Floral medallion"],
	"Pak Kaduk": ["Rooster feather", "Old playing cards", "Muddy footprints"],
	"Badang": ["Small monkey", "Headband cloth", "Scratched boulder"],
	"Mahsuri": ["White dove feather", "Torn handwritten letter", "Perfume bottle"],
	"Pak Pandir": ["Village frog", "Worn fishing net", "Small muddy footprints"],
	"Bawang Putih": ["Garlic bulb", "White handkerchief", "Flower-shaped locket"],
	"Bawang Merah": ["Red onion", "Red cloth", "Cracked mirror"],
	"Raja Bersiung": ["Fang", "Blood-stained cloth", "Carved crown"],
	"Nenek Kebayan": ["Old rattan basket", "Jasmine flower", "Delicate footprints"],
	"Orang Kampung Lelaki": ["Straw hat", "Wooden pipe", "Rice and vegetables"],
	"Orang Kampung Perempuan": ["Vegetable basket", "Floral batik handkerchief", "Muddy sandals"]
}

const MAPS := [
	{"name": "Istana Puteri Gunung Ledang", "description": "Explore palace halls and gardens\non the mountain path.", "region": Rect2(0, 0, 1420, 505)},
	{"name": "Rumah Pak Kaduk", "description": "Search the kampung yard and paddy field\nfor the rooster arena.", "region": Rect2(10, 515, 745, 440)},
	{"name": "Rumah Mahsuri", "description": "Follow village paths from Mahsuri's home\nto her garden.", "region": Rect2(780, 515, 748, 440)}
]

const TASKS := {
	"Rumah Mahsuri": [
		{"name":"Gather five story clues", "place":"Village path", "prompt":"Which item belongs in the evidence box?", "choices":["Torn letter", "Iron anchor", "Snow globe"], "answer":0},
		{"name":"Hear three village stories", "place":"Village elder", "prompt":"Which detail should you ask the villagers about?", "choices":["Mahsuri's story", "A space launch", "A desert caravan"], "answer":0},
		{"name":"Collect healer's medicine", "place":"Healer's house", "prompt":"Choose the healer's supplies.", "choices":["Herbal medicine", "Silver coins", "A royal crown"], "answer":0},
		{"name":"Deliver medicine to the family", "place":"Mahsuri's house", "prompt":"Who needs the medicine delivery?", "choices":["Mahsuri's family", "The palace guards", "The rooster"], "answer":0},
		{"name":"Collect six white flowers", "place":"Flower garden", "prompt":"Which flowers belong at the tomb?", "choices":["White jasmine", "Red hibiscus", "Blue orchids"], "answer":0},
		{"name":"Match belongings to their owners", "place":"Gathering hall", "prompt":"Match the misplaced letter to its owner.", "choices":["Mahsuri", "Badang", "Pak Kaduk"], "answer":0},
		{"name":"Find the key and unlock the chest", "place":"Storage room", "prompt":"The small brass key fits which object?", "choices":["Locked chest", "Garden gate", "Water well"], "answer":0},
		{"name":"Place flowers at Mahsuri's tomb", "place":"Mahsuri's tomb", "prompt":"Complete the remembrance ritual.", "choices":["Lay down the flowers", "Take the flowers home", "Hide the flowers"], "answer":0}
	],
	"Rumah Pak Kaduk": [
		{"name":"Find five food pieces", "place":"Village yard", "prompt":"Choose food for the rooster.", "choices":["Grain", "A glass marble", "A flower pot"], "answer":0},
		{"name":"Feed Pak Kaduk's rooster", "place":"Chicken coop", "prompt":"What should you give the rooster?", "choices":["The grain you collected", "A playing card", "A lantern"], "answer":0},
		{"name":"Find three clothing repair items", "place":"House storage", "prompt":"Choose a useful repair item.", "choices":["Thread and cloth", "A cooking pot", "A compass"], "answer":0},
		{"name":"Repair Pak Kaduk's clothes", "place":"Main house", "prompt":"Where does this cloth patch belong?", "choices":["The torn sleeve", "The roof", "The chicken coop"], "answer":0},
		{"name":"Collect five rooster feathers", "place":"Paddy path", "prompt":"Follow the feather trail.", "choices":["Feather by the paddy", "Shell by the river", "Leaf by the gate"], "answer":0},
		{"name":"Find the rooster at the arena", "place":"Competition arena", "prompt":"Listen for the rooster near the arena.", "choices":["Call the rooster", "Ring the palace bell", "Open the tomb"], "answer":0},
		{"name":"Complete the arena timing challenge", "place":"Arena gate", "prompt":"Pick the steady moment to enter.", "choices":["When the marker reaches the center", "Before the count begins", "After the arena closes"], "answer":0},
		{"name":"Collect the scattered arena coins", "place":"Arena floor", "prompt":"Gather the coins left after the competition.", "choices":["Pick up the coins", "Leave the arena", "Give them to the rooster"], "answer":0}
	],
	"Istana Puteri Gunung Ledang": [
		{"name":"Find five route markers", "place":"Palace garden", "prompt":"Which marker points toward the mountain?", "choices":["The carved trail marker", "A kitchen spoon", "A playing card"], "answer":0},
		{"name":"Gather food and water", "place":"Palace kitchen", "prompt":"Choose a travel supply.", "choices":["Food and water", "A silk curtain", "An empty chest"], "answer":0},
		{"name":"Navigate the forest crossroads", "place":"Forest crossing", "prompt":"Follow the marked path at the fork.", "choices":["Take the marked mountain trail", "Walk into the river", "Return to the kitchen"], "answer":0},
		{"name":"Find seven golden trays", "place":"Royal hall", "prompt":"Which tray is part of the royal request?", "choices":["Golden serving tray", "Wooden fishing net", "Clay flower pot"], "answer":0},
		{"name":"Catch seven glowing fireflies", "place":"Lantern garden", "prompt":"Tap the firefly while it glows.", "choices":["Catch the glowing firefly", "Chase the shadow", "Wait for sunrise"], "answer":0},
		{"name":"Collect the requested symbolic materials", "place":"Princess's chamber", "prompt":"Which object is one of the Princess's symbols?", "choices":["Floral medallion", "Iron shovel", "Fishing basket"], "answer":0},
		{"name":"Deliver the proposal letter", "place":"Sultan's camp", "prompt":"Take the letter to the meeting place.", "choices":["Deliver the sealed letter", "Leave it in the forest", "Give it to the cook"], "answer":0},
		{"name":"Follow the markers to the Princess", "place":"Mountain overlook", "prompt":"Complete the final conversation.", "choices":["Speak with Puteri Gunung Ledang", "Return to the arena", "Hide the route markers"], "answer":0}
	]
}

const TASK_POINTS := [Vector2(370, 235), Vector2(530, 235), Vector2(880, 245), Vector2(1050, 370), Vector2(880, 530), Vector2(625, 555), Vector2(350, 520), Vector2(340, 390)]
const TASK_STEPS := {
	"Rumah Mahsuri": [5, 3, 1, 1, 6, 3, 1, 1],
	"Rumah Pak Kaduk": [5, 1, 3, 1, 5, 1, 1, 1],
	"Istana Puteri Gunung Ledang": [5, 1, 1, 7, 7, 1, 1, 1]
}
const NPC_NAMES := ["Pak Pandir", "Bawang Putih", "Badang", "Mahsuri"]
const NPC_POINTS := [Vector2(430, 330), Vector2(760, 300), Vector2(990, 475), Vector2(520, 460)]

var current_screen := "menu"
var selected_map := 0
var lobby_player_name := "Player 1"
var waiting_elapsed := 0.0
var selected_character := ""
var character_reservations: Dictionary = {}
var impostor_character := ""
var player_is_impostor := false
var player_position := Vector2(640, 390)
var move_vector := Vector2.ZERO
var completed_tasks: Array[int] = []
var task_progress: Array[int] = []
var collected_clues: Array[String] = []
var task_overlay_index := -1
var last_notice := ""
var last_notice_time := 0.0
var audio_muted := false
var dead_npcs: Array[String] = []
var rng := RandomNumberGenerator.new()
var map_image: Texture2D


func _ready() -> void:
	rng.randomize()
	build_menu()


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_notice_time > 2.4:
		var notice_label := get_node_or_null("NoticeLabel") as Label
		if notice_label: notice_label.text = ""
		var menu_notice := get_node_or_null("MenuNoticeLabel") as Label
		if menu_notice: menu_notice.text = ""
	if current_screen == "waiting_room":
		waiting_elapsed += delta
		var timer_label := find_child("LobbyStatusLabel", true, false) as Label
		if timer_label:
			var elapsed := int(waiting_elapsed)
			timer_label.text = "1 / 5 PLAYERS   •   WAITING %02d:%02d" % [floori(float(elapsed) / 60.0), elapsed % 60]
		return
	if current_screen != "game" or task_overlay_index >= 0:
		return
	var direction := move_vector
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if direction.length() > 1.0: direction = direction.normalized()
	player_position += direction * delta * 250.0
	player_position.x = clampf(player_position.x, 72.0, 1205.0)
	player_position.y = clampf(player_position.y, 135.0, 670.0)
	var pawn := get_node_or_null("Pawn") as Control
	if pawn:
		pawn.position = player_position - Vector2(20, 24)


func _unhandled_input(event: InputEvent) -> void:
	if current_screen == "game" and task_overlay_index < 0 and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		interact_nearest()


func clear_screen(screen_name: String) -> void:
	current_screen = screen_name
	for child in get_children(): child.queue_free()
	await get_tree().process_frame


func build_menu() -> void:
	await clear_screen("menu")
	add_background(load(MENU_ART))
	add_color_overlay(Color(0.05, 0.07, 0.08, 0.32))
	# The menu artwork already contains the full title plaque and subtitle. Avoid
	# drawing a second title label, which was clipped against the bottom edge.
	var menu_panel := make_panel(Rect2(465, 255, 350, 395), Color(0.13, 0.075, 0.045, 0.91))
	var menu_buttons := ["PLAY", "HOW TO PLAY", "SETTINGS", "EXIT"]
	for i in menu_buttons.size():
		var btn := make_button(menu_panel, menu_buttons[i], Callable(self, "_menu_action").bind(i), 300, 54, i == 0)
		btn.position = Vector2(25, 25 + i * 85)
	build_menu_icon_buttons()
	var badge := make_label("LOCAL PRACTICE  •  NETWORK ROOMS NOT CONNECTED", 14, Color("f7d9a2"), HORIZONTAL_ALIGNMENT_CENTER)
	badge.position = Vector2(300, 680); badge.size = Vector2(680, 24)
	var menu_notice := make_label("", 14, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	menu_notice.name = "MenuNoticeLabel"; menu_notice.position = Vector2(900, 78); menu_notice.size = Vector2(350, 28)


func build_menu_icon_buttons() -> void:
	# These transparent hit targets sit over the gear, music and help artwork.
	_make_art_icon_button(Rect2(1072, 22, 54, 54), "Settings", Callable(self, "show_settings").bind("menu"))
	var music := _make_art_icon_button(Rect2(1137, 22, 52, 54), "Toggle music and sound", Callable(self, "_toggle_audio"))
	music.name = "MenuMusicButton"
	var mute_slash := ColorRect.new()
	mute_slash.name = "AudioMutedSlash"
	mute_slash.color = Color("ff5b50")
	mute_slash.position = Vector2(9, 24); mute_slash.size = Vector2(34, 5)
	mute_slash.pivot_offset = mute_slash.size / 2; mute_slash.rotation_degrees = -45
	mute_slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mute_slash.visible = audio_muted
	music.add_child(mute_slash)
	_make_art_icon_button(Rect2(1200, 22, 54, 54), "How to play", Callable(self, "show_how_to_play").bind("menu"))


func _make_art_icon_button(rect: Rect2, hint: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position; button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = hint
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "pressed", "hover", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(0, 0, 0, 0)
		if state == "hover": style.bg_color = Color(1, 0.82, 0.42, 0.18)
		if state == "pressed": style.bg_color = Color(1, 0.82, 0.42, 0.28)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(callback)
	add_child(button)
	return button


func _toggle_audio() -> void:
	audio_muted = not audio_muted
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0: AudioServer.set_bus_mute(master_bus, audio_muted)
	var music_button := get_node_or_null("MenuMusicButton") as Button
	if music_button: music_button.tooltip_text = "Turn music and sound on" if audio_muted else "Turn music and sound off"
	var mute_slash := get_node_or_null("MenuMusicButton/AudioMutedSlash") as ColorRect
	if mute_slash: mute_slash.visible = audio_muted
	var settings_audio := get_node_or_null("SettingsAudioButton") as Button
	if settings_audio: settings_audio.text = "UNMUTE AUDIO" if audio_muted else "MUTE AUDIO"
	if current_screen == "menu": show_menu_notice("Music and sound muted." if audio_muted else "Music and sound enabled.")


func show_menu_notice(message: String) -> void:
	last_notice_time = Time.get_ticks_msec() / 1000.0
	var label := get_node_or_null("MenuNoticeLabel") as Label
	if label: label.text = message


func _menu_action(index: int) -> void:
	match index:
		0: build_map_select()
		1: show_how_to_play("menu")
		2: show_settings("menu")
		3: get_tree().quit()


func build_map_select() -> void:
	await clear_screen("map_select")
	add_background(load(MENU_ART))
	add_color_overlay(Color(0.04, 0.07, 0.08, 0.76))
	var title := make_label("Choose a Map", 42, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(250, 35); title.size = Vector2(780, 58)
	var atlas := load(MAP_ART) as Texture2D
	for i in MAPS.size():
		var card := make_panel(Rect2(40 + i * 400, 120, 380, 500), Color(0.12, 0.09, 0.07, 0.97))
		var preview := TextureRect.new()
		preview.texture = make_map_texture(atlas, MAPS[i]["region"])
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.position = Vector2(12, 12); preview.size = Vector2(356, 230)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		_make_child_label(card, MAPS[i]["name"], 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(20, 252, 340, 42))
		var description := _make_child_label(card, MAPS[i]["description"], 14, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(26, 298, 328, 66))
		description.clip_contents = true
		var choose := make_button(card, "SELECT MAP", Callable(self, "_choose_map").bind(i), 316, 50, true)
		choose.position = Vector2(32, 422)
	var back := make_button(self, "BACK", Callable(self, "build_menu"), 125, 44)
	back.position = Vector2(36, 34)


func _choose_map(index: int) -> void:
	selected_map = index
	selected_character = ""
	character_reservations.clear()
	waiting_elapsed = 0.0
	build_waiting_room()


func build_waiting_room() -> void:
	await clear_screen("waiting_room")
	add_background(load(WAITING_ROOM_ART))
	add_color_overlay(Color(0.025, 0.025, 0.025, 0.38))

	var header := make_panel(Rect2(40, 28, 1200, 86), Color(0.11, 0.075, 0.045, 0.94))
	_make_child_label(header, "WAITING ROOM", 30, GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(24, 12, 300, 58))
	_make_child_label(header, "MAP  •  " + MAPS[selected_map]["name"], 19, CREAM, HORIZONTAL_ALIGNMENT_LEFT, Rect2(350, 18, 480, 48))
	var status := _make_child_label(header, "1 / 5 PLAYERS   •   WAITING 00:00", 17, Color("d8edb2"), HORIZONTAL_ALIGNMENT_RIGHT, Rect2(840, 18, 330, 48))
	status.name = "LobbyStatusLabel"

	var map_panel := make_panel(Rect2(55, 140, 420, 430), Color(0.12, 0.08, 0.055, 0.96))
	_make_child_label(map_panel, "YOUR SELECTED MAP", 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(20, 14, 380, 34))
	var map_preview := TextureRect.new()
	map_preview.texture = make_map_texture(load(MAP_ART), MAPS[selected_map]["region"])
	map_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_preview.position = Vector2(18, 58); map_preview.size = Vector2(384, 222)
	map_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_preview)
	_make_child_label(map_panel, "Waiting for more players to join this map.", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 298, 372, 42))
	_make_child_label(map_panel, "Network rooms are not connected in this build.", 13, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 345, 372, 44))

	var players_panel := make_panel(Rect2(500, 140, 725, 430), Color(0.12, 0.08, 0.055, 0.96))
	_make_child_label(players_panel, "PLAYERS IN ROOM", 18, GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(22, 14, 420, 34))
	_make_child_label(players_panel, "1 PLAYER HERE  •  4 OPEN SLOTS", 14, CREAM, HORIZONTAL_ALIGNMENT_RIGHT, Rect2(430, 14, 270, 34))
	for i in 5:
		var slot := _make_child_panel(players_panel, Rect2(22 + i * 138, 64, 124, 260), Color(0.17, 0.12, 0.085, 0.96))
		if i == 0:
			_add_player_avatar(slot)
			var name_entry := LineEdit.new()
			name_entry.name = "LobbyNameEntry"
			name_entry.text = lobby_player_name
			name_entry.placeholder_text = "Your name"
			name_entry.max_length = 20
			name_entry.position = Vector2(8, 174); name_entry.size = Vector2(108, 34)
			name_entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_entry.add_theme_font_size_override("font_size", 14)
			name_entry.add_theme_color_override("font_color", CREAM)
			var field_style := StyleBoxFlat.new()
			field_style.bg_color = Color("35271c"); field_style.border_color = Color("c5904b")
			field_style.set_border_width_all(1); field_style.set_corner_radius_all(7)
			field_style.content_margin_left = 4; field_style.content_margin_right = 4
			name_entry.add_theme_stylebox_override("normal", field_style)
			name_entry.add_theme_stylebox_override("focus", field_style)
			name_entry.text_changed.connect(_on_lobby_name_changed)
			slot.add_child(name_entry)
			_make_child_label(slot, "YOU  •  HOST", 12, Color("d8edb2"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(8, 214, 108, 26))
		else:
			var empty_avatar := _make_child_panel(slot, Rect2(28, 30, 68, 68), Color(0.20, 0.17, 0.13, 1.0))
			empty_avatar.add_theme_stylebox_override("panel", _circle_style(Color(0.20, 0.17, 0.13, 1.0), Color("8d785f")))
			_make_child_label(slot, "+", 34, Color("b8a58b"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(28, 33, 68, 60))
			_make_child_label(slot, "OPEN SLOT", 12, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(7, 120, 110, 30))
			_make_child_label(slot, "Waiting for\na player", 12, Color("a99b86"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(8, 155, 108, 48))

	var back := make_button(self, "CHANGE MAP", Callable(self, "build_map_select"), 210, 48)
	back.position = Vector2(55, 610)
	var next := make_button(self, "CHOOSE CHARACTER", Callable(self, "build_character_select"), 270, 48, true)
	next.position = Vector2(955, 610)
	var local_note := make_label("LOCAL LOBBY PREVIEW  •  MULTIPLAYER JOINING IS NOT CONNECTED YET", 13, Color("f7d9a2"), HORIZONTAL_ALIGNMENT_CENTER)
	local_note.position = Vector2(300, 620); local_note.size = Vector2(680, 28)


func _add_player_avatar(parent: Control) -> void:
	var avatar_bg := _make_child_panel(parent, Rect2(16, 10, 92, 100), Color(0.12, 0.18, 0.20, 1.0))
	avatar_bg.add_theme_stylebox_override("panel", _circle_style(Color("283a38"), Color("d3a24e")))
	_make_child_panel(parent, Rect2(38, 64, 48, 34), Color("734c77"))
	_make_child_panel(parent, Rect2(41, 34, 42, 48), Color("e8b58a"))
	_make_child_panel(parent, Rect2(39, 29, 46, 20), Color("30231d"))
	_make_child_panel(parent, Rect2(49, 53, 5, 5), Color("251a17"))
	_make_child_panel(parent, Rect2(69, 53, 5, 5), Color("251a17"))
	_make_child_label(parent, "PLAYER AVATAR", 10, Color("d6c5aa"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(8, 112, 108, 22))


func _on_lobby_name_changed(new_name: String) -> void:
	lobby_player_name = new_name.strip_edges()


func _circle_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill; style.border_color = border
	style.set_border_width_all(2); style.set_corner_radius_all(48)
	return style


func _make_child_panel(parent: Control, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new(); panel.position = rect.position; panel.size = rect.size
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = Color("8d6436")
	style.set_border_width_all(1); style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func build_character_select() -> void:
	await clear_screen("character_select")
	add_background(load(MENU_ART)); add_color_overlay(Color(0.035, 0.055, 0.06, 0.86))
	_make_child_label(self, "CHOOSE YOUR CHARACTER", 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(250, 16, 780, 48))
	_make_child_label(self, MAPS[selected_map]["name"] + "  •  8 CHARACTERS", 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(270, 65, 740, 32))
	var roster: Array = MAP_CHARACTERS[MAPS[selected_map]["name"]]
	for i in roster.size():
		var character: String = roster[i]
		var col := i % 4; var row := floori(float(i) / 4.0)
		var card := make_panel(Rect2(46 + col * 298, 112 + row * 250, 286, 230), Color(0.13, 0.085, 0.055, 0.97))
		var portrait_frame := _make_child_panel(card, Rect2(10, 12, 102, 164), Color(0.10, 0.075, 0.055, 1.0))
		var portrait := TextureRect.new()
		portrait.texture = load(CHARACTER_PORTRAITS[character])
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.position = Vector2(12, 14); portrait.size = Vector2(98, 160)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_frame.add_child(portrait)
		_make_child_label(card, character, 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(118, 26, 158, 58))
		_make_child_label(card, "FOLKLORE CHARACTER", 10, Color("d8b974"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(118, 91, 158, 24))
		var reserved := character_reservations.has(character)
		var is_selected := selected_character == character
		var button_text := "SELECTED" if is_selected else ("TAKEN" if reserved else "SELECT")
		var select := make_button(card, button_text, Callable(self, "_select_character").bind(character), 150, 42, is_selected)
		select.position = Vector2(122, 145)
		select.disabled = is_selected or reserved
		if reserved: select.tooltip_text = "Selected by " + str(character_reservations[character])
	var selection_text := selected_character if not selected_character.is_empty() else "Choose one character"
	_make_child_label(self, "Selected: " + selection_text, 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(290, 625, 520, 30))
	var start := make_button(self, "START PRACTICE", Callable(self, "start_practice"), 230, 48, true)
	start.position = Vector2(1000, 632); start.disabled = selected_character.is_empty()
	var back := make_button(self, "BACK TO ROOM", Callable(self, "build_waiting_room"), 190, 46)
	back.position = Vector2(36, 632)
	_make_child_label(self, "Characters reserved by other players will be unavailable when multiplayer is connected.", 12, Color("ead6b9"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(330, 674, 620, 22))


func _select_character(character: String) -> void:
	if character_reservations.has(character): return
	selected_character = character
	build_character_select()


func update_character_reservations(reservations: Dictionary) -> void:
	character_reservations = reservations.duplicate()
	if character_reservations.has(selected_character): selected_character = ""
	if current_screen == "character_select": build_character_select()


func _character_sigil(index: int) -> String:
	return ["♛", "🐓", "✦", "❀", "🐸", "♧", "✿", "♜", "☾", "⌂", "❀"][index]


func start_practice() -> void:
	completed_tasks.clear(); collected_clues.clear(); dead_npcs.clear()
	task_progress.clear()
	player_position = Vector2(640, 395)
	var tasks: Array = TASKS[MAPS[selected_map]["name"]]
	for i in tasks.size():
		completed_tasks.append(0)
		task_progress.append(0)
	player_is_impostor = rng.randi_range(0, 4) == 0
	if player_is_impostor:
		impostor_character = selected_character
	else:
		var available := NPC_NAMES.filter(func(c: String) -> bool: return c != selected_character)
		impostor_character = available[rng.randi_range(0, available.size() - 1)]
	build_game()
	show_notice("You are the Impostor. Secret identity: Nenek Kebayan." if player_is_impostor else "You are a Villager. Complete tasks and find the Impostor.")


func build_game() -> void:
	await clear_screen("game")
	map_image = make_map_texture(load(MAP_ART), MAPS[selected_map]["region"])
	var map_bg := TextureRect.new(); map_bg.texture = map_image; map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; map_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; map_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(map_bg)
	var shade := ColorRect.new(); shade.color = Color(0.04, 0.04, 0.03, 0.22); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(shade)
	var header := make_panel(Rect2(12, 10, 1256, 56), Color(0.11, 0.075, 0.045, 0.92))
	var title := make_label(MAPS[selected_map]["name"], 19, GOLD)
	title.position = Vector2(18, 12); title.size = Vector2(440, 32); title.reparent(header, false)
	var role := make_label(("IMPOSTOR" if player_is_impostor else "VILLAGER") + "  •  " + selected_character, 15, Color("fff0cf"))
	role.position = Vector2(565, 14); role.size = Vector2(520, 28); role.reparent(header, false)
	var progress := make_label("TASKS  %d / 8    •    CLUES  %d / 3" % [completed_tasks.count(1), collected_clues.size()], 14, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	progress.name = "ProgressLabel"; progress.position = Vector2(1010, 12); progress.size = Vector2(225, 32); progress.reparent(header, false)
	var task_panel := make_panel(Rect2(16, 86, 284, 421), Color(0.12, 0.09, 0.06, 0.91))
	var task_title := make_label("VILLAGE TASKS", 17, GOLD)
	task_title.position = Vector2(16, 12); task_title.size = Vector2(250, 27); task_title.reparent(task_panel, false)
	var tasks: Array = TASKS[MAPS[selected_map]["name"]]
	for i in tasks.size():
		var count_text := "" if completed_tasks[i] == 1 else " (%d/%d)" % [task_progress[i], TASK_STEPS[MAPS[selected_map]["name"]][i]]
		var label := make_label(("✓ " if completed_tasks[i] == 1 else "◇ ") + str(tasks[i]["name"]) + count_text, 13, Color("d8edb2") if completed_tasks[i] == 1 else CREAM)
		label.position = Vector2(16, 50 + i * 42); label.size = Vector2(254, 39); label.reparent(task_panel, false)
	for i in TASK_POINTS.size():
		var place: Button = make_button(self, "✦ " + str(tasks[i]["place"]), Callable(self, "_travel_hint").bind(i), 148, 34)
		place.position = TASK_POINTS[i]; place.add_theme_font_size_override("font_size", 11)
		place.modulate = Color(1, 1, 1, 0.9)
	# The gong is a separate interaction and never counts as a clue or task.
	var gong := make_button(self, "◉ GONG", Callable(self, "call_meeting"), 104, 38, true)
	gong.position = Vector2(586, 106)
	for i in NPC_NAMES.size():
		if dead_npcs.has(NPC_NAMES[i]): continue
		var npc := make_button(self, "● " + NPC_NAMES[i], Callable(self, "_travel_npc").bind(i), 142, 32)
		npc.position = NPC_POINTS[i]; npc.add_theme_font_size_override("font_size", 11)
	# Randomized, non-task identity evidence; these are selected for the impostor's visual character.
	var character_clues: Array = CHARACTER_CLUES[impostor_character]
	var clue_points := [Vector2(335, 320), Vector2(720, 520), Vector2(1065, 265)]
	for i in 3:
		if collected_clues.has(character_clues[i]): continue
		var clue := make_button(self, "⌕ CLUE", Callable(self, "_travel_clue").bind(i), 84, 32)
		clue.position = clue_points[i]; clue.add_theme_font_size_override("font_size", 11)
	var pawn := make_panel(Rect2(player_position - Vector2(20, 24), Vector2(40, 48)), Color("f5bc51"))
	pawn.name = "Pawn"
	var pawn_label := make_label("YOU", 12, INK, HORIZONTAL_ALIGNMENT_CENTER)
	pawn_label.position = Vector2(1, 13); pawn_label.size = Vector2(38, 20); pawn_label.reparent(pawn, false)
	var notice := make_label("", 15, Color("fff3cd"), HORIZONTAL_ALIGNMENT_CENTER)
	notice.name = "NoticeLabel"; notice.position = Vector2(310, 612); notice.size = Vector2(660, 28)
	build_control_bar()
	var leave := make_button(self, "MENU", Callable(self, "build_menu"), 88, 36)
	leave.position = Vector2(1180, 665)


func build_control_bar() -> void:
	var pad := make_panel(Rect2(20, 550, 186, 137), Color(0.09, 0.075, 0.055, 0.82))
	var up := make_button(pad, "▲", Callable(self, "_set_move").bind(Vector2.UP), 46, 38)
	up.position = Vector2(70, 8); up.button_down.connect(func(): _set_move(Vector2.UP)); up.button_up.connect(_stop_move)
	var left := make_button(pad, "◀", Callable(self, "_set_move").bind(Vector2.LEFT), 48, 38)
	left.position = Vector2(18, 50); left.button_down.connect(func(): _set_move(Vector2.LEFT)); left.button_up.connect(_stop_move)
	var down := make_button(pad, "▼", Callable(self, "_set_move").bind(Vector2.DOWN), 48, 38)
	down.position = Vector2(70, 91); down.button_down.connect(func(): _set_move(Vector2.DOWN)); down.button_up.connect(_stop_move)
	var right := make_button(pad, "▶", Callable(self, "_set_move").bind(Vector2.RIGHT), 48, 38)
	right.position = Vector2(122, 50); right.button_down.connect(func(): _set_move(Vector2.RIGHT)); right.button_up.connect(_stop_move)
	var interact := make_button(self, "INTERACT  [E]", Callable(self, "interact_nearest"), 164, 46, true)
	interact.position = Vector2(1005, 605)
	var inspect := make_button(self, "INSPECT CLUE", Callable(self, "inspect_nearest_clue"), 164, 42)
	inspect.position = Vector2(1005, 657)
	var journal := make_button(self, "CLUE JOURNAL", Callable(self, "show_journal"), 156, 38)
	journal.position = Vector2(825, 662)
	if player_is_impostor:
		var kill := make_button(self, "ELIMINATE", Callable(self, "eliminate_nearest"), 136, 42, true)
		kill.position = Vector2(620, 664)


func interact_nearest() -> void:
	var task_index := _nearest_index(TASK_POINTS, 110.0)
	if task_index >= 0:
		if completed_tasks[task_index] == 1: show_notice("That task is already complete."); return
		open_task(task_index); return
	if player_position.distance_to(Vector2(640, 120)) < 100.0:
		call_meeting(); return
	if _nearest_index(NPC_POINTS, 90.0) >= 0:
		show_notice("The villagers look uneasy. Check the clue journal before accusing anyone."); return
	show_notice("Move closer to a marked task, villager or gong.")


func open_task(index: int) -> void:
	task_overlay_index = index
	var task: Dictionary = TASKS[MAPS[selected_map]["name"]][index]
	var overlay := make_panel(Rect2(345, 154, 590, 408), Color(0.13, 0.085, 0.05, 0.98))
	overlay.name = "TaskOverlay"
	var title := make_label(str(task["name"]), 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(24, 20); title.size = Vector2(542, 54); title.reparent(overlay, false)
	var instruction := make_label(str(task["prompt"]), 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	instruction.position = Vector2(35, 95); instruction.size = Vector2(520, 65); instruction.reparent(overlay, false)
	for i in task["choices"].size():
		var choice := make_button(overlay, str(task["choices"][i]), Callable(self, "_answer_task").bind(index, i), 500, 48, i == 0)
		choice.position = Vector2(45, 185 + i * 61)
	var cancel := make_button(overlay, "CANCEL", Callable(self, "_close_task"), 120, 38)
	cancel.position = Vector2(235, 373)


func _answer_task(task_index: int, answer: int) -> void:
	var task: Dictionary = TASKS[MAPS[selected_map]["name"]][task_index]
	if player_is_impostor:
		task_overlay_index = -1
		build_game(); show_notice("Fake task only. Impostors do not increase shared task progress."); return
	if answer == int(task["answer"]):
		task_progress[task_index] += 1
		var required: int = TASK_STEPS[MAPS[selected_map]["name"]][task_index]
		if task_progress[task_index] >= required: completed_tasks[task_index] = 1
		task_overlay_index = -1
		if get_node_or_null("TaskOverlay"): get_node("TaskOverlay").queue_free()
		if completed_tasks.count(1) == 8:
			show_result(true, "The village is safe. All shared tasks are complete.")
		else:
			build_game()
			if completed_tasks[task_index] == 1:
				show_notice("Task complete: " + str(task["name"]))
			else:
				show_notice("Progress %d/%d: %s" % [task_progress[task_index], required, str(task["name"])])
	else:
		show_notice("That choice doesn't fit. Try another answer.")


func _close_task() -> void:
	task_overlay_index = -1
	var overlay := get_node_or_null("TaskOverlay")
	if overlay: overlay.queue_free()


func inspect_nearest_clue() -> void:
	var clue_points := [Vector2(335, 320), Vector2(720, 520), Vector2(1065, 265)]
	var nearest := _nearest_index(clue_points, 110.0)
	if nearest < 0: show_notice("Move close to a glowing clue marker to inspect it."); return
	var clues: Array = CHARACTER_CLUES[impostor_character]
	var clue_name: String = clues[nearest]
	if collected_clues.has(clue_name): show_notice("You already recorded this clue."); return
	collected_clues.append(clue_name)
	show_clue_panel(clue_name, impostor_character)
	_update_progress()


func show_clue_panel(clue_name: String, character: String) -> void:
	var overlay := make_panel(Rect2(370, 190, 540, 300), Color(0.12, 0.08, 0.06, 0.98))
	var title := make_label("CLUE RECORDED", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(25, 24); title.size = Vector2(490, 40); title.reparent(overlay, false)
	var copy := make_label("Found: " + clue_name + "\n\nThis evidence is linked to the visual character " + character + ". A character's appearance does not prove their role.", 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	copy.position = Vector2(35, 82); copy.size = Vector2(470, 130); copy.reparent(overlay, false)
	var close := make_button(overlay, "ADD TO JOURNAL", func(): overlay.queue_free(), 250, 46, true)
	close.position = Vector2(145, 229)


func show_journal() -> void:
	var overlay := make_panel(Rect2(320, 115, 640, 480), Color(0.12, 0.08, 0.06, 0.98))
	var title := make_label("CLUE JOURNAL", 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(20, 18); title.size = Vector2(600, 40); title.reparent(overlay, false)
	var intro := make_label("Evidence is separate from task progress. The visual character is not the secret role.", 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	intro.position = Vector2(32, 65); intro.size = Vector2(576, 40); intro.reparent(overlay, false)
	var list_text := "No clues recorded yet. Inspect the glowing markers on the map."
	if not collected_clues.is_empty(): list_text = "\n".join(collected_clues.map(func(c: String) -> String: return "• " + c))
	var list := make_label(list_text, 19, CREAM)
	list.position = Vector2(70, 135); list.size = Vector2(500, 245); list.reparent(overlay, false)
	var close := make_button(overlay, "CLOSE", func(): overlay.queue_free(), 135, 43)
	close.position = Vector2(252, 414)


func call_meeting() -> void:
	if player_position.distance_to(Vector2(640, 120)) > 100.0:
		show_notice("Move close to the central gong to call a meeting."); return
	show_vote_panel()


func show_vote_panel() -> void:
	var overlay := make_panel(Rect2(300, 120, 680, 480), Color(0.12, 0.08, 0.06, 0.99))
	overlay.name = "VoteOverlay"
	var title := make_label("EMERGENCY MEETING", 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(30, 20); title.size = Vector2(620, 46); title.reparent(overlay, false)
	var intro := make_label("Discuss the clues. Vote for the player you suspect, or skip the vote.", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	intro.position = Vector2(40, 72); intro.size = Vector2(600, 40); intro.reparent(overlay, false)
	var suspects := NPC_NAMES.filter(func(n: String) -> bool: return not dead_npcs.has(n))
	if player_is_impostor: suspects.append(selected_character)
	for i in suspects.size():
		var vote := make_button(overlay, "Vote: " + suspects[i], Callable(self, "_cast_vote").bind(suspects[i]), 470, 48)
		vote.position = Vector2(105, 126 + i * 59)
	var skip := make_button(overlay, "SKIP VOTE", Callable(self, "_cast_vote").bind(""), 180, 42, true)
	skip.position = Vector2(250, 423)


func _cast_vote(suspect: String) -> void:
	if suspect.is_empty():
		var skipped_overlay := get_node_or_null("VoteOverlay")
		if skipped_overlay: skipped_overlay.queue_free()
		build_game(); show_notice("The group skipped the vote."); return
	var picked_impostor := (not player_is_impostor and suspect == impostor_character) or (player_is_impostor and suspect == selected_character)
	if picked_impostor:
		show_result(true, suspect + " was revealed as the Impostor. The Villagers win!")
	else:
		if not suspect.is_empty() and not dead_npcs.has(suspect): dead_npcs.append(suspect)
		var vote_overlay := get_node_or_null("VoteOverlay")
		if vote_overlay: vote_overlay.queue_free()
		build_game(); show_notice("" if suspect.is_empty() else suspect + " was a Villager. The investigation continues.")


func eliminate_nearest() -> void:
	if not player_is_impostor: return
	var nearest := _nearest_index(NPC_POINTS, 90.0)
	if nearest < 0: show_notice("Move close to a player to eliminate them."); return
	var victim: String = NPC_NAMES[nearest]
	if victim == impostor_character: show_notice("Your secret identity is tied to a different visual character."); return
	if not dead_npcs.has(victim): dead_npcs.append(victim)
	if dead_npcs.size() >= NPC_NAMES.size(): show_result(false, "Every Villager has been eliminated. The Impostor wins!")
	else: build_game(); show_notice(victim + " was eliminated. Stay out of sight.")


func show_result(villagers_win: bool, message: String) -> void:
	current_screen = "result"
	for child in get_children():
		if child is Control: child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var overlay := make_panel(Rect2(310, 200, 660, 330), Color(0.1, 0.07, 0.04, 0.98))
	var title := make_label("VILLAGERS WIN" if villagers_win else "IMPOSTOR WINS", 32, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(30, 26); title.size = Vector2(600, 52); title.reparent(overlay, false)
	var summary := make_label(message + "\n\nImpostor visual character: " + impostor_character, 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	summary.position = Vector2(45, 105); summary.size = Vector2(570, 90); summary.reparent(overlay, false)
	var again := make_button(overlay, "PLAY AGAIN", Callable(self, "build_menu"), 220, 48, true)
	again.position = Vector2(220, 240)


func _travel_hint(_index: int) -> void:
	show_notice("Walk to the glowing location, then press INTERACT. WASD / arrow keys also move.")


func _travel_npc(_index: int) -> void:
	show_notice("Walk close to a villager. Use INTERACT to hear a hint.")


func _travel_clue(_index: int) -> void:
	show_notice("Walk to the glowing marker and press INSPECT CLUE.")


func _nearest_index(points: Array, max_distance: float) -> int:
	var best := -1; var distance := max_distance
	for i in points.size():
		var candidate: float = player_position.distance_to(points[i])
		if candidate < distance: distance = candidate; best = i
	return best


func _set_move(direction: Vector2) -> void:
	move_vector = direction


func _stop_move() -> void:
	move_vector = Vector2.ZERO


func _update_progress() -> void:
	var progress := find_child("ProgressLabel", true, false) as Label
	if progress: progress.text = "TASKS  %d / 8    •    CLUES  %d / 3" % [completed_tasks.count(1), collected_clues.size()]


func show_notice(message: String) -> void:
	last_notice = message; last_notice_time = Time.get_ticks_msec() / 1000.0
	var label := get_node_or_null("NoticeLabel") as Label
	if label: label.text = message


func show_how_to_play(return_screen: String) -> void:
	var overlay := make_panel(Rect2(325, 115, 630, 490), Color(0.12, 0.08, 0.06, 0.98))
	var title := make_label("HOW TO PLAY", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(25, 20); title.size = Vector2(580, 42); title.reparent(overlay, false)
	var copy := make_label("Choose a map and a folklore character. In practice mode, five local characters enter the village.\n\nVillager: complete the eight map tasks, inspect identity clues and call the gong to vote.\n\nImpostor: keep your role secret and eliminate every Villager. The secret role is assigned independently from your selected character.\n\nMove with WASD, arrow keys, or the on-screen pad. Press E or INTERACT near a marked activity. Clues never increase task progress.", 16, CREAM)
	copy.position = Vector2(48, 82); copy.size = Vector2(535, 290); copy.reparent(overlay, false)
	var close := make_button(overlay, "CLOSE", func(): overlay.queue_free(), 140, 42)
	close.position = Vector2(245, 420)
	if return_screen == "menu": pass


func show_settings(_return_screen: String) -> void:
	var overlay := make_panel(Rect2(375, 200, 530, 320), Color(0.12, 0.08, 0.06, 0.99))
	_make_child_label(overlay, "SETTINGS", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 22, 480, 42))
	_make_child_label(overlay, "Landscape layout is enabled.\nTouch and keyboard movement are supported.\nAudio controls apply to all game sound.", 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 78, 460, 84))
	var audio := make_button(overlay, "UNMUTE AUDIO" if audio_muted else "MUTE AUDIO", Callable(self, "_toggle_audio"), 210, 42, true)
	audio.name = "SettingsAudioButton"; audio.position = Vector2(150, 174)
	var close := make_button(overlay, "CLOSE", func(): overlay.queue_free(), 140, 42)
	close.position = Vector2(195, 232)


func _make_child_label(parent: Control, text: String, font_size: int, color: Color, align: HorizontalAlignment, rect: Rect2) -> Label:
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


func add_background(texture: Texture2D) -> void:
	var bg := TextureRect.new(); bg.texture = texture; bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)


func add_color_overlay(color: Color) -> void:
	var rect := ColorRect.new(); rect.color = color; rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rect.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(rect)


func make_map_texture(atlas: Texture2D, region: Rect2) -> Texture2D:
	var result := AtlasTexture.new(); result.atlas = atlas; result.region = region
	return result


func make_label(text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", color); label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75)); label.add_theme_constant_override("shadow_offset_x", 1); label.add_theme_constant_override("shadow_offset_y", 2); label.horizontal_alignment = align; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(label); return label


func make_panel(rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new(); panel.position = rect.position; panel.size = rect.size
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = Color("c5904b"); style.set_border_width_all(2); style.set_corner_radius_all(12); style.content_margin_left = 8; style.content_margin_right = 8; style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style); add_child(panel); return panel


func make_button(parent: Control, title: String, callback: Callable, width: float, height: float, highlight: bool = false) -> Button:
	var button := Button.new(); button.text = title; button.custom_minimum_size = Vector2(width, height); button.size = Vector2(width, height); button.focus_mode = Control.FOCUS_NONE; button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new(); normal.bg_color = Color("7d431e") if highlight else Color("51321f"); normal.border_color = Color("e4b25b"); normal.set_border_width_all(2); normal.set_corner_radius_all(10); normal.content_margin_left = 10; normal.content_margin_right = 10
	var hover := normal.duplicate() as StyleBoxFlat; hover.bg_color = Color("9b5c29") if highlight else Color("704426")
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", hover); button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", CREAM); button.add_theme_color_override("font_hover_color", Color.WHITE); button.add_theme_color_override("font_pressed_color", GOLD)
	button.pressed.connect(callback)
	if parent == self: add_child(button)
	else: parent.add_child(button)
	return button
