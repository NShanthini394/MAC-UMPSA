extends Control
## Eight separate footwear sprites. A pair scores only after both shoes are placed.
signal pair_completed
signal feedback(message: String, success: bool)

const FOOTWEAR_ATLAS := "res://assets/tasks/realistic/traditional_footwear.png"
const PAIR_NAMES := ["Blue · Terompah", "Yellow · Capal", "Red · Kasut sulam", "Green · Anyaman"]
const SOURCE_CENTRES := [Vector2(87,128),Vector2(208,130),Vector2(322,128),Vector2(145,207),Vector2(300,286),Vector2(192,286),Vector2(78,286),Vector2(303,207)]
const SOURCE_ANGLES := [-0.35,0.25,0.25,-0.45,0.5,-0.35,-0.2,0.2]
const SPRITE_SIZE := Vector2(100,100)
var textures: Array[Texture2D] = []
var images: Array[Image] = []
var slots: Array[int] = [-1,-1,-1,-1,-1,-1,-1,-1]
var credited_pairs: Array[int] = []
var input_enabled := true
var selected_shoe := -1
var _touch_id := -1
var _dragging := false
var _moved := false
var _pointer := Vector2.ZERO
var _press_at := Vector2.ZERO
var _original_slot := -1
var _initialised := false
var _visual_clock := 0.0
var _settling: Dictionary = {}

func _process(delta: float) -> void:
	_visual_clock += delta
	for index in _settling.keys():
		_settling[index]["age"] += delta
		if _settling[index]["age"]>=0.3: _settling.erase(index)
	if selected_shoe>=0 or not _settling.is_empty(): queue_redraw()

func configure(progress: int) -> void:
	name = "ShoeArrangement"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(792,382)
	var atlas := load(FOOTWEAR_ATLAS) as Texture2D
	var cell := Vector2(atlas.get_size())/2.0
	for pair in 4:
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2(pair%2,pair/2)*cell,cell)
		texture.filter_clip = true
		textures.append(texture)
		images.append(texture.get_image())
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_progress(progress)

func set_progress(progress: int) -> void:
	# Keep locally placed single shoes while a completed pair is acknowledged.
	if not _initialised:
		_initialised = true
		for pair in mini(progress,4): _restore_pair(pair)
	elif progress < credited_pairs.size():
		while credited_pairs.size() > progress:
			var pair: int = credited_pairs.pop_back()
			slots[pair] = -1; slots[pair+4] = -1
	elif progress > credited_pairs.size():
		for pair in 4:
			if credited_pairs.size() >= progress: break
			if pair not in credited_pairs: _restore_pair(pair)
	selected_shoe = -1; _dragging = false; _touch_id = -1
	visible = progress < 4
	queue_redraw()

func _restore_pair(pair: int) -> void:
	credited_pairs.append(pair)
	slots[pair] = pair*2; slots[pair+4] = pair*2+1

func pair_rect(pair: int) -> Rect2:
	return Rect2(432+(pair%2)*166,86+(pair/2)*121,150,108)

func slot_centre(slot: int) -> Vector2:
	var rect := pair_rect(slot/2)
	return rect.position + Vector2(43+(slot%2)*64,54)

func shoe_centre(index: int) -> Vector2:
	return slot_centre(slots[index]) if slots[index]>=0 else SOURCE_CENTRES[index]

func next_pair() -> int:
	for pair in 4:
		if pair not in credited_pairs: return pair
	return -1

func next_source() -> Vector2:
	var pair := next_pair()
	if pair < 0: return Vector2.ZERO
	return shoe_centre(pair if slots[pair]<0 else pair+4)

func next_target() -> Vector2:
	var pair := next_pair()
	if pair < 0: return Vector2.ZERO
	return slot_centre(pair*2 if pair*2 not in slots else pair*2+1)

