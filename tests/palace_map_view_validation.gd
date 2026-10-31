extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
const UI = preload("res://scripts/game_ui.gd")
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
	root.get_texture().get_image().save_png("res://.godot/page-previews/palace_"+name_+".png")
func tap(control: Control) -> void:
	var event := InputEventScreenTouch.new()
	event.index=0;event.position=control.get_global_rect().get_center();event.pressed=true
	root.push_input(event,true);await process_frame
	event=InputEventScreenTouch.new()
	event.index=0;event.position=control.get_global_rect().get_center();event.pressed=false
	root.push_input(event,true);await settle()
func run() -> void:
	await validate()
	if is_instance_valid(app): app.queue_free()
	await process_frame
	print("PALACE MAP VIEW: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func prepare(map_index: int, nenek: bool = false) -> Control:
	app.selected_map=map_index;app.player_is_impostor=nenek
	app.selected_character="Bawang Putih"
	app.completed_tasks.clear();app.task_progress.clear()
	for index in Data.COMMON_TASKS.size(): app.completed_tasks.append(0);app.task_progress.append(0)
	app.player_position=Geometry.spawn_point(map_index)
	await app.build_game();app.player_body.set_physics_process(false)
	app.show_map_overlay();await settle()
	return app.find_child("MapOverlay",true,false)
func validate() -> void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	await settle();app.set_process(false);app.online_server_url=""
	for map_index in 3:
		var view := await prepare(map_index)
		var map_tab: Button=view.find_child("MapTab",true,false)
		var tasks_tab: Button=view.find_child("MapTasksTab",true,false)
		check(map_tab.button_pressed and not tasks_tab.button_pressed,"MAP is selected on opening map %d"%map_index)
		await tap(tasks_tab)
		check(view._tasks.visible and not view._legend.visible,"Touch opens TASKS on map %d"%map_index)
		check(tasks_tab.button_pressed and not map_tab.button_pressed,"TASKS highlight follows touch on map %d"%map_index)
		check(tasks_tab.get_theme_stylebox("normal").texture==UI.menu_button_style("red").texture,"TASKS gets red active style on map %d"%map_index)
		check(map_tab.get_theme_stylebox("normal").texture!=UI.menu_button_style("red").texture,"Inactive MAP loses red on map %d"%map_index)
		check(view._buttons.all(func(button: Button)->bool:return button.size==Vector2(208,72)),"Task rows have equal width and two-line height")
		check(view._buttons.size()==Data.COMMON_TASKS.size(),"All twelve tasks remain on map %d"%map_index)
		if map_index==0:
			await tap(view._buttons[2])
			check(view.selected==2 and view._buttons[2].button_pressed,"Touch selects palace task three")
			await capture("selected_task_3")
			for index in Data.COMMON_TASKS.size():
				view._buttons[index].pressed.emit()
				check(view.selected==index,"Task button chooses its matching task")
				for other in Data.COMMON_TASKS.size():
					var expected: String="red" if index==other else "jade"
					check(view._buttons[other].get_theme_stylebox("normal").texture==UI.menu_button_style(expected).texture,"Only selected palace task is red")
			view._choose(2);app.completed_tasks[2]=1;await settle()
			check(view._buttons[2].modulate==Color.WHITE and view._buttons[2].get_theme_stylebox("normal").texture==UI.menu_button_style("red").texture,"Completion retains the selected red style")
			check(view._task_badges[2].text=="✓","Selected completed task retains its check mark")
		else:
			check(view._buttons[2].toggle_mode,"House task rows support selected highlights")
		view._choose(5)
		check(view._details.visible and view.canvas.selected==5 and view._map_tab.button_pressed,"Choosing a task automatically shows its map details")
		await tap(tasks_tab)
		await capture("tasks_%d"%map_index)
		view._tasks.scroll_vertical=9999;await settle()
		check(view._tasks.get_global_rect().intersects(view._buttons[-1].get_global_rect()),"Task list scroll reaches task twelve on map %d"%map_index)
		view._tasks.scroll_vertical=0
		await tap(map_tab)
		check(map_tab.button_pressed and not tasks_tab.button_pressed,"MAP highlight returns on map %d"%map_index)
		check(view.canvas.selected==5 and view._details.visible,"MAP retains selected task and place")
		if map_index==0:
			check(view.canvas.get_script().resource_path.ends_with("palace_map_3d.gd"),"The palace uses the 3D viewer")
			check(view.canvas.viewport_3d.own_world_3d and view.canvas.camera is Camera3D,"Palace renders an isolated real 3D scene")
			check(view.canvas.world.find_children("CutawayWall_*","MeshInstance3D",false,false).size()>20,"Cutaway walls are built from floor boundaries")
			check(view.canvas.world.find_children("DoorThreshold_*","MeshInstance3D",false,false).size()==Geometry.floor_plan(0).layout["doors"].size(),"All real entrances are retained")
			check(view.canvas._marker_points.size()==Data.COMMON_TASKS.size(),"All twelve 3D task markers are projected")
			var bounds := Rect2(Vector2(18,18),view.canvas.size-Vector2(36,36))
			for at in view.canvas._marker_points: check(bounds.has_point(at),"Task marker is inside fitted 3D view")
			var panel := view.find_child("MapViewPanel",true,false) as Panel
			check(panel.get_theme_stylebox("panel").bg_color==Data.SECTION_PANEL,"Map outer frame matches the map-selection palette")
			await capture("3d_map")
			var marker: Vector2=view.canvas.task_marker_position(10)
			view.canvas._start(marker);view.canvas._finish(marker)
			check(view.selected==10,"3D marker chooses its actual task")
			view.canvas.change_zoom(1.2)
			check(view.canvas.zoom>1,"3D zoom works")
			view.canvas._start(Vector2(400,200));view.canvas._move(Vector2(470,220),Vector2(70,20));view.canvas._finish(Vector2(470,220))
			check(view.canvas.yaw != -22.0,"3D drag changes the viewing angle")
			view.canvas.reset_view()
			check(view.canvas.zoom==1 and view.canvas.yaw==-22 and view.canvas.pitch==48,"FIT resets zoom and rotation")
			var before: Vector2=view.canvas.world_to_screen(app.player_body.global_position)
			app.player_body.global_position=Geometry.task_points(0)[0]
			check(view.canvas.world_to_screen(app.player_body.global_position).distance_to(before)>20,"Live player position projects into the map")
			app.completed_tasks[0]=1;await settle()
			check(view._task_badges[0].text=="✓","Live task completion updates the viewer")
		else:
			check(view.canvas.get_script().resource_path.ends_with("palace_map_3d.gd"),"House map %d uses the 3D cutaway"%map_index)
			check(view.canvas.viewport_3d.own_world_3d and view.canvas.camera is Camera3D,"House map has an isolated real 3D scene")
			check(view.canvas.world.find_children("DoorThreshold_*","MeshInstance3D",false,false).size()==Geometry.floor_plan(map_index).layout["doors"].size(),"House retains all actual entrances")
			check(view.canvas._marker_points.size()==Data.COMMON_TASKS.size(),"House projects all twelve tasks")
			var bounds := Rect2(Vector2(18,18),view.canvas.size-Vector2(36,36))
			for at in view.canvas._marker_points: check(bounds.has_point(at),"House task marker fits the 3D view")
			var marker: Vector2=view.canvas.task_marker_position(10)
			view.canvas._start(marker);view.canvas._finish(marker)
			check(view.selected==10,"House 3D marker selects matching task")
			view.canvas.change_zoom(1.2)
			check(view.canvas.zoom>1,"House 3D zoom works")
			view.canvas._start(Vector2(400,200));view.canvas._move(Vector2(470,220),Vector2(70,20));view.canvas._finish(Vector2(470,220))
			check(view.canvas.yaw != -22.0,"House 3D drag rotates")
			view.canvas.reset_view()
			check(view.canvas.zoom==1 and view.canvas.yaw==-22,"House FIT restores view")
			await capture("house_3d_%d"%map_index)
		view.queue_free();await settle()
	for window_size in [Vector2i(2400,1080),Vector2i(1920,1200)]:
		root.size=window_size;await settle()
		var view := await prepare(0)
		var panel: Control=view.find_child("MapViewPanel",true,false)
		check(panel.get_global_rect().get_center().distance_to(app.get_viewport_rect().size*0.5)<2,"Palace viewer is centred at "+str(window_size))
		await tap(view.find_child("MapTasksTab",true,false));check(view._tasks.visible,"Wide/tablet tab touch stays aligned")
		await tap(view.find_child("MapTab",true,false))
		await capture("3d_%dx%d"%[window_size.x,window_size.y])
		view.queue_free();await settle()
	var nenek_view := await prepare(0,true)
	nenek_view._tab(true);await settle()
	check(not nenek_view._tasks.visible and not nenek_view._tasks_tab.visible,"Nenek has no task list")
	check(nenek_view.canvas._marker_points.is_empty(),"Nenek has no task markers in 3D")
	check(nenek_view._map_tab.button_pressed,"Nenek remains on the MAP tab")
	for map_index in [1,2]:
		nenek_view.queue_free();await settle()
		nenek_view=await prepare(map_index,true)
		check(nenek_view.canvas._marker_points.is_empty() and not nenek_view._tasks_tab.visible,"House Nenek sees no task markers or task list")
