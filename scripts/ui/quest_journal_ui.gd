extends CanvasLayer
## Quest journal UI — shows active and completed quests with objectives.

@onready var panel: PanelContainer = $Panel
@onready var quest_list: ItemList = $Panel/HSplitContainer/QuestList
@onready var quest_title: Label = $Panel/HSplitContainer/DetailPanel/VBoxContainer/QuestTitle
@onready var quest_desc: RichTextLabel = $Panel/HSplitContainer/DetailPanel/VBoxContainer/QuestDescription
@onready var objectives_container: VBoxContainer = $Panel/HSplitContainer/DetailPanel/VBoxContainer/ObjectivesContainer

var is_open: bool = false


func _ready() -> void:
	panel.visible = false
	QuestManager.quest_log_changed.connect(_refresh)
	quest_list.item_selected.connect(_on_quest_selected)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
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
	quest_list.clear()
	for quest_state in QuestManager.get_active_quests():
		var quest: QuestData = quest_state.data
		quest_list.add_item(quest.title)
	_clear_detail()


func _on_quest_selected(index: int) -> void:
	var active := QuestManager.get_active_quests()
	if index < 0 or index >= active.size():
		return

	var quest_state: Dictionary = active[index]
	var quest: QuestData = quest_state.data
	quest_title.text = quest.title
	quest_desc.text = quest.description

	for child in objectives_container.get_children():
		child.queue_free()

	for obj in quest.objectives:
		var label := Label.new()
		var current: int = quest_state.objectives.get(obj.objective_id, 0)
		var prefix := "[x] " if current >= obj.required_count else "[ ] "
		var count_text := ""
		if obj.required_count > 1:
			count_text = " (%d/%d)" % [current, obj.required_count]
		label.text = prefix + obj.description + count_text
		if obj.is_optional:
			label.text += " (Optional)"
		objectives_container.add_child(label)


func _clear_detail() -> void:
	quest_title.text = ""
	quest_desc.text = "Select a quest to view details."
	for child in objectives_container.get_children():
		child.queue_free()
