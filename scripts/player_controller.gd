extends CharacterBody2D
## Physics-based player actor used by offline practice and online room views.

const MapGeometry = preload("res://scripts/map_geometry.gd")

@export var move_speed := 250.0
@export var map_index := 0
var locked_entrances: Array = []
var sleeping := false
var inactive := false
var _sleep_badge: Label

var is_local_player := true
var is_network_driven := false
var _move_direction := Vector2.ZERO
var _network_target := Vector2.ZERO
var _has_network_target := false

@onready var character_actor: Control = $CharacterActor
@onready var follow_camera: Camera2D = $Camera2D


func configure(character: String, player_name: String, local_player: bool, network_driven: bool = false) -> void:
	is_local_player = local_player
	is_network_driven = network_driven
	if is_node_ready():
		character_actor.call("configure", character, player_name)
		follow_camera.enabled = local_player
		set_physics_process(local_player and not network_driven)
		set_process(network_driven)


func set_input_direction(direction: Vector2) -> void:
	_move_direction = Vector2.ZERO if inactive else direction.limit_length(1.0)


func set_sleeping(value: bool, animate: bool = false) -> void:
	if sleeping == value: return
	sleeping = value
	if sleeping:
		_move_direction = Vector2.ZERO
		velocity = Vector2.ZERO
		if _has_network_target: global_position = _network_target
	character_actor.call("set_sleeping", sleeping, animate)
	if _sleep_badge == null:
		_sleep_badge = Label.new()
		_sleep_badge.text = "Z z z"
		_sleep_badge.position = Vector2(-23, -120)
		_sleep_badge.add_theme_font_size_override("font_size", 18)
		_sleep_badge.add_theme_color_override("font_color", Color("b8ddff"))
		_sleep_badge.add_theme_color_override("font_shadow_color", Color.BLACK)
		_sleep_badge.add_theme_constant_override("shadow_offset_x", 2)
		_sleep_badge.add_theme_constant_override("shadow_offset_y", 2)
		_sleep_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_material := CanvasItemMaterial.new()
		badge_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_sleep_badge.material = badge_material
		add_child(_sleep_badge)
	_sleep_badge.visible = sleeping
	if animate and sleeping:
		_sleep_badge.modulate.a = 0.0
		var badge_tween := create_tween()
		badge_tween.tween_property(_sleep_badge, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_sleep_badge.modulate.a = 1.0


func play_sleep_spell_blow(direction: Vector2) -> void:
	character_actor.call("play_sleep_spell_blow", direction)


func set_network_target(target: Vector2) -> void:
	_network_target = target
	_has_network_target = true


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_network_target = global_position
	follow_camera.enabled = is_local_player
	set_physics_process(is_local_player and not is_network_driven)
	set_process(is_network_driven)


func _physics_process(delta: float) -> void:
	if not is_local_player or is_network_driven:
		return
	if inactive:
		velocity = Vector2.ZERO
		character_actor.call("set_running", false)
		return
	global_position = MapGeometry.recover_position(map_index, global_position, 14.0, locked_entrances)
	var current := global_position
	var target := MapGeometry.move_position(map_index, current, _move_direction * move_speed * minf(delta, 0.1), 14.0, locked_entrances)
	# Geometry has already selected a safe wall slide. Do not let a second physics
	# slide redirect that motion into an unvalidated inside corner.
	move_and_collide(target - current)
	velocity = (global_position - current) / maxf(delta, 0.0001)
	if velocity.length_squared() > 1.0:
		character_actor.call("set_facing_direction", velocity)
	character_actor.call("set_running", velocity.length_squared() > 1.0)


func _process(delta: float) -> void:
	if not is_network_driven or not _has_network_target:
		return
	if inactive:
		global_position = _network_target
		character_actor.call("set_running", false)
		return
	var travel_direction := _network_target - global_position
	var distance := global_position.distance_to(_network_target)
	if distance > 3.0:
		character_actor.call("set_facing_direction", travel_direction)
	character_actor.call("set_running", distance > 3.0)
	global_position = global_position.lerp(_network_target, 1.0 - exp(-16.0 * delta))
