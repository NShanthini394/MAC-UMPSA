extends SubViewportContainer
## 3D presentation for the Istana map. The existing 2D gameplay bodies remain
## authoritative for movement and collisions; their positions drive billboards.

const MapGeometry = preload("res://scripts/map_geometry.gd")
const WORLD_SIZE := Vector2(2025.0, 720.0)
const WORLD_SCALE := 0.01

var _viewport: SubViewport
var _world_3d: Node3D
var _camera: Camera3D
var _source_world: Node2D
var _local_player: CharacterBody2D
var _actor_visuals: Array[Dictionary] = []
var _player_light: OmniLight3D


func configure(source_world: Node2D, local_player: CharacterBody2D) -> void:
	_source_world = source_world
	_local_player = local_player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_viewport = SubViewport.new()
	_viewport.name = "Istana3DViewport"
	_viewport.size = Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	add_child(_viewport)

	_world_3d = Node3D.new()
	_world_3d.name = "Istana3DWorld"
	_viewport.add_child(_world_3d)
	_build_environment()
	_build_ground()
	_build_obstacles()
	_build_architecture_details()
	_build_trees()
	_build_world_markers()
	_build_character_visuals()
	_source_world.hide()


func _process(delta: float) -> void:
	if not is_instance_valid(_camera):
		return
	# Keep the full Istana plan in view while the layout is being reviewed.
	# The camera can return to a player-follow shot after the map is approved.
	var overview_target := Vector3.ZERO
	var overview_position := Vector3(0.0, 11.5, 4.0)
	_camera.global_position = _camera.global_position.lerp(overview_position, 1.0 - exp(-3.0 * delta))
	_camera.look_at(overview_target, Vector3.UP)
	if is_instance_valid(_player_light) and is_instance_valid(_local_player):
		_player_light.global_position = _map_to_3d(_local_player.global_position) + Vector3(0.0, 1.1, 0.0)
	for visual_data in _actor_visuals:
		var actor: Node2D = visual_data["actor"]
		var visual: Sprite3D = visual_data["sprite"]
		var name_label: Label3D = visual_data["name_label"]
		if not is_instance_valid(actor) or not is_instance_valid(visual) or not is_instance_valid(name_label):
			continue
		var actor_world_position := _map_to_3d(actor.global_position)
		visual.global_position = actor_world_position + Vector3(0.0, 0.36, 0.0)
		name_label.global_position = actor_world_position + Vector3(0.0, 0.88, 0.0)
		visual.visible = actor.visible
		var source_sprite: CanvasItem = visual_data["source_sprite"]
		if is_instance_valid(source_sprite):
			var texture: Texture2D
			var flip_h := false
			if source_sprite is TextureRect:
				texture = (source_sprite as TextureRect).texture
				flip_h = (source_sprite as TextureRect).scale.x < 0.0
			elif source_sprite is Sprite2D:
				texture = (source_sprite as Sprite2D).texture
				flip_h = (source_sprite as Sprite2D).flip_h
			if visual.texture != texture:
				_apply_actor_texture(visual, texture)
			visual.flip_h = flip_h


func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("1a252d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e2d6b7")
	environment.ambient_light_energy = 0.78
	environment_node.environment = environment
	_world_3d.add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "WarmSunlight"
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_color = Color("ffe2a6")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	_world_3d.add_child(sun)

	_camera = Camera3D.new()
	_camera.name = "FollowCamera3D"
	_camera.fov = 48.0
	_camera.near = 0.05
	_camera.far = 45.0
	_camera.position = Vector3(0.0, 6.8, 1.8)
	_world_3d.add_child(_camera)
	_camera.current = true

	_player_light = OmniLight3D.new()
	_player_light.name = "PlayerAreaLight"
	_player_light.light_color = Color("ffdfa0")
	_player_light.light_energy = 0.35
	_player_light.omni_range = 4.5
	_world_3d.add_child(_player_light)


