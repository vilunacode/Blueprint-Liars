extends Node

## Rundenzähler und Score, überlebt Phasenwechsel innerhalb einer Session.

var round_number: int = 1
var scores: Dictionary = {}  # peer_id (int) -> Punkte (int)


func reset_for_new_game() -> void:
	round_number = 1
	scores.clear()


func add_score(peer_id: int, amount: int) -> void:
	scores[peer_id] = scores.get(peer_id, 0) + amount
