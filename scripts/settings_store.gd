extends RefCounted
const DEFAULTS = {"music": 100.0, "effects": 100.0, "muted": false, "sensitivity": 1.0, "text_size": 20.0, "language": "en", "joystick_visibility": "touch"}
static var values: Dictionary = {}
static func load_values() -> void:
	if not values.is_empty(): return
	var config := ConfigFile.new()
	config.load("user://preferences.cfg")
	values = DEFAULTS.duplicate()
	for key in values: values[key] = config.get_value("settings", key, values[key])
	values["guest_id"] = config.get_value("settings", "guest_id", "GUEST-" + Crypto.new().generate_random_bytes(4).hex_encode().to_upper())
	if not config.has_section_key("settings", "guest_id"):
		config.set_value("settings", "guest_id", values.guest_id)
		config.save("user://preferences.cfg")
static func get_value(key: String) -> Variant:
	load_values()
	return values.get(key)
static func set_value(key: String, value: Variant) -> void:
	load_values()
	values[key] = value
	var config := ConfigFile.new()
	for name_ in values: config.set_value("settings", name_, values[name_])
	config.save("user://preferences.cfg")
static func ensure_buses() -> void:
	for name_ in ["Music", "Effects"]:
		if AudioServer.get_bus_index(name_) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1, name_)
			AudioServer.set_bus_send(AudioServer.bus_count-1, "Master")
static func apply(app: Control) -> void:
	load_values(); ensure_buses()
	for pair in [["Music", "music"], ["Effects", "effects"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]), linear_to_db(maxf(0.0001, float(values[pair[1]])/100.0)))
	app.audio_muted = bool(values.muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), app.audio_muted)
static func restore() -> void:
	for key in DEFAULTS: set_value(key, DEFAULTS[key])
