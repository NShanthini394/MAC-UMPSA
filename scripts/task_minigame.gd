extends Control
## Small physical task interactions that run inside the task overlay.

signal step_completed
signal sound_requested(kind: String)

class DragToken extends Button:
	var item_id := ""

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var preview := Label.new()
		preview.text = text
		preview.add_theme_font_size_override("font_size", 18)
		preview.add_theme_color_override("font_color", Color("fff0cf"))
		set_drag_preview(preview)
		return {"item": item_id}


class DropTarget extends Button:
	signal item_dropped(item_id: String, target_id: String)
	var target_id := ""
	var accepting := true

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return accepting and data is Dictionary and data.has("item")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		item_dropped.emit(str(data.get("item", "")), target_id)


const BOARD := Color("30251c")
const BOARD_EDGE := Color("b9833f")
const CREAM := Color("fff0cf")
const GOLD := Color("f7c35a")
const GREEN := Color("61f28a")

var task: Dictionary = {}
var task_kind := "collect"
var current_progress := 0
var required_progress := 1
var board: Panel
var feedback_label: Label
var timing_marker: ColorRect
var timing_phase := 0.0
var timing_direction := 1.0
var route_position := 0
var supplies_found: Array[String] = []
var key_found := false
var key_hide_index := -1
var active_drag_target: String = ""
var selected_drag_item := ""
var input_enabled := true


func configure(task_data: Dictionary, progress: int, required: int) -> void:
	task = task_data
	task_kind = str(task.get("minigame", "collect"))
	current_progress = progress
	required_progress = required
	key_hide_index = randi_range(0, 2)
	_build_board()


func set_progress(progress: int) -> void:
	current_progress = progress
	if task_kind == "collect" or task_kind == "talk" or task_kind == "timing" or task_kind == "matching":
		_build_board()


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	for child in find_children("*", "BaseButton", true, false):
		(child as BaseButton).disabled = not enabled
		if child is DropTarget:
			(child as DropTarget).accepting = enabled


func _process(delta: float) -> void:
	if task_kind != "timing" or not is_instance_valid(timing_marker):
		return
	timing_phase += delta * timing_direction * 0.72
	if timing_phase >= 1.0:
		timing_phase = 1.0
		timing_direction = -1.0
	elif timing_phase <= 0.0:
		timing_phase = 0.0
		timing_direction = 1.0
	timing_marker.position.x = 30.0 + timing_phase * 622.0


func _build_board() -> void:
	selected_drag_item = ""
	for child in get_children():
		remove_child(child)
		child.queue_free()
	board = Panel.new()
	board.name = "PhysicalTaskBoard"
	board.position = Vector2.ZERO
	board.size = size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = BOARD
	panel_style.border_color = BOARD_EDGE
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	board.add_theme_stylebox_override("panel", panel_style)
	add_child(board)
	feedback_label = _label("", 15, CREAM, Rect2(20, size.y - 34, size.x - 40, 24), HORIZONTAL_ALIGNMENT_CENTER)
	match task_kind:
		"collect": _build_collect_board()
		"talk": _build_talk_board()
		"drag": _build_drag_board()
		"interact": _build_interact_board()
		"timing": _build_timing_board()
		"route": _build_route_board()
		"supplies": _build_supplies_board()
		"find_rooster": _build_find_rooster_board()
		"search_key": _build_search_key_board()
		"matching": _build_matching_board()
		"final_route": _build_final_route_board()
		_: _build_collect_board()


