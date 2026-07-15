extends Node

## Verwaltet Host/Client-Verbindung und die Spielerliste.
## Ist die einzige Stelle, die ENetMultiplayerPeer erzeugt/zerstört.

signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected

const PORT := 7777
const MAX_PLAYERS := 8

var players: Dictionary = {}  # peer_id (int) -> player_info (Dictionary)
var my_info: Dictionary = {"name": "Spieler"}


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func create_game(player_name: String) -> Error:
	my_info.name = player_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	# Host trägt sich selbst als Peer 1 ein.
	players[1] = my_info
	player_connected.emit(1, my_info)
	return OK


func join_game(address: String, player_name: String) -> Error:
	my_info.name = player_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func leave_game() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()


@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
	# Läuft NUR auf dem Host: nimmt die Info entgegen und broadcastet die volle Liste.
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	players[sender_id] = new_player_info
	player_connected.emit(sender_id, new_player_info)
	_sync_full_player_list.rpc(players)


@rpc("authority", "reliable")
func _sync_full_player_list(all_players: Dictionary) -> void:
	# Läuft auf Clients: übernimmt die vom Host verteilte, autoritative Spielerliste.
	if multiplayer.is_server():
		return
	for peer_id in all_players.keys():
		if not players.has(peer_id):
			player_connected.emit(peer_id, all_players[peer_id])
	players = all_players


func _on_peer_disconnected(id: int) -> void:
	if players.erase(id):
		player_disconnected.emit(id)
	if multiplayer.is_server():
		_sync_full_player_list.rpc(players)


func _on_connected_ok() -> void:
	var peer_id := multiplayer.get_unique_id()
	players[peer_id] = my_info
	_register_player.rpc_id(1, my_info)


func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
