extends Node3D
class_name VillageBuilder
## Procedurally constructs a hand-designed village layout using CSG primitives.
## Buildings are placed at fixed positions but built from code (no external assets).

@export var village_name: String = "Millhaven"

# Shader materials (used for key surfaces)
var stone_mat: Material = preload("res://resources/materials/stone_material.tres")
var wood_mat: Material = preload("res://resources/materials/wood_material.tres")
var dark_wood_mat: Material = preload("res://resources/materials/dark_wood_material.tres")
var plaster_mat: Material = preload("res://resources/materials/plaster_material.tres")
var roof_mat: Material = preload("res://resources/materials/roof_material.tres")
var path_mat: Material = preload("res://resources/materials/path_material.tres")

# Flat colors (used for small details, windows, water, etc.)
var stone_color := Color(0.55, 0.52, 0.48)
var wood_color := Color(0.45, 0.3, 0.18)
var dark_wood_color := Color(0.3, 0.2, 0.12)
var roof_color := Color(0.35, 0.15, 0.1)
var plaster_color := Color(0.85, 0.8, 0.7)
var door_color := Color(0.3, 0.18, 0.08)
var hay_color := Color(0.7, 0.6, 0.3)
var water_color := Color(0.2, 0.35, 0.5, 0.7)
var path_color := Color(0.5, 0.42, 0.32)


func _ready() -> void:
	_build_village()


func _build_village() -> void:
	# Central well/plaza
	_build_well(Vector3(0, 0, 0))

	# Tavern - largest building, center of village life
	_build_tavern(Vector3(-12, 0, -5))

	# Blacksmith - with forge area
	_build_blacksmith(Vector3(10, 0, -8))

	# General store
	_build_house(Vector3(8, 0, 8), "General Store", plaster_color, Vector3(6, 3.5, 5))

	# Residential houses
	_build_house(Vector3(-10, 0, 10), "Elder's House", plaster_color, Vector3(5, 3, 5))
	_build_house(Vector3(-18, 0, 6), "Farmer's Cottage", plaster_color, Vector3(4.5, 2.8, 4))
	_build_house(Vector3(0, 0, 15), "Guard House", stone_color, Vector3(5, 3.5, 5))
	_build_house(Vector3(16, 0, 4), "Herbalist's Hut", plaster_color, Vector3(4, 2.5, 4))

	# Village gate / entrance markers
	_build_gate(Vector3(0, 0, -22))

	# Paths
	_build_paths()

	# Market stalls near the center
	_build_market_stall(Vector3(4, 0, -3), "Fruit Stand")
	_build_market_stall(Vector3(-4, 0, 4), "Cloth Merchant")

	# Fences along the village perimeter (partial)
	_build_fence_line(Vector3(-22, 0, -15), Vector3(-22, 0, 15), 8)
	_build_fence_line(Vector3(20, 0, -15), Vector3(20, 0, 15), 8)

	# Lamp posts
	_build_lamp(Vector3(-5, 0, -5))
	_build_lamp(Vector3(5, 0, 5))
	_build_lamp(Vector3(-5, 0, 10))
	_build_lamp(Vector3(10, 0, 0))


