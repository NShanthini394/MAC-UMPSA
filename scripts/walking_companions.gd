extends RefCounted
## Server-owned companions: walk clear aisles, pause, and never perform tasks or vote.
const Geometry = preload("res://scripts/map_geometry.gd")
const Navigation = preload("res://scripts/map_navigation.gd")
static var destinations: Dictionary = {}

static func tick(room: Dictionary, delta: float, now: float, random: RandomNumberGenerator, doors: Array) -> void:
	var map_index := int(room["map_index"])
	if not destinations.has(map_index):
		var points: Array[Vector2] = []
		var plan := Geometry.floor_plan(map_index)
		for route in plan.layout["routes"]:
			for source in route:
				var point: Vector2 = plan.world_point(source)
				if not Geometry.is_position_blocked(map_index, point, 14) and point not in points: points.append(point)
		destinations[map_index] = points
	for player in room["players"].values():
		if not bool(player.get("is_bot", false)) or not bool(player.get("alive", true)) or bool(player.get("sleeping", false)): continue
		if now < float(player.get("bot_pause", 0.0)): continue
		var route: PackedVector2Array = player.get("bot_path", PackedVector2Array())
		var origin: Vector2 = player["position"]
		if route.is_empty():
			var points: Array = destinations[map_index]
			if points.is_empty(): continue
			var target: Vector2 = points[random.randi_range(0, points.size()-1)]
			route = Navigation.path(map_index, origin, target, doors)
			if not route.is_empty(): route.remove_at(0)
			player["bot_path"] = route
			player["bot_pause"] = now + random.randf_range(0.3, 1.5)
			continue
		var target := route[0]
		if origin.distance_to(target) < 5:
			route.remove_at(0); player["bot_path"] = route
			if route.is_empty(): player["bot_pause"] = now + random.randf_range(0.6, 2.8)
			continue
		var step := origin.direction_to(target) * minf(origin.distance_to(target), minf(delta, 0.1) * 165.0)
		var moved := Geometry.move_position(map_index, origin, step, 14, doors)
		player["position"] = moved
		if moved.distance_to(origin) < 0.05:
			player["bot_path"] = PackedVector2Array()
			player["bot_pause"] = now + 1.5
