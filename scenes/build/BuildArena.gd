extends Node3D

const SLOT_SCENE := preload("res://scenes/build/Slot.tscn")

@onready var slots_container: Node3D = $Slots
@onready var info_label: Label = $UI/VBoxContainer/InfoLabel
@onready var back_button: Button = $UI/VBoxContainer/BackButton
@onready var hand_container: HBoxContainer = $UI/HandContainer

var slots_by_id: Dictionary = {}  # StringName -> Slot-Node
var hand_counts: Dictionary = {}  # StringName -> int, rein lokal/optisch
var selected_part_id: StringName = &""

var filled_slots: Dictionary = {}  # StringName -> StringName, Host-autoritativ
var peer_hand_counts: Dictionary = {}  # int (peer_id) -> Dictionary, Host-autoritativ


func _ready() -> void:
	get_viewport().physics_object_picking = true
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = multiplayer.is_server()
	_spawn_slots()
	_build_hand()
	_update_info_label()


func _spawn_slots() -> void:
	var blueprint: Blueprint = RoleManager.my_blueprint
	if blueprint == null:
		return
	for slot_definition in blueprint.slots:
		var slot := SLOT_SCENE.instantiate()
		slots_container.add_child(slot)
		slot.setup(slot_definition)
		slot.clicked.connect(_on_slot_clicked)
		slots_by_id[slot_definition.id] = slot


func _build_hand() -> void:
	var blueprint: Blueprint = RoleManager.my_blueprint
	if blueprint == null:
		return
	hand_counts.clear()
	for slot_definition in blueprint.slots:
		var part_id: StringName = slot_definition.expected_part_id
		hand_counts[part_id] = hand_counts.get(part_id, 0) + 1
	_refresh_hand_ui()


func _refresh_hand_ui() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	var group := ButtonGroup.new()
	for part_id in hand_counts.keys():
		var count: int = hand_counts[part_id]
		if count <= 0:
			continue
		var part: PartData = PartLibrary.get_part(part_id)
		var button := Button.new()
		button.text = "%s x%d" % [part.display_name, count]
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_on_hand_button_pressed.bind(part_id))
		hand_container.add_child(button)


func _on_hand_button_pressed(part_id: StringName) -> void:
	selected_part_id = part_id


func _on_slot_clicked(slot: Node3D) -> void:
	if selected_part_id == &"" or slot.is_filled():
		return
	var part_id := selected_part_id
	# Optimistisch: Hand-Item sofort lokal verbrauchen. Ein serverseitiges
	# Rollback bei Ablehnung (z. B. Slot inzwischen belegt) gibt's noch nicht -
	# für die kleinen Testrunden hier unkritisch, echte Race Conditions selten.
	hand_counts[part_id] = max(0, hand_counts.get(part_id, 0) - 1)
	_refresh_hand_ui()
	selected_part_id = &""

	if multiplayer.is_server():
		# Host ruft sich selbst direkt auf statt per rpc_id (Self-Targeting
		# ohne "call_local" würde sonst nicht auslösen, siehe RoleManager).
		_handle_place_request(multiplayer.get_unique_id(), slot.slot_definition.id, part_id)
	else:
		_request_place.rpc_id(1, slot.slot_definition.id, part_id)


@rpc("any_peer", "reliable")
func _request_place(slot_id: StringName, part_id: StringName) -> void:
	if not multiplayer.is_server():
		return
	_handle_place_request(multiplayer.get_remote_sender_id(), slot_id, part_id)


func _handle_place_request(sender_id: int, slot_id: StringName, part_id: StringName) -> void:
	if filled_slots.has(slot_id):
		return
	if not peer_hand_counts.has(sender_id):
		peer_hand_counts[sender_id] = RoleManager.get_hand_counts_for_peer(sender_id)
	var hand: Dictionary = peer_hand_counts[sender_id]
	if hand.get(part_id, 0) <= 0:
		return
	hand[part_id] -= 1
	filled_slots[slot_id] = part_id
	_broadcast_placement.rpc(slot_id, part_id)


@rpc("authority", "call_local", "reliable")
func _broadcast_placement(slot_id: StringName, part_id: StringName) -> void:
	filled_slots[slot_id] = part_id
	var slot: Node3D = slots_by_id.get(slot_id)
	if slot == null:
		return
	var part: PartData = PartLibrary.get_part(part_id)
	if part != null:
		slot.show_placed_part(part)


func _update_info_label() -> void:
	var role_name := "Baulügner" if RoleManager.am_i_liar else "ehrlicher Bauarbeiter"
	var blueprint_name := "?"
	if RoleManager.my_blueprint != null:
		blueprint_name = RoleManager.my_blueprint.display_name
	info_label.text = "Deine Rolle: %s\nAnleitung: %s" % [role_name, blueprint_name]


func _on_back_pressed() -> void:
	GameState.request_return_to_lobby()
