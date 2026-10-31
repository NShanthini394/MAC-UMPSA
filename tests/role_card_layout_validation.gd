extends SceneTree
const Data = preload("res://scripts/game_data.gd")
var app: Control
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)
func settle() -> void:
	await process_frame;await process_frame;await process_frame
func capture(name_: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/role_card_"+name_+".png")
func wait_for(predicate: Callable, message: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while not predicate.call():
		if Time.get_ticks_msec()>deadline: check(false,"Timed out: "+message);return false
		await process_frame
	return true
func validate_content(card: Panel, character: String, nenek: bool) -> void:
	var copy_labels: Array[Label]=[]
	for label in card.find_children("*","Label",true,false):
		copy_labels.append(label)
		check(label.get_theme_font_size("font_size")>=18,"Large readable fonts retained: "+character)
		check(label.get_line_count()*label.get_line_height()<=label.size.y+1,"Text fits its allotted height: "+str(label.name)+" / "+character)
		check(card.get_global_rect().encloses(label.get_global_rect()),"Text stays inside role card: "+str(label.name))
	for a in copy_labels.size():
		for b in range(a+1,copy_labels.size()):
			check(not copy_labels[a].get_global_rect().intersects(copy_labels[b].get_global_rect()),"Role text rows do not overlap: "+character)
	var value: Label=card.find_child("RoleCharacterValue",true,false)
	var title: Label=card.find_child("RoleTitleLabel",true,false)
	var portrait: Control=card.find_child("RolePortrait",true,false)
	check(value.text==character,"Correct assigned character name")
	check(title.text==("You are Nenek Kebayan" if nenek else "You are a Villager"),"Correct secret role title")
	for label in copy_labels: check(not portrait.get_global_rect().intersects(label.get_global_rect()),"Portrait does not overlap text")
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	await settle();app.online_server_url="";app.set_process(false)
	app.completed_tasks.clear();app.task_progress.clear()
	for index in Data.COMMON_TASKS.size(): app.completed_tasks.append(0);app.task_progress.append(0)
	await validate_all_characters()
	await validate_flow(false)
	await validate_flow(true)
	app.queue_free();await process_frame
	print("ROLE CARD LAYOUT: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func validate_all_characters() -> void:
	for window_size in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(1024,768)]:
		root.size=window_size;await settle()
		await app.clear_screen("role_reveal")
		for index in Data.CHARACTERS.size():
			for nenek in [false,true]:
				app.selected_character=Data.CHARACTERS[(index+3)%Data.CHARACTERS.size()]
				app.assigned_role_character=Data.CHARACTERS[index]
				app.player_is_impostor=nenek
				var frame: Panel=app.make_panel(Rect2(240,70,800,580),Color("21180f"))
				var card: Panel=app._build_revealed_role_card(frame);card.show()
				await settle()
				validate_content(card,Data.CHARACTERS[index],nenek)
				check(app.get_viewport_rect().encloses(frame.get_global_rect()),"Role frame stays on phone/tablet screen")
				frame.queue_free();await process_frame
func validate_flow(nenek: bool) -> void:
	root.size=Vector2i(1280,720);await settle()
	app.selected_map=0
	app.selected_character="Orang Kampung Lelaki" if not nenek else "Mahsuri"
	app.assigned_role_character="Raja Bersiung" if not nenek else "Puteri Gunung Ledang"
	app.player_is_impostor=nenek
	app._show_role_reveal()
	if not await wait_for(func()->bool:return app.current_screen=="role_reveal" and app.find_child("ShuffleCards",true,false)!=null,"shuffle frame"):return
	var shuffle: Control=app.find_child("ShuffleCards",true,false)
	var frame: Control=app.find_child("PrivateRoleReveal",true,false)
	check(frame.get_global_rect().encloses(shuffle.get_global_rect()),"Shuffle stays inside the larger role frame")
	if not await wait_for(func()->bool:
		var label: Label=app.find_child("RoleRevealCountdown",true,false)
		return label!=null and label.text=="Entering the village…", "revealed card after flip"):return
	var revealed_at := Time.get_ticks_msec()
	var card: Panel=app.find_child("RevealedRoleCard",true,false)
	validate_content(card,app.assigned_role_character,nenek)
	var privacy: Label=app.find_child("RoleRevealPrivacy",true,false)
	check(not card.get_global_rect().intersects(privacy.get_global_rect()),"Privacy note sits below role content")
	var countdown: Label=app.find_child("RoleRevealCountdown",true,false)
	check(not privacy.get_global_rect().intersects(countdown.get_global_rect()),"Countdown has its own row")
	await capture("nenek_reading" if nenek else "villager_reading")
	var seen: Array[int]=[]
	var first_tick_at := 0
	while app.current_screen=="role_reveal":
		if Time.get_ticks_msec()-revealed_at>7000: check(false,"Role did not enter gameplay");return
		var caption: Label=app.find_child("RoleRevealCountdown",true,false)
		if caption:
			for seconds in [3,2,1]:
				if caption.text=="Entering the village in %d…"%seconds and seconds not in seen:
					seen.append(seconds)
					if seconds==3:
						first_tick_at=Time.get_ticks_msec()
						check(app.audio_director.role_player.stream==app.audio_director.cached_streams["role_tick"],"Visible countdown has the matching tick sound")
						await capture("nenek_countdown" if nenek else "villager_countdown")
		await process_frame
	check(seen==[3,2,1],"Countdown shows exactly 3, 2, 1")
	check(first_tick_at-revealed_at>=1900,"Players get two seconds to read before countdown")
	check(Time.get_ticks_msec()-revealed_at>=4900,"Role is displayed for five seconds after flip")
	check(app.current_screen=="game","Countdown automatically enters the game")
