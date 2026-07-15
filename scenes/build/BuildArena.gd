extends Node3D

const SLOT_SCENE := preload("res://scenes/build/Slot.tscn")
const BUILD_DURATION_SECONDS := 180.0
const INSPECTION_COST_SECONDS := 5.0

@onready var slots_container: Node3D = $Slots
@onready var info_label: Label = $UI/VBoxContainer/InfoLabel
@onready var back_button: Button = $UI/VBoxContainer/BackButton
@onready var hand_container: HBoxContainer = $UI/HandContainer
@onready var time_label: Label = $UI/TimeLabel

var slots_by_id: Dictionary = {}  # StringName -> Slot-Node
var hand_counts: Dictionary = {}  # StringName -> int, rein lokal/optisch
var selected_part_id: StringName = &""
var inspected_part_ids: Dictionary = {}  # StringName -> bool, rein lokal/optisch
var remaining_time: float = BUILD_DURATION_SECONDS

var filled_slots: Dictionary = {}  # StringName -> StringName, Host-autoritativ
var peer_hand_counts: Dictionary = {}  # int (peer_id) -> Dictionary, Host-autoritativ


func _ready() -> void:
	get_viewport().physics_object_picking = true
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = multiplayer.is_server()
	BuildResult.reset()
	_spawn_slots()
	_build_hand()
	_update_info_label()
	remaining_time = BUILD_DURATION_SECONDS
	_update_time_label()


func _process(delta: float) -> void:
	if remaining_time <= 0.0:
		return
	remaining_time = max(0.0, remaining_time - delta)
	_update_time_label()
	if remaining_time <= 0.0 and multiplayer.is_server():
		GameState.request_reveal()


func _update_time_label() -> void:
	if remaining_time <= 0.0:
		time_label.text = "Zeit abgelaufen!"
		return
	var total_seconds := int(ceil(remaining_time))
	time_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


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

		var item_box := HBoxContainer.new()

		var label_text := "%s x%d" % [part.display_name, count]
		if inspected_part_ids.get(part_id, false):
			label_text += " (%.2fm)" % part.size.x
		var select_button := Button.new()
		select_button.text = label_text
		select_button.toggle_mode = true
		select_button.button_group = group
		select_button.pressed.connect(_on_hand_button_pressed.bind(part_id))
		item_box.add_child(select_button)

		var inspect_button := Button.new()
		inspect_button.text = "Prüfen"
		inspect_button.disabled = inspected_part_ids.get(part_id, false)
		inspect_button.pressed.connect(_on_inspect_pressed.bind(part_id))
		item_box.add_child(inspect_button)

		hand_container.add_child(item_box)


func _on_hand_button_pressed(part_id: StringName) -> void:
	selected_part_id = part_id


func _on_inspect_pressed(part_id: StringName) -> void:
	# Deckt die tatsächliche Größe eines Teils auf - kostet Zeit vom Bau-Timer,
	# das ist die Risiko/Nutzen-Abwägung aus dem Spielkonzept.
	if inspected_part_ids.get(part_id, false):
		return
	inspected_part_ids[part_id] = true
	remaining_time = max(0.0, remaining_time - INSPECTION_COST_SECONDS)
	_update_time_label()
	_refresh_hand_ui()


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
	BuildResult.record_placement(slot_id, part_id)
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
