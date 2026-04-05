extends Node3D
class_name EnemySpawner
## Spawns enemies at designated positions. Connects death signals to quest system.

@export var spawn_points: Array[Vector3] = []
@export var enemy_name: String = "Skeleton"
@export var enemy_id: String = "skeleton"

var bone_color := Color(0.85, 0.82, 0.75)
var armor_color := Color(0.3, 0.28, 0.25)
var eye_color := Color(0.8, 0.2, 0.1)

var spawned_enemies: Array[Enemy] = []
var enemies_killed: int = 0
var quest_node: Node = null

signal all_enemies_killed
signal enemy_killed(enemy: Enemy)


func _ready() -> void:
	call_deferred("_spawn_enemies")
	call_deferred("_find_quest")


func _find_quest() -> void:
	quest_node = get_tree().get_first_node_in_group("starter_quest")


func _spawn_enemies() -> void:
	for i in range(spawn_points.size()):
		var pos: Vector3 = spawn_points[i]
		var enemy := _create_skeleton(i)
		enemy.position = global_position + pos
		get_parent().add_child(enemy)
		spawned_enemies.append(enemy)
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies_killed += 1
	enemy_killed.emit(enemy)

	# Notify quest
	if quest_node and quest_node.has_method("on_skeleton_killed"):
		quest_node.on_skeleton_killed(enemy)

	# Drop amulet from the last skeleton
	if enemies_killed >= spawn_points.size():
		_drop_amulet(enemy.global_position)
		all_enemies_killed.emit()


func _drop_amulet(pos: Vector3) -> void:
	# Create a glowing pickup at the death location
	var pickup := Node3D.new()
	pickup.name = "AmuletPickup"
	pickup.position = pos + Vector3(0, 0.5, 0)
	pickup.add_to_group("interactables")

	# Visual - glowing orb
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.3, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.3, 0.8)
	mat.emission_energy_multiplier = 2.0
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	pickup.add_child(mesh_inst)

	# Point light
	var light := OmniLight3D.new()
	light.light_color = Color(0.6, 0.3, 0.8)
	light.light_energy = 0.6
	light.omni_range = 4.0
	pickup.add_child(light)

	# Label
	var label := Label3D.new()
	label.text = "Ancient Amulet"
	label.position.y = 0.6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 16
	label.modulate = Color(0.8, 0.6, 1.0)
	pickup.add_child(label)

	# Interaction area
	var area := Area3D.new()
	area.collision_layer = 16  # Interactables
	area.collision_mask = 2    # Player
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.5
	col.shape = shape
	area.add_child(col)
	pickup.add_child(area)

	# Pickup script
	var script := GDScript.new()
	script.source_code = """extends Node3D

var picked_up: bool = false

func _ready() -> void:
	var area := get_node("Area3D") as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)

func interact(player: CharacterBody3D) -> void:
	_pickup()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not picked_up:
		_pickup()

func _pickup() -> void:
	if picked_up:
		return
	picked_up = true
	var amulet := load("res://resources/items/ancient_amulet.tres") as ItemData
	if amulet:
		InventoryManager.add_item(amulet)
	var quest := get_tree().get_first_node_in_group("starter_quest")
	if quest and quest.has_method("on_amulet_collected"):
		quest.on_amulet_collected()
	queue_free()
"""
	script.reload()
	pickup.set_script(script)

	get_parent().add_child(pickup)


