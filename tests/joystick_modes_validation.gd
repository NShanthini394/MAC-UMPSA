extends SceneTree
const Store = preload("res://scripts/settings_store.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var checks := 0
var failures := 0
var app: Control
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func settle() -> void:
	await process_frame; await process_frame; await process_frame
func touch(pad: Control, at: Vector2, pressed: bool, id: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index=id; event.position=pad.get_global_transform_with_canvas()*at; event.pressed=pressed
	root.push_input(event,true); await settle()
func drag(pad: Control, at: Vector2, id: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index=id; event.position=pad.get_global_transform_with_canvas()*at; event.relative=Vector2(70,0)
	root.push_input(event,true); await settle()
func capture(title: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/controls_"+title+".png")
func run() -> void:
	Store.load_values(); var saved := Store.values.duplicate()
	Store.set_value("language","en"); Store.set_value("sensitivity",1.0); Store.set_value("joystick_visibility","touch")
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await settle()
	app.online_server_url="";app.set_process(false)
	check(Store.DEFAULTS.joystick_visibility=="touch","Show on Touch is default")
	for map_index in 3:
		app.selected_map=map_index; app.selected_character="Bawang Merah"; app.player_is_impostor=false;app.player_voted_out=false
		app.completed_tasks.assign([0,0,0,0,0,0,0,0,0,0,0,0]);app.task_progress.assign([0,0,0,0,0,0,0,0,0,0,0,0])
		app.player_position=Geometry.spawn_point(map_index)
		await app.build_game();await settle();app.player_body.set_physics_process(false)
		var pad:Control=app.find_child("VirtualJoystick",true,false)
		for dimensions in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(1920,1200)]:
			root.size=dimensions;await settle()
			check(app.get_viewport_rect().encloses(pad.get_global_rect()),"Joystick touch area fits phone/tablet")
			for mode in ["touch","hidden","always"]:
				Store.set_value("joystick_visibility",mode);await settle()
				check(pad.visual_visible()==(mode=="always"),"Resting visual follows setting "+mode)
				var origin:=Vector2(150,pad.size.y-160)
				await touch(pad,origin,true)
				check(pad.active and app.joystick_touch_id==0,"First touch owns floating joystick")
				check(pad.visual_visible()==(mode!="hidden"),"Touched visual follows setting "+mode)
				check(pad.visual_center().distance_to(origin)<1,"Joystick appears at exact lower-left touch point")
				await drag(pad,origin+Vector2(78,0))
				check(app.move_vector.x>0.85 and pad.displacement.x>70,"All display modes preserve movement")
				await touch(pad,origin+Vector2(20,0),true,1)
				await drag(pad,origin+Vector2(0,78),1)
				await touch(pad,origin,false,1)
				check(app.joystick_touch_id==0 and app.move_vector.x>0.85,"Second finger cannot move or release joystick")
				if map_index==1 and dimensions==Vector2i(1280,720): await capture(mode+"_active")
				await touch(pad,origin+Vector2(78,0),false)
				check(not pad.active and app.move_vector==Vector2.ZERO and app.joystick_touch_id==-1,"Release resets movement and thumb ownership")
				check(pad.visual_visible()==(mode=="always"),"Release hides touch-only mode")
				if map_index==1 and dimensions==Vector2i(1280,720): await capture(mode+"_rest")
			Store.set_value("joystick_visibility","touch");await settle()
			await touch(pad,Vector2(220,pad.size.y-140),true)
			await drag(pad,Vector2(220,pad.size.y-60))
			app.page_controls.show_settings();await settle()
			check(not pad.active and app.move_vector==Vector2.ZERO,"Opening Settings releases active joystick")
			var page:Control=app.find_child("SettingsPage",true,false)
			page.show_section("CONTROLS & DISPLAY");await settle()
			for pair in [["JoystickAlways","always"],["JoystickHidden","hidden"],["JoystickTouch","touch"]]:
				page.find_child(pair[0],true,false).pressed.emit();await settle()
				check(Store.get_value("joystick_visibility")==pair[1],"Settings row saves joystick choice")
			var config:=ConfigFile.new();config.load("user://preferences.cfg")
			check(config.get_value("settings","joystick_visibility")=="touch","Joystick choice persists to disk")
			if map_index==1 and dimensions==Vector2i(1280,720):await capture("settings")
			app.page_controls.close_dialog();await settle()
			app.player_sleeping=true;app._update_power_hud();await settle()
			await touch(pad,Vector2(200,pad.size.y-150),true);await drag(pad,Vector2(278,pad.size.y-150))
			check(app.move_vector.x>0.85,"Sleeping Villager can still move with joystick")
			await touch(pad,Vector2(278,pad.size.y-150),false);app.player_sleeping=false
			await touch(pad,Vector2(200,pad.size.y-150),true);await drag(pad,Vector2(278,pad.size.y-150))
			pad._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);await settle()
			check(not pad.active and app.move_vector==Vector2.ZERO,"Focus loss stops movement")
			Store.set_value("joystick_visibility","touch")
	app.queue_free();await settle()
	for key in saved: Store.set_value(key,saved[key])
	print("JOYSTICK MODES: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
