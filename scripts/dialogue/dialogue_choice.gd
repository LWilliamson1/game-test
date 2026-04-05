extends Resource
class_name DialogueChoice
## A single choice the player can make in dialogue.

@export var text: String = ""
@export var next_entry_id: String = ""
@export var required_item_id: String = ""
@export var required_quest_id: String = ""
@export var skill_check: String = ""  # e.g., "persuasion:50"
