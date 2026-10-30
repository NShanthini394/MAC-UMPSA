extends SceneTree
## All three full-size floor plans: doors, obstacles, objectives and real physics.
const Geometry = preload("res://scripts/map_geometry.gd")
const Navigation = preload("res://scripts/map_navigation.gd")
const Data = preload("res://scripts/game_data.gd")
const GRID_STEP := 5.0
var failures: Array[String] = []
var checks := 0
var reachable := {}
var valid_cells := {}


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	for map_index in 3:
		await validate_map(map_index)
	print("MAP FLOOR CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func cell_point(map_index: int, cell: Vector2i) -> Vector2:
	return Geometry.floor_plan(map_index).world_point(Vector2(cell) * GRID_STEP)


func valid_cell(map_index: int, cell: Vector2i) -> bool:
	if not valid_cells.has(cell): valid_cells[cell] = not Geometry.is_position_blocked(map_index, cell_point(map_index, cell), 14)
	return valid_cells[cell]


func flood(map_index: int) -> void:
	reachable.clear()
	valid_cells.clear()
	var plan := Geometry.floor_plan(map_index)
	var start := Vector2i((Geometry.spawn_point(map_index) / plan.scale / GRID_STEP).round())
	var queue: Array[Vector2i] = [start]
	reachable[start] = true
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if reachable.has(next) or not valid_cell(map_index, next): continue
			if Geometry.is_step_blocked(map_index, cell_point(map_index, cell), cell_point(map_index, next), 14): continue
			reachable[next] = true
			queue.append(next)
	print("Map %d: %d reachable cells; %d floor edges" % [map_index, reachable.size(), plan.edges.size()])


func can_reach(map_index: int, point: Vector2) -> bool:
	var cell := Vector2i((point / Geometry.floor_plan(map_index).scale / GRID_STEP).round())
	for x in range(-2, 3):
		for y in range(-2, 3):
			var candidate := cell + Vector2i(x, y)
			if reachable.has(candidate) and not Geometry.is_step_blocked(map_index, point, cell_point(map_index, candidate), 14): return true
	return false


func validate_map(map_index: int) -> void:
	var plan := Geometry.floor_plan(map_index)
	var map_name: String = Data.MAPS[map_index]["name"]
	var image := load(Data.map_art_path(map_index)) as Texture2D
	check(image.get_size() == Geometry.world_size(map_index), map_name + ": full source image, without a crop or distortion")
	for entrance in plan.layout["doors"]:
		var rect: Rect2 = plan.world_rect(entrance["rect"])
		var normal := Vector2.RIGHT if rect.size.y > rect.size.x else Vector2.DOWN
		var a := rect.get_center() - normal * 24
		var b := rect.get_center() + normal * 24
		check(not Geometry.is_step_blocked(map_index, a, b, 14), map_name + ": enter " + entrance["name"])
		check(not Geometry.is_step_blocked(map_index, b, a, 14), map_name + ": exit " + entrance["name"])
		check(Geometry.is_step_blocked(map_index, a, b, 14, [rect]), map_name + ": lock closes the marked threshold " + entrance["name"])
	for landmark in plan.layout["forbidden"]:
		check(Geometry.is_position_blocked(map_index, plan.world_point(plan.layout["forbidden"][landmark]), 14), map_name + ": blocked " + landmark)
	for crossing in plan.layout["wall_crossings"]:
		var a := plan.world_point(crossing[0])
		var b := plan.world_point(crossing[1])
		check(Geometry.is_step_blocked(map_index, a, b, 14), map_name + ": cannot tunnel through a room divider")
		check(not Geometry.has_clear_path(map_index, a, b), map_name + ": room wall blocks sight and spells")
	flood(map_index)
	var markers: Array = Geometry.task_points(map_index) + Geometry.npc_points(map_index) + Geometry.clue_candidates(map_index) + [Geometry.gong_point(map_index)]
	var clues := Geometry.clue_candidates(map_index)
	check(clues.size() >= 6, map_name + ": enough separated clues for online play")
	for i in clues.size():
		for task in Geometry.task_points(map_index):
			check(clues[i].distance_to(task) >= 125.0, map_name + ": clue stays away from task markers")
		for j in range(i):
			check(clues[i].distance_to(clues[j]) >= 160.0, map_name + ": clues spread across the map")
	for i in markers.size():
		check(not Geometry.is_position_blocked(map_index, markers[i], 14), map_name + ": objective %d is on clear floor" % i)
		check(can_reach(map_index, markers[i]), map_name + ": objective %d is reachable" % i)
		var route := Navigation.path(map_index, Geometry.spawn_point(map_index), markers[i])
		check(route.size() >= 2, map_name + ": objective %d has a navigable hint route" % i)
		var clear := true
		for j in range(route.size() - 1):
			if Geometry.is_step_blocked(map_index, route[j], route[j + 1], 14): clear = false
		check(clear, map_name + ": route %d follows floors and entrances" % i)
	var spawns: Array[Vector2] = []
	for slot in 10:
		var point := Geometry.spawn_point_for_player(map_index, slot)
		check(not Geometry.is_position_blocked(map_index, point, 14) and can_reach(map_index, point), map_name + ": clear connected spawn %d" % slot)
		check(spawns.all(func(other: Vector2) -> bool: return point.distance_to(other) >= 30), map_name + ": distinct spawn %d" % slot)
		spawns.append(point)
	for entrance in plan.layout["doors"]:
		check(can_reach(map_index, plan.world_rect(entrance["rect"]).get_center()), map_name + ": connected entrance " + entrance["name"])
	await physics_doors(map_index)
	print("Completed " + map_name)


func physics_doors(map_index: int) -> void:
	var plan := Geometry.floor_plan(map_index)
	var world := Node2D.new()
	root.add_child(world)
	load("res://scripts/game_screen.gd").new().call("_add_map_collisions", world, map_index)
	var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
	player.set("map_index", map_index)
	world.add_child(player)
	player.call("configure", "Badang", "Door test", true, false)
	for entrance in plan.layout["doors"]:
		var rect: Rect2 = plan.world_rect(entrance["rect"])
		var direction := Vector2.RIGHT if rect.size.y > rect.size.x else Vector2.DOWN
		player.position = rect.get_center() - direction * 20
		player.call("set_input_direction", direction)
		await create_timer(0.18).timeout
		check((player.position - rect.get_center()).dot(direction) > 5, "Physics crosses map %d / %s" % [map_index, entrance["name"]])
	player.call("set_input_direction", Vector2.ZERO)
	world.queue_free()
	await process_frame
