extends CanvasLayer
## In-game HUD showing health, stamina, magicka bars, crosshair, and notifications.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var magicka_bar: ProgressBar = $MarginContainer/VBoxContainer/MagickaBar
@onready var crosshair: TextureRect = $Crosshair
@onready var interact_label: Label = $InteractLabel
@onready var notification_label: Label = $NotificationLabel
@onready var gold_label: Label = $GoldLabel
@onready var time_label: Label = $TimeLabel

var notification_timer: float = 0.0


func _ready() -> void:
	interact_label.visible = false
	notification_label.visible = false
	InventoryManager.gold_changed.connect(_on_gold_changed)
	InventoryManager.item_added.connect(_on_item_added)
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)


func _process(delta: float) -> void:
	if notification_timer > 0:
		notification_timer -= delta
		if notification_timer <= 0:
			notification_label.visible = false


func connect_player_stats(stats: PlayerStats) -> void:
	stats.health_changed.connect(_on_health_changed)
	stats.stamina_changed.connect(_on_stamina_changed)
	stats.magicka_changed.connect(_on_magicka_changed)
	stats.level_up.connect(_on_level_up)


func show_interact_prompt(text: String) -> void:
	interact_label.text = "[E] " + text
	interact_label.visible = true


func hide_interact_prompt() -> void:
	interact_label.visible = false


func show_notification(text: String, duration: float = 3.0) -> void:
	notification_label.text = text
	notification_label.visible = true
	notification_timer = duration


func update_time(time_string: String) -> void:
	if time_label:
		time_label.text = time_string


func _on_health_changed(value: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = value


func _on_stamina_changed(value: float, max_value: float) -> void:
	stamina_bar.max_value = max_value
	stamina_bar.value = value


func _on_magicka_changed(value: float, max_value: float) -> void:
	magicka_bar.max_value = max_value
	magicka_bar.value = value


func _on_gold_changed(amount: int) -> void:
	gold_label.text = str(amount) + " Gold"


func _on_item_added(item: ItemData, _quantity: int) -> void:
	show_notification("Acquired: " + item.display_name)


func _on_quest_started(quest_id: String) -> void:
	show_notification("New Quest: " + quest_id)


func _on_quest_completed(quest_id: String) -> void:
	show_notification("Quest Complete: " + quest_id)


func _on_level_up(new_level: int) -> void:
	show_notification("Level Up! You are now level " + str(new_level), 5.0)
