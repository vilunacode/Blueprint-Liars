extends Resource
class_name SlotDefinition

@export var id: StringName
@export var expected_part_id: StringName
@export var local_position: Vector3 = Vector3.ZERO
@export var local_rotation_degrees: Vector3 = Vector3.ZERO

## IDs benachbarter Slots - werden in Schritt 11 zu Generic6DOFJoint3D-Verbindungen,
## sobald beim Stresstest von Slot- auf Rigidbody-Physik umgeschaltet wird.
@export var connected_slot_ids: Array[StringName] = []
