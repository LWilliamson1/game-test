extends Resource
class_name QuestData
## Defines a quest with objectives, rewards, and metadata.

enum QuestType { MAIN, SIDE, MISC }

@export var quest_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var quest_type: QuestType = QuestType.SIDE
@export var objectives: Array[QuestObjective] = []
@export var prerequisite_quest_ids: Array[String] = []

@export_group("Rewards")
@export var reward_xp: float = 0.0
@export var reward_gold: int = 0
@export var reward_item_ids: Array[String] = []
