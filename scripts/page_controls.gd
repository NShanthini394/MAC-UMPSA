extends CanvasLayer
## Persistent navigation and audio controls, independent of rebuilt game pages.
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const ICON_CUTOUT_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform vec2 icon_size = vec2(54.0);
varying vec2 icon_position;
void vertex() { icon_position = VERTEX; }
void fragment() {
    vec2 p = abs(icon_position / icon_size - vec2(0.5));
    // Follow the bevelled frame, excluding the sky outside its corners.
    float edge = max(max(p.x, p.y) - 0.475, p.x + p.y - 0.845);
    COLOR = texture(TEXTURE, UV);
    COLOR.a *= 1.0 - smoothstep(-0.006, 0.006, edge);
}
"""
var app
var _root: Control
var _back: Button
var _music: Button
var _settings: Button
var _help: Button
var _slash: ColorRect
var _styles: Dictionary = {}
var _last_screen := ""
var _last_task_modal := false
var _last_muted := false
var _dialog: ColorRect
var _dialog_kind := ""
var _icons: Dictionary = {}


func configure(controller: Control) -> void:
	app = controller
	layer = 100
	name = "PageControls"
	_root = Control.new()
	_root.name = "PageControlsRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_back = UI.make_button(_root, "< BACK", Callable(app, "navigate_back"), 100, 34)
	_back.name = "UtilityBackButton"
	_music = UI.make_button(_root, "MUSIC ON", Callable(app, "_toggle_audio"), 124, 34)
	_music.name = "UtilityMusicButton"
	_settings = UI.make_button(_root, "SETTINGS", Callable(app, "show_settings").bind(""), 112, 34)
	_settings.name = "UtilitySettingsButton"
	_help = UI.make_button(_root, "?", Callable(app, "show_how_to_play").bind(""), 54, 54)
	_help.name = "UtilityHelpButton"
	for button in [_back, _music, _settings, _help]:
		button.z_index = 20
		button.add_theme_font_size_override("font_size", 13)
		_styles[button.name] = {}
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			_styles[button.name][state] = button.get_theme_stylebox(state).duplicate()
	_back.tooltip_text = "Go back. Leaving a room or match asks for confirmation."
	_settings.tooltip_text = "Settings"
	_help.tooltip_text = "How to play"
	# Reuse the actual artwork of the menu's three buttons in the gameplay HUD.
	var artwork := load(Data.MENU_ART) as Texture2D
	var art_scale := artwork.get_size() / Vector2(1280, 720)
	var cutout_shader := Shader.new()
	cutout_shader.code = ICON_CUTOUT_SHADER
	for entry in [[_settings, Rect2(1072, 22, 54, 54)], [_music, Rect2(1137, 22, 52, 54)], [_help, Rect2(1200, 22, 54, 54)]]:
		var button: Button = entry[0]
		var region: Rect2 = entry[1]
		var icon := TextureRect.new()
		icon.name = "MenuArtworkIcon"
		icon.texture = UI.make_map_texture(artwork, Rect2(region.position * art_scale, region.size * art_scale))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cutout := ShaderMaterial.new()
		cutout.shader = cutout_shader
		cutout.set_shader_parameter("icon_size", region.size)
		icon.material = cutout
		button.add_child(icon)
		_icons[button.name] = icon
	_slash = ColorRect.new()
	_slash.color = Color("ff5b50")
	_slash.position = Vector2(9, 24); _slash.size = Vector2(34, 5)
	_slash.pivot_offset = _slash.size / 2; _slash.rotation_degrees = -45
	_slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_music.add_child(_slash)
	refresh(true)


func place(button: Button, rect: Rect2, transparent: bool = false) -> void:
	button.custom_minimum_size = rect.size
	button.size = rect.size
	button.position = rect.position
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		if transparent:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(1, 0.82, 0.42, 0.18) if state == "hover" else Color(0, 0, 0, 0)
			button.add_theme_stylebox_override(state, style)
		else:
			button.add_theme_stylebox_override(state, _styles[button.name][state])


func refresh(force: bool = false) -> void:
	if not is_instance_valid(_root): return
	var screen: String = app.current_screen
	var menu := screen == "menu"
	var playing := screen in ["game", "meeting"]
	var quiet := screen in ["login", "map_select", "create_room", "waiting_room", "role_reveal"]
	var task_modal := playing and int(app.task_overlay_index) >= 0
	if force or screen != _last_screen or task_modal != _last_task_modal:
		_last_screen = screen
		_last_task_modal = task_modal
		_back.visible = not menu and not playing and not quiet and not task_modal
		_music.visible = not quiet and not task_modal
		_settings.visible = not quiet and not task_modal
		_help.visible = (menu or playing) and not task_modal
		for icon in _icons.values(): icon.visible = playing
		if menu:
			_music.text = ""; _settings.text = ""; _help.text = ""
			place(_back, Rect2(16, 676, 100, 34))
			place(_settings, Rect2(1072, 22, 54, 54), true)
			place(_music, Rect2(1137, 22, 52, 54), true)
			place(_help, Rect2(1200, 22, 54, 54), true)
		elif playing:
			_music.text = ""; _settings.text = ""; _help.text = ""
			place(_settings, Rect2(1072, 78, 54, 54), true)
			place(_music, Rect2(1137, 78, 52, 54), true)
			place(_help, Rect2(1200, 78, 54, 54), true)
		else:
			_settings.text = "SETTINGS"
			place(_back, Rect2(16, 676, 100, 34))
			place(_music, Rect2(124, 676, 124, 34))
			place(_settings, Rect2(256, 676, 112, 34))
	if force or bool(app.audio_muted) != _last_muted or not menu:
		_last_muted = bool(app.audio_muted)
		_music.text = "" if menu or playing else ("MUTED" if _last_muted else "MUSIC ON")
		_music.tooltip_text = "Turn music and audio on" if _last_muted else "Mute music and audio"
		_slash.visible = (menu or playing) and _last_muted
		var audio := _root.find_child("SettingsAudioButton", true, false) as Button
		if audio: audio.text = "TURN AUDIO ON" if _last_muted else "MUTE AUDIO"


func dialog_open() -> bool:
	return is_instance_valid(_dialog) and not _dialog.is_queued_for_deletion()


func close_dialog() -> void:
	if is_instance_valid(_dialog):
		_root.remove_child(_dialog)
		_dialog.queue_free()
	_dialog = null
	_dialog_kind = ""


func dialog_panel(kind: String, rect: Rect2) -> Panel:
	close_dialog()
	app._stop_move()
	_dialog_kind = kind
	_dialog = ColorRect.new()
	_dialog.name = "UtilityDialog"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.color = Color(0, 0, 0, 0.50)
	_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog.z_index = 10
	_root.add_child(_dialog)
	var panel := UI.make_panel(_dialog, rect, Color(0.12, 0.08, 0.06, 0.99))
	var close: Button = app.make_button(panel, "×", close_dialog, 42, 42)
	close.name = "PopupCloseButton"
	close.position = Vector2(rect.size.x - 52, 10)
	close.add_theme_font_size_override("font_size", 25)
	close.tooltip_text = "Tutup"
	close.accessibility_name = "Tutup"
	return panel


func show_settings() -> void:
	var panel := dialog_panel("settings", Rect2(375, 160, 530, 400))
	panel.name = "SettingsOverlay"
	UI.make_child_label(panel, "SETTINGS", 26, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 20, 420, 42))
	var audio := UI.make_button(panel, "TURN AUDIO ON" if bool(app.audio_muted) else "MUTE AUDIO", Callable(app, "_toggle_audio"), 220, 42, true)
	audio.name = "SettingsAudioButton"; audio.position = Vector2(155, 82)
	var volume_label := UI.make_child_label(panel, "VOLUME · %d%%" % int(app.audio_volume), 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 138, 460, 30))
	volume_label.name = "SettingsVolumeLabel"
	var volume := HSlider.new()
	volume.name = "SettingsVolumeSlider"
	volume.position = Vector2(65, 177); volume.size = Vector2(400, 28)
	volume.min_value = 0; volume.max_value = 100; volume.step = 1
	volume.value = app.audio_volume
	volume.value_changed.connect(Callable(app, "_set_audio_volume"))
	panel.add_child(volume)
	var test_sound := UI.make_button(panel, "TEST SOUND", Callable(app, "_test_audio"), 220, 38, true)
	test_sound.name = "SettingsTestSoundButton"; test_sound.position = Vector2(155, 218)
	UI.make_child_label(panel, "WASD / arrow keys or the touch pad to move.", 14, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, 260, 460, 26))
	var help := UI.make_button(panel, "HOW TO PLAY", Callable(app, "show_how_to_play").bind(""), 200, 40)
	help.position = Vector2(165, 288)
	var playing: bool = app.current_screen in ["game", "meeting"]
	if playing:
		var leave := UI.make_button(panel, "LEAVE GAME", Callable(app, "show_exit_confirmation"), 180, 40)
		leave.name = "SettingsLeaveGameButton"; leave.position = Vector2(70, 344)
	refresh(true)


func show_help() -> void:
	var panel := dialog_panel("help", Rect2(325, 70, 630, 580))
	panel.name = "HowToPlayOverlay"
	UI.make_child_label(panel, "HOW TO PLAY", 26, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 20, 520, 42))
	var guide := RichTextLabel.new()
	guide.name = "HowToPlayGuide"
	guide.bbcode_enabled = true
	guide.fit_content = false
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.scroll_active = true
	guide.add_theme_font_size_override("normal_font_size", 16)
	guide.add_theme_color_override("default_color", Data.CREAM)
	guide.add_theme_constant_override("line_separation", 3)
	guide.text = "[color=#f7c35a][b]Orang Kampung[/b][/color]\nFinish tasks, inspect clues, and vote at the gong.\n\n[color=#f7c35a][b]Jampi Tidur[/b][/color]\nVillagers sleep until the match ends. They can watch nearby events but cannot move, chat, vote, or act.\n\n[color=#f7c35a][b]Kabus & Sumpahan Pintu[/b][/color]\nFog covers Nenek's nearby surroundings for 20 seconds. Door locking closes every entrance of her current section for 10 seconds. Both share a two-minute recharge.\n\n[color=#f7c35a][b]Controls[/b][/color]\nMove with WASD, arrow keys, or the touch pad. Press E near a task."
	guide.position = Vector2(42, 80); guide.size = Vector2(546, 402)
	panel.add_child(guide)


func confirm(title: String, message: String, callback: Callable) -> void:
	var panel := dialog_panel("confirm", Rect2(390, 215, 500, 290))
	panel.name = "LeaveConfirmation"
	UI.make_child_label(panel, title, 26, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(24, 22, 398, 44))
	UI.make_child_label(panel, message, 17, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(42, 80, 416, 78))
	var yes := UI.make_button(panel, "YES, LEAVE", func(): close_dialog(); callback.call(), 170, 46, true)
	yes.name = "ConfirmLeaveButton"; yes.position = Vector2(62, 190)
	var stay := UI.make_button(panel, "STAY", close_dialog, 170, 46)
	stay.name = "CancelLeaveButton"; stay.position = Vector2(268, 190)
