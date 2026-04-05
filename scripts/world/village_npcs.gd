extends Node3D
class_name VillageNPCs
## Spawns named NPCs at fixed positions in the village.
## Each NPC gets a simple capsule mesh body, a name label, and dialogue capability.

var skin_color := Color(0.85, 0.72, 0.6)
var guard_color := Color(0.35, 0.35, 0.4)
var cloth_colors := [
	Color(0.6, 0.2, 0.15),  # Red tunic
	Color(0.2, 0.35, 0.55), # Blue
	Color(0.25, 0.45, 0.2), # Green
	Color(0.55, 0.4, 0.2),  # Brown
	Color(0.5, 0.2, 0.5),   # Purple
]


func _ready() -> void:
	_spawn_npcs()


func _spawn_npcs() -> void:
	# Tavern keeper - inside/near the tavern door
	_spawn_npc("Brenna", "Tavern Keeper", Vector3(-12, 0, -1.5),
		cloth_colors[0], NPCData.Role.MERCHANT,
		"Welcome to The Rusty Flagon! Sit down, have a drink.",
		180.0)

	# Blacksmith
	_spawn_npc("Tormund", "Blacksmith", Vector3(13, 0, -8),
		cloth_colors[3], NPCData.Role.MERCHANT,
		"Need a blade sharpened? Or perhaps something new forged?",
		-90.0)

	# Village Elder - near elder's house
	_spawn_npc("Elder Aldric", "Village Elder", Vector3(-8, 0, 10),
		cloth_colors[4], NPCData.Role.QUEST_GIVER,
		"Ah, a traveler. Millhaven hasn't seen one in some time. We could use your help.",
		0.0)

	# Guard at the gate
	_spawn_npc("Guard Captain Rolf", "Guard", Vector3(-2, 0, -20),
		guard_color, NPCData.Role.GUARD,
		"Keep your weapons sheathed inside the village walls.",
		0.0, true)

	# Guard patrolling near guard house
	_spawn_npc("Guard Mira", "Guard", Vector3(2, 0, 13),
		guard_color, NPCData.Role.GUARD,
		"All quiet. For now.",
		90.0, true)

	# Herbalist
	_spawn_npc("Sage Elara", "Herbalist", Vector3(16, 0, 6),
		cloth_colors[2], NPCData.Role.MERCHANT,
		"Potions, salves, remedies. What ails you, traveler?",
		-90.0)

	# Market vendors
	_spawn_npc("Marta", "Fruit Seller", Vector3(4, 0, -1.5),
		cloth_colors[1], NPCData.Role.MERCHANT,
		"Fresh apples and berries! Picked this morning!",
		0.0)

	_spawn_npc("Old Cedric", "Cloth Merchant", Vector3(-4, 0, 5.5),
		cloth_colors[3], NPCData.Role.MERCHANT,
		"Finest linens in the region. Well... the only linens, but still fine!",
		180.0)

	# Wandering villagers
	_spawn_npc("Hilda", "Farmer", Vector3(-16, 0, 4),
		cloth_colors[2], NPCData.Role.VILLAGER,
		"The crops are coming in well this season. If the bandits don't get to them first...",
		45.0)

	_spawn_npc("Jorik", "Fisherman", Vector3(6, 0, 12),
		cloth_colors[1], NPCData.Role.VILLAGER,
		"Used to fish down by the river. Can't anymore though, not since... well, you'll hear about it.",
		-30.0)

	# Mysterious NPC near dungeon path
	_spawn_npc("The Stranger", "???", Vector3(30, 0, -25),
		Color(0.2, 0.2, 0.22), NPCData.Role.QUEST_GIVER,
		"That cavern to the east... Ashfall Cavern, they call it. Something stirs within. Something ancient.",
		90.0)


func _spawn_npc(npc_name: String, title: String, pos: Vector3,
		clothing_color: Color, role: NPCData.Role, greeting: String,
		facing_deg: float, is_armored: bool = false) -> void:

	var npc := CharacterBody3D.new()
	npc.name = npc_name.replace(" ", "_")
	npc.position = pos
	npc.rotation.y = deg_to_rad(facing_deg)
	npc.collision_layer = 4   # NPC layer
	npc.collision_mask = 3    # World + Player
	npc.add_to_group("npcs")

	# Body collision
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	col.shape = capsule
	col.position.y = 0.85
	npc.add_child(col)

	# --- Visual body ---
	var body_node := Node3D.new()
	body_node.name = "Body"
	npc.add_child(body_node)

	# Legs
	var legs := _create_box(Vector3(0.4, 0.8, 0.3), Color(0.3, 0.25, 0.2))
	legs.position.y = 0.4
	body_node.add_child(legs)

	# Torso
	var body_color: Color = guard_color if is_armored else clothing_color
	var torso := _create_box(Vector3(0.5, 0.7, 0.3), body_color)
	torso.position.y = 1.15
	body_node.add_child(torso)

	# Head
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.15
	head_mesh.height = 0.3
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = skin_color
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = head_mat
	head.position.y = 1.65
	body_node.add_child(head)

	# Arms
	for x in [-0.35, 0.35]:
		var arm := _create_box(Vector3(0.12, 0.6, 0.12), body_color)
		arm.position = Vector3(x, 1.0, 0)
		body_node.add_child(arm)

	# Guard helmet
	if is_armored:
		var helmet := _create_box(Vector3(0.35, 0.2, 0.35), guard_color)
		helmet.position.y = 1.8
		body_node.add_child(helmet)

	# --- Name label ---
	var label := Label3D.new()
	label.text = npc_name
	label.position.y = 2.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 18
	label.modulate = _get_name_color(role)
	npc.add_child(label)

	# Title label (smaller, below name)
	var title_label := Label3D.new()
	title_label.text = title
	title_label.position.y = 1.95
	title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_label.font_size = 12
	title_label.modulate = Color(0.7, 0.7, 0.7)
	npc.add_child(title_label)

	# --- Simple dialogue via interact method ---
	var script := GDScript.new()
	script.source_code = _make_npc_script(greeting)
	script.reload()
	npc.set_script(script)

	add_child(npc)


func _make_npc_script(greeting: String) -> String:
	# Escape quotes in greeting
	var safe_greeting := greeting.replace('"', '\\"')
	return """extends CharacterBody3D

var _greeting: String = "%s"

func interact(player: CharacterBody3D) -> void:
	# Build a simple one-line dialogue
	var dialogue := DialogueData.new()
	var entry := DialogueEntry.new()
	entry.id = "greet"
	entry.speaker_name = name.replace("_", " ")
	entry.text = _greeting
	entry.next_entry_id = ""
	dialogue.entries = [entry]
	DialogueManager.start_dialogue(dialogue)
""" % safe_greeting


func _get_name_color(role: NPCData.Role) -> Color:
	match role:
		NPCData.Role.MERCHANT:
			return Color(0.9, 0.85, 0.5)  # Gold
		NPCData.Role.QUEST_GIVER:
			return Color(1.0, 0.85, 0.2)  # Bright gold
		NPCData.Role.GUARD:
			return Color(0.6, 0.7, 0.9)  # Steel blue
		_:
			return Color(0.9, 0.9, 0.9)  # White


func _create_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	return inst
