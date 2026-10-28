extends Node
## Original, locally generated audio for the Malay folklore game.

const MUSIC_PATH := "res://assets/audio/kampung_misteri_bgm.wav"
const SFX_PATHS := {
	"ui": "res://assets/audio/ui_click.wav",
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


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "FolkloreBackgroundMusic"
	music_player.volume_db = -15.0
	music_player.bus = "Master"
	var music_stream := load(MUSIC_PATH) as AudioStreamWAV
	if music_stream:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
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
	call_deferred("play_sfx", "ui")


func play_sfx(kind: String) -> void:
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
	player.play()
