extends Node
## Global quest manager (autoloaded). Tracks active, completed, and failed quests.

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String, current: int, required: int)
signal quest_log_changed

## All quest definitions keyed by quest_id
var quest_registry: Dictionary = {}

## Active quest tracking: quest_id -> {data: QuestData, objectives: {obj_id: current_count}}
var active_quests: Dictionary = {}
var completed_quest_ids: Array[String] = []
var failed_quest_ids: Array[String] = []


func register_quest(quest: QuestData) -> void:
	quest_registry[quest.quest_id] = quest


func start_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id) or quest_id in completed_quest_ids:
		return false
	var quest: QuestData = quest_registry.get(quest_id)
	if quest == null:
		push_warning("Quest not found in registry: " + quest_id)
		return false

	# Check prerequisites
	for prereq in quest.prerequisite_quest_ids:
		if prereq not in completed_quest_ids:
			return false

	var objective_progress: Dictionary = {}
	for obj in quest.objectives:
		objective_progress[obj.objective_id] = 0

	active_quests[quest_id] = {
		"data": quest,
		"objectives": objective_progress,
	}
	quest_started.emit(quest_id)
	quest_log_changed.emit()
	return true


func update_objective(quest_id: String, objective_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	var quest_state: Dictionary = active_quests[quest_id]
	if not quest_state.objectives.has(objective_id):
		return

	quest_state.objectives[objective_id] += amount
	var quest: QuestData = quest_state.data
	var objective: QuestObjective = _find_objective(quest, objective_id)
	if objective:
		var current: int = quest_state.objectives[objective_id]
		objective_updated.emit(quest_id, objective_id, current, objective.required_count)

	_check_quest_completion(quest_id)


func fail_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		active_quests.erase(quest_id)
		failed_quest_ids.append(quest_id)
		quest_failed.emit(quest_id)
		quest_log_changed.emit()


func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)


func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quest_ids


func get_active_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in active_quests:
		result.append(active_quests[quest_id])
	return result


func _check_quest_completion(quest_id: String) -> void:
	var quest_state: Dictionary = active_quests[quest_id]
	var quest: QuestData = quest_state.data

	for obj in quest.objectives:
		if obj.is_optional:
			continue
		var current: int = quest_state.objectives.get(obj.objective_id, 0)
		if current < obj.required_count:
			return  # Not yet complete

	_complete_quest(quest_id)


func _complete_quest(quest_id: String) -> void:
	var quest_state: Dictionary = active_quests[quest_id]
	var quest: QuestData = quest_state.data

	# Grant rewards
	if quest.reward_xp > 0:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			var stats: PlayerStats = player.get_node_or_null("PlayerStats")
			if stats:
				stats.add_experience(quest.reward_xp)

	if quest.reward_gold > 0:
		InventoryManager.add_gold(quest.reward_gold)

	active_quests.erase(quest_id)
	completed_quest_ids.append(quest_id)
	quest_completed.emit(quest_id)
	quest_log_changed.emit()


func _find_objective(quest: QuestData, objective_id: String) -> QuestObjective:
	for obj in quest.objectives:
		if obj.objective_id == objective_id:
			return obj
	return null


func get_save_data() -> Dictionary:
	var active: Dictionary = {}
	for quest_id in active_quests:
		active[quest_id] = active_quests[quest_id].objectives.duplicate()
	return {
		"active": active,
		"completed": completed_quest_ids.duplicate(),
		"failed": failed_quest_ids.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	completed_quest_ids = Array(data.get("completed", []), TYPE_STRING, "", null)
	failed_quest_ids = Array(data.get("failed", []), TYPE_STRING, "", null)
	for quest_id in data.get("active", {}):
		if quest_registry.has(quest_id):
			active_quests[quest_id] = {
				"data": quest_registry[quest_id],
				"objectives": data.active[quest_id],
			}
	quest_log_changed.emit()
