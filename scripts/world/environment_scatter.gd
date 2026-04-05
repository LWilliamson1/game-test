extends Node3D
class_name EnvironmentScatter
## Procedurally scatters trees, rocks, and grass around the terrain.
## Respects exclusion zones (village, paths) and terrain height.

@export_group("Scatter Settings")
@export var scatter_radius: float = 90.0
@export var seed_value: int = 42

@export_group("Trees")
@export var tree_count: int = 120
@export var tree_min_scale: float = 0.8
@export var tree_max_scale: float = 1.5
@export var tree_trunk_color: Color = Color(0.35, 0.22, 0.1)
@export var tree_canopy_color: Color = Color(0.15, 0.4, 0.12)

@export_group("Rocks")
@export var rock_count: int = 80
@export var rock_min_scale: float = 0.3
@export var rock_max_scale: float = 2.0
@export var rock_color: Color = Color(0.45, 0.42, 0.4)

@export_group("Exclusion")
@export var exclusion_center: Vector2 = Vector2.ZERO
@export var exclusion_radius: float = 35.0
@export var dungeon_center: Vector2 = Vector2(60, -40)
@export var dungeon_exclusion_radius: float = 10.0

var terrain: TerrainGenerator
var rng: RandomNumberGenerator


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value

	# Find terrain generator in parent
	terrain = get_parent().get_node_or_null("TerrainGenerator")

	_scatter_trees()
	_scatter_rocks()


func _scatter_trees() -> void:
	var trees_node := Node3D.new()
	trees_node.name = "Trees"
	add_child(trees_node)

	var placed := 0
	var attempts := 0
	while placed < tree_count and attempts < tree_count * 5:
		attempts += 1
		var pos := _random_position()
		if pos == Vector3.ZERO:
			continue

		var tree := _create_tree()
		var s := rng.randf_range(tree_min_scale, tree_max_scale)
		tree.scale = Vector3(s, s, s)
		tree.position = pos
		tree.rotate_y(rng.randf() * TAU)
		trees_node.add_child(tree)
		placed += 1


func _scatter_rocks() -> void:
	var rocks_node := Node3D.new()
	rocks_node.name = "Rocks"
	add_child(rocks_node)

	var placed := 0
	var attempts := 0
	while placed < rock_count and attempts < rock_count * 5:
		attempts += 1
		var pos := _random_position()
		if pos == Vector3.ZERO:
			continue

		var rock := _create_rock()
		var s := rng.randf_range(rock_min_scale, rock_max_scale)
		rock.scale = Vector3(s, s * rng.randf_range(0.5, 1.0), s)
		rock.position = pos
		rock.rotate_y(rng.randf() * TAU)
		rock.rotate_x(rng.randf_range(-0.2, 0.2))
		rocks_node.add_child(rock)
		placed += 1


func _random_position() -> Vector3:
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(exclusion_radius * 0.5, scatter_radius)
	var x := cos(angle) * dist
	var z := sin(angle) * dist

	# Check exclusion zones
	var pos2 := Vector2(x, z)
	if pos2.distance_to(exclusion_center) < exclusion_radius:
		return Vector3.ZERO
	if pos2.distance_to(dungeon_center) < dungeon_exclusion_radius:
		return Vector3.ZERO

	var y := 0.0
	if terrain:
		y = terrain.get_height_at(x, z)

	return Vector3(x, y, z)


func _create_tree() -> Node3D:
	var tree := Node3D.new()

	# Trunk
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.15
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 3.0

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = tree_trunk_color

	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.material_override = trunk_mat
	trunk.position.y = 1.5
	tree.add_child(trunk)

	# Canopy (layered cones for a pine-tree look)
	for i in range(3):
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.8 - i * 0.4
		cone.height = 2.0

		var canopy_mat := StandardMaterial3D.new()
		canopy_mat.albedo_color = tree_canopy_color.lerp(Color(0.2, 0.5, 0.15), i * 0.15)

		var canopy := MeshInstance3D.new()
		canopy.mesh = cone
		canopy.material_override = canopy_mat
		canopy.position.y = 3.0 + i * 1.2
		tree.add_child(canopy)

	# Collision (simple capsule for the trunk)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 3.0
	col_shape.shape = capsule
	col_shape.position.y = 1.5
	body.add_child(col_shape)
	tree.add_child(body)

	return tree


func _create_rock() -> Node3D:
	var rock := Node3D.new()

	# Use a sphere mesh squashed to look like a boulder
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.5
	rock_mesh.height = 1.0

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = rock_color.lerp(Color(0.35, 0.32, 0.3), rng.randf_range(0.0, 0.3))
	rock_mat.roughness = 0.9

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = rock_mesh
	mesh_inst.material_override = rock_mat
	mesh_inst.position.y = 0.3
	rock.add_child(mesh_inst)

	# Collision
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	col.position.y = 0.3
	body.add_child(col)
	rock.add_child(body)

	return rock
