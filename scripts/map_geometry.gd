extends RefCounted
## Shared world-space data used by the client physics and room server.

const MAP_SIZES := [Vector2(2025, 720), Vector2(1280, 756), Vector2(1280, 753)]
const SPAWN_POINTS := [Vector2(1010, 380), Vector2(640, 395), Vector2(640, 395)]
const GONG_POINTS := [Vector2(1010, 430), Vector2(640, 570), Vector2(640, 570)]
const SOURCE_SIZES := [Vector2(1420, 505), Vector2(745, 440), Vector2(748, 440)]
# Areas follow the artwork. Every lock lists the actual openings through its
# boundary. Open countryside supports fog; no invisible outdoor walls are added.
const SABOTAGE_AREAS_SOURCE := [
	[
		{"name": "Bilik Puteri", "zones": [Rect2(520, 55, 270, 71)], "doors": [Rect2(625, 112, 55, 14)]},
		{"name": "Balairung", "zones": [Rect2(524, 126, 266, 109)], "doors": [Rect2(625, 112, 55, 14), Rect2(625, 235, 55, 14), Rect2(510, 170, 14, 28), Rect2(790, 170, 14, 28)]},
		{"name": "Dewan Makan", "zones": [Rect2(294, 126, 216, 109)], "doors": [Rect2(510, 170, 14, 28), Rect2(365, 235, 45, 14)]},
		{"name": "Dapur", "zones": [Rect2(294, 249, 216, 115)], "doors": [Rect2(365, 235, 45, 14), Rect2(510, 294, 14, 26)]},
		{"name": "Bilik Tamu", "zones": [Rect2(804, 126, 230, 109)], "doors": [Rect2(790, 170, 14, 28), Rect2(895, 235, 45, 14)]},
		{"name": "Bilik Senjata", "zones": [Rect2(804, 249, 230, 115)], "doors": [Rect2(895, 235, 45, 14), Rect2(790, 294, 14, 26)]},
		{"name": "Lobi", "zones": [Rect2(524, 249, 266, 115)], "doors": [Rect2(625, 235, 55, 14), Rect2(510, 294, 14, 26), Rect2(790, 294, 14, 26), Rect2(622, 364, 68, 14)]},
		{"name": "Taman Istana", "zones": [Rect2(12, 12, 230, 481)], "doors": []},
		{"name": "Halaman Istana", "zones": [Rect2(1088, 12, 320, 481)], "doors": []},
		{"name": "Jambatan Istana", "zones": [Rect2(595, 378, 110, 115)], "doors": [Rect2(622, 364, 68, 14)]},
		{"name": "Laluan Luar Istana", "zones": [Rect2(242, 12, 846, 43), Rect2(242, 55, 36, 57), Rect2(242, 462, 353, 31), Rect2(705, 462, 383, 31), Rect2(218, 55, 32, 407), Rect2(1088, 55, 40, 407)], "doors": []}
	],
	[
		{"name": "Bilik Tidur", "zones": [Rect2(174, 48, 124, 106)], "doors": [Rect2(240, 154, 42, 18), Rect2(298, 136, 18, 36)]},
		{"name": "Ruang Keluarga", "zones": [Rect2(316, 48, 104, 106)], "doors": [Rect2(298, 136, 18, 36), Rect2(420, 136, 18, 36)]},
		{"name": "Dapur", "zones": [Rect2(438, 48, 96, 106)], "doors": [Rect2(420, 136, 18, 36), Rect2(423, 154, 37, 18)]},
		{"name": "Serambi", "zones": [Rect2(174, 172, 124, 128)], "doors": [Rect2(240, 154, 42, 18), Rect2(298, 136, 18, 36), Rect2(298, 284, 18, 16), Rect2(228, 300, 46, 24)]},
		{"name": "Ruang Makan", "zones": [Rect2(316, 172, 218, 128)], "doors": [Rect2(423, 154, 37, 18), Rect2(298, 136, 18, 36), Rect2(298, 284, 18, 16), Rect2(302, 300, 54, 24)]},
		{"name": "Kebun / Ladang", "zones": [Rect2(52, 220, 124, 124)], "doors": [Rect2(96, 334, 32, 10)]},
		{"name": "Reban Ayam", "zones": [Rect2(558, 8, 179, 212)], "doors": []},
		{"name": "Perigi / Halaman Timur", "zones": [Rect2(558, 220, 179, 150)], "doors": []},
		{"name": "Halaman Kampung", "zones": [Rect2(8, 344, 729, 88), Rect2(8, 8, 142, 212), Rect2(8, 220, 44, 124), Rect2(176, 324, 382, 20), Rect2(150, 8, 408, 18)], "doors": [Rect2(310, 370, 65, 16)]}
	],
	[
		{"name": "Bilik Tidur", "zones": [Rect2(146, 62, 154, 94)], "doors": [Rect2(212, 156, 80, 18), Rect2(300, 122, 18, 84)]},
		{"name": "Dapur", "zones": [Rect2(318, 62, 202, 94)], "doors": [Rect2(376, 156, 106, 18), Rect2(300, 122, 18, 84)]},
		{"name": "Ruang Tamu", "zones": [Rect2(146, 174, 154, 114)], "doors": [Rect2(212, 156, 80, 18), Rect2(300, 122, 18, 84), Rect2(300, 280, 18, 8)]},
		{"name": "Ruang Makan", "zones": [Rect2(318, 174, 202, 114)], "doors": [Rect2(376, 156, 106, 18), Rect2(300, 122, 18, 84), Rect2(300, 280, 18, 8), Rect2(288, 288, 96, 24)]},
		{"name": "Halaman / Kebun", "zones": [Rect2(8, 8, 112, 378), Rect2(120, 8, 426, 28), Rect2(146, 288, 374, 24), Rect2(120, 312, 426, 74), Rect2(8, 400, 732, 32)], "doors": [Rect2(268, 386, 124, 14)]},
		{"name": "Tandas Luar", "zones": [Rect2(546, 8, 154, 122)], "doors": []},
		{"name": "Tebing Sungai / Jeti", "zones": [Rect2(546, 130, 194, 256)], "doors": []}
	]
]
const TASK_POINTS_BY_MAP := [
	[Vector2(340, 360), Vector2(650, 220), Vector2(1600, 285), Vector2(1800, 400), Vector2(1630, 535), Vector2(930, 600), Vector2(540, 650), Vector2(930, 360)],
	[Vector2(500, 590), Vector2(1100, 430), Vector2(430, 350), Vector2(650, 340), Vector2(180, 300), Vector2(960, 560), Vector2(900, 615), Vector2(1080, 620)],
	[Vector2(270, 570), Vector2(520, 250), Vector2(1030, 600), Vector2(650, 330), Vector2(170, 360), Vector2(780, 310), Vector2(900, 245), Vector2(220, 610)]
]

