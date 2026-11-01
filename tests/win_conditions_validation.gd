extends SceneTree
const Rules = preload("res://scripts/match_rules.gd")

func _initialize() -> void:
	var checks := 0
	for nenek in 3:
		for villagers in 9:
			for complete in [false, true]:
				var room := {"players": {}, "completed_tasks": []}
				room.completed_tasks.resize(12)
				room.completed_tasks.fill(1 if complete else 0)
				for i in nenek:
					room.players[i] = {"role": "nenek_kebayan", "alive": true}
				for i in villagers:
					room.players[10+i] = {"role": "villager", "alive": true}
				# Sleeping and voted-out villagers must not prevent a Nenek win.
				room.players[30] = {"role": "villager", "alive": true, "sleeping": true}
				room.players[31] = {"role": "villager", "alive": false}
				var expected := ""
				if nenek == 0: expected = "villagers"
				elif nenek > villagers or (nenek == 1 and villagers == 1): expected = "nenek_kebayan"
				assert(Rules.winner(room) == expected, "Unexpected result for %d Nenek / %d awake villagers / tasks %s" % [nenek, villagers, complete])
				checks += 1
	print("WIN CONDITIONS: %d scenarios passed" % checks)
	quit()