func _build_ground() -> void:
	var half_x := WORLD_SIZE.x * WORLD_SCALE * 0.5
	var half_z := WORLD_SIZE.y * WORLD_SCALE * 0.5
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(half_x * 2.0, half_z * 2.0)
	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "GardenGround"
	ground_mesh.mesh = mesh
	ground_mesh.position.y = -0.015
	ground_mesh.material_override = _make_material(Color("56794d"), 0.98)
	_world_3d.add_child(ground_mesh)

	# Raised foundation and individual tiled sections follow the existing
	# palace plan, including the three wings, Balairung, lobby, and upper suite.
	_add_visual_box("PalaceFoundation", _source_rect_to_map(Rect2(280, 112, 768, 266)), 0.12, _make_material(Color("665442"), 0.92), 0.0)
	_add_tiled_room("DewanMakanFloor", Rect2(294, 126, 216, 108), Color("b98e67"), Color("c59c73"))
	_add_tiled_room("DapurFloor", Rect2(294, 249, 216, 115), Color("88775f"), Color("988569"))
	_add_tiled_room("BalairungFloor", Rect2(524, 126, 266, 108), Color("bea780"), Color("cbb68c"))
	_add_tiled_room("LobiFloor", Rect2(524, 249, 266, 115), Color("c8ad7e"), Color("d2bb8d"))
	_add_tiled_room("BilikTamuFloor", Rect2(804, 126, 230, 108), Color("a98a68"), Color("b69772"))
	_add_tiled_room("BilikSenjataFloor", Rect2(804, 249, 230, 115), Color("726b5e"), Color("827969"))
	_add_tiled_room("BilikPuteriFloor", Rect2(520, 55, 270, 57), Color("72547f"), Color("80618c"))
	_add_visual_box("EntranceCauseway", _source_rect_to_map(Rect2(602, 365, 106, 128)), 0.08, _make_material(Color("9a8b72"), 0.94), 0.02)
	_add_visual_box("BalairungCarpet", _source_rect_to_map(Rect2(570, 171, 174, 52)), 0.025, _make_material(Color("8e3448"), 0.96), 0.105)
	_add_visual_box("PrincessCarpet", _source_rect_to_map(Rect2(575, 66, 160, 38)), 0.025, _make_material(Color("75488a"), 0.92), 0.105)
	_add_visual_box("WestGardenWalk", _source_rect_to_map(Rect2(18, 85, 232, 330)), 0.045, _make_material(Color("8c8063"), 0.94), 0.008)
	_add_visual_box("EastGardenWalk", _source_rect_to_map(Rect2(1090, 108, 295, 286)), 0.045, _make_material(Color("a49372"), 0.94), 0.008)
	_add_room_furnishings()

	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundCollision3D"
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(half_x * 2.0, 0.04, half_z * 2.0)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.03
	ground_body.add_child(ground_shape)
	_world_3d.add_child(ground_body)


func _add_tiled_room(room_name: String, source_rect: Rect2, first_color: Color, second_color: Color) -> void:
	var map_rect := _source_rect_to_map(source_rect)
	# Keep each chamber as a small number of standard meshes. A generated
	# vertex-color tile mesh can fail on some D3D12 drivers, so tile variation
	# is expressed with shallow, ordinary box meshes instead.
	_add_visual_box(room_name + "Base", map_rect, 0.085, _make_material(first_color.darkened(0.24), 0.96), 0.0425)
	_add_visual_box(room_name, map_rect.grow(-2.5), 0.018, _make_material(first_color, 0.94), 0.094)
	var stripe_material := _make_material(second_color, 0.94)
	var stripe_count := 3
	for stripe_index in stripe_count:
		var stripe_y := map_rect.position.y + map_rect.size.y * float(stripe_index + 1) / float(stripe_count + 1)
		var stripe_rect := Rect2(map_rect.position.x + 3.0, stripe_y, map_rect.size.x - 6.0, 1.4)
		_add_visual_box("%sTileSeam_%d" % [room_name, stripe_index], stripe_rect, 0.006, stripe_material, 0.106)