func handle_input(event: InputEvent) -> void:
	if not input_enabled:
		if event is InputEventScreenTouch and not event.pressed and event.index==_touch_id: _touch_id=-1
		if event is InputEventMouseButton and not event.pressed: _dragging=false
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id<0: _touch_id=event.index; _press(event.position)
		elif not event.pressed and event.index==_touch_id: _release(event.position); _touch_id=-1
	elif event is InputEventScreenDrag and event.index==_touch_id: _motion(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and _touch_id<0:
		if event.pressed: _press(event.position)
		else: _release(event.position)
	elif event is InputEventMouseMotion and _dragging and _touch_id<0: _motion(event.position)

func _press(at: Vector2) -> void:
	if selected_shoe>=0 and _drop(at): return
	var hit := _shoe_at(at)
	if hit < 0: return
	selected_shoe=hit; _original_slot=slots[hit]
	_pointer=at; _press_at=at; _dragging=true; _moved=false
	queue_redraw()

func _motion(at: Vector2) -> void:
	if not _dragging: return
	_pointer=at
	_moved = _moved or at.distance_to(_press_at)>6
	queue_redraw()

func _release(at: Vector2) -> void:
	if not _dragging: return
	_dragging=false
	if _moved:
		if not _drop(at):
			slots[selected_shoe]=_original_slot
			selected_shoe=-1
			feedback.emit("Place the shoe in its matching colour on the right.",false)
	queue_redraw()

func _shoe_at(at: Vector2) -> int:
	# Alpha hit testing prevents a transparent sprite corner selecting another shoe.
	for index in range(7,-1,-1):
		if index%4 in credited_pairs: continue
		var local := (at-shoe_centre(index)).rotated(-SOURCE_ANGLES[index] if slots[index]<0 else 0.0)
		if index>=4: local.x=-local.x
		var uv := local/SPRITE_SIZE+Vector2(0.5,0.5)
		if uv.x<0 or uv.y<0 or uv.x>=1 or uv.y>=1: continue
		var image: Image = images[index%4]
		var pixel := uv*Vector2(image.get_size())
		if image.get_pixel(int(pixel.x),int(pixel.y)).a>0.15: return index
	# Allow a little room around the pictured shoe for a finger on small screens.
	if _touch_id>=0:
		var nearest := -1
		var distance := 44.0
		for index in 8:
			if index%4 in credited_pairs: continue
			var candidate := at.distance_to(shoe_centre(index))
			if candidate<distance: nearest=index;distance=candidate
		return nearest
	return -1

func _drop(at: Vector2) -> bool:
	if selected_shoe<0: return false
	var pair := selected_shoe%4
	if not pair_rect(pair).grow(3).has_point(at): return false
	var available: Array[int] = []
	for slot in [pair*2,pair*2+1]:
		if slot not in slots or slots[selected_shoe]==slot: available.append(slot)
	if available.is_empty(): return false
	available.sort_custom(func(a:int,b:int)->bool:return at.distance_squared_to(slot_centre(a))<at.distance_squared_to(slot_centre(b)))
	_settling[selected_shoe] = {"from":_pointer if _dragging or _moved else shoe_centre(selected_shoe),"age":0.0}
	slots[selected_shoe]=available[0]
	selected_shoe=-1; _dragging=false
	if slots[pair]>=0 and slots[pair+4]>=0 and pair not in credited_pairs:
		credited_pairs.append(pair)
		feedback.emit("Colour-matched pair arranged!",true)
		pair_completed.emit()
	else: feedback.emit("One shoe placed. Find the other shoe of the same colour.",true)
	queue_redraw()
	return true

func _draw() -> void:
	_label("SCATTERED SHOES",Vector2(104,75),15)
	_label("ARRANGE BY COLOUR",Vector2(475,75),15)
	draw_line(Vector2(395,88),Vector2(395,316),Color("77502e"),2,true)
	for pair in 4:
		var rect := pair_rect(pair)
		var complete := pair in credited_pairs
		var style := StyleBoxFlat.new()
		style.bg_color=Color("71854e") if complete else Color("d0af77")
		style.border_color=Color("b6e692") if complete else Color("735431")
		style.set_border_width_all(2); style.set_corner_radius_all(9)
		draw_style_box(style,rect)
		_label(("✓ " if complete else "")+PAIR_NAMES[pair],rect.position+Vector2(8,104),12,Color("30251b"))
		for side in 2:
			var point := slot_centre(pair*2+side)
			draw_arc(point,24,0,TAU,24,Color(0.36,0.27,0.15,0.22),1,true)
	for index in 8:
		if selected_shoe==index: continue
		_draw_shoe(index,shoe_centre(index),SOURCE_ANGLES[index] if slots[index]<0 else 0.0)
	if selected_shoe>=0:
		_draw_shoe(selected_shoe,_pointer if _dragging else shoe_centre(selected_shoe),0.0,true)

func _draw_shoe(index:int,at:Vector2,angle:float,highlight:bool=false) -> void:
	var scale_factor := 1.04+sin(_visual_clock*4)*0.015 if highlight else 1.0
	if _settling.has(index):
		var t: float = clampf(_settling[index]["age"]/0.3,0.0,1.0)
		at = Vector2(_settling[index]["from"]).lerp(at,1-pow(1-t,3))+Vector2(0,-sin(t*PI)*10)
	draw_set_transform(at+Vector2(4,8),angle,Vector2(-1,1)*scale_factor if index>=4 else Vector2.ONE*scale_factor)
	draw_texture_rect(textures[index%4],Rect2(-SPRITE_SIZE*0.5,SPRITE_SIZE),false,Color(0,0,0,0.2))
	draw_set_transform(at,angle,Vector2(-1,1)*scale_factor if index>=4 else Vector2.ONE*scale_factor)
	if highlight: draw_arc(Vector2.ZERO,39,0,TAU,32,Color("ffe8a0"),2,true)
	draw_texture_rect(textures[index%4],Rect2(-SPRITE_SIZE*0.5,SPRITE_SIZE),false)
	draw_set_transform(Vector2.ZERO)

func _label(copy:String,at:Vector2,font_size:int,color:Color=Color("fff0cf")) -> void:
	copy = preload("res://scripts/app_language.gd").text(copy)
	draw_string(ThemeDB.fallback_font,at+Vector2(1,1),copy,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0,0,0,0.6))
	draw_string(ThemeDB.fallback_font,at,copy,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
