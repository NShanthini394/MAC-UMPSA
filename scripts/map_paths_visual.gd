extends Node2D
## Visible paths, boundaries and two-way arrows, using the collision plan itself.
const Geometry = preload("res://scripts/map_geometry.gd")
var map_index := 0
var overview := false
var debug_boundaries := false
var player_marker := Vector2.INF


func _draw() -> void:
	var plan := Geometry.floor_plan(map_index)
	var texture := load(plan.layout["art"]) as Texture2D
	var source: Rect2 = plan.layout["tile"]
	for patch in plan.layout.get("patches", []):
		for x in range(int(patch.position.x), int(patch.end.x), 20):
			for y in range(int(patch.position.y), int(patch.end.y), 20):
				var tile := Rect2(x, y, 20, 20).intersection(patch)
				draw_texture_rect_region(texture, tile, Rect2(source.position, source.size * tile.size / 20.0))
	if debug_boundaries:
		for edge in plan.source_edges:
			draw_line(edge[0], edge[1], Color(0.98, 0.78, 0.40, 0.65), 1.1, true)
		for rect in plan.layout["solids"]: draw_rect(rect, Color(0.98, 0.78, 0.40, 0.3), false, 1)
	for entrance in plan.layout["doors"]:
		var rect: Rect2 = entrance["rect"]
		var center := rect.get_center()
		var along := Vector2.RIGHT if rect.size.y > rect.size.x else Vector2.DOWN
		var across := along.orthogonal()
		var half_width := (rect.size.y if rect.size.y > rect.size.x else rect.size.x) * 0.5 - 4
		for sign_value in [-1.0, 1.0]:
			var mark: Vector2 = center + across * half_width * sign_value
			draw_line(mark - along * 6, mark + along * 6, Color("9ce9bd"), 2.0, true)
		draw_line(center - along * 8, center + along * 8, Color("b5f5d1"), 2.0, true)
		for sign_value in [-1.0, 1.0]:
			var tip: Vector2 = center + along * 13 * sign_value
			draw_colored_polygon(PackedVector2Array([tip, tip - along * 6 * sign_value + across * 4, tip - along * 6 * sign_value - across * 4]), Color("b5f5d1"))
	if player_marker.is_finite():
		draw_circle(player_marker, 9, Color("123d50"))
		draw_circle(player_marker, 5, Color("b1eeff"))
		draw_arc(player_marker, 12, 0, TAU, 24, Color("e8faff"), 2, true)
