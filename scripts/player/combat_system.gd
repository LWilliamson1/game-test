extends Node3D
class_name CombatSystem
## Handles melee combat: attack animations, hit detection, damage dealing.
## Attach to the Player node.

@export var attack_damage: float = 10.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 0.6
@export var attack_angle: float = 60.0  # Degrees, half-cone

var can_attack: bool = true
var is_attacking: bool = false
var cooldown_timer: float = 0.0

signal attacked(target: Node3D)
signal enemy_killed(target: Node3D)

@onready var player: CharacterBody3D = get_parent()


func _ready() -> void:
	# Check if player has stats for damage bonus
	pass


func _process(delta: float) -> void:
	if not can_attack:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_attack = true
			is_attacking = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and can_attack:
		if DialogueManager.is_active:
			return
		_perform_attack()


func _perform_attack() -> void:
	can_attack = false
	is_attacking = true
	cooldown_timer = attack_cooldown

	# Calculate actual damage (base + weapon bonus)
	var total_damage := attack_damage
	# Check equipped weapon in inventory for bonus damage
	for entry in InventoryManager.items:
		if entry.item.item_type == ItemData.ItemType.WEAPON:
			total_damage += entry.item.damage
			break  # Use first weapon found

	# Find targets in range and angle
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var forward := -camera.global_transform.basis.z
	var origin := camera.global_position

	var targets := _find_targets_in_cone(origin, forward, attack_range, attack_angle)
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(total_damage)
			attacked.emit(target)

			# Check if killed
			if target.has_method("is_dead") and target.is_dead():
				enemy_killed.emit(target)


func _find_targets_in_cone(origin: Vector3, forward: Vector3, range: float, angle_deg: float) -> Array[Node3D]:
	var results: Array[Node3D] = []
	var cos_angle := cos(deg_to_rad(angle_deg))

	# Check all enemies in the scene
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not enemy is Node3D:
			continue
		var to_enemy: Vector3 = (enemy.global_position + Vector3(0, 1, 0)) - origin
		var dist := to_enemy.length()
		if dist > range:
			continue

		var dot := forward.dot(to_enemy.normalized())
		if dot >= cos_angle:
			results.append(enemy)

	return results
