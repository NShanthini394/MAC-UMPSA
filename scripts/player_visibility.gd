extends Node
## Hides other characters and impostor markers beyond the local player's sight.

var _observer: Node2D
var _target: CanvasItem
var _radius := 250.0
var _target_visible := false
const MapGeometry = preload("res://scripts/map_geometry.gd")


func configure(observer: Node2D, target: CanvasItem, radius: float) -> void:
	_observer = observer
	_target = target
	_radius = radius
	set_process(true)
	_update_visibility()


func _process(delta: float) -> void:
	_update_visibility(delta)


func _update_visibility(delta: float = 1.0) -> void:
	if not is_instance_valid(_observer) or not is_instance_valid(_target):
		set_process(false)
		return
	var target_position := _target.get_global_transform().origin
	var entrances: Array = _observer.get_meta("locked_entrances", [])
	# Keep moving villagers visible at the edge of the camera. Occluding walls and
	# locked entrances still hide them, while range cutoffs no longer pop sprites.
	_target_visible = MapGeometry.has_clear_path(int(_observer.get("map_index")), _observer.global_position, target_position, entrances)
	if _target_visible: _target.visible = true
	var tint := _target.modulate
	tint.a = move_toward(tint.a, 1.0 if _target_visible else 0.0, delta * 3.5)
	_target.modulate = tint
	if not _target_visible and tint.a <= 0.01: _target.visible = false
