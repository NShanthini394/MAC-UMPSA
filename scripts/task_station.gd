extends Node2D
## Small diegetic station symbols; the unchanged floor plan controls collisions.
var task_index := 0
const INK := Color("493824")
const CREAM := Color("f5deb0")

func _draw() -> void:
	draw_ellipse(Vector2(0,3),22,7,Color(0.12,0.08,0.03,0.25))
	match task_index:
		0:
			draw_rect(Rect2(-15,-16,30,19),Color("5f6962"))
			draw_arc(Vector2(0,-16),15,PI,TAU,16,CREAM,3,true)
			draw_line(Vector2(-20,-9),Vector2(20,-9),INK,3)
		1:
			for i in 3: draw_line(Vector2(-17+i*3,-12+i*5),Vector2(15+i*2,-15+i*5),Color("7b4f2c"),6,true)
		2:
			draw_line(Vector2(12,-32),Vector2(-7,-4),INK,4,true)
			for i in 7: draw_line(Vector2(-12+i*2,-10),Vector2(-22+i*5,4),Color("dec181"),2,true)
		3:
			draw_line(Vector2(-24,-25),Vector2(24,-25),INK,3)
			draw_line(Vector2(-23,-30),Vector2(-23,3),INK,3)
			draw_line(Vector2(23,-30),Vector2(23,3),INK,3)
			draw_rect(Rect2(-16,-23,13,20),Color("ce755c"))
			draw_rect(Rect2(4,-23,13,20),Color("e6d09e"))
		4:
			for i in 5: draw_circle(Vector2.from_angle(i*TAU/5)*7+Vector2(0,-12),6,CREAM)
			draw_circle(Vector2(0,-12),4,Color("d7a342"))
			draw_line(Vector2(0,-9),Vector2(0,5),Color("647f42"),3)
		5:
			draw_arc(Vector2(0,-5),20,0,TAU,24,CREAM,2,true)
			for i in 3: draw_circle(Vector2(-9+i*8,-4+i%2*6),4,Color("6b9c9c"))
		6:
			draw_line(Vector2(0,3),Vector2(0,-33),INK,4)
			draw_line(Vector2(0,-30),Vector2(16,-30),INK,4)
			draw_circle(Vector2(16,-23),8,Color("ead49c"))
			draw_arc(Vector2(16,-23),9,0,TAU,16,INK,2,true)
		7:
			for x in [-10,7]:
				draw_ellipse(Vector2(x,-8),6,13,Color("ad6748"))
				draw_line(Vector2(x-4,-13),Vector2(x,-5),CREAM,2)
				draw_line(Vector2(x+4,-13),Vector2(x,-5),CREAM,2)

		8:
			draw_rect(Rect2(-16,-18,32,21),Color("827769"))
			draw_line(Vector2(5,-14),Vector2(18,-35),CREAM,6,true)
		9:
			draw_rect(Rect2(-13,-18,26,21),Color("739fa9"))
			draw_line(Vector2(12,-14),Vector2(26,-26),Color("739fa9"),5,true)
		10:
			draw_rect(Rect2(-20,-26,40,29),Color("b9b36d"))
			for i in 4: draw_line(Vector2(-18,-22+i*7),Vector2(18,-22+i*7),INK,2,true)
		11:
			for i in 5:
				draw_line(Vector2(-20+i*10,-30),Vector2(-20+i*10,0),CREAM,1,true)
				draw_line(Vector2(-20,-30+i*7),Vector2(20,-30+i*7),CREAM,1,true)
