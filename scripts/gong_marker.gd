extends Node2D
## Separate gong artwork shared by all maps, with a silhouette outline.
signal pressed
var map_index := 0

func _ready() -> void:
	var visual_offset := Vector2(0, [-60.0, -70.0, -75.0][clampi(map_index, 0, 2)])
	var sprite := Sprite2D.new()
	sprite.name = "OutlinedGong"
	sprite.texture = load("res://assets/props/gong_reference_transparent.png")
	sprite.position = visual_offset
	sprite.scale = Vector2.ONE * ([106.0, 138.0, 122.0][clampi(map_index, 0, 2)] / sprite.texture.get_width())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var outline := ShaderMaterial.new()
	outline.shader = preload("res://scripts/task_object_outline.gdshader")
	outline.set_shader_parameter("outline_width", 28.0)
	sprite.material = outline
	add_child(sprite)
	var area := Area2D.new()
	area.position = visual_offset
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 62.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape: int):
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			pressed.emit())
	area.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	area.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

