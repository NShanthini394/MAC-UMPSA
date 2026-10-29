extends Control
## Eight village chores. Mouse, touch drag, and tap-to-place share the same rules.
signal step_completed
signal sound_requested(kind: String)
const CREAM := Color("fff0cf")
const GOLD := Color("edbb63")
const INK := Color("30251b")
const MarbleShot = preload("res://scripts/marble_shot.gd")
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
    if task_kind=="rice" and progress==2: feedback_label.text="Cooking only: wait for the rice to cook, then lift the pot."
    if task_kind=="fire" and progress==2: feedback_label.text="Tap the flint to light the stacked wood."
    if task_kind=="marbles": feedback_label.text="Pull for power • green: inside • red: miss • land all 4 marbles"
    if task_kind=="slippers": feedback_label.text="Place both shoes of each colour to complete all four pairs."
    if task_kind=="lamp" and progress<3: _instruction.text="Connect wire %s to its matching letter and colour."%["A","B","C"][progress]
    queue_redraw()

func set_input_enabled(enabled: bool) -> void:
    if enabled: _pending = false
    input_enabled = enabled and current_progress < required_progress

func _process(delta: float) -> void:
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
    if task_kind=="lamp": return Vector2(135,106+current_progress*77)
    return Vector2(145,180)

func _target() -> Vector2:
    match task_kind:
        "lamp": return Vector2(650,106+([2,0,1][mini(current_progress,2)])*77)
        "laundry": return Vector2(340+current_progress*105,155)
        "slippers": return shoe_board.next_target()
        _: return Vector2(535,182)

func _flower_position() -> Vector2:
    return [Vector2(178,125),Vector2(590,240),Vector2(348,184),Vector2(649,115),Vector2(420,265)][mini(current_progress,4)]

func _dust_position() -> Vector2:
    return [Vector2(220,140),Vector2(545,245),Vector2(390,180),Vector2(620,115),Vector2(182,272)][mini(current_progress,4)]

