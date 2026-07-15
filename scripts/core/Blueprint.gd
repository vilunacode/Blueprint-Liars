extends Resource
class_name Blueprint

## Eine vollständige Bauanleitung. "Ehrliche" und Baulügner-Variante eines
## Bauobjekts sind zwei Blueprint-Instanzen, die sich in genau den Slots
## unterscheiden, in denen sabotiert werden kann - keine Code-Verzweigung.

@export var display_name: String
@export var slots: Array[SlotDefinition] = []


func get_slot(slot_id: StringName) -> SlotDefinition:
	for slot in slots:
		if slot.id == slot_id:
			return slot
	return null
