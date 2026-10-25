extends CharacterBody2D
## Physics-based player actor used by offline practice and online room views.

@export var move_speed := 250.0

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
	_move_direction = direction.limit_length(1.0)


func set_network_target(target: Vector2) -> void:
	_network_target = target
	_has_network_target = true


func _ready() -> void:
	_network_target = global_position
	follow_camera.enabled = is_local_player
	set_physics_process(is_local_player and not is_network_driven)
	set_process(is_network_driven)


func _physics_process(_delta: float) -> void:
	if not is_local_player or is_network_driven:
		return
	velocity = _move_direction * move_speed
	move_and_slide()
	character_actor.call("set_running", velocity.length_squared() > 1.0)


func _process(delta: float) -> void:
	if not is_network_driven or not _has_network_target:
		return
	var distance := global_position.distance_to(_network_target)
	character_actor.call("set_running", distance > 3.0)
	global_position = global_position.lerp(_network_target, 1.0 - exp(-16.0 * delta))
