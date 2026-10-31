extends Node
## Local UI catalogues plus Huawei translations of authored game text only.
const CODES := ["en", "ms", "zh", "ta"]
const NAMES := ["English", "Bahasa Melayu", "中文 (Chinese)", "தமிழ் (Tamil)"]
const Core = preload("res://scripts/language_core.gd")
static var instance: Node
var bridge: Node
var selected := 0
var dictionaries: Dictionary = {}
var translations: Dictionary = {}
var sources: Dictionary = {}
var queue: Array[String] = []
var attempted: Dictionary = {}
var active_source := ""
var active_id := 1000000
var elapsed := 0.0
var scan_elapsed := 0.0
var last_error := ""
var preferences_path := "user://app_language.cfg"

func _ready() -> void:
	instance = self
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://localization/sources.json"))
	if raw is Array:
		for source in raw: sources[str(source)] = true
	var stored := ConfigFile.new()
	stored.load(preferences_path)
	var preference := str(preload("res://scripts/settings_store.gd").get_value("language"))
	selected = maxi(0, CODES.find(preference))
	for index in range(1, 4):
		var code: String = CODES[index]
		var messages: Dictionary = stored.get_value("catalogue", code, {})
		var current_ui = JSON.parse_string(FileAccess.get_file_as_string("res://localization/current_ui.json"))
		if current_ui is Array:
			for row in current_ui:
				messages[row[0]] = row[index]; sources[row[0]] = true
		var translation := Translation.new()
		translation.locale = code
		for row in Core.TEXT:
			messages[row[0]] = row[index]
		if code == "ms": messages.merge(preload("res://scripts/language_malay.gd").TEXT, true)
		for source in messages: translation.add_message(source, str(messages[source]))
		dictionaries[code] = messages
		translations[code] = translation
		TranslationServer.add_translation(translation)
	TranslationServer.set_locale(CODES[selected])

static func text(source: String) -> String:
	if is_instance_valid(instance) and instance.selected != 0: instance._enqueue(source)
	return TranslationServer.translate(source)

func _exit_tree() -> void:
	for translation in translations.values(): TranslationServer.remove_translation(translation)
	if instance == self:
		instance = null; TranslationServer.set_locale("en")

func select_language(index: int) -> void:
	cancel_job()
	selected = clampi(index, 0, 3)
	queue.clear(); attempted.clear(); last_error = ""
	TranslationServer.set_locale(CODES[selected])
	if selected == 0:
		for control in bridge.app.find_children("*", "Control", true, false):
			if control.has_meta("language_font_size"): control.add_theme_font_size_override("font_size", int(control.get_meta("language_font_size")))
	preload("res://scripts/settings_store.gd").set_value("language", CODES[selected])
	_save()
	_refresh_current()
	scan_elapsed = 1.0

func _save() -> void:
	var stored := ConfigFile.new()
	stored.set_value("preferences", "language", selected)
	for code in dictionaries: stored.set_value("catalogue", code, dictionaries[code])
	stored.save(preferences_path)

func cancel_job() -> void:
	if not active_source.is_empty():
		queue.push_front(active_source)
		attempted.erase(active_source)
		active_source = ""
		active_id += 1
		if is_instance_valid(bridge) and bridge.native != null: bridge.native.call("cancelTranslation")

func _process(delta: float) -> void:
	if selected == 0: return
	if not active_source.is_empty():
		elapsed += delta
		if elapsed > 20.0:
			_on_error(active_id, "Huawei translation timed out. Check your internet connection and select the language again to retry.")
			if is_instance_valid(bridge) and bridge.native != null: bridge.native.call("cancelTranslation")
		return
	scan_elapsed += delta
	if scan_elapsed > 0.5:
		scan_elapsed = 0.0
		_collect(bridge.app)
	if is_instance_valid(bridge.overlay) or bridge.pending or queue.is_empty() or not last_error.is_empty(): return
	if OS.get_name() != "Android" or bridge.native == null: return
	var configuration: Dictionary = bridge._configuration()
	if str(configuration.get("api_key", "")).is_empty():
		last_error = "Huawei configuration is missing from this APK. Export again with the Huawei plugin enabled."
		return
	active_source = queue.pop_front()
	attempted[active_source] = true
	active_id += 1; elapsed = 0.0
	bridge.native.call("translate", active_id, active_source, CODES[selected], str(configuration.get("app_id", "")), str(configuration.api_key))

