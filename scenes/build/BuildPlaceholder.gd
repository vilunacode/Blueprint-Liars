extends Control

## Temporärer Platzhalter, damit der Phasenwechsel Lobby -> Build sichtbar/testbar ist.
## Wird in Schritt 5 durch die echte BuildArena (Slots, Bauteile) ersetzt.

@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = multiplayer.is_server()
	RoleManager.role_assigned.connect(_on_role_assigned)
	_refresh_info_label()


func _refresh_info_label() -> void:
	var role_text := "unbekannt (warte auf Rollenvergabe...)"
	if RoleManager.my_blueprint != null:
		var role_name := "Baulügner" if RoleManager.am_i_liar else "ehrlicher Bauarbeiter"
		role_text = "%s\nGeladene Anleitung: %s (%d Slots)" % [role_name, RoleManager.my_blueprint.display_name, RoleManager.my_blueprint.slots.size()]
	info_label.text = "Bauphase (Platzhalter)\nBauarena folgt in Schritt 5.\nSpieler in der Runde: %d\n\nDeine Rolle: %s" % [NetworkManager.players.size(), role_text]


func _on_role_assigned(_is_liar: bool, _blueprint: Blueprint) -> void:
	_refresh_info_label()


func _on_back_pressed() -> void:
	GameState.request_return_to_lobby()
