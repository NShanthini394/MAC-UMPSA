extends SceneTree
const Net=preload("res://scripts/network_manager.gd")
const Chat=preload("res://scripts/bot_conversation.gd")
const Rules=preload("res://scripts/match_rules.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func run()->void:
 var server:=Net.new();root.add_child(server);server.set_process(false);server._server_random.seed=17
 var room:Dictionary={"map_index":0,"mode":"solo","started":false,"host_id":7,"players":{7:server._make_player(7,"Aiman",true,"Badang")},"start_countdown":0.0,"bot_match":true}
 server.rooms={"TEST1":room};server._try_start_room("TEST1",false)
 var random:=RandomNumberGenerator.new();random.seed=33
 Chat.begin(room,100,random)
 Chat.hear(room,7,"Do you guys have a clue?",100,random)
 var messages:Array=[];var times:Array=[]
 for tick in 120:
  var now:=100+tick*0.25
  var event:=Chat.tick(room,now,random)
  if not event.is_empty():
   check(event.message not in messages,"Bots do not repeat the same line")
   check(not str(event.message).contains("minigame"),"Chat shows task names, not dictionaries")
   messages.append(event.message);times.append(now)
 check(messages.size()>=2,"Bots answer and continue discussion")
 check(times[0]<=103,"Human question receives a prompt reply")
 for i in range(1,times.size()):check(times[i]-times[i-1]>=2,"Messages are staggered")
 var bot:Dictionary=Chat.active_bots(room)[0];bot.bot_last_task=0
 check(Chat.alibi(bot).contains("cook rice"),"Alibis reference the task actually performed")
 Chat.hear(room,7,str(bot.name)+", where were you?",131,random)
 check(room.bot_chat_queue.any(func(event):return event.id==bot.id and event.speaker=="Aiman"),"Named bot receives directed question")
 room.meeting_state="voting";room.meeting_timer=20;room.votes={}
 var voters:=Rules.voter_ids(room)
 for id in voters.slice(0,voters.size()-1):room.votes[id]=-1
 server._finish_voting_if_complete("TEST1")
 check(room.meeting_state=="voting","Incomplete voting waits")
 room.votes[voters[-1]]=-1
 server._finish_voting_if_complete("TEST1")
 check(room.meeting_state=="reveal" and room.last_reveal.id==-1,"All Skip immediately reveals without elimination")
 var snapshot:Dictionary=room.last_reveal.duplicate()
 server._finish_voting_if_complete("TEST1")
 check(room.last_reveal==snapshot,"Completion cannot resolve twice")
 room.meeting_state="voting";room.votes={};room.meeting_timer=20
 var target:int=room.impostor_ids[0]
 for id in voters:room.votes[id]=target if id!=target else -1
 server._finish_voting_if_complete("TEST1")
 check(room.meeting_state=="reveal" and room.last_reveal.id==target,"All submitted votes reveal immediately")
 server.queue_free();await process_frame
 print("CONVERSATION & VOTING: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
