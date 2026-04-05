extends Resource
class_name QuestObjective
## A single objective within a quest.

enum ObjectiveType { TALK_TO, COLLECT, KILL, REACH_LOCATION, USE_ITEM }

@export var objective_id: String = ""
@export var description: String = ""
@export var type: ObjectiveType = ObjectiveType.TALK_TO
@export var target_id: String = ""  # NPC id, item id, location id, etc.
@export var required_count: int = 1
@export var is_optional: bool = false
