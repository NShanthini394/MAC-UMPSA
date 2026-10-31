extends SceneTree
const Store = preload("res://scripts/settings_store.gd")
const Profiles = preload("res://scripts/account_profiles.gd")
const QR = preload("res://scripts/room_qr.gd")
const Net = preload("res://scripts/network_manager.gd")
const Data = preload("res://scripts/game_data.gd")
var checks := 0
var failures := 0
var app: Control
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	await process_frame; await process_frame; await process_frame
func capture(title: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/combined_" + title + ".png")
func run() -> void:
	Store.load_values()
	var saved := Store.values.duplicate()
	Store.set_value("language", "en")
	var profiles_path := Profiles.path; Profiles.path = "user://huawei-combined-test-profile.cfg"
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app); await settle()
	app.online_server_url = ""
	var language: Node = app.huawei_translation.app_language
	language.preferences_path = "user://huawei-combined-test-languages.cfg"
	check(is_instance_valid(app.huawei_scan) and is_instance_valid(app.huawei_translation), "Both Huawei bridges survive screen changes")
	check(Net.LOBBY_WAIT_SECONDS == 5 and Net.QUICK_WAIT_SECONDS == 60, "Our five-second start and sixty-second search remain")
	check(app.find_child("LoginHero",true,false)!=null and app.find_child("LoginGoogleButton",true,false)!=null, "Our login artwork and providers remain")
	await app.build_menu(); await settle()
	check(app.find_child("StartGameButton",true,false)!=null, "Our Start Game menu remains")
	await capture("menu")
	app.build_play_modes(); await settle()
	for button in ["FriendsModeButton", "SoloModeButton", "QuickMatchButton"]:
		check(app.find_child(button,true,false)!=null,"Our mode exists: " + button)
	await capture("modes")
	for index in 4:
		language.select_language(index)
		check(Store.get_value("language")==language.CODES[index],"Settings persists language code")
		check(str(TranslationServer.get_locale()).begins_with(language.CODES[index]),"Godot locale matches chosen language")
		check(not language.text("START GAME").is_empty(),"Bundled main menu text exists")
		if index>0: check(language.text("START GAME")!="START GAME","Bundled menu is translated")
		for dimensions in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(1920,1200)]:
			root.size=dimensions; await settle()
			app.page_controls.show_settings(); await settle()
			var page: Control=app.find_child("SettingsPage",true,false)
			page.show_section("LANGUAGE"); await settle()
			language._collect(app); await settle()
			for button in ["LanguageEnglish","LanguageMalay","LanguageChinese","LanguageTamil"]:
				check(page.find_child(button,true,false)!=null,"All four language choices remain visible in our Settings")
			for label in page.find_children("*","Label",true,false):
				if label.text.is_empty() or label.clip_text: continue
				check(label.get_line_count()*label.get_line_height()<=label.size.y+2,"Language text fits: "+label.text.left(32))
			if dimensions==Vector2i(1280,720): await capture("language_"+language.CODES[index])
			app.page_controls.close_dialog(); await settle()
	language.select_language(0); root.size=Vector2i(1280,720); await settle()
	language.queue.clear(); language.attempted.clear(); language.selected=2
	language._enqueue("private@example.test password 123456 room ABC23")
	check(language.queue.is_empty(),"Unknown personal text never enters automatic translation queue")
	language.selected=2; language.active_id=1000042; language.active_source="Count %d"
	check(language._on_translated(1000042,"Count %s"),"Wrong placeholder response is consumed safely")
	check(not language.dictionaries.zh.has("Count %d"),"Wrong-placeholder translation is rejected")
	language.selected=0
	for code in ["ABC23", "QWERT"]:
		check(QR.parse(QR.payload(code))==code,"Room QR payload round-trips")
		var image:Image=QR.image_for_code(code)
		check(image!=null and image.get_size()==Vector2i(232,232),"Room QR encodes a complete image")
	check(QR.parse("https://example.test").is_empty() and QR.parse("NKR1:AAAA0").is_empty(),"QR parsing rejects unrelated data and invalid codes")
	app.internet_mode=true; app.room_code="ABC23"; app._show_room_qr(); await settle()
	check(app.find_child("RoomQrImage",true,false)!=null,"Host can display QR even without native SDK on desktop")
	await capture("room_qr"); app.navigate_back(); await settle()
	check(app.find_child("RoomQrOverlay",true,false)==null,"Back closes QR without leaving current screen")
	app.room_code=""; app.show_join_room(); await settle()
	check(app.find_child("ScanRoomQrButton",true,false)!=null,"Existing join form offers Scan QR")
	app._scan_room_qr(); await settle()
	check(app.find_child("JoinRoomStatusLabel",true,false).text.contains("Android"),"Desktop scanning explains the Android requirement")
	app._on_room_code_scanned("ABC23")
	check(app.find_child("JoinCodeEntry",true,false).text=="ABC23","Scanning fills the existing room code field")
	app._cancel_join_room(); await settle()
	check(not app.huawei_scan.scan_pending,"Leaving join cancels pending native scans")
	check(app.network_manager.active_room_code.is_empty(),"A QR scan never joins without player confirmation")
	app.queue_free(); await settle()
	DirAccess.remove_absolute("user://huawei-combined-test-profile.cfg")
	DirAccess.remove_absolute("user://huawei-combined-test-languages.cfg")
	Profiles.path=profiles_path
	for key in saved: Store.set_value(key,saved[key])
	print("HUAWEI COMBINED: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
