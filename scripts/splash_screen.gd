extends Control
## A viewport-sized game splash; the Android OS launch icon is independent.
const MAIN_SCENE := "res://scenes/main.tscn"
@export var auto_continue := true
var elapsed := 0.0
var transitioning := false
var loading := false

func _ready() -> void:
	if not auto_continue: return
	if "--server" in OS.get_cmdline_user_args():
		transitioning = true
		get_tree().call_deferred("change_scene_to_file", MAIN_SCENE)
		return
	var error := ResourceLoader.load_threaded_request(MAIN_SCENE)
	loading = error == OK
	if not loading: push_error("The game scene could not be loaded: " + error_string(error))

func _process(delta: float) -> void:
	if not auto_continue or transitioning or not loading: return
	elapsed += delta
	if elapsed < 1.2: return
	var status := ResourceLoader.load_threaded_get_status(MAIN_SCENE)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
		transitioning = true
		get_tree().call_deferred("change_scene_to_packed", scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		loading = false
		push_error("The game scene could not be loaded.")
