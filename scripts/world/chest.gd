extends Interactable
class_name Chest
## A lootable chest that grants items when opened.

@export var loot_items: Array[ItemData] = []
@export var gold_amount: int = 0


func _on_interact(_player: CharacterBody3D) -> void:
	for item in loot_items:
		InventoryManager.add_item(item)
	if gold_amount > 0:
		InventoryManager.add_gold(gold_amount)
	# TODO: Play open animation