func _build_tavern(pos: Vector3) -> void:
	var building := Node3D.new()
	building.name = "Tavern"
	building.position = pos
	add_child(building)

	# Main body
	var body := _create_box_shader(Vector3(9, 4, 7), stone_mat)
	body.position.y = 2
	building.add_child(body)

	# Upper floor (half-timbered)
	var upper := _create_box_shader(Vector3(9.5, 3, 7.5), plaster_mat)
	upper.position.y = 5.5
	building.add_child(upper)

	# Timber beams on upper floor
	for i in range(4):
		var beam := _create_box_shader(Vector3(0.15, 3, 7.6), dark_wood_mat)
		beam.position = Vector3(-3.5 + i * 2.3, 5.5, 0)
		building.add_child(beam)

	# Roof
	var roof := _create_roof(Vector3(10.5, 2.5, 8.5), roof_color)
	roof.position.y = 8.5
	building.add_child(roof)

	# Door
	var door := _create_box_shader(Vector3(1.2, 2.2, 0.3), wood_mat)
	door.position = Vector3(0, 1.1, 3.6)
	building.add_child(door)

	# Windows
	for x in [-2.5, 2.5]:
		var win := _create_box(Vector3(0.8, 0.8, 0.3), Color(0.6, 0.7, 0.85, 0.5))
		win.position = Vector3(x, 2.5, 3.6)
		building.add_child(win)
		var win2 := _create_box(Vector3(0.8, 0.8, 0.3), Color(0.6, 0.7, 0.85, 0.5))
		win2.position = Vector3(x, 5.5, 3.6)
		building.add_child(win2)

	# Tavern sign
	var sign_post := _create_box_shader(Vector3(0.1, 2, 0.1), dark_wood_mat)
	sign_post.position = Vector3(2, 3, 3.8)
	building.add_child(sign_post)

	var sign_board := _create_box_shader(Vector3(1.5, 0.8, 0.1), wood_mat)
	sign_board.position = Vector3(2, 3.8, 4.0)
	building.add_child(sign_board)

	# Collision for the whole building
	_add_building_collision(building, Vector3(9.5, 7, 7.5), Vector3(0, 3.5, 0))

	# Label
	_add_label(building, "The Rusty Flagon", Vector3(0, 9, 3.8))


func _build_blacksmith(pos: Vector3) -> void:
	var building := Node3D.new()
	building.name = "Blacksmith"
	building.position = pos
	add_child(building)

	# Main workshop
	var body := _create_box_shader(Vector3(7, 3.5, 6), stone_mat)
	body.position.y = 1.75
	building.add_child(body)

	# Roof
	var roof := _create_roof(Vector3(8, 2, 7), roof_color)
	roof.position.y = 5
	building.add_child(roof)

	# Open forge area (lean-to roof, no wall on one side)
	var forge_roof := _create_box_shader(Vector3(4, 0.2, 4), dark_wood_mat)
	forge_roof.position = Vector3(5.5, 3, 0)
	building.add_child(forge_roof)

	# Forge pillars
	for z in [-1.5, 1.5]:
		var pillar := _create_box_shader(Vector3(0.2, 3, 0.2), dark_wood_mat)
		pillar.position = Vector3(7.2, 1.5, z)
		building.add_child(pillar)

	# Anvil (small dark box)
	var anvil := _create_box(Vector3(0.6, 0.5, 0.4), Color(0.2, 0.2, 0.22))
	anvil.position = Vector3(5.5, 0.5, 0)
	building.add_child(anvil)

	# Forge fire pit
	var pit := _create_box(Vector3(1.0, 0.6, 1.0), Color(0.15, 0.15, 0.15))
	pit.position = Vector3(5.5, 0.3, -2)
	building.add_child(pit)

	# Door
	var door := _create_box_shader(Vector3(1.2, 2.2, 0.3), wood_mat)
	door.position = Vector3(0, 1.1, 3.1)
	building.add_child(door)

	_add_building_collision(building, Vector3(7, 3.5, 6), Vector3(0, 1.75, 0))
	_add_label(building, "Blacksmith", Vector3(0, 6, 3.2))


