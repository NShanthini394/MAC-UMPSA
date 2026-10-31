extends SceneTree
const Net=preload("res://scripts/network_manager.gd")
const Rules=preload("res://scripts/match_rules.gd")
const Brain=preload("res://scripts/bot_brain.gd")
const Geo=preload("res://scripts/map_geometry.gd")
const Powers=preload("res://scripts/nenek_powers.gd")
var server:Node
var clients:Array[Node]=[]
var branches:Array[Node]=[]
var failures:=0
var checks:=0
var endpoint:="127.0.0.1"
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func wait_for(predicate:Callable)->bool:
	var deadline:=Time.get_ticks_msec()+7000
	while not predicate.call():
		if Time.get_ticks_msec()>deadline:check(false,"Network timeout");return false
		await process_frame
	return true
func peer()->Node:
	var branch:=Node.new();branch.name="ModePeer%d"%branches.size();root.add_child(branch);branches.append(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(),branch.get_path())
	var node:=Net.new();node.name="NetworkManager";branch.add_child(node);node.server_port=17995
	return node
func run()->void:
	await validate()
	for client in clients:client.leave_room()
	if server:server.set_process(false);server.multiplayer.multiplayer_peer.close()
	for branch in branches:branch.queue_free()
	await process_frame
	print("PLAY MODES NETWORK: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
func validate()->void:
	var websocket:="--websocket-test" in OS.get_cmdline_user_args()
	if websocket:endpoint="ws://127.0.0.1:17995"
	server=peer();check(server.start_server(17995,websocket,false)==OK,"Server starts")
	var host:=peer();clients.append(host)
	var guest:=peer();clients.append(guest)
	var late:=peer();clients.append(late)
	host.create_room(0,"Aiman",endpoint)
	if not await wait_for(func():return not host.active_room_code.is_empty()):return
	var code:String=host.active_room_code
	var room:Dictionary=server.rooms[code]
	server._tick_lobby_countdown(code,120)
	check(not room.started and room.start_countdown<0,"Private host is never forced to start by timeout")
	host.start_match();await create_timer(0.1).timeout
	check(not room.locked,"Private room requires two humans")
	guest.join_room(code,"Priya",endpoint)
	if not await wait_for(func():return room.players.size()==2):return
	host.start_match();await create_timer(0.1).timeout
	check(not room.locked,"Private start waits for guest Ready")
	guest.toggle_ready()
	if not await wait_for(func():return room.players[guest.local_peer_id()].ready):return
	host.start_match()
	if not await wait_for(func():return room.locked):return
	server.set_process(false)
	check(room.players.size()==10 and room.start_countdown>4,"Two ready humans get eight bots and five-second countdown")
	check(not room.started,"Bot filling does not bypass start countdown")
	var errors:Array=[];late.room_error.connect(func(message):errors.append(message))
	late.join_room(code,"Wei Jian",endpoint)
	if not await wait_for(func():return not errors.is_empty()):return
	check(late.active_room_code.is_empty(),"Locked match rejects late join")
	check(Net.LOBBY_WAIT_SECONDS==5.0 and ceili(host.lobby_countdown)==5 and ceili(guest.lobby_countdown)==5,"Both clients begin at five, not ten")
	room.start_countdown=5.0
	for seconds_left in [4,3,2,1]:
		server._tick_lobby_countdown(code,1.0)
		if not await wait_for(func():return ceili(host.lobby_countdown)==seconds_left and ceili(guest.lobby_countdown)==seconds_left):return
		check(not room.started,"Both clients see countdown %d before gameplay"%seconds_left)
	server._tick_lobby_countdown(code,1.0)
	check(room.started and room.impostor_ids.size()==2,"Exactly two Nenek among ten characters")
	check(Rules.human_ids(room).any(func(id):return room.players[id].role=="villager"),"Small friend groups retain a human Villager")
	check(Rules.voter_ids(room).size()==10,"Awake AI participants can vote")
	server._set_meeting_phase(code,"voting",20)
	guest.cast_vote(-1)
	if not await wait_for(func():return room.votes.has(guest.local_peer_id())):return
	guest.cast_vote(host.local_peer_id());await create_timer(0.05).timeout
	check(room.votes[guest.local_peer_id()]==-1,"Skip is immutable on the authoritative server")
	room.votes={};room.meeting_state=""

	check(server._room_members(room).all(func(member):return not member.has("role") and not member.has("bot_suspicions")),"Snapshots hide roles and AI evidence")
	var bot:Dictionary={}
	for member in room.players.values():
		if member.get("is_bot",false) and member.role=="villager":bot=member;break
	var point:Vector2=Geo.task_points(0)[0]
	bot.position=point;bot.bot_action_at=0.0
	server._tick_testing_bots(code,Time.get_ticks_msec()/1000.0)
	check(room.task_progress[0]>0,"Villager bot advances a task at its station")
	var nenek_id:int=room.impostor_ids[0]
	# Exercise AI powers with an AI-controlled Nenek, regardless of human roles.
	for id in room.impostor_ids:
		if room.players[id].get("is_bot",false):nenek_id=id;break
	var human_villager:int=-1
	for id in Rules.human_ids(room):
		if room.players[id].role=="villager":human_villager=id
	bot["bot_suspicions"]={nenek_id:5.0}
	var random:=RandomNumberGenerator.new();random.seed=23
	room.votes={}
	check(Brain.vote(room,bot,random)==nenek_id,"Observed sleep spell drives a bot vote")
	bot.bot_suspicions={};room.votes={human_villager:nenek_id}
	var followed:=0
	for trial in 100:
		if Brain.vote(room,bot,random)==nenek_id:followed+=1
	check(followed>=30 and followed<=80,"Bots consider human accusations without all voting identically")
	room.votes={};check(Brain.vote(room,bot,random)==-1,"An uninformed Villager bot can Skip")
	var actor:Dictionary=room.players[nenek_id]
	actor.position=point;actor.sleep_ready_at=0;actor.bot_action_at=0;actor.bot_sabotage_at=0
	bot.position=point
	room.meeting_state=""
	server._tick_testing_bots(code,Time.get_ticks_msec()/1000.0)
	check(room.players.values().any(func(member):return member.sleeping),"Nenek AI casts Sleep Spell")
	check(str(room.sabotage_kind)!="","Nenek AI can sabotage")
	check(not Rules.winner(room)=="villagers","Tasks and both Nenek are required for victory")
	var ended:Array=[];guest.match_finished.connect(func(_winner,message):ended.append(message))
	host.leave_room()
	if not await wait_for(func():return not ended.is_empty()):return
	check(not server.rooms.has(code) and str(ended[0]).contains("host left"),"Host leaving ends the game for everyone")
	guest.leave_room();late.leave_room();server.set_process(true)
	host.find_match("Aiman",endpoint)
	if not await wait_for(func():return not host.active_room_code.is_empty()):return
	code=host.active_room_code;room=server.rooms[code]
	check(host.active_room_mode=="quick" and host.lobby_searching,"Quick Match immediately opens a shared search lobby")
	check(room.start_countdown>55 and room.start_countdown<=60,"Quick Match search is at most sixty seconds")
	var before:float=room.start_countdown
	guest.find_match("Priya",endpoint)
	if not await wait_for(func():return guest.active_room_code==code):return
	check(room.start_countdown<=before,"Another human joins without restarting the timer")
	server.set_process(false);server._tick_lobby_countdown(code,60)
	check(room.locked and not room.started and room.players.size()==10,"Search expiry fills bots and begins preparation countdown")
	server._tick_lobby_countdown(code,5)
	check(room.started and room.impostor_ids.size()==2,"Quick Match starts with two humans and eight bots")
	host.leave_room();guest.leave_room();await create_timer(0.1).timeout
	server.set_process(true)
	host.create_room(2,"Solo Player",endpoint,"solo")
	if not await wait_for(func():return not host.active_room_code.is_empty()):return
	code=host.active_room_code;room=server.rooms[code]
	host.start_match()
	if not await wait_for(func():return room.locked):return
	server.set_process(false);server._tick_lobby_countdown(code,5)
	check(room.started and room.players.size()==10,"Solo starts immediately with nine AI characters")
	check(room.players[host.local_peer_id()].role=="villager" and room.impostor_ids.size()==2,"Solo human is a Villager with two Nenek bots")
	check(Rules.winner(room).is_empty(),"Solo match does not end immediately")
	var reveals:Array=[];var winners:Array=[]
	host.elimination_revealed.connect(func(details):reveals.append(details))
	host.match_finished.connect(func(winner,_message):winners.append(winner))
	room.completed_tasks.fill(1)
	for member in room.players.values():member.alive=true;member.sleeping=false
	for target in room.impostor_ids:
		room.meeting_state="voting";room.meeting_timer=0;room.votes={}
		for voter in Rules.voter_ids(room):room.votes[voter]=int(target)
		server._resolve_vote(code)
		server._process(Net.REVEAL_SECONDS+0.1)
		await create_timer(0.05).timeout
	check(reveals.size()==2 and reveals[0].remaining==1 and reveals[1].remaining==0,"Both Nenek eliminations reach the client with correct remaining counts")
	check("villagers" in winners and room.finished,"Tasks plus both eliminations finish a complete Solo match")
	host.leave_room();await create_timer(0.1).timeout;server.set_process(true)
	# Ten ready humans can start a public match before the search timeout.
	for index in 10:
		var client:Node=clients[index] if index<clients.size() else peer()
		if index>=clients.size():clients.append(client)
		client.find_match("Human %d"%index,endpoint)
		if not await wait_for(func():return not client.active_room_code.is_empty()):return
	code=clients[0].active_room_code;room=server.rooms[code]
	check(Rules.human_ids(room).size()==10,"Ten humans share one public lobby")
	for client in clients:client.toggle_ready()
	if not await wait_for(func():return room.locked):return
	check(room.start_countdown>4 and room.players.size()==10 and not room.players.values().any(func(member):return member.get("is_bot",false)),"Ten ready humans start early without bots")
