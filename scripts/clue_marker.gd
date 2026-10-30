extends Node2D
## A floating investigation seal with fireflies, a soft halo and ground ripples.
var clue_index := 0
var animation_time := 0.0
const INK := Color("191b19")
const GOLD := Color("efcb80")
const GLOW := Color("a3dfce")

func _ready() -> void:
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	animation_time = clue_index*1.7

func _process(delta: float) -> void:
	animation_time += delta
	if is_visible_in_tree(): queue_redraw()

func _draw() -> void:
	var t := animation_time
	var bob := sin(t*2.1)*2.5
	var centre := Vector2(0,-18+bob)
	draw_ellipse(Vector2(0,3),13,4,Color(0,0,0,0.3))
	for i in 2:
		var phase := fmod(t*0.4+i*0.5,1.0)
		draw_ellipse(Vector2(0,2),10+phase*12,3+phase*3,Color(GLOW,0.19*(1-phase)))
	for i in range(4,0,-1):
		draw_circle(centre,12+i*3,Color(GLOW,0.018+sin(t*2)*0.004),true,-1,true)
	# Parchment corners and magnifying glass identify a clue without revealing it.
	draw_set_transform(centre,-0.12+sin(t*1.3)*0.035)
	var parchment := PackedVector2Array([Vector2(-11,-11),Vector2(7,-11),Vector2(12,-6),Vector2(12,10),Vector2(-11,10)])
	draw_colored_polygon(parchment,Color("e7d3a5"))
	var edge := parchment.duplicate()
	edge.append(parchment[0])
	draw_polyline(edge,INK,2,true)
	draw_line(Vector2(7,-11),Vector2(7,-6),Color("96764b"),1,true)
	draw_line(Vector2(7,-6),Vector2(12,-6),Color("96764b"),1,true)
	for i in 3: draw_line(Vector2(-7,-5+i*5),Vector2(5,-5+i*5),Color("9d8155"),1,true)
	draw_line(Vector2(5,4),Vector2(12,13),INK,6,true)
	draw_line(Vector2(5,4),Vector2(12,13),GOLD,3,true)
	draw_circle(Vector2(0,-2),8,INK,true,-1,true)
	draw_circle(Vector2(0,-2),6,Color("9dc8b9"),true,-1,true)
	draw_arc(Vector2(0,-2),6,PI*1.05,PI*1.7,16,Color("eaffef"),1.5,true)
	draw_circle(Vector2(-2,-4),1.5,Color("eaffef"),true,-1,true)
	draw_set_transform(Vector2.ZERO)
	for i in 6:
		var phase := fmod(t*0.28+i/6.0,1.0)
		var angle := i*2.4+t*0.55
		var at := Vector2(cos(angle)*(14+phase*8),7-phase*43)
		var alpha := sin(phase*PI)*0.75
		draw_circle(at,2.5,Color(GLOW,alpha*0.12),true,-1,true)
		draw_circle(at,0.9,Color(GOLD,alpha),true,-1,true)
