extends RefCounted

## Shared immutable content and layout data for the game.
const GAME_TITLE := "Nenek Kebayan: Siapa Pengkhianat?"
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
	"Puteri Gunung Ledang": ["Peti emas", "Kain sutera ungu", "Loket bermotif bunga"],
	"Pak Kaduk": ["Bulu ayam", "Kad permainan lama", "Jejak kaki berlumpur"],
	"Badang": ["Monyet kecil", "Kain ikat kepala", "Batu besar bercalar"],
	"Mahsuri": ["Bulu merpati putih", "Surat koyak", "Botol minyak wangi"],
	"Pak Pandir": ["Katak kampung", "Jala usang", "Jejak kaki kecil berlumpur"],
	"Bawang Putih": ["Bawang putih", "Sapu tangan putih", "Loket berbentuk bunga"],
	"Bawang Merah": ["Bawang merah", "Kain merah", "Cermin retak"],
	"Raja Bersiung": ["Taring", "Kain berlumuran darah", "Mahkota berukir"],
	"Nenek Kebayan": ["Bakul rotan lama", "Bunga melur", "Jejak kaki halus"],
	"Orang Kampung Lelaki": ["Topi mengkuang", "Pipa kayu", "Beras dan sayur"],
	"Orang Kampung Perempuan": ["Bakul sayur", "Sapu tangan batik bunga", "Selipar berlumpur"]
}

const MAPS := [
	{"name": "Istana Puteri Gunung Ledang", "description": "Explore palace halls and gardens\non the mountain path.", "region": Rect2(0, 0, 1420, 505)},
	{"name": "Rumah Pak Kaduk", "description": "Search the kampung yard and paddy field\nfor the rooster arena.", "region": Rect2(10, 515, 745, 440)},
	{"name": "Rumah Mahsuri", "description": "Follow village paths from Mahsuri's home\nto her garden.", "region": Rect2(780, 515, 748, 440)}
]

