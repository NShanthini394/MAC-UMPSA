extends Control
## Displays the chosen folklore character and switches to walk frames while moving.

const GameData = preload("res://scripts/game_data.gd")

# Existing walk cycles in folklore_cast.png. Each entry describes a row of
# equally spaced character frames in the original 1536x1024 artwork.
const WALK_ROWS := {
	"Puteri Gunung Ledang": {"x": 124.0, "y": 88.0, "width": 68.0, "height": 178.0, "step": 68.0, "count": 4},
	"Pak Kaduk": {"x": 554.0, "y": 114.0, "width": 64.0, "height": 154.0, "step": 70.0, "count": 3},
	"Badang": {"x": 906.0, "y": 112.0, "width": 68.0, "height": 164.0, "step": 70.0, "count": 3},
	"Mahsuri": {"x": 1302.0, "y": 122.0, "width": 66.0, "height": 168.0, "step": 66.0, "count": 3},
	"Pak Pandir": {"x": 116.0, "y": 490.0, "width": 70.0, "height": 180.0, "step": 72.0, "count": 4},
	"Bawang Merah": {"sheet": "res://assets/characters/walk/bawang_merah_walk.png", "x": 0.0, "y": 0.0, "width": 180.0, "height": 200.0, "step": 180.0, "count": 3}
}

const BACK_VIEW_TEXTURES := {
	"Puteri Gunung Ledang": "res://assets/characters/back/puteri_gunung_ledang_back.png",
	"Pak Kaduk": "res://assets/characters/back/pak_kaduk_back.png",
	"Badang": "res://assets/characters/back/badang_back.png",
	"Mahsuri": "res://assets/characters/back/mahsuri_back.png",
	"Raja Bersiung": "res://assets/characters/back/raja_bersiung_back.png",
	"Orang Kampung Lelaki": "res://assets/characters/back/orang_kampung_lelaki_back.png",
	"Orang Kampung Perempuan": "res://assets/characters/back/orang_kampung_perempuan_back.png",
	"Bawang Merah": "res://assets/characters/back/bawang_merah_back.png"
}

const FALLBACK_WALK_SHADER := """
shader_type canvas_item;
uniform float walk_phase = 0.0;
uniform bool walking = false;
void fragment() {
	vec2 sample_uv = UV;
	if (walking && UV.y > 0.66) {
		float side = UV.x < 0.5 ? 1.0 : -1.0;
		float stride = sin(walk_phase) * 0.022 * side * smoothstep(0.66, 0.84, UV.y);
		sample_uv.x += stride;
	}
	COLOR = texture(TEXTURE, sample_uv) * COLOR;
}
"""

var _sprite: TextureRect
var _walk_frames: Array[Texture2D] = []
var _front_texture: Texture2D
var _back_texture: Texture2D
var _is_running := false
var _sleeping := false
var _elapsed := 0.0
var _frame_index := 0
var _base_sprite_y := 0.0
var _name_label: Label
var _fallback_walk_material: ShaderMaterial
var _facing_mode := "side"


func _ready() -> void:
	_sprite = TextureRect.new()
	_sprite.name = "CharacterSprite"
	_sprite.position = Vector2(7, 0)
	_sprite.size = Vector2(66, 72)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback_walk_material = ShaderMaterial.new()
	var walk_shader := Shader.new()
	walk_shader.code = FALLBACK_WALK_SHADER
	_fallback_walk_material.shader = walk_shader
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
	_front_texture = null
	_back_texture = null
	_frame_index = 0
	_facing_mode = "side"
	_sprite.scale = Vector2.ONE
	_sprite.position.x = 7.0
	if BACK_VIEW_TEXTURES.has(character):
		_back_texture = load(BACK_VIEW_TEXTURES[character]) as Texture2D
	if WALK_ROWS.has(character):
		var row: Dictionary = WALK_ROWS[character]
		var cast_sheet := load(str(row.get("sheet", GameData.CAST_ART))) as Texture2D
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
		_front_texture = _walk_frames[0]
		_sprite.texture = _front_texture
		_sprite.material = null
	elif GameData.CHARACTER_PORTRAITS.has(character):
		_front_texture = load(GameData.CHARACTER_PORTRAITS[character]) as Texture2D
		_sprite.texture = _front_texture
		_sprite.material = _fallback_walk_material
	set_running(false)


func set_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.01:
		return
	if direction.y < -absf(direction.x) * 0.65 and _back_texture:
		_facing_mode = "back"
		_sprite.texture = _back_texture
		_sprite.material = null
		_sprite.scale = Vector2.ONE
		_sprite.position.x = 7.0
	elif absf(direction.x) > absf(direction.y) * 0.65:
		_facing_mode = "side"
		if not _walk_frames.is_empty():
			_sprite.texture = _walk_frames[_frame_index]
			_sprite.material = null
		elif _front_texture:
			_sprite.texture = _front_texture
			_sprite.material = _fallback_walk_material
		if direction.x < 0.0:
			_sprite.scale = Vector2(-1, 1)
			_sprite.position.x = 73.0
		else:
			_sprite.scale = Vector2.ONE
			_sprite.position.x = 7.0
	else:
		# The available walk sheets have rear art but no matching front-walk set;
		# use the clean first walking frame when moving toward the camera.
		_facing_mode = "front"
		if not _walk_frames.is_empty():
			_sprite.texture = _walk_frames[0]
			_sprite.material = null
		elif _front_texture:
			_sprite.texture = _front_texture
			_sprite.material = _fallback_walk_material
		_sprite.scale = Vector2.ONE
		_sprite.position.x = 7.0


func set_running(running: bool) -> void:
	if _sleeping: return
	_is_running = running
	if not _is_running:
		_elapsed = 0.0
		_frame_index = 0
		if _facing_mode == "back" and _back_texture:
			_sprite.texture = _back_texture
		elif _front_texture:
			_sprite.texture = _front_texture
		elif not _walk_frames.is_empty():
			_sprite.texture = _walk_frames[0]
		_sprite.position.y = _base_sprite_y
		_sprite.rotation = 0.0
		if _fallback_walk_material:
			_fallback_walk_material.set_shader_parameter("walking", false)


func set_sleeping(value: bool) -> void:
	_sleeping = false
	set_running(false)
	_sleeping = value
	_sprite.pivot_offset = Vector2(33, 60)
	_sprite.rotation = deg_to_rad(-65.0) if value else 0.0
	_sprite.position.y = _base_sprite_y + (24.0 if value else 0.0)
	_sprite.modulate = Color("c0d2e8") if value else Color.WHITE


func _process(delta: float) -> void:
	if _sleeping: return
	if not _is_running:
		return
	_elapsed += delta
	if _facing_mode == "back" and _back_texture:
		_sprite.position.y = _base_sprite_y + absf(sin(_elapsed * 12.0)) * 1.0
		return
	if not _walk_frames.is_empty():
		if _elapsed >= 0.15:
			_elapsed = 0.0
			_frame_index = (_frame_index + 1) % _walk_frames.size()
			_sprite.texture = _walk_frames[_frame_index]
		return
	# Some selectable characters have portrait art only, so keep those readable
	# while shifting the lower half in alternating steps until matching frames exist.
	_fallback_walk_material.set_shader_parameter("walking", true)
	_fallback_walk_material.set_shader_parameter("walk_phase", _elapsed * 12.0)
	_sprite.position.y = _base_sprite_y + absf(sin(_elapsed * 12.0)) * 1.5
	_sprite.rotation = sin(_elapsed * 12.0) * 0.018