const NPC_POINTS_BY_MAP := [
	[Vector2(640, 300), Vector2(1600, 410), Vector2(1740, 510), Vector2(850, 360)],
	[Vector2(420, 580), Vector2(800, 350), Vector2(1050, 490), Vector2(500, 410)],
	[Vector2(410, 580), Vector2(810, 360), Vector2(1060, 490), Vector2(510, 410)]
]

const CLUE_CANDIDATES_BY_MAP := [
	[Vector2(340, 360), Vector2(650, 220), Vector2(1600, 285), Vector2(1800, 400), Vector2(1630, 535), Vector2(930, 600), Vector2(540, 650), Vector2(930, 360), Vector2(1850, 540), Vector2(360, 600), Vector2(1200, 580), Vector2(1000, 235)],
	[Vector2(500, 590), Vector2(1100, 430), Vector2(370, 350), Vector2(650, 340), Vector2(180, 300), Vector2(960, 560), Vector2(900, 615), Vector2(1080, 620), Vector2(235, 560), Vector2(770, 590), Vector2(1120, 300), Vector2(650, 185)],
	[Vector2(180, 520), Vector2(520, 250), Vector2(1030, 600), Vector2(650, 330), Vector2(170, 360), Vector2(780, 310), Vector2(900, 245), Vector2(220, 610), Vector2(1110, 570), Vector2(450, 610), Vector2(1000, 360), Vector2(620, 570)]
]