func _enqueue(source: String) -> void:
	if selected == 0: return
	if source.is_empty() or source.length() > 4000: return
	if not sources.has(source) or dictionaries[CODES[selected]].has(source): return
	if attempted.has(source) or queue.has(source) or active_source == source: return
	queue.append(source)

func _collect(node: Node) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED: return
	# Do not send account names, chat, room codes, passwords or player input.
	# Exact membership in the authored source catalogue is mandatory.
	if node is Label or node is Button or node is RichTextLabel:
		_enqueue(str(node.text))
		if node is Label: _fit_label(node)
		if node is Button and not node is OptionButton:
			_fit_button(node)
	if node is LineEdit: _enqueue(node.placeholder_text)
	if node is OptionButton and node.name != "SettingsLanguageButton":
		for index in node.item_count: _enqueue(node.get_item_text(index))
	for child in node.get_children():
		if child != self: _collect(child)

func _fit_button(button: Button) -> void:
	if button.text.is_empty(): return
	if not button.has_meta("language_font_size"):
		button.set_meta("language_font_size", button.get_theme_font_size("font_size"))
	var base_size: int = button.get_meta("language_font_size")
	var font := button.get_theme_font("font")
	var width := font.get_string_size(TranslationServer.translate(button.text), HORIZONTAL_ALIGNMENT_LEFT, -1, base_size).x
	var fitted := clampi(int(base_size * (button.size.x-28) / maxf(width, 1.0)), 12, base_size)
	button.add_theme_font_size_override("font_size", fitted)

func _on_translated(id: int, text: String) -> bool:
	if id < 1000000: return false
	if id != active_id or active_source.is_empty(): return true
	if text.strip_edges().is_empty(): return _on_error(id, "Huawei returned an empty translation. Select the language again to retry.")
	# Formatting arguments must survive machine translation unchanged.
	var placeholders := RegEx.new()
	placeholders.compile("%[-+0-9.]*[sdif%]")
	var expected: Array[String] = []
	var received: Array[String] = []
	for match in placeholders.search_all(active_source): expected.append(match.get_string())
	for match in placeholders.search_all(text): received.append(match.get_string())
	if expected != received:
		active_source = ""
		return true
	var code: String = CODES[selected]
	dictionaries[code][active_source] = text
	translations[code].add_message(active_source, text)
	active_source = ""
	TranslationServer.set_locale(code)
	_refresh_current()
	_save()
	return true

func _refresh_current() -> void:
	if not is_instance_valid(bridge) or not is_instance_valid(bridge.app): return
	if bridge.app.current_screen == "character_select": bridge.app._refresh_character_select()
	if bridge.app.current_screen == "waiting_room": bridge.app._refresh_waiting_room()
	if bridge.app.current_screen == "game" and is_instance_valid(bridge.app.game_world):
		bridge.app._refresh_task_rows()
		bridge.app._update_progress()
		var role: Label = bridge.app.find_child("GameRoleLabel", true, false)
		if role: role.text = text("NENEK KEBAYAN" if bridge.app.player_is_impostor else "VILLAGER") + "  •  " + bridge.app.selected_character
	for control in bridge.app.find_children("*", "Control", true, false):
		control.queue_redraw()

func _on_error(id: int, message: String) -> bool:
	if id < 1000000: return false
	if id == active_id and not active_source.is_empty():
		active_source = ""
		last_error = message
	return true

func status_text() -> String:
	if selected == 0: return "English is selected."
	if selected == 1: return "Malay selected. Bundled text works offline; additional text can use Huawei translation."
	if not last_error.is_empty(): return last_error
	if OS.get_name() != "Android" or bridge.native == null:
		return "Some game text needs Huawei translation in the Android app."
	if not active_source.is_empty() or not queue.is_empty(): return "Translating game text with Huawei… Internet is required."
	return "Language applied."

func _fit_label(label: Label) -> void:
	if label.text.is_empty() or label.size.x <= 0 or label.size.y <= 0: return
	if not label.has_meta("language_font_size"):
		label.set_meta("language_font_size", label.get_theme_font_size("font_size"))
	var base_size: int = label.get_meta("language_font_size")
	var fitted := base_size
	label.add_theme_font_size_override("font_size", fitted)
	while fitted > mini(14, base_size) and label.get_line_count() * label.get_line_height() > label.size.y + 1:
		fitted -= 1
		label.add_theme_font_size_override("font_size", fitted)
