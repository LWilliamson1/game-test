extends CharacterBody3D
## First-person player controller with movement, jumping, sprinting, and mouse look.

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.5
@export var acceleration: float = 10.0
@export var deceleration: float = 8.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

@export_group("Interaction")
@export var interact_distance: float = 3.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float = walk_speed
var is_sprinting: bool = false

signal interacted_with(target: Node3D)


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	# Toggle mouse capture
	if event.is_action_pressed("pause"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Interaction
	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Sprinting
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor()
	current_speed = sprint_speed if is_sprinting else walk_speed

	# Movement direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	move_and_slide()


func _try_interact() -> void:
	if interact_ray and interact_ray.is_colliding():
		var target := interact_ray.get_collider()
		if target and target.has_method("interact"):
			target.interact(self)
			interacted_with.emit(target)


func get_look_direction() -> Vector3:
	return -camera.global_transform.basis.z
