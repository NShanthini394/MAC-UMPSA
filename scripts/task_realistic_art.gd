extends RefCounted
## Image props and time-based effects only; task rules stay in TaskMiniGame.
const ATLAS_PATH := "res://assets/tasks/realistic/village_props_v2.png"
const WOOD_PATH := "res://assets/tasks/realistic/timber_table.png"
const CLOTH_PATH := "res://assets/tasks/realistic/hanging_batik.png"
const CREAM := Color("fff0cf")
const INK := Color("30251b")
const COLORS := [Color("dc7964"),Color("edcb78"),Color("82becb"),Color("a9c485")]
var atlas: Texture2D
var wood: Texture2D
var cloth: Texture2D
var clock := 0.0
var effects: Array[Dictionary] = []
var impact := 0.0

func _init() -> void:
    atlas = load(ATLAS_PATH) as Texture2D
    wood = load(WOOD_PATH) as Texture2D
    cloth = load(CLOTH_PATH) as Texture2D

func advance(delta: float) -> void:
    clock += delta
    impact = maxf(0.0,impact-delta*4.0)
    for effect in effects: effect["age"] += delta
    effects = effects.filter(func(e: Dictionary) -> bool: return e["age"]<e["duration"])

func action(kind: String, stage: int, at: Vector2) -> void:
    effects.append({"kind":kind,"stage":stage,"at":at,"age":0.0,"duration":0.85})
    impact = 1.0

func prop(b: Control, index: int, at: Vector2, extent: Vector2, angle: float = 0.0, tint: Color = Color.WHITE, shadow: bool = true) -> void:
    if atlas == null: return
    var cell := Vector2(atlas.get_size())/Vector2(6,4)
    var region := Rect2(Vector2(index%6,index/6)*cell,cell)
    # Tight authored regions exclude adjacent plant/mat tips in the source sheet.
    if index in [12,13]: region = Rect2(region.position+Vector2(0,8),cell-Vector2(0,32))
    if index==11: region = Rect2(region.position+Vector2(0,20),cell-Vector2(0,20))
    if shadow:
        b._ellipse(at+Vector2(3,extent.y*0.29),Vector2(extent.x*0.31,extent.y*0.065),Color(0.04,0.025,0.01,0.25*tint.a))
    b.draw_set_transform(at,angle)
    if index==6 and cloth:
        b.draw_texture_rect(cloth,Rect2(-extent*0.5,extent),false,tint)
    else:
        b.draw_texture_rect_region(atlas,Rect2(-extent*0.5,extent),region,tint)
    b.draw_set_transform(Vector2.ZERO)

