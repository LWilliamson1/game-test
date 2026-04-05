extends CanvasLayer
## Inventory screen UI — shows items, weight, gold, and item details.

@onready var panel: PanelContainer = $Panel
@onready var item_list: ItemList = $Panel/HSplitContainer/ItemList
@onready var item_name_label: Label = $Panel/HSplitContainer/DetailPanel/VBoxContainer/ItemName
@onready var item_desc_label: RichTextLabel = $Panel/HSplitContainer/DetailPanel/VBoxContainer/ItemDescription
@onready var item_stats_label: Label = $Panel/HSplitContainer/DetailPanel/VBoxContainer/ItemStats
@onready var use_button: Button = $Panel/HSplitContainer/DetailPanel/VBoxContainer/UseButton
@onready var drop_button: Button = $Panel/HSplitContainer/DetailPanel/VBoxContainer/DropButton
@onready var weight_label: Label = $Panel/WeightLabel

var is_open: bool = false
var selected_index: int = -1


func _ready() -> void:
	panel.visible = false
	InventoryManager.inventory_changed.connect(_refresh)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	item_list.item_selected.connect(_on_item_selected)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()


func toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh()
		get_tree().paused = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false


func _refresh() -> void:
	item_list.clear()
	for entry in InventoryManager.items:
		var item: ItemData = entry.item
		var qty: int = entry.quantity
		var label_text := item.display_name
		if qty > 1:
			label_text += " (x" + str(qty) + ")"
		item_list.add_item(label_text, item.icon)

	var weight := InventoryManager.get_current_weight()
	weight_label.text = "Weight: %.1f / %.1f" % [weight, InventoryManager.max_weight]
	_clear_detail()


func _on_item_selected(index: int) -> void:
	selected_index = index
	if index < 0 or index >= InventoryManager.items.size():
		_clear_detail()
		return

	var entry: Dictionary = InventoryManager.items[index]
	var item: ItemData = entry.item
	item_name_label.text = item.display_name
	item_desc_label.text = item.description

	var stats_text := "Weight: %.1f | Value: %d" % [item.weight, item.value]
	if item.damage > 0:
		stats_text += "\nDamage: %.0f" % item.damage
	if item.armor_rating > 0:
		stats_text += "\nArmor: %.0f" % item.armor_rating
	if item.heal_amount > 0:
		stats_text += "\nHeals: %.0f" % item.heal_amount
	item_stats_label.text = stats_text

	use_button.visible = item.can_use
	drop_button.visible = item.can_drop


func _clear_detail() -> void:
	item_name_label.text = ""
	item_desc_label.text = "Select an item to view details."
	item_stats_label.text = ""
	use_button.visible = false
	drop_button.visible = false
	selected_index = -1


func _on_use_pressed() -> void:
	if selected_index >= 0 and selected_index < InventoryManager.items.size():
		var item: ItemData = InventoryManager.items[selected_index].item
		InventoryManager.use_item(item.id)


func _on_drop_pressed() -> void:
	if selected_index >= 0 and selected_index < InventoryManager.items.size():
		var item: ItemData = InventoryManager.items[selected_index].item
		InventoryManager.remove_item(item.id)
