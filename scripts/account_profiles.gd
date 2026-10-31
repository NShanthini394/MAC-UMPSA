extends RefCounted
## Local profile choices scoped to each Firebase UID or offline Guest ID.
## No credentials, passwords, email addresses or session tokens are stored here.
const Settings = preload("res://scripts/settings_store.gd")
const Data = preload("res://scripts/game_data.gd")
static var path := "user://profiles.cfg"
static func key(user: Dictionary) -> String:
	return str(user.get("uid", "")) if not user.is_empty() else str(Settings.get_value("guest_id"))
static func profile(user: Dictionary) -> Dictionary:
	var config := ConfigFile.new(); config.load(path)
	var id := key(user)
	var fallback := str(user.get("display_name", "Player 1"))
	if fallback.is_empty(): fallback = "Player 1"
	return {"username":str(config.get_value(id, "username", fallback)) , "avatar":str(config.get_value(id, "avatar", ""))}
static func save(user: Dictionary, field: String, value: String) -> Error:
	if field not in ["username", "avatar"]: return ERR_INVALID_PARAMETER
	if field == "avatar" and value not in Data.CHARACTERS and value != "": return ERR_INVALID_PARAMETER
	var config := ConfigFile.new(); config.load(path)
	config.set_value(key(user), field, value)
	return config.save(path)
static func link_guest(user: Dictionary) -> void:
	var guest := profile({})
	var config := ConfigFile.new(); config.load(path)
	# Keep both records. An existing permanent profile must not be overwritten.
	if not config.has_section(key(user)):
		for field in guest: config.set_value(key(user), field, guest[field])
	config.set_value(key(user), "linked_guest", key({}))
	config.save(path)
static func erase_account(uid: String) -> void:
	var config := ConfigFile.new(); config.load(path)
	var linked := str(config.get_value(uid, "linked_guest", ""))
	if config.has_section(uid): config.erase_section(uid)
	if not linked.is_empty() and config.has_section(linked): config.erase_section(linked)
	config.save(path)
	if linked == key({}): Settings.set_value("guest_id", "GUEST-" + Crypto.new().generate_random_bytes(4).hex_encode().to_upper())
