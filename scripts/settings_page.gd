extends ColorRect
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const Store = preload("res://scripts/settings_store.gd")
const Icons = preload("res://scripts/settings_icons.gd")
var app: Control
var navigation: CanvasLayer
var content: VBoxContainer
var status: Label
var section := ""

func configure(controller: Control, controls: CanvasLayer) -> void:
	app = controller; navigation = controls
	name = "SettingsPage"; size = Vector2(1280, 720)
	color = Data.SECTION_PANEL; z_index = 50; mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/ui/login_background.png")
	backdrop.position = Vector2.ZERO; backdrop.size = size
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.28, 0.22, 0.18, 1); backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	UI.make_panel(self, Rect2(44, 22, 1192, 676), Data.SECTION_PANEL)
	app.firebase_auth.failed.connect(_account_failure)
	app.firebase_auth.busy_changed.connect(_account_busy)
	app.firebase_auth.account_updated.connect(_account_success)
	show_section("")

func _account_failure(message: String) -> void:
	if is_instance_valid(status): status.text = message

func _account_busy(busy: bool) -> void:
	var close := find_child("SettingsPageClose", true, false) as Button
	if close: close.disabled = busy
	for button in content.find_children("*", "BaseButton", true, false):
		if busy: button.set_meta("before_account_busy", button.disabled); button.disabled = true
		elif button.has_meta("before_account_busy"): button.disabled = bool(button.get_meta("before_account_busy")); button.remove_meta("before_account_busy")
	if busy: status.text = "Confirming your account…"

func _account_success(action: String, message: String) -> void:
	if action == "linked": show_section("ACCOUNT")
	if action in ["username", "password"]: show_section("ACCOUNT")
	if action == "refresh" and section == "ACCOUNT SECURITY": show_section(section)
	if is_instance_valid(status): status.text = message

func label_(text: String, font_size: int = 20, colour: Color = Data.CREAM) -> Label:
	var label := Label.new()
	label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func show_section(value: String) -> void:
	section = value
	for child in get_children():
		if child.has_meta("settings_content"): remove_child(child); child.queue_free()
	var frame := Control.new(); frame.set_meta("settings_content", true); frame.size = size; frame.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(frame)
	var title := UI.make_child_label(frame, "SETTINGS" + ("  /  " + section if not section.is_empty() else ""), 27, Data.GOLD, HORIZONTAL_ALIGNMENT_LEFT, Rect2(80, 40, 1000, 46))
	title.name = "SettingsPageHeading"
	var close := UI.make_button(frame, "×", navigation.close_dialog, 52, 52)
	close.name = "SettingsPageClose"; close.position = Vector2(1158, 36); close.tooltip_text = "Return to game" if app.current_screen in ["game", "meeting"] else "Close Settings"
	if not section.is_empty():
		var back := UI.make_button(frame, "‹  ACCOUNT" if section in preload("res://scripts/account_settings.gd").ACTIONS or section == "VERIFY EMAIL" else "‹  SETTINGS", show_section.bind("ACCOUNT" if section in preload("res://scripts/account_settings.gd").ACTIONS or section == "VERIFY EMAIL" else ""), 180, 42)
		back.position = Vector2(80, 98); back.name = "SettingsSectionBack"
	var top := 108.0 if section.is_empty() else 154.0
	var scroll := ScrollContainer.new(); scroll.name = "SettingsScroll"
	scroll.position = Vector2(80, top); scroll.size = Vector2(1120, 646-top)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	content = VBoxContainer.new(); content.name = "SettingsContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12); scroll.add_child(content)
	status = UI.make_child_label(frame, "", 16, Color("d5c3d7"), HORIZONTAL_ALIGNMENT_LEFT, Rect2(80, 648, 1100, 44))
	status.name = "SettingsSavedLabel"
	if section in preload("res://scripts/account_settings.gd").ACTIONS or section == "VERIFY EMAIL":
		preload("res://scripts/account_settings.gd").build(self, section)
		return
	match section:
		"": overview()
		"ACCOUNT": account()
		"AUDIO": audio()
		"CONTROLS & DISPLAY": controls()
		"HOW TO PLAY": guide()
		"REPORT A PROBLEM": report()
		"DATA & PRIVACY": privacy()
		"ABOUT THE GAME": about()
		"LANGUAGE": language()

func heading(text: String) -> void:
	var label := label_(text, 20, Data.GOLD)
	label.custom_minimum_size.y = 42
	content.add_child(label)

func paragraph(text: String) -> void:
	var label := label_(text)
	label.custom_minimum_size.y = 42
	content.add_child(label)

