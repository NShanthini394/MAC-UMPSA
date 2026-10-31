extends RefCounted
## Offline conversation planner: staggered, contextual replies based on each
## bot's own observations. No cloud service or hidden-role oracle is used.
const Rules = preload("res://scripts/match_rules.gd")
const Powers = preload("res://scripts/nenek_powers.gd")
const Data = preload("res://scripts/game_data.gd")

static func begin(room: Dictionary, now: float, random: RandomNumberGenerator) -> void:
	room["bot_chat_queue"] = []
	room["bot_chat_history"] = []
	room["bot_chat_next"] = now + 1.5
	var bots := active_bots(room)
	# A few people open the conversation; others reply when addressed.
	for i in mini(bots.size(), 5):
		var bot: Dictionary = bots[(i + random.randi_range(0, bots.size()-1)) % bots.size()]
		var queue: Array = room.bot_chat_queue
		if queue.any(func(event: Dictionary) -> bool: return event.id == bot.id): continue
		queue.append({"id": bot.id, "due": now + 2.0 + i * random.randf_range(3.5, 5.0), "message": "", "speaker": ""})

static func active_bots(room: Dictionary) -> Array:
	var result: Array = []
	for bot in room.players.values():
		if bot.get("is_bot", false) and Powers.is_active(bot): result.append(bot)
	return result

static func hear(room: Dictionary, sender: int, message: String, now: float, random: RandomNumberGenerator) -> void:
	var bots := active_bots(room)
	if bots.is_empty(): return
	var lower := message.to_lower()
	var addressed: Array = []
	for bot in bots:
		if lower.contains(str(bot.name).to_lower()): addressed.append(bot)
	# Answer a human promptly without making every bot echo the same response.
	var speaker := str(room.players[sender].name)
	var turn := int(room.get("bot_chat_turn", 0))
	room["bot_chat_turn"] = turn + 1
	var respondents: Array = addressed.slice(0, 2) if not addressed.is_empty() else [bots[turn % bots.size()]]
	if addressed.is_empty() and ("?" in message or "clue" in lower) and bots.size() > 1:
		respondents.append(bots[(turn+1) % bots.size()])
	var queue: Array = room.get("bot_chat_queue", [])
	for i in respondents.size():
		var bot: Dictionary = respondents[i]
		# Replace that bot's pending opener or old answer with the newest question.
		queue = queue.filter(func(event: Dictionary) -> bool: return event.id != bot.id)
		queue.append({"id": bot.id, "due": now + random.randf_range(1.3, 2.5) + i * 3.0, "message": message, "speaker": speaker})
	room["bot_chat_queue"] = queue

static func tick(room: Dictionary, now: float, random: RandomNumberGenerator) -> Dictionary:
	if now < float(room.get("bot_chat_next", now+1)): return {}
	var queue: Array = room.get("bot_chat_queue", [])
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.due < b.due)
	while not queue.is_empty():
		var event: Dictionary = queue[0]
		if now < float(event.due): return {}
		queue.pop_front()
		if not room.players.has(event.id) or not Powers.is_active(room.players[event.id]): continue
		var bot: Dictionary = room.players[event.id]
		var message := response(room, bot, str(event.message), str(event.speaker), random)
		var history: Array = room.get("bot_chat_history", [])
		if message in history:
			message = "%s, %s" % [str(event.speaker) if not str(event.speaker).is_empty() else "Everyone", alibi(bot)]
		if message in history: continue
		history.append(message)
		if history.size() > 30: history.pop_front()
		room["bot_chat_history"] = history
		room["bot_chat_next"] = now + random.randf_range(2.2, 3.8)
		return {"member": bot, "message": message}
	return {}

static func alibi(bot: Dictionary) -> String:
	var task := int(bot.get("bot_last_task", -1))
	if task >= 0 and task < Data.COMMON_TASKS.size(): return "I was working on %s." % str(Data.COMMON_TASKS[task].name).to_lower()
	return ["I was moving between the rooms.", "I was looking for an unfinished task.", "I was checking the paths near the house."][abs(int(bot.id)) % 3]

static func evidence(room: Dictionary, bot: Dictionary) -> String:
	for suspect in bot.get("bot_suspicions", {}):
		if float(bot.bot_suspicions[suspect]) >= 5 and room.players.has(suspect):
			return "I saw %s cast a sleep spell. That is who I suspect." % str(room.players[suspect].name)
	return ""

static func response(room: Dictionary, bot: Dictionary, message: String, speaker: String, random: RandomNumberGenerator) -> String:
	var lower := message.to_lower()
	var proof := evidence(room, bot)
	var variant := random.randi_range(0, 2)
	var prefix := speaker + ", " if not speaker.is_empty() else ""
	if message.is_empty():
		if not proof.is_empty(): return proof
		return [alibi(bot)+" Did anyone see a sleep spell?", "I have no clear suspect yet. What did everyone see?", "Let's compare what we saw before voting. "+alibi(bot)][variant]
	if lower.contains(str(bot.name).to_lower()) and any_word(lower, ["sus", "nenek", "impost", "vote", "spell", "you"]):
		return ["I understand the suspicion, "+speaker+", but "+alibi(bot).to_lower(), "What did you see me do, "+speaker+"? "+alibi(bot), "I did not cast that spell. "+alibi(bot)][variant]
	if any_word(lower, ["clue", "evidence", "suspect", "who", "spell", "sleep"]):
		if not proof.is_empty(): return prefix+proof
		return [prefix+"I didn't witness a spell. Where did you see it?", prefix+"I have no solid evidence yet. Did you see who was beside the sleeping player?", prefix+"I can't confirm a suspect. "+alibi(bot)+" What clue did you find?"][variant]
	if any_word(lower, ["saw", "see", "seen", "near", "room", "where", "kitchen", "garden", "hall"]):
		return [prefix+"which player was there with you? "+alibi(bot), prefix+"was that before or after the gong? "+alibi(bot), prefix+"can anyone else confirm that location? "+alibi(bot)][variant]
	if any_word(lower, ["task", "rice", "fire", "shoe", "laundry", "marble", "flower", "lamp"]):
		return prefix+alibi(bot)+[" We still need to find both Nenek Kebayan.", " Tasks alone won't identify the imposters.", " Did you notice anyone following you?"][variant]
	if any_word(lower, ["skip", "vote"]):
		return prefix+(proof if not proof.is_empty() else ["I'll skip if we have no evidence.", "Let's avoid voting someone out just for being nearby.", "I need a clearer reason before choosing someone."][variant])
	if any_word(lower, ["hello", " hi", "hey"]) or lower == "hi": return prefix+["hello! Did you find any clues?", "hey. "+alibi(bot), "hi! Let's work out who used the sleep spell."][variant]
	if any_word(lower, ["thank", "okay", " ok", "agree"]): return prefix+["let's keep comparing our observations.", "I'll keep that in mind for the vote.", "we should stick to what someone actually saw."][variant]
	return prefix+["can you tell us which player you mean?", "what happened just before that? "+alibi(bot), "I'm listening. Where did that happen?"][variant]

static func any_word(text: String, words: Array) -> bool:
	for word in words:
		if text.contains(str(word)): return true
	return false
