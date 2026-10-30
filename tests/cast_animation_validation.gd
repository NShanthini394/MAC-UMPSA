extends SceneTree
## Validate the shipped art, actual frame playback and both player-control paths.
const Data = preload("res://scripts/game_data.gd")
const Actor = preload("res://scripts/character_actor.gd")
const Geometry = preload("res://scripts/map_geometry.gd")
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	for character in Data.CHARACTERS:
		validate_character(character)
	await validate_player_controls()
	print("CAST ANIMATION CHECKS: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func validate_character(character: String) -> void:
	var actor := Actor.new()
	root.add_child(actor)
	actor.configure(character, character)
	actor.set_process(false)
	var sprite: TextureRect = actor.get_node("CharacterSprite")
	var frames: SpriteFrames = actor.get("_animations")
	check(frames != null, character + " has an actual animation resource")
	if frames == null:
		actor.queue_free()
		return
	var sheet: Texture2D = (sprite.texture as AtlasTexture).atlas
	var image := sheet.get_image()
	check(image.get_pixel(0, 0).a == 0.0 and image.get_pixel(image.get_width() - 1, 0).a == 0.0, character + " uses real transparency")
	check(sprite.material == null, character + " uses drawn leg frames instead of a distortion shader")
	for direction in ["front", "back", "side"]:
		var idle := StringName(direction + "_idle")
		var walk := StringName(direction + "_walk")
		check(frames.get_frame_count(idle) == 1 and frames.get_frame_count(walk) == 4, character + " has standing and walking art for " + direction)
		var leg_hashes := {}
		for i in frames.get_frame_count(walk):
			var frame := frames.get_frame_texture(walk, i) as AtlasTexture
			check(Rect2(Vector2.ZERO, sheet.get_size()).encloses(frame.region) and frame.margin.position.x >= -0.05 and frame.margin.position.y >= -0.05, character + " pose stays within its atlas and aligned canvas")
			var crop := Rect2i(Vector2i(frame.region.position + Vector2(0, frame.region.size.y * 0.58)), Vector2i(frame.region.size * Vector2(1, 0.42)))
			leg_hashes[hash(image.get_region(crop).get_data())] = true
		check(leg_hashes.size() > 1, character + " changes the legs/hem pixels while walking " + direction)
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		actor.set_facing_direction(direction)
		actor.set_running(false)
		var idle := sprite.texture
		var anchor := sprite.position
		actor.set_running(true)
		var contact := sprite.texture
		actor.call("_process", 0.125)
		check(sprite.texture != contact, character + " advances to a passing pose")
		actor.call("_process", 0.375)
		check(sprite.texture == contact, character + " loops at the intended speed")
		actor.call("_process", 1.5)
		check(sprite.texture == contact and sprite.position == anchor, character + " handles long frames without losing phase or moving the feet anchor")
		actor.set_running(false)
		actor.call("_process", 0.5)
		check(sprite.texture == idle and sprite.flip_h == (direction == Vector2.LEFT), character + " stops facing the correct direction")
	actor.set_running(true)
	actor.set_sleeping(true)
	check(is_zero_approx(sprite.rotation) and is_zero_approx(sprite.position.y), character + " remains upright while asleep")
	var asleep := sprite.texture
	actor.call("_process", 0.5)
	check(sprite.texture == asleep and not bool(actor.get("_is_running")), character + " stops walking while asleep")
	actor.set_running(true)
	actor.call("_process", 0.125)
	check(bool(actor.get("_is_running")) and is_zero_approx(sprite.rotation), character + " can animate walking upright while asleep")
	actor.set_sleeping(false)
	check(sprite.rotation == 0.0 and sprite.position.y == 0.0, character + " restores the standing pose after waking")
	for path in [Data.CHARACTER_PORTRAITS[character], Data.CHARACTER_AVATARS[character]]:
		check(load(path) is AtlasTexture, character + " has an updated portrait/avatar")
	actor.queue_free()


func validate_player_controls() -> void:
	for character in Data.CHARACTERS:
		var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
		root.add_child(player)
		player.call("configure", character, "Local", true, false)
		player.set_physics_process(false)
		check(player.get_node("CharacterActor").get("_character") == character, "Local selection is respected: " + character)
		player.call("configure", character, "Remote", false, true)
		check(player.get_node("CharacterActor").get("_character") == character, "Remote selection is respected: " + character)
		player.queue_free()
	await process_frame
	var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.position = Geometry.spawn_point(0)
	player.call("configure", "Bawang Putih", "Movement test", true, false)
	var origin := player.position
	var direction := Vector2.ZERO
	for candidate in [Vector2.RIGHT, Vector2.DOWN, Vector2.UP, Vector2.LEFT]:
		if not Geometry.is_step_blocked(0, origin, origin + candidate * 55, 14):
			direction = candidate
			break
	player.call("set_input_direction", direction)
	await create_timer(0.18).timeout
	check(player.position.distance_to(origin) > 1 and bool(player.get_node("CharacterActor").get("_is_running")), "Real physics movement starts the selected character animation")
	player.call("set_sleeping", true)
	var asleep_position := player.position
	await create_timer(0.18).timeout
	player.call("set_input_direction", direction)
	await create_timer(0.18).timeout
	check(player.position.distance_to(asleep_position) > 1, "Sleeping player can continue walking")
	check(is_zero_approx(player.get_node("CharacterActor/CharacterSprite").rotation), "Sleeping walker stays upright")
	player.queue_free()
	var remote: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
	root.add_child(remote)
	remote.call("configure", "Orang Kampung Perempuan", "Remote movement", false, true)
	remote.call("set_network_target", Vector2(40, 0))
	await process_frame
	await process_frame
	check(bool(remote.get_node("CharacterActor").get("_is_running")), "Network-driven movement starts remote walking frames")
	remote.queue_free()
	await process_frame
