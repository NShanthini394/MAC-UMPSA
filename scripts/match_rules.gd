extends RefCounted
## Shared outcome rules for human and AI participants.

static func human_ids(room: Dictionary, active_only: bool = false) -> Array[int]:
	var ids: Array[int] = []
	for id in room.get("players", {}):
		var member: Dictionary = room["players"][id]
		if bool(member.get("is_bot", false)): continue
		if active_only and (not bool(member.get("alive", true)) or bool(member.get("sleeping", false))): continue
		ids.append(int(id))
	return ids

static func remaining_nenek(room: Dictionary) -> int:
	var count := 0
	for member in room.get("players", {}).values():
		if str(member.get("role", "")) == "nenek_kebayan" and bool(member.get("alive", true)): count += 1
	return count

static func tasks_complete(room: Dictionary) -> bool:
	var tasks: Array = room.get("completed_tasks", [])
	return tasks.size() == preload("res://scripts/game_data.gd").COMMON_TASKS.size() and tasks.count(1) == tasks.size()

static func winner(room: Dictionary) -> String:
	var awake_villagers := 0
	for id in voter_ids(room):
		if str(room["players"][id].get("role", "villager")) == "villager": awake_villagers += 1
	if remaining_nenek(room) == 0 and tasks_complete(room): return "villagers"
	if awake_villagers == 0: return "nenek_kebayan"
	return ""

static func voter_ids(room: Dictionary) -> Array[int]:
	var ids: Array[int] = []
	for id in room.get("players", {}):
		var member: Dictionary = room["players"][id]
		if bool(member.get("alive", true)) and not bool(member.get("sleeping", false)): ids.append(int(id))
	return ids