func _add_room_furnishings() -> void:
	var wood := _make_material(Color("6f492e"), 0.84)
	var dark_wood := _make_material(Color("493326"), 0.88)
	var gold := _make_material(Color("bd914a"), 0.72, 0.04)
	# Dining table and low seats in the west hall.
	_add_furniture_box("DiningTable", Vector2(402, 178), Vector2(74, 36), 0.27, wood)
	for point in [Vector2(365, 155), Vector2(439, 155), Vector2(365, 201), Vector2(439, 201)]:
		_add_furniture_box("DiningSeat", point, Vector2(17, 15), 0.16, dark_wood)
	# Kitchen preparation counters.
	_add_furniture_box("KitchenCounter", Vector2(333, 282), Vector2(50, 20), 0.22, wood)
	_add_furniture_box("KitchenCounter", Vector2(474, 334), Vector2(44, 18), 0.22, wood)
	# Central ceremonial dais and the princess's raised chamber.
	_add_furniture_box("BalairungDais", Vector2(655, 151), Vector2(58, 24), 0.18, gold)
	_add_furniture_box("RoyalThrone", Vector2(655, 143), Vector2(22, 20), 0.34, dark_wood)
	_add_furniture_box("PrincessDais", Vector2(655, 77), Vector2(48, 18), 0.17, gold)
	_add_furniture_box("PrincessSeat", Vector2(655, 71), Vector2(20, 16), 0.31, wood)
	# A bed and weapon racks make the east chambers legible from above.
	_add_furniture_box("GuestBed", Vector2(855, 165), Vector2(45, 61), 0.22, _make_material(Color("79818a"), 0.94))
	_add_furniture_box("WeaponRack", Vector2(965, 279), Vector2(74, 17), 0.24, dark_wood)
	_add_furniture_box("WeaponRack", Vector2(965, 338), Vector2(74, 17), 0.24, dark_wood)


func _add_furniture_box(node_name: String, source_center: Vector2, source_size: Vector2, height: float, material: Material) -> void:
	var map_scale := Vector2(WORLD_SIZE.x / 1420.0, WORLD_SIZE.y / 505.0)
	var map_center := source_center * map_scale
	var size := source_size * map_scale
	_add_visual_box(node_name, Rect2(map_center - size * 0.5, size), height, material, height * 0.5 + 0.09)


func _add_visual_box(node_name: String, map_rect: Rect2, height: float, material: Material, y_center: float) -> void:
	var box_node := MeshInstance3D.new()
	box_node.name = node_name
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(map_rect.size.x * WORLD_SCALE, height, map_rect.size.y * WORLD_SCALE)
	box_node.mesh = box_mesh
	box_node.material_override = material
	var center := _map_to_3d(map_rect.get_center())
	box_node.position = Vector3(center.x, y_center, center.z)
	_world_3d.add_child(box_node)


func _build_obstacles() -> void:
	var walls: Array = []
	var water: Array = []
	var all_obstacles: Array = MapGeometry.obstacles(0)
	for i in all_obstacles.size():
		var obstacle: Rect2 = all_obstacles[i]
		if (i >= 4 and i <= 9) or i == 28 or i == 29:
			water.append(obstacle)
		elif i >= MapGeometry.PALACE_SOURCE_OBSTACLES.size():
			continue
		else:
			walls.append(obstacle)

	var wall_material := _make_material(Color("47443e"), 0.96)
	var cap_material := _make_material(Color("726b5e"), 0.90)
	for index in walls.size():
		var rect: Rect2 = walls[index]
		var height := 0.58 if index >= 4 else 0.28
		var center := rect.get_center()
		var size := Vector2(maxf(rect.size.x, 6.0), maxf(rect.size.y, 6.0)) * WORLD_SCALE
		_add_box("PalaceWall_%02d" % index, center, size, height, wall_material, height * 0.5)
		if index >= 4:
			_add_box("WallCap_%02d" % index, center, size + Vector2(0.035, 0.035), 0.055, cap_material, height + 0.0275)
	for rect in water:
		_add_water_surface(rect)


