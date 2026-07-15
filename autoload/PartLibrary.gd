extends Node

## Lädt alle bekannten Bauteil-Resourcen einmal und macht sie per ID auffindbar -
## gebraucht von Slot (Platzhalter-Größe/Farbe) und später vom Bauteil-Handling (Schritt 6).

const PART_PATHS := [
	"res://resources/parts/side_panel.tres",
	"res://resources/parts/shelf_board.tres",
	"res://resources/parts/shelf_board_short.tres",
	"res://resources/parts/back_panel.tres",
]

var _parts_by_id: Dictionary = {}


func _ready() -> void:
	for path in PART_PATHS:
		var part: PartData = load(path)
		_parts_by_id[part.id] = part


func get_part(part_id: StringName) -> PartData:
	return _parts_by_id.get(part_id)
