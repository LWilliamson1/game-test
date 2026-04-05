extends Node3D
class_name TerrainGenerator
## Generates rolling terrain using layered noise. Attach to the world scene.

@export_group("Terrain Size")
@export var terrain_size: Vector2 = Vector2(200, 200)
@export var resolution: float = 2.0  # Distance between vertices

@export_group("Height")
@export var max_height: float = 12.0
@export var noise_scale: float = 0.02
@export var noise_octaves: int = 4
@export var noise_lacunarity: float = 2.0
@export var noise_gain: float = 0.5

@export_group("Flat Zone")
@export var village_center: Vector2 = Vector2.ZERO
@export var village_radius: float = 30.0
@export var village_falloff: float = 15.0

@export_group("Material")
@export var terrain_material: Material

var noise: FastNoiseLite
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D


func _ready() -> void:
	_setup_noise()
	_generate_terrain()


func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = noise_scale
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_gain
	noise.seed = randi()


func _generate_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cols := int(terrain_size.x / resolution) + 1
	var rows := int(terrain_size.y / resolution) + 1
	var half_x := terrain_size.x / 2.0
	var half_z := terrain_size.y / 2.0

	# Generate height map
	var heights: Array[float] = []
	heights.resize(cols * rows)

	for z in range(rows):
		for x in range(cols):
			var world_x := x * resolution - half_x
			var world_z := z * resolution - half_z
			var h := _get_height(world_x, world_z)
			heights[z * cols + x] = h

	# Build triangles
	for z in range(rows - 1):
		for x in range(cols - 1):
			var i := z * cols + x
			var v00 := Vector3(x * resolution - half_x, heights[i], z * resolution - half_z)
			var v10 := Vector3((x + 1) * resolution - half_x, heights[i + 1], z * resolution - half_z)
			var v01 := Vector3(x * resolution - half_x, heights[i + cols], (z + 1) * resolution - half_z)
			var v11 := Vector3((x + 1) * resolution - half_x, heights[i + cols + 1], (z + 1) * resolution - half_z)

			# UV based on world position
			var uv00 := Vector2(v00.x, v00.z) * 0.1
			var uv10 := Vector2(v10.x, v10.z) * 0.1
			var uv01 := Vector2(v01.x, v01.z) * 0.1
			var uv11 := Vector2(v11.x, v11.z) * 0.1

			# Triangle 1
			var n1 := (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1)
			st.set_uv(uv00); st.add_vertex(v00)
			st.set_uv(uv10); st.add_vertex(v10)
			st.set_uv(uv01); st.add_vertex(v01)

			# Triangle 2
			var n2 := (v01 - v11).cross(v10 - v11).normalized()
			st.set_normal(n2)
			st.set_uv(uv10); st.add_vertex(v10)
			st.set_uv(uv11); st.add_vertex(v11)
			st.set_uv(uv01); st.add_vertex(v01)

	var mesh := st.commit()

	# Create visual mesh
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	if terrain_material:
		mesh_instance.material_override = terrain_material
	add_child(mesh_instance)

	# Create collision
	static_body = StaticBody3D.new()
	static_body.collision_layer = 1  # World layer
	add_child(static_body)

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)


func _get_height(world_x: float, world_z: float) -> float:
	var raw_height := noise.get_noise_2d(world_x, world_z) * max_height

	# Flatten around village center
	var dist_to_village := Vector2(world_x, world_z).distance_to(village_center)
	if dist_to_village < village_radius:
		return 0.0
	elif dist_to_village < village_radius + village_falloff:
		var t := (dist_to_village - village_radius) / village_falloff
		t = t * t * (3.0 - 2.0 * t)  # Smoothstep
		return lerp(0.0, raw_height, t)

	return raw_height


## Get the terrain height at any world XZ position (for placing objects).
func get_height_at(world_x: float, world_z: float) -> float:
	if noise == null:
		_setup_noise()
	return _get_height(world_x, world_z)
