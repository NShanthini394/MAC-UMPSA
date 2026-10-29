extends RefCounted
## Shared match rules. Time is supplied by the server (or local practice clock).

const MapGeometry = preload("res://scripts/map_geometry.gd")
const SLEEP_RANGE := 105.0
const SLEEP_COOLDOWN := 25.0
const SABOTAGE_COOLDOWN := 120.0
const FOG_DURATION := 20.0
const LOCK_DURATION := 10.0
const FOG_RADIUS := 180.0
const FOG_VILLAGER_SIGHT := 36.0


static func is_active(player: Dictionary) -> bool:
	return bool(player.get("alive", true)) and not bool(player.get("sleeping", false))


static func reset_match(room: Dictionary, now: float) -> void:
	room["sabotage_kind"] = ""
	room["sabotage_area"] = -1
	room["sabotage_until"] = 0.0
	room["fog_origin"] = Vector2.ZERO
	# The first sabotage is ready; subsequent uses share a two-minute recharge.
	room["sabotage_ready_at"] = now
	for player in room.get("players", {}).values():
		player["alive"] = true
		player["sleeping"] = false
		player["sleep_ready_at"] = now


static func expire_sabotage(room: Dictionary, now: float) -> bool:
	if str(room.get("sabotage_kind", "")) != "" and now >= float(room.get("sabotage_until", 0.0)):
		room["sabotage_kind"] = ""
		room["sabotage_area"] = -1
		return true
	return false


static func locked_doors(room: Dictionary, now: float) -> Array:
	if str(room.get("sabotage_kind", "")) != "lock" or now >= float(room.get("sabotage_until", 0.0)):
		return []
	return MapGeometry.area_doors(int(room.get("map_index", 0)), int(room.get("sabotage_area", -1)))


static func try_sleep(room: Dictionary, caster_id: int, target_id: int, now: float) -> String:
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "": return "Powers are unavailable outside active play."
	var players: Dictionary = room.get("players", {})
	if not players.has(caster_id) or not players.has(target_id): return "That player is no longer here."
	var caster: Dictionary = players[caster_id]
	var target: Dictionary = players[target_id]
	if not is_active(caster) or str(caster.get("role", "")) != "nenek_kebayan": return "Only active Nenek Kebayan can cast Sleep Spell."
	if caster_id == target_id or not is_active(target) or str(target.get("role", "")) != "villager": return "Choose an awake villager."
	if now < float(caster.get("sleep_ready_at", 0.0)): return "Sleep Spell is still recharging."
	var origin: Vector2 = caster.get("position", Vector2.ZERO)
	var destination: Vector2 = target.get("position", Vector2.ZERO)
	if origin.distance_to(destination) > SLEEP_RANGE: return "Move closer to an awake villager."
	if not MapGeometry.has_clear_path(int(room.get("map_index", 0)), origin, destination, locked_doors(room, now)):
		return "A wall or locked entrance blocks Sleep Spell."
	target["sleeping"] = true
	target["direction"] = Vector2.ZERO
	caster["sleep_ready_at"] = now + SLEEP_COOLDOWN
	return ""


static func try_sabotage(room: Dictionary, caster_id: int, kind: String, now: float) -> String:
	if not bool(room.get("started", false)) or bool(room.get("finished", false)) or str(room.get("meeting_state", "")) != "": return "Powers are unavailable outside active play."
	var players: Dictionary = room.get("players", {})
	if not players.has(caster_id): return "That player is no longer here."
	var caster: Dictionary = players[caster_id]
	if not is_active(caster) or str(caster.get("role", "")) != "nenek_kebayan": return "Only active Nenek Kebayan can sabotage."
	if kind not in ["fog", "lock"]: return "Choose fog or door locking."
	var map_index := int(room.get("map_index", 0))
	var origin: Vector2 = caster.get("position", Vector2.ZERO)
	var area_index := MapGeometry.section_at_position(map_index, origin)
	if kind == "lock" and MapGeometry.area_doors(map_index, area_index).is_empty(): return "Your current section has no doors or gates. Use fog here."
	if now < float(room.get("sabotage_ready_at", 0.0)): return "Fog and door locking share a two-minute recharge."
	room["sabotage_kind"] = kind
	room["sabotage_area"] = area_index
	room["fog_origin"] = origin
	room["sabotage_until"] = now + (FOG_DURATION if kind == "fog" else LOCK_DURATION)
	room["sabotage_ready_at"] = now + SABOTAGE_COOLDOWN
	# Move anyone standing exactly in a closing doorway to its nearest clear side.
	# This avoids trapping their collision body inside the barrier.
	for door in locked_doors(room, now):
		for player in players.values():
			if not is_active(player): continue
			var point: Vector2 = player.get("position", Vector2.ZERO)
			if door.grow(14.0).has_point(point):
				player["position"] = MapGeometry.clear_doorway_position(map_index, point, door)
	return ""


static func winner(room: Dictionary) -> String:
	var villagers := 0
	var nenek := 0
	for player in room.get("players", {}).values():
		if not is_active(player): continue
		if str(player.get("role", "villager")) == "nenek_kebayan": nenek += 1
		else: villagers += 1
	if nenek == 0: return "villagers"
	if villagers == 0: return "nenek_kebayan"
	return ""


static func snapshot(room: Dictionary, player: Dictionary, now: float) -> Dictionary:
	var seconds_left := maxf(0.0, float(room.get("sabotage_until", 0.0)) - now)
	return {
		"kind": str(room.get("sabotage_kind", "")) if seconds_left > 0.0 else "",
		"area": int(room.get("sabotage_area", -1)),
		"seconds_left": seconds_left,
		"fog_origin": room.get("fog_origin", Vector2.ZERO),
		"fog_radius": FOG_RADIUS,
		"sleep_cooldown": maxf(0.0, float(player.get("sleep_ready_at", 0.0)) - now),
		"sabotage_cooldown": maxf(0.0, float(room.get("sabotage_ready_at", 0.0)) - now)
	}
