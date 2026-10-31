extends Control
## Parchment floor plan derived from the exact gameplay floors and doorways.
signal task_selected(index: int)
const Geometry = preload("res://scripts/map_geometry.gd")
const INK := Color("63482c")
const PAPER := Color("ddc08b")
const ROOM_COLORS := [Color("d3b678"),Color("ccaa70"),Color("d8bd8e"),Color("be9870"),Color("b7a07e"),Color("b1bb85"),Color("c9ab70"),Color("aeb47a"),Color("a4b384")]
var app: Control
var zoom := 1.0
var pan := Vector2.ZERO
var selected := -1
var _pressed := false
var _dragged := false
var _press_at := Vector2.ZERO
var _touch_id := -1
var _room_pieces: Array = []
var _draw_after := 0.0

func configure(controller: Control) -> void:
	app = controller
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	var plan := Geometry.floor_plan(app.selected_map)
	for index in plan.layout["sections"].size():
		for zone in plan.layout["sections"][index]["zones"]:
			var region := PackedVector2Array([zone.position,zone.position+Vector2(zone.size.x,0),zone.end,zone.position+Vector2(0,zone.size.y)])
			for floor_polygon in plan.floors:
				for piece in Geometry2D.intersect_polygons(region,floor_polygon): _room_pieces.append({"points":piece,"color":ROOM_COLORS[index%ROOM_COLORS.size()]})
	queue_redraw()

func _process(delta: float) -> void:
	_draw_after -= delta
	if _draw_after <= 0: queue_redraw(); _draw_after=0.15

func reset_view() -> void:
	zoom = 1.0; pan = Vector2.ZERO; queue_redraw()

func change_zoom(factor: float) -> void:
	zoom = clampf(zoom*factor,0.75,3.0); queue_redraw()

func source_to_screen(point: Vector2) -> Vector2:
	var design: Vector2 = Geometry.floor_plan(app.selected_map).layout["design_size"]
	var fit := minf((size.x-48)/design.x,(size.y-48)/design.y)*zoom
	return (point-design*0.5)*fit+size*0.5+pan

func world_to_screen(point: Vector2) -> Vector2:
	return source_to_screen(point/Geometry.floor_plan(app.selected_map).scale)

