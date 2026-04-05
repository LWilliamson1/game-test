extends Node
## Global inventory manager (autoloaded). Handles adding, removing, using items.

signal item_added(item: ItemData, quantity: int)
signal item_removed(item: ItemData, quantity: int)
signal item_used(item: ItemData)
signal inventory_changed
signal gold_changed(new_amount: int)

var items: Array[Dictionary] = []  # [{item: ItemData, quantity: int}]
var gold: int = 0
var max_weight: float = 200.0


func add_item(item: ItemData, quantity: int = 1) -> bool:
	if get_current_weight() + item.weight * quantity > max_weight:
		return false

	if item.stackable:
		for entry in items:
			if entry.item.id == item.id:
				entry.quantity = min(entry.quantity + quantity, item.max_stack)
				item_added.emit(item, quantity)
				inventory_changed.emit()
				return true

	items.append({"item": item, "quantity": quantity})
	item_added.emit(item, quantity)
	inventory_changed.emit()
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(items.size()):
		if items[i].item.id == item_id:
			items[i].quantity -= quantity
			var removed_item: ItemData = items[i].item
			if items[i].quantity <= 0:
				items.remove_at(i)
			item_removed.emit(removed_item, quantity)
			inventory_changed.emit()
			return true
	return false


func use_item(item_id: String) -> bool:
	for entry in items:
		if entry.item.id == item_id and entry.item.can_use:
			item_used.emit(entry.item)
			if entry.item.stackable:
				remove_item(item_id, 1)
			return true
	return false


func has_item(item_id: String, quantity: int = 1) -> bool:
	for entry in items:
		if entry.item.id == item_id and entry.quantity >= quantity:
			return true
	return false


func get_item_count(item_id: String) -> int:
	for entry in items:
		if entry.item.id == item_id:
			return entry.quantity
	return 0


func get_current_weight() -> float:
	var total: float = 0.0
	for entry in items:
		total += entry.item.weight * entry.quantity
	return total


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func remove_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func get_items_by_type(item_type: ItemData.ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in items:
		if entry.item.item_type == item_type:
			result.append(entry)
	return result


func get_save_data() -> Dictionary:
	var item_list: Array = []
	for entry in items:
		item_list.append({
			"item_path": entry.item.resource_path,
			"quantity": entry.quantity,
		})
	return {"items": item_list, "gold": gold}


func load_save_data(data: Dictionary) -> void:
	items.clear()
	gold = data.get("gold", 0)
	for entry in data.get("items", []):
		var item := load(entry.item_path) as ItemData
		if item:
			items.append({"item": item, "quantity": entry.quantity})
	inventory_changed.emit()
	gold_changed.emit(gold)
