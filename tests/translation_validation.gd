extends SceneTree
var checks := 0
var failures := 0
class NativeMock extends RefCounted:
	var cancelled := 0
	func cancelTranslation() -> void: cancelled+=1

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	await app.build_menu()
	app.show_settings()
	var settings_language := app.find_child("SettingsLanguageButton",true,false) as OptionButton
	check(settings_language!=null and settings_language.item_count==4,"Settings offers English and all three translated languages")
	check(settings_language.selected==app.huawei_translation.app_language.selected,"Settings reflects the preferred app language")
	app.page_controls.close_dialog()
	app.show_how_to_play()
	var button := app.find_child("GuideTranslateButton",true,false) as Button
	check(button==null,"Guide uses the app language without a separate Translate action")
	var service: Node = app.huawei_translation
	var guide := app.find_child("HowToPlayGuide",true,false) as RichTextLabel
	service.open_text(guide,"Bridge test",guide.get_parsed_text())
	check(is_instance_valid(service.overlay),"Translate opens its dialog")
	check(service.language.item_count==3 and service.language.get_item_text(2)=="Tamil","Tamil is available in the language selector")
	check(service.TARGETS[2]=="ta","Tamil uses its correct language code")
	check(service.overlay.get_parent()==app.page_controls.get_node("PageControlsRoot"),"Translation appears above the help dialog")
	check(not service.source_text.contains("[color"),"Help sends plain text without formatting markup")
	var original: String = service.source_text
	service.request_translation()
	check(not service.pending and service.status.text.contains("Android"),"Desktop does not pretend to call Huawei translation")
	check(service.source_text==original,"Original English remains unchanged")
	var native := NativeMock.new()
	service.native=native
	service._on_translated(100,"Unsolicited result")
	check(not service.result_label.text.contains("Unsolicited"),"Unsolicited native callback is ignored")
	service.pending=true; service.request_id=101; service.pending_key="ms:"+original; service.submit.disabled=true
	service._on_translated(100,"Stale result")
	check(service.pending,"Stale callback cannot finish the active request")
	service._on_translated(101,"Mock translation fixture")
	check(not service.pending and not service.submit.disabled,"Successful callback restores the Translate button")
	check(service.result_label.text=="Mock translation fixture","Successful callback displays plain translated text")
	check(service.cache.has("ms:"+original),"Successful translation is cached by source and target")
	check(service.source_text==original,"Success does not replace gameplay source text")
	service.result_label.text=""; service.request_translation()
	check(service.result_label.text=="Mock translation fixture","Same-session cache avoids another request")
	service.pending=true; service.request_id=102; service.submit.disabled=true
	service._on_error(102,"Connection unavailable")
	check(not service.pending and not service.submit.disabled and service.status.text=="Connection unavailable","Failure restores controls and explains the problem")
	service.pending=true; service.submit.disabled=true
	service.language.select(1); service.language.item_selected.emit(1)
	check(not service.pending and service.result_label.text.is_empty(),"Changing language cancels the old request and clears its result")
	app.navigate_back()
	check(not is_instance_valid(service.overlay),"Back dismisses only the translation dialog")
	check(app.find_child("HowToPlayOverlay",true,false)!=null,"Help remains available behind the translation dialog")
	check(native.cancelled>0,"Cancellation reaches the native SDK bridge")
	service.open_text(app.page_controls.get_node("PageControlsRoot"),"Test","Cook the rice.")
	check(service.language.selected==service.preferred_language,"Translation opens with the preferred language")
	service.pending=true; var old_id: int=service.request_id
	service.close(); service._on_translated(old_id,"Late callback")
	check(not is_instance_valid(service.overlay) and not service.pending,"Closed dialogs ignore late results")
	var owner := Control.new(); app.add_child(owner)
	service.open_text(owner,"Test","Cook the rice.")
	owner.queue_free(); await process_frame; service._process(0)
	check(not is_instance_valid(service.overlay),"Removing the source task closes its translation")
	app.page_controls.close_dialog()
	app.player_is_impostor=false; app.selected_character="Badang"; app.selected_map=1
	app.completed_tasks.resize(app.GameData.COMMON_TASKS.size()); app.completed_tasks.fill(0)
	app.task_progress.resize(app.GameData.COMMON_TASKS.size()); app.task_progress.fill(0)
	app.player_position=app.MapGeometry.task_points(1)[0]
	await app.build_game()
	app.player_body.set_physics_process(false)
	app.open_task(0)
	var task_button := app.find_child("TaskTranslateButton",true,false) as Button
	check(task_button==null,"Task instructions use Settings instead of a Translate button")
	service.open_text(app.find_child("TaskOverlay",true,false),"Task bridge test",app.GameData.COMMON_TASKS[0]["prompt"])
	check(service.source_text==app.GameData.COMMON_TASKS[0]["prompt"],"Task translation uses the instruction shown to the player")
	check(app.task_progress[0]==0,"Opening translation does not advance a task")
	service.close(); app._close_task(); await process_frame
	app.show_clue_panel("Old rattan basket","Hidden Impostor")
	var clue_button := app.find_child("ClueTranslateButton",true,false) as Button
	check(clue_button==null,"Clue uses the app language without a Translate button")
	var clue_label := app.find_child("ClueNameLabel",true,false) as Label
	check(clue_label!=null and clue_label.text=="Old rattan basket","Clue displays its authored name")
	service.open_text(clue_label,"Clue bridge test",clue_label.text)
	check(service.source_text=="Old rattan basket","Clue translation includes the discovered clue only")
	check(not service.source_text.contains("Hidden Impostor"),"Clue translation does not include the secret character argument")
	app.queue_free(); await process_frame
	print("TRANSLATION CHECKS: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
