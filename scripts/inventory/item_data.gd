extends Resource
class_name ItemData
## Base resource for all items in the game. Create .tres files from this.

enum ItemType { WEAPON, ARMOR, POTION, FOOD, KEY, MISC, SCROLL, INGREDIENT }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MISC
@export var rarity: Rarity = Rarity.COMMON
@export var weight: float = 1.0
@export var value: int = 0
@export var stackable: bool = false
@export var max_stack: int = 1
@export var can_drop: bool = true
@export var can_use: bool = false

## Optional stats for equipment
@export_group("Equipment Stats")
@export var damage: float = 0.0
@export var armor_rating: float = 0.0
@export var health_bonus: float = 0.0
@export var stamina_bonus: float = 0.0
@export var magicka_bonus: float = 0.0

## Optional effect for consumables
@export_group("Consumable Effects")
@export var heal_amount: float = 0.0
@export var stamina_restore: float = 0.0
@export var magicka_restore: float = 0.0
@export var effect_duration: float = 0.0