func _build_architecture_details() -> void:
	var stone := _make_material(Color("dbc79e"), 0.82)
	var gold := _make_material(Color("bd8a3c"), 0.68, 0.08)
	# The main southern entry rises in shallow stone steps toward the palace lobby.
	var source_step_count := 8
	var source_step_span := 70.0
	for i in source_step_count:
		var source_y := 477.0 - (float(i) + 0.5) * source_step_span / float(source_step_count)
		var rise := 0.08 + float(i) * 0.055
		var center := _source_to_world(Vector2(655.0, source_y))
		var step := MeshInstance3D.new()
		step.name = "EntranceStep_%02d" % i
		var box := BoxMesh.new()
		box.size = Vector3(1.02, rise, 0.14)
		step.mesh = box
		step.material_override = stone
		step.position = Vector3(center.x, rise * 0.5, center.z)
		_world_3d.add_child(step)

	# Gold-capped stone columns mark the front gate and principal hall doors.
	for point in [Vector2(595, 385), Vector2(715, 385), Vector2(595, 345), Vector2(715, 345), Vector2(536, 190), Vector2(760, 190)]:
		_add_column(point, stone, gold)

	# A small open pavilion is raised over the west garden's existing platform.
	var pavilion_center := Vector2(155, 105)
	for offset in [Vector2(-0.22, -0.18), Vector2(0.22, -0.18), Vector2(-0.22, 0.18), Vector2(0.22, 0.18)]:
		_add_column(pavilion_center + offset / WORLD_SCALE, stone, gold, 0.54)
	var roof := MeshInstance3D.new()
	roof.name = "GardenPavilionRoof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(0.62, 0.12, 0.52)
	roof.mesh = roof_mesh
	roof.material_override = _make_material(Color("594044"), 0.84)
	roof.position = _source_to_world(pavilion_center)
	roof.position.y = 0.59
	_world_3d.add_child(roof)

	var fountain_center := _source_to_world(Vector2(1199.0, 255.0))
	var fountain_rim := MeshInstance3D.new()
	fountain_rim.name = "GardenFountainRim"
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.31
	rim_mesh.bottom_radius = 0.36
	rim_mesh.height = 0.16
	fountain_rim.mesh = rim_mesh
	fountain_rim.material_override = stone
	fountain_rim.position = Vector3(fountain_center.x, 0.10, fountain_center.z)
	_world_3d.add_child(fountain_rim)
	var fountain_bowl := MeshInstance3D.new()
	fountain_bowl.name = "FountainBasin"
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 0.27
	bowl_mesh.bottom_radius = 0.27
	bowl_mesh.height = 0.025
	fountain_bowl.mesh = bowl_mesh
	fountain_bowl.material_override = _make_material(Color("55b9d0"), 0.26, 0.18)
	fountain_bowl.position = Vector3(fountain_center.x, 0.19, fountain_center.z)
	_world_3d.add_child(fountain_bowl)


func _add_water_surface(rect: Rect2) -> void:
	var water_mesh := PlaneMesh.new()
	water_mesh.size = rect.size * WORLD_SCALE
	var water_material := _make_material(Color("287d8d"), 0.22, 0.12)
	water_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var water := MeshInstance3D.new()
	water.name = "Water_%.0f_%.0f" % [rect.position.x, rect.position.y]
	water.mesh = water_mesh
	water.material_override = water_material
	var center := _map_to_3d(rect.get_center())
	water.position = Vector3(center.x, 0.022, center.z)
	_world_3d.add_child(water)


