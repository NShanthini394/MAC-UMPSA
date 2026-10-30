extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.selected_character = "Badang"
	app.assigned_role_character = "Badang"
	app.player_is_impostor = false
	app._show_role_reveal()
	await process_frame
	var director: Node = app.audio_director
	check(app.current_screen=="role_reveal","Role shuffle opens normally")
	check(director.role_player.playing,"Suspense starts with the role shuffle")
	check(director.role_player.stream==director.cached_streams["role_shuffle"],"Shuffle uses the suspense cue")
	check(not director.music_player.playing,"Menu music stops during the reveal")
	var deadline := Time.get_ticks_msec()+6000
	while director.role_player.stream!=director.cached_streams["role_tick"] and Time.get_ticks_msec()<deadline:
		await process_frame
	check(director.role_player.stream==director.cached_streams["role_tick"],"Countdown replaces suspense after the flip")
	var caption := app.find_child("RoleRevealCountdown",true,false) as Label
	check(caption!=null and caption.text.contains("3"),"First tick coincides with the displayed three")
	for seconds in [3,2,1]:
		director.play_role_countdown_tick(seconds)
		check(is_equal_approx(director.role_player.pitch_scale,1.0+0.1*(3-seconds)),"Countdown pitch increases toward the start")
	await app.build_menu()
	check(not director.role_player.playing,"Leaving the reveal cancels its audio")
	check(is_equal_approx(director.role_player.pitch_scale,1.0),"Audio cancellation resets pitch for the next shuffle")
	app.queue_free()
	await process_frame
	print("ROLE AUDIO CHECKS: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