func _build_house(pos: Vector3, house_name: String, wall_color: Color, size: Vector3) -> void:
	var building := Node3D.new()
	building.name = house_name
	building.position = pos
	add_child(building)

	# Walls — use plaster or stone shader based on original color
	var wall_mat_to_use: Material = plaster_mat if wall_color == plaster_color else stone_mat
	var body := _create_box_shader(size, wall_mat_to_use)
	body.position.y = size.y / 2
	building.add_child(body)

	# Stone foundation
	var foundation := _create_box_shader(Vector3(size.x + 0.2, 0.4, size.z + 0.2), stone_mat)
	foundation.position.y = 0.2
	building.add_child(foundation)

	# Roof
	var roof := _create_roof(Vector3(size.x + 1, 1.8, size.z + 1), roof_color)
	roof.position.y = size.y + 0.9
	building.add_child(roof)

	# Door
	var door := _create_box_shader(Vector3(1.0, 2.0, 0.3), wood_mat)
	door.position = Vector3(0, 1.0, size.z / 2 + 0.1)
	building.add_child(door)

	# Window
	var win := _create_box(Vector3(0.7, 0.7, 0.3), Color(0.6, 0.7, 0.85, 0.5))
	win.position = Vector3(size.x / 3, size.y * 0.6, size.z / 2 + 0.1)
	building.add_child(win)

	_add_building_collision(building, size, Vector3(0, size.y / 2, 0))
	_add_label(building, house_name, Vector3(0, size.y + 2, size.z / 2 + 0.2))


func _build_well(pos: Vector3) -> void:
	var well := Node3D.new()
	well.name = "Village Well"
	well.position = pos
	add_child(well)

	# Stone base
	var base := _create_box_shader(Vector3(1.8, 0.9, 1.8), stone_mat)
	base.position.y = 0.45
	well.add_child(base)

	# Water surface
	var water := _create_box(Vector3(1.4, 0.05, 1.4), water_color)
	water.position.y = 0.6
	well.add_child(water)

	# Roof posts
	for x in [-0.7, 0.7]:
		var post := _create_box_shader(Vector3(0.12, 2.0, 0.12), dark_wood_mat)
		post.position = Vector3(x, 1.9, 0)
		well.add_child(post)

	# Roof beam
	var beam := _create_box_shader(Vector3(2.0, 0.12, 0.8), dark_wood_mat)
	beam.position.y = 2.9
	well.add_child(beam)

	# Roof
	var roof := _create_roof(Vector3(2.2, 0.6, 1.2), roof_color)
	roof.position.y = 3.3
	well.add_child(roof)

	_add_building_collision(well, Vector3(1.8, 0.9, 1.8), Vector3(0, 0.45, 0))


func _build_gate(pos: Vector3) -> void:
	var gate := Node3D.new()
	gate.name = "Village Gate"
	gate.position = pos
	add_child(gate)

	# Two stone pillars
	for x in [-2.5, 2.5]:
		var pillar := _create_box_shader(Vector3(0.8, 4, 0.8), stone_mat)
		pillar.position = Vector3(x, 2, 0)
		gate.add_child(pillar)

		# Pillar cap
		var cap := _create_box_shader(Vector3(1.0, 0.3, 1.0), stone_mat)
		cap.position = Vector3(x, 4.15, 0)
		gate.add_child(cap)

	# Wooden cross beam
	var beam := _create_box_shader(Vector3(6, 0.4, 0.5), dark_wood_mat)
	beam.position.y = 3.8
	gate.add_child(beam)

	# Village name sign
	_add_label(gate, village_name, Vector3(0, 4.6, 0))


func _build_market_stall(pos: Vector3, stall_name: String) -> void:
	var stall := Node3D.new()
	stall.name = stall_name
	stall.position = pos
	add_child(stall)

	# Counter
	var counter := _create_box_shader(Vector3(2.5, 1.0, 1.2), wood_mat)
	counter.position.y = 0.5
	stall.add_child(counter)

	# Awning posts
	for x in [-1.1, 1.1]:
		var post := _create_box_shader(Vector3(0.1, 2.5, 0.1), dark_wood_mat)
		post.position = Vector3(x, 1.25, -0.5)
		stall.add_child(post)

	# Awning
	var awning := _create_box(Vector3(2.8, 0.08, 1.8), hay_color)
	awning.position = Vector3(0, 2.5, 0)
	awning.rotation.x = -0.15
	stall.add_child(awning)

	_add_building_collision(stall, Vector3(2.5, 1.0, 1.2), Vector3(0, 0.5, 0))


