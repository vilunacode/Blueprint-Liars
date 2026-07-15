extends Node

## Verteilt die Bauanleitung an alle Spieler - unicast pro Peer, niemals Broadcast,
## damit kein Client die Baulügner-Identität eines anderen Spielers mitlesen kann.
## Beide Blueprint-Varianten liegen als Asset bereits lokal bei jedem Client;
## über das Netzwerk geht nur der Pfad zur jeweils eigenen Variante, keine Resource-Daten.

signal role_assigned(is_liar: bool, blueprint: Blueprint)

const HONEST_BLUEPRINT_PATH := "res://resources/blueprints/shelf_honest.tres"
const LIAR_BLUEPRINT_PATH := "res://resources/blueprints/shelf_liar.tres"

var liar_peer_id: int = -1  # nur auf dem Host zuverlässig gesetzt
var my_blueprint: Blueprint = null
var am_i_liar: bool = false


func assign_roles() -> void:
	# Host-only.
	if not multiplayer.is_server():
		return
	var peer_ids: Array = NetworkManager.players.keys()
	if peer_ids.is_empty():
		return
	liar_peer_id = peer_ids.pick_random()
	var my_id := multiplayer.get_unique_id()
	for peer_id in peer_ids:
		var is_liar: bool = (peer_id == liar_peer_id)
		var path := LIAR_BLUEPRINT_PATH if is_liar else HONEST_BLUEPRINT_PATH
		if peer_id == my_id:
			# Host wendet seine eigene Rolle direkt an, kein Self-RPC
			# (rpc_id auf die eigene Peer-ID würde ohne "call_local" nicht auslösen).
			_apply_blueprint(path, is_liar)
		else:
			_receive_blueprint_path.rpc_id(peer_id, path, is_liar)


@rpc("authority", "reliable")
func _receive_blueprint_path(blueprint_path: String, is_liar: bool) -> void:
	_apply_blueprint(blueprint_path, is_liar)


func _apply_blueprint(blueprint_path: String, is_liar: bool) -> void:
	my_blueprint = load(blueprint_path)
	am_i_liar = is_liar
	role_assigned.emit(is_liar, my_blueprint)


func get_hand_counts_for_peer(peer_id: int) -> Dictionary:
	# Host-only: berechnet deterministisch (ohne Netzwerk-Roundtrip), was ein
	# Peer laut seiner zugewiesenen Blueprint-Variante in der Hand haben sollte -
	# damit der Host Platzierungs-Anfragen gegen die tatsächliche Hand validieren kann.
	var path := LIAR_BLUEPRINT_PATH if peer_id == liar_peer_id else HONEST_BLUEPRINT_PATH
	var blueprint: Blueprint = load(path)
	var counts: Dictionary = {}
	for slot_definition in blueprint.slots:
		var part_id: StringName = slot_definition.expected_part_id
		counts[part_id] = counts.get(part_id, 0) + 1
	return counts
