extends Node
## A separate server MultiplayerAPI keeps the host's own player a normal client.
const Network = preload("res://scripts/network_manager.gd")
var discovery_port := int(ProjectSettings.get_setting("network/discovery_port",7001))
var service: Node
var _api: MultiplayerAPI
var _branch: Node


func start(port: int = 7000) -> Error:
	if is_instance_valid(service): return OK
	# Godot does not allow nested custom MultiplayerAPI roots. The service is a
	# sibling of client scenes, while this owner controls its lifetime.
	_branch = Node.new()
	_branch.name = "LanService_%d" % get_instance_id()
	get_tree().root.add_child(_branch)
	_api = MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(_api, _branch.get_path())
	service = Network.new()
	service.name = "NetworkManager"
	service.set("discovery_port",discovery_port)
	_branch.add_child(service)
	var result: Error = service.call("start_server", port)
	if result != OK:
		_branch.queue_free()
		service = null
	return result


func stop() -> void:
	if is_instance_valid(service):
		service.set_process(false)
		if is_instance_valid(service.get("lan_discovery")): service.get("lan_discovery").stop_listener()
		var peer := _api.multiplayer_peer if _api != null else null
		if peer != null: peer.close()
	if is_instance_valid(_branch): _branch.queue_free()
	service = null
	_branch = null


func _exit_tree() -> void:
	stop()


static func addresses() -> PackedStringArray:
	var addresses_found := PackedStringArray()
	for address in IP.get_local_addresses():
		if not address.is_valid_ip_address() or ":" in address: continue
		if address.begins_with("127.") or address.begins_with("169.254.") or address == "0.0.0.0": continue
		if address not in addresses_found: addresses_found.append(address)
	return addresses_found
