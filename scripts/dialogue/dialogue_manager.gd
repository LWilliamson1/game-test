extends Node
## Global dialogue manager (autoloaded). Handles starting, advancing, and ending dialogues.

signal dialogue_started(dialogue: DialogueData)
signal dialogue_entry_shown(entry: DialogueEntry)
signal dialogue_ended
signal choice_made(choice: DialogueChoice)

var current_dialogue: DialogueData = null
var current_entry: DialogueEntry = null
var is_active: bool = false


func start_dialogue(dialogue: DialogueData) -> void:
	if is_active or dialogue == null:
		return
	current_dialogue = dialogue
	is_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	dialogue_started.emit(dialogue)
	show_entry(dialogue.get_start_entry())


func show_entry(entry: DialogueEntry) -> void:
	if entry == null:
		end_dialogue()
		return
	current_entry = entry
	_apply_entry_effects(entry)
	dialogue_entry_shown.emit(entry)


func advance() -> void:
	if not is_active or current_entry == null:
		return
	if current_entry.has_choices():
		return  # Wait for player choice
	if current_entry.next_entry_id.is_empty():
		end_dialogue()
	else:
		var next := current_dialogue.get_entry(current_entry.next_entry_id)
		show_entry(next)


func select_choice(index: int) -> void:
	if not is_active or current_entry == null:
		return
	if index < 0 or index >= current_entry.choices.size():
		return
	var choice := current_entry.choices[index]
	choice_made.emit(choice)
	if choice.next_entry_id.is_empty():
		end_dialogue()
	else:
		var next := current_dialogue.get_entry(choice.next_entry_id)
		show_entry(next)


func end_dialogue() -> void:
	current_dialogue = null
	current_entry = null
	is_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dialogue_ended.emit()


func _apply_entry_effects(entry: DialogueEntry) -> void:
	if entry.grant_xp > 0:
		# Find player stats and grant XP
		var player := get_tree().get_first_node_in_group("player")
		if player:
			var stats: PlayerStats = player.get_node_or_null("PlayerStats")
			if stats:
				stats.add_experience(entry.grant_xp)

	if entry.grant_gold > 0:
		InventoryManager.add_gold(entry.grant_gold)

	if not entry.grant_quest_id.is_empty():
		QuestManager.start_quest(entry.grant_quest_id)
