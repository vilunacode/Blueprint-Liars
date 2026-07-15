extends Node3D

## Kamera fährt automatisch um die fertige Konstruktion; Spieler können
## Slots anklicken, um sie für alle sichtbar zu markieren ("pingen").
## Die Abstimmung (Schritt 10) baut auf den hier gesammelten Pings auf.

const SLOT_SCENE := preload("res://scenes/build/Slot.tscn")
const ORBIT_SPEED_DEGREES := 12.0

@onready var slots_container: Node3D = $Slots
@onready var camera_pivot: Node3D = $CameraPivot
@onready var info_label: Label = $UI/InfoLabel

var slots_by_id: Dictionary = {}  # StringName -> Slot-Node


func _ready() -> void:
	get_viewport().physics_object_picking = true
	info_label.text = "Aufdeckungsphase - klicke verdächtige Stellen an, um sie zu markieren"
	_spawn_result_slots()


func _process(delta: float) -> void:
	camera_pivot.rotate_y(deg_to_rad(ORBIT_SPEED_DEGREES) * delta)


func _spawn_result_slots() -> void:
	var blueprint: Blueprint = RoleManager.my_blueprint
	if blueprint == null:
		return
	for slot_definition in blueprint.slots:
		var slot := SLOT_SCENE.instantiate()
		slots_container.add_child(slot)
		slot.setup(slot_definition)
		var placed_part_id: StringName = BuildResult.filled_slots.get(slot_definition.id, &"")
		if placed_part_id != &"":
			var part: PartData = PartLibrary.get_part(placed_part_id)
			if part != null:
				slot.show_placed_part(part)
		slot.clicked.connect(_on_slot_clicked)
		slots_by_id[slot_definition.id] = slot


func _on_slot_clicked(slot: Node3D) -> void:
	if multiplayer.is_server():
		_broadcast_ping.rpc(slot.slot_definition.id)
	else:
		_request_ping.rpc_id(1, slot.slot_definition.id)


@rpc("any_peer", "reliable")
func _request_ping(slot_id: StringName) -> void:
	if not multiplayer.is_server():
		return
	_broadcast_ping.rpc(slot_id)


@rpc("authority", "call_local", "reliable")
func _broadcast_ping(slot_id: StringName) -> void:
	var slot: Node3D = slots_by_id.get(slot_id)
	if slot != null:
		slot.mark_pinged()
