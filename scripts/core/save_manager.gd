extends Node
## Global save manager (autoloaded). Handles saving and loading game state to disk.

const SAVE_PATH := "user://savegame.json"

signal game_saved
signal game_loaded


func save_game() -> void:
	var save_data := {
		"version": 1,
		"inventory": InventoryManager.get_save_data(),
		"quests": QuestManager.get_save_data(),
	}

	# Save player stats if available
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stats: PlayerStats = player.get_node_or_null("PlayerStats")
		if stats:
			save_data["player_stats"] = stats.get_save_data()
		save_data["player_position"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z,
		}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		game_saved.emit()
		print("Game saved.")


func load_game() -> void:
	if not has_save():
		push_warning("No save file found.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_error("Failed to parse save file.")
		return

	var data: Dictionary = json.data

	# Restore inventory
	if data.has("inventory"):
		InventoryManager.load_save_data(data.inventory)

	# Restore quests
	if data.has("quests"):
		QuestManager.load_save_data(data.quests)

	# Player stats and position will be restored after scene loads
	game_loaded.emit()
	print("Game loaded.")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
