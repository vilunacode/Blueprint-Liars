extends Control

## Temporärer Platzhalter, damit der Phasenwechsel Lobby -> Build sichtbar/testbar ist.
## Wird in Schritt 5 durch die echte BuildArena (Slots, Bauteile) ersetzt.

@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = multiplayer.is_server()
	info_label.text = "Bauphase (Platzhalter)\nBauarena folgt in Schritt 5.\nSpieler in der Runde: %d" % NetworkManager.players.size()


func _on_back_pressed() -> void:
	GameState.request_return_to_lobby()
