extends Control
## Twelve village chores. Mouse, touch drag, and tap-to-place share the same rules.
signal step_completed
signal sound_requested(kind: String)
const CREAM := Color("fff0cf")
const GOLD := Color("edbb63")
const INK := Color("30251b")
const MarbleShot = preload("res://scripts/marble_shot.gd")
const RealisticArt = preload("res://scripts/task_realistic_art.gd")
var realistic_art: RefCounted
const ShoeArrangement = preload("res://scripts/shoe_arrangement.gd")
var shoe_board: Control
var _shot := MarbleShot.new()
const COLORS := [Color("cc6451"),Color("e8bb64"),Color("72acb8"),Color("9eae76")]
var task: Dictionary = {}
var task_kind := "rice"
var current_progress := 0
var required_progress := 1
var input_enabled := true
var feedback_label: Label
var _instruction: Label
var _selected := false
var _dragging := false
var _pointer := Vector2.ZERO
var _last_pointer := Vector2.ZERO
var _stroke := 0.0
var _sparks := 0
var _heat := 0.0
var _heat_direction := 1.0
var _touch_id := -1
var _pending := false

func configure(data: Dictionary, progress: int, required: int) -> void:
    realistic_art = RealisticArt.new()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    task = data
    task_kind = str(task["minigame"])
    required_progress = required
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    feedback_label = Label.new()
    feedback_label.name = "TaskBoardFeedback"
    feedback_label.position = Vector2(20,340)
    feedback_label.size = Vector2(752,30)
    feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback_label.add_theme_font_size_override("font_size",15)
    feedback_label.add_theme_color_override("font_color",CREAM)
    feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(feedback_label)
    _instruction = Label.new()
    _instruction.position = Vector2(20,10)
    _instruction.size = Vector2(752,36)
    _instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _instruction.add_theme_font_size_override("font_size",17)
    _instruction.add_theme_color_override("font_color",CREAM)
    _instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_instruction)
    if task_kind=="slippers":
        shoe_board=ShoeArrangement.new()
        shoe_board.configure(progress)
        shoe_board.pair_completed.connect(func():_submit("drag"))
        shoe_board.feedback.connect(func(message:String,success:bool):
            feedback_label.text=message
            if not success: sound_requested.emit("timing_miss"))
        add_child(shoe_board)
    set_progress(progress)

func set_progress(progress: int) -> void:
    current_progress = progress
    _pending = false
    input_enabled = progress < required_progress
    _selected = false
    _dragging = false
    _touch_id = -1
    _pointer = Vector2(145,230)
    _stroke = 0
    _sparks = 0
    _shot.reset()
    if is_instance_valid(shoe_board): shoe_board.set_progress(progress)
    var lines := {
        "herbs":["Add ginger to the mortar.","Add turmeric to the mortar.","Add the leaves to the mortar.","Tap the mortar five times to pound the herbs."],
        "water":["Water the highlighted dry plant."],
        "weave":["Drag the pandan strip to the row with its matching number."],
        "net":["Join the loose cord to the knot with its matching number."],
        "rice":["Drag the rice into the pot.","Pour the water into the pot.","Lift the pot when the marker reaches the green zone."],
        "fire":["Place the dry twigs in the fire pit.","Stack the logs on the twigs.","Tap the flint five times to make sparks."],
        "sweep":["Swipe through the dirt. Piles cleared: %d/5"%progress],
        "laundry":["Drag the cloth to the matching colour on the line."],
        "flowers":["Find the hidden flowers. Flowers found: %d/5"%progress],
        "marbles":["Pull the marble back, aim the arrow, then release."],
        "lamp":["Join the wire ends with matching colours and letters."],
        "slippers":["Drag each shoe to its matching colour on the right."]
    }
    var messages: Array = lines.get(task_kind,["Complete the task."])
    _instruction.text = "Task complete!" if progress >= required_progress else messages[mini(progress,messages.size()-1)]
    feedback_label.text = "Swipe with your finger or mouse." if task_kind=="sweep" else "You can also tap the object, then tap its target." if task_kind in ["rice","fire","laundry","marbles","lamp","slippers"] else "Look for petals behind the leaves."
    if task_kind in ["herbs","water","weave","net"]: feedback_label.text="Drag the object, or tap it and then tap the highlighted target."
    if task_kind=="rice" and progress==2: feedback_label.text="Cooking only: wait for the rice to cook, then lift the pot."
    if task_kind=="herbs" and progress==3: feedback_label.text="Tap the stone mortar five times to pound the ingredients."
    if task_kind=="fire" and progress==2: feedback_label.text="Tap the flint to light the stacked wood."
    if task_kind=="marbles": feedback_label.text="Pull for power • green: inside • red: miss • land all 4 marbles"
    if task_kind=="slippers": feedback_label.text="Place both shoes of each colour to complete all four pairs."
    if task_kind=="lamp" and progress<3: _instruction.text="Connect wire %s to its matching letter and colour."%["A","B","C"][progress]
    queue_redraw()

