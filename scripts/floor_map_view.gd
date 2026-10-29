extends Control
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
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

func _process(_delta: float) -> void:
	if not is_instance_valid(app) or app.player_is_impostor or _buttons.size()!=8: return
	var state := hash(app.completed_tasks)
	if state==_last_completed: return
	_last_completed=state
	for index in 8:
		var complete: bool = app.completed_tasks[index]==1
		_task_badges[index].text="✓" if complete else str(index+1)
		_buttons[index].modulate=Color("b7d391") if complete else Color.WHITE
	if selected>=0: _choose(selected)

func configure(controller: Control) -> void:
	app=controller; name="MapOverlay"; z_index=30
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color=Color(0.06,0.04,0.02,0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel_size := Vector2(1180,630)
	var panel := UI.make_panel(self,Rect2((get_viewport_rect().size-panel_size)*0.5,panel_size),Color("302519"))
	var peta := UI.make_button(panel,"MAP",_tab.bind(false),112,42,true)
	peta.position=Vector2(20,18)
	var tasks := UI.make_button(panel,"TASKS",_tab.bind(true),112,42)
	tasks.name="MapTasksTab"; tasks.visible=not app.player_is_impostor
	tasks.position=Vector2(144,18)
	UI.make_child_label(panel,Data.MAPS[app.selected_map]["name"],22,Data.GOLD,HORIZONTAL_ALIGNMENT_LEFT,Rect2(284,18,790,42))
	var close := UI.make_button(panel,"×",queue_free,42,42)
	close.name="MapCloseButton"; close.position=Vector2(1128,12)
	_legend=Control.new(); _legend.position=Vector2(22,92); _legend.size=Vector2(228,330); panel.add_child(_legend)
	UI.make_child_label(_legend,"MAP KEY",17,Data.GOLD,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,0,228,30))
	var legend_lines := ["▲   Your position","1–8   Unfinished tasks","✓   Completed tasks","▣   Room / area","┄   Door / access"]
	if app.player_is_impostor: legend_lines=["▲   Your position","▣   Room / area","┄   Door / access"]
	for index in legend_lines.size(): UI.make_child_label(_legend,legend_lines[index],15,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,50+index*40,228,36))
	var instruction := UI.make_child_label(_legend,"Choose a task number\nto see its location:",14,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,270,228,56))
	instruction.name="MapNumberInstruction"
	if app.player_is_impostor: instruction.text="View rooms and paths\non the map."
	_tasks=Control.new(); _tasks.position=Vector2(22,92); _tasks.size=Vector2(228,464); panel.add_child(_tasks)
	for index in 8:
		# Button text contributes an unwrapped minimum width. Keep it empty and
		# draw the name in a fixed, wrapping child so every row stays identical.
		var button := UI.make_button(_tasks,"",_choose.bind(index),228,56)
		button.position=Vector2(0,index*58)
		button.clip_contents=true
		button.accessibility_name=str(Data.COMMON_TASKS[index]["name"])
		var badge := UI.make_child_label(button,str(index+1),13,Data.CREAM,HORIZONTAL_ALIGNMENT_CENTER,Rect2(18,0,18,56))
		_task_badges.append(badge)
		var copy: String = str(Data.COMMON_TASKS[index]["name"])
		copy=copy.replace("marbles into", "marbles\ninto")
		var task_name := UI.make_child_label(button,copy,14,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(42,6,168,44))
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
	_route.position=Vector2(22,570); _route.disabled=true
	canvas=load("res://scripts/floor_map_canvas.gd").new() as Control
	canvas.name="FloorPlanCanvas"; canvas.position=Vector2(272,84); canvas.size=Vector2(886,458)
	panel.add_child(canvas); canvas.call("configure",app)
	canvas.connect("task_selected",_choose)
	UI.make_child_label(panel,"Floor plan • follow the marked doors and paths",13,Data.CREAM,HORIZONTAL_ALIGNMENT_LEFT,Rect2(280,551,630,25))
	var zoom_out := UI.make_button(panel,"−",func():canvas.call("change_zoom",1/1.2),44,40)
	zoom_out.position=Vector2(960,572)
	var zoom_in := UI.make_button(panel,"+",func():canvas.call("change_zoom",1.2),44,40)
	zoom_in.position=Vector2(1010,572)
	var reset := UI.make_button(panel,"FIT",func():canvas.call("reset_view"),90,40)
	reset.position=Vector2(1060,572); reset.add_theme_font_size_override("font_size",13)
	_tab(false)
	app.page_controls.refresh(true)

func _tab(tasks: bool) -> void:
	if app.player_is_impostor: tasks=false
	_tasks.visible=tasks; _legend.visible=not tasks
	_details.visible=not tasks and selected>=0
	_route.visible=not tasks and selected>=0
	canvas.set("selected",-1 if tasks else selected)

func _choose(index: int) -> void:
	if app.player_is_impostor: return
	selected=index; canvas.set("selected",-1 if _tasks.visible else index)
	var section_id: int = Geometry.floor_plan(app.selected_map).layout["task_sections"][index]
	var place: String = Geometry.floor_plan(app.selected_map).layout["sections"][section_id]["name"]
	_selection.text="%d. %s"%[index+1,Data.COMMON_TASKS[index]["name"]]
	_place.text=place
	_details.visible=not _tasks.visible
	_route.visible=not _tasks.visible
	_route.disabled=app.completed_tasks[index]==1 or not app.can_local_act()
	_route.text="COMPLETED" if app.completed_tasks[index]==1 else "SHOW ROUTE"

func _navigate() -> void:
	if selected<0: return
	if app.completed_tasks[selected]==1: _choose(selected); return
	app._travel_hint(selected)
	queue_free()
