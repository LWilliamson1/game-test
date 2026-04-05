extends CharacterBody3D
class_name Enemy
## A hostile NPC that chases and attacks the player.

@export var enemy_name: String = "Skeleton"
@export var enemy_id: String = "skeleton"
@export var max_health: float = 30.0
@export var damage: float = 8.0
@export var move_speed: float = 3.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.2
@export var detection_range: float = 18.0
@export var xp_reward: float = 25.0

@export_group("Drops")
@export var drop_item_id: String = ""
@export var drop_chance: float = 1.0

var health: float
var _is_dead: bool = false
var player_ref: Node3D = null
var can_attack: bool = true
var attack_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

enum State { IDLE, CHASE, ATTACK, DEAD }
var current_state: State = State.IDLE

signal died(enemy: Enemy)
signal damaged(enemy: Enemy, amount: float)


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

	match current_state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack()

	move_and_slide()


func _state_idle() -> void:
	velocity.x = 0
	velocity.z = 0
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var dist := global_position.distance_to(player.global_position)
		if dist < detection_range:
			player_ref = player
			current_state = State.CHASE


func _state_chase(delta: float) -> void:
	if player_ref == null:
		current_state = State.IDLE
		return

	var dist := global_position.distance_to(player_ref.global_position)
	if dist > detection_range * 1.5:
		player_ref = null
		current_state = State.IDLE
		return

	if dist <= attack_range:
		current_state = State.ATTACK
		return

	# Move toward player
	var direction := (player_ref.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# Face player
	if direction.length() > 0.01:
		var look_target := global_position + direction
		look_at(look_target)


func _state_attack() -> void:
	velocity.x = 0
	velocity.z = 0

	if player_ref == null:
		current_state = State.IDLE
		return

	var dist := global_position.distance_to(player_ref.global_position)
	if dist > attack_range * 1.5:
		current_state = State.CHASE
		return

	if can_attack:
		_perform_attack()


func _perform_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown

	if player_ref and player_ref.has_node("PlayerStats"):
		var stats: PlayerStats = player_ref.get_node("PlayerStats")
		stats.take_damage(damage)


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	health -= amount
	damaged.emit(self, amount)

	# Aggro on hit
	if current_state == State.IDLE:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player_ref = player
			current_state = State.CHASE

	if health <= 0:
		_die()


func is_dead() -> bool:
	return _is_dead


func _die() -> void:
	_is_dead = true
	current_state = State.DEAD
	velocity = Vector3.ZERO

	# Grant XP
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stats: PlayerStats = player.get_node_or_null("PlayerStats")
		if stats:
			stats.add_experience(xp_reward)

	died.emit(self)

	# Tilt over as a "death" visual
	var tween := create_tween()
	tween.tween_property(self, "rotation:x", -PI / 2, 0.4)
	tween.tween_callback(_after_death)


func _after_death() -> void:
	# Disable collision after falling over
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true
