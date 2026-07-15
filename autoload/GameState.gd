extends Node

## Phasen-Statemachine der Runde. Nur der Host wechselt aktiv die Phase;
## Clients folgen der autoritativen RPC.

enum Phase { LOBBY, BUILD, REVEAL, VOTING, STRESSTEST, SCORING }

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
	# Rollenvergabe muss vor dem Phasenwechsel abgeschlossen sein: beide laufen
	# reliable/geordnet über denselben Kanal pro Peer, die Blueprint-RPC kommt
	# also vor der Phasen-RPC an - auf diese Reihenfolge verlässt sich die
	# BuildArena beim Anzeigen der Rolle.
	RoleManager.assign_roles()
	_set_phase.rpc(Phase.BUILD)


func request_return_to_lobby() -> void:
	if not multiplayer.is_server():
		return
	_set_phase.rpc(Phase.LOBBY)


func request_reveal() -> void:
	# Nur der Host darf auslösen - der Host-Timer ist die autoritative Uhr
	# für den Phasenübergang, auch wenn jeder Client seinen Countdown rein
	# lokal anzeigt (siehe BuildArena).
	if not multiplayer.is_server():
		return
	_set_phase.rpc(Phase.REVEAL)


func request_voting() -> void:
	if not multiplayer.is_server():
		return
	_set_phase.rpc(Phase.VOTING)