func _label(copy: String, font_size: int, color: Color, rect: Rect2, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board.add_child(label)
	return label


func _button(copy: String, rect: Rect2, callback: Callable, prominent: bool = false) -> Button:
	var button := Button.new()
	button.text = copy
	button.position = rect.position
	button.size = rect.size
	button.disabled = not input_enabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("79502e") if prominent else Color("493528")
	normal.border_color = GOLD if prominent else Color("9a7449")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("96663a") if prominent else Color("60462f")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.pressed.connect(callback)
	board.add_child(button)
	return button


func _build_collect_board() -> void:
	_label("Kutip objek yang betul di sekitar kawasan.", 16, CREAM, Rect2(20, 14, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var items: Array = task.get("items", [str(task.get("action", "Objek"))])
	var amount := mini(required_progress - current_progress, 8)
	for i in amount:
		var text := str(items[i % items.size()])
		var col := i % 4
		var row := i / 4
		var rect := Rect2(36 + col * 170, 62 + row * 82, 148, 64)
		_button(text, rect, Callable(self, "_complete_one"))
	if amount <= 0:
		_label("Semua objek sudah dikutip.", 18, GREEN, Rect2(30, 100, size.x - 60, 60), HORIZONTAL_ALIGNMENT_CENTER)


func _build_talk_board() -> void:
	_label("Pilih penduduk untuk berbual.", 16, CREAM, Rect2(20, 14, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var people: Array = task.get("people", ["Penduduk 1", "Penduduk 2", "Penduduk 3"])
	var remaining := mini(required_progress - current_progress, people.size())
	for i in remaining:
		var person_index := current_progress + i
		var rect := Rect2(42 + (i % 3) * 220, 92, 190, 100)
		_button("◉\n" + str(people[person_index % people.size()]), rect, Callable(self, "_complete_one").bind("ui"))


func _build_drag_board() -> void:
	var source_name := str(task.get("drag_from", "Objek"))
	var target_name := str(task.get("drag_to", "Tempat sasaran"))
	active_drag_target = str(task.get("drag_id", "item"))
	_label("Seret objek ke tempat yang betul.", 16, CREAM, Rect2(20, 12, size.x - 40, 32), HORIZONTAL_ALIGNMENT_CENTER)
	var token := DragToken.new()
	token.text = source_name
	token.item_id = active_drag_target
	token.disabled = not input_enabled
	token.position = Vector2(55, 105)
	token.size = Vector2(190, 80)
	token.add_theme_font_size_override("font_size", 19)
	var token_style := StyleBoxFlat.new()
	token_style.bg_color = Color("8b6038")
	token_style.border_color = GOLD
	token_style.set_border_width_all(3)
	token_style.set_corner_radius_all(14)
	token.add_theme_stylebox_override("normal", token_style)
	token.add_theme_color_override("font_color", CREAM)
	token.pressed.connect(_on_drag_token_pressed.bind(active_drag_target))
	board.add_child(token)
	_label("➜", 34, GOLD, Rect2(310, 112, 80, 58), HORIZONTAL_ALIGNMENT_CENTER)
	var target := DropTarget.new()
	target.text = target_name
	target.position = Vector2(445, 92)
	target.size = Vector2(230, 115)
	target.target_id = active_drag_target
	target.accepting = input_enabled
	var target_style := StyleBoxFlat.new()
	target_style.bg_color = Color("3b4c39")
	target_style.border_color = Color("9dbb72")
	target_style.set_border_width_all(3)
	target_style.set_corner_radius_all(14)
	target_style.content_margin_left = 16
	target_style.content_margin_right = 16
	target.add_theme_stylebox_override("normal", target_style)
	var target_hover := target_style.duplicate() as StyleBoxFlat
	target_hover.bg_color = Color("4c6248")
	target.add_theme_stylebox_override("hover", target_hover)
	target.add_theme_stylebox_override("pressed", target_hover)
	target.add_theme_color_override("font_color", CREAM)
	target.add_theme_font_size_override("font_size", 17)
	target.pressed.connect(_on_drag_target_pressed)
	target.item_dropped.connect(_on_drag_dropped)
	board.add_child(target)
	feedback_label.text = "" if task.get("hint", "").is_empty() else str(task["hint"])
	feedback_label.text += " Tekan objek, kemudian tekan tempat sasaran."


func _on_drag_token_pressed(item_id: String) -> void:
	selected_drag_item = item_id
	sound_requested.emit("ui")
	feedback_label.text = "Objek dipilih. Tekan tempat sasaran yang betul."


func _on_drag_target_pressed() -> void:
	if selected_drag_item == active_drag_target:
		_complete_one("drag")
	else:
		sound_requested.emit("timing_miss")
		feedback_label.text = "Pilih objek dahulu, kemudian tekan tempat sasaran."


func _build_interact_board() -> void:
	_label(str(task.get("interact_caption", "Tekan butang interaksi untuk meneruskan.")), 16, CREAM, Rect2(20, 20, size.x - 40, 36), HORIZONTAL_ALIGNMENT_CENTER)
	_label("◉", 64, GOLD, Rect2(285, 74, 220, 100), HORIZONTAL_ALIGNMENT_CENTER)
	_button(str(task.get("interact_label", "INTERAKSI")), Rect2(220, 194, 340, 62), Callable(self, "_complete_one").bind("ui"), true)


func _on_drag_dropped(item_id: String, target_id: String) -> void:
	if item_id == active_drag_target and target_id == active_drag_target:
		_complete_one("drag")
	else:
		sound_requested.emit("timing_miss")
		feedback_label.text = "Belum tepat. Cuba seret semula."


func _build_timing_board() -> void:
	_label("Tekan apabila penanda berada di dalam zon hijau.", 16, CREAM, Rect2(20, 14, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var track := ColorRect.new()
	track.position = Vector2(30, 112)
	track.size = Vector2(622, 24)
	track.color = Color("503d2b")
	board.add_child(track)
	var target_zone := ColorRect.new()
	target_zone.position = Vector2(30 + 622 * 0.43, 108)
	target_zone.size = Vector2(622 * 0.14, 32)
	target_zone.color = Color("49b66b", 0.85)
	board.add_child(target_zone)
	timing_marker = ColorRect.new()
	timing_marker.position = Vector2(30, 100)
	timing_marker.size = Vector2(8, 48)
	timing_marker.color = Color("ffe37a")
	board.add_child(timing_marker)
	_button("TEKAN SEKARANG", Rect2(240, 190, 240, 58), Callable(self, "_try_timing"), true)


func _try_timing() -> void:
	if absf(timing_phase - 0.5) <= 0.14:
		_complete_one("timing_good")
	else:
		sound_requested.emit("timing_miss")
		feedback_label.text = "Belum kena pada masa yang tepat. Cuba lagi!"


func _build_route_board() -> void:
	_label("Ikut turutan penanda pada laluan.", 16, CREAM, Rect2(20, 12, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var route: Array = task.get("route", ["↑", "→", "↑"])
	var route_text := ""
	for direction in route: route_text += str(direction) + "   "
	_label("LALUAN   " + route_text.strip_edges(), 22, GOLD, Rect2(20, 52, size.x - 40, 40), HORIZONTAL_ALIGNMENT_CENTER)
	var directions := ["↑", "→", "↓", "←"]
	for i in directions.size():
		var rect := Rect2(220 + (i % 2) * 150, 110 + (i / 2) * 72, 120, 58)
		_button(directions[i], rect, Callable(self, "_choose_route_direction").bind(directions[i]), true)
	feedback_label.text = "Langkah %d/%d" % [route_position, route.size()]


func _choose_route_direction(direction: String) -> void:
	var route: Array = task.get("route", ["↑", "→", "↑"])
	if direction == str(route[route_position]):
		route_position += 1
		if route_position >= route.size():
			route_position = 0
			_complete_one("ui")
		else:
			sound_requested.emit("ui")
			feedback_label.text = "Betul! Langkah %d/%d" % [route_position, route.size()]
	else:
		route_position = 0
		sound_requested.emit("timing_miss")
		feedback_label.text = "Tersalah laluan. Cuba semula dari awal."


func _build_supplies_board() -> void:
	_label("Kumpulkan kedua-dua bekalan perjalanan.", 16, CREAM, Rect2(20, 14, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var supplies: Array = task.get("items", ["Air", "Makanan"])
	for i in supplies.size():
		var item := str(supplies[i])
		var rect := Rect2(145 + i * 245, 92, 200, 100)
		_button("✚\n" + item, rect, Callable(self, "_collect_supply").bind(item))
	feedback_label.text = "Bekalan dikumpul: %d/%d" % [supplies_found.size(), supplies.size()]


func _collect_supply(item: String) -> void:
	if not supplies_found.has(item):
		supplies_found.append(item)
		sound_requested.emit("collect")
	feedback_label.text = "Bekalan dikumpul: %d/%d" % [supplies_found.size(), task.get("items", []).size()]
	if supplies_found.size() >= task.get("items", []).size():
		_complete_one("ui")


func _build_find_rooster_board() -> void:
	_label("Cari dan tekan ayam Pak Kaduk.", 16, CREAM, Rect2(20, 14, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var choices: Array = ["Ayam betina", "Patung ayam", "Ayam Pak Kaduk", "Bakul jerami"]
	choices.shuffle()
	for i in choices.size():
		var item := str(choices[i])
		var rect := Rect2(70 + (i % 2) * 300, 75 + (i / 2) * 82, 250, 68)
		_button("◉  " + item, rect, Callable(self, "_select_rooster").bind(item))


func _select_rooster(item: String) -> void:
	if item == "Ayam Pak Kaduk":
		_complete_one("collect")
	else:
		sound_requested.emit("timing_miss")
		feedback_label.text = "Bukan ayam Pak Kaduk. Cari lagi!"


func _build_search_key_board() -> void:
	if not key_found:
		_label("Cari kunci di dalam peti yang berhampiran.", 15, CREAM, Rect2(20, 10, size.x - 40, 36), HORIZONTAL_ALIGNMENT_CENTER)
		var hiding_places := ["Bakul", "Pasu", "Tikar"]
		for i in hiding_places.size():
			_button("⌕\n" + hiding_places[i], Rect2(96 + i * 205, 80, 160, 115), Callable(self, "_search_spot").bind(i))
	else:
		_build_drag_board()
		feedback_label.text = "Kunci ditemui! Seret kunci ke peti berkunci."


func _search_spot(spot_index: int) -> void:
	if spot_index == key_hide_index:
		key_found = true
		sound_requested.emit("collect")
		_build_board()
		feedback_label.text = "Kunci ditemui! Seret kunci ke peti berkunci."
	else:
		sound_requested.emit("timing_miss")
		feedback_label.text = "Tiada kunci di situ. Cuba tempat yang lain."


func _build_matching_board() -> void:
	_label("Seret setiap barang kepada pemilik yang betul.", 16, CREAM, Rect2(20, 12, size.x - 40, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var pairs: Array = task.get("pairs", [])
	if pairs.is_empty():
		_complete_one()
		return
	var pair_index := current_progress % pairs.size()
	var pair: Dictionary = pairs[pair_index]
	var token := DragToken.new()
	token.text = str(pair.get("item", "Barang"))
	token.item_id = str(pair.get("id", ""))
	token.disabled = not input_enabled
	token.position = Vector2(54, 102)
	token.size = Vector2(210, 82)
	token.add_theme_font_size_override("font_size", 18)
	token.add_theme_color_override("font_color", CREAM)
	token.pressed.connect(_on_drag_token_pressed.bind(token.item_id))
	board.add_child(token)
	_label("➜", 32, GOLD, Rect2(315, 112, 70, 56), HORIZONTAL_ALIGNMENT_CENTER)
	var owners: Array = task.get("owners", [])
	for i in owners.size():
		var target := DropTarget.new()
		target.text = str(owners[i])
		target.position = Vector2(300 + (i % 3) * 132, 190 + (i / 3) * 62)
		target.size = Vector2(122, 58)
		target.target_id = str(owners[i])
		target.accepting = input_enabled
		target.disabled = not input_enabled
		var style := StyleBoxFlat.new()
		style.bg_color = Color("3b4c39")
		style.border_color = Color("9dbb72")
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.content_margin_left = 8; style.content_margin_right = 8
		style.content_margin_top = 6; style.content_margin_bottom = 6
		target.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = Color("4c6248")
		target.add_theme_stylebox_override("hover", hover)
		target.add_theme_stylebox_override("pressed", hover)
		target.add_theme_font_size_override("font_size", 16)
		target.add_theme_color_override("font_color", CREAM)
		target.pressed.connect(_on_matching_target_pressed.bind(str(pair.get("id", "")), str(pair.get("owner", "")), str(owners[i])))
		target.item_dropped.connect(_on_matching_drop.bind(str(pair.get("id", "")), str(pair.get("owner", ""))))
		board.add_child(target)


func _on_matching_target_pressed(expected_id: String, expected_owner: String, target_owner: String) -> void:
	if selected_drag_item.is_empty():
		feedback_label.text = "Pilih barang dahulu, kemudian tekan pemiliknya."
		return
	_on_matching_drop(selected_drag_item, target_owner, expected_id, expected_owner)


func _on_matching_drop(item_id: String, target_id: String, expected_id: String, expected_owner: String) -> void:
	if item_id == expected_id and target_id == expected_owner:
		_complete_one("drag")
	else:
		sound_requested.emit("timing_miss")
		feedback_label.text = "Padanan salah. Cuba barang yang lain."


func _build_final_route_board() -> void:
	_label("Ikut penanda ke Puteri, kemudian tekan untuk berbual.", 16, CREAM, Rect2(20, 14, size.x - 40, 34), HORIZONTAL_ALIGNMENT_CENTER)
	_button("⌖  IKUT PENANDA", Rect2(90, 92, 240, 95), Callable(self, "_reach_princess"))
	var princess := _button("◉  PUTERI GUNUNG LEDANG", Rect2(400, 92, 250, 95), Callable(self, "_speak_to_princess"))
	princess.name = "PrincessTaskButton"
	princess.disabled = true
	feedback_label.text = "Ikut penanda dahulu."


func _reach_princess() -> void:
	sound_requested.emit("ui")
	feedback_label.text = "Anda sudah tiba. Sekarang berbual dengan Puteri."
	var princess := board.get_node_or_null("PrincessTaskButton") as Button
	if princess: princess.disabled = false


func _speak_to_princess() -> void:
	var princess := board.get_node_or_null("PrincessTaskButton") as Button
	if princess and princess.disabled:
		feedback_label.text = "Ikut penanda ke puncak dahulu."
		return
	_complete_one("ui")


func _complete_one(sound_kind: String = "collect") -> void:
	sound_requested.emit(sound_kind)
	step_completed.emit()
