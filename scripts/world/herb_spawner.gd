extends Node3D
class_name HerbSpawner
## Spawns collectible Silverleaf herb pickups on the hillsides.

@export var herb_positions: Array[Vector3] = [
	Vector3(-45, 0, 20),   # West hillside
	Vector3(35, 0, 35),    # North-east
	Vector3(-30, 0, -40),  # South-west
	Vector3(50, 0, 10),    # East (near dungeon road)
	Vector3(-55, 0, -10),  # Far west
]

var terrain: TerrainGenerator
var leaf_color := Color(0.6, 0.8, 0.55)
var glow_color := Color(0.7, 0.9, 0.65)


func _ready() -> void:
	terrain = get_parent().get_node_or_null("TerrainGenerator")
	call_deferred("_spawn_herbs")


func _spawn_herbs() -> void:
	for i in range(herb_positions.size()):
		var pos := herb_positions[i]
		# Adjust Y to terrain height
		if terrain:
			pos.y = terrain.get_height_at(pos.x, pos.z)
		_create_herb_pickup(pos, i)


func _create_herb_pickup(pos: Vector3, index: int) -> void:
	var pickup := Node3D.new()
	pickup.name = "Silverleaf_%d" % index
	pickup.position = pos

	# Stem
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.01
	stem_mesh.bottom_radius = 0.02
	stem_mesh.height = 0.3
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.3, 0.5, 0.2)
	var stem := MeshInstance3D.new()
	stem.mesh = stem_mesh
	stem.material_override = stem_mat
	stem.position.y = 0.15
	pickup.add_child(stem)

	# Leaves (small flat boxes)
	for j in range(4):
		var leaf_mesh := BoxMesh.new()
		leaf_mesh.size = Vector3(0.12, 0.02, 0.08)
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = leaf_color
		leaf_mat.emission_enabled = true
		leaf_mat.emission = glow_color
		leaf_mat.emission_energy_multiplier = 0.8
		var leaf := MeshInstance3D.new()
		leaf.mesh = leaf_mesh
		leaf.material_override = leaf_mat
		leaf.position = Vector3(0, 0.2 + j * 0.05, 0)
		leaf.rotation.y = j * PI / 2 + 0.3
		leaf.rotation.z = 0.4
		pickup.add_child(leaf)

	# Glow light
	var light := OmniLight3D.new()
	light.position.y = 0.3
	light.light_color = glow_color
	light.light_energy = 0.3
	light.omni_range = 3.0
	pickup.add_child(light)

	# Label (visible from a distance)
	var label := Label3D.new()
	label.text = "Silverleaf"
	label.position.y = 0.7
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 14
	label.modulate = Color(0.7, 0.9, 0.7)
	pickup.add_child(label)

	# Interaction area
	var area := Area3D.new()
	area.collision_layer = 16
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.5
	col.shape = shape
	col.position.y = 0.3
	area.add_child(col)
	pickup.add_child(area)

	# Pickup script
	var script := GDScript.new()
	script.source_code = """extends Node3D

var picked_up: bool = false

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)

func interact(player: CharacterBody3D) -> void:
	_pickup()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not picked_up:
		_pickup()

func _pickup() -> void:
	if picked_up:
		return
	picked_up = true
	var herb := load("res://resources/items/silverleaf.tres") as ItemData
	if herb:
		InventoryManager.add_item(herb)
	queue_free()
"""
	script.reload()
	pickup.set_script(script)

	add_child(pickup)
