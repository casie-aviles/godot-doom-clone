extends Node

# constants for movement speed and mouse sensitivity
const SPEED = 5.0

# constants for slide mechanic
const SLIDE_SPEED = 12.0
const SLIDE_DURATION = 0.4
const SLIDE_COOLDOWN = 1.0

# constants for gravity
const GRAVITY = 30.0

# variables for slide mechanic
var is_sliding = false
var slide_timer = 0.0
var slide_cooldown_timer = 0.0
var slide_direction = Vector3.ZERO

# referene player node and its camera
@onready var player = get_parent() as CharacterBody3D
@onready var camera = player.get_node("Camera3D")
@onready var skid_sound = player.get_node("SkidSound")

func try_slide() -> void:
	if not is_sliding and slide_cooldown_timer <= 0.0:
		skid_sound.play()
		var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
		if input_dir.length() > 0.1:
			is_sliding = true
			slide_timer = SLIDE_DURATION
			slide_cooldown_timer = SLIDE_COOLDOWN
			slide_direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func process_movement(delta: float, velocity: Vector3) -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.y -= GRAVITY * delta

	if is_sliding:
		velocity = slide_direction * SLIDE_SPEED
	else:
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
	else:
		if slide_cooldown_timer > 0.0:
			slide_cooldown_timer -= delta

	# Optional: camera bobbing
	if is_sliding:
		camera.position.y = lerp(camera.position.y, -0.8, 0.2)
	else:
		camera.position.y = lerp(camera.position.y, 0.0, 0.2)

	return velocity
