extends Node3D

const SLOT_SCENE := preload("res://scenes/build/Slot.tscn")

@onready var slots_container: Node3D = $Slots
@onready var info_label: Label = $UI/VBoxContainer/InfoLabel
@onready var back_button: Button = $UI/VBoxContainer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = multiplayer.is_server()
	_spawn_slots()
	_update_info_label()


func _spawn_slots() -> void:
	var blueprint: Blueprint = RoleManager.my_blueprint
	if blueprint == null:
		return
	for slot_definition in blueprint.slots:
		var slot := SLOT_SCENE.instantiate()
		slots_container.add_child(slot)
		slot.setup(slot_definition)


func _update_info_label() -> void:
	var role_name := "Baulügner" if RoleManager.am_i_liar else "ehrlicher Bauarbeiter"
	var blueprint_name := "?"
	if RoleManager.my_blueprint != null:
		blueprint_name = RoleManager.my_blueprint.display_name
	info_label.text = "Deine Rolle: %s\nAnleitung: %s" % [role_name, blueprint_name]


func _on_back_pressed() -> void:
	GameState.request_return_to_lobby()
