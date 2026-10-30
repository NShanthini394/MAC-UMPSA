extends RefCounted
## Cached aisle/door graphs. Every shortcut checks the full swept player radius.
const Geometry = preload("res://scripts/map_geometry.gd")
static var _graphs: Dictionary = {}


static func _graph(map_index: int) -> AStar2D:
	if _graphs.has(map_index): return _graphs[map_index]
	var graph := AStar2D.new()
	var plan := Geometry.floor_plan(map_index)
	var ids := {}
	for route in plan.layout["routes"]:
		for source_point in route:
			var point := plan.world_point(source_point)
			if not ids.has(point) and not Geometry.is_position_blocked(map_index, point, 14):
				var id := graph.get_available_point_id()
				graph.add_point(id, point)
				ids[point] = id
	for door in plan.layout["doors"]:
		var point := plan.world_rect(door["rect"]).get_center()
		if not ids.has(point) and not Geometry.is_position_blocked(map_index, point, 14):
			var id := graph.get_available_point_id()
			graph.add_point(id, point)
			ids[point] = id
	for route in plan.layout["routes"]:
		var previous := -1
		for source_point in route:
			var point := plan.world_point(source_point)
			if not ids.has(point): continue
			var current: int = ids[point]
			if previous >= 0 and not Geometry.is_step_blocked(map_index, graph.get_point_position(previous), point, 14): graph.connect_points(previous, current)
			previous = current
	for rect in plan.solids:
		var expanded: Rect2 = rect.grow(17)
		for point in [expanded.position, expanded.position + Vector2(expanded.size.x, 0), expanded.end, expanded.position + Vector2(0, expanded.size.y)]:
			if not ids.has(point) and not Geometry.is_position_blocked(map_index, point, 14):
				var id := graph.get_available_point_id()
				graph.add_point(id, point)
				ids[point] = id
	var points := graph.get_point_ids()
	for a in points:
		for b in points:
			if a >= b: continue
			var first := graph.get_point_position(a)
			var second := graph.get_point_position(b)
			if first.distance_to(second) <= 220 and not Geometry.is_step_blocked(map_index, first, second, 14): graph.connect_points(a, b)
	_graphs[map_index] = graph
	return graph


static func path(map_index: int, start_point: Vector2, end_point: Vector2, doors: Array = []) -> PackedVector2Array:
	if not Geometry.is_step_blocked(map_index, start_point, end_point, 14, doors): return PackedVector2Array([start_point, end_point])
	var graph := _graph(map_index)
	var blocked: Array[Vector2i] = []
	if not doors.is_empty():
		for a in graph.get_point_ids():
			for b in graph.get_point_connections(a):
				if a < b and Geometry.is_step_blocked(map_index, graph.get_point_position(a), graph.get_point_position(b), 14, doors): blocked.append(Vector2i(a, b))
		for edge in blocked: graph.disconnect_points(edge.x, edge.y)
	var existing := graph.get_point_ids()
	var start := graph.get_available_point_id()
	graph.add_point(start, start_point)
	var finish := graph.get_available_point_id()
	graph.add_point(finish, end_point)
	for id in existing:
		var point := graph.get_point_position(id)
		if not Geometry.is_step_blocked(map_index, start_point, point, 14, doors): graph.connect_points(start, id)
		if not Geometry.is_step_blocked(map_index, end_point, point, 14, doors): graph.connect_points(finish, id)
	var result := graph.get_point_path(start, finish)
	graph.remove_point(start)
	graph.remove_point(finish)
	for edge in blocked: graph.connect_points(edge.x, edge.y)
	var shortened := PackedVector2Array()
	var cursor := 0
	while cursor < result.size():
		shortened.append(result[cursor])
		var next := result.size() - 1
		while next > cursor + 1 and Geometry.is_step_blocked(map_index, result[cursor], result[next], 14, doors): next -= 1
		cursor = maxi(cursor + 1, next)
	return shortened
