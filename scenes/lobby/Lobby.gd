extends Control

const PLAYER_CARD_SCENE := preload("res://scenes/lobby/LobbyPlayerCard.tscn")

@onready var name_edit: LineEdit = $VBoxContainer/NameEdit
@onready var address_edit: LineEdit = $VBoxContainer/AddressEdit
@onready var host_button: Button = $VBoxContainer/HButtonBox/HostButton
@onready var join_button: Button = $VBoxContainer/HButtonBox/JoinButton
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var player_list: VBoxContainer = $VBoxContainer/PlayerList
@onready var status_label: Label = $VBoxContainer/StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	start_button.disabled = true

	NetworkManager.player_connected.connect(_on_player_list_updated)
	NetworkManager.player_disconnected.connect(_on_player_list_updated)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

	address_edit.text = "127.0.0.1"
	name_edit.text = "Spieler%d" % randi_range(1, 999)

	# Falls die Lobby-Szene erneut geladen wird, während bereits eine Verbindung besteht
	# (z. B. Rückkehr aus Scoring), sofort den aktuellen Stand anzeigen.
	_refresh_player_list()


func _on_host_pressed() -> void:
	var err := NetworkManager.create_game(name_edit.text)
	if err != OK:
		status_label.text = "Hosten fehlgeschlagen (Fehler %d)" % err
		return
	status_label.text = "Host gestartet auf Port %d" % NetworkManager.PORT
	host_button.disabled = true
	join_button.disabled = true
	_refresh_player_list()


func _on_join_pressed() -> void:
	var err := NetworkManager.join_game(address_edit.text, name_edit.text)
	if err != OK:
		status_label.text = "Verbindung fehlgeschlagen (Fehler %d)" % err
		return
	status_label.text = "Verbinde zu %s..." % address_edit.text
	host_button.disabled = true
	join_button.disabled = true


func _on_player_list_updated(_peer_id: int = -1, _info: Dictionary = {}) -> void:
	status_label.text = "Verbunden (%d Spieler)" % NetworkManager.players.size()
	_refresh_player_list()


func _refresh_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()
	for peer_id in NetworkManager.players.keys():
		var info: Dictionary = NetworkManager.players[peer_id]
		var card := PLAYER_CARD_SCENE.instantiate()
		player_list.add_child(card)
		card.set_player_name(info.get("name", "???"))
		card.set_host_flag(peer_id == 1)

	var connected := multiplayer.multiplayer_peer != null
	start_button.disabled = not (connected and multiplayer.is_server())


func _on_start_pressed() -> void:
	GameState.request_start_game()


func _on_server_disconnected() -> void:
	status_label.text = "Verbindung zum Host verloren."
	host_button.disabled = false
	join_button.disabled = false
	_refresh_player_list()