func _build_trees() -> void:
	# Low-poly trees add height at the garden edges while the original art keeps
	# the detailed foliage and flower beds visible beneath them.
	var tree_points := [
		Vector2(44, 24), Vector2(163, 23), Vector2(220, 26), Vector2(345, 22), Vector2(420, 24),
		Vector2(1105, 25), Vector2(1200, 22), Vector2(1338, 24), Vector2(35, 465), Vector2(145, 467),
		Vector2(1150, 463), Vector2(1280, 466), Vector2(1370, 450), Vector2(190, 95), Vector2(1300, 155)
	]
	var trunk_material := _make_material(Color("60432d"), 0.98)
	var leaf_materials := [
		_make_material(Color("397a39"), 0.96),
		_make_material(Color("4e9146"), 0.96),
		_make_material(Color("6a9b4c"), 0.96)
	]
	for index in tree_points.size():
		var point := _source_to_world(tree_points[index])
		var trunk := MeshInstance3D.new()
		trunk.name = "GardenTreeTrunk_%02d" % index
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.055
		trunk_mesh.bottom_radius = 0.09
		trunk_mesh.height = 0.48
		trunk.mesh = trunk_mesh
		trunk.material_override = trunk_material
		trunk.position = Vector3(point.x, 0.24, point.z)
		_world_3d.add_child(trunk)
		var crown := MeshInstance3D.new()
		crown.name = "GardenTreeCrown_%02d" % index
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 0.31
		crown_mesh.height = 0.46
		crown_mesh.radial_segments = 8
		crown_mesh.rings = 4
		crown.mesh = crown_mesh
		crown.material_override = leaf_materials[index % leaf_materials.size()]
		crown.position = Vector3(point.x, 0.58, point.z)
		_world_3d.add_child(crown)


func _build_world_markers() -> void:
	for child in _source_world.get_children():
		if not child is Label:
			continue
		var label := child as Label
		if not (label.name.begins_with("TaskMarker_") or label.name.begins_with("ClueMarker_") or label.name == "MeetingGongMarker"):
			continue
		var marker := Label3D.new()
		marker.name = "3D_" + label.name
		marker.text = label.text
		marker.font_size = 46
		marker.pixel_size = 0.0028
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.modulate = label.get_theme_color("font_color")
		marker.outline_size = 8
		marker.outline_modulate = Color("241a12")
		var map_position := label.position + label.size * 0.5
		marker.position = _map_to_3d(map_position) + Vector3(0, 0.46, 0)
		_world_3d.add_child(marker)


func _build_character_visuals() -> void:
	for child in _source_world.get_children():
		if child is CharacterBody2D:
			_add_player_billboard(child as CharacterBody2D)
		elif child is Node2D and child.name.begins_with("NPC_"):
			_add_npc_billboard(child as Node2D)
func _add_player_billboard(actor: CharacterBody2D) -> void:
	var source_sprite := actor.get_node_or_null("CharacterActor/CharacterSprite") as TextureRect
	if source_sprite == null:
		return
	var visual := Sprite3D.new()
	visual.name = "Visual_%s" % actor.name
	visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	visual.pixel_size = WORLD_SCALE
	visual.transparent = true
	visual.position = _map_to_3d(actor.global_position) + Vector3(0.0, 0.36, 0.0)
	_apply_actor_texture(visual, source_sprite.texture)
	_world_3d.add_child(visual)
	var name_label := Label3D.new()
	name_label.name = "Name_%s" % actor.name
	var actor_name := actor.get_node_or_null("CharacterActor/PlayerName") as Label
	name_label.text = actor_name.text if actor_name else "Player"
	name_label.font_size = 34
	name_label.pixel_size = 0.0023
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.outline_size = 7
	name_label.outline_modulate = Color(0, 0, 0, 0.88)
	name_label.modulate = Color("fff0cf")
	name_label.position = _map_to_3d(actor.global_position) + Vector3(0.0, 0.88, 0.0)
	_world_3d.add_child(name_label)
	_actor_visuals.append({"actor": actor, "sprite": visual, "source_sprite": source_sprite, "name_label": name_label})


