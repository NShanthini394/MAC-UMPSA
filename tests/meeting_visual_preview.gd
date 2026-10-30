extends SceneTree
var app: Control
func _initialize() -> void: run.call_deferred()
func capture(filename: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/page-previews/v5_"+filename+".png")
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	await process_frame;await process_frame
	app.online_server_url=""; await app._find_public_match()
	app._on_matchmaking_changed(3)
	await capture("queue")
	app.selected_character="Raja Bersiung";app.player_is_impostor=false;app.selected_map=1
	app.completed_tasks=[0,0,0,0,0,0,0,0] as Array[int]
	app.task_progress=[0,0,0,0,0,0,0,0] as Array[int]
	app.player_position=load("res://scripts/map_geometry.gd").gong_point(1)
	await app.build_game()
	app.player_body.set_physics_process(false)
	app.player_body.get_node("Camera2D").reset_smoothing()
	var roster: Array=[]
	for i in 10: roster.append({"id":i+2,"name":["Amira","Aiman","Suria","Hakim","Melati","Arif","Dahlia","Farah","Lina","Johan"][i],"character":app.CHARACTERS[i],"alive":true,"sleeping":false})
	app.lobby_players=roster
	app._on_network_meeting_changed("alarm",4,roster,0,6)
	await create_timer(1.8).timeout
	await capture("gong_alarm")
	print("GONG LENGTH: ",load("res://assets/audio/gong.mp3").get_length())
	app._on_network_meeting_changed("discussion",20,roster,0,6)
	app.network_chat_lines.assign(["Amira: Who was near the kitchen?","Aiman: I saw someone leave the main hall."])
	app._on_network_chat_received(3,"Suria","Let's compare the clues.")
	await capture("discussion")
	app._on_network_meeting_changed("voting",10,roster,0,6)
	await capture("voting")
	app._on_elimination_revealed({"id":2,"name":"Amira","character":"Puteri Gunung Ledang","was_nenek":true,"remaining":1,"tasks_complete":false})
	await create_timer(2.2).timeout
	await capture("transformation")
	await create_timer(2.6).timeout
	await capture("nenek_revealed")
	app._on_elimination_revealed({"id":4,"name":"Hakim","character":"Orang Kampung Lelaki","was_nenek":false,"remaining":2,"tasks_complete":false})
	await create_timer(2.2).timeout
	await capture("innocent_departure")
	await create_timer(2.8).timeout
	await capture("innocent_result")
	app.queue_free();await process_frame;quit()
