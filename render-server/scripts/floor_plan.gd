extends RefCounted
## Union of hand-traced floors. Shared seams are removed before physics is built.
var layout: Dictionary
var scale: Vector2
var floors: Array[PackedVector2Array] = []
var edges: Array[PackedVector2Array] = []
var source_edges: Array[PackedVector2Array] = []
var solids: Array[Rect2] = []


func _init(data: Dictionary) -> void:
	layout = data
	scale = data["world_size"] / data["design_size"]
	for rect in data["floors"]:
		floors.append(PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]))
	for points in data.get("polygons", []): floors.append(PackedVector2Array(points))
	for path in data.get("paths", []):
		for polygon in Geometry2D.offset_polyline(PackedVector2Array(path["points"]), float(path["width"]) * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
			floors.append(polygon)
	for rect in data["solids"]: solids.append(world_rect(rect))
	_build_edges()


func world_point(point: Vector2) -> Vector2:
	return point * scale


func world_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * scale, rect.size * scale)


func _inside(point: Vector2) -> bool:
	for polygon in floors:
		if Geometry2D.is_point_in_polygon(point, polygon): return true
	return false


func _build_edges() -> void:
	var candidates: Array[PackedVector2Array] = []
	for polygon in floors:
		for i in polygon.size(): candidates.append(PackedVector2Array([polygon[i], polygon[(i + 1) % polygon.size()]]))
	var seen := {}
	for edge in candidates:
		var a: Vector2 = edge[0]
		var delta: Vector2 = edge[1] - a
		var length_squared := delta.length_squared()
		if length_squared < 0.0001: continue
		var cuts: Array[float] = [0.0, 1.0]
		for other in candidates:
			var hit = Geometry2D.segment_intersects_segment(a, edge[1], other[0], other[1])
			if hit != null: cuts.append(clampf((hit - a).dot(delta) / length_squared, 0, 1))
			for point in other:
				var t: float = (point - a).dot(delta) / length_squared
				if t > 0 and t < 1 and (a + delta * t).distance_squared_to(point) < 0.0001: cuts.append(t)
		cuts.sort()
		for i in range(cuts.size() - 1):
			if cuts[i + 1] - cuts[i] < 0.00001: continue
			var start := a + delta * cuts[i]
			var finish := a + delta * cuts[i + 1]
			var middle := (start + finish) * 0.5
			var normal := delta.normalized().orthogonal() * 0.05
			if _inside(middle + normal) == _inside(middle - normal): continue
			var first := start.snapped(Vector2(0.01, 0.01))
			var last := finish.snapped(Vector2(0.01, 0.01))
			var key := str(first) + str(last) if first.x < last.x or (first.x == last.x and first.y < last.y) else str(last) + str(first)
			if seen.has(key): continue
			seen[key] = true
			source_edges.append(PackedVector2Array([start, finish]))
			edges.append(PackedVector2Array([world_point(start), world_point(finish)]))


func contains(point: Vector2, radius: float = 14.0) -> bool:
	if not _inside(point / scale): return false
	for edge in edges:
		if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, edge[0], edge[1])) < radius * radius: return false
	return true


func crosses_edge(a: Vector2, b: Vector2, radius: float = 0.0) -> bool:
	var swept := Rect2(a.min(b), (b - a).abs()).grow(radius + 0.01)
	for edge in edges:
		if not swept.intersects(Rect2(edge[0].min(edge[1]), (edge[1] - edge[0]).abs()).grow(0.01)): continue
		if Geometry2D.segment_intersects_segment(a, b, edge[0], edge[1]) != null: return true
		if radius > 0:
			if minf(minf(a.distance_squared_to(Geometry2D.get_closest_point_to_segment(a, edge[0], edge[1])), b.distance_squared_to(Geometry2D.get_closest_point_to_segment(b, edge[0], edge[1]))), minf(edge[0].distance_squared_to(Geometry2D.get_closest_point_to_segment(edge[0], a, b)), edge[1].distance_squared_to(Geometry2D.get_closest_point_to_segment(edge[1], a, b)))) < radius * radius: return true
	return false
