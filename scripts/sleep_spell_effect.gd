extends Node2D
## Warm, airy powder trail for Nenek Kebayan's sleep spell.

const CAST_TIME := 0.78
const TOTAL_TIME := 1.18
const DUST_COUNT := 34

var _source := Vector2.ZERO
var _target := Vector2.ZERO
var _elapsed := 0.0


func configure(source: Vector2, target: Vector2) -> void:
	_source = source + Vector2(0.0, -50.0)
	_target = target + Vector2(0.0, -30.0)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= TOTAL_TIME:
		queue_free()
		return
	queue_redraw()


func _path_point(t: float, side_offset: float = 0.0) -> Vector2:
	var direction := _target - _source
	var normal := direction.normalized().orthogonal()
	var arc := sin(t * PI) * minf(13.0, direction.length() * 0.11)
	var drift := sin(t * TAU * 1.5) * 2.5
	return _source.lerp(_target, t) + normal * (side_offset + drift) + Vector2(0.0, -arc)


func _draw() -> void:
	var direction := _target - _source
	if direction.length_squared() < 1.0: return
	var cast_progress := clampf(_elapsed / CAST_TIME, 0.0, 1.0)
	var visible_points := PackedVector2Array()
	var point_count := 20
	for i in range(point_count + 1):
		var t := cast_progress * float(i) / point_count
		visible_points.append(_path_point(t))
	if visible_points.size() > 1:
		draw_polyline(visible_points, Color(0.83, 0.55, 0.88, 0.2), 18.0, true)
		draw_polyline(visible_points, Color(1.0, 0.67, 0.77, 0.58), 8.0, true)
		draw_polyline(visible_points, Color(1.0, 0.88, 0.59, 0.86), 2.8, true)

	for i in range(DUST_COUNT):
		var delay := float(i) * 0.014
		var particle_time := _elapsed - delay
		if particle_time < 0.0: continue
		var progress := clampf(particle_time / CAST_TIME, 0.0, 1.0)
		var phase := progress * (1.0 - progress)
		var side := sin(float(i) * 2.399) * 10.0 * phase
		var point := _path_point(progress, side)
		var alpha := sin(progress * PI) * clampf((CAST_TIME - particle_time) * 4.0, 0.0, 1.0)
		var radius := (2.2 + float(i % 4) * 0.8) * (0.55 + phase)
		draw_circle(point, radius * 2.6, Color(0.92, 0.60, 0.88, alpha * 0.13))
		draw_circle(point, radius, Color(1.0, 0.72, 0.74, alpha * 0.76))
		draw_circle(point, radius * 0.38, Color(1.0, 0.91, 0.64, alpha))
		if i % 5 == 0:
			var sparkle := radius * 1.9
			draw_line(point + Vector2(-sparkle, 0), point + Vector2(sparkle, 0), Color(1.0, 0.94, 0.72, alpha), 1.4, true)
			draw_line(point + Vector2(0, -sparkle), point + Vector2(0, sparkle), Color(1.0, 0.94, 0.72, alpha), 1.4, true)

	var impact := clampf((_elapsed - CAST_TIME * 0.72) / 0.46, 0.0, 1.0)
	if impact > 0.0:
		var eased := impact * (2.0 - impact)
		var fade := (1.0 - impact) * 0.85
		var radius := 8.0 + eased * 38.0
		draw_arc(_target, radius, 0.0, TAU, 48, Color(1.0, 0.79, 0.57, fade), 3.0, true)
		draw_arc(_target, radius * 0.68, 0.0, TAU, 48, Color(0.89, 0.60, 0.91, fade * 0.8), 2.0, true)
		for i in range(8):
			var angle := TAU * float(i) / 8.0 - _elapsed * 1.7
			var star := _target + Vector2.RIGHT.rotated(angle) * radius
			var color := Color(1.0, 0.9, 0.65, fade)
			draw_line(star - Vector2(3, 0), star + Vector2(3, 0), color, 1.7, true)
			draw_line(star - Vector2(0, 3), star + Vector2(0, 3), color, 1.7, true)
