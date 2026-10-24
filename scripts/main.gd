extends Control
## Playable local practice build for Kampung Legenda: Misteri Tiga Rumah.

const MENU_ART := "res://assets/ui/main_menu.png"
const MAP_ART := "res://assets/maps/heritage_maps.png"
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
	{"name": "Istana Puteri Gunung Ledang", "description": "Explore the royal palace, gardens and mountain path.", "region": Rect2(0, 0, 1350, 490)},
	{"name": "Rumah Pak Kaduk", "description": "Search the kampung yard, paddy field and rooster arena.", "region": Rect2(0, 500, 750, 445)},
	{"name": "Rumah Mahsuri", "description": "Follow the village paths from Mahsuri's home to her garden.", "region": Rect2(780, 500, 750, 445)}
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
var selected_character := ""
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
var dead_npcs: Array[String] = []
var rng := RandomNumberGenerator.new()
var map_image: Texture2D


func _ready() -> void:
	rng.randomize()
	build_menu()


func _process(delta: float) -> void:
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
	var notice := get_node_or_null("NoticeLabel") as Label
	if notice and Time.get_ticks_msec() / 1000.0 - last_notice_time > 2.4:
		notice.text = ""


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
	var title := make_label("Kampung Legenda", 60, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(270, 78); title.size = Vector2(740, 82); title.add_theme_color_override("font_shadow_color", INK); title.add_theme_constant_override("shadow_offset_x", 4); title.add_theme_constant_override("shadow_offset_y", 5)
	var subtitle := make_label("Misteri Tiga Rumah", 27, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.position = Vector2(410, 158); subtitle.size = Vector2(460, 42)
	var menu_panel := make_panel(Rect2(465, 255, 350, 395), Color(0.13, 0.075, 0.045, 0.91))
	var menu_buttons := ["PLAY", "HOW TO PLAY", "SETTINGS", "EXIT"]
	for i in menu_buttons.size():
		var btn := make_button(menu_panel, menu_buttons[i], Callable(self, "_menu_action").bind(i), 300, 54, i == 0)
		btn.position = Vector2(25, 25 + i * 85)
	var badge := make_label("LOCAL PRACTICE  •  NETWORK ROOMS NOT CONNECTED", 14, Color("f7d9a2"), HORIZONTAL_ALIGNMENT_CENTER)
	badge.position = Vector2(300, 680); badge.size = Vector2(680, 24)


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
		var card := make_panel(Rect2(70 + i * 390, 120, 350, 490), Color(0.12, 0.09, 0.07, 0.96))
		var preview := TextureRect.new(); preview.texture = make_map_texture(atlas, MAPS[i]["region"]); preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.position = Vector2(12, 12); preview.size = Vector2(326, 275); card.add_child(preview)
		var map_name := make_label(MAPS[i]["name"], 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		map_name.position = Vector2(15, 300); map_name.size = Vector2(320, 58); map_name.reparent(card, false)
		var description := make_label(MAPS[i]["description"], 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		description.position = Vector2(20, 360); description.size = Vector2(310, 52); description.reparent(card, false)
		var choose := make_button(card, "SELECT MAP", Callable(self, "_choose_map").bind(i), 270, 48, true)
		choose.position = Vector2(40, 425)
	var back := make_button(self, "BACK", Callable(self, "build_menu"), 125, 44)
	back.position = Vector2(36, 34)


func _choose_map(index: int) -> void:
	selected_map = index
	build_character_select()


func build_character_select() -> void:
	await clear_screen("character_select")
	add_background(load(MENU_ART)); add_color_overlay(Color(0.035, 0.055, 0.06, 0.84))
	var title := make_label("Select Your Character", 38, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(300, 20); title.size = Vector2(680, 54)
	var subtitle := make_label(MAPS[selected_map]["name"], 19, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.position = Vector2(300, 70); subtitle.size = Vector2(680, 32)
	var cast := TextureRect.new(); cast.texture = load(CAST_ART); cast.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; cast.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cast.position = Vector2(34, 120); cast.size = Vector2(270, 500); cast.modulate = Color(1, 1, 1, 0.85); add_child(cast)
	for i in CHARACTERS.size():
		var col := i % 4; var row := i / 4
		var card := make_panel(Rect2(330 + col * 226, 128 + row * 166, 205, 148), Color(0.16, 0.105, 0.07, 0.97))
		var sigil := make_label(_character_sigil(i), 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		sigil.position = Vector2(5, 6); sigil.size = Vector2(195, 40); sigil.reparent(card, false)
		var name := make_label(CHARACTERS[i], 15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		name.position = Vector2(8, 45); name.size = Vector2(189, 45); name.reparent(card, false)
		var select := make_button(card, "SELECT", Callable(self, "_select_character").bind(CHARACTERS[i]), 150, 36, selected_character == CHARACTERS[i])
		select.position = Vector2(27, 100)
	var selected := selected_character if not selected_character.is_empty() else "Choose one of 11 folklore characters"
	var selected_label := make_label("Selected: " + selected, 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	selected_label.position = Vector2(340, 640); selected_label.size = Vector2(640, 28)
	var start := make_button(self, "START PRACTICE", Callable(self, "start_practice"), 245, 52, true)
	start.position = Vector2(880, 635); start.disabled = selected_character.is_empty()
	var back := make_button(self, "BACK", Callable(self, "build_map_select"), 115, 42)
	back.position = Vector2(35, 35)
	var online := make_label("Offline practice uses four village characters as local suspects.", 13, Color("ead6b9"), HORIZONTAL_ALIGNMENT_CENTER)
	online.position = Vector2(345, 684); online.size = Vector2(630, 20)


func _select_character(character: String) -> void:
	selected_character = character
	build_character_select()


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
	var overlay := make_panel(Rect2(375, 185, 530, 340), Color(0.12, 0.08, 0.06, 0.98))
	var title := make_label("SETTINGS", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(20, 20); title.size = Vector2(490, 42); title.reparent(overlay, false)
	var copy := make_label("Landscape layout is enabled.\n\nMusic and sound hooks are reserved for original game audio.\n\nTouch movement and keyboard movement are supported.", 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	copy.position = Vector2(35, 95); copy.size = Vector2(460, 135); copy.reparent(overlay, false)
	var close := make_button(overlay, "CLOSE", func(): overlay.queue_free(), 140, 42)
	close.position = Vector2(195, 274)


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
