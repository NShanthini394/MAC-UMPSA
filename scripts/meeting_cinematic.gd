extends Control
## Shared timed presentation; the server owns every phase and the final outcome.
const Data = preload("res://scripts/game_data.gd")
const Actor = preload("res://scripts/character_actor.gd")
var kind := "alarm"
var details: Dictionary = {}
var elapsed := 0.0
var artwork: TextureRect
var actor: Control
var disguise: TextureRect
var headline: Label
var caption: Label
var frame := -1
var duration := 3.2
var magic: Node2D
var alarm_sweep: Polygon2D

func configure(mode: String, reveal: Dictionary = {}) -> void:
	kind = mode; details = reveal
	duration = 3.2 if kind == "alarm" else 7.0
	name = "MeetingCinematic"
	position = Vector2.ZERO; size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.035,0.015,0.015,0.94)
	shade.position = Vector2(-1000,-600); shade.size = Vector2(3280,1920)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP; add_child(shade)
	artwork = TextureRect.new(); artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(artwork)
	headline = label("", Rect2(120,520,1040,74), 34, Data.GOLD)
	caption = label("", Rect2(170,602,940,70), 23, Data.CREAM)
	if kind == "alarm":
		# The source is a storyboard rather than a uniformly padded sprite atlas.
		# Use the two clean strike poses, then animate the sweep and title ourselves.
		alarm_sweep = Polygon2D.new()
		alarm_sweep.polygon = PackedVector2Array([Vector2(-660,-45),Vector2(-440,-95),Vector2(-500,-55),Vector2(-160,-115),Vector2(220,-90),Vector2(650,-55),Vector2(480,0),Vector2(670,60),Vector2(280,88),Vector2(380,110),Vector2(-260,90),Vector2(-660,50),Vector2(-490,0)])
		alarm_sweep.color = Color("bd160d"); alarm_sweep.position=Vector2(640,395)
		add_child(alarm_sweep); move_child(alarm_sweep,1)
		artwork.position = Vector2(320,105); artwork.size = Vector2(640,320)
		headline.position = Vector2(100,370); headline.size=Vector2(1080,110)
		headline.add_theme_font_size_override("font_size",52)
		headline.add_theme_constant_override("outline_size",14)
		headline.add_theme_color_override("font_outline_color",Color("1c0604"))
		headline.add_theme_color_override("font_color",Color("fff7df"))
		headline.text = "EMERGENCY MEETING"
		caption.text = "The gong has sounded. Gather and share your clues."
	else:
		# The departure scene supplies the torch-lit setting. The actual voted
		# character is rendered separately, with their real name overlaid below.
		artwork.texture = load("res://assets/meetings/departure_background.png")
		artwork.position = Vector2(230,40); artwork.size = Vector2(820,461)
		artwork.modulate = Color(0.85,0.85,0.90)
		magic = Node2D.new(); add_child(magic)
		magic.draw.connect(func(): _draw_magic(magic))
		if int(details.get("id", -1)) >= 0:
			actor = Actor.new(); add_child(actor)
			actor.configure(str(details.get("character", "Orang Kampung Lelaki")), "")
			actor.position = Vector2(512,180); actor.scale = Vector2.ONE * 3.2
			actor.get_node("PlayerName").hide()
			disguise = TextureRect.new(); disguise.name = "RevealedNenek"
			disguise.texture = load("res://assets/meetings/nenek_reveal.png")
			disguise.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			disguise.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			disguise.position = Vector2(440,110); disguise.size = Vector2(400,350)
			disguise.modulate.a = 0.0; add_child(disguise)
			headline.text = "The village has made its choice…"
		else:
			headline.text = "NO ONE WAS ELIMINATED"
			caption.text = "The vote was tied or skipped. The investigation continues."

func atlas(path: String, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new(); texture.atlas = load(path); texture.region = region
	return texture

func label(text: String, rect: Rect2, font_size: int, colour: Color) -> Label:
	var result := Label.new(); result.text = text; result.position = rect.position; result.size = rect.size
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color",colour)
	result.add_theme_color_override("font_shadow_color",Color.BLACK)
	result.add_theme_constant_override("shadow_offset_y",3)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(result)
	return result

func _process(delta: float) -> void:
	elapsed += delta
	if kind == "alarm":
		var next := 0 if elapsed < 0.35 else 1
		if next != frame:
			frame = next
			artwork.texture = atlas("res://assets/meetings/emergency_meeting.png",Rect2(110,0,330,181) if frame==0 else Rect2(650,0,375,181))
		alarm_sweep.scale.x = clampf((elapsed-0.35)/0.45,0.0,1.0)
		artwork.position.x=320.0+(sin(elapsed*65.0)*4.0 if elapsed>0.35 and elapsed<0.8 else 0.0)
		headline.modulate.a=clampf((elapsed-0.6)/0.3,0.0,1.0)
		return
	if actor == null: return
	var correct := bool(details.get("was_nenek", false))
	if correct:
		var glow := clampf((elapsed-1.0)/1.7,0.0,1.0)
		actor.modulate.a = 1.0-glow
		disguise.modulate.a = glow
		if elapsed > 2.8: headline.text = str(details["name"]) + " was Nenek Kebayan!"
	else:
		actor.rotation = 0.10
		actor.modulate = Color(0.72,0.77,0.88)
		var leaving := clampf((elapsed-1.2)/3.3,0.0,1.0)
		actor.set_facing_direction(Vector2.UP if elapsed > 1.2 else Vector2.DOWN)
		actor.set_running(elapsed > 1.2)
		actor.position = Vector2(512,180).lerp(Vector2(626,140),leaving)
		actor.scale = Vector2.ONE * lerpf(3.2,0.5,leaving)
		actor.modulate.a = 1.0 - maxf(0.0,(leaving-0.7)/0.3)
		if elapsed > 2.2: headline.text = str(details["name"]) + " was not Nenek Kebayan."
	if elapsed > 4.5:
		var remaining := int(details.get("remaining",2))
		if remaining == 0:
			caption.text = "Both Nenek Kebayan have been found!" + ("\nAll tasks are complete. The village is saved." if details.get("tasks_complete",false) else "\nComplete the remaining tasks to save the village.")
		elif remaining == 1: caption.text = "One Nenek Kebayan is still among you…"
		else: caption.text = "Two Nenek Kebayan are still among you…"
	if magic: magic.queue_redraw()

func _draw_magic(canvas: CanvasItem) -> void:
	if kind != "reveal" or not details.get("was_nenek",false) or elapsed < 0.7 or elapsed > 4.0: return
	var intensity := sin(clampf((elapsed-0.7)/3.3,0.0,1.0)*PI)
	var centre := Vector2(640,300)
	for i in 5:
		canvas.draw_arc(centre,75+i*24+sin(elapsed*5+i)*8,elapsed+i,elapsed+i+TAU*0.85,64,Color(1.0,0.25+0.12*i,0.1,intensity*0.65),3.0,true)
	for i in 32:
		var angle := i*TAU/32.0+elapsed
		var radius := 75.0+fmod(i*19.0+elapsed*85.0,145.0)
		canvas.draw_circle(centre+Vector2.from_angle(angle)*radius,2.0+i%3,Color(1.0,0.65,0.15,intensity),true,-1,true)