func _add_npc_billboard(npc: Node2D) -> void:
	var source_sprite := npc.get_node_or_null("Sprite2D") as Sprite2D
	if source_sprite == null or source_sprite.texture == null:
		return
	var visual := Sprite3D.new()
	visual.name = "Visual_%s" % npc.name
	visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	visual.pixel_size = WORLD_SCALE
	visual.position = _map_to_3d(npc.global_position) + Vector3(0.0, 0.36, 0.0)
	_apply_actor_texture(visual, source_sprite.texture)
	_world_3d.add_child(visual)
	var name_label := Label3D.new()
	name_label.text = npc.name.replace("NPC_", "").replace("_", " ")
	name_label.font_size = 30
	name_label.pixel_size = 0.0022
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.outline_size = 6
	name_label.outline_modulate = Color(0, 0, 0, 0.88)
	name_label.modulate = Color("fff0cf")
	name_label.position = _map_to_3d(npc.global_position) + Vector3(0.0, 0.82, 0.0)
	_world_3d.add_child(name_label)
	_actor_visuals.append({"actor": npc, "sprite": visual, "source_sprite": source_sprite, "name_label": name_label})


func _apply_actor_texture(visual: Sprite3D, texture: Texture2D) -> void:
	visual.texture = texture
	if texture == null:
		return
	var largest_side := maxf(float(texture.get_width()), float(texture.get_height()))
	var desired_height := 0.72
	var uniform_scale := desired_height / (largest_side * WORLD_SCALE)
	visual.scale = Vector3.ONE * uniform_scale


func _add_column(source_point: Vector2, body_material: Material, cap_material: Material, height: float = 0.92) -> void:
	var position := _source_to_world(source_point)
	var column := MeshInstance3D.new()
	column.name = "PalaceColumn"
	var column_mesh := CylinderMesh.new()
	column_mesh.top_radius = 0.065
	column_mesh.bottom_radius = 0.09
	column_mesh.height = height
	column.mesh = column_mesh
	column.material_override = body_material
	column.position = Vector3(position.x, height * 0.5, position.z)
	_world_3d.add_child(column)
	var cap := MeshInstance3D.new()
	cap.name = "ColumnGoldCap"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.11
	cap_mesh.bottom_radius = 0.10
	cap_mesh.height = 0.055
	cap.mesh = cap_mesh
	cap.material_override = cap_material
	cap.position = Vector3(position.x, height + 0.025, position.z)
	_world_3d.add_child(cap)


func _add_box(node_name: String, map_center: Vector2, map_size: Vector2, height: float, material: Material, y_center: float) -> void:
	var box_node := MeshInstance3D.new()
	box_node.name = node_name
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(map_size.x, height, map_size.y)
	box_node.mesh = box_mesh
	box_node.material_override = material
	var center := _map_to_3d(map_center)
	box_node.position = Vector3(center.x, y_center, center.z)
	_world_3d.add_child(box_node)
	var static_body := StaticBody3D.new()
	static_body.name = node_name + "Collision"
	static_body.position = box_node.position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_mesh.size
	collision.shape = shape
	static_body.add_child(collision)
	_world_3d.add_child(static_body)


func _make_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _map_to_3d(position: Vector2) -> Vector3:
	return Vector3((position.x - WORLD_SIZE.x * 0.5) * WORLD_SCALE, 0.0, (position.y - WORLD_SIZE.y * 0.5) * WORLD_SCALE)


func _source_to_world(source_position: Vector2) -> Vector3:
	var mapped := Vector2(source_position.x * WORLD_SIZE.x / 1420.0, source_position.y * WORLD_SIZE.y / 505.0)
	return _map_to_3d(mapped)


func _source_rect_to_map(source_rect: Rect2) -> Rect2:
	var map_scale := Vector2(WORLD_SIZE.x / 1420.0, WORLD_SIZE.y / 505.0)
	return Rect2(source_rect.position * map_scale, source_rect.size * map_scale)