func set_input_enabled(enabled: bool) -> void:
    if enabled: _pending = false
    input_enabled = enabled and current_progress < required_progress

func _process(delta: float) -> void:
    if realistic_art != null:
        realistic_art.advance(delta)
        queue_redraw()
    if task_kind=="marbles" and _shot.rolling:
        var outcome := _shot.advance(delta)
        if outcome=="inside": _submit("timing_good")
        elif outcome=="miss":
            _shot.reset()
            _miss("The marble stopped outside the circle. Adjust your aim and power, then try again.")
        queue_redraw()
    if task_kind=="rice" and current_progress==2 and input_enabled:
        _heat += delta*_heat_direction*0.45
        if _heat>=1: _heat=1; _heat_direction=-1
        if _heat<=0: _heat=0; _heat_direction=1
        queue_redraw()

func _text(copy: String, at: Vector2, font_size: int = 18, color: Color = CREAM) -> void:
    draw_string(ThemeDB.fallback_font,at,copy,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _box(rect: Rect2, fill: Color, edge: Color = GOLD) -> void:
    draw_style_box(_style(fill,edge),rect)

func _style(fill: Color, edge: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color=fill; style.border_color=edge
    style.set_border_width_all(2); style.set_corner_radius_all(12)
    return style

func _source() -> Vector2:
    if task_kind=="slippers" and is_instance_valid(shoe_board): return shoe_board.next_source()
    if task_kind=="net": return Vector2(145,100+current_progress*60)
    if task_kind=="weave": return Vector2(145,115+current_progress*50)
    if task_kind=="lamp": return Vector2(135,106+current_progress*77)
    return Vector2(145,180)

func _target() -> Vector2:
    match task_kind:
        "water": return Vector2(350+current_progress*110,210)
        "weave": return Vector2(535,115+current_progress*50)
        "net": return Vector2(630,100+[2,0,3,1][mini(current_progress,3)]*60)
        "lamp": return Vector2(650,106+([2,0,1][mini(current_progress,2)])*77)
        "laundry": return Vector2(340+current_progress*105,155)
        "slippers": return shoe_board.next_target()
        _: return Vector2(535,182)

func _flower_position() -> Vector2:
    return [Vector2(178,125),Vector2(590,240),Vector2(348,184),Vector2(649,115),Vector2(420,265)][mini(current_progress,4)]

func _dust_position() -> Vector2:
    return [Vector2(220,140),Vector2(545,245),Vector2(390,180),Vector2(620,115),Vector2(182,272)][mini(current_progress,4)]

func _draw() -> void:
    if realistic_art != null: realistic_art.draw_board(self)

func _ellipse(at: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in 32: points.append(at+Vector2(cos(i*TAU/32)*radius.x,sin(i*TAU/32)*radius.y))
    draw_colored_polygon(points,color)

func _gui_input(event: InputEvent) -> void:
    if task_kind=="slippers" and is_instance_valid(shoe_board):
        shoe_board.input_enabled=input_enabled and not _pending
        shoe_board.handle_input(event)
        accept_event()
        return
    if not input_enabled or _pending or (task_kind=="marbles" and _shot.rolling):
        # Network acknowledgements can arrive after the finger is lifted.
        # Always release ownership so the next swipe starts a fresh gesture.
        if event is InputEventScreenTouch and not event.pressed and event.index==_touch_id: _touch_id=-1
        if event is InputEventMouseButton and not event.pressed: _dragging=false
        return
    if event is InputEventScreenTouch:
        if event.pressed and _touch_id<0: _touch_id=event.index; _press(event.position)
        elif not event.pressed and event.index==_touch_id: _release(event.position); _touch_id=-1
        accept_event()
    elif event is InputEventScreenDrag and event.index==_touch_id:
        _motion(event.position); accept_event()
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and _touch_id<0:
        if event.pressed: _press(event.position)
        else: _release(event.position)
        accept_event()
    elif event is InputEventMouseMotion and _dragging and _touch_id<0:
        _motion(event.position); accept_event()

func _press(at: Vector2) -> void:
    _pointer=at; _last_pointer=at
    if task_kind=="marbles":
        if at.distance_to(_shot.anchor)<=28:
            _dragging=true
            queue_redraw()
        else: _miss("Touch the marble first, then pull it back.")
        return
    if task_kind=="herbs" and current_progress==3:
        if at.distance_to(_target())<=68:
            if realistic_art != null: realistic_art.action(task_kind,current_progress,_target() if task_kind=="herbs" else Vector2(145,180))
            _sparks+=1; sound_requested.emit("ui"); queue_redraw()
            if _sparks>=5: _submit("timing_good")
        else: _miss("Tap the mortar to pound the herbs.")
        return
    if task_kind=="flowers":
        if at.distance_to(_flower_position())<=28: _submit("collect")
        else: _miss("No flower there. Look between the leaves.")
        return
    if task_kind=="rice" and current_progress==2:
        if Rect2(525,269,190,42).has_point(at):
            if _heat>=0.55 and _heat<=0.8: _submit("timing_good")
            else: _miss("Wait for the marker to reach the green zone before lifting the pot.")
        return
    if task_kind=="fire" and current_progress==2:
        if Rect2(73,128,148,105).has_point(at):
            if realistic_art != null: realistic_art.action(task_kind,current_progress,Vector2(145,180))
            _sparks+=1; sound_requested.emit("ui"); queue_redraw()
            if _sparks>=5: _submit("timing_good")
        return
    if task_kind=="sweep": _dragging=true; queue_redraw(); return
    if _selected and _drop_valid(at): _submit("drag"); return
    if at.distance_to(_source())<=70:
        _selected=true; _dragging=true; queue_redraw()
    else: _miss("Select the object first, then drag it to the target.")

func _motion(at: Vector2) -> void:
    if not _dragging: return
    if task_kind=="sweep":
        var closest := Geometry2D.get_closest_point_to_segment(_dust_position(),_last_pointer,at)
        if closest.distance_to(_dust_position())<48: _stroke+=minf(at.distance_to(_last_pointer),120)
        if _stroke>=90: _submit("drag")
    _pointer=at; _last_pointer=at; queue_redraw()

func _release(at: Vector2) -> void:
    if _pending or not input_enabled: return
    if task_kind=="marbles":
        if _dragging:
            if _shot.launch(_source()-at): feedback_label.text="The marble is rolling…"
            else: _miss("Pull back a little to launch the marble.")
        _dragging=false; _selected=false; queue_redraw()
        return
    if _dragging and task_kind!="sweep":
        if _drop_valid(at): _submit("drag")
        else: feedback_label.text="Not quite. Select the object and try the target again."
    _dragging=false; _pointer=at; queue_redraw()

func _drop_valid(at: Vector2) -> bool:
    if task_kind=="marbles": return false
    if task_kind in ["lamp","slippers","laundry","water","weave","net"]: return at.distance_to(_target())<=38
    return at.distance_to(_target())<=68

func _miss(copy: String) -> void:
    sound_requested.emit("timing_miss"); feedback_label.text=copy

func _submit(sound_kind: String) -> void:
    if not input_enabled or _pending: return
    if realistic_art != null:
        var at: Vector2 = _flower_position() if task_kind=="flowers" else _dust_position() if task_kind=="sweep" else _target()
        realistic_art.action(task_kind,current_progress,at)
    _pending=true; input_enabled=false; _dragging=false; _selected=false
    sound_requested.emit(sound_kind)
    step_completed.emit()
    queue_redraw()
