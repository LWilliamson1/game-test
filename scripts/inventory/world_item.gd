extends RigidBody3D
class_name WorldItem
## A pickable item in the world. Attach to a RigidBody3D with a mesh and collision.

@export var item_data: ItemData
@export var quantity: int = 1

@onready var label: Label3D = $Label3D


func _ready() -> void:
	if label and item_data:
		label.text = item_data.display_name
		label.visible = false


func interact(player: CharacterBody3D) -> void:
	if item_data and InventoryManager.add_item(item_data, quantity):
		queue_free()


func _on_mouse_entered() -> void:
	if label:
		label.visible = true


func _on_mouse_exited() -> void:
	if label:
		label.visible = false
