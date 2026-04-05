extends Node3D
class_name DungeonEntrance
## A cave/dungeon entrance built into a hillside.

@export var dungeon_name: String = "Ashfall Cavern"
@export var dungeon_scene_path: String = ""
@export var requires_key_id: String = ""

var stone_color := Color(0.4, 0.38, 0.35)
var dark_stone := Color(0.2, 0.18, 0.16)
var moss_color := Color(0.2, 0.3, 0.15)
var stone_shader_mat: Material = preload("res://resources/materials/stone_material.tres")


func _ready() -> void:
	_build_entrance()


func _build_entrance() -> void:
	# Hillside mound behind the entrance
	var hill := _create_mesh(SphereMesh.new(), Vector3(12, 6, 10), stone_color)
	hill.position = Vector3(0, 0, -4)
	hill.scale = Vector3(1.5, 0.7, 1.0)
	add_child(hill)

	# Stone archway frame
	# Left pillar
	var left_pillar := _create_box_shader(Vector3(1.2, 4, 1.2), stone_shader_mat)
	left_pillar.position = Vector3(-2.2, 2, 0)
	add_child(left_pillar)

	# Right pillar
	var right_pillar := _create_box_shader(Vector3(1.2, 4, 1.2), stone_shader_mat)
	right_pillar.position = Vector3(2.2, 2, 0)
	add_child(right_pillar)

	# Arch top
	var arch := _create_box_shader(Vector3(5.6, 0.8, 1.2), stone_shader_mat)
	arch.position = Vector3(0, 4.4, 0)
	add_child(arch)

	# Keystone
	var keystone := _create_box_shader(Vector3(0.8, 1.0, 1.3), stone_shader_mat)
	keystone.position = Vector3(0, 4.8, 0)
	add_child(keystone)

	# Dark interior (black box behind the entrance to suggest depth)
	var interior := _create_box(Vector3(3.5, 3.5, 6), Color(0.02, 0.02, 0.03))
	interior.position = Vector3(0, 1.75, -3.5)
	add_child(interior)

	# Steps leading down
	for i in range(3):
		var step := _create_box_shader(Vector3(4.0, 0.25, 0.8), stone_shader_mat)
		step.position = Vector3(0, -i * 0.25, 1.0 + i * 0.8)
		add_child(step)

	# Moss/vine patches on the stone
	for i in range(4):
		var moss := _create_box(Vector3(0.6, 0.6, 0.15), moss_color)
		var side := -1.0 if i % 2 == 0 else 1.0
		moss.position = Vector3(side * 2.4, 1.0 + i * 0.8, 0.1)
		add_child(moss)

	# Scattered bones near entrance
	for i in range(3):
		var bone := _create_box(Vector3(0.4, 0.06, 0.06), Color(0.85, 0.82, 0.75))
		bone.position = Vector3(-1.0 + i * 0.8, 0.03, 2.5 + i * 0.3)
		bone.rotation.y = i * 0.7
		add_child(bone)

	# Dim light from inside
	var cave_light := OmniLight3D.new()
	cave_light.position = Vector3(0, 2, -2)
	cave_light.light_color = Color(0.3, 0.2, 0.1)
	cave_light.light_energy = 0.4
	cave_light.omni_range = 6.0
	add_child(cave_light)

	# Torch on left pillar
	var torch_light := OmniLight3D.new()
	torch_light.position = Vector3(-2.2, 3.5, 0.7)
	torch_light.light_color = Color(1.0, 0.7, 0.3)
	torch_light.light_energy = 1.2
	torch_light.omni_range = 8.0
	torch_light.shadow_enabled = true
	add_child(torch_light)

	# Torch mesh (small flame-colored box)
	var torch := _create_box(Vector3(0.1, 0.6, 0.1), dark_stone)
	torch.position = Vector3(-2.2, 3.2, 0.7)
	add_child(torch)
	var flame := _create_box(Vector3(0.15, 0.2, 0.15), Color(1.0, 0.6, 0.1))
	flame.position = Vector3(-2.2, 3.6, 0.7)
	add_child(flame)

	# Collision for archway (block player from walking through walls)
	_add_collision(Vector3(1.2, 4, 1.2), Vector3(-2.2, 2, 0))
	_add_collision(Vector3(1.2, 4, 1.2), Vector3(2.2, 2, 0))

	# Interaction area (trigger zone at the entrance)
	var interact_area := Area3D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 16  # Interactables
	interact_area.collision_mask = 2   # Player
	var interact_col := CollisionShape3D.new()
	var interact_shape := BoxShape3D.new()
	interact_shape.size = Vector3(3, 3, 1.5)
	interact_col.shape = interact_shape
	interact_col.position = Vector3(0, 1.5, 0.5)
	interact_area.add_child(interact_col)
	interact_area.body_entered.connect(_on_body_entered)
	add_child(interact_area)

	# Name label
	var label := Label3D.new()
	label.text = dungeon_name
	label.position = Vector3(0, 5.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 22
	label.modulate = Color(0.9, 0.6, 0.6)
	add_child(label)


func interact(player: CharacterBody3D) -> void:
	if not requires_key_id.is_empty():
		if not InventoryManager.has_item(requires_key_id):
			return
	if not dungeon_scene_path.is_empty():
		get_tree().change_scene_to_file(dungeon_scene_path)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Show prompt via HUD
		pass


func _create_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	return inst


func _create_box_shader(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	return inst


func _create_mesh(mesh: Mesh, _size: Vector3, color: Color) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	return inst


func _add_collision(size: Vector3, offset: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = offset
	body.add_child(col)
	add_child(body)
