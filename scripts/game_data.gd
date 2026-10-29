extends RefCounted

## Shared immutable content and layout data for the game.
const GAME_TITLE := "Nenek Kebayan: Siapa Pengkhianat?"
const MENU_ART := "res://assets/ui/main_menu_no_center_settings.png"
const WAITING_ROOM_ART := "res://assets/ui/waiting_room.png"
const MAP_ART := "res://assets/maps/palace_village_maps.png"
const CAST_ART := "res://assets/characters/folklore_cast.png"
const INK := Color("21170f")
const CREAM := Color("fff0cf")
const GOLD := Color("f7c35a")
const PANEL := Color("241b18", 0.94)

const CHARACTERS := [
	"Puteri Gunung Ledang", "Pak Kaduk", "Badang", "Mahsuri", "Pak Pandir",
	"Bawang Putih", "Bawang Merah", "Raja Bersiung",
	"Orang Kampung Lelaki", "Orang Kampung Perempuan"
]

const MAP_CHARACTERS := {
	"Istana Puteri Gunung Ledang": ["Puteri Gunung Ledang", "Pak Kaduk", "Badang", "Mahsuri", "Raja Bersiung", "Orang Kampung Lelaki", "Orang Kampung Perempuan"],
	"Rumah Pak Kaduk": ["Pak Kaduk", "Pak Pandir", "Badang", "Bawang Putih", "Bawang Merah", "Orang Kampung Lelaki", "Orang Kampung Perempuan"],
	"Rumah Mahsuri": ["Mahsuri", "Puteri Gunung Ledang", "Pak Pandir", "Bawang Putih", "Bawang Merah", "Orang Kampung Lelaki", "Orang Kampung Perempuan"]
}

const CHARACTER_ANIMATIONS := {
	"Puteri Gunung Ledang": "res://assets/characters/animated/puteri_gunung_ledang.tres",
	"Pak Kaduk": "res://assets/characters/animated/pak_kaduk.tres",
	"Badang": "res://assets/characters/animated/badang.tres",
	"Mahsuri": "res://assets/characters/animated/mahsuri.tres",
	"Pak Pandir": "res://assets/characters/animated/pak_pandir.tres",
	"Bawang Putih": "res://assets/characters/animated/bawang_putih.tres",
	"Bawang Merah": "res://assets/characters/animated/bawang_merah.tres",
	"Raja Bersiung": "res://assets/characters/animated/raja_bersiung.tres",
	"Orang Kampung Lelaki": "res://assets/characters/animated/orang_kampung_lelaki.tres",
	"Orang Kampung Perempuan": "res://assets/characters/animated/orang_kampung_perempuan.tres"
}

const CHARACTER_PORTRAITS := {
	"Puteri Gunung Ledang": "res://assets/characters/animated/puteri_gunung_ledang_portrait.tres",
	"Pak Kaduk": "res://assets/characters/animated/pak_kaduk_portrait.tres",
	"Badang": "res://assets/characters/animated/badang_portrait.tres",
	"Mahsuri": "res://assets/characters/animated/mahsuri_portrait.tres",
	"Pak Pandir": "res://assets/characters/animated/pak_pandir_portrait.tres",
	"Bawang Putih": "res://assets/characters/animated/bawang_putih_portrait.tres",
	"Bawang Merah": "res://assets/characters/animated/bawang_merah_portrait.tres",
	"Raja Bersiung": "res://assets/characters/animated/raja_bersiung_portrait.tres",
	"Nenek Kebayan": "res://assets/characters/portraits/nenek_kebayan.png",
	"Orang Kampung Lelaki": "res://assets/characters/animated/orang_kampung_lelaki_portrait.tres",
	"Orang Kampung Perempuan": "res://assets/characters/animated/orang_kampung_perempuan_portrait.tres"
}

const CHARACTER_AVATARS := {
	"Puteri Gunung Ledang": "res://assets/characters/animated/puteri_gunung_ledang_avatar.tres",
	"Pak Kaduk": "res://assets/characters/animated/pak_kaduk_avatar.tres",
	"Badang": "res://assets/characters/animated/badang_avatar.tres",
	"Mahsuri": "res://assets/characters/animated/mahsuri_avatar.tres",
	"Pak Pandir": "res://assets/characters/animated/pak_pandir_avatar.tres",
	"Bawang Putih": "res://assets/characters/animated/bawang_putih_avatar.tres",
	"Bawang Merah": "res://assets/characters/animated/bawang_merah_avatar.tres",
	"Raja Bersiung": "res://assets/characters/animated/raja_bersiung_avatar.tres",
	"Nenek Kebayan": "res://assets/characters/portraits/nenek_kebayan_avatar.png",
	"Orang Kampung Lelaki": "res://assets/characters/animated/orang_kampung_lelaki_avatar.tres",
	"Orang Kampung Perempuan": "res://assets/characters/animated/orang_kampung_perempuan_avatar.tres"
}

