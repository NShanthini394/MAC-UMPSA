extends Control
## Lightweight 3D cutaways of all three authoritative floor plans.
## This is a map viewer only; it never changes gameplay bodies or collisions.
signal task_selected(index: int)
const Geometry = preload("res://scripts/map_geometry.gd")
const UNIT := 0.01
const ROOM_COLOURS := [Color("5d9a9b"), Color("8fb4ad"), Color("889cb6"), Color("a3bcb3"), Color("7c9eaa"), Color("afc5ad"), Color("7bb5ad"), Color("569b79"), Color("559887")]
var app: Control
var zoom := 1.0
var pan := Vector2.ZERO
var selected := -1
var yaw := -22.0
var pitch := 48.0
var viewport_3d: SubViewport
var world: Node3D
var camera: Camera3D
var _overlay: Control
var _plan: RefCounted
var _materials: Dictionary = {}
var _marker_points: Array[Vector2] = []
var _pressed := false
var _dragged := false
var _press_at := Vector2.ZERO
var _touch_id := -1
var _refresh_after := 0.0
var _bounds := Rect2(48,62,1910,590)


func configure(controller: Control) -> void:
	app = controller
	_plan = Geometry.floor_plan(app.selected_map)
	if app.selected_map != 0: _bounds = Rect2(60,100,1348,950)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	var surface := SubViewportContainer.new()
	surface.name = "PalaceMapSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.stretch = true
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	viewport_3d = SubViewport.new()
	viewport_3d.name = "PalaceMapViewport"
	viewport_3d.own_world_3d = true
	viewport_3d.handle_input_locally = false
	viewport_3d.gui_disable_input = true
	viewport_3d.msaa_3d = Viewport.MSAA_2X
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	surface.add_child(viewport_3d)
	world = Node3D.new(); world.name = "PalaceCutaway"
	viewport_3d.add_child(world)
	_build_lighting()
	_build_map()
	_overlay = Control.new()
	_overlay.name = "PalaceMapMarkers"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_overlay.draw.connect(_draw_markers)
	resized.connect(_fit_camera)
	_fit_camera()


func _material(colour: Color) -> StandardMaterial3D:
	var key := colour.to_html()
	if _materials.has(key): return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.88
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


func _point(source: Vector2, height: float = 0.0) -> Vector3:
	var centre: Vector2 = _plan.layout["design_size"] * 0.5
	return Vector3((source.x-centre.x)*UNIT, height, (source.y-centre.y)*UNIT)


