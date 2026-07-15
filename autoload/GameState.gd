extends Node

## Phasen-Statemachine der Runde. Nur der Host wechselt aktiv die Phase;
## Clients folgen der autoritativen RPC.

enum Phase { LOBBY, BUILD, REVEAL, STRESSTEST, SCORING }

signal phase_changed(new_phase: Phase)

var current_phase: Phase = Phase.LOBBY


@rpc("authority", "call_local", "reliable")
func _set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)


func request_start_game() -> void:
	# Nur der Host darf die Runde tatsächlich starten.
	if not multiplayer.is_server():
		return
	_set_phase.rpc(Phase.BUILD)


func request_return_to_lobby() -> void:
	if not multiplayer.is_server():
		return
	_set_phase.rpc(Phase.LOBBY)