func _build_fence_line(from: Vector3, to: Vector3, segments: int) -> void:
	var fences := Node3D.new()
	fences.name = "Fence"
	add_child(fences)

	for i in range(segments + 1):
		var t := float(i) / segments
		var pos := from.lerp(to, t)

		# Post
		var post := _create_box_shader(Vector3(0.12, 1.2, 0.12), dark_wood_mat)
		post.position = pos + Vector3(0, 0.6, 0)
		fences.add_child(post)

		# Rails between posts
		if i < segments:
			var next_t := float(i + 1) / segments
			var next_pos := from.lerp(to, next_t)
			var mid := pos.lerp(next_pos, 0.5)
			var length := pos.distance_to(next_pos)

			for rail_y in [0.4, 0.8]:
				var rail := _create_box_shader(Vector3(length, 0.08, 0.06), wood_mat)
				rail.position = mid + Vector3(0, rail_y, 0)
				rail.look_at(next_pos + Vector3(0, rail_y, 0))
				fences.add_child(rail)


func _build_lamp(pos: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.name = "Lamp"
	lamp.position = pos
	add_child(lamp)

	# Post
	var post := _create_box(Vector3(0.12, 3.0, 0.12), Color(0.2, 0.2, 0.2))
	post.position.y = 1.5
	lamp.add_child(post)

	# Lantern housing
	var housing := _create_box(Vector3(0.3, 0.4, 0.3), Color(0.2, 0.2, 0.2))
	housing.position.y = 3.2
	lamp.add_child(housing)

	# Light
	var light := OmniLight3D.new()
	light.position.y = 3.2
	light.light_energy = 0.8
	light.light_color = Color(1.0, 0.85, 0.6)
	light.omni_range = 8.0
	light.omni_attenuation = 1.5
	light.shadow_enabled = true
	lamp.add_child(light)


func _build_paths() -> void:
	var paths := Node3D.new()
	paths.name = "Paths"
	add_child(paths)

	# Main road from gate to village center
	_add_path_segment(paths, Vector3(0, 0.02, -22), Vector3(0, 0.02, 0), 3.0)

	# Paths to buildings
	_add_path_segment(paths, Vector3(0, 0.02, 0), Vector3(-12, 0.02, -5), 2.0)
	_add_path_segment(paths, Vector3(0, 0.02, 0), Vector3(10, 0.02, -8), 2.0)
	_add_path_segment(paths, Vector3(0, 0.02, 0), Vector3(8, 0.02, 8), 2.0)
	_add_path_segment(paths, Vector3(0, 0.02, 0), Vector3(-10, 0.02, 10), 2.0)
	_add_path_segment(paths, Vector3(0, 0.02, 0), Vector3(0, 0.02, 15), 2.0)


func _add_path_segment(parent: Node3D, from: Vector3, to: Vector3, width: float) -> void:
	var mid := from.lerp(to, 0.5)
	var length := from.distance_to(to)

	var path_mesh := _create_box_shader(Vector3(width, 0.05, length), path_mat)
	path_mesh.position = mid
	path_mesh.look_at(to)
	parent.add_child(path_mesh)


# --- Helper functions ---

func _create_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

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


func _create_roof(size: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = size.z / 2
	mesh.height = size.y
	mesh.radial_segments = 4

	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = roof_mat
	inst.scale = Vector3(size.x / size.z, 1, 1)
	inst.rotation.y = PI / 4
	return inst


func _add_building_collision(parent: Node3D, size: Vector3, offset: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = offset
	body.add_child(col)
	parent.add_child(body)


func _add_label(parent: Node3D, text: String, offset: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = offset
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.modulate = Color(1.0, 0.9, 0.7)
	parent.add_child(label)