const TASKS := {
	"Rumah Mahsuri": [
		{"name":"Cari 5 petunjuk di sekitar kampung", "place":"Jalan kampung", "prompt":"Cari dan kutip petunjuk yang bertaburan di sekitar kampung.", "minigame":"collect", "items":["Surat Mahsuri", "Bulu merpati", "Botol minyak wangi", "Kain batik", "Loket bunga"]},
		{"name":"Bercakap dengan 3 orang penduduk", "place":"Balai kampung", "prompt":"Berbual dengan penduduk untuk mengumpulkan kisah tentang Mahsuri.", "minigame":"talk", "people":["Pak Pandir", "Bawang Putih", "Badang"]},
		{"name":"Ambil bekalan ubat dari rumah tabib", "place":"Rumah tabib", "prompt":"Ambil bekalan ubat tradisional daripada tabib.", "minigame":"collect", "items":["Bekalan ubat"]},
		{"name":"Hantar ubat kepada keluarga Mahsuri", "place":"Rumah Mahsuri", "prompt":"Seret bungkusan ubat kepada keluarga Mahsuri.", "minigame":"drag", "drag_from":"Bungkusan ubat", "drag_to":"Keluarga Mahsuri", "drag_id":"ubat"},
		{"name":"Cari dan kutip 6 bunga putih", "place":"Taman bunga", "prompt":"Kutip bunga putih yang tumbuh di sekitar kampung.", "minigame":"collect", "items":["Bunga putih", "Bunga melur", "Bunga tanjung", "Bunga cempaka", "Bunga kenanga", "Bunga raya putih"]},
		{"name":"Padankan barang dengan pemiliknya", "place":"Balai perhimpunan", "prompt":"Seret setiap barang kepada pemilik yang betul.", "minigame":"matching", "pairs":[{"id":"surat","item":"Surat koyak","owner":"Mahsuri"},{"id":"batu","item":"Batu bercalar","owner":"Badang"},{"id":"kad","item":"Kad lama","owner":"Pak Kaduk"}], "owners":["Mahsuri", "Badang", "Pak Kaduk"]},
		{"name":"Buka peti berkunci", "place":"Stor simpanan", "prompt":"Cari kunci di kawasan berhampiran, kemudian buka peti.", "minigame":"search_key", "drag_from":"Kunci peti", "drag_to":"Peti berkunci", "drag_id":"kunci"},
		{"name":"Letakkan bunga di makam Mahsuri", "place":"Makam Mahsuri", "prompt":"Seret bunga ke makam Mahsuri untuk melengkapkan misi.", "minigame":"drag", "drag_from":"Bunga putih", "drag_to":"Makam Mahsuri", "drag_id":"bunga"}
	],
	"Rumah Pak Kaduk": [
		{"name":"Cari 5 cebisan makanan untuk ayam Pak Kaduk", "place":"Laman kampung", "prompt":"Cari dan kutip cebisan makanan yang bertaburan.", "minigame":"collect", "items":["Beras", "Jagung", "Padi", "Dedak", "Kacang"]},
		{"name":"Beri makan ayam Pak Kaduk", "place":"Kandang ayam", "prompt":"Tekan butang interaksi untuk memberi makanan kepada ayam.", "minigame":"interact", "interact_caption":"Bekas makanan sudah tersedia. Tekan untuk memberi makan ayam.", "interact_label":"BERI MAKAN AYAM"},
		{"name":"Cari 3 barang untuk membaiki baju", "place":"Stor rumah", "prompt":"Kutip barang jahitan yang diperlukan.", "minigame":"collect", "items":["Benang", "Jarum", "Cebisan kain"]},
		{"name":"Baiki baju Pak Kaduk", "place":"Rumah utama", "prompt":"Seret cebisan kain ke bahagian baju yang koyak.", "minigame":"drag", "drag_from":"Cebisan kain", "drag_to":"Bahagian baju koyak", "drag_id":"kain"},
		{"name":"Ikut jejak ayam dengan mengutip 5 bulu", "place":"Laluan bendang", "prompt":"Kutip bulu ayam untuk menjejaki laluannya.", "minigame":"collect", "items":["Bulu ayam", "Bulu ayam", "Bulu ayam", "Bulu ayam", "Bulu ayam"]},
		{"name":"Cari ayam Pak Kaduk di sekitar gelanggang", "place":"Gelanggang pertandingan", "prompt":"Periksa kawasan gelanggang dan cari ayam Pak Kaduk.", "minigame":"find_rooster"},
		{"name":"Sertai cabaran masa di gelanggang", "place":"Pintu gelanggang", "prompt":"Tekan apabila penanda berada di zon hijau.", "minigame":"timing"},
		{"name":"Kutip syiling selepas pertandingan", "place":"Lantai gelanggang", "prompt":"Kutip syiling yang bertaburan di gelanggang.", "minigame":"collect", "items":["Syiling emas", "Syiling perak", "Syiling tembaga", "Syiling emas", "Syiling perak"]}
	],
	"Istana Puteri Gunung Ledang": [
		{"name":"Cari 5 penanda laluan ke kaki gunung", "place":"Taman istana", "prompt":"Cari dan kutip penanda laluan untuk membuka jalan ke kaki gunung.", "minigame":"collect", "items":["Penanda kayu", "Pita merah", "Batu tanda", "Bendera kecil", "Ukiran laluan"]},
		{"name":"Kumpulkan bekalan perjalanan", "place":"Dapur istana", "prompt":"Ambil air dan makanan untuk perjalanan.", "minigame":"supplies", "items":["Bekas air", "Bungkusan makanan"]},
		{"name":"Cari jalan di persimpangan hutan", "place":"Persimpangan hutan", "prompt":"Ikut turutan penanda untuk mencari jalan yang betul.", "minigame":"route", "route":["↑", "→", "↑"]},
		{"name":"Cari 7 dulang emas", "place":"Balai diraja", "prompt":"Cari dulang emas di lokasi yang ditandakan pada peta.", "minigame":"collect", "items":["Dulang emas", "Dulang emas", "Dulang emas", "Dulang emas", "Dulang emas", "Dulang emas", "Dulang emas"]},
		{"name":"Tangkap 7 ikon hati nyamuk", "place":"Taman tanglung", "prompt":"Tekan ketika ikon berada di zon hijau untuk menangkapnya.", "minigame":"timing"},
		{"name":"Kumpul bahan simbolik untuk Puteri", "place":"Bilik Puteri", "prompt":"Kutip bahan simbolik yang diperlukan Puteri.", "minigame":"collect", "items":["Bunga melur", "Kain sutera", "Loket bunga"]},
		{"name":"Bawa surat pinangan ke kawasan pertemuan", "place":"Kem Sultan", "prompt":"Seret surat pinangan dari kem Sultan ke kawasan pertemuan.", "minigame":"drag", "drag_from":"Surat pinangan", "drag_to":"Kawasan pertemuan", "drag_id":"surat"},
		{"name":"Temui Puteri dan selesaikan perbualan", "place":"Puncak gunung", "prompt":"Ikut penanda ke lokasi Puteri, kemudian berbual dengannya.", "minigame":"final_route"}
	]
}

const TASK_POINTS := [Vector2(370, 235), Vector2(530, 235), Vector2(880, 245), Vector2(1050, 370), Vector2(880, 530), Vector2(625, 555), Vector2(350, 520), Vector2(340, 390)]
const TASK_STEPS := {
	"Rumah Mahsuri": [5, 3, 1, 1, 6, 3, 1, 1],
	"Rumah Pak Kaduk": [5, 1, 3, 1, 5, 1, 1, 1],
	"Istana Puteri Gunung Ledang": [5, 1, 1, 7, 7, 3, 1, 1]
}
const NPC_NAMES := ["Pak Pandir", "Bawang Putih", "Badang", "Mahsuri"]
const NPC_POINTS := [Vector2(430, 330), Vector2(760, 300), Vector2(990, 475), Vector2(520, 460)]