# Rectangles are hand-authored against the existing map artwork. They cover
# large walls, furniture, water, trees and boundary fences; they are not
# inferred from image colors.
const PALACE_SOURCE_OBSTACLES := [
	# Map-edge walls/fences. Room walls below include deliberate door gaps.
	Rect2(0, 0, 1420, 12), Rect2(0, 0, 12, 505), Rect2(1408, 0, 12, 505), Rect2(0, 493, 1420, 12),
	# The moat around the palace; leave the south bridge open.
	Rect2(278, 55, 230, 55), Rect2(800, 55, 250, 55),
	Rect2(250, 112, 30, 270), Rect2(1048, 112, 40, 270),
	# Extend the south moat blockers through the full blue-water band in the
	# palace artwork. The central bridge remains the only crossing.
	Rect2(250, 382, 345, 80), Rect2(705, 382, 383, 80),
	# Palace exterior walls. The main south entrance aligns with the bridge.
	Rect2(280, 112, 14, 252), Rect2(1034, 112, 14, 252),
	Rect2(280, 112, 240, 14), Rect2(790, 112, 258, 14),
	Rect2(280, 364, 342, 14), Rect2(690, 364, 358, 14),
	# Divider walls between Dewan Makan, Dapur, Bilik Tamu and Bilik Senjata.
	Rect2(510, 126, 14, 44), Rect2(510, 198, 14, 96), Rect2(510, 320, 14, 44),
	Rect2(790, 126, 14, 44), Rect2(790, 198, 14, 96), Rect2(790, 320, 14, 44),
	Rect2(294, 235, 71, 14), Rect2(410, 235, 100, 14),
	Rect2(804, 235, 91, 14), Rect2(940, 235, 94, 14),
	# Balairung and Lobi walls; leave the centered passage between them.
	Rect2(520, 112, 105, 14), Rect2(680, 112, 110, 14),
	Rect2(520, 235, 105, 14), Rect2(680, 235, 110, 14),
	# Garden pond and the fountain basin.
	Rect2(28, 220, 190, 125), Rect2(1160, 205, 78, 100)
]

const PALACE_TREE_BLOCKERS_SOURCE := [
	Rect2(181, 86, 18, 18), Rect2(1291, 146, 18, 18),
	Rect2(26, 456, 18, 18), Rect2(136, 458, 18, 18), Rect2(1141, 454, 18, 18),
	Rect2(1271, 457, 18, 18), Rect2(1361, 441, 18, 18)
]

# Blockers are authored against the corresponding artwork crop (not the
# destination viewport), then scaled into world coordinates in obstacles().
# Door and gate gaps are intentional walkways through each wall/fence.
const PAK_KADUK_SOURCE_OBSTACLES := [
	# World bounds and the compound fence; leave the front gate open.
	Rect2(0, 0, 745, 8), Rect2(0, 0, 8, 440), Rect2(737, 0, 8, 440),
	Rect2(8, 370, 302, 16), Rect2(375, 370, 362, 16), Rect2(8, 432, 729, 8),
	# Raised house exterior and the two visible stair/door entrances.
	Rect2(150, 26, 408, 22), Rect2(150, 40, 24, 266), Rect2(534, 40, 24, 266),
	Rect2(174, 300, 54, 24), Rect2(274, 300, 28, 24), Rect2(356, 300, 178, 24),
	# Interior room dividers. Door gaps align with the openings in the artwork.
	Rect2(174, 154, 66, 18), Rect2(282, 154, 141, 18), Rect2(460, 154, 74, 18),
	Rect2(298, 48, 18, 88), Rect2(298, 172, 18, 112),
	Rect2(420, 48, 18, 88), Rect2(420, 172, 18, 112),
	# Vegetable garden fence with its small entrance, plus solid props.
	Rect2(52, 220, 124, 10), Rect2(52, 230, 10, 104), Rect2(166, 230, 10, 104),
	Rect2(62, 334, 34, 10), Rect2(128, 334, 38, 10),
	Rect2(138, 344, 22, 22), Rect2(632, 268, 48, 38), Rect2(692, 376, 28, 32)
]