const CHARACTER_CLUES := {
	"Puteri Gunung Ledang": ["Gold chest", "Purple silk cloth", "Floral pendant"],
	"Pak Kaduk": ["Rooster feather", "Old playing card", "Muddy footprints"],
	"Badang": ["Small monkey", "Headband", "Scratched boulder"],
	"Mahsuri": ["White dove feather", "Torn letter", "Perfume bottle"],
	"Pak Pandir": ["Village frog", "Worn fishing net", "Small muddy footprints"],
	"Bawang Putih": ["Garlic", "White handkerchief", "Flower-shaped pendant"],
	"Bawang Merah": ["Shallot", "Red cloth", "Cracked mirror"],
	"Raja Bersiung": ["Fang", "Bloodstained cloth", "Carved crown"],
	"Nenek Kebayan": ["Old rattan basket", "Jasmine flower", "Delicate footprints"],
	"Orang Kampung Lelaki": ["Woven hat", "Wooden pipe", "Rice and vegetables"],
	"Orang Kampung Perempuan": ["Vegetable basket", "Floral batik handkerchief", "Muddy slippers"]
}

const MAPS := [
	{"name": "Istana Puteri Gunung Ledang", "description": "Explore the throne hall, palace rooms\nand gardens through marked entrances.", "art":"res://assets/maps/istana_puteri_gunung_ledang.png", "region": Rect2(0, 0, 2172, 724)},
	{"name": "Rumah Pak Kaduk", "description": "Explore the wooden homestead,\nchicken yard and vegetable garden.", "art":"res://assets/maps/rumah_pak_kaduk.png", "region": Rect2(0, 0, 1448, 1086)},
	{"name": "Rumah Mahsuri", "description": "Follow the coastal house stairways,\nsandy paths and wooden piers.", "art":"res://assets/maps/rumah_mahsuri.png", "region": Rect2(0, 0, 1448, 1086)}
]


static func map_art_path(map_index: int) -> String:
	return str(MAPS[clampi(map_index, 0, 2)]["art"])

const COMMON_TASKS := [
    {"name":"Cook rice", "place":"Kitchen", "prompt":"Add rice and water to the pot, then lift it when the rice is cooked.", "minigame":"rice"},
    {"name":"Light a wood fire", "place":"Fire pit", "prompt":"Arrange the twigs and logs, then strike the flint to light the fire.", "minigame":"fire"},
    {"name":"Sweep the floor", "place":"Indoor area", "prompt":"Sweep through the piles of dirt until the floor is clean.", "minigame":"sweep"},
    {"name":"Hang the laundry", "place":"Clothesline", "prompt":"Drag each cloth to its matching place on the clothesline.", "minigame":"laundry"},
    {"name":"Find the flowers", "place":"Garden", "prompt":"Find five flowers hidden among the leaves.", "minigame":"flowers"},
    {"name":"Shoot marbles into the circle", "place":"Play area", "prompt":"Pull each marble back and release it. All four marbles must stop fully inside the circle.", "minigame":"marbles"},
    {"name":"Repair the lamp", "place":"Lamp", "prompt":"Connect the wires with matching colours and letters.", "minigame":"lamp"},
    {"name":"Arrange the shoes", "place":"Entrance", "prompt":"Match the footwear by colour to make four pairs: blue, yellow, red and green.", "minigame":"slippers"}
]
const TASKS := {
    "Istana Puteri Gunung Ledang": COMMON_TASKS,
    "Rumah Pak Kaduk": COMMON_TASKS,
    "Rumah Mahsuri": COMMON_TASKS
}
const TASK_POINTS := [Vector2(580,382),Vector2(1805,435),Vector2(990,236),Vector2(1360,279),Vector2(240,280),Vector2(709,267),Vector2(1340,414),Vector2(850,401)]
const COMMON_TASK_STEPS := [3,3,5,4,5,4,3,4]
const TASK_STEPS := {
    "Istana Puteri Gunung Ledang": COMMON_TASK_STEPS,
    "Rumah Pak Kaduk": COMMON_TASK_STEPS,
    "Rumah Mahsuri": COMMON_TASK_STEPS
}
const NPC_NAMES := ["Pak Pandir", "Bawang Putih", "Badang", "Mahsuri"]
const NPC_POINTS := [Vector2(430, 330), Vector2(760, 300), Vector2(990, 475), Vector2(520, 460)]
