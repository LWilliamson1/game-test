extends Resource
class_name DialogueEntry
## A single node in a dialogue tree.

@export var id: String = ""
@export var speaker_name: String = ""
@export_multiline var text: String = ""
@export var choices: Array[DialogueChoice] = []
@export var next_entry_id: String = ""  # Used when there are no choices (linear)

## Optional conditions and effects
@export_group("Conditions")
@export var required_quest_id: String = ""
@export var required_item_id: String = ""

@export_group("Effects")
@export var grant_quest_id: String = ""
@export var grant_item_id: String = ""
@export var grant_xp: float = 0.0
@export var grant_gold: int = 0


func has_choices() -> bool:
	return choices.size() > 0