func label(b: Control, copy: String, at: Vector2, size: int = 15, color: Color = CREAM) -> void:
    copy = preload("res://scripts/app_language.gd").text(copy)
    b.draw_string(ThemeDB.fallback_font,at+Vector2(1,2),copy,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0,0,0,0.65))
    b.draw_string(ThemeDB.fallback_font,at,copy,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func halo(b: Control, at: Vector2, radius: float = 40.0) -> void:
    b.draw_arc(at,radius+sin(clock*3.0)*2,0,TAU,48,Color(1,0.85,0.5,0.6+sin(clock*3.0)*0.15),2,true)

func steam(b: Control, at: Vector2, strength: float = 1.0) -> void:
    for i in 6:
        var life := fmod(clock*0.45+i/6.0,1.0)
        var p := at+Vector2(sin(life*5+i)*12+(i-3)*8,-life*72)
        b.draw_circle(p,5+life*10,Color(0.94,0.93,0.84,(1-life)*0.2*strength),true,-1,true)

func flame(b: Control, at: Vector2, strength: float) -> void:
    b._ellipse(at+Vector2(0,-12),Vector2(65,35)*strength,Color(1,0.43,0.09,0.1))
    for i in 7:
        var h := (25+sin(clock*9+i*2)*9)*strength
        var base := at+Vector2((i-3)*12,0)*strength
        var tip := base+Vector2(sin(clock*6+i)*6,-h*2)
        b.draw_colored_polygon(PackedVector2Array([base-Vector2(10,0)*strength,tip,base+Vector2(10,0)*strength]),Color("df6e28"))
        b.draw_colored_polygon(PackedVector2Array([base-Vector2(5,0)*strength,base.lerp(tip,0.65),base+Vector2(5,0)*strength]),Color("ffcf70"))

func draw_board(b: Control) -> void:
    b._box(Rect2(0,0,792,382),Color("211d18"),Color("9d7546"))
    if wood: b.draw_texture_rect(wood,Rect2(22,51,748,279),false)
    b.draw_rect(Rect2(22,51,748,279),Color(0.04,0.025,0.01,0.22))
    if b.current_progress>=b.required_progress:
        label(b,"TASK COMPLETE",Vector2(270,205),28)
        _effects(b)
        return
    var source: Vector2 = b._pointer if b._dragging else b._source()
    var stage: int = b.current_progress
    match b.task_kind:
        "rice": _rice(b,source,stage)
        "fire": _fire(b,source,stage)
        "sweep": _sweep(b)
        "laundry": _laundry(b,source,stage)
        "flowers": _flowers(b)
        "marbles": _marbles(b)
        "lamp": _lamp(b,stage)
        "herbs": _herbs(b,source,stage)
        "water": _water(b,source,stage)
        "weave": _weave(b,source,stage)
        "net": _net(b,source,stage)
        "slippers": pass # Existing photographed footwear is drawn by ShoeArrangement.
    _effects(b)
    if b._pending: label(b,"Saving progress…",Vector2(285,322),15)

func _rice(b: Control, source: Vector2, stage: int) -> void:
    prop(b,0,Vector2(535,181),Vector2(200,190))
    if stage>0: steam(b,Vector2(535,124),0.45 if stage==1 else 1.0)
    if stage<2:
        prop(b,1 if stage==0 else 2,source,Vector2(130,130),-0.18 if b._dragging else sin(clock*1.5)*0.025)
        halo(b,Vector2(535,182),65)
        label(b,"RICE" if stage==0 else "WATER",Vector2(112,275))
    else:
        flame(b,Vector2(535,244),0.6)
        b._box(Rect2(92,268,400,23),Color("3c3529"))
        b.draw_rect(Rect2(312,270,100,19),Color("6c9b60"))
        b.draw_line(Vector2(92+b._heat*400,260),Vector2(92+b._heat*400,299),CREAM,4,true)
        b._box(Rect2(525,269,190,42),Color("63513a"))
        label(b,"LIFT THE POT",Vector2(547,297),17)

func _fire(b: Control, source: Vector2, stage: int) -> void:
    b._ellipse(Vector2(535,225),Vector2(107,59),Color("48463c"))
    b._ellipse(Vector2(535,220),Vector2(88,43),Color("272720"))
    if stage>=1: prop(b,3,Vector2(535,213),Vector2(190,140),0.3)
    if stage>=2: prop(b,3,Vector2(535,185),Vector2(175,130),-0.3)
    prop(b,3 if stage<2 else 4,source,Vector2(150,135),-0.12*impact)
    if stage==2:
        flame(b,Vector2(535,210),0.15+b._sparks*0.12)
        label(b,preload("res://scripts/app_language.gd").text("STRIKES  %d / 5") %b._sparks,Vector2(90,280))
    else:
        halo(b,Vector2(535,182),65)
        label(b,"DRY TWIGS" if stage==0 else "FIREWOOD",Vector2(90,280))

func _sweep(b: Control) -> void:
    prop(b,23,b._dust_position(),Vector2(125,95))
    prop(b,5,b._pointer+Vector2(10,-18),Vector2(150,150),sin(clock*18)*0.08 if b._dragging else 0.0)
    if b._dragging:
        for i in 10:
            var life := fmod(clock*1.8+i*0.1,1.0)
            b.draw_circle(b._pointer+Vector2((i-5)*5,-life*35),2+life*3,Color(0.75,0.65,0.43,(1-life)*0.35))
    label(b,preload("res://scripts/app_language.gd").text("DIRT CLEARED  %d / 5") %b.current_progress,Vector2(530,307))

func _laundry(b: Control, source: Vector2, stage: int) -> void:
    b.draw_line(Vector2(280,76),Vector2(280,286),Color("805e3e"),8,true)
    b.draw_line(Vector2(730,76),Vector2(730,286),Color("805e3e"),8,true)
    b.draw_polyline(PackedVector2Array([Vector2(280,92),Vector2(505,101),Vector2(730,92)]),Color("d1b78a"),3,true)
    for i in 4:
        var at := Vector2(340+i*105,155)
        if i<stage:
            prop(b,6,at,Vector2(100,125),sin(clock*2+i)*0.07,COLORS[i])
            b.draw_line(at+Vector2(-24,-54),at+Vector2(-24,-40),CREAM,5,true)
        else:
            b.draw_arc(at,37,0,TAU,32,COLORS[i],2,true)
        label(b,str(i+1),at+Vector2(-4,87),15,COLORS[i])
    prop(b,6,source,Vector2(100,125),-0.1 if b._dragging else 0.0,COLORS[stage])
    b.draw_circle(source+Vector2(36,-37),14,COLORS[stage])
    label(b,str(stage+1),source+Vector2(32,-32),15,INK)
    label(b,preload("res://scripts/app_language.gd").text("MATCH COLOUR  %d") %(stage+1),Vector2(70,287))

func _flowers(b: Control) -> void:
    for i in 17:
        var at := Vector2(85+(i*127)%625,100+(i*73)%190)
        prop(b,8,at,Vector2(112,95),sin(clock*1.4+i)*0.035,Color.WHITE,false)
    var at: Vector2 = b._flower_position()
    prop(b,7,at,Vector2(72,72),sin(clock*1.8)*0.05)
    for offset in [Vector2(-26,24),Vector2(28,20)]:
        prop(b,8,at+offset,Vector2(65,45),sin(clock*1.4)*0.03,Color.WHITE,false)
    label(b,preload("res://scripts/app_language.gd").text("JASMINE COLLECTED  %d / 5") %b.current_progress,Vector2(470,311))

func _marbles(b: Control) -> void:
    b._ellipse(b._shot.goal+Vector2(0,7),Vector2(91,88),Color(0,0,0,0.13))
    b.draw_arc(b._shot.goal,85,0,TAU,64,Color("f1dfb3"),4,true)
    for i in b.current_progress: prop(b,9,Vector2(512+i%2*35,163+i/2*34),Vector2(42,42),0.0,COLORS[i])
    var at: Vector2 = b._shot.position
    if b._dragging:
        var pull: Vector2 = b._shot.clamped_pull(b._source()-b._pointer)
        at = b._source()-pull
        var landing: Vector2 = b._shot.prediction(pull)
        var inside: bool = b._shot.inside_goal(landing)
        var color := Color("8bbd76") if inside else Color("e67d68")
        var tip := landing.clamp(Vector2(55,83),Vector2(735,297))
        var direction := (tip-at).normalized()
        b.draw_dashed_line(at,tip,color,3,8,true)
        b.draw_colored_polygon(PackedVector2Array([tip,tip-direction*14+direction.orthogonal()*7,tip-direction*14-direction.orthogonal()*7]),color)
        b.draw_arc(tip,18,0,TAU,24,color,2,true)
        label(b,"INSIDE" if inside else "MISS",Vector2(300,305),18,color)
    prop(b,9,at,Vector2(44,44),clock*5.0 if b._shot.rolling else 0.0,COLORS[b.current_progress%4])
    label(b,preload("res://scripts/app_language.gd").text("INSIDE  %d / 4") %b.current_progress,Vector2(485,309))

func cable(b: Control, from: Vector2, to: Vector2, color: Color, sag: float = 26.0) -> void:
    var points := PackedVector2Array()
    for i in 25:
        var t := i/24.0
        points.append(from.lerp(to,t)+Vector2(0,sin(t*PI)*sag))
    b.draw_polyline(points,Color("27261f"),9,true)
    b.draw_polyline(points,color,5,true)
    b.draw_polyline(points,Color(1,1,1,0.2),1,true)

func _lamp(b: Control, stage: int) -> void:
    b._box(Rect2(85,76,100,220),Color("3b3a32"),Color("937e59"))
    b._box(Rect2(600,76,100,220),Color("3b3a32"),Color("937e59"))
    prop(b,10,Vector2(392,178),Vector2(145,190),sin(clock*1.5)*0.015,Color(0.65,0.65,0.6) if stage==0 else Color.WHITE)
    if stage>0: b.draw_circle(Vector2(392,153),42+sin(clock*5)*2,Color(1,0.72,0.27,0.1*stage))
    for i in 3:
        var left := Vector2(135,106+i*77)
        var right := Vector2(650,106+[2,0,1][i]*77)
        if i<stage: cable(b,left,right,COLORS[i])
        b.draw_circle(left,23,Color("1e211d")); b.draw_circle(right,23,Color("1e211d"))
        b.draw_circle(left,18,COLORS[i]); b.draw_circle(right,18,COLORS[i])
        label(b,["A","B","C"][i],left+Vector2(-6,6),18,INK)
        label(b,["A","B","C"][i],right+Vector2(-6,6),18,INK)
        if i==stage: halo(b,left,26)
    if b._selected: cable(b,b._source(),b._pointer,COLORS[stage],12)

func _herbs(b: Control, source: Vector2, stage: int) -> void:
    prop(b,12,Vector2(535,188),Vector2(210,180))
    for i in mini(stage,3): prop(b,14+i,Vector2(510+i*24,167),Vector2(48,48),i*0.7,Color.WHITE,false)
    var offset := Vector2(-impact*18,impact*30) if stage==3 else Vector2.ZERO
    prop(b,13,Vector2(587,119)+offset,Vector2(120,150),-0.15-impact*0.25)
    if stage<3:
        prop(b,14+stage,source,Vector2(125,120),-0.12 if b._dragging else 0.0)
        label(b,["GINGER","TURMERIC","HERB LEAVES"][stage],Vector2(85,280))
        halo(b,Vector2(535,182),65)
    else:
        halo(b,Vector2(535,182),65)
        label(b,preload("res://scripts/app_language.gd").text("POUND HERBS  %d / 5") %b._sparks,Vector2(80,280))

func _water(b: Control, source: Vector2, stage: int) -> void:
    for i in 4:
        var at := Vector2(350+i*110,210)
        var sway := sin(clock*1.9+i)*0.025
        prop(b,18,at,Vector2(100,145),sway,Color.WHITE if i<stage else Color("c8b88e"))
        if i<stage: b._ellipse(at+Vector2(0,35),Vector2(27,7),Color(0.08,0.13,0.08,0.3))
        if i==stage: halo(b,at,42)
        label(b,"WATERED" if i<stage else "DRY",at+Vector2(-31,80),12)
    prop(b,17,source,Vector2(145,130),0.22 if b._dragging else 0.0)

func _weave(b: Control, source: Vector2, stage: int) -> void:
    prop(b,19,Vector2(535,185),Vector2(320,255),0.0,Color(0.8,0.8,0.7))
    for i in 4:
        var at := Vector2(535,115+i*50)
        if i<stage: prop(b,20,at,Vector2(280,50),0.0,COLORS[i],false)
        else: b.draw_dashed_line(at-Vector2(100,0),at+Vector2(100,0),COLORS[i],2,6,true)
        label(b,str(i+1),at+Vector2(137,5),18)
    prop(b,20,source,Vector2(160,45),sin(clock*2)*0.025,COLORS[stage])
    label(b,str(stage+1),source+Vector2(-5,6),17)

func _net(b: Control, source: Vector2, stage: int) -> void:
    prop(b,21,Vector2(495,181),Vector2(370,265))
    for i in 4:
        var knot := Vector2(630,100+[2,0,3,1][i]*60)
        if i<stage:
            cable(b,Vector2(335,100+i*60),knot,COLORS[i],12)
            for ring in 3: b.draw_arc(knot+Vector2(ring*2,0),6+ring,0,TAU,20,CREAM,2,true)
        b.draw_circle(knot,18,COLORS[i])
        label(b,str(i+1),knot+Vector2(-5,6),17,INK)
    prop(b,22,Vector2(108,230),Vector2(140,140))
    cable(b,Vector2(85,source.y),source,COLORS[stage],12)
    b.draw_circle(source,20,COLORS[stage])
    label(b,str(stage+1),source+Vector2(-5,6),17,INK)

func _effects(b: Control) -> void:
    for effect in effects:
        var t: float = effect["age"]/effect["duration"]
        var at: Vector2 = effect["at"]
        var alpha := 1.0-t
        match str(effect["kind"]):
            "water", "rice":
                if effect["kind"]=="rice" and effect["stage"]==2:
                    prop(b,0,at+Vector2(0,-t*45),Vector2(200,190),-t*0.06,Color(1,1,1,alpha))
                    continue
                var is_grain: bool = effect["kind"]=="rice" and effect["stage"]==0
                prop(b,1 if is_grain else 2 if effect["kind"]=="rice" else 17,at+Vector2(-63,-59),Vector2(115,115),0.35,Color(1,1,1,alpha))
                for i in 14:
                    var p := at+Vector2(-55+i*4,-80).lerp(Vector2(sin(i*3)*22,10),clampf(t*2+i*0.025,0,1))
                    b.draw_line(p,p+Vector2(0,3 if is_grain else 8),Color(0.94,0.89,0.72,alpha) if is_grain else Color(0.6,0.84,0.94,alpha),2,true)
                b.draw_arc(at+Vector2(0,15),10+t*35,0,TAU,32,Color(0.65,0.85,0.94,alpha*0.6),2,true)
            "fire", "lamp":
                for i in 12:
                    var direction := Vector2.from_angle(i*2.4)
                    var p := at+direction*t*65+Vector2(0,t*t*32)
                    b.draw_line(p,p-direction*6,Color(1,0.77,0.3,alpha),2,true)
            "herbs", "sweep":
                for i in 12:
                    var p := at+Vector2(sin(i*3.1)*t*60,-sin(t*PI)*35+cos(i*2)*15)
                    b.draw_circle(p,2+alpha*2,Color(0.71,0.67,0.37,alpha*0.65))
            "laundry", "weave", "net":
                b.draw_arc(at,16+t*28,0,TAU,40,Color(0.78,0.91,0.6,alpha*0.7),2,true)
                if effect["kind"]=="weave":
                    prop(b,20,at+Vector2(-120*(1-t),0),Vector2(280,50),0.0,Color(1,1,1,alpha),false)
                elif effect["kind"]=="net":
                    for ring in 3: b.draw_arc(at+Vector2(ring*2,0),7+(1-t)*20+ring,0,TAU,24,Color(0.9,0.81,0.62,alpha),2,true)
                else:
                    prop(b,6,at,Vector2(100,125),sin(t*PI*4)*(1-t)*0.2,Color(1,1,1,alpha),false)
            "flowers":
                prop(b,7,at+Vector2(0,-t*55),Vector2(65,65)*(1-t*0.3),t*0.6,Color(1,1,1,alpha),false)
            "marbles":
                b.draw_arc(at,15+t*30,0,TAU,32,Color(0.78,0.91,0.6,alpha),2,true)
