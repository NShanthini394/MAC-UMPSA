extends Node2D
signal interact_requested
const OUTLINE = preload("res://scripts/task_object_outline.gdshader")
const PROPS := "res://assets/tasks/realistic/village_props_v2.png"
const SHOES := "res://assets/tasks/realistic/traditional_footwear.png"
const VISUAL_SCALE := 0.75
static var textures: Dictionary = {}
var task_index := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var indices := [0,3,5,6,7,9,10,11,12,17,19,21]
	match task_index:
		3: _sprite(load("res://assets/tasks/realistic/hanging_batik.png"),Vector2(0,-18),60)
		7:
			_sprite(_cell(SHOES,Vector2i(2,2),0),Vector2(-12,-15),54,-0.12)
			_sprite(_cell(SHOES,Vector2i(2,2),1),Vector2(12,-15),54,0.12)
		_:
			_sprite(_cell(PROPS,Vector2i(6,4),indices[task_index]),Vector2(0,-17),62)
			if task_index==8: _sprite(_cell(PROPS,Vector2i(6,4),13),Vector2(11,-30),43)
			if task_index==9: _sprite(_cell(PROPS,Vector2i(6,4),18),Vector2(20,-8),36)
			if task_index==5: _sprite(_cell(PROPS,Vector2i(6,4),9),Vector2(18,-5),30)
	var area := Area2D.new()
	area.name = "TaskClickArea"
	area.input_pickable = true
	area.collision_layer = 1
	area.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	shape.position = Vector2(0,-15)
	area.add_child(shape)
	add_child(area)
	area.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if not is_visible_in_tree(): return
	var clicked: bool = event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed
	var touched: bool = event is InputEventScreenTouch and event.pressed
	if clicked or touched:
		get_viewport().set_input_as_handled()
		interact_requested.emit()

static func _cell(path: String, grid: Vector2i, index: int) -> Texture2D:
	var key := path+":"+str(index)
	if not textures.has(key):
		var atlas := load(path) as Texture2D
		var size := Vector2i(atlas.get_size())/grid
		var region := Rect2i(Vector2i(index%grid.x,index/grid.x)*size,size)
		if path==PROPS and index==0: region.size.x += 22
		if path==PROPS and index==5: region.size.y += 18
		if path==PROPS and index==7:
			region.position.x += 28
			region.size.x -= 28
		if path==PROPS and index in [12,13]:
			region.position.y += 8
			region.size.y -= 32
		var source := atlas.get_image().get_region(region)
		source.convert(Image.FORMAT_RGBA8)
		var padded := Image.create(source.get_width()+32,source.get_height()+32,false,Image.FORMAT_RGBA8)
		padded.blit_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i(16,16))
		textures[key] = ImageTexture.create_from_image(padded)
	return textures[key]

func _sprite(texture: Texture2D, at: Vector2, extent: float, angle: float = 0.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at*VISUAL_SCALE
	sprite.rotation = angle
	sprite.scale = Vector2.ONE*extent*VISUAL_SCALE/float(maxi(texture.get_width(),texture.get_height()))
	var material := ShaderMaterial.new()
	material.shader = OUTLINE
	material.set_shader_parameter("outline_width",1.4/sprite.scale.x)
	sprite.material = material
	add_child(sprite)

func _draw() -> void:
	draw_ellipse(Vector2(1,4)*VISUAL_SCALE,25*VISUAL_SCALE,7*VISUAL_SCALE,Color(0,0,0,0.24))
