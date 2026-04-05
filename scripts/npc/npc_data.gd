extends Resource
class_name NPCData
## Defines an NPC's identity, stats, and behavior.

enum Attitude { FRIENDLY, NEUTRAL, HOSTILE }
enum Role { MERCHANT, QUEST_GIVER, GUARD, VILLAGER, COMPANION, ENEMY }

@export var npc_id: String = ""
@export var display_name: String = ""
@export_multiline var bio: String = ""
@export var role: Role = Role.VILLAGER
@export var attitude: Attitude = Attitude.NEUTRAL
@export var level: int = 1

@export_group("Combat")
@export var max_health: float = 50.0
@export var damage: float = 5.0
@export var armor: float = 0.0

@export_group("Dialogue")
@export var dialogue: DialogueData
@export var greeting_line: String = ""

@export_group("Merchant")
@export var shop_items: Array[ItemData] = []
