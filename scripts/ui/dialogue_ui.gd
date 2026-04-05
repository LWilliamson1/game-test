extends CanvasLayer
## Dialogue box UI that shows speaker, text, and choices.

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var continue_label: Label = $Panel/VBoxContainer/ContinueLabel


func _ready() -> void:
	panel.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_entry_shown.connect(_on_entry_shown)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _unhandled_input(event: InputEvent) -> void:
	if not DialogueManager.is_active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		DialogueManager.advance()


func _on_dialogue_started(_dialogue: DialogueData) -> void:
	panel.visible = true


func _on_entry_shown(entry: DialogueEntry) -> void:
	speaker_label.text = entry.speaker_name
	text_label.text = entry.text

	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()

	if entry.has_choices():
		continue_label.visible = false
		for i in range(entry.choices.size()):
			var choice := entry.choices[i]
			var button := Button.new()
			button.text = str(i + 1) + ". " + choice.text
			button.pressed.connect(_on_choice_pressed.bind(i))
			choices_container.add_child(button)
	else:
		continue_label.visible = true
		continue_label.text = "[Click to continue]"


func _on_choice_pressed(index: int) -> void:
	DialogueManager.select_choice(index)


func _on_dialogue_ended() -> void:
	panel.visible = false
