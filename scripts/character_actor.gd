extends Control
## Displays the chosen folklore character and switches to walk frames while moving.

const GameData = preload("res://scripts/game_data.gd")

# Existing walk cycles in folklore_cast.png. Each entry describes a row of
# equally spaced character frames in the original 1536x1024 artwork.
const WALK_ROWS := {
	"Puteri Gunung Ledang": {"x": 108.0, "y": 48.0, "width": 78.0, "height": 220.0, "step": 78.0, "count": 4},
	"Pak Kaduk": {"x": 540.0, "y": 48.0, "width": 72.0, "height": 220.0, "step": 73.0, "count": 3},
	"Badang": {"x": 895.0, "y": 48.0, "width": 76.0, "height": 220.0, "step": 75.0, "count": 3},
	"Mahsuri": {"x": 1282.0, "y": 48.0, "width": 78.0, "height": 220.0, "step": 78.0, "count": 3},
	"Pak Pandir": {"x": 120.0, "y": 485.0, "width": 78.0, "height": 190.0, "step": 82.0, "count": 4}
}

var _sprite: TextureRect
var _walk_frames: Array[Texture2D] = []
var _is_running := false
var _elapsed := 0.0
var _frame_index := 0
var _base_sprite_y := 0.0
var _name_label: Label


func _ready() -> void:
	_sprite = TextureRect.new()
	_sprite.name = "CharacterSprite"
	_sprite.position = Vector2(7, 0)
	_sprite.size = Vector2(66, 72)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	_base_sprite_y = _sprite.position.y
	_name_label = Label.new()
	_name_label.name = "PlayerName"
	_name_label.text = "YOU"
	_name_label.position = Vector2(0, -18)
	_name_label.size = Vector2(80, 18)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 10)
	_name_label.add_theme_color_override("font_color", GameData.CREAM)
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 2)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)


func configure(character: String, display_name: String = "YOU") -> void:
	_name_label.text = display_name
	_walk_frames.clear()
	_frame_index = 0
	if WALK_ROWS.has(character):
		var row: Dictionary = WALK_ROWS[character]
		var cast_sheet := load(GameData.CAST_ART) as Texture2D
		for frame_number in range(int(row["count"])):
			var frame := AtlasTexture.new()
			frame.atlas = cast_sheet
			frame.region = Rect2(
				float(row["x"]) + float(row["step"]) * frame_number,
				float(row["y"]),
				float(row["width"]),
				float(row["height"])
			)
			_walk_frames.append(frame)
		_sprite.texture = _walk_frames[0]
	elif GameData.CHARACTER_PORTRAITS.has(character):
		_sprite.texture = load(GameData.CHARACTER_PORTRAITS[character])


func set_running(running: bool) -> void:
	_is_running = running
	if not _is_running:
		_elapsed = 0.0
		_frame_index = 0
		if not _walk_frames.is_empty():
			_sprite.texture = _walk_frames[0]
		_sprite.position.y = _base_sprite_y
		_sprite.rotation = 0.0


func _process(delta: float) -> void:
	if not _is_running:
		return
	_elapsed += delta
	if not _walk_frames.is_empty():
		if _elapsed >= 0.12:
			_elapsed = 0.0
			_frame_index = (_frame_index + 1) % _walk_frames.size()
			_sprite.texture = _walk_frames[_frame_index]
		return
	# Some selectable characters have portrait art only, so keep those readable
	# while adding a small step bounce until matching walk frames are available.
	_sprite.position.y = _base_sprite_y + sin(_elapsed * 18.0) * 2.0
	_sprite.rotation = sin(_elapsed * 18.0) * 0.035