func _polygon(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points: result.append(source_to_screen(point))
	return result

func _text(copy: String, point: Vector2, font_size: int, color: Color) -> void:
	copy = preload("res://scripts/app_language.gd").text(copy)
	var font := ThemeDB.fallback_font
	var lines := copy.split("\n")
	for index in lines.size():
		var width := font.get_string_size(lines[index],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,point+Vector2(-width*0.5,(index-(lines.size()-1)*0.5)*(font_size+2)),lines[index],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	for x in range(0,int(size.x),30): draw_line(Vector2(x,0),Vector2(x,size.y),Color(0.35,0.26,0.14,0.07))
	for y in range(0,int(size.y),30): draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.35,0.26,0.14,0.07))
	if not is_instance_valid(app): return
	var plan := Geometry.floor_plan(app.selected_map)
	var occupied: Array[Rect2] = []
	if not app.player_is_impostor:
		for point in Geometry.task_points(app.selected_map): occupied.append(Rect2(world_to_screen(point)-Vector2(16,16),Vector2(32,32)))
	var player_location: Vector2 = app.player_body.global_position if is_instance_valid(app.player_body) else app.player_position
	occupied.append(Rect2(world_to_screen(player_location)-Vector2(15,15),Vector2(30,30)))
	for polygon in plan.floors: draw_colored_polygon(_polygon(polygon),Color("f2dba6"))
	for piece in _room_pieces: draw_colored_polygon(_polygon(piece["points"]),piece["color"])
	for rect in plan.layout["solids"]:
		var start := source_to_screen(rect.position)
		var end := source_to_screen(rect.end)
		draw_rect(Rect2(start,end-start),Color(0.35,0.26,0.14,0.23))
	for edge in plan.source_edges: draw_line(source_to_screen(edge[0]),source_to_screen(edge[1]),INK,2,true)
	for door in plan.layout["doors"]:
		var rect: Rect2 = door["rect"]
		var along := Vector2.DOWN if rect.size.y>rect.size.x else Vector2.RIGHT
		var length: float = maxf(rect.size.x,rect.size.y)*0.42
		var center: Vector2 = rect.get_center()
		draw_line(source_to_screen(center-along*length),source_to_screen(center+along*length),Color("ffedbd"),6,true)
		draw_dashed_line(source_to_screen(center-along*length),source_to_screen(center+along*length),INK,2,4,true)
	for index in plan.layout["sections"].size():
		var section: Dictionary = plan.layout["sections"][index]
		var rect: Rect2 = section["zones"][0]
		var copy: String = section["name"]
		copy = copy.replace("Well and East Yard","Well &\nEast Yard").replace("Veranda and Stairs","Veranda &\nStairs").replace("Yard and Garden","Yard &\nGarden").replace("Beach and Piers","Beach &\nPiers")
		var width := source_to_screen(rect.end).x-source_to_screen(rect.position).x
		if width < 145 and not copy.contains("\n"): copy = copy.replace(" ","\n")
		var label_at := source_to_screen(rect.get_center())
		var font_size := clampi(int(width/7),12,16)
		var label_size := Vector2(0,copy.split("\n").size()*(font_size+2))
		for line in copy.split("\n"): label_size.x=maxf(label_size.x,ThemeDB.fallback_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
		var room_center := label_at
		for offset in [Vector2.ZERO,Vector2(0,-23),Vector2(0,23),Vector2(-26,0),Vector2(26,0),Vector2(0,-40),Vector2(0,40),Vector2(-46,0),Vector2(46,0),Vector2(-26,-23),Vector2(26,-23),Vector2(-26,23),Vector2(26,23),Vector2(-60,0),Vector2(60,0),Vector2(0,-60),Vector2(0,60)]:
			var candidate: Vector2 = label_at+offset
			var bounds := Rect2(candidate-label_size*0.5-Vector2(3,8),label_size+Vector2(6,6))
			if not occupied.any(func(other: Rect2)->bool:return bounds.intersects(other)):
				label_at=candidate; occupied.append(bounds)
				break
		if room_center.distance_to(label_at)>30: draw_line(room_center,label_at,Color(0.35,0.26,0.14,0.5),1,true)
		draw_rect(Rect2(label_at-label_size*0.5-Vector2(2,8),label_size+Vector2(4,5)),Color(0.88,0.76,0.53,0.82))
		_text(copy,label_at,font_size,Color("3c3425"))
	var points: Array = Geometry.task_points(app.selected_map)
	for index in points.size():
		if app.player_is_impostor: continue
		var at := world_to_screen(points[index])
		var complete: bool = index<app.completed_tasks.size() and app.completed_tasks[index]==1
		if index==selected: draw_circle(at,17,Color("fff0bb"))
		draw_circle(at,12,Color("60794b") if complete else Color("a45d28"))
		draw_arc(at,12,0,TAU,24,Color("fff0ca"),1.5,true)
		_text("✓" if complete else str(index+1),at+Vector2(0,5),14,Color("fff6d9"))
	var player_point: Vector2 = app.player_body.global_position if is_instance_valid(app.player_body) else app.player_position
	var at := world_to_screen(player_point)
	draw_circle(at,15,Color(0.35,0.12,0.08,0.18))
	var arrow := PackedVector2Array([at+Vector2(0,-13),at+Vector2(10,10),at+Vector2(0,5),at+Vector2(-10,10),at+Vector2(0,-13)])
	draw_colored_polygon(arrow,Color("a7472c"))
	draw_polyline(arrow,Color("fff2b6"),2,true)
	_text("N",Vector2(size.x-28,28),15,INK)
	draw_line(Vector2(size.x-28,38),Vector2(size.x-28,68),INK,2,true)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x-28,35),Vector2(size.x-34,47),Vector2(size.x-22,47)]),INK)

func _start(at: Vector2) -> void:
	_pressed = true; _dragged = false; _press_at = at

func _move(at: Vector2, relative: Vector2) -> void:
	if not _pressed: return
	if _press_at.distance_to(at)>5: _dragged=true
	if _dragged: pan+=relative; queue_redraw()

func _finish(at: Vector2) -> void:
	if _pressed and not _dragged and not app.player_is_impostor:
		var points: Array = Geometry.task_points(app.selected_map)
		for index in points.size():
			if at.distance_to(world_to_screen(points[index]))<=18:
				task_selected.emit(index); break
	_pressed = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: change_zoom(1.2)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: change_zoom(1/1.2)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: _start(event.position)
			else: _finish(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _pressed: _move(event.position,event.relative); accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_id<0: _touch_id=event.index; _start(event.position)
		elif not event.pressed and event.index==_touch_id: _finish(event.position); _touch_id=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==_touch_id: _move(event.position,event.relative); accept_event()