const MAHSURI_SOURCE_OBSTACLES := [
	# World bounds and compound fence; the southern entrance remains passable.
	Rect2(0, 0, 748, 8), Rect2(0, 0, 8, 440), Rect2(740, 0, 8, 440),
	Rect2(54, 386, 214, 14), Rect2(392, 386, 294, 14), Rect2(8, 432, 732, 8),
	# Follow the irregular coast so the sandy footpath stays open but sea does not.
	Rect2(700, 0, 48, 130), Rect2(665, 130, 83, 130),
	Rect2(680, 260, 68, 80), Rect2(700, 340, 48, 92),
	# Match the house roof outline closely so the adjoining yard stays walkable.
	Rect2(120, 36, 426, 26), Rect2(120, 54, 26, 250), Rect2(520, 54, 26, 250),
	Rect2(146, 288, 142, 24), Rect2(384, 288, 136, 24),
	# Interior room dividers, keeping the pictured doorways open.
	Rect2(160, 156, 52, 18), Rect2(292, 156, 84, 18), Rect2(482, 156, 94, 18),
	Rect2(300, 62, 18, 60), Rect2(300, 206, 18, 74),
	Rect2(426, 62, 18, 60), Rect2(426, 206, 18, 74),
	# Block the well only; keep the garden edge and sandy walking lane open.
	Rect2(38, 366, 30, 34)
]

static func world_size(map_index: int) -> Vector2:
	return MAP_SIZES[clampi(map_index, 0, MAP_SIZES.size() - 1)]


static func spawn_point(map_index: int) -> Vector2:
	return SPAWN_POINTS[clampi(map_index, 0, SPAWN_POINTS.size() - 1)]


static func spawn_point_for_player(map_index: int, player_index: int) -> Vector2:
	# Put players in two tidy rows near the map's common spawn. The spacing keeps
	# their collision capsules from overlapping when the match opens.
	var column := player_index % 5
	var row := floori(float(player_index) / 5.0)
	var offset := Vector2(float(column - 2) * 30.0, float(row) * 32.0 - 16.0)
	var point := spawn_point(map_index) + offset
	if is_position_blocked(map_index, point):
		return spawn_point(map_index)
	return point


static func gong_point(map_index: int) -> Vector2:
	return GONG_POINTS[clampi(map_index, 0, GONG_POINTS.size() - 1)]


static func task_points(map_index: int) -> Array:
	return TASK_POINTS_BY_MAP[clampi(map_index, 0, TASK_POINTS_BY_MAP.size() - 1)]


static func npc_points(map_index: int) -> Array:
	return NPC_POINTS_BY_MAP[clampi(map_index, 0, NPC_POINTS_BY_MAP.size() - 1)]


static func clue_candidates(map_index: int) -> Array:
	return CLUE_CANDIDATES_BY_MAP[clampi(map_index, 0, CLUE_CANDIDATES_BY_MAP.size() - 1)]


static func obstacles(map_index: int) -> Array:
	var safe_index := clampi(map_index, 0, MAP_SIZES.size() - 1)
	var source_obstacles: Array
	var source_size: Vector2
	if safe_index == 1:
		source_obstacles = PAK_KADUK_SOURCE_OBSTACLES
		source_size = Vector2(745.0, 440.0)
	elif safe_index == 2:
		source_obstacles = MAHSURI_SOURCE_OBSTACLES
		source_size = Vector2(748.0, 440.0)
	else:
		var palace_scale := Vector2(MAP_SIZES[0].x / 1420.0, MAP_SIZES[0].y / 505.0)
		var palace_scaled: Array[Rect2] = []
		for source_rect in PALACE_SOURCE_OBSTACLES:
			palace_scaled.append(Rect2(source_rect.position * palace_scale, source_rect.size * palace_scale))
		for source_rect in PALACE_TREE_BLOCKERS_SOURCE:
			palace_scaled.append(Rect2(source_rect.position * palace_scale, source_rect.size * palace_scale))
		return palace_scaled
	var scale := Vector2(MAP_SIZES[safe_index].x / source_size.x, MAP_SIZES[safe_index].y / source_size.y)
	var scaled: Array[Rect2] = []
	for source_rect in source_obstacles:
		scaled.append(Rect2(source_rect.position * scale, source_rect.size * scale))
	return scaled


static func areas(map_index: int) -> Array:
	var result: Array = []
	for area in sabotage_areas(map_index):
		for zone in area["zones"]:
			result.append({"name": area["name"], "rect": zone})
	return result


