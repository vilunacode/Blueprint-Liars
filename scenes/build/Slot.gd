extends Node3D

## Visueller Platzhalter für einen Bausteckplatz. Zeigt eine halbtransparente
## Box in Größe/Farbe des ERWARTETEN Teils - noch nicht interaktiv (Schritt 6).

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var slot_definition: SlotDefinition


func setup(definition: SlotDefinition) -> void:
	slot_definition = definition
	name = String(definition.id)
	position = definition.local_position
	rotation_degrees = definition.local_rotation_degrees

	var expected_part: PartData = PartLibrary.get_part(definition.expected_part_id)
	if expected_part == null:
		return

	var box := BoxMesh.new()
	box.size = expected_part.size
	mesh_instance.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(expected_part.color.r, expected_part.color.g, expected_part.color.b, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
