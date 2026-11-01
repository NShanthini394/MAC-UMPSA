extends SceneTree
const Store = preload("res://scripts/settings_store.gd")
const Profiles = preload("res://scripts/account_profiles.gd")
const Meeting = preload("res://scripts/meeting_view.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func settle() -> void:
	for frame in 8: await process_frame
func run() -> void:
	Store.load_values(); var saved := Store.values.duplicate()
	var old_path := Profiles.path; Profiles.path="user://chat-layout-test.cfg"
	var app=load("res://scenes/main.tscn").instantiate(); root.add_child(app); await settle()
	app.online_server_url=""; app.set_process(false)
	var language: Node = app.huawei_translation.app_language
	language.preferences_path="user://chat-layout-language-test.cfg"
	app.lobby_players=[{"id":7,"name":"Shanthini","character":"Badang","alive":true}]
	var messages := ["Everyone, I was working on pound the herbs.","Shanthini, I can't confirm a suspect. I was working on pound the herbs. What clue did you find?","தடயங்களை ஒப்பிட்டு பார்த்த பிறகு யார் மீது சந்தேகம் என்பதை முடிவு செய்யலாம். நான் சமையலறையில் வேலை செய்து கொண்டிருந்தேன்.","我正在厨房完成任务。我们应该先比较线索，再决定要投票给谁。", "Saya sedang menyelesaikan tugasan di dapur. Mari bandingkan petunjuk sebelum mengundi."]
	for dimensions in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(1920,1200)]:
		root.size=dimensions
		for font_size in [18,24,28]:
			Store.set_value("text_size",font_size)
			Meeting.discussion(app)
			for i in messages.size(): Meeting.append_chat(app,app.network_manager.local_peer_id() if i%2==0 else 7,"Shanthini" if i%2==0 else "Jia Xin",messages[i])
			await settle()
			var log: Control=app.find_child("MeetingChatLog",true,false)
			for bubble in log.find_children("ChatBubble","PanelContainer",true,false):
				for label in bubble.find_children("*","Label",true,false):
					check(bubble.get_global_rect().encloses(label.get_global_rect()),"Wrapped multilingual message stays inside bubble")
					check(label.get_line_count()*label.get_line_height()<=label.size.y+1,"Actual font line height fits bubble")
			var scroll: ScrollContainer=app.find_child("MeetingChatScroll",true,false)
			check(scroll.get_v_scroll_bar().max_value>scroll.size.y,"Long chat scrolls within fixed discussion area")
			if DisplayServer.get_name()!="headless" and dimensions==Vector2i(1280,720) and font_size==24:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://output/chat-bubbles-fixed.png")
	app.queue_free(); await settle();Profiles.path=old_path
	for key in saved:Store.set_value(key,saved[key])
	print("CHAT BUBBLE LAYOUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
