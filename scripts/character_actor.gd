extends Control
## Directional frame animation shared by local players, remote players and NPCs.
const GameData = preload("res://scripts/game_data.gd")

var _sprite: TextureRect
var _name_label: Label
var _animations: SpriteFrames
var _is_running := false
var _sleeping := false
var _elapsed := 0.0
var _frame_index := 0
var _facing_mode := "front"
var _base_sprite_y := 0.0
var _character := ""


func _ready() -> void:
	_sprite = TextureRect.new()
	_sprite.name = "CharacterSprite"
	_sprite.position = Vector2(7, 0)
	_sprite.size = Vector2(66, 72)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	_name_label = Label.new()
	_name_label.name = "PlayerName"
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
	_character = character
	_name_label.text = display_name
	_animations = null
	_is_running = false
	_sleeping = false
	_elapsed = 0.0
	_frame_index = 0
	_facing_mode = "front"
	_sprite.scale = Vector2.ONE
	_sprite.flip_h = false
	_sprite.rotation = 0.0
	_sprite.modulate = Color.WHITE
	_sprite.material = null
	_sprite.texture = null
	if GameData.CHARACTER_ANIMATIONS.has(character):
		_animations = load(GameData.CHARACTER_ANIMATIONS[character]) as SpriteFrames
	if _animations != null:
		_sprite.texture = _animations.get_frame_texture(&"front_idle", 0)
	elif GameData.CHARACTER_PORTRAITS.has(character):
		_sprite.texture = load(GameData.CHARACTER_PORTRAITS[character]) as Texture2D
	if _sprite.texture != null:
		var aspect := _sprite.texture.get_width() / float(maxi(1, _sprite.texture.get_height()))
		_sprite.size = Vector2(72.0 * aspect, 72.0)
		_sprite.position = Vector2((80.0 - _sprite.size.x) * 0.5, _base_sprite_y)
	_sprite.pivot_offset = Vector2(_sprite.size.x * 0.5, 60)
	_apply_frame()


func set_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.01 or _sleeping: return
	if absf(direction.y) > absf(direction.x):
		_facing_mode = "back" if direction.y < 0 else "front"
		_sprite.flip_h = false
	else:
		_facing_mode = "side"
		_sprite.flip_h = direction.x < 0
	_apply_frame()


func set_running(running: bool) -> void:
	if _sleeping or _is_running == running: return
	_is_running = running
	_elapsed = 0.0
	_frame_index = 0
	_apply_frame()


func set_sleeping(value: bool) -> void:
	_sleeping = value
	_is_running = false
	_elapsed = 0.0
	_frame_index = 0
	_apply_frame()
	_sprite.rotation = deg_to_rad(-65.0) if value else 0.0
	_sprite.position.y = _base_sprite_y + (24.0 if value else 0.0)
	_sprite.modulate = Color("c0d2e8") if value else Color.WHITE


func _animation_name() -> StringName:
	return StringName(_facing_mode + ("_walk" if _is_running and not _sleeping else "_idle"))


func _apply_frame() -> void:
	if _animations == null: return
	var animation := _animation_name()
	var count := _animations.get_frame_count(animation)
	if count > 0:
		_sprite.texture = _animations.get_frame_texture(animation, _frame_index % count)


func _process(delta: float) -> void:
	if _sleeping or not _is_running or _animations == null: return
	var animation := _animation_name()
	var fps := _animations.get_animation_speed(animation)
	if fps <= 0.0: return
	_elapsed += delta
	var steps := floori(_elapsed * fps + 0.00001)
	if steps > 0:
		_elapsed = maxf(0.0, _elapsed - steps / fps)
		_frame_index = (_frame_index + steps) % _animations.get_frame_count(animation)
		_apply_frame()