func row(text: String, icon_name: String, callback: Callable, node_name: String = "") -> Button:
	var button := Button.new()
	button.name = node_name if not node_name.is_empty() else "SettingsRow"+str(content.get_child_count())
	button.custom_minimum_size = Vector2(0, 62); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback); button.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("66342f") if state in ["hover", "pressed", "focus"] else Color("302319")
		style.border_color = Color("9d7c50"); style.border_width_bottom = 1; style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, style)
	content.add_child(button)
	var icon := TextureRect.new(); icon.texture = Icons.icon(icon_name)
	icon.position = Vector2(18, 13); icon.size = Vector2(36, 36); icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(icon)
	var title := label_(text, 22); title.position = Vector2(72, 10); title.size = Vector2(920, 42); button.add_child(title)
	var arrow := label_("›", 30, Data.GOLD); arrow.position = Vector2(1044, 9); arrow.size = Vector2(32, 44); button.add_child(arrow)
	return button

func profile() -> void:
	var card := HBoxContainer.new(); card.custom_minimum_size.y = 94; card.add_theme_constant_override("separation", 22); content.add_child(card)
	var avatar := TextureRect.new(); avatar.texture = Icons.icon("profile"); avatar.custom_minimum_size = Vector2(76, 76); avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; card.add_child(avatar)
	var copy := VBoxContainer.new(); copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card.add_child(copy)
	var user: Dictionary = app.firebase_auth.user
	var profile_data := preload("res://scripts/account_profiles.gd").profile(user)
	var display_name := str(profile_data.username)
	if display_name.is_empty(): display_name = "Player 1"
	if Data.CHARACTER_AVATARS.has(str(profile_data.avatar)): avatar.texture = load(Data.CHARACTER_AVATARS[str(profile_data.avatar)])
	var name_label := label_(display_name, 26, Data.GOLD)
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	copy.add_child(name_label)
	var identity := "Signed in with Huawei ID" if user.get("provider", "") == "huawei" else str(user.get("email", "Signed in")) if not user.is_empty() else "Playing as Guest"
	var identity_label := label_(identity, 18)
	identity_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	copy.add_child(identity_label)
	var badge := label_("GUEST" if user.is_empty() else "SIGNED IN", 18, Color("d8edb2")); badge.custom_minimum_size.x = 130; card.add_child(badge)

func overview() -> void:
	profile()
	heading("ACCOUNT")
	row("Account Information", "profile", show_section.bind("ACCOUNT"), "SettingsAccountInformation")
	heading("GAME SETTINGS")
	row("Audio Settings", "audio", show_section.bind("AUDIO"), "SettingsAudioRow")
	row("Controls & Display", "controls", show_section.bind("CONTROLS & DISPLAY"), "SettingsControlsRow")
	row("Language", "language", show_section.bind("LANGUAGE"), "SettingsLanguageRow")
	heading("HELP & ABOUT")
	row("How to Play", "help", show_section.bind("HOW TO PLAY"), "SettingsHelpRow")
	row("Report a Problem", "report", show_section.bind("REPORT A PROBLEM"), "SettingsReportRow")
	row("Data & Privacy", "security", show_section.bind("DATA & PRIVACY"), "SettingsPrivacyRow")
	row("About the Game", "info", show_section.bind("ABOUT THE GAME"), "SettingsAboutRow")
	if app.current_screen in ["game", "meeting"]:
		row("Leave Game", "exit", app.show_exit_confirmation, "SettingsLeaveGameButton")

func account() -> void:
	preload("res://scripts/account_settings.gd").build(self)

func slider(title: String, key: String, minimum: float, maximum: float, step_: float, suffix: String = "%") -> void:
	var label := label_(title+"  ·  "+str(int(float(Store.get_value(key))))+suffix, 22, Data.GOLD); content.add_child(label)
	var control := HSlider.new(); control.name = "Preference_"+key
	control.custom_minimum_size = Vector2(0, 52); control.min_value = minimum; control.max_value = maximum; control.step = step_; control.value = float(Store.get_value(key)); content.add_child(control)
	control.value_changed.connect(func(value_: float):
		Store.set_value(key, value_); Store.apply(app)
		label.text = title+"  ·  "+str(snappedf(value_, step_))+suffix
		status.text = "Settings saved.")

func audio() -> void:
	slider("Music volume", "music", 0, 100, 1)
	slider("Sound-effects volume", "effects", 0, 100, 1)
	row("All audio: MUTED — tap to turn on" if bool(Store.get_value("muted")) else "All audio: ON — tap to mute", "audio", func():
		Store.set_value("muted", not bool(Store.get_value("muted"))); Store.apply(app); show_section("AUDIO"), "SettingsMuteToggle")
	row("Test sound", "audio", func(): app._play_sfx("task_complete"), "SettingsTestSoundButton")
	row("Restore audio defaults", "reset", func():
		for key in ["music", "effects", "muted"]: Store.set_value(key, Store.DEFAULTS[key])
		Store.apply(app); show_section("AUDIO"))

