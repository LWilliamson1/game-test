extends Node
class_name PlayerStats
## Tracks player health, stamina, magicka and leveling — Elder Scrolls style.

signal health_changed(new_value: float, max_value: float)
signal stamina_changed(new_value: float, max_value: float)
signal magicka_changed(new_value: float, max_value: float)
signal player_died
signal level_up(new_level: int)

@export_group("Base Stats")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var max_magicka: float = 100.0

@export_group("Regeneration")
@export var health_regen: float = 1.0
@export var stamina_regen: float = 5.0
@export var magicka_regen: float = 3.0

@export_group("Leveling")
@export var level: int = 1
@export var experience: float = 0.0
@export var experience_to_next: float = 100.0
@export var level_xp_multiplier: float = 1.5

var health: float
var stamina: float
var magicka: float
var is_dead: bool = false


func _ready() -> void:
	health = max_health
	stamina = max_stamina
	magicka = max_magicka


func _process(delta: float) -> void:
	if is_dead:
		return
	_regenerate(delta)


func _regenerate(delta: float) -> void:
	if health < max_health:
		set_health(min(health + health_regen * delta, max_health))
	if stamina < max_stamina:
		set_stamina(min(stamina + stamina_regen * delta, max_stamina))
	if magicka < max_magicka:
		set_magicka(min(magicka + magicka_regen * delta, max_magicka))


func take_damage(amount: float) -> void:
	set_health(health - amount)
	if health <= 0 and not is_dead:
		is_dead = true
		player_died.emit()


func heal(amount: float) -> void:
	set_health(min(health + amount, max_health))


func use_stamina(amount: float) -> bool:
	if stamina >= amount:
		set_stamina(stamina - amount)
		return true
	return false


func use_magicka(amount: float) -> bool:
	if magicka >= amount:
		set_magicka(magicka - amount)
		return true
	return false


func add_experience(amount: float) -> void:
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next *= level_xp_multiplier
		level_up.emit(level)


func set_health(value: float) -> void:
	health = clamp(value, 0.0, max_health)
	health_changed.emit(health, max_health)


func set_stamina(value: float) -> void:
	stamina = clamp(value, 0.0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


func set_magicka(value: float) -> void:
	magicka = clamp(value, 0.0, max_magicka)
	magicka_changed.emit(magicka, max_magicka)


func get_save_data() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"experience_to_next": experience_to_next,
		"health": health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"magicka": magicka,
		"max_magicka": max_magicka,
	}


func load_save_data(data: Dictionary) -> void:
	level = data.get("level", 1)
	experience = data.get("experience", 0.0)
	experience_to_next = data.get("experience_to_next", 100.0)
	max_health = data.get("max_health", 100.0)
	health = data.get("health", max_health)
	max_stamina = data.get("max_stamina", 100.0)
	stamina = data.get("stamina", max_stamina)
	max_magicka = data.get("max_magicka", 100.0)
	magicka = data.get("magicka", max_magicka)