func _draw() -> void:
    _box(Rect2(Vector2.ZERO,Vector2(792,382)),Color("30251c"),Color("b9833f"))
    _box(Rect2(22,51,748,279),Color("b78a54"),Color("674728"))
    for i in 10: draw_line(Vector2(24,65+i*27),Vector2(766,65+i*27),Color(0.3,0.2,0.1,0.12),1)
    if current_progress>=required_progress:
        _text("✓   TASK COMPLETE",Vector2(250,200),30,CREAM)
        return
    var source := _pointer if _dragging else _source()
    match task_kind:
        "rice":
            draw_circle(Vector2(535,220),65,Color("5e3d26"))
            draw_arc(Vector2(535,220),55,0,PI,24,Color("ed9f4c"),10,true)
            _box(Rect2(467,134,136,80),Color("525654"),Color("ccd0c1"))
            _ellipse(Vector2(535,139),Vector2(68,16),Color("d9d6b6"))
            if current_progress>0:
                for i in 35: draw_line(Vector2(482+(i*29)%107,136+(i*7)%9),Vector2(487+(i*29)%107,137+(i*7)%9),CREAM,2,true)
            if current_progress<2:
                _box(Rect2(source-Vector2(62,40),Vector2(124,80)),Color("795334"))
                _text("RICE" if current_progress==0 else "WATER",source+Vector2(-35,8),22)
                _text("RICE POT",Vector2(472,270),18,INK)
            else:
                _box(Rect2(92,268,400,23),Color("64533b"))
                draw_rect(Rect2(92+400*0.55,270,400*0.25,19),Color("66965d"))
                draw_line(Vector2(92+_heat*400,260),Vector2(92+_heat*400,299),CREAM,5)
                _box(Rect2(525,269,190,42),Color("784f2f"))
                _text("LIFT THE POT",Vector2(541,297),18)
        "fire":
            draw_circle(Vector2(535,210),90,Color("6f6b59"))
            draw_circle(Vector2(535,210),70,Color("3e3127"))
            if current_progress>=1: _logs(Vector2(535,210),Color("cead75"),4)
            if current_progress>=2: _logs(Vector2(535,200),Color("794c2b"),3)
            if current_progress<2:
                _logs(source,Color("cead75") if current_progress==0 else Color("794c2b"),4)
                _text("TWIGS" if current_progress==0 else "LOGS",Vector2(95,275),18,INK)
            else:
                _box(Rect2(73,128,148,105),Color("7a7f78"))
                _text("FLINT",Vector2(97,188),20)
                _text("Sparks: %d/5"%_sparks,Vector2(88,270),17,INK)
                for i in _sparks: draw_line(Vector2(520+i*6,160),Vector2(515+i*11,140-i*4),GOLD,3,true)
        "sweep":
            var dust := _dust_position()
            for i in 24:
                var point := dust+Vector2(sin(i*3.1)*42,cos(i*2.3)*22)
                draw_circle(point,3+(i%3),Color("624a2e"))
            draw_line(_pointer+Vector2(26,-35),_pointer+Vector2(-8,14),Color("6a4028"),7,true)
            for i in 10: draw_line(_pointer+Vector2(-13+i*3,5),_pointer+Vector2(-30+i*6,30),Color("dfbd73"),3,true)
            _text("SWEEP",Vector2(640,299),20,INK)
        "laundry":
            draw_line(Vector2(280,94),Vector2(730,94),INK,5)
            draw_line(Vector2(280,75),Vector2(280,278),Color("6b4629"),9)
            draw_line(Vector2(730,75),Vector2(730,278),Color("6b4629"),9)
            for i in 4:
                var at := Vector2(340+i*105,155)
                if i<current_progress: _cloth(at,COLORS[i])
                else: draw_rect(Rect2(at-Vector2(33,35),Vector2(66,76)),COLORS[i],false,3)
            _cloth(source,COLORS[current_progress%4])
        "flowers":
            for i in 34:
                var at := Vector2(66+(i*101)%653,82+(i*47)%220)
                _ellipse(at,Vector2(32,15),Color("5f7b48") if i%2 else Color("829553"))
            var flower := _flower_position()
            for i in 6: draw_circle(flower+Vector2.from_angle(i*TAU/6)*10,8,Color("eee4c3"))
            draw_circle(flower,6,Color("dda943"))
            for offset in [Vector2(-17,14),Vector2(14,16),Vector2(22,-5)]: _ellipse(flower+offset,Vector2(17,7),Color("658443"))
        "marbles":
            draw_circle(_shot.goal,85,Color("cfaa6e"))
            draw_arc(_shot.goal,85,0,TAU,48,CREAM,5,true)
            for i in current_progress: _marble(Vector2(512+i%2*35,163+i/2*34),COLORS[i])
            var marble_at := _shot.position
            if _dragging:
                var pull := _shot.clamped_pull(_source()-_pointer)
                marble_at = _source()-pull
                var landing := _shot.prediction(pull)
                var inside := _shot.inside_goal(landing)
                var color := Color("679e4b") if inside else Color("b54936")
                var tip := landing.clamp(Vector2(55,83),Vector2(735,297))
                var direction := (tip-marble_at).normalized()
                draw_line(marble_at,_source(),Color(0.3,0.2,0.1,0.4),2,true)
                draw_dashed_line(marble_at,tip,color,3,8,true)
                draw_colored_polygon(PackedVector2Array([tip,tip-direction*14+direction.orthogonal()*7,tip-direction*14-direction.orthogonal()*7]),color)
                draw_arc(tip,18,0,TAU,24,color,2,true)
                _text("INSIDE" if inside else "MISS",Vector2(300,305),18,color)
            _marble(marble_at,COLORS[current_progress%4])
            _text("INSIDE: %d / 4"%current_progress,Vector2(460,307),18,INK)
        "lamp":
            for i in 3:
                var left := Vector2(135,106+i*77)
                var right := Vector2(650,106+([2,0,1][i])*77)
                if i<current_progress: draw_line(left,right,COLORS[i],7,true)
                draw_circle(left,22,COLORS[i]); draw_circle(right,22,COLORS[i])
                if i==current_progress: draw_arc(left,27,0,TAU,24,CREAM,3,true)
                _text(["A","B","C"][i],left+Vector2(-6,7),21,INK)
                _text(["A","B","C"][i],right+Vector2(-6,7),21,INK)
            if _selected: draw_line(_source(),_pointer,COLORS[current_progress],7,true)
            draw_circle(Vector2(392,159),31,Color("786949"))
            _box(Rect2(374,187,36,32),Color("6c6457"))
            _text("LAMP",Vector2(363,253),18,INK)
        "slippers":
            pass # The footwear board draws eight independently movable image sprites.
    if _pending: _text("Saving progress…",Vector2(285,322),16,CREAM)

func _ellipse(at: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in 32: points.append(at+Vector2(cos(i*TAU/32)*radius.x,sin(i*TAU/32)*radius.y))
    draw_colored_polygon(points,color)

func _logs(at: Vector2, color: Color, count: int) -> void:
    for i in count:
        var start := at+Vector2(-43+i*8,-18+i*13)
        draw_line(start,start+Vector2(80,-10),Color("513721"),15,true)
        draw_line(start,start+Vector2(80,-10),color,10,true)

func _cloth(at: Vector2, color: Color) -> void:
    _box(Rect2(at-Vector2(34,37),Vector2(68,78)),color,INK)
    for i in 4: draw_line(at+Vector2(-30,-23+i*16),at+Vector2(30,-23+i*16),CREAM,2,true)

func _marble(at: Vector2, color: Color) -> void:
    draw_circle(at,18,INK); draw_circle(at,15,color)
    draw_circle(at+Vector2(-5,-5),5,CREAM)

func _slipper(at: Vector2, color: Color, left: bool) -> void:
    _ellipse(at,Vector2(19,45),INK)
    _ellipse(at,Vector2(16,41),color)
    draw_line(at+Vector2(-13,-20),at+Vector2(0,4),CREAM,5,true)
    draw_line(at+Vector2(13,-20),at+Vector2(0,4),CREAM,5,true)
    _text("L" if left else "R",at+Vector2(-5,28),14,INK)

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
    if task_kind in ["lamp","slippers","laundry"]: return at.distance_to(_target())<=38
    return at.distance_to(_target())<=68

func _miss(copy: String) -> void:
    sound_requested.emit("timing_miss"); feedback_label.text=copy

func _submit(sound_kind: String) -> void:
    if not input_enabled or _pending: return
    _pending=true; input_enabled=false; _dragging=false; _selected=false
    sound_requested.emit(sound_kind)
    step_completed.emit()
    queue_redraw()
