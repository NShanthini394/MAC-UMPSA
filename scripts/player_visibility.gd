extends Node
## Keep other characters visible regardless of distance or intervening walls.

var _observer: Node2D
var _target: CanvasItem


func configure(observer: Node2D, target: CanvasItem, _radius: float) -> void:
	_observer = observer
	_target = target
	set_process(true)
	_update_visibility()


func _process(delta: float) -> void:
	_update_visibility(delta)


func _update_visibility(_delta: float = 1.0) -> void:
	if not is_instance_valid(_observer) or not is_instance_valid(_target):
		set_process(false)
		return
	_target.visible = true
	var tint := _target.modulate
	tint.a = 1.0
	_target.modulate = tint
