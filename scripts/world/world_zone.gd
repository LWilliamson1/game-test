extends Node3D
class_name WorldZone
## A discrete zone/area in the world (town, dungeon, wilderness, etc.)

@export var zone_id: String = ""
@export var zone_name: String = ""
@export var zone_music: AudioStream
@export var ambient_color: Color = Color(1, 1, 1)
@export var fog_density: float = 0.0
@export var is_interior: bool = false

@onready var spawn_points: Node3D = $SpawnPoints
@onready var npc_spawns: Node3D = $NPCSpawns
@onready var environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	add_to_group("zones")


func get_player_spawn() -> Vector3:
	if spawn_points and spawn_points.get_child_count() > 0:
		return spawn_points.get_child(0).global_position
	return global_position


func get_npc_spawn_points() -> Array[Node3D]:
	var points: Array[Node3D] = []
	if npc_spawns:
		for child in npc_spawns.get_children():
			points.append(child)
	return points
