extends CanvasLayer
## Pause menu with resume, save, load, and quit to menu options.

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_btn: Button = $Panel/VBoxContainer/SaveButton
@onready var load_btn: Button = $Panel/VBoxContainer/LoadButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton

var is_open: bool = false


func _ready() -> void:
	panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	quit_btn.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()


func toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume() -> void:
	toggle()


func _on_save() -> void:
	SaveManager.save_game()


func _on_load() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
		toggle()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
