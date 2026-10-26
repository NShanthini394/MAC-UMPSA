extends Node
## Hides other characters and impostor markers beyond the local player's sight.

var _observer: Node2D
var _target: CanvasItem
var _radius := 250.0


func configure(observer: Node2D, target: CanvasItem, radius: float) -> void:
	_observer = observer
	_target = target
	_radius = radius
	set_process(true)
	_update_visibility()


func _process(_delta: float) -> void:
	_update_visibility()


func _update_visibility() -> void:
	if not is_instance_valid(_observer) or not is_instance_valid(_target):
		set_process(false)
		return
	var target_position := _target.get_global_transform().origin
	_target.visible = _observer.global_position.distance_to(target_position) <= _radius
