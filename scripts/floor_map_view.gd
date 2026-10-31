extends Control
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var _map_tab: Button
var _tasks_tab: Button
var _palace := false
var app: Control
var canvas: Control
var _legend: Control
var _tasks: Control
var _selection: Label
var _place: Label
var _details: Control
var _route: Button
var _buttons: Array[Button] = []
var _task_badges: Array[Label] = []
var selected := -1
var _last_completed := -1
var _route_pulse: Tween
var _route_glow: Panel

func _process(_delta: float) -> void:
	if not is_instance_valid(app) or app.player_is_impostor or _buttons.size()!=Data.COMMON_TASKS.size(): return
	var state := hash(app.completed_tasks)
	if state==_last_completed: return
	_last_completed=state
	_refresh_task_buttons()
	if selected>=0: _refresh_selection_details()

func configure(controller: Control) -> void:
	app=controller; name="MapOverlay"; z_index=30
	_palace=true # All three maps share the interactive 3D cutaway viewer.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color=Color(0.06,0.04,0.02,0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel_size := Vector2(1180,630)
	var panel := UI.make_panel(self,Rect2((size-panel_size)*0.5,panel_size),Data.SECTION_PANEL)
	panel.name="MapViewPanel"
	var border := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	border.border_color=Color("b19a6b")
	panel.add_theme_stylebox_override("panel",border)
	var peta := UI.make_button(panel,"MAP",_tab.bind(false),112,42,true)
	peta.name="MapTab"; peta.toggle_mode=true; _map_tab=peta
	peta.position=Vector2(20,18)
	var tasks := UI.make_button(panel,"TASKS",_tab.bind(true),112,42)
	tasks.name="MapTasksTab"; tasks.visible=not app.player_is_impostor
	tasks.toggle_mode=true; _tasks_tab=tasks
	tasks.position=Vector2(144,18)
	UI.make_child_label(panel,Data.MAPS[app.selected_map]["name"],22,Data.GOLD,HORIZONTAL_ALIGNMENT_LEFT,Rect2(284,18,790,42))
	var close := UI.make_button(panel,"×",queue_free,42,42)
	close.name="MapCloseButton"; close.position=Vector2(1128,12)
	if _palace: UI.apply_menu_button(close,"jade")
	_legend=Control.new(); _legend.position=Vector2(22,92); _legend.size=Vector2(228,330); panel.add_child(_legend)
	UI.make_child_label(_legend,"MAP KEY",17,Data.GOLD,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,0,228,30))
	var legend_lines := ["▲   Your position","1–12   Unfinished tasks","✓   Completed tasks","▣   Room / area","┄   Door / access"]
	if app.player_is_impostor: legend_lines=["▲   Your position","▣   Room / area","┄   Door / access"]
	for index in legend_lines.size(): UI.make_child_label(_legend,legend_lines[index],15,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,50+index*40,228,36))
	var instruction := UI.make_child_label(_legend,"Choose a task number\nto see its location:",14,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,270,228,56))
	instruction.name="MapNumberInstruction"
	if app.player_is_impostor: instruction.text="View rooms and paths\non the map."
	_tasks=ScrollContainer.new(); _tasks.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; _tasks.position=Vector2(22,92); _tasks.size=Vector2(228,464); panel.add_child(_tasks)
	var task_rows := VBoxContainer.new()
	task_rows.add_theme_constant_override("separation",2)
	_tasks.add_child(task_rows)
	for index in Data.COMMON_TASKS.size():
		# Button text contributes an unwrapped minimum width. Keep it empty and
		# draw the name in a fixed, wrapping child so every row stays identical.
		var button := UI.make_button(task_rows,"",_choose.bind(index),208,72)
		button.position=Vector2(0,index*74)
		button.clip_contents=true
		button.accessibility_name=str(Data.COMMON_TASKS[index]["name"])
		button.toggle_mode=true
		if _palace: UI.apply_menu_button(button,"jade")
		var badge := UI.make_child_label(button,str(index+1),13,Data.CREAM,HORIZONTAL_ALIGNMENT_CENTER,Rect2(14,0,24,72))
		_task_badges.append(badge)
		var copy: String = str(Data.COMMON_TASKS[index]["name"])
		copy=copy.replace("marbles into", "marbles\ninto")
		var task_name := UI.make_child_label(button,copy,14,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(42,9,152,54))
		task_name.name="TaskEntryName_%d"%index
		_buttons.append(button)
	_details=Control.new(); _details.name="SelectedTaskDetails"
	_details.position=Vector2(22,430); _details.size=Vector2(228,126); panel.add_child(_details)
	_selection=UI.make_child_label(_details,"",15,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,0,228,66))
	_selection.name="SelectedTaskName"
	_selection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_selection.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	_place=UI.make_child_label(_details,"",14,Data.GOLD,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,72,228,48))
	_place.name="SelectedTaskPlace"
	_place.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_place.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	_route=UI.make_button(panel,"SHOW ROUTE",_navigate,228,42,true)
	_route.name="ShowRouteButton"
	_route.position=Vector2(22,570); _route.disabled=true
	_route.pivot_offset=_route.size*0.5
	_route_glow=Panel.new();_route_glow.name="RouteAttentionGlow"
	_route_glow.position=Vector2(-5,-5);_route_glow.size=Vector2(238,52)
	_route_glow.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_route_glow.show_behind_parent=true
	var glow_style:=StyleBoxFlat.new()
	glow_style.bg_color=Color("ffe9a0",0.25);glow_style.border_color=Color("ddac40")
	glow_style.set_border_width_all(2);glow_style.set_corner_radius_all(8)
	glow_style.shadow_color=Color("d9a63f",0.5);glow_style.shadow_size=9
	_route_glow.add_theme_stylebox_override("panel",glow_style)
	_route.add_child(_route_glow);_route_glow.hide()
	canvas=load("res://scripts/palace_map_3d.gd").new() as Control
	canvas.name="FloorPlanCanvas"; canvas.position=Vector2(272,84); canvas.size=Vector2(886,458)
	panel.add_child(canvas); canvas.call("configure",app)
	canvas.connect("task_selected",_choose)
	UI.make_child_label(panel,"3D map • open rooms and connected paths",13,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(280,551,630,25))
	var zoom_out := UI.make_button(panel,"−",func():canvas.call("change_zoom",1/1.2),44,40)
	zoom_out.position=Vector2(960,572)
	var zoom_in := UI.make_button(panel,"+",func():canvas.call("change_zoom",1.2),44,40)
	zoom_in.position=Vector2(1010,572)
	var reset := UI.make_button(panel,"FIT",func():canvas.call("reset_view"),90,40)
	reset.position=Vector2(1060,572); reset.add_theme_font_size_override("font_size",13)
	if _palace:
		for button in [zoom_out,zoom_in,reset]: UI.apply_menu_button(button,"jade")
	_style_outer_labels(panel)
	_tab(false)
	app.page_controls.refresh(true)

