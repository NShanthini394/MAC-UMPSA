extends SceneTree
const Chat = preload("res://scripts/bot_conversation.gd")
const Brain = preload("res://scripts/bot_brain.gd")
const Net = preload("res://scripts/network_manager.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var server := Net.new(); root.add_child(server); server.set_process(false)
	var room: Dictionary = {"map_index":1,"mode":"solo","started":false,"host_id":7,"players":{7:server._make_player(7,"Shanthini",true,"Badang")},"start_countdown":0.0,"bot_match":true}
	server.rooms = {"TEST1":room}; server._try_start_room("TEST1",false)
	room.started_at = 100.0
	var random := RandomNumberGenerator.new(); random.seed = 33
	Chat.begin(room,100,random)
	check(room.bot_chat_queue.size() <= 3, "Only a few bots open the discussion")
	var last := -100.0; var counts := {}; var last_by_bot := {}
	for tick in 180:
		var now := 100.0 + tick*0.25
		if tick % 12 == 0: Chat.hear(room,7,"Hi, anyone has a clue?",now,random)
		var event := Chat.tick(room,now,random)
		if event.is_empty(): continue
		var id: int = event.member.id
		check(now-last>=4.5,"Discussion leaves reading time between replies")
		check(now-float(last_by_bot.get(id,-100.0))>=14.0,"Each bot pauses before speaking again")
		last=now;last_by_bot[id]=now;counts[id]=int(counts.get(id,0))+1
	for count in counts.values(): check(count<=2,"No bot exceeds two messages per discussion")
	var opponent: Dictionary = room.players[room.impostor_ids[0]]
	check(not Brain.can_bot_attack(room,opponent,144),"Solo has a 45-second initial grace period")
	check(Brain.can_bot_attack(room,opponent,145),"Solo attacks become possible after grace period")
	Brain.record_bot_attack(room,opponent,145)
	check(not Brain.can_bot_attack(room,opponent,184),"Solo bot attack cooldown is enforced")
	check(Brain.can_bot_attack(room,opponent,185),"Solo bot can attack again; wins are not forced")
	var other: Dictionary=room.players[room.impostor_ids[1]]
	check(not Brain.can_bot_attack(room,other,164),"Two solo imposters cannot chain attacks together")
	check(Brain.can_bot_attack(room,other,165),"Other solo imposter recovers after shared interval")
	room.mode="friends"
	check(Brain.can_bot_attack(room,opponent,100),"Solo tuning does not change Friends attacks")
	server.queue_free(); await process_frame
	print("DISCUSSION BALANCE: %d checks; %d failures"%[checks,failures]); quit(1 if failures else 0)
