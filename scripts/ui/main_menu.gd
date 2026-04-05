extends Control
## Main menu with new game, load game, and quit options.

@onready var new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var load_game_btn: Button = $VBoxContainer/LoadGameButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	quit_btn.pressed.connect(_on_quit)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Disable load if no save exists
	load_game_btn.disabled = not SaveManager.has_save()


func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/world/test_world.tscn")


func _on_load_game() -> void:
	SaveManager.load_game()
	get_tree().change_scene_to_file("res://scenes/world/test_world.tscn")


func _on_quit() -> void:
	get_tree().quit()
