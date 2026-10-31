extends SceneTree
const Net=preload("res://scripts/network_manager.gd")
const Geo=preload("res://scripts/map_geometry.gd")
const Powers=preload("res://scripts/nenek_powers.gd")
const Walk=preload("res://scripts/walking_companions.gd")
const Rules=preload("res://scripts/match_rules.gd")
var failures:=0
var checks:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	var service:=Net.new();root.add_child(service);service.set_process(false)
	service._server_random.seed=12345
	for map_index in 3:
		var room:Dictionary={"map_index":map_index,"mode":"solo","started":false,"host_id":7,"players":{7:service._make_player(7,"Human",true,"Badang")},"start_countdown":0.0,"bot_match":true}
		service.rooms={"SIM01":room};service._try_start_room("SIM01",false)
		check(room.players.size()==10 and room.impostor_ids.size()==2,"Ten characters and two Nenek on map %d"%map_index)
		check(room.players[7].role=="villager","Human stays Villager in Solo")
		var origins:Dictionary={}
		for member in room.players.values():origins[member.id]=member.position
		var now:=Time.get_ticks_msec()/1000.0
		var moved:=false
		for frame in 1200:
			now+=0.1
			Powers.expire_sabotage(room,now)
			if room.meeting_state!="":room.meeting_state="";room.bot_meeting_at=now+90
			Walk.tick(room,0.1,now,service._server_random,Powers.locked_doors(room,now))
			service._tick_testing_bots("SIM01",now)
			if frame%60==0:
				for member in room.players.values():
					check(not Geo.is_position_blocked(map_index,member.position,12),"AI respects mapped floors, walls and roofs")
					if member.position.distance_to(origins[member.id])>40:moved=true
			if room.get("finished",false):break
		check(moved,"Bots navigate beyond spawn on map %d"%map_index)
		check(room.task_progress.any(func(progress):return progress>0),"Bots find real task stations on map %d"%map_index)
		check(room.players.values().any(func(member):return member.sleeping),"Nenek bots catch Villagers on map %d"%map_index)
		room.finished=false
		for member in room.players.values():
			member.alive=true;member.sleeping=false
		room.completed_tasks.fill(1)
		check(Rules.winner(room)!="villagers","Tasks alone do not win")
		for id in room.impostor_ids:room.players[id].alive=false
		check(Rules.winner(room)=="villagers","All tasks and both eliminated Nenek win")
	service.queue_free();await process_frame
	print("BOT BEHAVIOUR: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
