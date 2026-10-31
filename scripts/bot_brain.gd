extends RefCounted
## Rule-based AI: observations, tasks, pursuit and votes. Villager decisions
## never read the hidden role of a suspect.
const Geo=preload("res://scripts/map_geometry.gd")
const Powers=preload("res://scripts/nenek_powers.gd")
const Rules=preload("res://scripts/match_rules.gd")

static func witness_sleep(room:Dictionary,caster_id:int,target_id:int)->void:
	var caster:Dictionary=room.players[caster_id]
	for witness in room.players.values():
		if not witness.get("is_bot",false) or not Powers.is_active(witness) or witness.id==caster_id or witness.id==target_id:continue
		if str(witness.role)!="villager":continue
		var sight:=260.0
		if str(room.get("sabotage_kind",""))=="fog" and witness.position.distance_to(room.get("fog_origin",Vector2.ZERO))<Powers.FOG_RADIUS:sight=Powers.FOG_VILLAGER_SIGHT
		if witness.position.distance_to(caster.position)>sight:continue
		if not Geo.has_clear_path(int(room.map_index),witness.position,caster.position):continue
		var suspicion:Dictionary=witness.get("bot_suspicions",{})
		suspicion[caster_id]=float(suspicion.get(caster_id,0))+5.0
		witness["bot_suspicions"]=suspicion

static func hear_accusation(room:Dictionary,message:String)->void:
	var lower:=message.to_lower()
	if not preload("res://scripts/bot_conversation.gd").any_word(lower, ["suspect", "suspicious", "cast", "imposter", "impostor", "is nenek", "vote for"]): return
	for suspect in room.players.values():
		if not lower.contains(str(suspect.name).to_lower()):continue
		for bot in room.players.values():
			if not bot.get("is_bot",false) or bot.id==suspect.id or str(bot.role)!="villager":continue
			var suspicion:Dictionary=bot.get("bot_suspicions",{})
			suspicion[suspect.id]=minf(2.0,float(suspicion.get(suspect.id,0))+0.5) if float(suspicion.get(suspect.id,0))<5 else suspicion[suspect.id]
			bot["bot_suspicions"]=suspicion

static func vote(room:Dictionary,bot:Dictionary,random:RandomNumberGenerator)->int:
	var eligible:=Rules.voter_ids(room)
	eligible.erase(int(bot.id))
	var best:=-1
	var score:=0.0
	for id in bot.get("bot_suspicions",{}):
		if int(id) not in eligible:continue
		if float(bot.bot_suspicions[id])>score:score=float(bot.bot_suspicions[id]);best=int(id)
	if str(bot.role)=="villager" and score>=2:return best
	# A human's submitted vote is public behaviour, not secret-role information.
	var nominations:Dictionary={}
	for id in Rules.human_ids(room,true):
		var target:=int(room.get("votes",{}).get(id,-1))
		if target in eligible:nominations[target]=int(nominations.get(target,0))+1
	for target in nominations:
		if str(bot.role)=="nenek_kebayan" and str(room.players[target].role)=="nenek_kebayan":continue
		if int(nominations[target]) >= 2 or random.randf()<0.55:return int(target)
	if str(bot.role)=="nenek_kebayan":
		var villagers:Array=[]
		for id in eligible:
			if str(room.players[id].role)=="villager":villagers.append(id)
		if not villagers.is_empty():return int(villagers[random.randi_range(0,villagers.size()-1)])
	return -1

static func destination(room:Dictionary,bot:Dictionary,now:float,random:RandomNumberGenerator,fallback:Vector2)->Vector2:
	if str(bot.role)=="nenek_kebayan":
		var targets:Array=[]
		for member in room.players.values():
			if Powers.is_active(member) and str(member.role)=="villager":targets.append(member.position)
		if not targets.is_empty():return targets[random.randi_range(0,targets.size()-1)]
	else:
		# One villager approaches the gong; the others continue their tasks.
		if now>=float(room.get("bot_meeting_at",now+60)):
			for member in room.players.values():
				if member.get("is_bot",false) and Powers.is_active(member) and str(member.role)=="villager":
					if int(member.id)==int(bot.id):return Geo.gong_point(int(room.map_index))
					break
		var points:=Geo.task_points(int(room.map_index))
		var task := int(bot.get("bot_task_target", -1))
		# Finish the chosen activity instead of abandoning it between steps.
		if task >= 0 and int(room.completed_tasks[task]) == 0: return points[task]
		var best := INF
		for i in points.size():
			if int(room.completed_tasks[i]) != 0: continue
			var score: float = bot.position.distance_to(points[i]) + random.randf_range(0, 120)
			for other in room.players.values():
				if int(other.id) != int(bot.id) and Powers.is_active(other) and int(other.get("bot_task_target", -1)) == i: score += 900
			if score < best: best = score; task = i
		if best < INF:
			bot["bot_task_target"] = task
			return points[task]
	return fallback
