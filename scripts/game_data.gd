extends RefCounted

## Shared immutable content and layout data for the game.
const MENU_ART := "res://assets/ui/main_menu.png"
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

const CHARACTER_PORTRAITS := {
	"Puteri Gunung Ledang": "res://assets/characters/portraits/puteri_gunung_ledang.png",
	"Pak Kaduk": "res://assets/characters/portraits/pak_kaduk.png",
	"Badang": "res://assets/characters/portraits/badang.png",
	"Mahsuri": "res://assets/characters/portraits/mahsuri.png",
	"Pak Pandir": "res://assets/characters/portraits/pak_pandir.png",
	"Bawang Putih": "res://assets/characters/portraits/bawang_putih.png",
	"Bawang Merah": "res://assets/characters/portraits/bawang_merah.png",
	"Raja Bersiung": "res://assets/characters/portraits/raja_bersiung.png",
	"Nenek Kebayan": "res://assets/characters/portraits/nenek_kebayan.png",
	"Orang Kampung Lelaki": "res://assets/characters/portraits/orang_kampung_lelaki.png",
	"Orang Kampung Perempuan": "res://assets/characters/portraits/orang_kampung_perempuan.png"
}

const CHARACTER_AVATARS := {
	"Puteri Gunung Ledang": "res://assets/characters/portraits/puteri_gunung_ledang_avatar.png",
	"Pak Kaduk": "res://assets/characters/portraits/pak_kaduk_avatar.png",
	"Badang": "res://assets/characters/portraits/badang_avatar.png",
	"Mahsuri": "res://assets/characters/portraits/mahsuri_avatar.png",
	"Pak Pandir": "res://assets/characters/portraits/pak_pandir_avatar.png",
	"Bawang Putih": "res://assets/characters/portraits/bawang_putih_avatar.png",
	"Bawang Merah": "res://assets/characters/portraits/bawang_merah_avatar.png",
	"Raja Bersiung": "res://assets/characters/portraits/raja_bersiung_avatar.png",
	"Nenek Kebayan": "res://assets/characters/portraits/nenek_kebayan_avatar.png",
	"Orang Kampung Lelaki": "res://assets/characters/portraits/orang_kampung_lelaki_avatar.png",
	"Orang Kampung Perempuan": "res://assets/characters/portraits/orang_kampung_perempuan_avatar.png"
}

const CHARACTER_CLUES := {
	"Puteri Gunung Ledang": ["Golden jewelry box", "Purple silk cloth", "Floral medallion"],
	"Pak Kaduk": ["Rooster feather", "Old playing cards", "Muddy footprints"],
	"Badang": ["Small monkey", "Headband cloth", "Scratched boulder"],
	"Mahsuri": ["White dove feather", "Torn handwritten letter", "Perfume bottle"],
	"Pak Pandir": ["Village frog", "Worn fishing net", "Small muddy footprints"],
	"Bawang Putih": ["Garlic bulb", "White handkerchief", "Flower-shaped locket"],
	"Bawang Merah": ["Red onion", "Red cloth", "Cracked mirror"],
	"Raja Bersiung": ["Fang", "Blood-stained cloth", "Carved crown"],
	"Nenek Kebayan": ["Old rattan basket", "Jasmine flower", "Delicate footprints"],
	"Orang Kampung Lelaki": ["Straw hat", "Wooden pipe", "Rice and vegetables"],
	"Orang Kampung Perempuan": ["Vegetable basket", "Floral batik handkerchief", "Muddy sandals"]
}

const MAPS := [
	{"name": "Istana Puteri Gunung Ledang", "description": "Explore palace halls and gardens\non the mountain path.", "region": Rect2(0, 0, 1420, 505)},
	{"name": "Rumah Pak Kaduk", "description": "Search the kampung yard and paddy field\nfor the rooster arena.", "region": Rect2(10, 515, 745, 440)},
	{"name": "Rumah Mahsuri", "description": "Follow village paths from Mahsuri's home\nto her garden.", "region": Rect2(780, 515, 748, 440)}
]

