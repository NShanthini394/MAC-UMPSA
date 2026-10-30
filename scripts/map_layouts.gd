extends RefCounted
## Traced floor plans, pictured stairways, and explicitly rendered connections.
## Coordinates refer to each source image, except palace's 2048x683 design view.
const LAYOUTS := [
{
	"design_size": Vector2(2048, 683), "world_size": Vector2(2172, 724),
	"art": "res://assets/maps/istana_puteri_gunung_ledang.png", "tile": Rect2(913, 438, 16, 16),
	"spawn": Vector2(940, 401), "gong": Vector2(940, 280),
	"floors": [
		Rect2(797, 88, 284, 223), Rect2(909, 286, 59, 88), Rect2(820, 365, 240, 82), Rect2(895, 428, 93, 230),
		Rect2(478, 190, 266, 112), Rect2(615, 288, 48, 80), Rect2(478, 337, 264, 113),
		Rect2(1137, 190, 267, 112), Rect2(1239, 288, 48, 80), Rect2(1138, 337, 270, 113),
		Rect2(715, 375, 122, 54), Rect2(1045, 375, 130, 54), Rect2(365, 240, 132, 56), Rect2(1380, 240, 226, 56),
		Rect2(1585, 237, 246, 56), Rect2(1585, 237, 59, 302), Rect2(1780, 235, 55, 285), Rect2(1585, 410, 248, 62),
		Rect2(1600, 517, 231, 50), Rect2(1602, 143, 47, 110), Rect2(1783, 144, 47, 110)
	],
	"paths": [
		{"width": 46, "points": [Vector2(145,214),Vector2(158,253),Vector2(183,281),Vector2(156,318),Vector2(156,349),Vector2(127,380),Vector2(115,419),Vector2(104,453),Vector2(109,488),Vector2(133,518)]},
		{"width": 46, "points": [Vector2(183,281),Vector2(242,280),Vector2(300,280),Vector2(351,280)]},
		{"width": 46, "points": [Vector2(344,198),Vector2(353,245),Vector2(351,280),Vector2(351,320),Vector2(350,359),Vector2(366,397),Vector2(366,444),Vector2(358,484),Vector2(343,518)]},
		{"width": 46, "points": [Vector2(156,349),Vector2(190,376),Vector2(242,383),Vector2(290,377),Vector2(350,359)]},
		{"width": 46, "points": [Vector2(245,241),Vector2(245,280)]}, {"width": 46, "points": [Vector2(242,383),Vector2(242,410)]}
	],
	"solids": [
		Rect2(904,242,72,16), Rect2(914,99,55,53), Rect2(805,173,18,24), Rect2(1058,173,20,24), Rect2(805,278,24,25), Rect2(1054,278,25,25),
		Rect2(555,235,125,32), Rect2(485,193,44,33), Rect2(696,193,42,30), Rect2(1216,230,98,39), Rect2(1142,193,40,30), Rect2(1361,193,37,31),
		Rect2(480,348,50,95), Rect2(541,409,83,34), Rect2(500,337,104,22), Rect2(665,337,68,22), Rect2(685,359,50,12), Rect2(685,435,50,15),
		Rect2(1230,372,89,58), Rect2(1368,340,36,100), Rect2(1138,337,40,34), Rect2(1138,435,40,15), Rect2(1185,422,36,26)
	],
	"patches": [Rect2(715,375,122,54),Rect2(1045,375,130,54),Rect2(365,240,132,56),Rect2(1380,240,226,56)],
	"doors": [
		{"name":"Throne hall stairs","rect":Rect2(909,315,59,12)}, {"name":"Dining stairs","rect":Rect2(615,309,48,12)},
		{"name":"Guest stairs","rect":Rect2(1239,309,48,12)}, {"name":"Kitchen doorway","rect":Rect2(762,375,12,54)},
		{"name":"Armoury doorway","rect":Rect2(1100,375,12,54)}, {"name":"Main gate","rect":Rect2(895,462,93,12)},
		{"name":"West garden gate","rect":Rect2(389,240,12,56)}, {"name":"Dining garden door","rect":Rect2(453,240,12,56)},
		{"name":"Guest garden door","rect":Rect2(1420,240,12,56)}, {"name":"East garden gate","rect":Rect2(1535,240,12,56)}
	],
	"sections": [
		{"name":"Throne Hall","zones":[Rect2(797,88,284,223)],"doors":[0]},
		{"name":"Dining Hall","zones":[Rect2(478,190,266,112)],"doors":[1,7]},
		{"name":"Guest Room","zones":[Rect2(1137,190,267,112)],"doors":[2,8]},
		{"name":"Kitchen","zones":[Rect2(478,337,264,113)],"doors":[1,3]},
		{"name":"Armoury","zones":[Rect2(1138,337,270,113)],"doors":[2,4]},
		{"name":"Main Bridge","zones":[Rect2(895,474,93,184)],"doors":[5]},
		{"name":"Lobby","zones":[Rect2(820,365,240,82),Rect2(909,311,59,54)],"doors":[0,3,4,5]},
		{"name":"West Garden","zones":[Rect2(85,185,295,350)],"doors":[6]},
		{"name":"East Garden","zones":[Rect2(1555,130,295,445)],"doors":[9]}
	],
	"task_sections":[3,8,0,2,7,1,4,6],
	"tasks":[Vector2(580,382),Vector2(1805,435),Vector2(990,236),Vector2(1360,279),Vector2(240,280),Vector2(709,267),Vector2(1340,414),Vector2(850,401)],
	"npcs": [Vector2(585,383),Vector2(1340,414),Vector2(1615,429),Vector2(850,240)],
	"clues": [Vector2(240,280),Vector2(709,267),Vector2(1360,279),Vector2(1340,400),Vector2(1805,435),Vector2(990,236),Vector2(580,382),Vector2(850,135),Vector2(940,580),Vector2(351,338),Vector2(1625,185),Vector2(940,201)],
	"routes": [
		[Vector2(940,640),Vector2(940,580),Vector2(940,490),Vector2(940,401),Vector2(940,350),Vector2(940,300),Vector2(940,280),Vector2(884,280),Vector2(884,201),Vector2(940,201)],
		[Vector2(940,201),Vector2(850,201),Vector2(850,135)], [Vector2(940,201),Vector2(990,201),Vector2(990,236)],
		[Vector2(940,401),Vector2(850,401),Vector2(700,401),Vector2(640,390),Vector2(640,355),Vector2(640,285)],
		[Vector2(640,390),Vector2(580,382)], [Vector2(640,285),Vector2(710,285),Vector2(709,267)],
		[Vector2(640,285),Vector2(515,285),Vector2(515,268),Vector2(351,268),Vector2(351,280)],
		[Vector2(940,401),Vector2(1120,401),Vector2(1200,401),Vector2(1200,355),Vector2(1263,355),Vector2(1263,285)],
		[Vector2(1263,355),Vector2(1340,355),Vector2(1340,400),Vector2(1340,414)],
		[Vector2(1263,285),Vector2(1360,285),Vector2(1360,268),Vector2(1625,268)],
		[Vector2(1625,185),Vector2(1625,268),Vector2(1625,438),Vector2(1625,540),Vector2(1805,540),Vector2(1805,438),Vector2(1805,268),Vector2(1805,185)],
		[Vector2(1625,268),Vector2(1805,268)], [Vector2(1625,438),Vector2(1805,438)],
		[Vector2(145,214),Vector2(158,253),Vector2(183,281),Vector2(156,318),Vector2(156,349),Vector2(127,380),Vector2(115,419),Vector2(104,453),Vector2(109,488),Vector2(133,518)],
		[Vector2(183,281),Vector2(242,280),Vector2(300,280),Vector2(351,280)],
		[Vector2(344,198),Vector2(353,245),Vector2(351,268),Vector2(351,280),Vector2(351,320),Vector2(350,359),Vector2(366,397),Vector2(366,444),Vector2(358,484),Vector2(343,518)],
		[Vector2(156,349),Vector2(190,376),Vector2(242,383),Vector2(290,377),Vector2(350,359)],
		[Vector2(245,241),Vector2(242,280)], [Vector2(242,383),Vector2(242,410)]
	],
	"forbidden": {"west roof":Vector2(435,380),"garden pavilion roof":Vector2(250,160),"east pavilion roof":Vector2(1900,325),"pond":Vector2(250,460),"fountain":Vector2(1710,340),"moat":Vector2(600,545),"hall divider":Vector2(767,240),"dining wall":Vector2(700,315)},
	"wall_crossings": [[Vector2(710,260),Vector2(840,260)],[Vector2(700,285),Vector2(700,355)]]
},
{
	"design_size": Vector2(1448,1086), "world_size": Vector2(1448,1086),
	"art":"res://assets/maps/rumah_pak_kaduk.png", "tile":Rect2(592,305,16,18),
	"spawn":Vector2(650,765),"gong":Vector2(728,765),
	"floors":[Rect2(359,165,181,188),Rect2(484,340,38,65),Rect2(359,394,184,168),Rect2(568,164,256,178),Rect2(849,148,131,184),Rect2(857,320,40,80),Rect2(578,391,413,137),Rect2(616,330,60,72),Rect2(433,548,77,157),Rect2(575,518,63,187),Rect2(594,787,72,120)],
	"polygons":[[Vector2(336,670),Vector2(433,667),Vector2(445,692),Vector2(503,692),Vector2(530,671),Vector2(630,680),Vector2(691,660),Vector2(1000,650),Vector2(1110,667),Vector2(1112,712),Vector2(1055,739),Vector2(951,753),Vector2(885,788),Vector2(800,802),Vector2(705,815),Vector2(590,815),Vector2(474,804),Vector2(376,799),Vector2(322,769)],
		[Vector2(150,915),Vector2(533,879),Vector2(600,855),Vector2(674,858),Vector2(751,891),Vector2(1201,904),Vector2(1352,949),Vector2(1318,1004),Vector2(935,1013),Vector2(870,1008),Vector2(490,1006),Vector2(221,998),Vector2(158,962)]],
	"paths":[
		{"width":84,"points":[Vector2(1058,680),Vector2(1110,597),Vector2(1129,530),Vector2(1103,476),Vector2(1118,405),Vector2(1135,339),Vector2(1121,276),Vector2(1075,228)]},
		{"width":60,"points":[Vector2(1110,597),Vector2(1179,617)]},
		{"width":56,"points":[Vector2(1135,339),Vector2(1206,301),Vector2(1274,293)]},
		{"width":72,"points":[Vector2(341,731),Vector2(315,674),Vector2(302,604),Vector2(285,538),Vector2(297,463),Vector2(291,391),Vector2(277,351),Vector2(251,347),Vector2(219,369),Vector2(158,378)]}
	],
	"solids":[Rect2(688,710,84,22),Rect2(411,176,62,100),Rect2(361,174,25,158),Rect2(482,165,53,42),Rect2(521,296,20,44),Rect2(567,204,29,70),Rect2(657,228,71,48),Rect2(791,186,30,137),Rect2(905,222,68,88),Rect2(849,148,42,45),Rect2(374,398,67,30),Rect2(431,465,64,30),Rect2(389,534,21,18),Rect2(652,423,110,60),Rect2(877,428,40,69),Rect2(965,393,15,119),Rect2(70,815,510,27),Rect2(692,815,652,27),Rect2(569,775,25,100),Rect2(666,775,28,100)],
	"patches":[Rect2(616,330,60,72),Rect2(594,787,72,73)],
	"doors":[{"name":"Bedroom stairs","rect":Rect2(484,357,38,12)}, {"name":"Kitchen stairs","rect":Rect2(857,343,40,12)}, {"name":"Family room doorway","rect":Rect2(616,360,60,12)}, {"name":"Veranda entrance","rect":Rect2(433,566,77,12)}, {"name":"Dining entrance","rect":Rect2(575,548,63,12)}, {"name":"Compound gate","rect":Rect2(594,822,72,12)}],
	"sections":[{"name":"Bedroom","zones":[Rect2(359,165,181,188)],"doors":[0]}, {"name":"Family Room","zones":[Rect2(568,164,256,178)],"doors":[2]}, {"name":"Kitchen","zones":[Rect2(849,148,131,184)],"doors":[1]}, {"name":"Veranda","zones":[Rect2(359,394,184,168)],"doors":[0,3]}, {"name":"Dining Room","zones":[Rect2(578,391,413,137)],"doors":[1,2,4]}, {"name":"Garden","zones":[Rect2(260,437,78,260)],"doors":[]}, {"name":"Chicken Coop","zones":[Rect2(135,335,180,85)],"doors":[]}, {"name":"Well and East Yard","zones":[Rect2(1030,230,290,490)],"doors":[]}, {"name":"Front Yard","zones":[Rect2(322,675,790,140)],"doors":[3,4,5]}],
	"task_sections":[2,6,1,7,5,4,0,3],
	"tasks":[Vector2(877,210),Vector2(219,369),Vector2(760,291),Vector2(1179,617),Vector2(295,550),Vector2(806,503),Vector2(495,302),Vector2(510,520)],
	"npcs":[Vector2(390,464),Vector2(760,291),Vector2(1115,395),Vector2(282,385)],
	"clues":[Vector2(295,550),Vector2(178,370),Vector2(495,302),Vector2(760,269),Vector2(1117,403),Vector2(942,485),Vector2(702,748),Vector2(1100,605),Vector2(470,617),Vector2(608,625),Vector2(630,850),Vector2(1150,602)],
	"routes":[
		[Vector2(630,950),Vector2(630,880),Vector2(630,780),Vector2(630,728),Vector2(650,680),Vector2(720,680),Vector2(1040,688),Vector2(1110,597),Vector2(1129,530),Vector2(1103,476),Vector2(1118,405),Vector2(1135,339),Vector2(1121,276),Vector2(1075,228)],
		[Vector2(1110,597),Vector2(1179,617)], [Vector2(1135,339),Vector2(1206,301),Vector2(1274,293)],
		[Vector2(630,728),Vector2(606,680),Vector2(606,548),Vector2(606,503),Vector2(606,408),Vector2(646,408),Vector2(646,360),Vector2(646,315),Vector2(760,315),Vector2(760,269)],
		[Vector2(606,503),Vector2(806,503),Vector2(927,503),Vector2(927,402),Vector2(877,402),Vector2(877,349),Vector2(877,210)],
		[Vector2(630,728),Vector2(470,724),Vector2(470,617),Vector2(470,548),Vector2(510,520),Vector2(510,409),Vector2(503,363),Vector2(503,288),Vector2(495,302)],
		[Vector2(470,548),Vector2(390,495),Vector2(390,464)],
		[Vector2(470,724),Vector2(341,731),Vector2(315,674),Vector2(302,604),Vector2(285,538),Vector2(297,463),Vector2(291,391),Vector2(277,351),Vector2(251,347),Vector2(219,369),Vector2(158,378)],
		[Vector2(630,728),Vector2(560,741)], [Vector2(630,728),Vector2(650,765),Vector2(728,765),Vector2(702,748)]
	],
	"forbidden":{"west roof":Vector2(328,290),"east roof":Vector2(1008,240),"coop roof":Vector2(149,295),"shed roof":Vector2(1270,173),"well":Vector2(1255,602),"bedroom wall":Vector2(450,367),"family wall":Vector2(750,365),"veranda divider":Vector2(556,460),"closed fence":Vector2(955,828)},
	"wall_crossings":[[Vector2(465,315),Vector2(465,415)],[Vector2(760,315),Vector2(760,410)],[Vector2(520,445),Vector2(602,445)]]
},
{
	"design_size":Vector2(1448,1086),"world_size":Vector2(1448,1086),
	"art":"res://assets/maps/rumah_mahsuri.png","tile":Rect2(726,400,16,18),
	"spawn":Vector2(840,760),"gong":Vector2(832,772),
	"floors":[Rect2(380,209,257,125),Rect2(567,326,42,68),Rect2(380,390,257,145),Rect2(680,209,280,125),Rect2(823,326,40,68),Rect2(680,390,280,145),Rect2(588,523,40,70),Rect2(608,553,166,59),Rect2(720,522,54,65),Rect2(642,588,91,148),Rect2(299,651,887,176),Rect2(614,811,141,110),Rect2(1250,287,122,59),Rect2(1254,485,134,74)],
	"polygons":[[Vector2(480,905),Vector2(600,875),Vector2(775,875),Vector2(904,910),Vector2(1160,898),Vector2(1216,941),Vector2(1207,991),Vector2(1048,1013),Vector2(653,1005),Vector2(560,1030),Vector2(480,1006)]],
	"paths":[
		{"width":72,"points":[Vector2(990,724),Vector2(1063,720),Vector2(1111,700),Vector2(1113,632),Vector2(1131,555),Vector2(1151,489),Vector2(1123,419),Vector2(1113,350),Vector2(1143,290),Vector2(1103,248)]},
		{"width":56,"points":[Vector2(1103,248),Vector2(1208,245),Vector2(1252,261),Vector2(1263,300),Vector2(1265,362),Vector2(1264,421),Vector2(1262,463),Vector2(1254,515)]},
		{"width":50,"points":[Vector2(1254,515),Vector2(1285,600),Vector2(1285,700),Vector2(1285,800),Vector2(1240,914),Vector2(1186,943)]},
		{"width":56,"points":[Vector2(305,580),Vector2(313,640),Vector2(313,705),Vector2(311,766)]}
	],
	"solids":[Rect2(784,716,98,26),Rect2(404,218,67,97),Rect2(523,210,75,37),Rect2(604,210,30,40),Rect2(778,250,86,42),Rect2(899,235,42,88),Rect2(775,209,73,25),Rect2(474,446,75,39),Rect2(466,393,81,27),Rect2(399,436,32,59),Rect2(437,512,68,23),Rect2(776,447,94,47),Rect2(927,426,30,104),Rect2(676,450,39,81),Rect2(792,513,68,23),Rect2(350,715,205,112),Rect2(940,754,96,72),Rect2(60,834,513,26),Rect2(806,834,430,26),Rect2(573,768,41,117),Rect2(755,768,51,117)],
	"patches":[Rect2(608,553,166,59),Rect2(720,522,54,65)],
	"doors":[{"name":"Bedroom stairs","rect":Rect2(567,350,42,12)}, {"name":"Kitchen stairs","rect":Rect2(823,350,40,12)}, {"name":"Living room entrance","rect":Rect2(588,548,40,12)}, {"name":"Dining room entrance","rect":Rect2(720,544,54,12)}, {"name":"Main front stairs","rect":Rect2(642,611,91,12)}, {"name":"Compound gate","rect":Rect2(614,835,141,12)}, {"name":"Upper pier entrance","rect":Rect2(1268,302,12,38)}, {"name":"Lower pier entrance","rect":Rect2(1269,500,12,42)}],
	"sections":[{"name":"Bedroom","zones":[Rect2(380,209,257,125)],"doors":[0]}, {"name":"Kitchen","zones":[Rect2(680,209,280,125)],"doors":[1]}, {"name":"Living Room","zones":[Rect2(380,390,257,145)],"doors":[0,2]}, {"name":"Dining Room","zones":[Rect2(680,390,280,145)],"doors":[1,3]}, {"name":"Veranda and Stairs","zones":[Rect2(588,532,186,204)],"doors":[2,3,4]}, {"name":"Yard and Garden","zones":[Rect2(299,651,887,176)],"doors":[4,5]}, {"name":"Back Yard","zones":[Rect2(1075,230,150,85)],"doors":[]}, {"name":"Beach and Piers","zones":[Rect2(1220,270,180,650)],"doors":[6,7]}],
	"task_sections":[1,6,2,7,5,3,0,4],
	"tasks":[Vector2(727,300),Vector2(1125,257),Vector2(600,425),Vector2(1280,320),Vector2(369,690),Vector2(895,503),Vector2(603,284),Vector2(686,580)],
	"npcs":[Vector2(600,430),Vector2(726,295),Vector2(1113,632),Vector2(930,735)],
	"clues":[Vector2(369,690),Vector2(1114,550),Vector2(1125,257),Vector2(727,300),Vector2(1110,706),Vector2(600,425),Vector2(603,284),Vector2(1280,522),Vector2(686,677),Vector2(1135,296),Vector2(1238,259),Vector2(1272,320)],
	"routes":[
		[Vector2(680,976),Vector2(680,890),Vector2(680,840),Vector2(680,780),Vector2(840,760),Vector2(1111,760),Vector2(1111,700),Vector2(1113,632),Vector2(1131,555),Vector2(1151,489),Vector2(1123,419),Vector2(1113,350),Vector2(1143,290),Vector2(1103,248)],
		[Vector2(1103,248),Vector2(1208,245),Vector2(1252,261),Vector2(1263,320),Vector2(1265,362),Vector2(1264,421),Vector2(1262,463),Vector2(1260,522),Vector2(1280,522)],
		[Vector2(1260,522),Vector2(1285,600),Vector2(1285,700),Vector2(1285,800),Vector2(1240,914),Vector2(1186,943)],
		[Vector2(680,780),Vector2(686,677),Vector2(686,580),Vector2(747,580),Vector2(747,550),Vector2(747,410),Vector2(843,410),Vector2(843,356),Vector2(843,313),Vector2(727,313),Vector2(727,300)],
		[Vector2(686,580),Vector2(612,574),Vector2(608,554),Vector2(600,505),Vector2(600,425),Vector2(588,410),Vector2(588,356),Vector2(588,280),Vector2(603,284)],
		[Vector2(747,410),Vector2(895,410),Vector2(895,503)],
		[Vector2(680,780),Vector2(580,690),Vector2(369,690),Vector2(313,705),Vector2(305,580)],
		[Vector2(840,760),Vector2(832,772)]
	],
	"forbidden":{"west roof":Vector2(316,300),"east roof":Vector2(1001,300),"shed roof":Vector2(167,424),"outhouse roof":Vector2(1125,130),"sea":Vector2(1370,700),"bedroom divider":Vector2(655,270),"living divider":Vector2(655,470),"bedroom wall":Vector2(495,355),"kitchen wall":Vector2(744,355),"closed fence":Vector2(940,847),"dining table":Vector2(823,470)},
	"wall_crossings":[[Vector2(600,270),Vector2(720,270)],[Vector2(600,420),Vector2(735,420)],[Vector2(500,315),Vector2(500,410)]]
}
]
