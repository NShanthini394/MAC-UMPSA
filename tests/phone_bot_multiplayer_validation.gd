extends SceneTree
const Net=preload("res://scripts/network_manager.gd")
const Geo=preload("res://scripts/map_geometry.gd")
var server: Node
var clients=[]
var checks=0
var failures=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func wait_for(fn: Callable) -> bool:
 var until=Time.get_ticks_msec()+8000
 while not fn.call():
  if Time.get_ticks_msec()>until: check(false,"Timed out waiting for networking");return false
  await process_frame
 return true
func peer() -> Node:
 var branch=Node.new();branch.name="TestPeer%d"%root.get_child_count();root.add_child(branch)
 set_multiplayer(MultiplayerAPI.create_default_interface(),branch.get_path())
 var node=Net.new();node.name="NetworkManager";branch.add_child(node)
 node.server_port=17991
 return node
func run() -> void:
 var websocket="--websocket-test" in OS.get_cmdline_user_args()
 var address="ws://127.0.0.1:17991" if websocket else "127.0.0.1"
 server=peer();check(server.start_server(17991,websocket)==OK,"Server starts")
 var host=peer();clients.append(host)
 host.connection_changed.connect(func(ok,msg):print("CONNECTION ",ok," ",msg))
 host.room_error.connect(func(msg):print("ROOM ERROR ",msg))
 print("CREATE ",host.create_room(1,"Aiman",address))
 if not await wait_for(func():return not host.active_room_code.is_empty()):quit(1);return
 var code=host.active_room_code
 var room=server.rooms[code]
 server._tick_lobby_countdown(code,0)
 check(room.start_countdown==120.0,"Two-minute waiting room timer")
 server._tick_lobby_countdown(code,120.0)
 check(room.started and room.players.size()==10,"One player starts with nine bots")
 check(room.impostor_ids.size()==2,"Bot match has two Nenek")
 check(room.players.values().filter(func(p):return p.get("is_bot",false)).size()==9,"Nine bots exactly")
 check(preload("res://scripts/match_rules.gd").winner(room)=="","Solo bot match does not immediately finish")
 host.leave_room()
 if not await wait_for(func():return not server.rooms.has(code)):quit(1);return
 host.create_room(1,"Host",address)
 if not await wait_for(func():return not host.active_room_code.is_empty()):quit(1);return
 code=host.active_room_code;room=server.rooms[code]
 var guest=peer();clients.append(guest)
 guest.join_room(code,"Priya",address)
 if not await wait_for(func():return room.players.size()==2):quit(1);return
 check(true,"Other players may join during the two-minute wait")
 server._tick_lobby_countdown(code,120.0)
 check(room.started and room.players.size()==10,"Two humans start with eight bots")
 var host_id=host.local_peer_id();var guest_id=guest.local_peer_id()
 room.players[host_id].sleeping=true
 var origin=Geo.spawn_point(1)
 room.players[host_id].position=origin
 room.players[guest_id].position=origin
 var direction=Vector2.ZERO
 for d in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
  if Geo.move_position(1,origin,d*40,14,[]).distance_to(origin)>25:direction=d;break
 host.send_player_input(direction);guest.send_player_input(direction)
 await create_timer(0.35).timeout
 check(room.players[host_id].position.distance_to(origin)>20,"Sleeping human can move on server")
 check(room.players[guest_id].position.distance_to(origin)>20,"Second human moves simultaneously")
 host.send_player_input(Vector2.ZERO);guest.send_player_input(Vector2.ZERO)
 await create_timer(0.15).timeout
 check(room.players[guest_id].direction==Vector2.ZERO,"Reliable stop clears movement")
 guest.request_player_input.rpc_id(1,direction,1)
 await create_timer(0.1).timeout
 check(room.players[guest_id].direction==Vector2.ZERO,"Delayed movement cannot override a newer stop")
 check(not preload("res://scripts/nenek_powers.gd").is_active(room.players[host_id]),"Sleeping human remains ineligible for actions")
 server._set_meeting_phase(code,"discussion",0.0)
 server._process(0.01)
 check(room.meeting_state=="voting_intro","Discussion transitions to voting animation")
 room.meeting_timer=0.0
 server._process(0.01)
 check(room.meeting_state=="voting" and room.meeting_timer==20.0,"Voting gets twenty seconds after animation")
 host.cast_vote(guest_id)
 await create_timer(0.15).timeout
 check(not room.votes.has(host_id),"Sleeping player cannot vote")
 check(room.votes.size()>0,"Active bots participate in voting")
 var ended=[]
 guest.match_finished.connect(func(w,m):ended.append(m))
 host.leave_room()
 await wait_for(func():return not ended.is_empty())
 check(not server.rooms.has(code) and ended[0].contains("host left"),"Host departure ends match for guest")
 check(Net.DISCUSSION_SECONDS==45 and Net.VOTING_SECONDS==20,"45-second chat and 20-second voting")
 guest.leave_room()
 host.find_match("Aiman",address)
 if not await wait_for(func():return not host.active_room_code.is_empty()):quit(1);return
 var public_code=host.active_room_code
 guest.find_match("Priya",address)
 if not await wait_for(func():return guest.active_room_code==public_code):quit(1);return
 check(server.rooms[public_code].players.size()==2,"Find Match joins people into the existing two-minute lobby")
 for c in clients:c.leave_room()
 server.set_process(false)
 server.multiplayer.multiplayer_peer.close()
 for child in root.get_children(): child.queue_free()
 await process_frame
 print("PHONE / BOT / MULTIPLAYER CHECKS: %d checks; %d failures"%[checks,failures])
 quit(1 if failures else 0)
