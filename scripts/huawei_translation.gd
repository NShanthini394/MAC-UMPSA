extends Node
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const TARGETS := ["ms","zh","ta"]
const LANGUAGE_NAMES := ["Bahasa Melayu", "Chinese", "Tamil"]
var preferred_language := 0
var app: Control
var native: Object
var overlay: ColorRect
var source_owner: WeakRef
var source_text := ""
var cache: Dictionary = {}
var request_id := 0
var pending := false
var pending_key := ""
var result_label: RichTextLabel
var status: Label
var language: OptionButton
var submit: Button
var app_language: Node

func _ready() -> void:
	var preferences := ConfigFile.new()
	if preferences.load("user://language.cfg") == OK:
		preferred_language = clampi(int(preferences.get_value("translation", "language", 0)), 0, TARGETS.size()-1)
	if Engine.has_singleton("KampungHuaweiTranslate"):
		native = Engine.get_singleton("KampungHuaweiTranslate")
		native.connect("translated",_on_translated)
		native.connect("translation_error",_on_error)
	app_language = preload("res://scripts/app_language.gd").new()
	app_language.name = "AppLanguage"
	app_language.bridge = self
	add_child(app_language)
	var keyboard := preload("res://scripts/keyboard_avoider.gd").new()
	keyboard.name = "KeyboardAvoider"
	add_child(keyboard)

func set_preferred_language(index: int) -> void:
	preferred_language = clampi(index, 0, TARGETS.size()-1)
	var preferences := ConfigFile.new()
	preferences.set_value("translation", "language", preferred_language)
	preferences.save("user://language.cfg")

func _process(_delta: float) -> void:
	if is_instance_valid(overlay) and source_owner!=null:
		var owner = source_owner.get_ref()
		if not is_instance_valid(owner) or owner.is_queued_for_deletion(): close()

func close() -> void:
	if is_instance_valid(app_language): app_language.cancel_job()
	request_id += 1
	pending = false
	if native!=null: native.call("cancelTranslation")
	if is_instance_valid(overlay):
		overlay.get_parent().remove_child(overlay)
		overlay.queue_free()
	overlay = null
	source_owner = null

func open_text(owner: Node, heading: String, text: String) -> void:
	close()
	app._stop_move()
	source_owner = weakref(owner)
	source_text = text.strip_edges()
	overlay = preload("res://scripts/fullscreen_shade.gd").new()
	overlay.name = "TranslationOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0,0,0,0.8)
	overlay.z_index = 100
	# Utility dialogs use a higher CanvasLayer than gameplay; share that layer.
	var parent: Node = app.page_controls.get_node("PageControlsRoot")
	parent.add_child(overlay)
	var panel := UI.make_panel(overlay.get_node("ShadeContent"),Rect2(260,85,760,550),Color("24180f"))
	UI.make_child_label(panel,"TRANSLATE · "+heading,23,Data.GOLD,HORIZONTAL_ALIGNMENT_CENTER,Rect2(30,16,650,42))
	var exit := UI.make_button(panel,"×",close,42,42)
	exit.position = Vector2(706,10)
	UI.make_child_label(panel,"Original (English)",14,Data.GOLD,HORIZONTAL_ALIGNMENT_LEFT,Rect2(30,64,680,24))
	_text_box(panel,text,Rect2(30,93,700,93))
	language = OptionButton.new()
	language.name = "TranslationLanguage"
	language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for title in LANGUAGE_NAMES: language.add_item(title)
	language.select(preferred_language)
	language.position=Vector2(30,198); language.size=Vector2(260,36)
	language.item_selected.connect(func(_index: int):
		set_preferred_language(_index)
		request_id+=1; pending=false
		if native!=null: native.call("cancelTranslation")
		submit.disabled=false; result_label.text=""; status.text="Tap TRANSLATE to request the selected language.")
	panel.add_child(language)
	result_label = _text_box(panel,"The translation will appear here.",Rect2(30,247,700,125))
	result_label.name = "TranslationResult"
	status = UI.make_child_label(panel,"The text above is sent to Huawei when you tap Translate. Internet is required.",14,Data.CREAM,HORIZONTAL_ALIGNMENT_CENTER,Rect2(30,383,700,60))
	status.name = "TranslationStatus"
	submit = UI.make_button(panel,"TRANSLATE",request_translation,270,46,true)
	submit.name = "RequestTranslationButton"; submit.position=Vector2(245,465)
	if OS.get_name()!="Android" or native==null:
		status.text="Live translation is available in the Android APK. The original text remains readable here."

func _text_box(parent: Control, text: String, rect: Rect2) -> RichTextLabel:
	var box := RichTextLabel.new()
	box.bbcode_enabled=false
	box.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.text=text
	box.scroll_active=true
	box.position=rect.position; box.size=rect.size
	box.add_theme_color_override("default_color",Data.CREAM)
	box.add_theme_font_size_override("normal_font_size",17)
	parent.add_child(box)
	return box

func _configuration() -> Dictionary:
	var path := "res://config/huawei-public.json"
	if not FileAccess.file_exists(path) and OS.has_feature("editor"): path="res://config/agconnect-services.json"
	if not FileAccess.file_exists(path): return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("client") is Dictionary: return {}
	return data.client

func request_translation() -> void:
	if pending or not is_instance_valid(overlay): return
	if source_text.is_empty() or source_text.length()>4000:
		status.text="This text cannot be translated. Please read the original."; return
	var target: String = TARGETS[language.selected]
	var key := target+":"+source_text
	if cache.has(key):
		result_label.text=cache[key]; status.text="Translation from this session."; return
	if OS.get_name()!="Android" or native==null:
		status.text="Use the Android APK for Huawei translation."; return
	var config := _configuration()
	if str(config.get("api_key","")).is_empty() or str(config.get("app_id","")).is_empty():
		status.text="Translation is not configured for this build yet."; return
	request_id+=1; pending=true; pending_key=key
	submit.disabled=true; result_label.text=""
	status.text="Checking language availability and translating…"
	var current := request_id
	native.call("translate",current,source_text,target,str(config.app_id),str(config.api_key))
	get_tree().create_timer(20.0).timeout.connect(func():
		if pending and request_id==current:
			if native!=null: native.call("cancelTranslation")
			_on_error(current,"Translation took too long. Check your connection and try again."))

func _on_translated(id: int, text: String) -> void:
	if is_instance_valid(app_language) and app_language._on_translated(id, text): return
	if not pending or id!=request_id or not is_instance_valid(overlay): return
	pending=false; submit.disabled=false
	if text.strip_edges().is_empty(): status.text="No translation was returned. Please try again."; return
	if cache.size()>=128: cache.clear()
	cache[pending_key]=text
	result_label.text=text
	status.text="Translated by Huawei ML Kit. The original text remains unchanged."

func _on_error(id: int, message: String) -> void:
	if is_instance_valid(app_language) and app_language._on_error(id, message): return
	if not pending or id!=request_id or not is_instance_valid(overlay): return
	pending=false; submit.disabled=false; status.text=message
