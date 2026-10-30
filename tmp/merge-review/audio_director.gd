extends Node
## Menu music and game sound effects.

const MUSIC_PATH := "res://assets/audio/backtrack.mp3"
const SFX_PATHS := {
<<<<<<< tmp/merge-review/audio_director.gd
	"ui": "res://assets/audio/ui_click.wav",
	"gong": "res://assets/audio/gong.mp3",
=======
	"role_shuffle": "res://assets/audio/role_shuffle_suspense.wav",
	"role_tick": "res://assets/audio/role_countdown_tick.wav",
	"victory": "res://assets/audio/victory.mp3",
	"kabus": "res://assets/audio/kabus.mp3",
	"gong": "res://assets/audio/gong.mp3",
	"footsteps": "res://assets/audio/footsteps.mp3",
	"countdown": "res://assets/audio/countdown.mp3",
	"backtrack": "res://assets/audio/backtrack.mp3",
	"ui": "res://assets/audio/ui_soft_click.wav",
>>>>>>> tmp/merge-review/incoming
	"open": "res://assets/audio/task_open.wav",
	"collect": "res://assets/audio/object_pickup.wav",
	"clue": "res://assets/audio/clue_found.wav",
	"task_complete": "res://assets/audio/task_complete.wav",
	"drag": "res://assets/audio/drag_drop.wav",
	"timing_good": "res://assets/audio/timing_good.wav",
	"timing_miss": "res://assets/audio/timing_miss.wav"
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var cached_streams: Dictionary = {}
var next_player := 0
<<<<<<< tmp/merge-review/audio_director.gd
var gong_player: AudioStreamPlayer
var gong_fade: Tween
=======
var role_player: AudioStreamPlayer
>>>>>>> tmp/merge-review/incoming


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "FolkloreBackgroundMusic"
	music_player.volume_db = -15.0
	music_player.bus = "Master"
	var music_stream := load(MUSIC_PATH) as AudioStreamMP3
	if music_stream:
		music_stream.loop = true
		music_player.stream = music_stream
		add_child(music_player)
		music_player.play()
	else:
		push_warning("Background music could not be loaded: " + MUSIC_PATH)
	for i in 6:
		var player := AudioStreamPlayer.new()
		player.name = "SoundEffectPlayer%d" % i
		player.volume_db = -1.0
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)
	# Cache effects before interaction to avoid loading delays on the first gong strike.
	for kind in SFX_PATHS:
		cached_streams[kind] = load(str(SFX_PATHS[kind]))
	role_player = AudioStreamPlayer.new()
	role_player.name = "PrivateRoleAudio"
	role_player.volume_db = -4.0
	add_child(role_player)
	call_deferred("play_sfx", "ui")
	gong_player = AudioStreamPlayer.new()
	gong_player.name = "MeetingGongAudio"
	gong_player.stream = load(SFX_PATHS["gong"])
	add_child(gong_player)


func start_role_shuffle() -> void:
	stop_role_audio()
	music_player.stop()
	for player in sfx_players:
		if player.stream == cached_streams.get("countdown"): player.stop()
	role_player.stream = cached_streams["role_shuffle"]
	role_player.play()


func play_role_countdown_tick(seconds_left: int) -> void:
	stop_role_audio()
	role_player.stream = cached_streams["role_tick"]
	role_player.pitch_scale = 1.0+0.1*(3-seconds_left)
	role_player.play()


func stop_role_audio() -> void:
	if is_instance_valid(role_player):
		role_player.stop()
		role_player.pitch_scale = 1.0


func play_sfx(kind: String) -> void:
	if kind == "gong":
		if gong_fade and gong_fade.is_valid(): gong_fade.kill()
		gong_player.volume_db = -1.0
		gong_player.play()
		# The supplied recording is 54 seconds long. Keep one clear strike and
		# fade its tail so it does not drown out the discussion or overlap later hits.
		gong_fade = create_tween()
		gong_fade.tween_interval(4.5)
		gong_fade.tween_property(gong_player,"volume_db",-40.0,2.5)
		gong_fade.tween_callback(gong_player.stop)
		return
	if not SFX_PATHS.has(kind) or sfx_players.is_empty():
		return
	if not cached_streams.has(kind):
		cached_streams[kind] = load(str(SFX_PATHS[kind]))
	var stream := cached_streams[kind] as AudioStream
	if stream == null:
		push_warning("Sound effect could not be loaded: " + str(SFX_PATHS[kind]))
		return
	var player := sfx_players[next_player]
	next_player = (next_player + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = -7.0 if kind == "ui" else -1.0
	player.play()


var last_screen := ""
var last_position := Vector2.ZERO
var steps: AudioStreamPlayer
var counting := false

func _process(_delta: float) -> void:
	var app = get_parent()
	var screen: String = app.current_screen
	if screen != "role_reveal": stop_role_audio()
	var seconds_left: float = app.practice_start_countdown
	if not app.room_code.is_empty() and app.network_manager != null:
		seconds_left = app.network_manager.lobby_countdown
	var active: bool = screen == "waiting_room" and seconds_left > 0.0 and seconds_left <= 10.0
	if active and not counting: play_sfx("countdown")
	if counting and not active:
		for player in sfx_players:
			if player.stream == cached_streams.get("countdown"): player.stop()
	counting = active
	var menu: bool = screen in ["login", "menu", "character_select", "waiting_room"] and not active
	if menu and not music_player.playing: music_player.play()
	elif not menu: music_player.stop()
	if steps == null:
		steps = AudioStreamPlayer.new()
		var stream := load("res://assets/audio/footsteps.mp3") as AudioStreamMP3
		stream.loop = true
		steps.stream = stream
		steps.volume_db = -10.0
		add_child(steps)
	var moving: bool = screen == "game" and last_screen == "game" and app.player_position.distance_to(last_position) > 0.1
	if moving and not steps.playing: steps.play()
	elif not moving: steps.stop()
	last_position = app.player_position
	last_screen = screen