static func sabotage_areas(map_index: int) -> Array:
	var safe_map := clampi(map_index, 0, MAP_SIZES.size() - 1)
	var scale: Vector2 = MAP_SIZES[safe_map] / SOURCE_SIZES[safe_map]
	var result: Array = []
	for source_area in SABOTAGE_AREAS_SOURCE[safe_map]:
		var area := {"name": source_area["name"], "zones": [], "doors": []}
		for key in ["zones", "doors"]:
			for source_rect in source_area[key]:
				area[key].append(Rect2(source_rect.position * scale, source_rect.size * scale))
		result.append(area)
	return result


static func area_doors(map_index: int, area_index: int) -> Array:
	var regions := sabotage_areas(map_index)
	if area_index < 0 or area_index >= regions.size(): return []
	return regions[area_index]["doors"]


static func point_in_area(map_index: int, area_index: int, point: Vector2) -> bool:
	var regions := sabotage_areas(map_index)
	if area_index < 0 or area_index >= regions.size(): return false
	for zone in regions[area_index]["zones"]:
		if zone.has_point(point): return true
	return false


static func section_at_position(map_index: int, point: Vector2) -> int:
	var regions := sabotage_areas(map_index)
	for i in regions.size():
		for zone in regions[i]["zones"]:
			if zone.has_point(point): return i
	# A player can stand in a doorway between the floor regions. Resolve only
	# that narrow threshold, rather than choosing another room across the map.
	var nearest := -1
	var distance := 24.0
	for i in regions.size():
		for zone in regions[i]["zones"]:
			var edge: Vector2 = point.clamp(zone.position, zone.end)
			var candidate := point.distance_to(edge)
			if candidate < distance:
				distance = candidate
				nearest = i
	return nearest


static func fog_regions(map_index: int, area_index: int, origin: Vector2, radius: float) -> Array:
	var bounds := Rect2(origin - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	bounds = bounds.intersection(Rect2(Vector2.ZERO, world_size(map_index)))
	var regions := sabotage_areas(map_index)
	if area_index < 0 or area_index >= regions.size(): return [bounds]
	var result: Array = []
	for zone in regions[area_index]["zones"]:
		var clipped: Rect2 = zone.intersection(bounds)
		if clipped.has_area(): result.append(clipped)
	return result


static func is_position_blocked(map_index: int, position: Vector2, radius: float = 12.0) -> bool:
	var world := world_size(map_index)
	if position.x < radius or position.y < radius or position.x > world.x - radius or position.y > world.y - radius:
		return true
	var expanded := Rect2()
	for obstacle in obstacles(map_index):
		expanded = obstacle.grow(radius)
		if expanded.has_point(position):
			return true
	return false


static func is_step_blocked(map_index: int, from_position: Vector2, to_position: Vector2, radius: float = 12.0, locked_entrances: Array = []) -> bool:
	if is_position_blocked(map_index, to_position, radius):
		return true
	for obstacle in obstacles(map_index):
		var expanded: Rect2 = obstacle.grow(radius)
		if not expanded.has_point(from_position) and segment_touches_rect(from_position, to_position, expanded):
			return true
	for door in locked_entrances:
		var expanded: Rect2 = door.grow(radius)
		if not expanded.has_point(from_position) and segment_touches_rect(from_position, to_position, expanded):
			return true
	return false


static func segment_touches_rect(from_point: Vector2, to_point: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from_point) or rect.has_point(to_point): return true
	var corners := [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(from_point, to_point, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false


static func has_clear_path(map_index: int, from_point: Vector2, to_point: Vector2, locked_entrances: Array = []) -> bool:
	for obstacle in obstacles(map_index) + locked_entrances:
		if segment_touches_rect(from_point, to_point, obstacle.grow(1.0)): return false
	return true


static func clear_doorway_position(map_index: int, point: Vector2, door: Rect2) -> Vector2:
	var margin := 16.0
	var candidates: Array[Vector2] = [
		Vector2(door.position.x - margin, point.y), Vector2(door.end.x + margin, point.y),
		Vector2(point.x, door.position.y - margin), Vector2(point.x, door.end.y + margin)
	]
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(point) < b.distance_squared_to(point))
	for candidate in candidates:
		if not is_position_blocked(map_index, candidate, 14.0): return candidate
	return point
