extends Node3D

## Ein Bausteckplatz: zeigt erst eine halbtransparente "Geist"-Box in Größe/Farbe
## des erwarteten Teils, wird per Klick anvisiert und zeigt nach Bestätigung durch
## den Host das tatsächlich platzierte Teil (deckend).

signal clicked(slot: Node3D)

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var click_area: Area3D = $ClickArea
@onready var collision_shape: CollisionShape3D = $ClickArea/CollisionShape3D

var slot_definition: SlotDefinition
var placed_part_id: StringName = &""


func setup(definition: SlotDefinition) -> void:
	slot_definition = definition
	name = String(definition.id)
	position = definition.local_position
	rotation_degrees = definition.local_rotation_degrees

	var expected_part: PartData = PartLibrary.get_part(definition.expected_part_id)
	if expected_part == null:
		return

	_apply_visual(expected_part, true)

	var shape := BoxShape3D.new()
	shape.size = expected_part.size
	collision_shape.shape = shape
	click_area.input_ray_pickable = true
	click_area.input_event.connect(_on_input_event)


func is_filled() -> bool:
	return placed_part_id != &""


func show_placed_part(part: PartData) -> void:
	placed_part_id = part.id
	_apply_visual(part, false)


func _apply_visual(part: PartData, is_ghost: bool) -> void:
	var box := BoxMesh.new()
	box.size = part.size
	mesh_instance.mesh = box

	var material := StandardMaterial3D.new()
	var alpha := 0.35 if is_ghost else 1.0
	material.albedo_color = Color(part.color.r, part.color.g, part.color.b, alpha)
	if is_ghost:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
