extends RefCounted
## Shared world-space data used by the client physics and room server.

const MAP_SIZES := [Vector2(2025, 720), Vector2(1280, 756), Vector2(1280, 753)]
const SPAWN_POINTS := [Vector2(1010, 380), Vector2(640, 395), Vector2(640, 395)]
const GONG_POINTS := [Vector2(1010, 430), Vector2(640, 570), Vector2(640, 570)]

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
	Rect2(645, 260, 103, 80), Rect2(680, 340, 68, 92),
	# House outer walls and front entrance stairs.
	Rect2(134, 38, 468, 24), Rect2(134, 54, 26, 250), Rect2(576, 54, 26, 250),
	Rect2(160, 288, 128, 24), Rect2(384, 288, 192, 24),
	# Interior room dividers, keeping the pictured doorways open.
	Rect2(160, 156, 52, 18), Rect2(292, 156, 84, 18), Rect2(482, 156, 94, 18),
	Rect2(300, 62, 18, 60), Rect2(300, 206, 18, 74),
	Rect2(426, 62, 18, 60), Rect2(426, 206, 18, 74),
	# Block the well only; keep the garden edge and sandy walking lane open.
	Rect2(38, 366, 30, 34)
]

const AREA_REGIONS_BY_MAP := [
	[
		{"name": "Palace Grounds", "rect": Rect2(0, 0, 2025, 720)}
	],
	[
		{"name": "House Interior", "rect": Rect2(300, 80, 680, 370)},
		{"name": "Village Yard", "rect": Rect2(240, 500, 790, 230)},
		{"name": "Paddy Path", "rect": Rect2(20, 210, 230, 330)},
		{"name": "Chicken Coop", "rect": Rect2(1030, 230, 230, 250)},
		{"name": "Competition Arena", "rect": Rect2(760, 520, 470, 210)}
	],
	[
		{"name": "Mahsuri's Village", "rect": Rect2(0, 0, 1280, 753)}
	]
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
	return AREA_REGIONS_BY_MAP[clampi(map_index, 0, AREA_REGIONS_BY_MAP.size() - 1)]


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
