extends SceneTree
const Network = preload("res://scripts/network_manager.gd")
const Rules = preload("res://scripts/match_rules.gd")
const Companions = preload("res://scripts/walking_companions.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)
func fixture() -> Dictionary:
	var room := {"map_index":1,"started":true,"players":{},"completed_tasks":[0,0,0,0,0,0,0,0],"task_progress":[0,0,0,0,0,0,0,0],"meeting_state":"voting","votes":{},"host_id":2}
	for i in 10:
		room["players"][i+2]={"id":i+2,"name":"Member %d"%i,"character":"Badang","role":"nenek_kebayan" if i<2 else "villager","alive":true,"sleeping":false,"position":Geometry.spawn_point(1),"is_bot":i>=5}
	return room
func run() -> void:
	var service := Network.new();root.add_child(service);service.set_process(false)
	var room := fixture()
	check(Rules.human_ids(room).size()==5,"Only real people count toward five-player eligibility")
	room["completed_tasks"]=[1,1,1,1,1,1,1,1]
	check(Rules.winner(room)=="","Tasks alone do not win")
	room["players"][2]["alive"]=false
	check(Rules.winner(room)=="","One eliminated Nenek does not win")
	room["players"][3]["alive"]=false
	check(Rules.winner(room)=="villagers","Both removed plus eight tasks wins")
	room["completed_tasks"][7]=0
	check(Rules.winner(room)=="","Both removed still require remaining task")
	room=fixture()
	for id in [4,5,6]: room["players"][id]["sleeping"]=true
	check(Rules.winner(room)=="nenek_kebayan","Awake walking companions never prevent Nenek victory")
	for test_case in [
		{"name":"Human majority wins despite five abstaining companions","votes":{2:3,3:-1,4:3,5:3,6:3},"target":3},
		{"name":"A tied player vote eliminates nobody","votes":{2:3,3:2,4:3,5:2,6:-1},"target":-1},
		{"name":"Skip tying the leading target eliminates nobody","votes":{2:3,3:-1,4:3,5:-1,6:4},"target":-1},
		{"name":"Unanswered human votes count as Skip","votes":{2:3,4:3},"target":-1},
		{"name":"All Skip eliminates nobody","votes":{2:-1,3:-1,4:-1,5:-1,6:-1},"target":-1}
	]:
		room=fixture(); room["votes"]=test_case["votes"];service.rooms["RULES"]=room
		service._resolve_vote("RULES")
		check(room["last_reveal"]["id"]==test_case["target"],test_case["name"])
		check(room["meeting_state"]=="reveal" and room["meeting_timer"]==7.0,"Result is held for the full shared animation")
	for map_index in 3:
		room=fixture();room["map_index"]=map_index;room["meeting_state"]=""
		for id in room["players"]:
			room["players"][id]["position"]=Geometry.spawn_point_for_player(map_index,id-2)
		var rng:=RandomNumberGenerator.new();rng.seed=4100+map_index
		for step in 100:
			Companions.tick(room,0.08,step*0.08,rng,[])
			for member in room["players"].values():
				if member["is_bot"]: check(not Geometry.is_position_blocked(map_index,member["position"],14),"Companion movement stays on map %d floor"%map_index)
	service.queue_free();await process_frame
	print("TWO NENEK RULES: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
