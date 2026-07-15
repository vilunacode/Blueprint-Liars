extends Control

## Jeder Spieler beschuldigt genau einen anderen Spieler. Der Host zählt aus,
## sobald entweder alle abgestimmt haben oder die Zeit abläuft, und deckt dann
## für alle sichtbar auf, wer wirklich der Baulügner war.

const VOTE_DURATION_SECONDS := 20.0

@onready var candidates_container: VBoxContainer = $VBoxContainer/CandidatesContainer
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var back_button: Button = $VBoxContainer/BackButton

var remaining_time: float = VOTE_DURATION_SECONDS
var has_voted: bool = false
var vote_resolved: bool = false
var votes: Dictionary = {}  # peer_id (Wähler) -> peer_id (Beschuldigter), Host-autoritativ


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false
	result_label.text = ""
	remaining_time = VOTE_DURATION_SECONDS
	_update_time_label()
	_build_candidate_buttons()


func _process(delta: float) -> void:
	if vote_resolved or remaining_time <= 0.0:
		return
	remaining_time = max(0.0, remaining_time - delta)
	_update_time_label()
	if remaining_time <= 0.0 and multiplayer.is_server():
		_resolve_votes()


func _update_time_label() -> void:
	if remaining_time <= 0.0:
		time_label.text = "Zeit abgelaufen!"
		return
	time_label.text = "Zeit für Abstimmung: %d s" % int(ceil(remaining_time))


func _build_candidate_buttons() -> void:
	var my_id := multiplayer.get_unique_id()
	for peer_id in NetworkManager.players.keys():
		if peer_id == my_id:
			continue
		var info: Dictionary = NetworkManager.players[peer_id]
		var button := Button.new()
		button.text = "Beschuldige %s" % info.get("name", "???")
		button.pressed.connect(_on_accuse_pressed.bind(peer_id))
		candidates_container.add_child(button)


func _on_accuse_pressed(accused_peer_id: int) -> void:
	if has_voted:
		return
	has_voted = true
	for child in candidates_container.get_children():
		child.disabled = true

	if multiplayer.is_server():
		# Host ruft sich selbst direkt auf statt per rpc_id (Self-Targeting
		# ohne "call_local" würde sonst nicht auslösen, siehe RoleManager).
		_handle_vote(multiplayer.get_unique_id(), accused_peer_id)
	else:
		_cast_vote.rpc_id(1, accused_peer_id)


@rpc("any_peer", "reliable")
func _cast_vote(accused_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_handle_vote(multiplayer.get_remote_sender_id(), accused_peer_id)


func _handle_vote(voter_id: int, accused_peer_id: int) -> void:
	votes[voter_id] = accused_peer_id
	if votes.size() >= NetworkManager.players.size():
		_resolve_votes()


func _resolve_votes() -> void:
	if vote_resolved:
		return
	vote_resolved = true
	var tally: Dictionary = {}  # accused_peer_id -> Stimmenzahl
	for voter_id in votes.keys():
		var accused: int = votes[voter_id]
		tally[accused] = tally.get(accused, 0) + 1

	var accused_peer_id := -1
	var best_count := -1
	for candidate_id in tally.keys():
		if tally[candidate_id] > best_count:
			best_count = tally[candidate_id]
			accused_peer_id = candidate_id

	_broadcast_result.rpc(accused_peer_id, RoleManager.liar_peer_id)


@rpc("authority", "call_local", "reliable")
func _broadcast_result(accused_peer_id: int, liar_peer_id: int) -> void:
	vote_resolved = true
	back_button.visible = multiplayer.is_server()

	var accused_name := "niemanden (keine Stimmen)"
	if NetworkManager.players.has(accused_peer_id):
		accused_name = NetworkManager.players[accused_peer_id].get("name", "???")
	var liar_name := "?"
	if NetworkManager.players.has(liar_peer_id):
		liar_name = NetworkManager.players[liar_peer_id].get("name", "???")

	var correct := accused_peer_id == liar_peer_id
	var verdict := "Richtig erwischt!" if correct else "Falsch geraten!"
	result_label.text = "Ihr habt beschuldigt: %s\n%s\nDer Baulügner war: %s" % [accused_name, verdict, liar_name]


func _on_back_pressed() -> void:
	GameState.request_return_to_lobby()