func _create_skeleton(index: int) -> Enemy:
	var enemy := Enemy.new()
	enemy.name = "Skeleton_%d" % index
	enemy.enemy_name = "Skeleton"
	enemy.enemy_id = "skeleton"
	enemy.max_health = 30.0
	enemy.damage = 8.0
	enemy.move_speed = 2.5
	enemy.attack_range = 2.0
	enemy.detection_range = 15.0
	enemy.xp_reward = 25.0
	enemy.collision_layer = 4   # NPC layer
	enemy.collision_mask = 3    # World + Player

	# Collision shape
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.7
	col.shape = capsule
	col.position.y = 0.85
	enemy.add_child(col)

	# --- Skeleton visual body ---
	var body := Node3D.new()
	body.name = "Body"
	enemy.add_child(body)

	# Ribcage / torso
	var torso := _box(Vector3(0.4, 0.5, 0.2), bone_color)
	torso.position.y = 1.1
	body.add_child(torso)

	# Spine
	var spine := _box(Vector3(0.08, 0.3, 0.08), bone_color)
	spine.position.y = 0.7
	body.add_child(spine)

	# Pelvis
	var pelvis := _box(Vector3(0.3, 0.15, 0.15), bone_color)
	pelvis.position.y = 0.55
	body.add_child(pelvis)

	# Skull
	var skull_mesh := SphereMesh.new()
	skull_mesh.radius = 0.14
	skull_mesh.height = 0.28
	var skull_mat := StandardMaterial3D.new()
	skull_mat.albedo_color = bone_color
	var skull := MeshInstance3D.new()
	skull.mesh = skull_mesh
	skull.material_override = skull_mat
	skull.position.y = 1.55
	body.add_child(skull)

	# Glowing eyes
	for x in [-0.05, 0.05]:
		var eye := _box(Vector3(0.04, 0.04, 0.04), eye_color)
		eye.position = Vector3(x, 1.58, 0.12)
		body.add_child(eye)

		# Eye glow
		var eye_mat: StandardMaterial3D = eye.material_override
		eye_mat.emission_enabled = true
		eye_mat.emission = eye_color
		eye_mat.emission_energy_multiplier = 3.0

	# Arms (bone sticks)
	for x in [-0.28, 0.28]:
		var upper_arm := _box(Vector3(0.06, 0.35, 0.06), bone_color)
		upper_arm.position = Vector3(x, 1.05, 0)
		upper_arm.rotation.z = x * 0.5  # Slight angle outward
		body.add_child(upper_arm)

		var lower_arm := _box(Vector3(0.05, 0.3, 0.05), bone_color)
		lower_arm.position = Vector3(x * 1.1, 0.75, 0.05)
		body.add_child(lower_arm)

	# Legs
	for x in [-0.1, 0.1]:
		var upper_leg := _box(Vector3(0.07, 0.35, 0.07), bone_color)
		upper_leg.position = Vector3(x, 0.38, 0)
		body.add_child(upper_leg)

		var lower_leg := _box(Vector3(0.06, 0.3, 0.06), bone_color)
		lower_leg.position = Vector3(x, 0.07, 0)
		body.add_child(lower_leg)

	# Rusty armor piece on some
	if index == 0:
		var pauldron := _box(Vector3(0.15, 0.1, 0.15), armor_color)
		pauldron.position = Vector3(-0.22, 1.35, 0)
		body.add_child(pauldron)

	# Name label
	var label := Label3D.new()
	label.text = "Skeleton"
	label.position.y = 2.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 16
	label.modulate = Color(0.9, 0.3, 0.3)
	enemy.add_child(label)

	# Health bar (simple colored box that scales with health)
	var health_bar_bg := _box(Vector3(0.6, 0.06, 0.06), Color(0.3, 0.0, 0.0))
	health_bar_bg.position = Vector3(0, 1.9, 0)
	health_bar_bg.name = "HealthBarBG"
	enemy.add_child(health_bar_bg)

	var health_bar := _box(Vector3(0.6, 0.06, 0.065), Color(0.8, 0.1, 0.1))
	health_bar.position = Vector3(0, 1.9, 0)
	health_bar.name = "HealthBar"
	enemy.add_child(health_bar)

	# Connect damage signal to update health bar
	enemy.damaged.connect(func(_e: Enemy, _amount: float):
		var bar := enemy.get_node_or_null("HealthBar") as MeshInstance3D
		if bar:
			var pct := enemy.health / enemy.max_health
			bar.scale.x = max(pct, 0.0)
			bar.position.x = -(1.0 - pct) * 0.3
	)

	return enemy


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	return inst