func controls() -> void:
	heading("JOYSTICK DISPLAY")
	var options := [["always", "Always Visible", "JoystickAlways"], ["hidden", "Always Hidden", "JoystickHidden"], ["touch", "Show on Touch (Default)", "JoystickTouch"]]
	for option in options:
		row(("✓  " if Store.get_value("joystick_visibility") == option[0] else "") + option[1], "controls", func():
			Store.set_value("joystick_visibility", option[0]); show_section("CONTROLS & DISPLAY"), option[2])
	paragraph("All three options keep movement enabled. In Show on Touch mode, the joystick appears where your finger touches the lower-left area and hides when released.")
	slider("Joystick sensitivity", "sensitivity", 0.6, 1.8, 0.1, "×")
	paragraph("Higher sensitivity needs less thumb movement. Walking speed and collision rules stay the same.")
	slider("Chat & guide text size", "text_size", 18, 24, 2, " px")
	paragraph("Text size applies to discussion messages and How to Play. Other game labels already use the larger phone layout.")
	row("Restore control defaults", "reset", func():
		for key in ["sensitivity", "text_size", "joystick_visibility"]: Store.set_value(key, Store.DEFAULTS[key])
		show_section("CONTROLS & DISPLAY"))

func guide() -> void:
	var copy := "CHOOSE A MODE\nFriends: create or join a private room. Solo: one human and nine bots. Quick Match searches for up to 60 seconds before filling empty spaces with bots.\n\nVILLAGERS\nComplete all twelve tasks and identify both Nenek Kebayan. Follow task routes, inspect clues and compare observations.\n\nNENEK KEBAYAN\nBlend in with the villagers and use your abilities. Sleeping villagers can explore but cannot complete tasks, chat or vote.\n\nMEETINGS & VOTING\nApproach the gong and press Interact. Discuss for 45 seconds, then vote or Skip within 20 seconds. A submitted vote cannot be changed. Results appear once all eligible voters have submitted.\n\nCONTROLS\nDrag anywhere in the lower-left touch area to move. On a computer use WASD or arrow keys. Use Interact near tasks or the gong, the map for routes, and the journal to review clues."
	var label := label_(copy, int(Store.get_value("text_size"))); content.add_child(label)

func report() -> void:
	paragraph("Describe what happened, the map, and the steps to reproduce it. Save or copy this report to share with the game team.")
	var input := TextEdit.new(); input.name = "SettingsReportText"; input.placeholder_text = "What happened? What did you expect?"; input.custom_minimum_size.y = 200; input.add_theme_font_size_override("font_size", 20); content.add_child(input)
	row("Save and copy report", "report", func():
		if input.text.strip_edges().is_empty(): status.text = "Please describe the problem first."; return
		var report_text := "Nenek Kebayan problem report\nOS: "+OS.get_name()+"\nMap: "+str(Data.MAPS[app.selected_map].name)+"\n\n"+input.text.substr(0, 5000)
		var file := FileAccess.open("user://problem_report.txt", FileAccess.WRITE)
		if file: file.store_string(report_text)
		DisplayServer.clipboard_set(report_text); status.text = "Report saved on this device and copied. Share it with the game team.")

func privacy() -> void:
	paragraph("Audio and control preferences, a local Guest ID, per-account username/avatar choices, and any saved problem report are stored on this device.")
	paragraph("Google and email sign-in use Firebase Authentication. Passwords and session tokens are not saved to the preferences file. Signing out clears the game's current sign-in session.")
	paragraph("Online multiplayer sends room information, player names, gameplay actions and meeting messages to the room server. Do not include personal information in public chat.")
	paragraph("Reports are saved or copied only when you choose that action. This page does not send reports automatically.")

func about() -> void:
	heading(Data.GAME_TITLE)
	paragraph("A Malaysian folklore social-deduction game. Every match has ten characters: eight Villagers and two Nenek Kebayan.")
	paragraph("Android landscape edition  •  Built with Godot Engine")
	paragraph("Build: 0.18  •  Huawei combined edition")

func language() -> void:
	heading("LANGUAGE")
	var service: Node = app.huawei_translation.app_language
	var names := ["English (Default)", "Malay / Bahasa Melayu", "Chinese / 中文", "Tamil / தமிழ்"]
	var ids := ["LanguageEnglish", "LanguageMalay", "LanguageChinese", "LanguageTamil"]
	for index in names.size():
		var item := row(("✓  " if service.selected == index else "") + names[index], "language", func():
			service.select_language(index); show_section("LANGUAGE"); status.text = service.status_text(), ids[index])
		item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	paragraph("English and bundled translations work offline. Additional Chinese and Tamil game text uses Huawei ML Kit and requires internet. Player names, chat, passwords and account details are not sent for automatic translation.")
	status.text = service.status_text()
