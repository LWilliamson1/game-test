extends Resource
class_name DialogueData
## A full dialogue tree. Each entry is a node with text and optional choices.

@export var dialogue_id: String = ""
@export var entries: Array[DialogueEntry] = []


func get_entry(entry_id: String) -> DialogueEntry:
	for entry in entries:
		if entry.id == entry_id:
			return entry
	return null


func get_start_entry() -> DialogueEntry:
	if entries.size() > 0:
		return entries[0]
	return null
