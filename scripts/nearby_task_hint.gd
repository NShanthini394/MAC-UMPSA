extends PanelContainer
## Nearby unfinished tasks, with a direction that follows real open entrances.
const Geometry = preload("res://scripts/map_geometry.gd")
const Navigation = preload("res://scripts/map_navigation.gd")
const Data = preload("res://scripts/game_data.gd")
const NEARBY_RANGE := 220.0
const MAX_WALK_DISTANCE := 280.0
var app: Control
var task_index := -1
var waypoints := PackedVector2Array()
var _arrow: TextureRect
var _heading: Label
var _task_name: Label
var _instruction: Label
var _query_after := 0.0
var _last_origin := Vector2.INF
var _last_state := 0


func configure(controller: Control) -> void:
	app = controller
	name = "NearbyTaskHint"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -260; offset_right = 260
	offset_top = -138; offset_bottom = -28
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09,0.14,0.09,0.94)
	style.border_color = Color("9cdd8e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 10; style.content_margin_bottom = 10
	add_theme_stylebox_override("panel",style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",16)
	add_child(row)
	_arrow = TextureRect.new()
	_arrow.name = "TaskDirectionArrow"
	_arrow.texture = load("res://assets/ui/direction_arrow.svg") as Texture2D
	_arrow.custom_minimum_size = Vector2(44,44)
	_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.resized.connect(func(): _arrow.pivot_offset = _arrow.size * 0.5)
	row.add_child(_arrow)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation",3)
	row.add_child(text)
	_heading = _label(text,"NearbyTaskHeading",16,Color("b6f5a5"))
	_task_name = _label(text,"NearbyTaskName",15,Data.CREAM)
	_task_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction = _label(text,"NearbyTaskInstruction",13,Color("dcdfd2"))
	visible = false


func _label(parent: Node, node_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	refresh(delta)


func refresh(delta: float = 0.0, force_query: bool = false) -> void:
	if not is_instance_valid(app) or app.player_is_impostor or app.current_screen != "game" or app.task_overlay_index >= 0 or not app.can_local_act() or app._utility_dialog_open():
		visible = false
		_query_after = 0
		return
	for overlay_name in ["MapOverlay","JournalOverlay","ClueOverlay","VoteOverlay","MeetingOverlay"]:
		if app.find_child(overlay_name,true,false) != null:
			visible = false
			_query_after = 0
			return
	var origin: Vector2 = app.player_body.global_position if is_instance_valid(app.player_body) else app.player_position
	var doors: Array = app.locked_entrances()
	var range_limit := NEARBY_RANGE
	if is_instance_valid(app.player_body):
		var sight: float = app.player_body.get_meta("sight_radius",160.0)
		if sight < 160.0: range_limit = minf(range_limit,sight)
	var state := hash([app.selected_map,app.completed_tasks,doors,range_limit])
	_query_after -= delta
	if force_query or _query_after <= 0 or state != _last_state or origin.distance_squared_to(_last_origin) > 400:
		_select_task(origin,doors,range_limit)
		_query_after = 0.3
		_last_origin = origin
		_last_state = state
	if task_index < 0 or waypoints.size() < 2:
		visible = false
		return
	var target: Vector2 = Geometry.task_points(app.selected_map)[task_index]
	if origin.distance_to(target) > range_limit:
		visible = false
		return
	var in_reach := origin.distance_to(target) <= 72 and Geometry.has_clear_path(app.selected_map,origin,target,doors)
	_heading.text = "TASK NEARBY"
	_task_name.text = str(Data.TASKS[Data.MAPS[app.selected_map]["name"]][task_index]["name"])
	_instruction.text = "Press INTERACT to start" if in_reach else "Follow the arrow to the task"
	var direction: Vector2 = waypoints[1] - origin
	_arrow.rotation = direction.angle() + PI * 0.5
	_arrow.visible = direction.length_squared() > 16
	_arrow.tooltip_text = "Direction to the nearby task"
	visible = true


func _select_task(origin: Vector2, doors: Array, range_limit: float) -> void:
	task_index = -1
	waypoints = PackedVector2Array()
	var nearest := MAX_WALK_DISTANCE
	var points: Array = Geometry.task_points(app.selected_map)
	for index in points.size():
		if index >= app.completed_tasks.size() or app.completed_tasks[index] == 1: continue
		if origin.distance_to(points[index]) > range_limit: continue
		var route := Navigation.path(app.selected_map,origin,points[index],doors)
		if route.size() < 2: continue
		var distance := 0.0
		for step in range(route.size()-1): distance += route[step].distance_to(route[step+1])
		if distance < nearest:
			nearest = distance
			task_index = index
			waypoints = route