const TASKS := {
	"Rumah Mahsuri": [
		{"name":"Gather five story clues", "place":"Village path", "prompt":"Which item belongs in the evidence box?", "choices":["Torn letter", "Iron anchor", "Snow globe"], "answer":0},
		{"name":"Hear three village stories", "place":"Village elder", "prompt":"Which detail should you ask the villagers about?", "choices":["Mahsuri's story", "A space launch", "A desert caravan"], "answer":0},
		{"name":"Collect healer's medicine", "place":"Healer's house", "prompt":"Choose the healer's supplies.", "choices":["Herbal medicine", "Silver coins", "A royal crown"], "answer":0},
		{"name":"Deliver medicine to the family", "place":"Mahsuri's house", "prompt":"Who needs the medicine delivery?", "choices":["Mahsuri's family", "The palace guards", "The rooster"], "answer":0},
		{"name":"Collect six white flowers", "place":"Flower garden", "prompt":"Which flowers belong at the tomb?", "choices":["White jasmine", "Red hibiscus", "Blue orchids"], "answer":0},
		{"name":"Match belongings to their owners", "place":"Gathering hall", "prompt":"Match the misplaced letter to its owner.", "choices":["Mahsuri", "Badang", "Pak Kaduk"], "answer":0},
		{"name":"Find the key and unlock the chest", "place":"Storage room", "prompt":"The small brass key fits which object?", "choices":["Locked chest", "Garden gate", "Water well"], "answer":0},
		{"name":"Place flowers at Mahsuri's tomb", "place":"Mahsuri's tomb", "prompt":"Complete the remembrance ritual.", "choices":["Lay down the flowers", "Take the flowers home", "Hide the flowers"], "answer":0}
	],
	"Rumah Pak Kaduk": [
		{"name":"Find five food pieces", "place":"Village yard", "prompt":"Choose food for the rooster.", "choices":["Grain", "A glass marble", "A flower pot"], "answer":0},
		{"name":"Feed Pak Kaduk's rooster", "place":"Chicken coop", "prompt":"What should you give the rooster?", "choices":["The grain you collected", "A playing card", "A lantern"], "answer":0},
		{"name":"Find three clothing repair items", "place":"House storage", "prompt":"Choose a useful repair item.", "choices":["Thread and cloth", "A cooking pot", "A compass"], "answer":0},
		{"name":"Repair Pak Kaduk's clothes", "place":"Main house", "prompt":"Where does this cloth patch belong?", "choices":["The torn sleeve", "The roof", "The chicken coop"], "answer":0},
		{"name":"Collect five rooster feathers", "place":"Paddy path", "prompt":"Follow the feather trail.", "choices":["Feather by the paddy", "Shell by the river", "Leaf by the gate"], "answer":0},
		{"name":"Find the rooster at the arena", "place":"Competition arena", "prompt":"Listen for the rooster near the arena.", "choices":["Call the rooster", "Ring the palace bell", "Open the tomb"], "answer":0},
		{"name":"Complete the arena timing challenge", "place":"Arena gate", "prompt":"Pick the steady moment to enter.", "choices":["When the marker reaches the center", "Before the count begins", "After the arena closes"], "answer":0},
		{"name":"Collect the scattered arena coins", "place":"Arena floor", "prompt":"Gather the coins left after the competition.", "choices":["Pick up the coins", "Leave the arena", "Give them to the rooster"], "answer":0}
	],
	"Istana Puteri Gunung Ledang": [
		{"name":"Find five route markers", "place":"Palace garden", "prompt":"Which marker points toward the mountain?", "choices":["The carved trail marker", "A kitchen spoon", "A playing card"], "answer":0},
		{"name":"Gather food and water", "place":"Palace kitchen", "prompt":"Choose a travel supply.", "choices":["Food and water", "A silk curtain", "An empty chest"], "answer":0},
		{"name":"Navigate the forest crossroads", "place":"Forest crossing", "prompt":"Follow the marked path at the fork.", "choices":["Take the marked mountain trail", "Walk into the river", "Return to the kitchen"], "answer":0},
		{"name":"Find seven golden trays", "place":"Royal hall", "prompt":"Which tray is part of the royal request?", "choices":["Golden serving tray", "Wooden fishing net", "Clay flower pot"], "answer":0},
		{"name":"Catch seven glowing fireflies", "place":"Lantern garden", "prompt":"Tap the firefly while it glows.", "choices":["Catch the glowing firefly", "Chase the shadow", "Wait for sunrise"], "answer":0},
		{"name":"Collect the requested symbolic materials", "place":"Princess's chamber", "prompt":"Which object is one of the Princess's symbols?", "choices":["Floral medallion", "Iron shovel", "Fishing basket"], "answer":0},
		{"name":"Deliver the proposal letter", "place":"Sultan's camp", "prompt":"Take the letter to the meeting place.", "choices":["Deliver the sealed letter", "Leave it in the forest", "Give it to the cook"], "answer":0},
		{"name":"Follow the markers to the Princess", "place":"Mountain overlook", "prompt":"Complete the final conversation.", "choices":["Speak with Puteri Gunung Ledang", "Return to the arena", "Hide the route markers"], "answer":0}
	]
}

const TASK_POINTS := [Vector2(370, 235), Vector2(530, 235), Vector2(880, 245), Vector2(1050, 370), Vector2(880, 530), Vector2(625, 555), Vector2(350, 520), Vector2(340, 390)]
const TASK_STEPS := {
	"Rumah Mahsuri": [5, 3, 1, 1, 6, 3, 1, 1],
	"Rumah Pak Kaduk": [5, 1, 3, 1, 5, 1, 1, 1],
	"Istana Puteri Gunung Ledang": [5, 1, 1, 7, 7, 1, 1, 1]
}
const NPC_NAMES := ["Pak Pandir", "Bawang Putih", "Badang", "Mahsuri"]
const NPC_POINTS := [Vector2(430, 330), Vector2(760, 300), Vector2(990, 475), Vector2(520, 460)]
