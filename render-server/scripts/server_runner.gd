extends Node
## Dedicated server entry point uses the same relative RPC path as LAN clients.
const Network = preload("res://scripts/network_manager.gd")


func _ready() -> void:
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())
	var service := Network.new()
	service.name = "NetworkManager"
	add_child(service)
	# NetworkManager reads --server / --port and starts the dedicated listener.