func _box(node_name: String, rect: Rect2, height: float, colour: Color, bottom: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(rect.size.x*UNIT, height, rect.size.y*UNIT)
	var instance := MeshInstance3D.new()
	instance.name = node_name; instance.mesh = mesh
	instance.position = _point(rect.get_center(),bottom+height*0.5)
	instance.material_override = _material(colour)
	world.add_child(instance)
	return instance


func _disc(node_name: String, source: Vector2, radius: float, height: float, colour: Color, bottom: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius; mesh.bottom_radius = radius
	mesh.height = height; mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.name = node_name; instance.mesh = mesh
	instance.position = _point(source,bottom+height*0.5)
	instance.material_override = _material(colour)
	world.add_child(instance)
	return instance


func _floor(node_name: String, polygon: PackedVector2Array, colour: Color, top: float, depth: float) -> void:
	var indices := Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty(): return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		surface.set_normal(Vector3.UP)
		surface.set_color(colour)
		surface.add_vertex(_point(polygon[index], top))
	for index in polygon.size():
		var a := _point(polygon[index], top)
		var b := _point(polygon[(index+1)%polygon.size()], top)
		var normal := (b-a).cross(Vector3.UP).normalized()
		for vertex in [a,b,b-Vector3.UP*depth,a,b-Vector3.UP*depth,a-Vector3.UP*depth]:
			surface.set_normal(normal)
			surface.set_color(colour.darkened(0.28))
			surface.add_vertex(vertex)
	var material := _material(Color.WHITE).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = true
	var instance := MeshInstance3D.new()
	instance.name = node_name; instance.mesh = surface.commit()
	instance.material_override = material
	world.add_child(instance)


func _build_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("102b37")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bce5e1")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var settings := WorldEnvironment.new(); settings.environment = environment
	world.add_child(settings)
	var light := DirectionalLight3D.new()
	light.name = "PalaceMapSun"
	light.rotation_degrees = Vector3(-55,-28,0)
	light.light_color = Color("fff0cf"); light.light_energy = 0.95
	# Static, simple meshes keep this small map inexpensive on Android.
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 45.0
	world.add_child(light)
	camera = Camera3D.new(); camera.name = "PalaceMapCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.1; camera.far = 70.0
	world.add_child(camera); camera.current = true


func _build_map() -> void:
	if app.selected_map != 0:
		_build_house_foundation()
		_build_floor_plan()
		_build_house_details()
		return
	_box("IslandFoundation",Rect2(48,62,1910,590),0.28,Color("28575f"),-0.44)
	_box("Moat",Rect2(405,76,1125,530),0.07,Color("2c788c"),-0.13)
	_box("WestGardenGround",Rect2(72,159,335,397),0.07,Color("387a61"),-0.1)
	_box("EastGardenGround",Rect2(1548,125,310,464),0.07,Color("3b826c"),-0.1)
	_build_floor_plan()
	_build_details()


func _build_floor_plan() -> void:
	for index in _plan.floors.size():
		_floor("WalkableFloor_%d"%index,_plan.floors[index],Color("c7d9c9"),0.06,0.17)
	for index in _plan.layout["sections"].size():
		var section: Dictionary = _plan.layout["sections"][index]
		for zone in section["zones"]:
			var rect: Rect2 = zone
			var region := PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
			for polygon in _plan.floors:
				for piece in Geometry2D.intersect_polygons(region,polygon):
					_floor("RoomFloor_%d"%index,piece,ROOM_COLOURS[index%ROOM_COLOURS.size()],0.075,0.05)
	# Every wall follows the boundary of the merged gameplay floors. Shared
	# door seams are already removed, so entrances stay visibly open.
	for index in _plan.source_edges.size():
		var edge: PackedVector2Array = _plan.source_edges[index]
		var middle := (edge[0]+edge[1])*0.5
		if not _has_wall(middle): continue
		var length := edge[0].distance_to(edge[1])*UNIT
		if length<0.02: continue
		var wall := _box("CutawayWall_%d"%index,Rect2(middle-Vector2(4,4),Vector2(8,8)),0.52,Color("d2dccb"),0.08)
		wall.mesh = BoxMesh.new(); wall.mesh.size = Vector3(length,0.52,0.06)
		wall.rotation.y = -atan2(edge[1].y-edge[0].y,edge[1].x-edge[0].x)
		var cap := MeshInstance3D.new(); cap.mesh = BoxMesh.new()
		cap.mesh.size = Vector3(length+0.02,0.045,0.09)
		cap.position.y=0.28; cap.material_override=_material(Color("c5a85f"))
		wall.add_child(cap)
	for index in _plan.layout["solids"].size():
		_box("Furniture_%d"%index,_plan.layout["solids"][index],0.20,Color("647c7b"),0.08)
	for index in _plan.layout["doors"].size():
		var rect: Rect2 = _plan.layout["doors"][index]["rect"]
		var along := Vector2.DOWN if rect.size.y>rect.size.x else Vector2.RIGHT
		var half := maxf(rect.size.x,rect.size.y)*0.5
		for side in [-1,1]:
			var at: Vector2=rect.get_center()+along*(half+3)*side
			_box("DoorPost_%d_%d"%[index,side],Rect2(at-Vector2(5,5),Vector2(10,10)),0.43,Color("e5c67c"),0.08)
		_box("DoorThreshold_%d"%index,rect,0.025,Color("f0dca2"),0.09)


func _build_details() -> void:
	# Ruby carpet, purple throne and warm gold distinguish the royal hall.
	_box("ThroneCarpet",Rect2(848,158,183,119),0.025,Color("863956"),0.09)
	_box("ThroneDais",Rect2(900,104,82,48),0.16,Color("c4af77"),0.09)
	_box("ThroneSeat",Rect2(919,114,43,33),0.24,Color("74538a"),0.25)
	_box("ThroneBack",Rect2(919,108,43,9),0.7,Color("b79551"),0.25)
	for at in [Vector2(807,108),Vector2(1071,108),Vector2(807,290),Vector2(1071,290)]:
		_disc("RoyalPillar",at,0.055,0.88,Color("e2c374"),0.08)
	for at in [Vector2(1695,202),Vector2(1750,483),Vector2(103,264),Vector2(311,222),Vector2(191,520),Vector2(1818,163)]:
		_disc("GardenTrunk",at,0.035,0.20,Color("6c7560"),0.07)
		_disc("GardenCanopy",at,0.15,0.22,Color("548b68"),0.22)
	_disc("WestPondBorder",Vector2(238,458),0.64,0.055,Color("87b5a4"),-0.05)
	_disc("WestPond",Vector2(238,458),0.56,0.06,Color("2d8093"),-0.01)
	_disc("EastFountainBasin",Vector2(1712,348),0.43,0.13,Color("c1d4c9"),-0.02)
	_disc("EastFountainWater",Vector2(1712,348),0.36,0.025,Color("539faf"),0.115)
	_disc("EastFountainColumn",Vector2(1712,348),0.065,0.43,Color("d5ded1"),0.13)
	_disc("EastFountainBowl",Vector2(1712,348),0.20,0.07,Color("b5cbbf"),0.45)
	# The gong is a real disc on a stand, placed at the gameplay gong location.
	var gong: Vector2=Geometry.gong_point(app.selected_map)/_plan.scale
	for side in [-1,1]: _box("GongStand",Rect2(gong+Vector2(side*28-4,-4),Vector2(8,8)),0.62,Color("c6a258"),0.09)
	var disc := _disc("CentralGong",gong,0.21,0.045,Color("e2b65c"),0.48)
	disc.rotation_degrees.x=90


func _fit_camera() -> void:
	if not is_instance_valid(camera): return
	var azimuth := deg_to_rad(yaw)
	var elevation := deg_to_rad(pitch)
	camera.position=Vector3(sin(azimuth)*cos(elevation),sin(elevation),cos(azimuth)*cos(elevation))*32
	camera.look_at(Vector3.ZERO,Vector3.UP)
	var extent := Vector2.ZERO
	var inverse := camera.global_transform.affine_inverse()
	for x in [_bounds.position.x,_bounds.end.x]:
		for y in [_bounds.position.y,_bounds.end.y]:
			for height in [-0.44,1.2]:
				var local: Vector3=inverse*_point(Vector2(x,y),height)
				extent=extent.max(Vector2(absf(local.x),absf(local.y)))
	var aspect := size.x/maxf(size.y,1.0)
	camera.size=maxf(extent.y,extent.x/aspect)*2.18/zoom
	_refresh()


func reset_view() -> void:
	zoom=1.0; pan=Vector2.ZERO; yaw=-22.0; pitch=48.0
	_fit_camera()


func change_zoom(factor: float) -> void:
	zoom=clampf(zoom*factor,0.75,3.0)
	_fit_camera()


func source_to_screen(source: Vector2) -> Vector2:
	return camera.unproject_position(_point(source,0.5))


func world_to_screen(point: Vector2) -> Vector2:
	return source_to_screen(point/_plan.scale)


func task_marker_position(index: int) -> Vector2:
	return _marker_points[index] if index<_marker_points.size() else world_to_screen(Geometry.task_points(app.selected_map)[index])


func _process(delta: float) -> void:
	_refresh_after-=delta
	if _refresh_after<=0.0:
		_refresh_after=0.15
		_refresh()


func _refresh() -> void:
	if not is_instance_valid(_overlay): return
	_marker_points.clear()
	var player: Vector2=app.player_body.global_position if is_instance_valid(app.player_body) else app.player_position
	var player_at := world_to_screen(player)
	if not app.player_is_impostor:
		for point in Geometry.task_points(app.selected_map):
			var at := world_to_screen(point)
			for offset in [Vector2.ZERO,Vector2(28,0),Vector2(-28,0),Vector2(0,-28),Vector2(0,28),Vector2(0,-48),Vector2(0,48)]:
				if player_at.distance_to(at+offset)>=36 and not _marker_points.any(func(other: Vector2)->bool:return other.distance_to(at+offset)<28):
					at+=offset; break
			_marker_points.append(at)
	_overlay.queue_redraw()
	viewport_3d.render_target_update_mode=SubViewport.UPDATE_ONCE


func _text(copy: String, at: Vector2, font_size: int, colour: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(copy,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	_overlay.draw_string(font,at-Vector2(width*0.5,0),copy,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,colour)


func _draw_markers() -> void:
	if not is_instance_valid(app) or not is_instance_valid(camera): return
	var occupied: Array[Rect2]=[]
	for at in _marker_points: occupied.append(Rect2(at-Vector2(17,17),Vector2(34,34)))
	var player: Vector2=app.player_body.global_position if is_instance_valid(app.player_body) else app.player_position
	var player_at := world_to_screen(player)
	occupied.append(Rect2(player_at-Vector2(20,20),Vector2(40,40)))
	for section in _plan.layout["sections"]:
		var rect: Rect2=section["zones"][0]
		var copy: String=preload("res://scripts/app_language.gd").text(section["name"])
		if copy.length()>12: copy=copy.replace(" and "," & ")
		if copy.contains(" "): copy=copy.replace(" ","\n")
		var lines := copy.split("\n")
		var label_size := Vector2(0,lines.size()*18+8)
		for line in lines: label_size.x=maxf(label_size.x,ThemeDB.fallback_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+16)
		var original := source_to_screen(rect.get_center())
		var at := original
		var label_offsets: Array[Vector2]=[Vector2.ZERO]
		for radius in [32.0,48.0,64.0,88.0,116.0,148.0]:
			for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2(-0.7,-0.7),Vector2(0.7,-0.7),Vector2(-0.7,0.7),Vector2(0.7,0.7)]: label_offsets.append(direction*radius)
		for offset in label_offsets:
			var candidate: Vector2=(original+offset).clamp(label_size*0.5+Vector2(4,4),size-label_size*0.5-Vector2(4,4))
			var bounds := Rect2(candidate-label_size*0.5,label_size)
			if not occupied.any(func(other: Rect2)->bool:return bounds.grow(3).intersects(other)):
				at=candidate; break
		occupied.append(Rect2(at-label_size*0.5,label_size))
		if at.distance_to(original)>20: _overlay.draw_line(original,at,Color("c2dfd6",0.65),1,true)
		var style := StyleBoxFlat.new()
		style.bg_color=Color("103a42",0.94);style.border_color=Color("94beb3",0.7)
		style.set_border_width_all(1);style.set_corner_radius_all(5)
		_overlay.draw_style_box(style,Rect2(at-label_size*0.5,label_size))
		for index in lines.size(): _text(lines[index],at+Vector2(0,(index-(lines.size()-1)*0.5)*18+5),15,Color("e9f1da"))
	for index in _marker_points.size():
		var at := _marker_points[index]
		var original := world_to_screen(Geometry.task_points(app.selected_map)[index])
		if at.distance_to(original)>4: _overlay.draw_line(original,at,Color("ffe6a9",0.8),1.5,true)
		var complete: bool=index<app.completed_tasks.size() and app.completed_tasks[index]==1
		if index==selected: _overlay.draw_circle(at,20,Color("ffdb78"))
		_overlay.draw_circle(at,14,Color("377c69") if complete else Color("b57537"))
		_overlay.draw_arc(at,14,0,TAU,32,Color("fff0ca"),1.5,true)
		_text("✓" if complete else str(index+1),at+Vector2(0,5),16,Color("fff9e8"))
	_overlay.draw_circle(player_at,19,Color("081b26",0.8))
	var arrow := PackedVector2Array([player_at+Vector2(0,-15),player_at+Vector2(11,11),player_at+Vector2(0,6),player_at+Vector2(-11,11),player_at+Vector2(0,-15)])
	_overlay.draw_colored_polygon(arrow,Color("f5ca66"))
	_overlay.draw_polyline(arrow,Color("fff8de"),2,true)
	_text("3D",Vector2(29,30),18,Color("beded5"))
	_text("N",Vector2(size.x-28,29),16,Color("beded5"))
	var north := (source_to_screen(Vector2(_plan.layout.design_size.x*0.5,240))-source_to_screen(Vector2(_plan.layout.design_size.x*0.5,340))).normalized()
	var centre := Vector2(size.x-28,59)
	_overlay.draw_line(centre-north*14,centre+north*14,Color("beded5"),2,true)
	_overlay.draw_colored_polygon(PackedVector2Array([centre+north*18,centre+north*6+north.orthogonal()*5,centre+north*6-north.orthogonal()*5]),Color("beded5"))


func _start(at: Vector2) -> void:
	_pressed=true;_dragged=false;_press_at=at


func _move(at: Vector2, relative: Vector2) -> void:
	if not _pressed: return
	if _press_at.distance_to(at)>5: _dragged=true
	if _dragged:
		yaw=clampf(yaw-relative.x*0.15,-55,55)
		pitch=clampf(pitch+relative.y*0.12,32,72)
		_fit_camera()


func _finish(at: Vector2) -> void:
	if _pressed and not _dragged and not app.player_is_impostor:
		var closest := -1
		var distance := 23.0
		for index in _marker_points.size():
			if at.distance_to(_marker_points[index])<distance:
				closest=index; distance=at.distance_to(_marker_points[index])
		if closest>=0: task_selected.emit(closest)
	_pressed=false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: change_zoom(1.2)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: change_zoom(1/1.2)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: _start(event.position)
			else: _finish(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _pressed: _move(event.position,event.relative);accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_id<0: _touch_id=event.index;_start(event.position)
		elif not event.pressed and event.index==_touch_id: _finish(event.position);_touch_id=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==_touch_id: _move(event.position,event.relative);accept_event()


func _has_wall(point: Vector2) -> bool:
	if app.selected_map == 0: return point.x >= 450 and point.x <= 1425 and point.y <= 454
	for section in _plan.layout.sections:
		if section.name not in ["Bedroom", "Kitchen", "Living Room", "Family Room", "Dining Room", "Veranda"]: continue
		for zone in section.zones:
			if zone.grow(3).has_point(point): return true
	return false

func _build_house_foundation() -> void:
	var coastal: bool = app.selected_map == 2
	_box("HouseIslandFoundation", _bounds, 0.28, Color("366969") if coastal else Color("46664c"), -0.44)
	if coastal:
		_box("CoastalWater", _bounds.grow(-12), 0.06, Color("2c788c"), -0.14)
		_box("CoastalSand", Rect2(280,180,1000,720), 0.05, Color("c3c49b"), -0.07)
	else:
		_box("HomesteadLawn", _bounds.grow(-12), 0.06, Color("6d9a70"), -0.14)
		_box("VegetableGarden", Rect2(120,450,170,280), 0.04, Color("52835c"), -0.06)
		for x in [145,185,225,265]: _box("VegetableRow",Rect2(x,470,12,240),0.04,Color("83b17b"),-0.02)

func _build_house_details() -> void:
	var coastal: bool = app.selected_map == 2
	var wood := Color("8b8d72")
	for section in _plan.layout.sections:
		var room: Rect2 = section.zones[0]
		if section.name == "Bedroom":
			var at: Vector2 = room.position+Vector2(60,70)
			_box("BedroomBed",Rect2(at-Vector2(28,42),Vector2(56,84)),0.18,Color("738da5"),0.09)
			_box("BedroomPillow",Rect2(at-Vector2(23,36),Vector2(46,20)),0.04,Color("dbe4cd"),0.27)
		elif section.name in ["Dining Room", "Family Room", "Living Room"]:
			var at: Vector2 = room.get_center()
			_box("RoomTable",Rect2(at-Vector2(36,22),Vector2(72,44)),0.23,wood,0.09)
			for side in [-1,1]: _box("RoomChair",Rect2(at+Vector2(side*52-10,-10),Vector2(20,20)),0.12,Color("648579"),0.09)
		elif section.name == "Kitchen":
			_box("KitchenHearth",Rect2(room.end-Vector2(50,75),Vector2(36,60)),0.24,Color("87958b"),0.09)
			_disc("CookingPot",room.end-Vector2(32,44),0.10,0.09,Color("4e6767"),0.33)
	if coastal:
		for pier in [Rect2(1250,287,122,59),Rect2(1254,485,134,74)]:
			_box("WoodenPier",pier,0.07,wood,0.02)
			for side in [-1,1]: _disc("PierPost",pier.get_center()+Vector2(side*pier.size.x*0.42,0),0.035,0.30,Color("d1be84"),0.09)
		for at in [Vector2(330,220),Vector2(1180,200),Vector2(1170,850)]: _house_tree(at,true)
	else:
		_disc("WellRim",Vector2(1255,602),0.43,0.30,Color("a6b7a3"),0.0)
		_disc("WellWater",Vector2(1255,602),0.32,0.01,Color("2f788a"),0.305)
		_box("ChickenCoop",Rect2(130,290,90,40),0.40,Color("83a188"),0.07)
		for at in [Vector2(300,200),Vector2(1070,180),Vector2(1200,780)]: _house_tree(at,false)
	var gong: Vector2 = Geometry.gong_point(app.selected_map)/_plan.scale
	for side in [-1,1]: _box("GongStand",Rect2(gong+Vector2(side*28-4,-4),Vector2(8,8)),0.62,Color("c6a258"),0.09)
	var disc := _disc("CentralGong",gong,0.21,0.045,Color("e2b65c"),0.48)
	disc.rotation_degrees.x = 90

func _house_tree(at: Vector2, palm: bool) -> void:
	_disc("GardenTrunk",at,0.035,0.4,Color("8e9673"),0.04)
	_disc("GardenCanopy",at,0.22 if palm else 0.18,0.12 if palm else 0.26,Color("61a37a"),0.4)
