extends CharacterBody3D
class_name NPCController
## Controls an NPC in the world — movement, interaction, and basic AI.

@export var npc_data: NPCData
@export var patrol_points: Array[Node3D] = []
@export var patrol_speed: float = 2.0
@export var detection_range: float = 15.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var label: Label3D = $Label3D

enum State { IDLE, PATROL, CHASE, COMBAT, TALK, DEAD }

var current_state: State = State.IDLE
var health: float
var current_patrol_index: int = 0
var player_ref: CharacterBody3D = null


func _ready() -> void:
	if npc_data:
		health = npc_data.max_health
		if label:
			label.text = npc_data.display_name
	add_to_group("npcs")

	if patrol_points.size() > 0:
		current_state = State.PATROL


func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)
		State.IDLE:
			_do_idle(delta)


func _do_idle(_delta: float) -> void:
	# Look for player if hostile
	if npc_data and npc_data.attitude == NPCData.Attitude.HOSTILE:
		var player := get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < detection_range:
			player_ref = player
			current_state = State.CHASE


func _do_patrol(_delta: float) -> void:
	if patrol_points.size() == 0:
		current_state = State.IDLE
		return

	var target: Node3D = patrol_points[current_patrol_index]
	nav_agent.target_position = target.global_position

	if nav_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity = direction * patrol_speed
	move_and_slide()


func _do_chase(_delta: float) -> void:
	if player_ref == null:
		current_state = State.IDLE
		return

	nav_agent.target_position = player_ref.global_position
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity = direction * patrol_speed * 1.5
	move_and_slide()


func interact(player: CharacterBody3D) -> void:
	if current_state == State.DEAD:
		return
	if npc_data and npc_data.dialogue:
		current_state = State.TALK
		player_ref = player
		DialogueManager.start_dialogue(npc_data.dialogue)
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)


func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return
	var actual := max(amount - (npc_data.armor if npc_data else 0.0), 1.0)
	health -= actual
	if health <= 0:
		_die()


func _die() -> void:
	current_state = State.DEAD
	# Drop loot, play animation, etc.
	# For now just disable collision
	set_physics_process(false)


func _on_dialogue_ended() -> void:
	current_state = State.IDLE
