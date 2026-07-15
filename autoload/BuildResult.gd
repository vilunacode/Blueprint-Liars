extends Node

## Überlebt den Phasenwechsel Build -> Reveal: hält fest, welches Teil
## tatsächlich in welchem Slot gelandet ist. Wird von BuildArena bei jeder
## bestätigten Platzierung (auf allen Peers gleichermaßen) geschrieben.

var filled_slots: Dictionary = {}  # StringName -> StringName


func record_placement(slot_id: StringName, part_id: StringName) -> void:
	filled_slots[slot_id] = part_id


func reset() -> void:
	filled_slots.clear()