func _tab(tasks: bool) -> void:
	if app.player_is_impostor: tasks=false
	_map_tab.set_pressed_no_signal(not tasks)
	_tasks_tab.set_pressed_no_signal(tasks)
	UI.apply_menu_button(_map_tab,"red" if not tasks else ("jade" if _palace else "wood"))
	UI.apply_menu_button(_tasks_tab,"red" if tasks else ("jade" if _palace else "wood"))
	_tasks.visible=tasks; _legend.visible=not tasks
	_details.visible=not tasks and selected>=0
	_route.visible=not tasks and selected>=0
	canvas.set("selected",-1 if tasks else selected)
	_update_route_attention()

func _choose(index: int) -> void:
	if app.player_is_impostor: return
	selected=index
	_refresh_task_buttons()
	_tab(false)
	_refresh_selection_details()

func _refresh_selection_details() -> void:
	if selected<0: return
	var index:=selected
	var section_id: int = Geometry.floor_plan(app.selected_map).layout["task_sections"][index]
	var place: String = Geometry.floor_plan(app.selected_map).layout["sections"][section_id]["name"]
	_selection.text="%d. %s"%[index+1,Data.COMMON_TASKS[index]["name"]]
	_place.text=place
	_details.visible=not _tasks.visible
	_route.visible=not _tasks.visible
	_route.disabled=app.completed_tasks[index]==1 or not app.can_local_act()
	_route.text="COMPLETED" if app.completed_tasks[index]==1 else "SHOW ROUTE"
	_update_route_attention()

func _refresh_task_buttons() -> void:
	for index in _buttons.size():
		var complete: bool = index<app.completed_tasks.size() and app.completed_tasks[index]==1
		_task_badges[index].text="✓" if complete else str(index+1)
		var button := _buttons[index]
		var chosen := index==selected
		button.set_pressed_no_signal(chosen)
		UI.apply_menu_button(button,"red" if chosen else ("jade" if _palace else "wood"))
		button.modulate=Color.WHITE

func _style_outer_labels(panel: Panel) -> void:
	for label in panel.find_children("*","Label",true,false):
		var ancestor: Node=label.get_parent()
		var inside_button:=false
		while ancestor!=panel and ancestor!=null:
			if ancestor is BaseButton: inside_button=true;break
			ancestor=ancestor.get_parent()
		if inside_button or canvas.is_ancestor_of(label): continue
		label.add_theme_color_override("font_color",Color("fff0cf"))
		label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.3))
		if label.text in ["MAP KEY",Data.MAPS[app.selected_map]["name"]]: label.add_theme_color_override("font_color",Color("ffe0a3"))
	_place.add_theme_color_override("font_color",Color("f5dfa7"))

func _update_route_attention() -> void:
	if not is_instance_valid(_route): return
	var active:=_route.visible and not _route.disabled and selected>=0
	if active and _route_pulse!=null and _route_pulse.is_valid(): return
	if _route_pulse!=null and _route_pulse.is_valid(): _route_pulse.kill()
	_route_pulse=null
	_route.scale=Vector2.ONE
	_route_glow.visible=active
	if not active: return
	_route_glow.modulate.a=0.25
	_route_pulse=create_tween().set_loops()
	_route_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_route_pulse.tween_property(_route,"scale",Vector2.ONE*1.03,0.65)
	_route_pulse.parallel().tween_property(_route_glow,"modulate:a",0.9,0.65)
	_route_pulse.tween_property(_route,"scale",Vector2.ONE,0.65)
	_route_pulse.parallel().tween_property(_route_glow,"modulate:a",0.25,0.65)

func _navigate() -> void:
	if selected<0: return
	if app.completed_tasks[selected]==1: _choose(selected); return
	app._travel_hint(selected)
	queue_free()
