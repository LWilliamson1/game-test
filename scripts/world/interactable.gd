extends StaticBody3D
class_name Interactable
## Base class for interactable objects in the world (doors, chests, levers, etc.)

@export var interaction_text: String = "Interact"
@export var requires_key_id: String = ""
@export var one_time_use: bool = false

var has_been_used: bool = false

signal used(by: CharacterBody3D)


func interact(player: CharacterBody3D) -> void:
	if one_time_use and has_been_used:
		return

	if not requires_key_id.is_empty():
		if not InventoryManager.has_item(requires_key_id):
			return  # Could show "locked" message

	has_been_used = true
	_on_interact(player)
	used.emit(player)


## Override this in subclasses to define specific behavior.
func _on_interact(_player: CharacterBody3D) -> void:
	pass
