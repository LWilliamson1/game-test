extends Node
## Global game manager (autoloaded). Central hub for game state and scene transitions.

enum GameState { MENU, PLAYING, PAUSED, DIALOGUE, INVENTORY, JOURNAL, LOADING }

signal state_changed(new_state: GameState)

var current_state: GameState = GameState.MENU
var player: CharacterBody3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state == GameState.PLAYING:
		pause_game()
	elif event.is_action_pressed("pause") and current_state == GameState.PAUSED:
		resume_game()


func set_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

	match new_state:
		GameState.PLAYING:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		GameState.PAUSED, GameState.INVENTORY, GameState.JOURNAL:
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.DIALOGUE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func start_new_game() -> void:
	set_state(GameState.LOADING)
	get_tree().change_scene_to_file("res://scenes/world/test_world.tscn")
	await get_tree().tree_changed
	set_state(GameState.PLAYING)


func pause_game() -> void:
	set_state(GameState.PAUSED)


func resume_game() -> void:
	set_state(GameState.PLAYING)


func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	set_state(GameState.MENU)


func register_player(p: CharacterBody3D) -> void:
	player = p
	p.add_to_group("player")
