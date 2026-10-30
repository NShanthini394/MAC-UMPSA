extends RefCounted
## One shared floor plan for authoritative LAN movement and local physics.
const Layouts = preload("res://scripts/map_layouts.gd")
const FloorPlan = preload("res://scripts/floor_plan.gd")
const MAP_SIZES := [Vector2(2172,724), Vector2(1448,1086), Vector2(1448,1086)]
const SOURCE_SIZES := [Vector2(2048,683), Vector2(1448,1086), Vector2(1448,1086)]
const PALACE_SOURCE_OBSTACLES := Layouts.LAYOUTS[0]["solids"]
const PALACE_TREE_BLOCKERS_SOURCE := []
static var _plans: Dictionary = {}
static var _spawns: Dictionary = {}


static func floor_plan(map_index: int) -> FloorPlan:
	var index := clampi(map_index, 0, 2)
	if not _plans.has(index): _plans[index] = FloorPlan.new(Layouts.LAYOUTS[index])
	return _plans[index]


static func world_size(map_index: int) -> Vector2:
	return MAP_SIZES[clampi(map_index, 0, 2)]


static func spawn_point(map_index: int) -> Vector2:
	var plan := floor_plan(map_index)
	return plan.world_point(plan.layout["spawn"])


static func spawn_point_for_player(map_index: int, player_index: int) -> Vector2:
	if not _spawns.has(map_index):
		var origin := spawn_point(map_index)
		var selected: Array[Vector2] = []
		var alternatives: Array[Vector2] = []
		for x in range(-5, 6):
			for y in range(-4, 5):
				var point := origin + Vector2(x, y) * 32.0
				if not is_position_blocked(map_index, point, 14.0): alternatives.append(point)
		alternatives.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(origin) < b.distance_squared_to(origin))
		for slot in 10:
			var point := origin + Vector2((slot % 5 - 2) * 32.0, (slot / 5) * 32.0 - 16.0)
			if is_position_blocked(map_index, point, 14.0) or not selected.all(func(other: Vector2) -> bool: return other.distance_to(point) >= 30.0):
				point = origin
				for alternative in alternatives:
					if selected.all(func(chosen: Vector2) -> bool: return chosen.distance_to(alternative) >= 30.0):
						point = alternative
						break
			selected.append(point)
		_spawns[map_index] = selected
	return _spawns[map_index][posmod(player_index, 10)]


static func gong_point(map_index: int) -> Vector2:
	var plan := floor_plan(map_index)
	return plan.world_point(plan.layout["gong"])


static func _points(map_index: int, key: String) -> Array:
	var plan := floor_plan(map_index)
	var result: Array[Vector2] = []
	for point in plan.layout[key]: result.append(plan.world_point(point))
	return result


static func task_points(map_index: int) -> Array:
	return _points(map_index, "tasks")


static func npc_points(map_index: int) -> Array:
	return _points(map_index, "npcs")


static func clue_candidates(map_index: int) -> Array:
	return _points(map_index, "clues")


static func obstacles(map_index: int) -> Array:
	return floor_plan(map_index).solids


static func sabotage_areas(map_index: int) -> Array:
	var plan := floor_plan(map_index)
	var result: Array = []
	for section in plan.layout["sections"]:
		var area := {"name": section["name"], "zones": [], "doors": []}
		for rect in section["zones"]: area["zones"].append(plan.world_rect(rect))
		for door_id in section["doors"]: area["doors"].append(plan.world_rect(plan.layout["doors"][door_id]["rect"]))
		result.append(area)
	return result


static func areas(map_index: int) -> Array:
	var result: Array = []
	for area in sabotage_areas(map_index):
		for rect in area["zones"]: result.append({"name": area["name"], "rect": rect})
	return result


static func area_doors(map_index: int, area_index: int) -> Array:
	var regions := sabotage_areas(map_index)
	return regions[area_index]["doors"] if area_index >= 0 and area_index < regions.size() else []


static func point_in_area(map_index: int, area_index: int, point: Vector2) -> bool:
	var regions := sabotage_areas(map_index)
	if area_index < 0 or area_index >= regions.size(): return false
	for rect in regions[area_index]["zones"]:
		if rect.has_point(point): return true
	return false


