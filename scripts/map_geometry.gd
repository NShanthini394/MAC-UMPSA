extends RefCounted
## Shared world-space data used by the client physics and room server.

const MAP_SIZES := [Vector2(2025, 720), Vector2(1280, 756), Vector2(1280, 753)]
const SPAWN_POINTS := [Vector2(1010, 380), Vector2(640, 395), Vector2(640, 395)]
const GONG_POINTS := [Vector2(1010, 430), Vector2(640, 570), Vector2(640, 570)]

const TASK_POINTS_BY_MAP := [
	[Vector2(300, 300), Vector2(650, 220), Vector2(1520, 285), Vector2(1720, 400), Vector2(1630, 535), Vector2(1030, 600), Vector2(540, 590), Vector2(850, 330)],
	[Vector2(500, 590), Vector2(1100, 430), Vector2(430, 350), Vector2(650, 340), Vector2(180, 300), Vector2(960, 560), Vector2(900, 615), Vector2(1080, 620)],
	[Vector2(270, 570), Vector2(520, 250), Vector2(1030, 600), Vector2(650, 330), Vector2(170, 360), Vector2(780, 310), Vector2(900, 245), Vector2(220, 610)]
]

const NPC_POINTS_BY_MAP := [
	[Vector2(640, 340), Vector2(1500, 410), Vector2(1740, 510), Vector2(750, 485)],
	[Vector2(420, 580), Vector2(800, 350), Vector2(1050, 490), Vector2(500, 410)],
	[Vector2(410, 580), Vector2(810, 360), Vector2(1060, 490), Vector2(510, 410)]
]

const CLUE_CANDIDATES_BY_MAP := [
	[Vector2(300, 300), Vector2(650, 220), Vector2(1520, 285), Vector2(1720, 400), Vector2(1630, 535), Vector2(1030, 600), Vector2(540, 590), Vector2(850, 330), Vector2(1850, 540), Vector2(360, 600), Vector2(1200, 580), Vector2(1000, 235)],
	[Vector2(500, 590), Vector2(1100, 430), Vector2(370, 350), Vector2(650, 340), Vector2(180, 300), Vector2(960, 560), Vector2(900, 615), Vector2(1080, 620), Vector2(235, 560), Vector2(770, 590), Vector2(1120, 300), Vector2(650, 185)],
	[Vector2(180, 520), Vector2(520, 250), Vector2(1030, 600), Vector2(650, 330), Vector2(170, 360), Vector2(780, 310), Vector2(900, 245), Vector2(220, 610), Vector2(1110, 570), Vector2(450, 610), Vector2(1000, 360), Vector2(620, 570)]
]

# Rectangles are hand-authored against the existing map artwork. They cover
# large walls, furniture, water, trees and boundary fences; they are not
# inferred from image colors.
const OBSTACLES_BY_MAP := [
	[
		Rect2(0, 0, 2025, 18), Rect2(0, 0, 18, 720), Rect2(2007, 0, 18, 720), Rect2(0, 702, 2025, 18),
		Rect2(430, 40, 1080, 34), Rect2(430, 40, 34, 480), Rect2(1476, 40, 34, 480),
		Rect2(464, 486, 400, 34), Rect2(1080, 486, 396, 34),
		Rect2(650, 130, 165, 75), Rect2(1050, 130, 165, 75),
		Rect2(700, 290, 100, 96), Rect2(1155, 286, 100, 96),
		Rect2(90, 90, 110, 100), Rect2(1800, 90, 110, 110)
	],
	[
		Rect2(0, 0, 1280, 18), Rect2(0, 0, 18, 756), Rect2(1262, 0, 18, 756),
		Rect2(0, 738, 500, 18), Rect2(760, 738, 520, 18),
		Rect2(258, 42, 764, 34), Rect2(258, 42, 34, 450), Rect2(988, 42, 34, 450),
		Rect2(292, 458, 270, 34), Rect2(748, 458, 240, 34),
		Rect2(365, 108, 94, 62), Rect2(800, 108, 95, 62),
		Rect2(535, 240, 185, 75), Rect2(314, 274, 76, 86), Rect2(895, 274, 72, 86),
		Rect2(55, 74, 90, 92), Rect2(152, 84, 70, 84), Rect2(72, 378, 155, 90),
		Rect2(1080, 93, 90, 105), Rect2(1135, 510, 88, 85)
	],
	[
		Rect2(0, 0, 1280, 18), Rect2(0, 0, 18, 753), Rect2(1262, 0, 18, 753),
		Rect2(0, 735, 500, 18), Rect2(760, 735, 520, 18),
		Rect2(258, 42, 764, 34), Rect2(258, 42, 34, 450), Rect2(988, 42, 34, 450),
		Rect2(292, 458, 270, 34), Rect2(748, 458, 240, 34),
		Rect2(365, 108, 94, 62), Rect2(800, 108, 95, 62),
		Rect2(535, 240, 185, 75), Rect2(314, 274, 76, 86), Rect2(895, 274, 72, 86),
		Rect2(1040, 500, 120, 90), Rect2(80, 80, 90, 120)
	]
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
	return OBSTACLES_BY_MAP[clampi(map_index, 0, OBSTACLES_BY_MAP.size() - 1)]


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