static func section_at_position(map_index: int, point: Vector2) -> int:
	var regions := sabotage_areas(map_index)
	for i in regions.size():
		for rect in regions[i]["zones"]:
			if rect.has_point(point): return i
	var nearest := -1
	var distance := 24.0
	for i in regions.size():
		for rect in regions[i]["zones"]:
			var candidate: float = point.distance_to(point.clamp(rect.position, rect.end))
			if candidate < distance:
				distance = candidate
				nearest = i
	return nearest


static func fog_regions(map_index: int, area_index: int, origin: Vector2, radius: float) -> Array:
	var bounds := Rect2(origin - Vector2.ONE * radius, Vector2.ONE * radius * 2).intersection(Rect2(Vector2.ZERO, world_size(map_index)))
	var regions := sabotage_areas(map_index)
	if area_index < 0 or area_index >= regions.size(): return [bounds]
	var result: Array = []
	for rect in regions[area_index]["zones"]:
		var clipped: Rect2 = rect.intersection(bounds)
		if clipped.has_area(): result.append(clipped)
	return result


static func is_position_blocked(map_index: int, point: Vector2, radius: float = 12.0) -> bool:
	var plan := floor_plan(map_index)
	if not plan.contains(point, radius): return true
	for rect in plan.solids:
		if rect.grow(radius).has_point(point): return true
	return false


static func is_step_blocked(map_index: int, from_point: Vector2, to_point: Vector2, radius: float = 12.0, locked_entrances: Array = []) -> bool:
	if is_position_blocked(map_index, to_point, radius): return true
	if floor_plan(map_index).crosses_edge(from_point, to_point, radius): return true
	for rect in obstacles(map_index) + locked_entrances:
		var expanded: Rect2 = rect.grow(radius)
		if not expanded.has_point(from_point) and segment_touches_rect(from_point, to_point, expanded): return true
	return false


static func recover_position(map_index: int, point: Vector2, radius: float = 14.0, locked_entrances: Array = []) -> Vector2:
	# A previous physics slide can leave the feet just inside the clearance band.
	# Recover only locally, on the same side of every wall and solid footprint.
	if not is_position_blocked(map_index, point, radius): return point
	var plan := floor_plan(map_index)
	if not plan.contains(point, 0): return point
	for distance in range(1, 17):
		for index in 32:
			var candidate := point + Vector2.from_angle(TAU * index / 32.0) * float(distance)
			if is_position_blocked(map_index, candidate, radius) or plan.crosses_edge(point, candidate): continue
			var crosses_solid := false
			for rect in plan.solids + locked_entrances:
				if segment_touches_rect(point, candidate, rect):
					crosses_solid = true
					break
			if not crosses_solid: return candidate
	return point


static func move_position(map_index: int, origin: Vector2, motion: Vector2, radius: float = 14.0, locked_entrances: Array = []) -> Vector2:
	var current := recover_position(map_index, origin, radius, locked_entrances)
	var target := current + motion
	if not is_step_blocked(map_index, current, target, radius, locked_entrances): return target
	# Accept a complete, safe axis slide. Combining two independently valid axis
	# moves can recreate the rejected diagonal through an inside corner.
	for axis in [Vector2(motion.x, 0), Vector2(0, motion.y)]:
		if axis.is_zero_approx(): continue
		target = current + axis
		if not is_step_blocked(map_index, current, target, radius, locked_entrances): return target
	return current


static func segment_touches_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b): return true
	var corners := [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null: return true
	return false


static func has_clear_path(map_index: int, a: Vector2, b: Vector2, locked_entrances: Array = []) -> bool:
	var plan := floor_plan(map_index)
	if not plan.contains(a, 0) or not plan.contains(b, 0) or plan.crosses_edge(a, b): return false
	for rect in obstacles(map_index) + locked_entrances:
		if segment_touches_rect(a, b, rect.grow(1.0)): return false
	return true


static func clear_doorway_position(map_index: int, point: Vector2, door: Rect2) -> Vector2:
	var candidates: Array[Vector2] = [Vector2(door.position.x - 16, point.y), Vector2(door.end.x + 16, point.y), Vector2(point.x, door.position.y - 16), Vector2(point.x, door.end.y + 16)]
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(point) < b.distance_squared_to(point))
	for candidate in candidates:
		if not door.grow(14.0).has_point(candidate) and not is_position_blocked(map_index, candidate, 14.0): return candidate
	return point
